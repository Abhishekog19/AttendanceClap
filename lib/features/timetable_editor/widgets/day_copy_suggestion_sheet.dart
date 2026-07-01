/// Day Copy Suggestion Sheet
///
/// Non-blocking bottom sheet suggesting to copy the previous day's schedule
/// to the current day (Section 5). Shown once per day, dismissed permanently.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';

void showDayCopySuggestion({
  required BuildContext context,
  required WidgetRef ref,
  required String currentDay,
  required String previousDay,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => DayCopySuggestionSheet(
      currentDay: currentDay,
      previousDay: previousDay,
      widgetRef: ref,
    ),
  );
}

class DayCopySuggestionSheet extends ConsumerWidget {
  const DayCopySuggestionSheet({
    super.key,
    required this.currentDay,
    required this.previousDay,
    required this.widgetRef,
  });

  final String currentDay;
  final String previousDay;
  final WidgetRef widgetRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timetableEditorNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2028) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666);
    final surface = isDark ? const Color(0xFF282A34) : const Color(0xFFF5F5F5);
    final border = isDark ? const Color(0xFF434655) : const Color(0xFFDDDDDD);
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6);

    final prevFull = kDayFullNames[previousDay] ?? previousDay;
    final curFull = kDayFullNames[currentDay] ?? currentDay;

    // Check if Mon-Fri copy is applicable
    final prevIdx = kDayOrder.indexOf(previousDay);
    final curIdx = kDayOrder.indexOf(currentDay);
    final isMonday = previousDay == 'MON';
    final showMonFri = isMonday && curIdx <= 4; // up to FRI

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          // Icon + Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(isDark ? 50 : 25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.content_copy_rounded,
                    size: 18, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Copy $prevFull\'s schedule?',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      '$curFull has no classes yet.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              // Copy to this day only
              Expanded(
                child: _CopyButton(
                  label: curFull,
                  icon: Icons.arrow_forward_rounded,
                  primary: primaryColor,
                  surface: surface,
                  border: border,
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).pop();
                    notifier.dismissDayCopySuggestion(currentDay);
                    notifier.copyDaySchedule(previousDay, currentDay);
                  },
                ),
              ),
              if (showMonFri) ...[
                const SizedBox(width: 8),
                // Copy Mon–Fri
                Expanded(
                  child: _CopyButton(
                    label: 'Mon–Fri',
                    icon: Icons.calendar_view_week_rounded,
                    primary: primaryColor,
                    surface: surface,
                    border: border,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      final weekdays = ['TUE', 'WED', 'THU', 'FRI'];
                      for (final d in weekdays) {
                        notifier.dismissDayCopySuggestion(d);
                      }
                      notifier.dismissDayCopySuggestion(currentDay);
                      notifier.copyDayToRange(
                        previousDay,
                        weekdays.where((d) {
                          final idx = kDayOrder.indexOf(d);
                          return idx > prevIdx && idx <= 4;
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(width: 8),
              // Dismiss
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  notifier.dismissDayCopySuggestion(currentDay);
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Center(
                    child: Text('Dismiss',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: secondary)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.surface,
    required this.border,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color primary;
  final Color surface;
  final Color border;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: primary.withAlpha(isDark ? 50 : 20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withAlpha(isDark ? 100 : 80)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: primary),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primary)),
            ],
          ),
        ),
      );
}
