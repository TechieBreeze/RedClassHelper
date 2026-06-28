// lib/core/nav/safe_nav.dart
//
// 导航防抖 — 拦截重复 push, 防止快速连点按钮把同一页压栈多次。
// cooldown 400ms (Android double-tap 默认 300ms, 留 buffer)。
// pop / go 不在此护: pop 已用 canPop() 守卫防崩, go 是幂等栈替换。

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class NavGuard {
  NavGuard._();

  static DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration cooldown = Duration(milliseconds: 400);

  static bool tryAcquire() {
    final now = DateTime.now();
    if (now.difference(_lastPush) < cooldown) return false;
    _lastPush = now;
    return true;
  }

  @visibleForTesting
  static void resetForTest() => _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
}

extension SafeNavContext on BuildContext {
  Future<T?> safePush<T>(String location, {Object? extra}) {
    if (!NavGuard.tryAcquire()) return Future<T?>.value(null);
    return push<T>(location, extra: extra);
  }

  /// Safe pop — no-op if the route stack is empty (e.g. page was opened as
  /// the initial route), preventing the "pop called on empty stack" crash.
  void safePop<T>([T? result]) {
    if (canPop()) {
      pop<T>(result);
    }
  }
}