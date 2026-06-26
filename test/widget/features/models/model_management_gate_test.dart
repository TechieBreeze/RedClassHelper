// test/widget/features/models/model_management_gate_test.dart
// Task 18 — verifies ModelManagementScreen gates download/delete on mobile.
//
// Note: The guard widgets (LlmUnsupportedBanner, UnsupportedFeatureGuard)
// fall back to dart:io Platform detection when no info override is supplied.
// On the Windows host runner that always reads isDesktop=true, so we pass
// `info` explicitly via the screen's parameter and verify the rendered
// branches match the requested platform.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/features/models/presentation/model_management_screen.dart';
import 'package:redclass/features/models/providers/installed_models_provider.dart';

void main() {
  testWidgets(
    'desktop (windows, expanded): no banner, download button enabled, '
    'no desktop-only tooltip',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          installedModelsProvider.overrideWith(
            (ref) async => const <InstalledModel>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ModelManagementScreen(
              info: PlatformInfo(
                platform: AppPlatform.windows,
                shortestSide: 1500,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner should be absent on desktop
      expect(find.byType(MaterialBanner), findsNothing);

      // Should find at least one 下载 button (catalog has 3 models).
      final downloadButtons = find.widgetWithText(FilledButton, '下载');
      expect(downloadButtons, findsWidgets);

      // At least one download button should be enabled (non-null onPressed).
      final enabledDownloadExists = tester
          .widgetList<FilledButton>(downloadButtons)
          .any((w) => w.onPressed != null);
      expect(enabledDownloadExists, isTrue);

      // No Tooltip message about desktop-only feature on desktop.
      expect(find.text('桌面端功能'), findsNothing);
    },
  );

  testWidgets('mobile (android): banner visible, download buttons disabled, '
      'tooltip "桌面端功能" shown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        installedModelsProvider.overrideWith(
          (ref) async => const <InstalledModel>[],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ModelManagementScreen(
            info: PlatformInfo(
              platform: AppPlatform.android,
              shortestSide: 400,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Banner should be present on mobile.
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('当前平台不支持本地 LLM 解析。请使用桌面端或回退到启发式解析。'), findsOneWidget);

    // Catalog still renders — but every 下载 button should be disabled.
    final downloadButtons = find.widgetWithText(FilledButton, '下载');
    expect(downloadButtons, findsWidgets);

    final allDisabled = tester
        .widgetList<FilledButton>(downloadButtons)
        .every((w) => w.onPressed == null);
    expect(allDisabled, isTrue);

    // Tooltip with 桌面端功能 must be present on the fallback buttons.
    final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
    final hasDesktopOnlyTooltip =
        tooltips.any((t) => t.message == '桌面端功能');
    expect(hasDesktopOnlyTooltip, isTrue);
  });
}
