import 'package:flutter/material.dart';

/// 通用 hover 交互卡片：
/// - 光标变手型
/// - hover 时轻微放大 + 阴影加深
/// - 平滑动画过渡
class HoverableCard extends StatefulWidget {
  const HoverableCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 12,
    this.scaleOnHover = 1.02,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double scaleOnHover;

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: widget.onTap != null ? (_) => _onHover(true) : null,
      onExit: widget.onTap != null ? (_) => _onHover(false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Transform.scale(
              scale: 1.0 + (widget.scaleOnHover - 1.0) * t,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(widget.borderRadius),
                  color: Color.lerp(
                    cs.surface,
                    cs.surfaceContainerHigh,
                    t,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow
                          .withAlpha((10 + t * 40).round()),
                      blurRadius: 4 + t * 12,
                      offset: Offset(0, 2 + t * 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}
