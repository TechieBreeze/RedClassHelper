// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主页 — Phase 1 占位,计划 01-05 添加题库空态 + 三模式入口 + 数据统计入口
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('红课复习'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home — 占位,完整布局在 01-05'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.go('/stats'),
              child: const Text('前往 /stats (验证路由)'),
            ),
          ],
        ),
      ),
    );
  }
}
