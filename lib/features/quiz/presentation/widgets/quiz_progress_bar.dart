import 'package:flutter/material.dart';

/// Quiz progress indicator -- D-05.
///
/// Displays a Material LinearProgressIndicator with determinate value
/// and centered text showing "第 N/M 题".
class QuizProgressBar extends StatelessWidget {
  const QuizProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: colorScheme.primary,
          minHeight: 4,
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '第 $current/$total 题',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
