/// TimetableShareService
///
/// Upload a parsed timetable to Firestore under a 6-char code.
/// Other students enter the code to download the same timetable instantly.
library;

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/timetable_entry_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Firestore schema
//
//  /shared_timetables/{code}
//    code        : String   (same as doc ID, uppercase alphanumeric)
//    schedule    : Map      (day → List<Map>)
//    division    : String?  optional e.g. "FYCM-2"
//    college     : String?  optional
//    createdAt   : Timestamp
//    expiresAt   : Timestamp (createdAt + 30 days)
//    shareCount  : int
// ─────────────────────────────────────────────────────────────────────────────

class TimetableShareService {
  TimetableShareService._();
  static final TimetableShareService instance = TimetableShareService._();

  static const _kCollection = 'shared_timetables';
  static const _kCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no O/0/I/1

  // ── Upload ────────────────────────────────────────────────────────────────

  /// Uploads [schedule] and returns the generated 6-char share code.
  Future<String> upload(
    Map<String, List<TimetableEntry>> schedule, {
    String? division,
    String? college,
  }) async {
    final code = _generateCode();
    final now = DateTime.now();
    final expires = now.add(const Duration(days: 30));

    // Serialise schedule: day → List<Map>
    final scheduleMap = <String, dynamic>{};
    for (final entry in schedule.entries) {
      scheduleMap[entry.key] = entry.value
          .map((e) => e.toMap()..remove('id'))
          .toList();
    }

    await FirebaseFirestore.instance
        .collection(_kCollection)
        .doc(code)
        .set({
      'code': code,
      'schedule': scheduleMap,
      if (division != null && division.isNotEmpty) 'division': division,
      if (college != null && college.isNotEmpty) 'college': college,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expires),
      'shareCount': 0,
    });

    debugPrint('[Share] uploaded code=$code');
    return code;
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  /// Fetches the schedule for [code].
  ///
  /// Throws [ShareCodeException] if not found or expired.
  Future<({Map<String, List<TimetableEntry>> schedule, String? division, String? college})>
      fetch(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != 6) {
      throw const ShareCodeException('Enter a 6-character code.');
    }

    final doc = await FirebaseFirestore.instance
        .collection(_kCollection)
        .doc(code)
        .get();

    if (!doc.exists || doc.data() == null) {
      throw ShareCodeException('Code "$code" not found. Check and try again.');
    }

    final data = doc.data()!;

    // Check expiry
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      throw ShareCodeException(
          'Code "$code" has expired (codes are valid for 30 days).');
    }

    // Increment share count (best-effort, don't block on it)
    doc.reference.update({'shareCount': FieldValue.increment(1)}).ignore();

    // Deserialise
    final rawSchedule = (data['schedule'] as Map<String, dynamic>?) ?? {};
    final schedule = <String, List<TimetableEntry>>{};

    for (final day in [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ]) {
      final rawList = (rawSchedule[day] as List?) ?? [];
      schedule[day] = rawList
          .whereType<Map<String, dynamic>>()
          .map((m) {
        try {
          return TimetableEntry(
            subject: m['subject'] as String? ?? '',
            day: day,
            startTime: m['startTime'] as String? ?? '00:00',
            endTime: m['endTime'] as String? ?? '00:00',
            faculty: m['faculty'] as String?,
            room: m['room'] as String?,
            confidence: (m['confidence'] as num?)?.toDouble() ?? 1.0,
          );
        } catch (_) {
          return null;
        }
      })
          .whereType<TimetableEntry>()
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    debugPrint('[Share] fetched code=$code  entries='
        '${schedule.values.expand((e) => e).length}');

    return (
      schedule: schedule,
      division: data['division'] as String?,
      college: data['college'] as String?,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _generateCode() {
    final rng = Random.secure();
    return List.generate(
      6,
      (_) => _kCodeChars[rng.nextInt(_kCodeChars.length)],
    ).join();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Exception
// ─────────────────────────────────────────────────────────────────────────────

class ShareCodeException implements Exception {
  final String message;
  const ShareCodeException(this.message);
  @override
  String toString() => message;
}
