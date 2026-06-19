import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redclass/core/paths.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // RESEARCH.md Pitfall 4: 预解析 path_provider 路径,避免 ref.watch 时的 late-init 错误
  final resolver = await PathResolver.create();
  runApp(
    ProviderScope(
      overrides: [
        pathResolverProvider.overrideWith((ref) async => resolver),
      ],
      child: const RedClassApp(),
    ),
  );
}

/// RedClass 根 Widget。
///
/// Plan 01-04 (router) 将替换为 MaterialApp.router，
/// Plan 01-05 (theme) 将包装 DynamicColorBuilder。
class RedClassApp extends StatelessWidget {
  const RedClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '红课复习',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text(
            '红课复习\nPhase 1 — PathResolver wired',
            textAlign: TextAlign.center,
          ),
          ),
          ),
    );
  }
}
