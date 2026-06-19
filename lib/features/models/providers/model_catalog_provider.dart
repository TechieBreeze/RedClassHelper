// lib/features/models/providers/model_catalog_provider.dart
// ── 3-tier model catalog provider ──
// Exposes preset model tiers: recommended (Qwen2.5-1.5B), fast (0.5B),
// experimental (3B). SHA-256 hashes are TBD pending first download.

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'model_catalog_provider.g.dart';

/// Model tier classification.
enum ModelTier { recommended, fast, experimental, custom }

/// Metadata for one preset model in the catalog.
class ModelInfo {
  final String id;
  final String name;
  final ModelTier tier;
  final int sizeBytes;
  final String sizeDisplay;
  final String ramRequirement;
  final String description;
  final String downloadUrl;
  final String sha256Hash;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.tier,
    required this.sizeBytes,
    required this.sizeDisplay,
    required this.ramRequirement,
    required this.description,
    required this.downloadUrl,
    required this.sha256Hash,
  });
}

/// The 3-tier preset model catalog.
///
/// D-04: Three tiers — Recommended (1.5B ~1.0 GB), Fast (0.5B ~0.5 GB),
/// Experimental (3B ~2.0 GB). Download on demand; no auto-download.
/// SHA-256 hashes are TBD until first verified download.
@riverpod
List<ModelInfo> modelCatalog(Ref ref) {
  return const [
    ModelInfo(
      id: 'qwen2.5-1.5b-q4km',
      name: 'Qwen2.5-1.5B Q4_K_M',
      tier: ModelTier.recommended,
      sizeBytes: 1200000000,
      sizeDisplay: '约 1.2 GB',
      ramRequirement: '需 2-3 GB 可用内存',
      description: '平衡质量与速度，适合大多数题库。',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/'
          'resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      sha256Hash: 'TBD',
    ),
    ModelInfo(
      id: 'qwen2.5-0.5b-q4km',
      name: 'Qwen2.5-0.5B Q4_K_M',
      tier: ModelTier.fast,
      sizeBytes: 500000000,
      sizeDisplay: '约 0.5 GB',
      ramRequirement: '需 1-2 GB 可用内存',
      description: '极速解析，精度略低于推荐模型。',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/'
          'resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      sha256Hash: 'TBD',
    ),
    ModelInfo(
      id: 'qwen2.5-3b-q4km',
      name: 'Qwen2.5-3B Q4_K_M',
      tier: ModelTier.experimental,
      sizeBytes: 2200000000,
      sizeDisplay: '约 2.2 GB',
      ramRequirement: '需 4 GB+ 可用内存',
      description: '最高解析质量，适合复杂题库。',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/'
          'resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf',
      sha256Hash: 'TBD',
    ),
  ];
}
