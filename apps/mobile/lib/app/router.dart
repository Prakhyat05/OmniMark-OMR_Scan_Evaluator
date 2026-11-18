import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/main_shell_scaffold.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/dashboard/presentation/pages/home_dashboard_page.dart';
import '../features/exams/presentation/pages/exams_list_page.dart';
import '../features/exams/presentation/pages/create_exam_page.dart';
import '../features/answer_keys/presentation/pages/answer_key_setup_page.dart';
import '../features/students/presentation/pages/students_management_page.dart';
import '../features/students/presentation/pages/add_student_page.dart';
import '../features/students/presentation/pages/student_detail_page.dart';
import '../features/scan/presentation/pages/scan_camera_page.dart';
import '../features/review/presentation/pages/review_queue_page.dart';
import '../features/results/presentation/pages/exam_results_summary_page.dart';
import '../features/results/presentation/pages/student_result_detail_page.dart';
import '../features/reports/presentation/pages/report_card_preview_page.dart';
import '../features/email_delivery/presentation/pages/email_report_card_page.dart';
import '../features/email_delivery/presentation/pages/email_history_page.dart';
import '../features/email_delivery/presentation/pages/email_settings_page.dart';
import '../features/settings/presentation/pages/institute_settings_page.dart';
import '../features/settings/presentation/pages/user_profile_page.dart';
import '../features/settings/presentation/pages/notifications_activity_page.dart';
import '../features/settings/presentation/pages/help_support_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Auth & Splash routes (outside shell)
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordPage(),
    ),

    // Stateful Navigation Shell for 4 core tabs with persistent BottomNavBar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const HomeDashboardPage(),
            ),
          ],
        ),
        // Tab 1: Exams
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/exams',
              builder: (context, state) => const ExamsListPage(),
            ),
          ],
        ),
        // Tab 2: Students
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/students',
              builder: (context, state) => const StudentsManagementPage(),
            ),
          ],
        ),
        // Tab 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const InstituteSettingsPage(),
            ),
          ],
        ),
      ],
    ),

    // Sub-routes & Modals (pushed on top of the root navigator)
    GoRoute(
      path: '/create-exam',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateExamPage(),
    ),
    GoRoute(
      path: '/answer-key-setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AnswerKeySetupPage(),
    ),
    GoRoute(
      path: '/add-student',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddStudentPage(),
    ),
    GoRoute(
      path: '/student-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StudentDetailPage(),
    ),
    GoRoute(
      path: '/scan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScanCameraPage(),
    ),
    GoRoute(
      path: '/review-queue',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReviewQueuePage(),
    ),
    GoRoute(
      path: '/exam-results-summary',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExamResultsSummaryPage(),
    ),
    GoRoute(
      path: '/student-result-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StudentResultDetailPage(),
    ),
    GoRoute(
      path: '/report-card-preview',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportCardPreviewPage(),
    ),
    GoRoute(
      path: '/email-report-card',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EmailReportCardPage(),
    ),
    GoRoute(
      path: '/email-history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EmailHistoryPage(),
    ),
    GoRoute(
      path: '/email-settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EmailSettingsPage(),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UserProfilePage(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsActivityPage(),
    ),
    GoRoute(
      path: '/help-support',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HelpSupportPage(),
    ),
  ],
);
