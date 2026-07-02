/// Subject Library Strip
///
/// Horizontal scrollable row of subject chips pinned above the timetable grid.
/// Tapping a chip selects it for placement; tapping again deselects.
/// "Selected" state shows a persistent floating chip overlay.
/// "+ Subject" entry at the end opens add-subject sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/subject_model.dart';
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
          // Placement mode banner
          if (selectedId != null) ...[
            _PlacementBanner(
              subject: subjects.firstWhere(
                (s) => s.id == selectedId,
                orElse: () => SubjectModel(
                  id: 'unknown',
                  name: '?',
                  attendedClasses: 0,
                  totalClasses: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ),
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
                                : const Color(0xFF4F5EFF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Subject',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFB4C5FF)
                                  : const Color(0xFF4F5EFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final subject = subjects[index];
                final isSelected = subject.id == selectedId;
                final color = hexToColor(subject.effectiveColorHex);

                return _SubjectChip(
                  subject: subject,
                  isSelected: isSelected,
                  color: color,
                  isDark: isDark,
                  onTap: () => notifier.selectSubject(subject.id),
                );
              },
            ),
          ),
          // Divider
          Container(
            height: 1,
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
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final SubjectModel subject;
  final bool isSelected;
  final Color color;
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
          color: isSelected ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSelected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              subject.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? _contrastColor(color)
                    : (isDark ? Colors.white70 : const Color(0xFF191B23)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.35
        ? const Color(0xFF111318)
        : Colors.white;
  }
}

// ─── Placement Banner ─────────────────────────────────────────────────────────

class _PlacementBanner extends StatelessWidget {
  const _PlacementBanner({
    required this.subject,
    required this.onCancel,
    required this.isDark,
  });

  final SubjectModel subject;
  final VoidCallback onCancel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(subject.effectiveColorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Placing ${subject.name} — tap a cell to place',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF434655),
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: isDark ? Colors.white38 : const Color(0xFF8990B0),
            ),
          ),
        ],
      ),
    );
  }
}
