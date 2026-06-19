// lib/core/paths.dart
// ── PathResolver: app 内唯一调用 path_provider 的类 (D-15) ──
// 所有文件系统路径必须从此处取得,业务代码禁止直接 import path_provider。
//
// D-16: 3 层路径分层
//   - AppSupport: redclass.db (SQLite)
//   - AppDocs:    models/, cache/, diagnostics/
//   - Temp:       下载中分片 / 解析中临时文件
// D-17: DB 放 getApplicationSupportDirectory() 避免 OneDrive 污染
// D-18: models/ 子目录延迟创建 (recursive: true)
// D-19: 7 个 getter: databasePath / modelsDir / cacheDir / diagnosticsDir / tempDir / pandoc / tempImportDir

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paths.g.dart';

/// 系统中未找到 pandoc 时抛出的异常
class PandocNotFoundException implements Exception {
  PandocNotFoundException()
      : message =
            '需要安装 pandoc 来导入 .doc 文件。下载地址：https://pandoc.org/installing.html';

  final String message;

  @override
  String toString() => message;
}

/// 唯一允许调用 `package:path_provider` 的类 (D-15)
/// 所有文件系统路径必须从此处取得,业务代码禁止直接 import path_provider
class PathResolver {
  PathResolver(this._appSupport, this._appDocs, this._temp);

  final Directory _appSupport;
  final Directory _appDocs;
  final Directory _temp;

  /// 工厂:并发获取 3 个平台目录 (D-16)
  static Future<PathResolver> create() async {
    final results = await Future.wait([
      getApplicationSupportDirectory(), // D-16/D-17: SQLite
      getApplicationDocumentsDirectory(), // D-16: models/cache/diagnostics
      getTemporaryDirectory(), // D-16: temp
    ]);
    return PathResolver(
      results[0],
      results[1],
      results[2],
    );
  }

  /// SQLite 数据库文件: getApplicationSupportDirectory()/redclass.db
  /// 放在 AppSupport 而非 Documents 是为了避免 Windows OneDrive 同步污染 (D-17)
  String get databasePath => p.join(_appSupport.path, 'redclass.db');

  /// LLM 模型文件目录: documents/models/*.gguf
  /// 用户可在 Windows 资源管理器手动查看/备份/删除 (D-18)
  Future<Directory> get modelsDir => _ensureSubdir(_appDocs, 'models');

  /// 导入过程缓存: documents/cache/
  Future<Directory> get cacheDir => _ensureSubdir(_appDocs, 'cache');

  /// 诊断包导出: documents/diagnostics/
  Future<Directory> get diagnosticsDir => _ensureSubdir(_appDocs, 'diagnostics');

  /// 临时目录(下载中分片 / 解析中临时文件)
  String get tempDir => _temp.path;

  /// pandoc 二进制路径。
  /// 按顺序检查: PATH → 常见安装位置 → 抛出 [PandocNotFoundException]
  Future<String> get pandoc => _resolvePandoc();

  /// 导入过程临时工作目录: cacheDir/import_work/
  /// 用于 pandoc .doc→.docx 转换、PDF 临时文件等。
  Future<String> get tempImportDir async {
    final cache = await cacheDir;
    final dir = Directory(p.join(cache.path, 'import_work'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// 解析 pandoc 二进制路径
  Future<String> _resolvePandoc() async {
    // 1. 先尝试 PATH 中的 pandoc
    if (await _commandExists('pandoc')) {
      return 'pandoc'; // 在 PATH 中可直接调用
    }

    // 2. 检查常见安装位置
    final candidates = _pandocCandidates();
    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        return candidate;
      }
    }

    throw PandocNotFoundException();
  }

  /// 检查命令行工具是否在 PATH 中可用
  static Future<bool> _commandExists(String command) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [command],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 按平台返回 pandoc 候选安装路径
  static List<String> _pandocCandidates() {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      return [
        r'C:\Program Files\Pandoc\pandoc.exe',
        if (localAppData.isNotEmpty)
          p.join(localAppData, r'Pandoc\pandoc.exe'),
        r'C:\Program Files (x86)\Pandoc\pandoc.exe',
      ];
    }
    return [
      '/usr/bin/pandoc',
      '/usr/local/bin/pandoc',
      '/snap/bin/pandoc',
      p.join(Platform.environment['HOME'] ?? '/home', '.local/bin/pandoc'),
    ];
  }

  static Future<Directory> _ensureSubdir(Directory parent, String name) async {
    final dir = Directory(p.join(parent.path, name));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

@Riverpod(keepAlive: true)
Future<PathResolver> pathResolver(Ref ref) => PathResolver.create();
