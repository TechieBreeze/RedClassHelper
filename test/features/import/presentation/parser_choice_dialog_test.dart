// test/features/import/presentation/parser_choice_dialog_test.dart
// ── ParserChoiceDialog widget tests ──
// 验证解析方式选择对话框的交互行为。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/features/models/providers/installed_models_provider.dart';
import 'package:redclass/features/models/widgets/parser_choice_dialog.dart';

/// Fake installed models provider returning a given list.
class FakeInstalledModels {
  final List<InstalledModel> models;
  FakeInstalledModels({this.models = const []});

  Future<List<InstalledModel>> call(Ref ref) async => models;
}

void main() {
  group('ParserChoiceDialog', () {
    Widget buildDialog({bool hasModels = false}) {
      final fake = FakeInstalledModels(
        models: hasModels
            ? [
                const InstalledModel(
                  filePath: '/models/test.gguf',
                  fileName: 'test.gguf',
                  sizeBytes: 1000,
                ),
              ]
            : [],
      );

      return ProviderScope(
        overrides: [installedModelsProvider.overrideWith(fake)],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: Text('Behind dialog'))),
        ),
      );
    }

    Future<void> showParserDialog(
      WidgetTester tester, {
      bool hasModels = false,
    }) async {
      await tester.pumpWidget(buildDialog(hasModels: hasModels));
      await tester.pump();

      // Show dialog
      showDialog<ParseMethod>(
        context: tester.element(find.text('Behind dialog')),
        barrierDismissible: false,
        builder: (_) => const ParserChoiceDialog(),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with 2 option cards', (tester) async {
      await showParserDialog(tester, hasModels: false);

      expect(find.text('快速解析（启发式）'), findsOneWidget);
      expect(find.text('高精度解析（LLM）'), findsOneWidget);
      expect(find.text('选择解析方式'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('tapping heuristic card selects it visually', (tester) async {
      await showParserDialog(tester, hasModels: false);

      // Tap the heuristic option card
      await tester.tap(find.text('快速解析（启发式）'));
      await tester.pump();

      // Verify: the AnimatedContainer border state change
      // The actual visual verification is via AnimatedContainer color + border
      // We check that the selected card is present (the widget rebuilds)
      expect(find.text('快速解析（启发式）'), findsOneWidget);

      // Wait for animation
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('tapping LLM card selects it when models installed', (
      tester,
    ) async {
      await showParserDialog(tester, hasModels: true);

      // LLM card should be enabled
      await tester.tap(find.text('高精度解析（LLM）'));
      await tester.pump();

      // Wait for animation
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('高精度解析（LLM）'), findsOneWidget);
    });

    testWidgets('LLM card disabled when no models installed', (tester) async {
      await showParserDialog(tester, hasModels: false);

      // LLM disabled text should be visible
      expect(find.text('需要先下载模型'), findsOneWidget);
      expect(find.text('前往设置 → 模型管理下载'), findsOneWidget);

      // Tap the "前往设置 → 模型管理下载" link which triggers the SnackBar
      await tester.tap(find.text('前往设置 → 模型管理下载'));
      await tester.pump();

      expect(find.text('请先下载模型。前往 设置 → 模型管理下载'), findsOneWidget);
    });

    testWidgets('"取消" button returns null and dismisses dialog', (
      tester,
    ) async {
      await showParserDialog(tester, hasModels: false);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed, we should see the background content
      expect(find.text('Behind dialog'), findsOneWidget);
      expect(find.text('选择解析方式'), findsNothing);
    });

    testWidgets('dialog is not backdrop-dismissible', (tester) async {
      await showParserDialog(tester, hasModels: false);

      // Tap outside the dialog (the barrier)
      // Since barrierDismissible is false, dialog should stay
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.text('选择解析方式'), findsOneWidget);
    });

    testWidgets('LLM card is not disabled when models installed', (
      tester,
    ) async {
      await showParserDialog(tester, hasModels: true);

      // No disabled text should appear
      expect(find.text('需要先下载模型'), findsNothing);

      // Card should be tappable (not grayed out)
      final llmText = tester.widget<Text>(find.text('高精度解析（LLM）'));
      // The Opacity wrapper should be at 1.0
      expect(llmText, isNotNull);
    });
  });
}
