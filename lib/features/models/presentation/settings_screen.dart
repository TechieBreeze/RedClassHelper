// lib/features/models/presentation/settings_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/color_scheme_provider.dart';
import '../../../core/theme_mode_provider.dart';
import '../../quiz/models/quiz_settings.dart';
import '../../quiz/providers/quiz_settings_provider.dart';

/// 设置页
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Platform.isWindows || Platform.isLinux;
    final settings = ref.watch(quizSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appColorScheme = ref.watch(appColorSchemeProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final double hPad;
          final double? maxW;
          if (width < 600) {
            hPad = 16;
            maxW = null;
          } else if (width < 840) {
            hPad = 24;
            maxW = null;
          } else {
            hPad = 32;
            maxW = 720;
          }
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW ?? double.infinity),
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                children: [
                  // ── 外观 ──
                  _SectionCard(
                    title: '外观',
                    icon: Icons.palette_outlined,
                    children: [
                      _ThemeTile(
                        title: '跟随系统',
                        subtitle: '自动匹配亮色/暗色',
                        icon: Icons.brightness_auto_rounded,
                        mode: ThemeMode.system,
                        selected: themeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.system),
                      ),
                      _ThemeTile(
                        title: '亮色模式',
                        subtitle: '始终使用浅色主题',
                        icon: Icons.light_mode_rounded,
                        mode: ThemeMode.light,
                        selected: themeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                      _ThemeTile(
                        title: '暗色模式',
                        subtitle: '始终使用深色主题',
                        icon: Icons.dark_mode_rounded,
                        mode: ThemeMode.dark,
                        selected: themeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // ── 主题色 ──
                  _SectionCard(
                    title: '主题色',
                    icon: Icons.brush_outlined,
                    children: [
                      _ColorSchemeTile(
                        title: '青绿',
                        colors: const [Color(0xFF00897B), Color(0xFF80CBC4)],
                        selected: appColorScheme == AppColorScheme.teal,
                        onTap: () => ref
                            .read(appColorSchemeProvider.notifier)
                            .setColorScheme(AppColorScheme.teal),
                      ),
                      _ColorSchemeTile(
                        title: '蓝紫',
                        colors: const [Color(0xFF5C6BC0), Color(0xFF9FA8DA)],
                        selected: appColorScheme == AppColorScheme.bluePurple,
                        onTap: () => ref
                            .read(appColorSchemeProvider.notifier)
                            .setColorScheme(AppColorScheme.bluePurple),
                      ),
                    ],
                  ),

                  if (isDesktop) ...[
                    const SizedBox(height: 16),
                    // ── 答题设置 ──
                    _SectionCard(
                      title: '答题设置',
                      icon: Icons.quiz_outlined,
                    children: [
                        ListTile(
                          title: const Text('点击即提交'),
                          subtitle:
                              const Text('关闭后需点击按钮确认答案'),
                          mouseCursor: MouseCursor.defer,
                          trailing: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Switch(
                              value: settings.submitMode == QuizSubmitMode.instant,
                              onChanged: (v) => ref
                                  .read(quizSettingsProvider.notifier)
                                  .setSubmitMode(v
                                      ? QuizSubmitMode.instant
                                      : QuizSubmitMode.confirm),
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        ListTile(
                          title: const Text('自动翻题'),
                          subtitle:
                              const Text('关闭后需手动点击或按键跳转'),
                          mouseCursor: MouseCursor.defer,
                          trailing: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Switch(
                              value:
                                  settings.advanceMode == QuizAdvanceMode.auto,
                              onChanged: (v) => ref
                                  .read(quizSettingsProvider.notifier)
                                  .setAdvanceMode(v
                                      ? QuizAdvanceMode.auto
                                      : QuizAdvanceMode.manual),
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  // ── 模型管理 ──
                  _SectionCard(
                    title: '高级',
                    icon: Icons.tune,
                    children: [
                      _HoverableListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.psychology_rounded,
                              color: cs.onTertiaryContainer, size: 22),
                        ),
                        title: const Text('模型管理'),
                        subtitle: const Text('查看已安装模型、下载推荐模型'),
                        trailing:
                            Icon(Icons.chevron_right_rounded, color: cs.outline),
                        onTap: () => context.push('/settings/models'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatefulWidget {
  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeTile> createState() => _ThemeTileState();
}

class _ThemeTileState extends State<_ThemeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (hovering == _hovering) return;
    _hovering = hovering;
    hovering ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Transform.scale(
              scale: 1.0 + t * 0.015,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withAlpha((t * 20).round()),
                      blurRadius: t * 6,
                      offset: Offset(0, t * 2),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.selected
                      ? cs.onPrimaryContainer
                      : cs.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: widget.selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )),
                    Text(widget.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withAlpha(150),
                            )),
                  ],
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_circle_rounded,
                    color: cs.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 带 hover 效果的 ListTile — 和 _ThemeTile 相同的 scale + shadow 动效。
class _HoverableListTile extends StatefulWidget {
  const _HoverableListTile({
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<_HoverableListTile> createState() => _HoverableListTileState();
}

class _HoverableListTileState extends State<_HoverableListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    hovering ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Transform.scale(
              scale: 1.0 + t * 0.015,
              child: Container(
                padding: widget.contentPadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withAlpha((t * 20).round()),
                      blurRadius: t * 6,
                      offset: Offset(0, t * 2),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: widget.leading,
            title: widget.title,
            subtitle: widget.subtitle,
            trailing: widget.trailing,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

/// 主题色选择项 — 显示两个色点 + hover 动效。
class _ColorSchemeTile extends StatefulWidget {
  const _ColorSchemeTile({
    required this.title,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ColorSchemeTile> createState() => _ColorSchemeTileState();
}

class _ColorSchemeTileState extends State<_ColorSchemeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (hovering == _hovering) return;
    _hovering = hovering;
    hovering ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Transform.scale(
              scale: 1.0 + t * 0.015,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withAlpha((t * 20).round()),
                      blurRadius: t * 6,
                      offset: Offset(0, t * 2),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Row(
            children: [
              // 色点预览
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: widget.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: widget.selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            widget.selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_circle_rounded,
                    color: cs.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
