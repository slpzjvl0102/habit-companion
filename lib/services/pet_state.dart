import '../models/app_data.dart';
import 'day_clock.dart';

/// The 2-layer state machine, layer 1 (mood). Re-skinned for a 10yo: a
/// growth-type companion, not a needy baby pet. "sad" -> lowEnergy/dormant.
enum PetMood { resting, energized, idle, lowEnergy }

class PetView {
  final PetMood mood;

  /// True when the child acted but the parent hasn't settled yet
  /// ("성장 준비 완료 · 승인 대기"). Mood stays positive — the child is never
  /// punished for the parent's lapse.
  final bool awaitingApproval;
  final int level;

  const PetView({
    required this.mood,
    required this.awaitingApproval,
    required this.level,
  });
}

/// Compute the companion's current displayed state.
/// - rest day            -> resting
/// - checked today       -> energized (awaitingApproval if not settled)
/// - missed (rollover)   -> lowEnergy (mild, instantly recovered on next check)
/// - otherwise           -> idle
PetView computePetView(AppData d, String today) {
  final log = d.log[today];
  if (log?.restDay == true) {
    return PetView(
        mood: PetMood.resting, awaitingApproval: false, level: d.petLevel);
  }
  final activeIds = d.activeHabits.map((h) => h.id).toSet();
  final checked = (log?.checked ?? const <String>{}).intersection(activeIds);
  final settled = (log?.settled ?? const <String>{}).intersection(activeIds);
  if (checked.isNotEmpty) {
    return PetView(
      mood: PetMood.energized,
      awaitingApproval: checked.difference(settled).isNotEmpty,
      level: d.petLevel,
    );
  }
  if (d.petLowEnergy) {
    return PetView(
        mood: PetMood.lowEnergy, awaitingApproval: false, level: d.petLevel);
  }
  return PetView(mood: PetMood.idle, awaitingApproval: false, level: d.petLevel);
}

/// True when the most recent active habit has been checked on >= 5 of the last
/// 7 habit-days and there's room to add another (cap 3). The parent then
/// approves adding the next link (progression trigger).
bool progressionReady(AppData d, String today, DayClock clock) {
  final actives = d.activeHabits;
  if (actives.isEmpty || d.habits.length >= 4) return false; // 4-routine chain
  final latest = actives.last;
  final hits = clock
      .lastNDays(today, 7)
      .where((day) => d.log[day]?.checked.contains(latest.id) == true)
      .length;
  return hits >= 5;
}
