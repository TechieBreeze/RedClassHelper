import 'package:flutter/material.dart';

class BankDetailScreen extends StatelessWidget {
  const BankDetailScreen({super.key, required this.bankId});

  final String bankId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('题库详情')),
      body: Center(
        child: Text('TODO — BankDetailScreen for $bankId\n(完整实现见 Phase 4)'),
      ),
    );
  }
}
