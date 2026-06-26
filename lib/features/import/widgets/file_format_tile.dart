import 'package:flutter/material.dart';

/// ImportScreen 中每种文件格式的可点击图块，带 hover 动效。
class FileFormatTile extends StatefulWidget {
  const FileFormatTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
    this.iconBg,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color? iconColor;
  final Color? iconBg;

  @override
  State<FileFormatTile> createState() => _FileFormatTileState();
}

class _FileFormatTileState extends State<FileFormatTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (hovering == _hovering || !widget.enabled) return;
    _hovering = hovering;
    hovering ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: widget.enabled ? (_) => _onHover(true) : null,
      onExit: widget.enabled ? (_) => _onHover(false) : null,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Transform.scale(
              scale: 1.0 + t * 0.015,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Color.lerp(cs.surface, cs.surfaceContainerHigh, t),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Color.lerp(
                      cs.outlineVariant.withAlpha(80),
                      cs.primary.withAlpha(120),
                      t,
                    )!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withAlpha((5 + t * 25).round()),
                      blurRadius: 2 + t * 6,
                      offset: Offset(0, 1 + t * 2),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.5,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.iconBg ?? cs.primaryContainer,
                        (widget.iconBg ?? cs.primaryContainer).withAlpha(120),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: widget.iconColor ?? cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
