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
    expect(state.pet.awaitingApproval, true); // instant, no parent gate

    state.settleHabit('h1');
    expect(state.pet.awaitingApproval, false);
    expect(state.data.points, 1);
  });

  test('checked-but-unsettled day stays positive (child not punished)', () async {
    final store = Storage();
    final d = AppData.seed('2026-06-20');
    d.dayLog('2026-06-20').checked.add('h1'); // child did it; parent never settled
    await store.save(d);

    final state =
        await AppState.boot(storage: store, now: () => DateTime(2026, 6, 21, 9));
    expect(state.data.petLowEnergy, false);
  });

  test('fully missed day -> lowEnergy, recovers on next check', () async {
    final store = Storage();
    await store.save(AppData.seed('2026-06-20')); // nothing on 06-20

    final state =
        await AppState.boot(storage: store, now: () => DateTime(2026, 6, 22, 9));
    expect(state.data.petLowEnergy, true);
    expect(state.pet.mood, PetMood.lowEnergy);

    state.checkHabit('h1');
    expect(state.data.petLowEnergy, false);
    expect(state.pet.mood, PetMood.energized);
  });

  test('rest day -> resting', () async {
    final state = await AppState.boot(now: () => DateTime(2026, 6, 10, 9));
    state.toggleRestDay();
    expect(state.pet.mood, PetMood.resting);
  });

  test('progression: 5 of last 7 -> can add next, capped at 3', () async {
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
    state.addNextHabit('물 한 컵');
    expect(state.data.habits.length, 3);
    state.addNextHabit('네 번째'); // capped
    expect(state.data.habits.length, 3);
  });
}
