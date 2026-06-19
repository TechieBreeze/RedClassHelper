import 'package:flutter/material.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.bankId, required this.mode});

  final String bankId;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('答题')),
      body: Center(
        child: Text('TODO — QuizScreen bankId=$bankId mode=$mode\n(完整实现见 Phase 4)'),
      ),
    );
  }
}
