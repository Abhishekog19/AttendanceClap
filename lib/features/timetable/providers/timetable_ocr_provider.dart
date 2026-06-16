import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/timetable_entry_model.dart';
import '../services/timetable_gemini_service.dart';
import '../services/timetable_ml_service.dart';

export '../services/timetable_ml_service.dart' show TimetableOcrException;

part 'timetable_ocr_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Status enum — granular pipeline steps
// ─────────────────────────────────────────────────────────────────────────────

enum OcrStatus {
  idle,
  validating,
  convertingPdf, // PDF → images
  extracting, // ML Kit OCR
  parsing, // Groq AI
  success,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────────────────────

class OcrState {
  final OcrStatus status;
  final Map<String, List<TimetableEntry>> schedule; // day → entries
  final String? rawText;
  final String? errorMessage;
  final bool retryable;
  final File? lastFile; // stored so retry can re-run without repicking
  final int processingTimeMs;
  final int subjectCount;
  final int entryCount;
  final int lowConfidenceCount;
  // PDF multi-page progress
  final int currentPage;
  final int totalPages;

  const OcrState({
    this.status = OcrStatus.idle,
    this.schedule = const {},
    this.rawText,
    this.errorMessage,
    this.retryable = false,
    this.lastFile,
    this.processingTimeMs = 0,
    this.subjectCount = 0,
    this.entryCount = 0,
    this.lowConfidenceCount = 0,
    this.currentPage = 0,
    this.totalPages = 0,
  });

  bool get hasData => schedule.isNotEmpty;
  bool get hasLowConfidence => lowConfidenceCount > 0;
  bool get isProcessingPdf => status == OcrStatus.convertingPdf && totalPages > 0;

