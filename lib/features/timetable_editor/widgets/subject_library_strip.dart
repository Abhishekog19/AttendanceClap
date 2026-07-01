/// Subject Library Strip
///
/// Horizontal scrollable row of subject chips pinned above the timetable grid.
/// Tapping a chip selects it for placement; tapping again deselects.
/// "Selected" state shows a persistent floating chip overlay.
/// "+ Subject" entry at the end opens add-subject sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';

class SubjectLibraryStrip extends ConsumerWidget {
  const SubjectLibraryStrip({super.key, this.onAddSubjectTap});

  final VoidCallback? onAddSubjectTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timetableEditorNotifierProvider);
    final notifier = ref.read(timetableEditorNotifierProvider.notifier);
    final subjects = state.data.subjects;
    final selectedId = state.ui.selectedSubjectId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2028) : Colors.white;
    final border = isDark ? const Color(0xFF282A34) : const Color(0xFFF0F0F0);

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Placement mode chip
          if (selectedId != null) ...[
            _PlacementChip(
              subject: subjects.firstWhere((s) => s.id == selectedId,
                  orElse: () => TimetableSubject(
                      id: selectedId,
                      name: '?',
                      shortName: '?',
                      colorHex: kSubjectColorPalette[0])),
              onCancel: () => notifier.cancelPlacement(),
              isDark: isDark,
            ),
          ],
          // Subject chips strip
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: subjects.length + 1, // +1 for the add button
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == subjects.length) {
                  // "+ New Subject" chip
                  return GestureDetector(
                    onTap: onAddSubjectTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF434655)
                              : const Color(0xFFDDDDDD),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFFB4C5FF)
                                : const Color(0xFF004AC6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Subject',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFB4C5FF)
                                  : const Color(0xFF004AC6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final subject = subjects[index];
                final isSelected = subject.id == selectedId;
                final subjectColor = hexToColor(subject.colorHex);

                return _SubjectChip(
                  subject: subject,
                  isSelected: isSelected,
                  subjectColor: subjectColor,
                  isDark: isDark,
                  onTap: () => notifier.selectSubject(subject.id),
                );
              },
            ),
          ),
          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: border,
          ),
        ],
      ),
    );
  }
}

// ─── Subject Chip ─────────────────────────────────────────────────────────────

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.subject,
    required this.isSelected,
    required this.subjectColor,
    required this.isDark,
    required this.onTap,
  });

  final TimetableSubject subject;
  final bool isSelected;
  final Color subjectColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? subjectColor
              : subjectColor.withAlpha(isDark ? 40 : 25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? subjectColor : subjectColor.withAlpha(120),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: subjectColor.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(200) : subjectColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              subject.shortName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF111111)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placement Mode Chip ──────────────────────────────────────────────────────

class _PlacementChip extends StatelessWidget {
  const _PlacementChip({
    required this.subject,
    required this.onCancel,
    required this.isDark,
  });

  final TimetableSubject subject;
  final VoidCallback onCancel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subjectColor = hexToColor(subject.colorHex);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: subjectColor.withAlpha(isDark ? 50 : 30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: subjectColor.withAlpha(150)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: subjectColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Placing: ${subject.shortName} — tap a cell to place',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF111111),
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Subject Sheet ────────────────────────────────────────────────────────

class AddSubjectSheet extends ConsumerStatefulWidget {
  const AddSubjectSheet({super.key});

  @override
  ConsumerState<AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends ConsumerState<AddSubjectSheet> {
  final _nameCtrl = TextEditingController();
  final _shortNameCtrl = TextEditingController();
  String _selectedColor = kSubjectColorPalette[0];
  bool _shortNameEdited = false;

  @override
  void initState() {
    super.initState();
    // Auto-assign next unused color
    final used = ref
        .read(timetableEditorNotifierProvider)
        .data
        .subjects
        .map((s) => s.colorHex)
        .toList();
    _selectedColor = nextSubjectColor(used);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2028) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666);
    final surface = isDark ? const Color(0xFF282A34) : const Color(0xFFF5F5F5);
    final border = isDark ? const Color(0xFF434655) : const Color(0xFFDDDDDD);
    final primaryColor =
        isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Subject',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: onSurface)),
            const SizedBox(height: 20),
            // Subject name
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Subject name',
                labelStyle: GoogleFonts.inter(color: secondary),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              onChanged: (v) {
                if (!_shortNameEdited) {
                  _shortNameCtrl.text = generateShortName(v);
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            // Short name (auto, editable)
            TextField(
              controller: _shortNameCtrl,
              maxLength: 4,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.inter(
                  color: onSurface, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Short name (auto)',
                labelStyle: GoogleFonts.inter(color: secondary),
                filled: true,
                fillColor: surface,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              onChanged: (_) => setState(() => _shortNameEdited = true),
            ),
            const SizedBox(height: 16),
            // Color picker
            Text('Color',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kSubjectColorPalette.map((hex) {
                final c = hexToColor(hex);
                final isSelected = hex == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? onSurface : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Add button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _nameCtrl.text.trim().isEmpty
                    ? null
                    : () {
                        final name = _nameCtrl.text.trim();
                        final shortName =
                            _shortNameCtrl.text.trim().isEmpty
                                ? generateShortName(name)
                                : _shortNameCtrl.text.trim().toUpperCase();
                        final subject = TimetableSubject(
                          id: '',
                          name: name,
                          shortName: shortName,
                          colorHex: _selectedColor,
                        );
                        ref
                            .read(timetableEditorNotifierProvider.notifier)
                            .addSubject(subject);
                        Navigator.of(context).pop();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor:
                      isDark ? const Color(0xFF002576) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Add Subject',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
