import 'package:flutter/material.dart';

/// Visual state for an option card during quiz interaction.
enum OptionCardState {
  /// Not yet selected, no answer submitted.
  normal,

  /// Hovered (desktop mouse), not yet selected.
  hovered,

  /// User has selected this option (pre-submit, confirm mode).
  selected,

  /// This is the correct answer (post-submit, shown for all correct options).
  correct,

  /// User selected this option AND it was wrong (post-submit).
  wrongSelected,

  /// This is the correct answer but user selected a different option (post-submit).
  correctUnselected,

  /// This option was not selected by user and is not correct (post-submit, dimmed).
  dimmed,
}

/// A single quiz option card with A/B/C/D letter prefix.
///
/// Renders one option in a Card with InkWell, showing the letter key,
/// option text, and optional trailing icon for feedback states (D-04).
///
/// Color contract per 04-UI-SPEC.md:
/// - normal: surfaceContainerHighest, no border/icon
/// - selected: primaryContainer, no trailing icon
/// - correct: green tint 0.15 + check_circle icon
/// - wrongSelected: red border 2px + cancel icon
/// - correctUnselected: green tint 0.10 + check_circle_outline icon
/// - dimmed: opacity 0.5, no icon
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.optionKey,
    required this.optionText,
    required this.state,
    this.onTap,
  });

  final String optionKey; // "A", "B", "C", or "D"
  final String optionText; // The full option text
  final OptionCardState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Widget card = Card(
      shape: _buildShape(colorScheme),
      color: _buildBackground(colorScheme),
      child: InkWell(
        onTap: state == OptionCardState.normal ||
                state == OptionCardState.hovered ||
                state == OptionCardState.selected
            ? onTap
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Letter prefix: bold in a rounded container
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _letterBgColor(colorScheme),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  optionKey,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _letterFgColor(colorScheme),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Option text
              Expanded(
                child: Text(
                  optionText,
                  style: textTheme.bodyLarge?.copyWith(
                    color: _textColor(colorScheme),
                  ),
                ),
              ),
              // Trailing icon (feedback states)
              if (_trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(
                  _trailingIcon!,
                  color: _trailingIconColor,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Wrap in Opacity for dimmed state
    if (state == OptionCardState.dimmed) {
      return Opacity(opacity: 0.5, child: card);
    }
    return card;
  }

  ShapeBorder _buildShape(ColorScheme cs) {
    if (state == OptionCardState.wrongSelected) {
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
      );
    }
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  }

  Color _buildBackground(ColorScheme cs) {
    return switch (state) {
      OptionCardState.correct => Colors.green.withOpacity(0.22),
      OptionCardState.correctUnselected => Colors.green.withOpacity(0.14),
      OptionCardState.selected => cs.primaryContainer,
      _ => cs.surfaceContainerHighest,
    };
  }

  Color _letterBgColor(ColorScheme cs) {
    if (state == OptionCardState.selected) return cs.primary.withOpacity(0.15);
    if (state == OptionCardState.correct ||
        state == OptionCardState.correctUnselected) {
      return Colors.green.withOpacity(0.28);
    }
    return cs.surfaceContainerHighest;
  }

  Color _letterFgColor(ColorScheme cs) {
    if (state == OptionCardState.selected) return cs.primary;
    if (state == OptionCardState.correct ||
        state == OptionCardState.correctUnselected) {
      return Colors.green.shade500;
    }
    return cs.onSurface;
  }

  Color _textColor(ColorScheme cs) {
    if (state == OptionCardState.dimmed) return cs.onSurface.withOpacity(0.5);
    return cs.onSurface;
  }

  IconData? get _trailingIcon {
    return switch (state) {
      OptionCardState.correct => Icons.check_circle,
      OptionCardState.wrongSelected => Icons.cancel,
      OptionCardState.correctUnselected => Icons.check_circle_outline,
      _ => null,
    };
  }

  Color? get _trailingIconColor {
    return switch (state) {
      OptionCardState.correct ||
      OptionCardState.correctUnselected =>
        Colors.green,
      OptionCardState.wrongSelected => const Color(0xFFD32F2F),
      _ => null,
    };
  }
}
