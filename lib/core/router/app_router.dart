import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/subjects/screens/subjects_screen.dart';
import '../../features/subjects/screens/add_edit_subject_screen.dart';
import '../../features/timetable/screens/timetable_screen.dart';
import '../../features/timetable/screens/semester_setup_screen.dart';
import '../../features/predictor/screens/predictor_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/subjects/screens/subject_detail_screen.dart';
import '../../features/attendance/screens/attendance_history_screen.dart';
import '../../features/notifications/screens/notification_settings_screen.dart';
import '../../features/notifications/screens/notification_center_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../data/models/subject_model.dart';

// ─── Onboarding screens ────────────────────────────────────────────────────────
import '../../features/onboarding/screens/ob_welcome_screen.dart';
import '../../features/onboarding/screens/ob_college_details_screen.dart';
import '../../features/onboarding/screens/ob_semester_setup_screen.dart';
import '../../features/onboarding/screens/ob_subject_setup_screen.dart';
import '../../features/onboarding/screens/ob_holiday_calendar_screen.dart';
import '../../features/onboarding/screens/ob_attendance_import_screen.dart';
import '../../features/onboarding/screens/ob_review_screen.dart';
import '../../features/onboarding/screens/ob_success_screen.dart';
import '../../features/onboarding/providers/onboarding_state.dart';

// ─── Timetable Editor ─────────────────────────────────────────────────────────
import '../../features/timetable_editor/screens/ob_timetable_grid_screen.dart';
import '../../features/timetable_editor/screens/edit_timetable_screen.dart';

// ─── Lifecycle state (replaces auth gate) ────────────────────────────────────
import 'app_lifecycle_state.dart';

part 'app_router.g.dart';

// ── Route constants ───────────────────────────────────────────────────────────

/// Routes that are part of the onboarding flow.
/// The router uses this to decide whether an onboarding-state user is already
/// in the right place or needs a redirect.
const _onboardingRoutePrefix = '/onboarding';

/// Route to send users who have completed onboarding but have no active semester.
const _semesterSetupRoute = '/timetable/semester-setup';

/// Default destination for fully-ready users arriving on an ambiguous route.
const _dashboardRoute = '/dashboard';

// ── Router provider ───────────────────────────────────────────────────────────

@riverpod
GoRouter appRouter(Ref ref) {
  // Watch the lifecycle state stream. The router rebuilds whenever the state
  // changes (e.g. after onboarding completes or a semester is created).
  final lifecycleAsync = ref.watch(appLifecycleStateProvider);

  return GoRouter(
    initialLocation: _dashboardRoute,
    redirect: (context, state) {
      // ── While the settings row is still loading, don't redirect. ─────────
      // AsyncLoading / AsyncError → hold position; app will rebuild when data
      // arrives. This prevents a flash to the wrong screen on cold start.
      if (lifecycleAsync.isLoading || lifecycleAsync.hasError) return null;

      final lifecycle = lifecycleAsync.requireValue;
      final loc = state.matchedLocation;
      final isOnboarding = loc.startsWith(_onboardingRoutePrefix);

      // ── Single state machine switch ───────────────────────────────────────
      return switch (lifecycle) {

        // Booting: never redirect — wait for the next emission.
        AppLifecycleBooting() => null,

        // Onboarding incomplete → send to the correct onboarding step.
        // Exception: success screen is OK to visit right after completing.
        AppLifecycleOnboarding(:final step) =>
            isOnboarding || loc == '/onboarding/success'
                ? null
                : OnboardingStep.routeFor(step),

        // Onboarding done but no semester → force semester setup.
        // Exception: allow the semester-setup screen itself and success screen.
        AppLifecycleNeedsSemester() =>
            loc == _semesterSetupRoute || loc == '/onboarding/success'
                ? null
                : _semesterSetupRoute,

        // Fully ready → block lingering on onboarding screens.
        AppLifecycleReady() => isOnboarding && loc != '/onboarding/success'
            ? _dashboardRoute
            : null,
      };
    },
    routes: [
      // ─── Onboarding Routes ─────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding/welcome',
        name: 'obWelcome',
        builder: (_, __) => const ObWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/college',
        name: 'obCollege',
        builder: (_, __) => const ObCollegeDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/semester',
        name: 'obSemester',
        builder: (_, __) => const ObSemesterSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/subjects',
        name: 'obSubjects',
        builder: (_, __) => const ObSubjectSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/timetable',
        name: 'obTimetable',
        builder: (_, __) => const ObTimetableGridScreen(),
      ),
      GoRoute(
        path: '/onboarding/holidays',
        name: 'obHolidays',
        builder: (_, __) => const ObHolidayCalendarScreen(),
      ),
      GoRoute(
        path: '/onboarding/import',
        name: 'obImport',
        builder: (_, __) => const ObAttendanceImportScreen(),
      ),
      GoRoute(
        path: '/onboarding/review',
        name: 'obReview',
        builder: (_, __) => const ObReviewScreen(),
      ),
      GoRoute(
        path: '/onboarding/success',
        name: 'obSuccess',
        builder: (_, __) => const ObSuccessScreen(),
      ),

      // ─── Main Shell (Bottom Nav) ────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/timetable',
            name: 'timetable',
            builder: (context, state) => const TimetableScreen(),
          ),
          GoRoute(
            path: '/predictor',
            name: 'predictor',
            builder: (context, state) => const PredictorScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ─── Standalone Routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/subjects',
        name: 'subjects',
        builder: (context, state) => const SubjectsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'addSubject',
            builder: (context, state) => const AddEditSubjectScreen(),
          ),
          GoRoute(
            path: 'edit',
            name: 'editSubject',
            builder: (context, state) {
              final subject = state.extra as SubjectModel?;
              return AddEditSubjectScreen(subject: subject);
            },
          ),
          GoRoute(
            path: 'detail',
            name: 'subjectDetail',
            builder: (context, state) {
              final subject = state.extra as SubjectModel;
              return SubjectDetailScreen(subject: subject);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/attendance/history',
        name: 'attendanceHistory',
        builder: (context, state) => const AttendanceHistoryScreen(),
      ),
      GoRoute(
        path: '/premium',
        name: 'premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/timetable/semester-setup',
        name: 'semesterSetup',
        builder: (context, state) => const SemesterSetupScreen(),
      ),
      GoRoute(
        path: '/timetable/edit',
        name: 'editTimetable',
        builder: (context, state) => const EditTimetableScreen(),
      ),
      GoRoute(
        path: '/notifications/settings',
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/notifications/center',
        name: 'notificationCenter',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
