import 'package:flutter_test/flutter_test.dart';
import 'package:habit_companion/services/day_clock.dart';

void main() {
  const clock = DayClock(resetHour: 4);

  test('reset hour keeps after-midnight on the previous habit-day', () {
    expect(clock.habitDay(DateTime(2026, 6, 22, 2)), '2026-06-21');
    expect(clock.habitDay(DateTime(2026, 6, 22, 5)), '2026-06-22');
  });

  test('lastNDays is oldest-first and inclusive', () {
    final days = clock.lastNDays('2026-06-10', 7);
    expect(days.length, 7);
    expect(days.first, '2026-06-04');
    expect(days.last, '2026-06-10');
  });

  test('daysAfter excludes from, includes to', () {
    expect(clock.daysAfter('2026-06-20', '2026-06-22'),
        ['2026-06-21', '2026-06-22']);
  });
}
