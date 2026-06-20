// lib/features/models/providers/installed_models_provider.dart
// ── Installed models list provider ──
// Scans PathResolver.modelsDir for .gguf files and returns them as
// InstalledModel objects with filePath, fileName, and sizeBytes.

import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/paths.dart';

part 'installed_models_provider.g.dart';

/// Represents a locally installed GGUF model file.
class InstalledModel {
  final String filePath;
  final String fileName;
  final int sizeBytes;

  const InstalledModel({
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
  });
}

/// Lists installed .gguf model files in [PathResolver.modelsDir].
///
/// Invalidated by [ModelDownloadNotifier] when a download completes.
@Riverpod(keepAlive: true)
Future<List<InstalledModel>> installedModels(Ref ref) async {
  final resolver = await ref.read(pathResolverProvider.future);
  final modelsDir = await resolver.modelsDir;

  final dir = Directory(modelsDir.path);
  if (!await dir.exists()) return [];

  final files = await dir
      .list()
      .where((e) => e is File && e.path.endsWith('.gguf'))
      .toList();

  return files.map((f) {
    final file = f as File;
    return InstalledModel(
      filePath: file.path,
      fileName: file.uri.pathSegments.last,
      sizeBytes: file.lengthSync(),
    );
  }).toList();
}
