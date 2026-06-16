/// TimetableMlService
///
/// Algorithm (vertical layout):
///   • Day assignment  → X BANDS (midpoint between consecutive day-header centres)
///   • Slot assignment → Y RANGE BANDS (label.top → nextLabel.top)
///     ─ uses TIME LABEL TOPS as row boundaries, NOT nearest-neighbour
///     ─ so "SM SSK JS" printed below "FAB LAB" in the same visual row stays
///       in the same slot, not the next one
///   • Table bottom cutoff = lastSlotLabel.top + 1.3 × avgSlotHeight
///     ─ legend / attribution text below the cutoff is collected separately,
///       never assigned to any slot
///   • Sub-rows within a cell: detected by Y-gap between consecutive tokens
///     ─ produces "Lab103 Lab102 LabFC | /PY /AN SM | B-1 B-2 B-3"
///     ─ Groq resolves 3 batches from that
///
/// Horizontal layout is symmetric (swap X↔Y roles).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../../data/models/timetable_entry_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kGroqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
const _kGroqModel = 'llama-3.3-70b-versatile';
const _kMaxPdfPages = 10;
const _kDaysPerBatch = 2;

const _kAllDays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// "08:00-09:00", "8:00–9:00", "8.00-9.00"
final _kTimeRx = RegExp(
  r'\b(\d{1,2})[:.h](\d{2})\s*[-–—]+\s*(\d{1,2})[:.h](\d{2})\b',
);

/// Y-gap (px) between token bottoms that marks a new visual sub-row inside a cell.
const _kSubRowGapPx = 16.0;

// ─────────────────────────────────────────────────────────────────────────────
//  Groq prompt
// ─────────────────────────────────────────────────────────────────────────────

const _kPrompt = r'''
You parse college timetable data for an attendance app.

INPUT FORMAT — one line per time-slot:
  TIME HH:MM-HH:MM | DayName: cell | DayName: cell | ...
  "-" or empty = no class. Cells with " | " inside contain parallel batch entries.

HOW TO READ A CELL:
  • Subject code or name  →  expand via LEGEND (if present). Put in "subject".
  • Teacher identifier    →  /XY, /ABCD (slash-prefix) OR uppercase initials (SM, SSK, AGD).
                             Put in "faculty". NEVER in "subject" or "room".
  • Room / lab code       →  word+number: Lab103, CR-14, WS-61, [604], Hall-2.
                             Put in "room". NEVER in "subject".
  • Batch label           →  B-1, B-2, G1, Batch-A, or division sub-code (EXTC-2-1).

PARALLEL BATCHES (" | " separator inside a cell):
  Create ONE TimetableEntry per sub-entry. All share the same startTime / endTime.
  Append the distinguishing part to the subject name:
    Priority: batch label  >  room code  >  teacher code
  Example sub-entries "Lab103 /PY B-1 | Lab102 /AN B-2 | LabFC SM B-3" →
    {"subject":"FAB Lab (B-1)","faculty":"/PY","room":"Lab103",...}
    {"subject":"FAB Lab (B-2)","faculty":"/AN","room":"Lab102",...}
    {"subject":"FAB Lab (B-3)","faculty":"SM","room":"LabFC",...}

MULTIPLE TEACHER CODES with NO explicit subject (e.g. "SM SSK JS"):
  These are batch-wise professors for a practical/lab session.
  Use the LEGEND to determine the subject. Create one entry per code.

SKIP: cells "-", blank, LUNCH, BREAK, RECESS, FREE, or dashes only.
TIMES: 24-hour HH:MM.
CONFIDENCE: 1.0=clearly legible, 0.7=legend-inferred, 0.4=uncertain.

OUTPUT — raw JSON only, no markdown:
{"Monday":[{"subject":"…","startTime":"HH:MM","endTime":"HH:MM","faculty":"…or null","room":"…or null","confidence":1.0}],"Tuesday":[…],…,"Sunday":[]}
All 7 days must appear ([] if no classes that day).
''';

// ─────────────────────────────────────────────────────────────────────────────
//  Service
// ─────────────────────────────────────────────────────────────────────────────

class TimetableMlService {
  TimetableMlService._();
  static final TimetableMlService instance = TimetableMlService._();

  // ── Public: image ─────────────────────────────────────────────────────────

