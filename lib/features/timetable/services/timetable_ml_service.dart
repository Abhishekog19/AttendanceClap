/// TimetableMlService
///
/// Pipeline:
///   1. Google ML Kit Text Recognition  → on-device OCR
///   2. Groq API (LLaMA 3.3 70B)        → structured JSON parsing
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/timetable_entry_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Groq config
// ─────────────────────────────────────────────────────────────────────────────

const _kGroqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
const _kGroqModel = 'llama-3.3-70b-versatile';

// ─────────────────────────────────────────────────────────────────────────────
//  System prompt — tuned for Indian engineering college timetables
// ─────────────────────────────────────────────────────────────────────────────

const _kSystemPrompt = '''
You are an expert academic timetable parser for Indian engineering colleges. Your job is to analyse OCR-extracted text from a printed timetable and return structured JSON.

UNDERSTANDING THE FORMAT:
- Timetables have a "Period No." column (1, 2, 3...) and a "Time" column (e.g., "08:00-09:00").
- Days are columns: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday.
- Each cell may have a subject code (e.g., "DSA", "VLSI", "IC", "MCA") and a teacher code (e.g., "/PY", "/SS").
- "(PR)" or "(H)" means practical/lab session.
- Subject legend/key at the bottom maps abbreviations to full names and teachers.
- Section codes like "E2-1", "E2-2" or "AM", "SS", "VB" are division sub-sections.
- "LUNCH BREAK" rows must be skipped.

WHAT TO DO:
1. Identify ALL unique time slots from the Time column (e.g., "08:00-09:00", "09:00-10:00").
2. For each day column, find what subject is taught in each time slot.
3. Expand abbreviations using the legend at the bottom if available.
4. For labs/practicals spanning multiple periods, create ONE entry with correct start+end.

OUTPUT RULES:
1. Return ONLY valid JSON — no markdown, no explanation, no code fences.
2. Schema:
{
  "Monday":    [ { "subject": "Full Subject Name", "startTime": "HH:MM", "endTime": "HH:MM", "faculty": "Prof. Name or null", "room": "room or null", "confidence": 0.0-1.0 } ],
  "Tuesday":   [...],
  "Wednesday": [...],
  "Thursday":  [...],
  "Friday":    [...],
  "Saturday":  [...],
  "Sunday":    []
}
3. Times in 24-hour HH:MM format (e.g., "08:00", "13:00").
4. confidence: 1.0 = clearly readable, 0.7 = inferred, 0.4 = uncertain.
5. Skip "LUNCH BREAK", "Break", "Free", "-" cells.
6. Days with no classes → empty array [].
7. Do NOT return empty arrays for all days if you can see subjects in the text.
''';

// ─────────────────────────────────────────────────────────────────────────────
//  Service
// ─────────────────────────────────────────────────────────────────────────────

class TimetableMlService {
  TimetableMlService._();
  static final TimetableMlService instance = TimetableMlService._();

  // ── Step 1: ML Kit OCR ────────────────────────────────────────────────────

  Future<String> extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText result = await recognizer.processImage(inputImage);

      if (result.text.trim().isEmpty) {
        throw const TimetableOcrException(
          'No text found in the image. '
          'Please ensure the timetable is clearly visible and well-lit.',
        );
      }

      debugPrint('[ML Kit] Raw text length: ${result.text.length} chars');
      debugPrint('[ML Kit] Blocks: ${result.blocks.length}');

