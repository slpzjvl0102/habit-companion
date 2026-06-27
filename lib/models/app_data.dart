// Pure data model for the experiment app. Serialized to a single
// shared_preferences JSON key. No backend, no accounts.

class Habit {
  final String id;
  String name;
  final int order;
  bool active;

  Habit({
    required this.id,
    required this.name,
    required this.order,
    this.active = true,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'order': order, 'active': active};

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        order: j['order'] as int,
        active: (j['active'] as bool?) ?? true,
      );
}

class DayLog {
  final Set<String> checked;
  final Set<String> settled;
  bool restDay;

  DayLog({Set<String>? checked, Set<String>? settled, this.restDay = false})
      : checked = checked ?? <String>{},
        settled = settled ?? <String>{};

  Map<String, dynamic> toJson() => {
        'checked': checked.toList(),
        'settled': settled.toList(),
        'restDay': restDay,
      };

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        checked: ((j['checked'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        settled: ((j['settled'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        restDay: (j['restDay'] as bool?) ?? false,
      );
}

class AppData {
  List<Habit> habits;
  Map<String, DayLog> log;
  int petLevel;
  int petXp;
  bool petLowEnergy;
  int points;
  String rewardPromise;
  String? firstDay;
  String lastSeenDay;
  int resetHour;
  String? parentPin;

  AppData({
    required this.habits,
    Map<String, DayLog>? log,
    this.petLevel = 1,
    this.petXp = 0,
    this.petLowEnergy = false,
    this.points = 0,
    this.rewardPromise = '',
    this.firstDay,
    required this.lastSeenDay,
    this.resetHour = 4,
    this.parentPin,
  }) : log = log ?? <String, DayLog>{};

  /// First-run seed: one hardcoded habit pulled from the real test child's
  /// morning routine (이불 정리).
  static AppData seed(String today) => AppData(
        habits: [Habit(id: 'h1', name: '이불 정리', order: 0)],
        firstDay: today,
        lastSeenDay: today,
      );

  List<Habit> get activeHabits => habits.where((h) => h.active).toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  DayLog dayLog(String day) => log.putIfAbsent(day, () => DayLog());

  Map<String, dynamic> toJson() => {
        'habits': habits.map((h) => h.toJson()).toList(),
        'log': log.map((k, v) => MapEntry(k, v.toJson())),
        'petLevel': petLevel,
        'petXp': petXp,
        'petLowEnergy': petLowEnergy,
        'points': points,
        'rewardPromise': rewardPromise,
        'firstDay': firstDay,
        'lastSeenDay': lastSeenDay,
        'resetHour': resetHour,
        'parentPin': parentPin,
      };

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        habits: ((j['habits'] as List?) ?? const [])
            .map((e) => Habit.fromJson(e as Map<String, dynamic>))
            .toList(),
        log: ((j['log'] as Map?) ?? const {}).map(
          (k, v) =>
              MapEntry(k as String, DayLog.fromJson(v as Map<String, dynamic>)),
        ),
        petLevel: (j['petLevel'] as int?) ?? 1,
        petXp: (j['petXp'] as int?) ?? 0,
        petLowEnergy: (j['petLowEnergy'] as bool?) ?? false,
        points: (j['points'] as int?) ?? 0,
        rewardPromise: (j['rewardPromise'] as String?) ?? '',
        firstDay: j['firstDay'] as String?,
        lastSeenDay: j['lastSeenDay'] as String,
        resetHour: (j['resetHour'] as int?) ?? 4,
        parentPin: j['parentPin'] as String?,
      );
}
