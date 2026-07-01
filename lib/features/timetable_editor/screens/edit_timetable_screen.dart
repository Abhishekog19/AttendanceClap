/// Edit Timetable Screen
///
/// Post-onboarding timetable editor. No wizard chrome —
/// just a top app bar with a "Done" back button and the shared TimetableGrid.
/// Accessed from Settings, Profile, or the main Timetable screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/timetable_grid.dart';

class EditTimetableScreen extends ConsumerWidget {
  const EditTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Edit Timetable',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: TimetableGrid(
        mode: TimetableGridMode.edit,
        onFinish: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
