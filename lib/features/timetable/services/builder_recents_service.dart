/// BuilderRecentsService
///
/// Persists subject+faculty+room combos entered in the Timetable Builder
/// so the user can re-select them as autocomplete suggestions.
///
/// Key design decisions:
/// - Stored in SharedPreferences (local, private to device).
/// - Independent from the timetable itself — deleting a slot from the
///   timetable does NOT remove the combo. Combos grow as the user uses the app.
/// - Up to [_kMaxRecents] entries are kept (oldest evicted first).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsKey = 'builder_subject_recents_v1';
const _kMaxRecents = 50;

class SubjectCombo {
  final String subject;
  final String? faculty;
  final String? room;
  final int savedAt; // epoch ms — for recency ordering

  const SubjectCombo({
    required this.subject,
    this.faculty,
    this.room,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'faculty': faculty,
        'room': room,
        'savedAt': savedAt,
      };

  factory SubjectCombo.fromJson(Map<String, dynamic> j) => SubjectCombo(
        subject: j['subject'] as String,
        faculty: j['faculty'] as String?,
        room: j['room'] as String?,
        savedAt: j['savedAt'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is SubjectCombo && other.subject == subject;

  @override
  int get hashCode => subject.hashCode;
}

class BuilderRecentsService {
  BuilderRecentsService._();
  static final BuilderRecentsService instance = BuilderRecentsService._();

  List<SubjectCombo> _recents = [];
  bool _loaded = false;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw != null) {
        final list = json.decode(raw) as List<dynamic>;
        _recents = list
            .map((e) => SubjectCombo.fromJson(e as Map<String, dynamic>))
            .toList();
        _recents.sort((a, b) => b.savedAt.compareTo(a.savedAt)); // newest first
      }
    } catch (e) {
      debugPrint('[Recents] load error: $e');
      _recents = [];
    }
    _loaded = true;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Call after the user saves a slot. Upserts the combo by subject name.
  Future<void> save(String subject, {String? faculty, String? room}) async {
    await ensureLoaded();

    final trimmed = subject.trim();
    if (trimmed.isEmpty) return;

    // Remove existing entry for this subject (to update recency)
    _recents.removeWhere((c) =>
        c.subject.toLowerCase() == trimmed.toLowerCase());

    // Insert at front
    _recents.insert(
      0,
      SubjectCombo(
        subject: trimmed,
        faculty: faculty?.trim().isEmpty == true ? null : faculty?.trim(),
        room: room?.trim().isEmpty == true ? null : room?.trim(),
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    // Evict old entries
    if (_recents.length > _kMaxRecents) {
      _recents = _recents.sublist(0, _kMaxRecents);
    }

    await _persist();
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  /// Returns combos whose subject starts with [query] (case-insensitive).
  /// Returns all if [query] is empty.
  List<SubjectCombo> search(String query) {
    if (!_loaded) return [];
    if (query.trim().isEmpty) return List.unmodifiable(_recents);
    final q = query.trim().toLowerCase();
    return _recents
        .where((c) => c.subject.toLowerCase().contains(q))
        .toList();
  }

  List<SubjectCombo> get all => List.unmodifiable(_recents);

  // ── Persist ───────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kPrefsKey, json.encode(_recents.map((c) => c.toJson()).toList()));
    } catch (e) {
      debugPrint('[Recents] persist error: $e');
    }
  }
}
