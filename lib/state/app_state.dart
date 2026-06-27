import 'package:flutter/foundation.dart';

import '../models/app_data.dart';
import '../services/day_clock.dart';
import '../services/pet_state.dart';
import '../services/storage.dart';

/// Single source of truth (provider). Wraps [AppData] with the core-loop
/// actions and the 2-layer state machine.
class AppState extends ChangeNotifier {
  final Storage _storage;
  final DateTime Function() _now;
  AppData data;

  AppState(this.data, this._storage, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  DayClock get clock => DayClock(resetHour: data.resetHour);
  String get today => clock.habitDay(_now());

  /// Load (or seed) state, run rollover, persist.
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
  List<Habit> get pendingApproval =>
      activeHabits.where((h) => isChecked(h.id) && !isSettled(h.id)).toList();

  // ---- actions ----
  void checkHabit(String id) {
    if (restDay) return;
    data.dayLog(today).checked.add(id);
    data.petLowEnergy = false; // immediate recovery
    _persist();
  }

  void settleHabit(String id) {
    final log = data.dayLog(today);
    if (!log.checked.contains(id) || log.settled.contains(id)) return;
    log.settled.add(id);
    data.points += 1;
    _grow();
    _persist();
  }

  void toggleRestDay() {
    final log = data.dayLog(today);
    log.restDay = !log.restDay;
    _persist();
  }

  void addNextHabit(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || data.habits.length >= 3) return;
    final nextOrder =
        data.habits.map((h) => h.order).fold<int>(-1, (m, o) => o > m ? o : m) +
            1;
    data.habits
        .add(Habit(id: 'h${data.habits.length + 1}', name: trimmed, order: nextOrder));
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

  // ---- internals ----
  void _grow() {
    data.petXp += 1;
    if (data.petXp >= data.petLevel * 3) {
      data.petXp = 0;
      data.petLevel += 1;
    }
  }

  /// Layer-1 rollover: any ended day with no check (and not a rest day) leaves
  /// the companion lowEnergy; a checked day clears it. Never starves/dies.
  void _rollover() {
    final t = today;
    if (data.lastSeenDay == t) return;
    final endedDays = <String>[data.lastSeenDay, ...clock.daysAfter(data.lastSeenDay, t)];
    final activeIds = data.activeHabits.map((h) => h.id).toSet();
    for (final day in endedDays) {
      if (day == t) continue; // today hasn't ended
      final l = data.log[day];
      final isRest = l?.restDay ?? false;
      final didCheck =
          l != null && l.checked.intersection(activeIds).isNotEmpty;
      if (!isRest && !didCheck) {
        data.petLowEnergy = true;
      } else if (didCheck) {
        data.petLowEnergy = false;
      }
    }
    data.lastSeenDay = t;
  }

  void _persist() {
    notifyListeners();
    _storage.save(data); // fire-and-forget; UI state already updated
  }
}
