import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: const Center(
        child: Text('TODO — StatsScreen\n(完整实现见 Phase 5)'),
      ),
    );
  }
}
