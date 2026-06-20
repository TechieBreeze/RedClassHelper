import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redclass/core/paths.dart';
import 'package:redclass/core/theme.dart';
import 'package:redclass/features/quiz/providers/quiz_settings_provider.dart';
import 'package:redclass/routing/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phase 1: Pre-resolve path_provider paths to avoid late-init (Pitfall 4)
  final resolver = await PathResolver.create();
  // Phase 4: Pre-initialize SharedPreferences to avoid async race (Pitfall 4)
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

/// RedClass 根 Widget。
///
/// Plan 01-05: DynamicColorBuilder 包裹 MaterialApp.router,
/// buildAppTheme 使用 dynamic_color 的 ColorScheme.harmonized() + fromSeed 兜底 (D-20/D-23)。
class RedClassApp extends StatelessWidget {
  const RedClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    // RESEARCH.md Pitfall 7: dynamic_color 在大多数桌面端返回 null; ThemeData 内部用 harmonized() 兜底
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: '红课复习',
          theme: buildAppTheme(Brightness.light, lightDynamic),
          darkTheme: buildAppTheme(Brightness.dark, darkDynamic),
          themeMode: ThemeMode.system, // D-21
          routerConfig: appRouter, // Phase 1 routing
          locale: const Locale('zh', 'CN'),
        );
      },
    );
  }
}
