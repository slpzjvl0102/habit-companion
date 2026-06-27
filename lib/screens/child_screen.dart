import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/companion.dart';

/// 실행자(아이) 뷰: 컴패니언 + 오늘의 고리 큰 탭 카드.
class ChildScreen extends StatelessWidget {
  const ChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CompanionView(pet: state.pet),
            const SizedBox(height: 28),
            if (state.restDay)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('오늘은 쉬는 날 💤  컴패니언도 같이 쉬어요.'),
                ),
              )
            else
              ...state.activeHabits.map((h) => _HabitCard(
                    name: h.name,
                    done: state.isChecked(h.id),
                    onTap: () => state.checkHabit(h.id),
                  )),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final String name;
  final bool done;
  final VoidCallback onTap;
  const _HabitCard(
      {required this.name, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(name, style: Theme.of(context).textTheme.headlineSmall),
        trailing: done
            ? const Chip(avatar: Icon(Icons.check, size: 18), label: Text('완료'))
            : FilledButton(onPressed: onTap, child: const Text('했어!')),
      ),
    );
  }
}
