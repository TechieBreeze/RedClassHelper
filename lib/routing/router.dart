// lib/routing/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/bank_detail/presentation/bank_detail_screen.dart';
import '../features/banks/presentation/banks_list_screen.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/import/presentation/import_preview_screen.dart';
import '../features/import/presentation/import_progress_screen.dart';
import '../features/import/presentation/import_screen.dart';
import '../features/import/presentation/import_summary_screen.dart';
import '../features/import/providers/import_notifier.dart';
import '../features/models/presentation/model_management_screen.dart';
import '../features/models/presentation/settings_screen.dart';
import '../features/quiz/presentation/bank_pick_screen.dart';
import '../features/quiz/presentation/quiz_summary_screen.dart';
import '../features/quiz/models/review_mode.dart';
import '../features/quiz/models/quiz_session_state.dart';
import '../features/quiz/providers/quiz_session_controller.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/stats/presentation/stats_screen.dart';

/// 全局 GoRouter 实例 — 唯一允许的导航 API (UI-SPEC §Routes)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: '/bank/:id',
      builder: (BuildContext context, GoRouterState state) =>
          BankDetailScreen(bankId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/banks',
      builder: (BuildContext context, GoRouterState state) =>
          const BanksListScreen(),
    ),
    GoRoute(
      path: '/quiz',
      redirect: (BuildContext context, GoRouterState state) {
        if (state.uri.path == '/quiz') return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: 'pick/:mode',
          builder: (BuildContext context, GoRouterState state) =>
              BankPickerScreen(mode: state.pathParameters['mode']!),
        ),
        GoRoute(
          path: ':bankId/:mode',
          redirect: (BuildContext context, GoRouterState state) {
            final mode = state.pathParameters['mode']!;
            try {
              reviewModeFromString(mode);
            } on ArgumentError {
              return '/';
            }
            return null;
          },
          routes: [
            GoRoute(
              path: 'summary',
              redirect: (BuildContext context, GoRouterState state) {
                final bankId = state.pathParameters['bankId']!;
                final mode = state.pathParameters['mode']!;
                final container = ProviderScope.containerOf(context);
                final sessionAsync = container.read(
                  quizSessionControllerProvider(bankId, mode),
                );
                final session = sessionAsync.value;
                if (session == null || session.status != QuizStatus.complete) {
                  return '/';
                }
                return null;
              },
              builder: (BuildContext context, GoRouterState state) =>
                  QuizSummaryScreen(
                    bankId: state.pathParameters['bankId']!,
                    mode: state.pathParameters['mode']!,
                  ),
            ),
          ],
          builder: (BuildContext context, GoRouterState state) => QuizScreen(
            bankId: state.pathParameters['bankId']!,
            mode: state.pathParameters['mode']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/stats',
      builder: (BuildContext context, GoRouterState state) =>
          const StatsScreen(),
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (BuildContext context, GoRouterState state) =>
          const BookmarksScreen(),
    ),
    GoRoute(
      path: '/import',
      builder: (BuildContext context, GoRouterState state) =>
          const ImportScreen(),
    ),
    // Phase 2: 导入管道路由
    GoRoute(
      path: '/import/progress',
      builder: (BuildContext context, GoRouterState state) =>
          const ImportProgressScreen(),
    ),
    GoRoute(
      path: '/import/preview/:jobId',
      redirect: (BuildContext context, GoRouterState state) {
        final container = ProviderScope.containerOf(context);
        final importState = container.read(importNotifierProvider);
        if (!importState.isEditing && !importState.isCommitting) {
          return '/';
        }
        return null;
      },
      builder: (BuildContext context, GoRouterState state) =>
          const ImportPreviewScreen(),
    ),
    GoRoute(
      path: '/import/summary/:jobId',
      redirect: (BuildContext context, GoRouterState state) {
        final container = ProviderScope.containerOf(context);
        final importState = container.read(importNotifierProvider);
        if (!importState.isDone && importState.committedCount == 0) {
          return '/';
        }
        return null;
      },
      builder: (BuildContext context, GoRouterState state) =>
          const ImportSummaryScreen(),
    ),
    // Phase 3: 模型管理路由
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/models',
      builder: (BuildContext context, GoRouterState state) =>
          const ModelManagementScreen(),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    appBar: AppBar(title: const Text('路由错误')),
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);
