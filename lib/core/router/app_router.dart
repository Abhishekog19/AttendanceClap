import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/subjects/screens/subjects_screen.dart';
import '../../features/subjects/screens/add_edit_subject_screen.dart';
import '../../features/timetable/screens/timetable_screen.dart';
// OCR feature — disabled until ready
// import '../../features/timetable/screens/timetable_upload_screen.dart';
// import '../../features/timetable/screens/timetable_review_screen.dart';
import '../../features/timetable/screens/semester_setup_screen.dart';
import '../../features/timetable/screens/schedule_preview_screen.dart';
import '../../features/timetable/screens/manage_timetable_screen.dart';
import '../../features/timetable/screens/manual_entry_screen.dart';
import '../../features/timetable/screens/timetable_builder_screen.dart';
import '../../features/predictor/screens/predictor_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/subjects/screens/subject_detail_screen.dart';
import '../../features/attendance/screens/attendance_history_screen.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/notifications/screens/notification_settings_screen.dart';
import '../../features/notifications/screens/notification_center_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/timetable_entry_model.dart';

// ─── Onboarding screens ────────────────────────────────────────────────────────
import '../../features/onboarding/screens/ob_welcome_screen.dart';
import '../../features/onboarding/screens/ob_college_details_screen.dart';
import '../../features/onboarding/screens/ob_semester_setup_screen.dart';
import '../../features/onboarding/screens/ob_subject_setup_screen.dart';
import '../../features/onboarding/screens/ob_timetable_builder_screen.dart';
import '../../features/onboarding/screens/ob_holiday_calendar_screen.dart';
import '../../features/onboarding/screens/ob_attendance_import_screen.dart';
import '../../features/onboarding/screens/ob_review_screen.dart';
import '../../features/onboarding/screens/ob_success_screen.dart';
import '../../features/onboarding/providers/onboarding_state.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  // Watch the current user profile to gate onboarding.
  // UserModel.onboardingComplete == false → redirect to onboarding.
  // Using valueOrNull so that while the profile is loading we return null
  // (no redirect) and the router stays put without flashing.
  final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // While Firebase auth is still resolving, don't redirect at all.
      // authState.isLoading is true during the initial stream evaluation.
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/auth');
      final isOnboardingRoute = loc.startsWith('/onboarding');

      // Not logged in → send to login (unless already on auth route)
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';

      // Logged in + on an auth page → check onboarding status
      if (isLoggedIn && isAuthRoute) {
        // Profile still loading — stay on auth screen until it resolves
        if (currentUser == null) return null;
        if (!currentUser.onboardingComplete) {
          // Resume at next step after the last completed one, or start at welcome
          final saved = currentUser.onboardingStep;
          final step = saved != null
              ? (OnboardingStep.nextStep(saved) ?? OnboardingStep.welcome)
              : OnboardingStep.welcome;
          return OnboardingStep.routeFor(step);
        }
        return '/dashboard';
      }

      // Logged in + not on auth — enforce onboarding gate
      if (isLoggedIn && !isAuthRoute && !isOnboardingRoute) {
        // Profile still loading — allow through (dashboard handles loading state)
        if (currentUser == null) return null;
        // Onboarding not complete — redirect into flow
        if (!currentUser.onboardingComplete) {
          final saved = currentUser.onboardingStep;
          final step = saved != null
              ? (OnboardingStep.nextStep(saved) ?? OnboardingStep.welcome)
              : OnboardingStep.welcome;
          return OnboardingStep.routeFor(step);
        }
      }

      // Logged in + on onboarding + already complete → go to dashboard
      if (isLoggedIn && isOnboardingRoute && currentUser?.onboardingComplete == true) {
        // Exception: success screen is fine to visit (briefly) after complete
        if (loc == '/onboarding/success') return null;
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ─── Onboarding Routes ────────────────────────────────────────────────────
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
        builder: (_, __) => const ObTimetableBuilderScreen(),
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

      // ─── Auth Routes ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ─── Main Shell (Bottom Nav) ──────────────────────────────────────────────
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
          // GoRoute(
          //   path: '/analytics',
          //   name: 'analytics',
          //   builder: (context, state) => const AnalyticsScreen(),
          // ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ─── Standalone Routes ────────────────────────────────────────────────────
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
      // ─── Attendance History ────────────────────────────────────────────────────
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
      // ─── Timetable OCR Routes — disabled until OCR feature is ready ────────────
      // GoRoute(
      //   path: '/timetable/upload',
      //   name: 'timetableUpload',
      //   builder: (context, state) => const TimetableUploadScreen(),
      // ),
      // GoRoute(
      //   path: '/timetable/review',
      //   name: 'timetableReview',
      //   builder: (context, state) => const TimetableReviewScreen(),
      // ),
      GoRoute(
        path: '/timetable/semester-setup',
        name: 'semesterSetup',
        builder: (context, state) => const SemesterSetupScreen(),
      ),
      GoRoute(
        path: '/timetable/schedule-preview',
        name: 'schedulePreview',
        builder: (context, state) => const SchedulePreviewScreen(),
      ),
      // ─── Timetable Manual Management Routes ───────────────────────────────────
      GoRoute(
        path: '/timetable/manage',
        name: 'manageTimetable',
        builder: (context, state) => const ManageTimetableScreen(),
      ),
      GoRoute(
        path: '/timetable/manual-entry',
        name: 'manualEntry',
        builder: (context, state) {
          final existing = state.extra as TimetableEntry?;
          return ManualEntryScreen(existing: existing);
        },
      ),
      GoRoute(
        path: '/timetable/builder',
        name: 'timetableBuilder',
        builder: (context, state) => const TimetableBuilderScreen(),
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
