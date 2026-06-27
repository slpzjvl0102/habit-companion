/// Day-boundary logic. A "habit day" starts at [resetHour] (default 4am), so a
/// late-evening parent approval still counts for that day.
class DayClock {
  final int resetHour;
  const DayClock({this.resetHour = 4});

  String key(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  /// The habit-day key for [now].
  String habitDay(DateTime now) =>
      key(now.subtract(Duration(hours: resetHour)));

  /// Last [n] habit-day keys ending at [today] (inclusive), oldest first.
  List<String> lastNDays(String today, int n) {
    final base = DateTime.parse(today);
    return List.generate(
      n,
      (i) => key(base.subtract(Duration(days: n - 1 - i))),
    );
  }

  /// Habit-day keys strictly after [from], up to and including [to].
  List<String> daysAfter(String from, String to) {
    final end = DateTime.parse(to);
    final out = <String>[];
    var d = DateTime.parse(from).add(const Duration(days: 1));
    while (!d.isAfter(end)) {
      out.add(key(d));
      d = d.add(const Duration(days: 1));
    }
    return out;
  }
}
