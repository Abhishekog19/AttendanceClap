import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/timetable_entry_model.dart';
import '../services/timetable_ml_service.dart';

export '../services/timetable_ml_service.dart' show TimetableOcrException;

part 'timetable_ocr_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────────────────────

enum OcrStatus { idle, extracting, parsing, success, error }

class OcrState {
  final OcrStatus status;
  final Map<String, List<TimetableEntry>> schedule; // day → entries
  final String? rawText;
  final String? errorMessage;
  final int processingTimeMs;
  final int subjectCount;
  final int entryCount;
  final int lowConfidenceCount;

  const OcrState({
    this.status = OcrStatus.idle,
    this.schedule = const {},
    this.rawText,
    this.errorMessage,
    this.processingTimeMs = 0,
    this.subjectCount = 0,
    this.entryCount = 0,
    this.lowConfidenceCount = 0,
  });

  bool get hasData => schedule.isNotEmpty;
  bool get hasLowConfidence => lowConfidenceCount > 0;

  OcrState copyWith({
    OcrStatus? status,
    Map<String, List<TimetableEntry>>? schedule,
    String? rawText,
    String? errorMessage,
    int? processingTimeMs,
    int? subjectCount,
    int? entryCount,
    int? lowConfidenceCount,
  }) {
    return OcrState(
      status: status ?? this.status,
      schedule: schedule ?? this.schedule,
      rawText: rawText ?? this.rawText,
      errorMessage: errorMessage ?? this.errorMessage,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      subjectCount: subjectCount ?? this.subjectCount,
      entryCount: entryCount ?? this.entryCount,
      lowConfidenceCount: lowConfidenceCount ?? this.lowConfidenceCount,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Edited timetable (user edits on the review screen)
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class EditedTimetable extends _$EditedTimetable {
  @override
  Map<String, List<TimetableEntry>> build() => {};

  void setAll(Map<String, List<TimetableEntry>> schedule) {
    state = Map.from(schedule);
  }

  void updateEntry(String day, int index, TimetableEntry updated) {
    final current = Map<String, List<TimetableEntry>>.from(state);
    final dayEntries = List<TimetableEntry>.from(current[day] ?? []);
    dayEntries[index] = updated;
    current[day] = dayEntries;
    state = current;
  }

  void removeEntry(String day, int index) {
    final current = Map<String, List<TimetableEntry>>.from(state);
    final dayEntries = List<TimetableEntry>.from(current[day] ?? []);
    dayEntries.removeAt(index);
    current[day] = dayEntries;
    state = current;
  }

  void addEntry(TimetableEntry entry) {
    final current = Map<String, List<TimetableEntry>>.from(state);
    final dayEntries = List<TimetableEntry>.from(current[entry.day] ?? []);
    dayEntries.add(entry);
    dayEntries.sort((a, b) => a.startTime.compareTo(b.startTime));
    current[entry.day] = dayEntries;
    state = current;
  }

  List<TimetableEntry> get flatList => state.values.expand((e) => e).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
//  OCR Notifier  (ML Kit → Gemini pipeline)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class TimetableOcr extends _$TimetableOcr {
  @override
  OcrState build() => const OcrState();

  final _service = TimetableMlService.instance;

  /// Main entry point — processes an image file through the full pipeline.
  Future<void> processImage(File file) async {
    final stopwatch = Stopwatch()..start();

    // ── Step 1: ML Kit OCR ─────────────────────────────────────────────────
    state = state.copyWith(
      status: OcrStatus.extracting,
      errorMessage: null,
    );

    late String rawText;
    try {
      rawText = await _service.extractTextFromImage(file);
    } on TimetableOcrException catch (e) {
      state = state.copyWith(
        status: OcrStatus.error,
        errorMessage: e.message,
      );
      return;
    } catch (e) {
      state = state.copyWith(
        status: OcrStatus.error,
        errorMessage: 'ML Kit error: $e',
      );
      return;
    }

    // ── Step 2: Groq parsing ───────────────────────────────────────────────
    state = state.copyWith(status: OcrStatus.parsing);

    try {
      final schedule = await _service.parseTextWithGroq(rawText);

      final allEntries = schedule.values.expand((e) => e).toList();
      final subjects = allEntries.map((e) => e.subject).toSet();
      final lowConf = allEntries.where((e) => e.isLowConfidence).length;

      state = OcrState(
        status: OcrStatus.success,
        schedule: schedule,
        rawText: rawText,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        subjectCount: subjects.length,
        entryCount: allEntries.length,
        lowConfidenceCount: lowConf,
      );
    } on TimetableOcrException catch (e) {
      state = state.copyWith(
        status: OcrStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: OcrStatus.error,
        errorMessage: 'Parsing error: $e',
      );
    }
  }

  void reset() => state = const OcrState();
}
