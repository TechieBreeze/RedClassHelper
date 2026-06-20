/// 复习模式 -- 答题引擎据此决定题目来源和判分后行为。
enum ReviewMode {
  /// 乱序抽题: 从题库随机抽题，立刻判分。答错自动加入错题本。
  random,

  /// 错题复习: 只展示错题本中的题目。答对即标记已掌握。
  review,

  /// 错题抽查: 从错题本随机抽 N 题自测。不写入错题本。
  spotcheck,
}

/// 从路由参数字符串解析 [ReviewMode]。
/// 用于 GoRouter `/quiz/:bankId/:mode` 路由的参数校验。
ReviewMode reviewModeFromString(String mode) {
  return switch (mode) {
    'random' => ReviewMode.random,
    'review' => ReviewMode.review,
    'spotcheck' => ReviewMode.spotcheck,
    _ => throw ArgumentError(
      'Invalid review mode: $mode. '
      'Expected one of: random, review, spotcheck',
    ),
  };
}

/// [ReviewMode] 的中文显示名。
String reviewModeDisplayName(ReviewMode mode) {
  return switch (mode) {
    ReviewMode.random => '乱序抽题',
    ReviewMode.review => '错题复习',
    ReviewMode.spotcheck => '错题抽查',
  };
}