  Future<Map<String, List<TimetableEntry>>> processImage(
    File imageFile, {
    VoidCallback? onGridBuilt,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    late RecognizedText ocr;
    try {
      ocr = await recognizer.processImage(inputImage);
    } finally {
      recognizer.close();
    }

    if (ocr.text.trim().isEmpty) {
      throw const TimetableOcrException(
        'No text found in the image.\n'
        'Ensure the timetable is clearly visible and well-lit.',
      );
    }

    debugPrint('[OCR] chars=${ocr.text.length}  blocks=${ocr.blocks.length}');

    final structured = _buildStructuredText(ocr);
    debugPrint('[OCR] ===== STRUCTURED TEXT =====\n$structured\n=====');

    onGridBuilt?.call();
    return _groqParse(structured, _kAllDays);
  }

  // ── Public: PDF ───────────────────────────────────────────────────────────

  Future<Map<String, List<TimetableEntry>>> processPdf(
    File pdfFile, {
    void Function(int, int)? onPageProgress,
    VoidCallback? onGridBuilt,
  }) async {
    final raw =
        await extractTextFromPdf(pdfFile, onPageProgress: onPageProgress);
    onGridBuilt?.call();
    return _groqParse(raw, _kAllDays);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Structured text builder
  // ─────────────────────────────────────────────────────────────────────────

  String _buildStructuredText(RecognizedText ocr) {
    // ── 1. Collect all ML Kit lines with full bounding boxes ───────────────
    final all = <_Ln>[];
    for (final block in ocr.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isEmpty) continue;
        final b = line.boundingBox;
        all.add(_Ln(
          text: t,
          top: b.top.toDouble(),
          left: b.left.toDouble(),
          bottom: b.bottom.toDouble(),
          right: b.right.toDouble(),
        ));
      }
    }
    if (all.isEmpty) return ocr.text;

    // ── 2. Find day headers and their pixel positions ──────────────────────
    final dayPos = <String, _DayPos>{};
    for (final ln in all) {
      final d = _matchDay(ln.text);
      if (d != null && !dayPos.containsKey(d)) {
        dayPos[d] = _DayPos(
          cx: (ln.left + ln.right) / 2,
          cy: (ln.top + ln.bottom) / 2,
          left: ln.left,
          top: ln.top,
        );
      }
    }
    debugPrint('[OCR] days: ${dayPos.keys.join(', ')}');
    if (dayPos.isEmpty) {
      debugPrint('[OCR] no day headers → raw fallback');
      return _rawFallback(all);
    }

    // ── 3. Detect orientation ──────────────────────────────────────────────
    final cxs = dayPos.values.map((p) => p.cx).toList();
    final cys = dayPos.values.map((p) => p.cy).toList();
    final xSpread = cxs.reduce(math.max) - cxs.reduce(math.min);
    final ySpread = cys.reduce(math.max) - cys.reduce(math.min);
    final isH = ySpread > xSpread * 1.3; // horizontal if days stacked vertically
    debugPrint('[OCR] layout=${isH ? 'horizontal' : 'vertical'}'
        '  xSpread=${xSpread.toInt()}  ySpread=${ySpread.toInt()}');

    // ── 4. Sort days in reading order ──────────────────────────────────────
    final ordDays = dayPos.keys.toList()
      ..sort((a, b) => isH
          ? dayPos[a]!.cy.compareTo(dayPos[b]!.cy) // top→bottom for horiz
          : dayPos[a]!.cx.compareTo(dayPos[b]!.cx)); // left→right for vert
    debugPrint('[OCR] order: $ordDays');

    // ── 5. Compute day BANDS in the primary axis (X for vert, Y for horiz) ─
    //
    // PRIMARY axis = axis along which day headers are spread.
    //   Vertical:   days spread LEFT→RIGHT  →  primary = X
    //   Horizontal: days spread TOP→BOTTOM  →  primary = Y
    //
    // First band starts at the LEFT EDGE of the first day header text
    // (not 0!) so that the period-number and time-label columns are excluded.
    //
    final dayBands = <String, ({double lo, double hi})>{};
    for (int i = 0; i < ordDays.length; i++) {
      final d = ordDays[i];
      final centre = isH ? dayPos[d]!.cy : dayPos[d]!.cx;
      final edge   = isH ? dayPos[d]!.top : dayPos[d]!.left;

      final lo = i == 0
          ? edge - 5  // start at actual header left/top edge
          : (centre +
                  (isH
                      ? dayPos[ordDays[i - 1]]!.cy
                      : dayPos[ordDays[i - 1]]!.cx)) /
              2;

      final hi = i == ordDays.length - 1
          ? double.infinity
          : (centre +
                  (isH
                      ? dayPos[ordDays[i + 1]]!.cy
                      : dayPos[ordDays[i + 1]]!.cx)) /
              2;

      dayBands[d] = (lo: lo, hi: hi);
    }

    // ── 6. Find time-slot labels and their positions ───────────────────────
    //
    // SECONDARY axis = axis along which time labels are spread.
    //   Vertical:   time labels TOP→BOTTOM  →  secondary = Y
    //   Horizontal: time labels LEFT→RIGHT  →  secondary = X
    //
    // For each slot we record labelStart = the leading edge of the time label
    // in the secondary axis. This becomes the ROW BOUNDARY:
    //   slot[i] covers: [labelStart[i], labelStart[i+1])
    //
    final slots = <_Slot>[];

    // For VERTICAL layout: time labels live in the leftmost column, to the LEFT
    // of the first day header. Any time-like text found INSIDE a day column
    // (e.g. in the legend) must be ignored.
    // For HORIZONTAL layout: time labels live in the topmost row, ABOVE the
    // first day header.
    final timeColMax = isH
        ? (dayPos[ordDays.first]!.top - 10)     // horizontal: above first day top
        : (dayPos[ordDays.first]!.left - 2);    // vertical: left of first day left

    for (final ln in all) {
      final m = _kTimeRx.firstMatch(ln.text);
      if (m == null || _isBreak(ln.text)) continue;

      // ── Column filter: reject time labels that are inside day columns ──
      final primaryCenter = isH
          ? (ln.top + ln.bottom) / 2   // horiz: Y centre
          : (ln.left + ln.right) / 2;  // vert:  X centre
      if (primaryCenter > timeColMax) continue; // inside content area — skip

      final st = _fmtTime(m.group(1)!, m.group(2)!);
      final et = _fmtTime(m.group(3)!, m.group(4)!);
      if (st == '00:00') continue;
      if (slots.any((s) => s.startTime == st)) continue; // deduplicate
      slots.add(_Slot(
        startTime: st,
        endTime: et,
        labelStart: isH ? ln.left : ln.top,
        labelEnd:   isH ? ln.right : ln.bottom,
      ));
    }

    // Sort by PHYSICAL POSITION first (needed for correct avgSlotH & rangeEnd).
    slots.sort((a, b) => a.labelStart.compareTo(b.labelStart));
    debugPrint('[OCR] slots (by pos): '
        '${slots.map((s) => '${s.startTime}@${s.labelStart.toInt()}').join(' ')}');
    if (slots.isEmpty) {
      debugPrint('[OCR] no time slots → raw fallback');
      return _rawFallback(all);
    }

    // ── 7. Compute average slot height and table-bottom cutoff ─────────────
    double avgH = 60.0;
    if (slots.length >= 2) {
      double sum = 0;
      for (int i = 1; i < slots.length; i++) {
        sum += slots[i].labelStart - slots[i - 1].labelStart;
      }
      avgH = sum / (slots.length - 1);
    }
    // Hard cutoff: legend / attribution below the last slot doesn't get assigned
    final tableCutoff = slots.last.labelStart + avgH * 1.3;
    debugPrint('[OCR] avgSlotH=${avgH.toInt()}  cutoff=${tableCutoff.toInt()}');

    // ── 8. Assign slot Y-range boundaries ─────────────────────────────────
    for (int i = 0; i < slots.length; i++) {
      slots[i].rangeStart = slots[i].labelStart;
      slots[i].rangeEnd   = i < slots.length - 1
          ? slots[i + 1].labelStart  // row ends where next time label begins
          : tableCutoff;
    }

    // ── 9. Header-band cutoff ──────────────────────────────────────────────
    // Anything above (or touching) the day-header row is a label, not content.
    final headerBottom = (isH
            ? dayPos.values.map((p) => p.cx).reduce(math.max)
            : dayPos.values.map((p) => p.cy).reduce(math.max)) +
        20;

    // Minimum primary coord: left/top edge of the first day column
    final contentMinPrimary =
        (isH ? dayPos[ordDays.first]!.top : dayPos[ordDays.first]!.left) - 5;

    // ── 10. Extract legend (below table cutoff) ────────────────────────────
    final legendLines = <String>[];
    for (final ln in all) {
      final sec = isH
          ? (ln.left + ln.right) / 2
          : (ln.top + ln.bottom) / 2; // secondary axis centre
      if (sec <= tableCutoff) continue;
      if (_matchDay(ln.text) != null) continue;
      if (_kTimeRx.hasMatch(ln.text)) continue;
      if (_isSkip(ln.text)) continue;
      legendLines.add(ln.text);
    }

    // ── 11. Build cell map ─────────────────────────────────────────────────
    final cells = <String, Map<String, List<_Ln>>>{};
    for (final d in ordDays) {
      cells[d] = {for (final s in slots) s.startTime: []};
    }

    for (final ln in all) {
      // Skip known label types
      if (_matchDay(ln.text) != null) continue;
      if (_kTimeRx.hasMatch(ln.text)) continue;
      if (_isBreak(ln.text)) continue;
      if (_isSkip(ln.text)) continue;

      final pri = isH                              // primary: Y for horiz, X for vert
          ? (ln.top + ln.bottom) / 2
          : (ln.left + ln.right) / 2;
      final sec = isH                              // secondary: X for horiz, Y for vert
          ? (ln.left + ln.right) / 2
          : (ln.top + ln.bottom) / 2;

      // Skip header band (day-name row/column)
      if (isH ? pri < headerBottom : sec < headerBottom) continue;

      // Skip time / period column (primary coord before first day header)
      if (pri < contentMinPrimary) continue;

      // Skip legend / attribution area
      if (sec > tableCutoff) continue;

      // Find day band
      String? day;
      for (final d in ordDays) {
        final b = dayBands[d]!;
        if (pri >= b.lo && pri < b.hi) {
          day = d;
          break;
        }
      }
      if (day == null) continue;

      // Find slot by RANGE (not nearest-neighbour)
      _Slot? slot;
      for (final s in slots) {
        if (sec >= s.rangeStart && sec < s.rangeEnd) {
          slot = s;
          break;
        }
      }
      if (slot == null) continue;

      cells[day]![slot.startTime]!.add(ln);
    }

    // ── 12. Format output ──────────────────────────────────────────────────
    final sb = StringBuffer();

    if (legendLines.isNotEmpty) {
      sb.writeln('LEGEND: ${legendLines.join(' | ')}');
      sb.writeln();
    }

    for (final slot in slots) {
      final row = <String>['TIME ${slot.startTime}-${slot.endTime}'];

      for (final day in ordDays) {
        final lns = cells[day]![slot.startTime]!;
        if (lns.isEmpty) {
          row.add('$day: -');
          continue;
        }

        // Sort by secondary axis (Y for vert, X for horiz) → top-to-bottom
        lns.sort((a, b) => isH
            ? a.left.compareTo(b.left)
            : a.top.compareTo(b.top));

        // Split into sub-rows by gap in secondary axis
        final subRows = <List<_Ln>>[[lns.first]];
        for (int i = 1; i < lns.length; i++) {
          final gap = isH
              ? lns[i].left - lns[i - 1].right
              : lns[i].top - lns[i - 1].bottom;
          if (gap > _kSubRowGapPx) {
            subRows.add([]);
          }
          subRows.last.add(lns[i]);
        }

        // Within each sub-row sort by primary axis (left-to-right)
        final cellText = subRows.map((sr) {
          sr.sort((a, b) => isH
              ? a.top.compareTo(b.top)
              : a.left.compareTo(b.left));
          return sr.map((l) => l.text).join(' ');
        }).join(' | ');

        row.add('$day: $cellText');
      }

      sb.writeln(row.join(' | '));
    }

    return sb.toString().trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Raw fallback
  // ─────────────────────────────────────────────────────────────────────────

  String _rawFallback(List<_Ln> lines) {
    lines.sort((a, b) {
      final ra = (a.top / 15).floor();
      final rb = (b.top / 15).floor();
      return ra != rb ? ra.compareTo(rb) : a.left.compareTo(b.left);
    });
    return lines.map((l) => l.text).join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Groq
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, List<TimetableEntry>>> _groqParse(
      String text, List<String> days) async {
    final key = _requireApiKey();
    try {
      return await _callGroq(text, days, key);
    } on _TooLargeEx {
      debugPrint('[Groq] 413 → batching by day');
      return _batchedParse(text, key);
    }
  }

  Future<Map<String, List<TimetableEntry>>> _batchedParse(
      String text, String key) async {
    final result = <String, List<TimetableEntry>>{};
    for (int i = 0; i < _kAllDays.length; i += _kDaysPerBatch) {
      final batch = _kAllDays.sublist(
          i, math.min(i + _kDaysPerBatch, _kAllDays.length));
      // Keep TIME rows for these days + any non-TIME lines (legend etc.)
      final batchText = text.split('\n').where((line) {
        if (!line.startsWith('TIME')) return true;
        return batch.any((d) => line.contains('$d:'));
      }).join('\n');

      debugPrint('[Groq] batch ${i ~/ _kDaysPerBatch + 1}: $batch');
      try {
        final partial = await _callGroq(batchText, batch, key);
        result.addAll(partial);
      } catch (e) {
        debugPrint('[Groq] batch error: $e');
      }
      if (i + _kDaysPerBatch < _kAllDays.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    for (final d in _kAllDays) {
      result.putIfAbsent(d, () => []);
    }
    return result;
  }

  Future<Map<String, List<TimetableEntry>>> _callGroq(
    String text,
    List<String> expectedDays,
    String apiKey, {
    int retry = 0,
  }) async {
    final body = json.encode({
      'model': _kGroqModel,
      'messages': [
        {'role': 'system', 'content': _kPrompt},
        {
          'role': 'user',
          'content': 'Parse this timetable into JSON.\n\n$text\n\n'
              'Return ONLY the raw JSON object, no markdown.',
        },
      ],
      'temperature': 0.05,
      'max_tokens': 3500,
      'response_format': {'type': 'json_object'},
    });

    http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse(_kGroqBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 55));
    } on SocketException {
      throw const TimetableOcrException(
          'No internet connection. Check your network.');
    } on http.ClientException catch (e) {
      throw TimetableOcrException('Network error: $e');
    }

    debugPrint('[Groq] status=${resp.statusCode}');

    switch (resp.statusCode) {
      case 200:
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final content =
            data['choices'][0]['message']['content'] as String? ?? '';
        debugPrint('[Groq] preview: '
            '${content.substring(0, content.length.clamp(0, 200))}');
        return _parseJson(content, expectedDays);
      case 413:
        throw _TooLargeEx();
      case 429 when retry < 2:
        final w = Duration(seconds: 3 * (retry + 1));
        debugPrint('[Groq] rate-limited → retry in ${w.inSeconds}s');
        await Future.delayed(w);
        return _callGroq(text, expectedDays, apiKey, retry: retry + 1);
      case 401:
        throw const TimetableOcrException(
            'Invalid Groq API key. Check GROQ_API_KEY in .env.');
      default:
        Map<String, dynamic>? err;
        try { err = json.decode(resp.body) as Map<String, dynamic>; } catch (_) {}
        throw TimetableOcrException(
            'Groq error ${resp.statusCode}: '
            '${err?['error']?['message'] ?? resp.body}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PDF helpers (backward compat)
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final r = await recognizer.processImage(inputImage);
      if (r.text.trim().isEmpty) {
        throw const TimetableOcrException(
            'No text found. Ensure the image is clearly visible.');
      }
      return r.text;
    } finally {
      recognizer.close();
    }
  }

  Future<String> extractTextFromPdf(
    File pdfFile, {
    void Function(int, int)? onPageProgress,
  }) async {
    final tmp = await getTemporaryDirectory();
    final tmpFiles = <File>[];
    PdfDocument? doc;
    try {
      doc = await PdfDocument.openFile(pdfFile.path);
      final n = doc.pagesCount;
      if (n == 0) throw const TimetableOcrException('PDF has 0 pages.');
      if (n > _kMaxPdfPages) {
        throw TimetableOcrException('PDF has $n pages — max $_kMaxPdfPages.');
      }
      final texts = <String>[];
      for (int i = 1; i <= n; i++) {
        onPageProgress?.call(i, n);
        final page = await doc.getPage(i);
        try {
          final img = await page.render(
            width: page.width * 2.1,
            height: page.height * 2.1,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
          );
          if (img == null || img.bytes.isEmpty) continue;
          final f = File('${tmp.path}/tt_p$i.jpg');
          await f.writeAsBytes(img.bytes);
          tmpFiles.add(f);
          try { texts.add(await extractTextFromImage(f)); }
          on TimetableOcrException catch (e) {
            debugPrint('[PDF] p$i: ${e.message}');
          }
        } finally { await page.close(); }
      }
      if (texts.isEmpty) {
        throw const TimetableOcrException(
            'No readable text in any PDF page.\n'
            '• Try uploading as a photo\n'
            '• Ensure the PDF is not encrypted');
      }
      return texts.join('\n\n');
    } finally {
      await doc?.close();
      for (final f in tmpFiles) {
        try { await f.delete(); } catch (_) {}
      }
    }
  }

  Future<Map<String, List<TimetableEntry>>> parseTextWithGroq(String raw) =>
      _groqParse(raw, _kAllDays);

  // ─────────────────────────────────────────────────────────────────────────
  //  JSON parsing
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, List<TimetableEntry>> _parseJson(
      String text, List<String> expectedDays) {
    var clean = text.trim().replaceAll(RegExp(r'```(?:json)?'), '').trim();
    final s = clean.indexOf('{');
    final e = clean.lastIndexOf('}');
    if (s == -1 || e == -1) {
      throw TimetableOcrException(
          'No JSON in Groq response:\n'
          '${clean.substring(0, clean.length.clamp(0, 400))}');
    }
    clean = clean.substring(s, e + 1);

    late Map<String, dynamic> data;
    try {
      data = json.decode(clean) as Map<String, dynamic>;
    } catch (ex) {
      throw TimetableOcrException('Invalid JSON from Groq: $ex');
    }

    final result = <String, List<TimetableEntry>>{};
    int total = 0;

    for (final day in expectedDays) {
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
            confidence:
                (entry['confidence'] as num?)?.toDouble() ?? 0.8,
          ));
        } catch (_) {}
      }
      entries.sort((a, b) => a.startTime.compareTo(b.startTime));
      result[day] = entries;
      total += entries.length;
    }
    debugPrint('[Parse] total=$total');

