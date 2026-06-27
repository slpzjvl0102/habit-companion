import 'package:flutter/material.dart';

import '../services/pet_state.dart';

/// The growth companion. FIX (design CRIT-1): the creature now visibly EVOLVES
/// with level (🥚→🐣→🦎→🐲→🐉) and shows an XP-to-next-evolution ring — the core
/// 10yo motivator the spec promised. lowEnergy is a "needs a charge" (battery)
/// state, kept bright, not a guilt-tripping faded sad pet.
class CompanionView extends StatelessWidget {
  final PetView pet;
  final int xp;
  final int xpForNext;
  const CompanionView({
    super.key,
    required this.pet,
    required this.xp,
    required this.xpForNext,
  });

  String _glyph(int level) {
    if (level <= 1) return '🥚';
    if (level == 2) return '🐣';
    if (level <= 4) return '🦎';
    if (level <= 6) return '🐲';
    return '🐉';
  }

  @override
  Widget build(BuildContext context) {
    final s = _spec(pet.mood);
    final progress = xpForNext > 0 ? (xp / xpForNext).clamp(0.0, 1.0) : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 184,
          height: 184,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 184,
                height: 184,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(s.ring),
                ),
              ),
              AnimatedScale(
                scale: pet.mood == PetMood.energized ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: s.bg),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: s.dim ? 0.8 : 1.0,
                    child: Text(_glyph(pet.level),
                        style: const TextStyle(fontSize: 78)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('다음 진화까지 $xp / $xpForNext',
              style: Theme.of(context).textTheme.bodySmall),
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
        return const _Spec('대기 중', Color(0xFFEFF1F5), Color(0xFF8FA0B6), false);
      case PetMood.lowEnergy:
        return const _Spec(
            '에너지 낮음 🔋', Color(0xFFFFF4E0), Color(0xFFF59E0B), true);
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
