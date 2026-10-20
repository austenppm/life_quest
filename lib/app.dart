import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/onboarding_quiz_screen.dart';
import 'screens/assistant/ai_assistant_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/quests/quests_screen.dart';
import 'screens/quests/quest_detail_screen.dart';
import 'screens/workouts/workouts_screen.dart';
import 'screens/workouts/workout_log_screen.dart';
import 'screens/study/study_screen.dart';
import 'screens/work/work_screen.dart';
import 'screens/alarms/alarms_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/calendar_sync_screen.dart';
import 'screens/money/money_screen.dart';
import 'screens/food/food_screen.dart';
import 'screens/weight/weight_tracker_screen.dart';
import 'screens/exercise/exercise_main_screen.dart';

class LifeQuestApp extends ConsumerWidget {
  const LifeQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authState.valueOrNull != null;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/') {
          return '/login';
        }
        if (isLoggedIn && isAuthRoute) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingQuizScreen(),
        ),
        // Main tabs with bottom navigation
        ShellRoute(
          builder: (context, state, child) => HomeScreen(child: child),
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardContent(),
              ),
            ),
            GoRoute(
              path: '/tasks',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TasksScreen(),
              ),
            ),
            GoRoute(
              path: '/food',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: FoodScreen(),
              ),
            ),
            GoRoute(
              path: '/exercise',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ExerciseMainScreen(),
              ),
            ),
            GoRoute(
              path: '/money',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MoneyScreen(),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
        // Secondary screens without bottom navigation
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: '/tasks/:taskId',
          builder: (context, state) => TaskDetailScreen(
            taskId: state.pathParameters['taskId']!,
          ),
        ),
        GoRoute(
          path: '/quests',
          builder: (context, state) => const QuestsScreen(),
        ),
        GoRoute(
          path: '/quests/:questId',
          builder: (context, state) => QuestDetailScreen(
            questId: state.pathParameters['questId']!,
          ),
        ),
        GoRoute(
          path: '/workouts',
          builder: (context, state) => const WorkoutsScreen(),
        ),
        GoRoute(
          path: '/workouts/log',
          builder: (context, state) => const WorkoutLogScreen(),
        ),
        GoRoute(
          path: '/study',
          builder: (context, state) => const StudyScreen(),
        ),
        GoRoute(
          path: '/work',
          builder: (context, state) => const WorkScreen(),
        ),
        GoRoute(
          path: '/alarms',
          builder: (context, state) => const AlarmsScreen(),
        ),
        GoRoute(
          path: '/achievements',
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: '/weight',
          builder: (context, state) => const WeightTrackerScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/calendar-sync',
          builder: (context, state) => const CalendarSyncScreen(),
        ),
        GoRoute(
          path: '/assistant',
          builder: (context, state) => const AIAssistantScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Life Quest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