      // ── Build spatially-sorted structured text ──────────────────────────
      // Collect all lines with their bounding boxes
      final allLines = <_MlLine>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          allLines.add(_MlLine(
            text: line.text,
            top: line.boundingBox.top.toDouble(),
            left: line.boundingBox.left.toDouble(),
            bottom: line.boundingBox.bottom.toDouble(),
          ));
        }
      }

      // Sort by actual pixel position (NOT compareTo — that returns -1/0/1)
      allLines.sort((a, b) {
        final yPixelDiff = a.top - b.top;
        // Same row = within 18px vertically
        if (yPixelDiff.abs() > 18) {
          return yPixelDiff < 0 ? -1 : 1;
        }
        // Same row: sort left to right
        final xPixelDiff = a.left - b.left;
        return xPixelDiff < 0 ? -1 : (xPixelDiff > 0 ? 1 : 0);
      });

      // Group into table rows (lines within 18px of each other vertically)
      final tableRows = <List<_MlLine>>[];
      List<_MlLine> currentRow = [];
      double? rowAnchorTop;

      for (final line in allLines) {
        if (rowAnchorTop == null || (line.top - rowAnchorTop).abs() <= 18) {
          currentRow.add(line);
          rowAnchorTop ??= line.top;
        } else {
          if (currentRow.isNotEmpty) tableRows.add(List.from(currentRow));
          currentRow = [line];
          rowAnchorTop = line.top;
        }
      }
      if (currentRow.isNotEmpty) tableRows.add(currentRow);

      // Build structured text: tab-separated columns, one line per row
      final structuredLines = tableRows
          .map((row) => row.map((l) => l.text.trim()).join('\t'))
          .where((line) => line.isNotEmpty)
          .toList();

      final structuredText = structuredLines.join('\n');

      debugPrint('[ML Kit] Structured rows: ${tableRows.length}');
      debugPrint('[ML Kit] Preview:\n${structuredText.substring(0, structuredText.length.clamp(0, 500))}');

      // Return both ML Kit's native text AND our structured version
      return '=== ML KIT RAW TEXT ===\n'
          '${result.text}\n\n'
          '=== SPATIALLY RECONSTRUCTED TABLE (tab=column, newline=row) ===\n'
          '$structuredText';
    } finally {
      recognizer.close();
    }
  }

  // ── Step 2: Groq API parsing ──────────────────────────────────────────────

  Future<Map<String, List<TimetableEntry>>> parseTextWithGroq(
      String rawText) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'your_groq_api_key_here') {
      throw const TimetableOcrException(
        'Groq API key not configured.\n'
        'Add your key to the .env file:\n'
        'GROQ_API_KEY=gsk_your_key_here\n\n'
        'Get a free key at: https://console.groq.com',
      );
    }

    final requestBody = json.encode({
      'model': _kGroqModel,
      'messages': [
        {'role': 'system', 'content': _kSystemPrompt},
        {
          'role': 'user',
          'content': 'Parse the following timetable OCR text into the JSON schema. '
              'The text contains the raw ML Kit output and a spatially-reconstructed table.\n\n'
              '$rawText\n\n'
              'Return ONLY the JSON object.',
        },
      ],
      'temperature': 0.1,
      'max_tokens': 8192,
      'response_format': {'type': 'json_object'},
    });

    try {
      debugPrint('[Groq] Sending request to Groq API…');
      final response = await http
          .post(
            Uri.parse(_kGroqBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('[Groq] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final content =
            data['choices'][0]['message']['content'] as String? ?? '';
        debugPrint('[Groq] Response length: ${content.length}');
        debugPrint('[Groq] Preview: ${content.substring(0, content.length.clamp(0, 300))}');
        return _parseGroqJson(content);
      } else if (response.statusCode == 401) {
        throw const TimetableOcrException(
            'Invalid Groq API key. Check GROQ_API_KEY in .env file.');
      } else if (response.statusCode == 429) {
        throw const TimetableOcrException(
            'Groq rate limit. Please wait a moment and try again.');
      } else {
        Map<String, dynamic>? err;
        try {
          err = json.decode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        throw TimetableOcrException(
            'Groq error ${response.statusCode}: '
            '${err?['error']?['message'] ?? response.body}');
      }
    } on TimetableOcrException {
      rethrow;
    } on SocketException {
      throw const TimetableOcrException(
          'No internet connection. Check your network and try again.');
    } catch (e) {
      throw TimetableOcrException('Groq request failed: $e');
    }
  }

  // ── Full pipeline ─────────────────────────────────────────────────────────

  Future<Map<String, List<TimetableEntry>>> processImage(File imageFile) async {
    final rawText = await extractTextFromImage(imageFile);
    final schedule = await parseTextWithGroq(rawText);
    return schedule;
  }

  // ── JSON parsing ──────────────────────────────────────────────────────────

  Map<String, List<TimetableEntry>> _parseGroqJson(String responseText) {
    String clean = responseText.trim();
    clean = clean.replaceAll(RegExp(r'```(?:json)?'), '').trim();

    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start == -1 || end == -1) {
      throw TimetableOcrException(
          'No JSON found in Groq response:\n'
          '${clean.substring(0, clean.length.clamp(0, 400))}');
    }
    clean = clean.substring(start, end + 1);

    late Map<String, dynamic> data;
    try {
      data = json.decode(clean) as Map<String, dynamic>;
    } catch (e) {
      throw TimetableOcrException('Invalid JSON from Groq: $e\n'
          'Response: ${clean.substring(0, clean.length.clamp(0, 300))}');
    }

    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];

    final result = <String, List<TimetableEntry>>{};
    int totalEntries = 0;

    for (final day in days) {
      final raw = (data[day] as List?) ?? [];
      final entries = <TimetableEntry>[];

      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        try {
          entries.add(TimetableEntry(
            subject: (e['subject'] as String? ?? 'Unknown').trim(),
            day: day,
            startTime: _normaliseTime(e['startTime'] as String? ?? '00:00'),
            endTime: _normaliseTime(e['endTime'] as String? ?? '00:00'),
            faculty: e['faculty'] as String?,
            room: e['room'] as String?,
            confidence: (e['confidence'] as num?)?.toDouble() ?? 0.8,
          ));
        } catch (ex) {
          debugPrint('[Parse] Skipping malformed entry $e: $ex');
        }
      }

      entries.sort((a, b) => a.startTime.compareTo(b.startTime));
      result[day] = entries;
      totalEntries += entries.length;
    }

    debugPrint('[Parse] Total entries extracted: $totalEntries');

    if (totalEntries == 0) {
      throw const TimetableOcrException(
        'Groq could not find any classes in the image.\n\n'
        'Tips:\n'
        '• Make sure the full timetable is visible\n'
        '• Try a higher resolution / better lit photo\n'
        '• Ensure the image is not rotated more than 45°',
      );
    }

    return result;
  }

  String _normaliseTime(String t) {
    final clean = t.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(clean);
    if (match != null) {
      final h = int.parse(match.group(1)!);
      final m = match.group(2)!;
      return '${h.toString().padLeft(2, '0')}:$m';
    }
    return '00:00';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Internal model for spatial sorting
// ─────────────────────────────────────────────────────────────────────────────

class _MlLine {
  final String text;
  final double top;
  final double left;
  final double bottom;
  const _MlLine({
    required this.text,
    required this.top,
    required this.left,
    required this.bottom,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Exception
// ─────────────────────────────────────────────────────────────────────────────

class TimetableOcrException implements Exception {
  final String message;
  const TimetableOcrException(this.message);

  @override
  String toString() => message;
}
