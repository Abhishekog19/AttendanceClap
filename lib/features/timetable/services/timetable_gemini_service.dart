/// Gemini Vision-based timetable parser.
///
/// Sends the raw image (base64) directly to Gemini 1.5 Flash which
/// understands the visual table layout — no ML Kit preprocessing needed.
/// Falls back to [TimetableMlService] if Gemini is unavailable.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../../data/models/timetable_entry_model.dart';
import 'timetable_ml_service.dart'; // for fallback + TimetableOcrException

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────

// Models tried in priority order. If the first fails (429/404), the next is used.
const _kGeminiModels = [
  'gemini-2.0-flash',
  'gemini-1.5-flash',
  'gemini-1.5-flash-8b',
];
const _kGeminiBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/models';
const _kMaxPdfPages = 10;

const _kAllDays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

// ─────────────────────────────────────────────────────────────────────────────
//  Prompt
// ─────────────────────────────────────────────────────────────────────────────

const _kPrompt = r'''
You are a college timetable parser. The image shows a weekly class timetable
for engineering / science students.

Your task: read EVERY cell of this timetable and return a JSON object.

RULES:
1. subject   → full name of the subject (expand abbreviations if clear from context).
               NEVER put a room code, teacher code, or batch label here.
2. faculty   → teacher identifier (/XY slash-prefix, or uppercase initials like SM, SSK, AGD).
               Full teacher name if written out. null if not present.
3. room      → lab or room code (Lab103, CR-14, WS-61, [604], Hall-2). null if not present.
4. startTime / endTime → 24-hour HH:MM strings derived from the column/row time header.
5. confidence → 1.0=clearly legible, 0.7=inferred from context/legend, 0.4=uncertain.
6. SKIP cells that are empty, contain only dashes "–", LUNCH, BREAK, RECESS, or FREE.
7. Multi-batch cells (multiple sub-groups in the SAME slot for the SAME day):
   Create ONE entry per batch. Append the distinguishing label to subject:
   e.g. "FAB Lab (B-1)", "FAB Lab (B-2)", "FAB Lab (B-3)".
   Priority for label: batch label > room code > teacher code.
8. If a legend/key table is visible at the bottom, use it to expand subject codes.

OUTPUT: a single raw JSON object (no markdown, no explanation):
{
  "Monday":    [{"subject":"…","startTime":"HH:MM","endTime":"HH:MM","faculty":"…or null","room":"…or null","confidence":1.0}],
  "Tuesday":   […],
  "Wednesday": […],
  "Thursday":  […],
  "Friday":    […],
  "Saturday":  […],
  "Sunday":    []
}
All seven day keys MUST be present. Use [] for days with no classes.
''';

// ─────────────────────────────────────────────────────────────────────────────
//  Service
// ─────────────────────────────────────────────────────────────────────────────

class TimetableGeminiService {
  TimetableGeminiService._();
  static final TimetableGeminiService instance = TimetableGeminiService._();

  // ── Public: image ─────────────────────────────────────────────────────────

