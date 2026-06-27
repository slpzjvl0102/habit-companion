import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// 주간 '성장 스토리' 카드 (미션 핵심 C1): 부모에게 변화의 귀인을
/// '환경(작은 고리 누적)'으로 돌린다. A(서사) + B(그때 vs 지금).
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
    final completed = state.clock
        .lastNDays(today, 7)
        .where((day) =>
            (d.log[day]?.checked ?? const <String>{}).any(activeIds.contains))
        .length;
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
                  child: _Pillar(
                      label: '그때 (1주차)', big: '1', sub: '고리 · 매일 챙김')),
              const Icon(Icons.arrow_forward, size: 28),
              Expanded(
                  child: _Pillar(
                      label: '지금',
                      big: '$chain',
                      sub: '고리 · 최근 7일 $completed일 자발')),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                week <= 1
                    ? '여기가 출발선이에요. 다음 주부터 "그때 vs 지금"이 보이기 시작해요.\n\n'
                        '기억해요 — 바뀌는 건 더 다그쳐서가 아니라, 작은 고리를 환경에 하나씩 심어둔 덕이에요.'
                    : '처음엔 고리 1개를 매일 챙겨야 했죠. 지금은 고리 $chain개, '
                        '최근 7일 중 $completed일을 스스로 했어요.\n\n'
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
