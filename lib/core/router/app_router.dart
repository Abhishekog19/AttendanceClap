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
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/subjects/screens/subject_detail_screen.dart';
import '../../features/attendance/screens/attendance_history_screen.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/notifications/screens/notification_settings_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/timetable_entry_model.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
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
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