  Future<Map<String, List<TimetableEntry>>> processImage(
    File imageFile, {
    VoidCallback? onGridBuilt,
  }) async {
    final key = _apiKey();
    if (key == null) {
      debugPrint('\n══════════════════════════════════════════');
      debugPrint('  🤖  OCR ENGINE: ML Kit + Groq (fallback)');
      debugPrint('  ⚠️   No GEMINI_API_KEY in .env');
      debugPrint('══════════════════════════════════════════\n');
      return TimetableMlService.instance
          .processImage(imageFile, onGridBuilt: onGridBuilt);
    }

    final bytes = await imageFile.readAsBytes();
    final mime = _mimeType(imageFile.path);

    debugPrint('\n══════════════════════════════════════════');
    debugPrint('  ✨  OCR ENGINE: Gemini Vision');
    debugPrint('  📷  file: ${imageFile.path.split("/").last}');
    debugPrint('  📦  size: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
    debugPrint('  🌐  models: ${_kGeminiModels.join(" → ")}');
    debugPrint('══════════════════════════════════════════\n');

    onGridBuilt?.call(); // signal "parsing" status immediately

    try {
      return await _callGemini(bytes, mime, key);
    } catch (e) {
      debugPrint('[Gemini] ❌ error=$e  → falling back to ML Kit + Groq');
      return TimetableMlService.instance
          .processImage(imageFile, onGridBuilt: onGridBuilt);
    }
  }

  // ── Public: PDF ───────────────────────────────────────────────────────────

  Future<Map<String, List<TimetableEntry>>> processPdf(
    File pdfFile, {
    void Function(int, int)? onPageProgress,
    VoidCallback? onGridBuilt,
  }) async {
    // Render the first page to an image and send it to Gemini.
    // Most timetables fit on one page; if multi-page, process each and merge.
    final key = _apiKey();
    if (key == null) {
      return TimetableMlService.instance.processPdf(
        pdfFile,
        onPageProgress: onPageProgress,
        onGridBuilt: onGridBuilt,
      );
    }

    final tmp = await getTemporaryDirectory();
    final tmpFiles = <File>[];
    PdfDocument? doc;
    final pageResults = <Map<String, List<TimetableEntry>>>[];

    try {
      doc = await PdfDocument.openFile(pdfFile.path);
      final n = doc.pagesCount.clamp(1, _kMaxPdfPages);

      for (int i = 1; i <= n; i++) {
        onPageProgress?.call(i, n);
        final page = await doc.getPage(i);
        try {
          final img = await page.render(
            width: page.width * 2.0,
            height: page.height * 2.0,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
          );
          if (img == null || img.bytes.isEmpty) continue;

          final f = File('${tmp.path}/gemini_p$i.jpg');
          await f.writeAsBytes(img.bytes);
          tmpFiles.add(f);

          try {
            final result =
                await _callGemini(img.bytes, 'image/jpeg', key);
            pageResults.add(result);
          } catch (e) {
            debugPrint('[Gemini] PDF page $i error: $e');
          }
        } finally {
          await page.close();
        }
      }
    } finally {
      await doc?.close();
      for (final f in tmpFiles) {
        try { await f.delete(); } catch (_) {}
      }
    }

    if (pageResults.isEmpty) {
      return TimetableMlService.instance.processPdf(
        pdfFile,
        onPageProgress: onPageProgress,
        onGridBuilt: onGridBuilt,
      );
    }

    onGridBuilt?.call();

    // Merge results from all pages (later pages override earlier for same day)
    final merged = <String, List<TimetableEntry>>{
      for (final d in _kAllDays) d: [],
    };
    for (final r in pageResults) {
      for (final day in _kAllDays) {
        if (r[day]?.isNotEmpty ?? false) {
          merged[day] = r[day]!;
        }
      }
    }
    return merged;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Gemini API call
  // ─────────────────────────────────────────────────────────────────────────

  // Tries each model in _kGeminiModels until one succeeds.
  Future<Map<String, List<TimetableEntry>>> _callGemini(
    List<int> imageBytes,
    String mimeType,
    String apiKey, {
    int modelIndex = 0,
  }) async {
    if (modelIndex >= _kGeminiModels.length) {
      throw const TimetableOcrException(
          'All Gemini models exhausted (quota or not available).');
    }

    final model = _kGeminiModels[modelIndex];
    final url = '$_kGeminiBaseUrl/$model:generateContent?key=$apiKey';

    final base64Data = base64Encode(imageBytes);
    final body = json.encode({
      'contents': [
        {
          'parts': [
            {'text': _kPrompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Data,
              }
            },
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
      },
    });

    debugPrint('[Gemini] 🚀 trying model=$model …');
    http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));
    } on SocketException {
      throw const TimetableOcrException('No internet connection.');
    } on http.ClientException catch (e) {
      throw TimetableOcrException('Network error: $e');
    }

    debugPrint('[Gemini] ✅ status=${resp.statusCode} model=$model');

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final content = (data['candidates'] as List?)
              ?.firstOrNull?['content']?['parts']
              ?.firstOrNull?['text'] as String? ??
          '';
      debugPrint('[Gemini] preview: '
          '${content.substring(0, content.length.clamp(0, 200))}');
      return _parseJson(content);
    } else if ((resp.statusCode == 429 || resp.statusCode == 404)) {
      // This model unavailable or quota exhausted — try next model
      debugPrint('[Gemini] ⚠️ $model: status=${resp.statusCode}, trying next model…');
      return _callGemini(imageBytes, mimeType, apiKey,
          modelIndex: modelIndex + 1);
    } else {
      Map<String, dynamic>? err;
      try { err = json.decode(resp.body) as Map<String, dynamic>; } catch (_) {}
      throw TimetableOcrException(
          'Gemini error ${resp.statusCode}: '
          '${err?['error']?['message'] ?? resp.body}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  JSON parsing (same shape as Groq output)
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, List<TimetableEntry>> _parseJson(String text) {
    var clean = text.trim().replaceAll(RegExp(r'```(?:json)?'), '').trim();
    final s = clean.indexOf('{');
    final e = clean.lastIndexOf('}');
    if (s == -1 || e == -1) {
      throw TimetableOcrException(
          'No JSON in Gemini response:\n'
          '${clean.substring(0, clean.length.clamp(0, 400))}');
    }
    clean = clean.substring(s, e + 1);

    late Map<String, dynamic> data;
    try {
      data = json.decode(clean) as Map<String, dynamic>;
    } catch (ex) {
      throw TimetableOcrException('Invalid JSON from Gemini: $ex');
    }

    final result = <String, List<TimetableEntry>>{};
    int total = 0;

    for (final day in _kAllDays) {
      final raw = (data[day] as List?) ?? [];
      final entries = <TimetableEntry>[];

      for (final entry in raw) {
        if (entry is! Map<String, dynamic>) continue;
        try {
          final subj = (entry['subject'] as String? ?? '').trim();
          if (_isPlaceholder(subj)) continue;
          entries.add(TimetableEntry(
            subject: subj,
            day: day,
            startTime: _normTime(entry['startTime'] as String? ?? ''),
            endTime: _normTime(entry['endTime'] as String? ?? ''),
            faculty: _clean(entry['faculty'] as String?),
            room: _clean(entry['room'] as String?),
            confidence: (entry['confidence'] as num?)?.toDouble() ?? 0.9,
          ));
        } catch (_) {}
      }

      entries.sort((a, b) => a.startTime.compareTo(b.startTime));
      result[day] = entries;
      total += entries.length;
    }

    debugPrint('\n══════════════════════════════════════════');
    debugPrint('  ✨  Gemini parsed $total entries across ${result.values.where((v) => v.isNotEmpty).length} days');
    debugPrint('══════════════════════════════════════════\n');

    if (total == 0) {
      throw const TimetableOcrException(
          'Gemini found no classes in the image.\n\n'
          '• Make sure the full timetable is visible\n'
          '• Try a clearer, well-lit photo');
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String? _apiKey() {
    final k = dotenv.env['GEMINI_API_KEY'] ?? '';
    return (k.isEmpty || k == 'your_gemini_api_key_here') ? null : k;
  }

  String _mimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

  bool _isPlaceholder(String s) {
    if (s.isEmpty) return true;
    if (RegExp(r'^[\-–—\s]+$').hasMatch(s)) return true;
    final rx = RegExp(r'\b(lunch|break|recess|free)\b', caseSensitive: false);
    return rx.hasMatch(s);
  }

  String? _clean(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty || t == 'null' || RegExp(r'^[\-–—]+$').hasMatch(t)) {
      return null;
    }
    return t;
  }

  String _normTime(String t) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t.trim());
    if (m != null) {
      return '${int.parse(m.group(1)!).toString().padLeft(2, '0')}:${m.group(2)}';
    }
    return '00:00';
  }
}
