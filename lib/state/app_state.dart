import 'package:flutter/foundation.dart';

import '../models/app_data.dart';
import '../services/day_clock.dart';
import '../services/pet_state.dart';
import '../services/storage.dart';

/// A check awaiting parent approval, possibly from an earlier day.
typedef PendingItem = ({String day, Habit habit, bool isToday});

/// Single source of truth (provider). Wraps [AppData] with the core-loop
/// actions and the 2-layer state machine.
class AppState extends ChangeNotifier {
  final Storage _storage;
  final DateTime Function() _now;
  AppData data;
  bool _lastGrowLeveled = false;

  AppState(this.data, this._storage, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  DayClock get clock => DayClock(resetHour: data.resetHour);
  String get today => clock.habitDay(_now());

  static Future<AppState> boot({
    Storage? storage,
    DateTime Function()? now,
  }) async {
    final store = storage ?? Storage();
    final clockNow = now ?? DateTime.now;
    final t = const DayClock().habitDay(clockNow());
    final loaded = await store.load();
    final state = AppState(loaded ?? AppData.seed(t), store, now: now);
    state._rollover();
    await store.save(state.data);
    return state;
  }

  // ---- derived ----
  PetView get pet => computePetView(data, today);
  List<Habit> get activeHabits => data.activeHabits;
  bool get restDay => data.log[today]?.restDay ?? false;
  bool isChecked(String id) => data.log[today]?.checked.contains(id) ?? false;
  bool isSettled(String id) => data.log[today]?.settled.contains(id) ?? false;
  bool get canAddNextHabit => progressionReady(data, today, clock);
  int get petXp => data.petXp;
  int get xpForNext => data.petLevel * 3;
  bool get lastGrowLeveled => _lastGrowLeveled;

  /// Today's status for one habit, for the parent's at-a-glance view.
  /// 0 = not done, 1 = done (awaiting approval), 2 = approved.
  int todayStatus(String id) {
    if (isSettled(id)) return 2;
    if (isChecked(id)) return 1;
    return 0;
  }

  /// Checks awaiting approval across the last 2 habit-days. FIX: a working
  /// parent who approves the next morning must still be able to settle
  /// yesterday's check (previously unreachable once the day rolled over).
  List<PendingItem> get pendingApprovals {
    final out = <PendingItem>[];
    final actives = data.activeHabits;
    for (final day in clock.lastNDays(today, 2)) {
      final log = data.log[day];
      if (log == null) continue;
      for (final h in actives) {
        if (log.checked.contains(h.id) && !log.settled.contains(h.id)) {
          out.add((day: day, habit: h, isToday: day == today));
        }
      }
    }
    return out;
  }

  // ---- actions ----
  void checkHabit(String id) {
    if (restDay) return;
    data.dayLog(today).checked.add(id);
    data.petLowEnergy = false; // immediate recovery
    _persist();
  }

  /// Settle a check that may belong to an earlier day. Points/growth land on
  /// the correct day's log so the child's reward is never silently dropped.
  void settleHabit(String day, String id) {
    final log = data.dayLog(day);
    if (!log.checked.contains(id) || log.settled.contains(id)) return;
    log.settled.add(id);
    data.points += 1;
    _grow();
    _persist();
  }

  void toggleRestDay() {
    data.dayLog(today).restDay = !(data.log[today]?.restDay ?? false);
    _persist();
  }

  void addNextHabit(String name) {
    final trimmed = name.trim();
    // Re-assert the 5/7 gate in the model (was UI-only before).
    if (trimmed.isEmpty || data.habits.length >= 3 || !canAddNextHabit) return;
    final nextOrder =
        data.habits.map((h) => h.order).fold<int>(-1, (m, o) => o > m ? o : m) +
            1;
    final nextId =
        data.habits.map((h) => h.order).fold<int>(-1, (m, o) => o > m ? o : m) +
            2;
    data.habits.add(Habit(id: 'h$nextId', name: trimmed, order: nextOrder));
    _persist();
  }

  void setRewardPromise(String text) {
    data.rewardPromise = text;
    _persist();
  }

  void setParentPin(String? pin) {
    data.parentPin = (pin == null || pin.isEmpty) ? null : pin;
    _persist();
  }

  /// Re-run day rollover when the app is resumed from background (Flutter does
  /// not re-run main()/boot() on resume).
  void refresh() {
    _rollover();
    notifyListeners();
    _save();
  }

  // ---- internals ----
  void _grow() {
    data.petXp += 1;
    if (data.petXp >= data.petLevel * 3) {
      data.petXp = 0;
      data.petLevel += 1;
      _lastGrowLeveled = true;
    } else {
      _lastGrowLeveled = false;
    }
  }

  /// Layer-1 rollover: the companion's lowEnergy reflects the most recent
  /// *non-rest* ended day (rest days are paused, not stale). Bounded to a
  /// 14-day look-back so a corrupt/ancient lastSeenDay can't loop forever.
  void _rollover() {
    final t = today;
    if (data.lastSeenDay == t) return;
    final activeIds = data.activeHabits.map((h) => h.id).toSet();
    final recent = clock.lastNDays(t, 15); // oldest..t
    for (var i = recent.length - 2; i >= 0; i--) {
      final day = recent[i];
      if (day.compareTo(data.lastSeenDay) < 0) break; // only days since last seen
      final l = data.log[day];
      if (l?.restDay ?? false) continue; // skip rest days
      final didCheck = l != null && l.checked.intersection(activeIds).isNotEmpty;
      data.petLowEnergy = !didCheck;
      break;
    }
    data.lastSeenDay = t;
  }

  void _persist() {
    notifyListeners();
    _save();
  }

  void _save() {
    // Fire-and-forget, but errors are caught + logged instead of becoming an
    // unhandled async error that silently loses a write.
    _storage.save(data).catchError((Object e) {
      debugPrint('habit_companion: save failed: $e');
    });
  }
}
