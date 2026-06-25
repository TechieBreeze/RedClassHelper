import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redclass/core/paths.dart';
import 'package:redclass/core/color_scheme_provider.dart';
import 'package:redclass/core/theme.dart';
import 'package:redclass/core/theme_mode_provider.dart';
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
class RedClassApp extends ConsumerWidget {
  const RedClassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = ref.watch(appColorSchemeProvider);
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
