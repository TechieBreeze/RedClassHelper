// lib/routing/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/bank_detail/presentation/bank_detail_screen.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/import/presentation/import_screen.dart';
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
      path: '/quiz/:bankId/:mode',
      builder: (BuildContext context, GoRouterState state) => QuizScreen(
        bankId: state.pathParameters['bankId']!,
        mode: state.pathParameters['mode']!,
      ),
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
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    appBar: AppBar(title: const Text('路由错误')),
    body: Center(
      child: Text('Route not found: ${state.uri}'),
    ),
  ),
);
