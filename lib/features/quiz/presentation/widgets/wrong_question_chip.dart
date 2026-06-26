import 'dart:async';

import 'package:flutter/material.dart';

/// Animated "已加入错题本" chip -- D-15.
///
/// When [show] transitions to true, the chip animates in with a slide-up
/// + fade-in (200ms, ease-out). After 1.5 seconds, it auto-dismisses
/// with a fade-out (200ms), then calls [onDismissed].
///
/// Uses StatefulWidget because the animation is purely local UI state
/// (no business logic involved).
class WrongQuestionChip extends StatefulWidget {
  const WrongQuestionChip({super.key, required this.show, this.onDismissed});

  final bool show;
  final VoidCallback? onDismissed;

  @override
  State<WrongQuestionChip> createState() => _WrongQuestionChipState();
}

class _WrongQuestionChipState extends State<WrongQuestionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;
  bool _wasShowing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant WrongQuestionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !_wasShowing) {
      _show();
    } else if (!widget.show && _wasShowing) {
      _hide();
    }
    _wasShowing = widget.show;
  }

  void _show() {
    _dismissTimer?.cancel();
    _controller.forward();
    _dismissTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _hide();
    });
  }

  void _hide() async {
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value == 0) return const SizedBox.shrink();
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(position: _slideAnimation, child: child!),
        );
      },
      child: Chip(
        avatar: const Icon(Icons.bookmark_added, size: 16),
        label: const Text('已加入错题本'),
        backgroundColor: colorScheme.errorContainer,
        labelStyle: TextStyle(
          color: colorScheme.onErrorContainer,
          fontSize: 13,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
