import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'weekly_card.dart';

/// 관리자(부모) 뷰: 승인(정산) · 휴식일 · 다음 고리 · 보상 메모 · 주간 카드.
/// 소프트 PIN 게이트로 아이의 자기승인을 막는다.
class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  bool _unlocked = false;
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
    if (pin != null && !_unlocked) {
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
                    setState(() => _unlocked = true);
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
    final pending = state.pendingApproval;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('관리자', style: Theme.of(context).textTheme.headlineSmall),
          Text('포인트 ${state.data.points} · 컴패니언 Lv.${state.data.petLevel}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('오늘 승인',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('승인할 항목이 없어요.'),
                    )
                  else
                    ...pending.map((h) => ListTile(
                          title: Text(h.name),
                          trailing: FilledButton(
                            onPressed: () => state.settleHabit(h.id),
                            child: const Text('승인'),
                          ),
                        )),
                ],
              ),
            ),
          ),
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('주간 성장 스토리'),
              subtitle: const Text('환경이 한 일을 보여줘요'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WeeklyCard())),
            ),
          ),
          _PinCard(state: state),
        ],
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
        onTap: () => _editPin(context),
      ),
    );
  }

  void _editPin(BuildContext context) {
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
}
