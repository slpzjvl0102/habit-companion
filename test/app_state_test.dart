import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_companion/models/app_data.dart';
import 'package:habit_companion/services/day_clock.dart';
import 'package:habit_companion/services/pet_state.dart';
import 'package:habit_companion/services/storage.dart';
import 'package:habit_companion/state/app_state.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('check -> energized + awaiting; settle -> approved + point', () async {
    final state = await AppState.boot(now: () => DateTime(2026, 6, 10, 9));
    expect(state.pet.mood, PetMood.idle);

    state.checkHabit('h1');
    expect(state.pet.mood, PetMood.energized);
    expect(state.pet.awaitingApproval, true);

    state.settleHabit(state.today, 'h1');
    expect(state.pet.awaitingApproval, false);
    expect(state.data.points, 1);
  });

  test('eng CRIT-1: a prior-day check is still approvable next morning',
      () async {
    final store = Storage();
    final d = AppData.seed('2026-06-20');
    d.dayLog('2026-06-20').checked.add('h1'); // child did it on day D
    await store.save(d);

    // working parent opens the app next morning (D+1)
    final state =
        await AppState.boot(storage: store, now: () => DateTime(2026, 6, 21, 9));
    final pending = state.pendingApprovals;
    expect(pending.any((p) => p.day == '2026-06-20' && p.habit.id == 'h1'), true);

    state.settleHabit('2026-06-20', 'h1');
    expect(state.data.log['2026-06-20']!.settled.contains('h1'), true);
    expect(state.data.points, 1); // reward landed on the correct day, not lost
  });

  test('checked-but-unsettled day stays positive (child not punished)',
      () async {
    final store = Storage();
    final d = AppData.seed('2026-06-20');
    d.dayLog('2026-06-20').checked.add('h1');
    await store.save(d);

    final state =
        await AppState.boot(storage: store, now: () => DateTime(2026, 6, 21, 9));
    expect(state.data.petLowEnergy, false);
  });

  test('fully missed day -> lowEnergy, recovers on next check', () async {
    final store = Storage();
    await store.save(AppData.seed('2026-06-20'));

    final state =
        await AppState.boot(storage: store, now: () => DateTime(2026, 6, 22, 9));
    expect(state.data.petLowEnergy, true);
    expect(state.pet.mood, PetMood.lowEnergy);

    state.checkHabit('h1');
    expect(state.data.petLowEnergy, false);
    expect(state.pet.mood, PetMood.energized);
  });

  test('rest day inside the gap is paused, not stale lowEnergy', () async {
    final store = Storage();
    final d = AppData.seed('2026-06-10');
    d.dayLog('2026-06-10').checked.add('h1'); // 06-10 done
    d.dayLog('2026-06-11').restDay = true; // 06-11 rest
    d.lastSeenDay = '2026-06-10';
    await store.save(d);

    // boot 06-12: most recent non-rest ended day is 06-10 (done) -> not lowEnergy
    final state =
        await AppState.boot(storage: store, now: () => DateTime(2026, 6, 12, 9));
    expect(state.data.petLowEnergy, false);
  });

  test('rest day -> resting', () async {
    final state = await AppState.boot(now: () => DateTime(2026, 6, 10, 9));
    state.toggleRestDay();
    expect(state.pet.mood, PetMood.resting);
  });

  test('progression: 5/7 unlocks ONE habit; the next needs its own gate',
      () async {
    final store = Storage();
    const clock = DayClock();
    final d = AppData.seed('2026-06-01');
    for (final day in clock.lastNDays('2026-06-10', 7).take(5)) {
      d.dayLog(day).checked.add('h1');
    }
    d.lastSeenDay = '2026-06-10';
    await store.save(d);

    final state =
        await AppState.boot(storage: store, now: () => DateTime(2026, 6, 10, 9));
    expect(state.canAddNextHabit, true);

    state.addNextHabit('양치');
    expect(state.data.habits.length, 2);

    // the new habit isn't established yet -> gate closed, can't chain again
    expect(state.canAddNextHabit, false);
    state.addNextHabit('물 한 컵');
    expect(state.data.habits.length, 2);
  });
}