  OcrState copyWith({
    OcrStatus? status,
    Map<String, List<TimetableEntry>>? schedule,
    String? rawText,
    String? errorMessage,
    bool? retryable,
    File? lastFile,
    int? processingTimeMs,
    int? subjectCount,
    int? entryCount,
    int? lowConfidenceCount,
    int? currentPage,
    int? totalPages,
  }) {
    return OcrState(
      status: status ?? this.status,
      schedule: schedule ?? this.schedule,
      rawText: rawText ?? this.rawText,
      errorMessage: errorMessage ?? this.errorMessage,
      retryable: retryable ?? this.retryable,
      lastFile: lastFile ?? this.lastFile,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      subjectCount: subjectCount ?? this.subjectCount,
      entryCount: entryCount ?? this.entryCount,
      lowConfidenceCount: lowConfidenceCount ?? this.lowConfidenceCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
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

  List<TimetableEntry> get flatList =>
      state.values.expand((e) => e).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
//  OCR Notifier  (ML Kit / PDF → Groq pipeline)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class TimetableOcr extends _$TimetableOcr {
  @override
  OcrState build() => const OcrState();


  // ── Public entry points ───────────────────────────────────────────────────


  /// Main entry — auto-detects image vs PDF and processes accordingly.
  Future<void> processFile(File file) async {
    state = state.copyWith(
      lastFile: file,
      retryable: false,
      errorMessage: null,
    );

    final ext = file.path.toLowerCase();
    if (ext.endsWith('.pdf')) {
      await _processPdf(file);
    } else {
      await _processImage(file);
    }
  }

  /// Retry the last file (only valid if state.retryable == true).
  Future<void> retry() async {
    final file = state.lastFile;
    if (file == null) return;
    await processFile(file);
  }

  /// Load a schedule fetched from a share code directly into state.
  /// Pushes the provider to success so the review screen can open.
  void loadSharedSchedule(Map<String, List<TimetableEntry>> schedule) {
    ref.read(editedTimetableProvider.notifier).setAll(schedule);
    final all = schedule.values.expand((e) => e).toList();
    state = OcrState(
      status: OcrStatus.success,
      schedule: schedule,
      retryable: false,
      subjectCount: all.map((e) => e.subject).toSet().length,
      entryCount: all.length,
      processingTimeMs: 0,
    );
  }

  void reset() => state = const OcrState();

  // ── Image pipeline ────────────────────────────────────────────────────────

  Future<void> _processImage(File file) async {
    final stopwatch = Stopwatch()..start();

    // Step 1: Validate
    state = state.copyWith(status: OcrStatus.validating, errorMessage: null);
    if (!await file.exists()) {
      _setError('File not found. Please pick the image again.',
          retryable: false);
      return;
    }

    // Step 2+3: Gemini Vision → JSON (falls back to ML Kit+Groq if no key)
    state = state.copyWith(status: OcrStatus.extracting);

    try {
      final schedule = await TimetableGeminiService.instance.processImage(
        file,
        onGridBuilt: () {
          state = state.copyWith(status: OcrStatus.parsing);
        },
      );

      final allEntries = schedule.values.expand((e) => e).toList();
      final subjects = allEntries.map((e) => e.subject).toSet();
      final lowConf = allEntries.where((e) => e.isLowConfidence).length;

      ref.read(editedTimetableProvider.notifier).setAll(schedule);

      state = OcrState(
        status: OcrStatus.success,
        schedule: schedule,
        retryable: false,
        lastFile: state.lastFile,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        subjectCount: subjects.length,
        entryCount: allEntries.length,
        lowConfidenceCount: lowConf,
      );
    } on TimetableOcrException catch (e) {
      await _logCrashlytics(e, StackTrace.current, 'image_pipeline');
      _setError(e.message, retryable: true);
    } catch (e, st) {
      await _logCrashlytics(e, st, 'image_pipeline_unexpected');
      _setError('Processing failed. Please try a clearer image.',
          retryable: true);
    }
  }

  // ── PDF pipeline ──────────────────────────────────────────────────────────

  Future<void> _processPdf(File file) async {
    final stopwatch = Stopwatch()..start();

    state = state.copyWith(status: OcrStatus.validating, errorMessage: null);
    if (!await file.exists()) {
      _setError('PDF file not found. Please pick the file again.',
          retryable: false);
      return;
    }

    state = state.copyWith(status: OcrStatus.convertingPdf);

    try {
      final schedule = await TimetableGeminiService.instance.processPdf(
        file,
        onPageProgress: (current, total) {
          state = state.copyWith(
            status: OcrStatus.convertingPdf,
            currentPage: current,
            totalPages: total,
          );
        },
        onGridBuilt: () {
          state = state.copyWith(status: OcrStatus.parsing);
        },
      );

      final allEntries = schedule.values.expand((e) => e).toList();
      final subjects = allEntries.map((e) => e.subject).toSet();
      final lowConf = allEntries.where((e) => e.isLowConfidence).length;

      ref.read(editedTimetableProvider.notifier).setAll(schedule);

      state = OcrState(
        status: OcrStatus.success,
        schedule: schedule,
        retryable: false,
        lastFile: state.lastFile,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        subjectCount: subjects.length,
        entryCount: allEntries.length,
        lowConfidenceCount: lowConf,
      );
    } on TimetableOcrException catch (e) {
      await _logCrashlytics(e, StackTrace.current, 'pdf_pipeline');
      _setError(e.message, retryable: true);
    } catch (e, st) {
      await _logCrashlytics(e, st, 'pdf_pipeline_unexpected');
      _setError('PDF processing failed. Please try a different file.',
          retryable: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setError(String message, {required bool retryable}) {
    state = state.copyWith(
      status: OcrStatus.error,
      errorMessage: message,
      retryable: retryable,
    );
  }

  Future<void> _logCrashlytics(
      Object error, StackTrace stack, String reason) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'TimetableOcr: $reason',
        fatal: false,
      );
    } catch (_) {
      // Never crash due to Crashlytics itself
    }
  }

  // ── Legacy entry point (kept for backward compat) ─────────────────────────

  /// Processes an image file — calls [processFile] internally.
  Future<void> processImage(File file) => processFile(file);
}
