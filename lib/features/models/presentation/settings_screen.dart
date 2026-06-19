// lib/features/models/presentation/settings_screen.dart
// ── Minimal settings screen (Phase 3) ──
// Shows model management entry on desktop (Windows/Linux).
// Android shows minimal placeholder (full settings in Phase 6).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Settings screen — Phase 3 minimal version.
///
/// Desktop: shows "模型管理" ListTile navigating to /settings/models.
/// Android: placeholder (Phase 6 will add more entries).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isLinux;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final EdgeInsets padding;
          final double? maxWidth;
          if (width < 600) {
            padding = const EdgeInsets.symmetric(horizontal: 16);
            maxWidth = null;
          } else if (width < 840) {
            padding = const EdgeInsets.symmetric(horizontal: 24);
            maxWidth = null;
          } else {
            padding = const EdgeInsets.symmetric(horizontal: 32);
            maxWidth = 720;
          }
          return Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: maxWidth ?? double.infinity),
              child: ListView(
                padding: padding,
                children: [
                  if (isDesktop)
                    ListTile(
                      leading: const Icon(Icons.psychology),
                      title: const Text('模型管理'),
                      subtitle: const Text('查看已安装模型、下载推荐模型'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/models'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
