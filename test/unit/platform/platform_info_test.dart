// test/unit/platform/platform_info_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/platform/platform_info.dart';

void main() {
  group('FormFactor breakpoint', () {
    test('shortestSide < 600 returns compact', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.android, shortestSide: 360);
      expect(info.formFactor, FormFactor.compact);
    });
    test('shortestSide < 840 returns medium', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.android, shortestSide: 720);
      expect(info.formFactor, FormFactor.medium);
    });
    test('shortestSide >= 840 returns expanded', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.windows, shortestSide: 1200);
      expect(info.formFactor, FormFactor.expanded);
    });
  });

  group('derived flags', () {
    test('android is mobile, not desktop', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.android, shortestSide: 400);
      expect(info.isMobile, true);
      expect(info.isDesktop, false);
    });
    test('windows is desktop, supportsLlm true', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.windows, shortestSide: 1200);
      expect(info.isDesktop, true);
      expect(info.supportsLlm, true);
    });
    test('android does not supportLlm', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.android, shortestSide: 400);
      expect(info.supportsLlm, false);
    });
  });
}
