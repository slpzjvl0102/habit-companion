import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';

/// Local persistence: the whole app state as one JSON blob in
/// shared_preferences. Works on web (localStorage) and Android.
class Storage {
  static const _key = 'habit_companion_state_v1';
  static const _backupKey = 'habit_companion_state_v1_corrupt_backup';

  Future<AppData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Do NOT silently discard a 3-week experiment's data. Preserve the
      // unreadable blob under a backup key so it can be recovered, then let
      // the caller decide. (fromJson is also tolerant of missing fields, so
      // we only land here on truly malformed JSON.)
      await prefs.setString(_backupKey, raw);
      return null;
    }
  }

  Future<void> save(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }
}
