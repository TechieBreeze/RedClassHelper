import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: RedClassApp(),
    ),
  );
}

/// RedClass 根 Widget。
///
/// Phase 1 种子实现 —— 空 MaterialApp(home: Scaffold)。
/// Plan 01-04 (router) 将替换为 MaterialApp.router，
/// Plan 01-05 (theme) 将包装 DynamicColorBuilder。
class RedClassApp extends ConsumerWidget {
  const RedClassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'RedClass',
      home: Scaffold(
        appBar: AppBar(title: const Text('RedClass')),
        body: const Center(
          child: Text('Phase 1 scaffold'),
        ),
      ),
    );
  }
}
