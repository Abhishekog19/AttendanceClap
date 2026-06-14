import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/subject_model.dart';

part 'local_cache_datasource.g.dart';

@riverpod
Future<LocalCacheDatasource> localCacheDatasource(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return LocalCacheDatasource(prefs);
}

class LocalCacheDatasource {
  final SharedPreferences _prefs;

  LocalCacheDatasource(this._prefs);

  static const _subjectsKey = 'cached_subjects';
  static const _userGoalKey = 'attendance_goal';
  static const _themeModeKey = 'theme_mode';

  // ─── Subjects Cache ──────────────────────────────────────────────────────────

  Future<void> cacheSubjects(List<SubjectModel> subjects) async {
    final json = subjects.map((s) => s.toJson()).toList();
    await _prefs.setString(_subjectsKey, jsonEncode(json));
  }

  List<SubjectModel>? getCachedSubjects() {
    final raw = _prefs.getString(_subjectsKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => SubjectModel.fromJson(
            item as Map<String, dynamic>, item['id'] as String? ?? ''))
        .toList();
  }

  Future<void> clearSubjectsCache() async {
    await _prefs.remove(_subjectsKey);
  }

  // ─── User Preferences ────────────────────────────────────────────────────────

  Future<void> saveAttendanceGoal(double goal) async {
    await _prefs.setDouble(_userGoalKey, goal);
  }

  double getAttendanceGoal() {
    return _prefs.getDouble(_userGoalKey) ?? 75.0;
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_themeModeKey) ?? 'system';
  }
}
