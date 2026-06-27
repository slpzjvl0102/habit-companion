import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// 주간 '성장 스토리' 카드 (미션 핵심 C1). FIX (design CRIT-2): the hero number is
/// now COMPLETION (which actually moves over a 3-week run), not chain count
/// (which stays "1→1" most of the time). A 7-dot strip makes change visceral.
/// Label is "완료한 날" (honest) rather than "자발", since a tap can't prove
/// self-initiation — the ABA OFF phase carries the self-initiation claim.
class WeeklyCard extends StatelessWidget {
  const WeeklyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final d = state.data;
    final today = state.today;
    final first = d.firstDay ?? today;
    final daysElapsed =
        DateTime.parse(today).difference(DateTime.parse(first)).inDays;
    final week = (daysElapsed ~/ 7) + 1;
    final activeIds = d.activeHabits.map((h) => h.id).toSet();
    final doneByDay = state.clock
        .lastNDays(today, 7)
        .map((day) =>
            (d.log[day]?.checked ?? const <String>{}).any(activeIds.contains))
        .toList();
    final completed = doneByDay.where((x) => x).length;
    final chain = d.activeHabits.length;

    return Scaffold(
      appBar: AppBar(title: const Text('성장 스토리')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('$week주차', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                  child: _Pillar(label: '그때 (1주차)', big: '0', sub: '완료한 날')),
              const Icon(Icons.arrow_forward, size: 28),
              Expanded(
                  child:
                      _Pillar(label: '지금', big: '$completed', sub: '/ 7일 완료')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final done in doneByDay)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    done ? Icons.circle : Icons.circle_outlined,
                    size: 18,
                    color: done
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black26,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
              child: Text('고리 $chain개',
                  style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                week <= 1
                    ? '여기가 출발선이에요. 다음 주부터 점이 하나씩 채워지는 걸 보세요.\n\n'
                        '바뀌는 건 더 다그쳐서가 아니라, 작은 고리를 환경에 심어둔 덕이에요.'
                    : '처음엔 매일 챙겨야 했죠. 지금은 최근 7일 중 $completed일을 해냈어요.\n\n'
                        '당신이 더 다그쳐서가 아니라, 작은 고리를 하나씩 이어준 결과예요. 환경이 한 거예요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  final String label;
  final String big;
  final String sub;
  const _Pillar({required this.label, required this.big, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(big, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(sub,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
