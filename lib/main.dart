import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redclass/core/paths.dart';
import 'package:redclass/core/color_scheme_provider.dart';
import 'package:redclass/core/theme.dart';
import 'package:redclass/core/theme_mode_provider.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/quiz/providers/quiz_settings_provider.dart';
import 'package:redclass/routing/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final resolver = await PathResolver.create();
  final sharedPrefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        pathResolverProvider.overrideWith((ref) async => resolver),
        sharedPreferencesProvider.overrideWith((ref) => sharedPrefs),
      ],
      child: const RedClassApp(),
    ),
  );
}

/// RedClass 根 Widget
///
/// 在 build 里 watch `appDatabaseProvider`，强制 drift 在 app 启动时打开
/// 数据库（连带触发 v2→v3 migration），而不是在用户首次走到某个 await DB
/// 的流程（比如导入 → commitToDatabase）时才延迟执行。Loading 阶段显示
/// splash，DB 就绪后才挂载路由——保证首次导入的 commitToDatabase 不会被
/// migration 阻塞。
class RedClassApp extends ConsumerWidget {
  const RedClassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = ref.watch(appColorSchemeProvider);
    final dbAsync = ref.watch(appDatabaseProvider);

    if (dbAsync.isLoading) {
      return MaterialApp(
        theme: buildAppTheme(Brightness.light, null, colorScheme: colorScheme),
        darkTheme: buildAppTheme(Brightness.dark, null, colorScheme: colorScheme),
        themeMode: themeMode,
        locale: const Locale('zh', 'CN'),
        home: const _DatabaseBootSplash(),
      );
    }
    if (dbAsync.hasError) {
      return MaterialApp(
        theme: buildAppTheme(Brightness.light, null, colorScheme: colorScheme),
        darkTheme: buildAppTheme(Brightness.dark, null, colorScheme: colorScheme),
        themeMode: themeMode,
        locale: const Locale('zh', 'CN'),
        home: _DatabaseBootError(error: dbAsync.error!),
      );
    }

    return MaterialApp.router(
      title: '红课复习',
      theme: buildAppTheme(Brightness.light, null, colorScheme: colorScheme),
      darkTheme: buildAppTheme(Brightness.dark, null, colorScheme: colorScheme),
      themeMode: themeMode,
      routerConfig: appRouter,
      locale: const Locale('zh', 'CN'),
    );
  }
}

/// DB 启动 splash——v2→v3 migration 在此期间执行（首次启动可能持续数秒）。
class _DatabaseBootSplash extends StatelessWidget {
  const _DatabaseBootSplash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text('红课复习', style: theme.textTheme.titleLarge),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text('正在初始化数据库…', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// DB 启动失败屏——migration 抛错时显示。提示用户重启或上报。
class _DatabaseBootError extends StatelessWidget {
  const _DatabaseBootError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '数据库初始化失败',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
