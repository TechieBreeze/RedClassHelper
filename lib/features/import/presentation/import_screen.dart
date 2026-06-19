import 'package:flutter/material.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入题库')),
      body: const Center(
        child: Text('TODO — ImportScreen\n(Phase 2 实现桌面端 .docx/.pdf/.json;Phase 5 加 Android .json 入口)'),
      ),
    );
  }
}
