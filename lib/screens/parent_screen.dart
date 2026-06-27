import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'weekly_card.dart';

/// 관리자(부모) 뷰. unlocked/onUnlocked are owned by HomeShell so the soft PIN
/// gate RE-LOCKS whenever the parent leaves the tab (fix: previously checked
/// once per launch, letting the kid self-approve).
class ParentScreen extends StatefulWidget {
  final bool unlocked;
  final VoidCallback onUnlocked;
  const ParentScreen({
    super.key,
    required this.unlocked,
    required this.onUnlocked,
  });

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pin = state.data.parentPin;
    if (pin != null && !widget.unlocked) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              const Text('부모 확인 (PIN)'),
              const SizedBox(height: 16),
              TextField(
                controller: _pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '4자리'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (_pin.text == pin) {
                    widget.onUnlocked();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN이 틀렸어요')));
                  }
                  _pin.clear();
                },
                child: const Text('열기'),
              ),
            ],
          ),
        ),
      );
    }
    return _ParentBody(state: state);
  }
}

class _ParentBody extends StatelessWidget {
  final AppState state;
  const _ParentBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('관리자', style: Theme.of(context).textTheme.headlineSmall),
          Text('포인트 ${state.data.points} · 컴패니언 Lv.${state.data.petLevel}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          _WeeklyPreview(state: state), // promoted to top (mission C1)
          if (state.data.parentPin == null) _PinNudge(state: state),
          _ApprovalCard(state: state),
          Card(
            child: SwitchListTile(
              title: const Text('오늘은 쉬는 날'),
              subtitle: const Text('컴패니언도 쉬고, 진행은 멈추지 않아요'),
              value: state.restDay,
              onChanged: (_) => state.toggleRestDay(),
            ),
          ),
          if (state.canAddNextHabit) _AddNextCard(state: state),
          _RewardCard(state: state),
          _PinCard(state: state),
        ],
      ),
    );
  }
}

class _WeeklyPreview extends StatelessWidget {
  final AppState state;
  const _WeeklyPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    final d = state.data;
    final activeIds = d.activeHabits.map((h) => h.id).toSet();
    final completed = state.clock
        .lastNDays(state.today, 7)
        .where((day) =>
            (d.log[day]?.checked ?? const <String>{}).any(activeIds.contains))
        .length;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.insights),
        title: const Text('주간 성장 스토리'),
        subtitle: Text('최근 7일 중 $completed일 스스로 · 환경이 한 일을 보세요'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const WeeklyCard())),
      ),
    );
  }
}

class _PinNudge extends StatelessWidget {
  final AppState state;
  const _PinNudge({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.warning_amber),
        title: const Text('부모 PIN을 설정하세요'),
        subtitle: const Text('지금은 아이가 스스로 승인할 수 있어요'),
        trailing: FilledButton(
          onPressed: () => editPin(context, state),
          child: const Text('설정'),
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final AppState state;
  const _ApprovalCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingApprovals;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('오늘 현황 · 승인',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            // FIX (design #5): show today's per-habit status, not just pending.
            ...state.activeHabits.map((h) {
              final st = state.todayStatus(h.id);
              final label = st == 2
                  ? '완료'
                  : st == 1
                      ? '했음 · 승인 대기'
                      : '아직 안 함';
              return ListTile(
                dense: true,
                title: Text(h.name),
                trailing: Text(label),
              );
            }),
            const Divider(),
            // FIX (eng CRIT-1): pending spans yesterday too, so a next-morning
            // approval still lands.
            if (pending.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('승인할 항목이 없어요.'),
              )
            else
              ...pending.map((p) => ListTile(
                    title: Text(p.habit.name),
                    subtitle: p.isToday ? null : const Text('어제 한 것'),
                    trailing: FilledButton(
                      onPressed: () {
                        state.settleHabit(p.day, p.habit.id);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(state.lastGrowLeveled
                              ? '+1 · 컴패니언이 진화했어요! Lv.${state.data.petLevel}'
                              : '+1 · 컴패니언이 자랐어요'),
                          duration: const Duration(seconds: 1),
                        ));
                      },
                      child: const Text('승인'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _AddNextCard extends StatefulWidget {
  final AppState state;
  const _AddNextCard({required this.state});
  @override
  State<_AddNextCard> createState() => _AddNextCardState();
}

class _AddNextCardState extends State<_AddNextCard> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다음 고리를 이을 때가 됐어요 🎉',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('지난 고리가 익었어요. 아이의 실제 루틴에서 다음 작은 습관 하나를 더하세요.'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: '예: 양치'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  widget.state.addNextHabit(_c.text);
                  _c.clear();
                },
                child: const Text('추가'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatefulWidget {
  final AppState state;
  const _RewardCard({required this.state});
  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> {
  late final TextEditingController _c =
      TextEditingController(text: widget.state.data.rewardPromise);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('실물 보상 약속 (수동)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _c,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '예: 이번 주 다 하면 아이스크림',
              ),
              onSubmitted: widget.state.setRewardPromise,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  widget.state.setRewardPromise(_c.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장됐어요')));
                },
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  final AppState state;
  const _PinCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasPin = state.data.parentPin != null;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.pin_outlined),
        title: Text(hasPin ? '부모 PIN 변경 / 해제' : '부모 PIN 설정'),
        subtitle: const Text('아이가 스스로 승인하지 못하게'),
        onTap: () => editPin(context, state),
      ),
    );
  }
}

void editPin(BuildContext context, AppState state) {
  final c = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('부모 PIN'),
      content: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        obscureText: true,
        decoration: const InputDecoration(hintText: '4자리 (비우면 해제)'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            state.setParentPin(c.text.isEmpty ? null : c.text);
            Navigator.pop(ctx);
          },
          child: const Text('저장'),
        ),
      ],
    ),
  );
}