    if (total == 0 && expectedDays.length == _kAllDays.length) {
      throw const TimetableOcrException(
          'No classes found.\n\n'
          '• Ensure day headers (Monday, Tuesday…) are clearly visible\n'
          '• Use a higher-resolution or better-lit photo\n'
          '• Image should not be rotated beyond 45°');
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _requireApiKey() {
    final k = dotenv.env['GROQ_API_KEY'] ?? '';
    if (k.isEmpty || k == 'your_groq_api_key_here') {
      throw const TimetableOcrException(
          'Groq API key not set. Add GROQ_API_KEY to .env.\n'
          'Free at https://console.groq.com');
    }
    return k;
  }

  /// Returns the canonical day name if [text] is (or abbreviates) a day name.
  String? _matchDay(String text) {
    final t = text.trim().toLowerCase();
    for (final day in _kAllDays) {
      final d = day.toLowerCase();
      if (t == d) return day;
      // Accept ≥3-char prefix: "Mon" → "Monday"
      if (t.length >= 3 && t.length <= d.length && d.startsWith(t)) return day;
    }
    return null;
  }

  bool _isBreak(String text) {
    final t = text.toLowerCase();
    return t.contains('lunch') ||
        t.contains('break') ||
        t.contains('recess') ||
        t.contains('free period') ||
        t.contains('short break');
  }

  bool _isSkip(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    if (RegExp(r'^[\-–—\s]+$').hasMatch(t)) return true; // dashes / blanks
    if (RegExp(r'^\d{1,2}$').hasMatch(t)) return true;   // period numbers
    if (_isBreak(t)) return true;
    return false;
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

  String _fmtTime(String h, String m) =>
      '${int.parse(h).toString().padLeft(2, '0')}:${m.padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _Ln {
  final String text;
  final double top, left, bottom, right;
  const _Ln({
    required this.text,
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
  });
}

class _DayPos {
  final double cx, cy, left, top;
  const _DayPos({
    required this.cx,
    required this.cy,
    required this.left,
    required this.top,
  });
}

/// A detected time slot.  [rangeStart] and [rangeEnd] are mutable and set
/// after all slots are discovered.
class _Slot {
  final String startTime;
  final String endTime;
  final double labelStart; // leading edge of the time-label in secondary axis
  final double labelEnd;   // trailing edge (unused but useful for debug)
  double rangeStart = 0;   // row starts here
  double rangeEnd   = 0;   // row ends here (exclusive)

  _Slot({
    required this.startTime,
    required this.endTime,
    required this.labelStart,
    required this.labelEnd,
  });
}

class _TooLargeEx implements Exception {}

// ─────────────────────────────────────────────────────────────────────────────
//  Public exception
// ─────────────────────────────────────────────────────────────────────────────

class TimetableOcrException implements Exception {
  final String message;
  const TimetableOcrException(this.message);
  @override
  String toString() => message;
}
