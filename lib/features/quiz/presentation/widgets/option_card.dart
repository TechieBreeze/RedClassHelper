import 'package:flutter/material.dart';

/// Visual state for an option card during quiz interaction.
enum OptionCardState {
  normal,
  hovered,
  selected,
  correct,
  wrongSelected,
  correctUnselected,
  dimmed,
}

/// A single quiz option card with A/B/C/D letter prefix + hover 动效.
class OptionCard extends StatefulWidget {
  const OptionCard({
    super.key,
    required this.optionKey,
    required this.optionText,
    required this.state,
    this.onTap,
  });

  final String optionKey;
  final String optionText;
  final OptionCardState state;
  final VoidCallback? onTap;

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard>
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
  void didUpdateWidget(covariant OptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _hovering = false;
      _controller.value = 0;
    }
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
    final tt = Theme.of(context).textTheme;

    final bool canTap = widget.state == OptionCardState.normal ||
        widget.state == OptionCardState.hovered ||
        widget.state == OptionCardState.selected;

    return MouseRegion(
      cursor: canTap ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: canTap ? (_) => _onHover(true) : null,
      onExit: canTap ? (_) => _onHover(false) : null,
      child: GestureDetector(
        onTap: canTap ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Transform.scale(
              scale: 1.0 + t * 0.015,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _buildBackground(cs, t),
                  borderRadius: BorderRadius.circular(12),
                  border: widget.state == OptionCardState.wrongSelected
                      ? Border.all(
                          color: cs.brightness == Brightness.dark
                              ? const Color(0xFFEA8A8A).withAlpha(120)
                              : cs.error.withAlpha(80),
                          width: 1.5,
                        )
                      : null,
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
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _letterBgColor(cs),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.optionKey,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _letterFgColor(cs),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.optionText,
                  style: tt.bodyLarge?.copyWith(
                    color: _textColor(cs),
                  ),
                ),
              ),
              if (_trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(
                  _trailingIcon!,
                  color: _trailingIconColor(cs),
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _buildBackground(ColorScheme cs, double hoverT) {
    final normalBg = Color.lerp(
      cs.surfaceContainerHighest,
      cs.primaryContainer.withAlpha(60),
      hoverT,
    )!;

    final isDark = cs.brightness == Brightness.dark;

    return switch (widget.state) {
      OptionCardState.correct => isDark
          ? const Color(0xFF1B3A2A).withAlpha(220)
          : Color.lerp(Colors.green.shade50, Colors.green.shade100, hoverT)!,
      OptionCardState.correctUnselected => isDark
          ? const Color(0xFF1B3A2A).withAlpha(160)
          : Colors.green.shade50.withAlpha(180),
      OptionCardState.wrongSelected => isDark
          ? const Color(0xFF3A2020).withAlpha(220)
          : Color.lerp(
              cs.errorContainer.withAlpha(80),
              cs.errorContainer.withAlpha(120),
              hoverT,
            )!,
      OptionCardState.selected => cs.primaryContainer,
      _ => normalBg,
    };
  }

  Color _letterBgColor(ColorScheme cs) {
    if (widget.state == OptionCardState.selected) {
      return cs.primary.withAlpha(40);
    }
    if (widget.state == OptionCardState.correct ||
        widget.state == OptionCardState.correctUnselected) {
      return cs.brightness == Brightness.dark
          ? const Color(0xFF2E6B4A).withAlpha(60)
          : Colors.green.withAlpha(30);
    }
    if (widget.state == OptionCardState.wrongSelected) {
      return cs.brightness == Brightness.dark
          ? cs.error.withAlpha(30)
          : cs.errorContainer;
    }
    return cs.surfaceContainerHighest;
  }

  Color _letterFgColor(ColorScheme cs) {
    if (widget.state == OptionCardState.selected) return cs.primary;
    if (widget.state == OptionCardState.correct ||
        widget.state == OptionCardState.correctUnselected) {
      return cs.brightness == Brightness.dark
          ? const Color(0xFF81C995)
          : Colors.green.shade700;
    }
    if (widget.state == OptionCardState.wrongSelected) {
      return cs.brightness == Brightness.dark
          ? const Color(0xFFEA8A8A)
          : cs.onErrorContainer;
    }
    return cs.onSurface;
  }

  Color _textColor(ColorScheme cs) {
    if (widget.state == OptionCardState.dimmed) {
      return cs.onSurface.withAlpha(140);
    }
    return cs.onSurface;
  }

  IconData? get _trailingIcon {
    return switch (widget.state) {
      OptionCardState.correct => Icons.check_circle,
      OptionCardState.wrongSelected => Icons.cancel,
      OptionCardState.correctUnselected => Icons.check_circle_outline,
      _ => null,
    };
  }

  Color _trailingIconColor(ColorScheme cs) {
    return switch (widget.state) {
      OptionCardState.correct ||
      OptionCardState.correctUnselected =>
        cs.brightness == Brightness.dark
            ? const Color(0xFF81C995)
            : Colors.green.shade600,
      OptionCardState.wrongSelected => cs.brightness == Brightness.dark
          ? const Color(0xFFEA8A8A)
          : cs.error,
      _ => cs.onSurface,
    };
  }
}
