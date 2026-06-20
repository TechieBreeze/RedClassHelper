// lib/features/models/widgets/download_progress.dart
// ── Download progress indicator ──
// Displayed inside ModelCard during active download. Shows percentage,
// LinearProgressIndicator, and speed in MB/s.

import 'package:flutter/material.dart';

import '../services/model_downloader.dart';

/// Displays download progress: percentage, progress bar, and speed.
class DownloadProgressWidget extends StatelessWidget {
  const DownloadProgressWidget({required this.progress, super.key});

  final DownloadProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress.fraction * 100).toStringAsFixed(0);
    final speedMBs = (progress.speedBytesPerSec / 1048576).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('下载中 $percent%', style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progress.fraction),
        const SizedBox(height: 4),
        Text('$speedMBs MB/s', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
