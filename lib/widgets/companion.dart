import 'package:flutter/material.dart';

import '../services/pet_state.dart';

/// The growth companion. Re-skinned for a 10yo: a creature you raise/charge —
/// mood is shown via aura color + label, never a babyish sad face. lowEnergy
/// just dims the creature.
class CompanionView extends StatelessWidget {
  final PetView pet;
  const CompanionView({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final s = _spec(pet.mood);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 168,
          height: 168,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.bg,
            border: Border.all(color: s.ring, width: 5),
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: s.dim ? 0.45 : 1.0,
            child: const Text('🐲', style: TextStyle(fontSize: 84)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Lv.${pet.level}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text(s.label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        if (pet.awaitingApproval)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Chip(
              avatar: Icon(Icons.hourglass_bottom, size: 18),
              label: Text('성장 준비 완료 · 승인 대기'),
            ),
          ),
      ],
    );
  }

  _Spec _spec(PetMood m) {
    switch (m) {
      case PetMood.energized:
        return const _Spec('활기 넘침', Color(0xFFDDF4E7), Color(0xFF22C55E), false);
      case PetMood.idle:
        return const _Spec('대기 중', Color(0xFFEFF1F5), Color(0xFFAAB2C0), false);
      case PetMood.lowEnergy:
        return const _Spec('에너지 낮음', Color(0xFFF2F2F4), Color(0xFFCBD0D8), true);
      case PetMood.resting:
        return const _Spec('쉬는 중 💤', Color(0xFFE9E8F5), Color(0xFF8B86D6), false);
    }
  }
}

class _Spec {
  final String label;
  final Color bg;
  final Color ring;
  final bool dim;
  const _Spec(this.label, this.bg, this.ring, this.dim);
}
