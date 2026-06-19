import 'package:flutter/material.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏夹')),
      body: const Center(
        child: Text('TODO — BookmarksScreen\n(完整实现见 Phase 5)'),
      ),
    );
  }
}
