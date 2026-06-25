// lib/core/widgets/adaptive_scaffold.dart
import 'package:flutter/material.dart';

import '../platform/platform_info.dart';
import '../platform/responsive.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.info,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  /// Optional [PlatformInfo] override. When null, the scaffold reads from
  /// [PlatformInfo.fromContext]. Tests pass an explicit value to avoid
  /// depending on the host platform reported by `dart:io`.
  final PlatformInfo? info;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      info: info,
      builder: (_, resolved) {
        if (resolved.isCompact) {
          return Scaffold(
            appBar: AppBar(title: Text(title), actions: actions),
            body: body,
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: bottomNavigationBar,
            drawer: drawer,
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(title), actions: actions),
          body: Row(
            children: [
              if (drawer != null) ...[
                SizedBox(width: 280, child: drawer!),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: body),
            ],
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}