import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏夹')),
      body: AdaptiveLayout(
        compact: (_) => const KeyedSubtree(
          key: Key('bookmarks_vertical_layout'),
          child: Center(
            child: Text('TODO — BookmarksScreen\n(完整实现见 Phase 5)'),
          ),
        ),
        medium: (_) => KeyedSubtree(
          key: const Key('bookmarks_vertical_layout'),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const Text('TODO — BookmarksScreen\n(完整实现见 Phase 5)'),
            ),
          ),
        ),
        expanded: (_) => KeyedSubtree(
          key: const Key('bookmarks_horizontal_layout'),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: const Text('TODO — BookmarksScreen\n(完整实现见 Phase 5)'),
            ),
          ),
        ),
      ),
    );
  }
}
