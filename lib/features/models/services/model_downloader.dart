// lib/features/models/services/model_downloader.dart
// ── Model download service ──
// HTTP download with Range resume, progress streaming, SHA-256 verification.
// Uses manual HTTP Range implementation (the range_request package has a
// Windows file-locking bug that interferes with temp-file rename; manual
// HTTP Range is more reliable across platforms).

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// High-level download state for the provider layer.
enum DownloadStatus { idle, downloading, verifying, done, error, cancelled }

/// Download progress snapshot emitted via [ModelDownloader.onProgress].
class DownloadProgress {
  final int bytesDownloaded;
  final int? totalBytes;
  final double speedBytesPerSec;

  const DownloadProgress({
    required this.bytesDownloaded,
    required this.totalBytes,
    this.speedBytesPerSec = 0,
  });

  double get fraction => totalBytes != null && totalBytes! > 0
      ? (bytesDownloaded / totalBytes!).clamp(0.0, 1.0)
      : 0.0;
}

/// Result of a successful download.
class DownloadResult {
  final String filePath;
  final int totalBytes;

  const DownloadResult({required this.filePath, required this.totalBytes});
}

/// Thrown when the download cannot be completed due to a network error.
class DownloadNetworkException implements Exception {
  final String url;
  final String? originalError;

  DownloadNetworkException(this.url, [this.originalError]);

  @override
  String toString() =>
      originalError != null ? '下载失败：$originalError' : '下载失败：网络连接异常。请检查网络后重试';
}

/// Thrown when SHA-256 verification fails — the downloaded file is
/// corrupted or tampered.
class DownloadVerificationException implements Exception {
  final String filePath;
  final String expectedSha256;
  final String actualSha256;

  DownloadVerificationException({
    required this.filePath,
    required this.expectedSha256,
    required this.actualSha256,
  });

  @override
  String toString() => '校验失败，请重新下载';
}

/// Thrown when there is not enough disk space to download the model.
class DownloadDiskSpaceException implements Exception {
  final int requiredBytes;
  final int availableBytes;

  DownloadDiskSpaceException({
    required this.requiredBytes,
    required this.availableBytes,
  });

  @override
  String toString() =>
      '磁盘空间不足，无法下载模型。'
      '请释放至少 ${(requiredBytes / 1e9).toStringAsFixed(1)} GB 空间';
}

/// Downloads a GGUF model file with HTTP Range resume, progress callbacks,
/// and SHA-256 integrity verification.
///
/// Uses manual HTTP Range requests via the [http] package. The
/// [range_request] package was evaluated but has a Windows file-locking
/// bug during temp-file rename that makes it unreliable for this use case.
class ModelDownloader {
  final String url;
  final String destPath;
  final String expectedSha256;
  final void Function(DownloadProgress)? onProgress;

  final http.Client _client;
  bool _cancelled = false;
  DateTime _lastProgressTime = DateTime(2000);
  int _lastBytesDownloaded = 0;

  ModelDownloader({
    required this.url,
    required this.destPath,
    required this.expectedSha256,
    this.onProgress,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Starts the download. Returns a [DownloadResult] on success.
  ///
  /// Throws [DownloadNetworkException], [DownloadVerificationException],
  /// or [DownloadDiskSpaceException] on failure.
  Future<DownloadResult> startDownload() async {
    _cancelled = false;

    try {
      // Step 0: Ensure parent directory exists
      final dir = Directory(p.dirname(destPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Step 1: HEAD request to get Content-Length and Accept-Ranges
      final headResponse = await _client
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (headResponse.statusCode != 200) {
        throw DownloadNetworkException(url, '服务器返回 ${headResponse.statusCode}');
      }

      final contentLength = int.tryParse(
        headResponse.headers['content-length'] ?? '',
      );
      if (contentLength == null) {
        throw DownloadNetworkException(url, '无法确定文件大小');
      }

      final acceptRanges =
          headResponse.headers['accept-ranges']?.toLowerCase() == 'bytes';

      // Step 2: Check existing file for resume
      final destFile = File(destPath);
      var existingSize = 0;
      if (acceptRanges && await destFile.exists()) {
        existingSize = await destFile.length();
        // If local file is larger than remote, something is wrong
        if (existingSize > contentLength) {
          await destFile.delete();
          existingSize = 0;
        }
      }

      // Exit early if already fully downloaded
      if (existingSize == contentLength) {
        // Verify SHA-256 if expected
        if (expectedSha256 != 'TBD') {
          final actual = await _computeSha256(destPath);
          if (actual != expectedSha256) {
            throw DownloadVerificationException(
              filePath: destPath,
              expectedSha256: expectedSha256,
              actualSha256: actual,
            );
          }
        }
        return DownloadResult(filePath: destPath, totalBytes: contentLength);
      }

      // Step 3: Download the file
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);

      if (existingSize > 0 && acceptRanges) {
        request.headers['Range'] = 'bytes=$existingSize-';
      }

      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));

      final statusCode = streamedResponse.statusCode;
      if (statusCode != 200 && statusCode != 206) {
        throw DownloadNetworkException(url, '服务器返回 $statusCode');
      }

      // Append to file (or write from scratch)
      final raf = await destFile.open(
        mode: existingSize > 0 ? FileMode.append : FileMode.write,
      );

      try {
        var totalBytesDownloaded = existingSize;

        await for (final chunk in streamedResponse.stream) {
          if (_cancelled) {
            await raf.close();
            await destFile.delete();
            throw _cancellationException();
          }
          await raf.writeFrom(chunk);
          totalBytesDownloaded += chunk.length;
          _emitProgress(totalBytesDownloaded, contentLength);
        }
      } finally {
        await raf.close();
      }

      // Step 4: SHA-256 verification
      if (expectedSha256 != 'TBD') {
        final actual = await _computeSha256(destPath);
        if (actual != expectedSha256) {
          throw DownloadVerificationException(
            filePath: destPath,
            expectedSha256: expectedSha256,
            actualSha256: actual,
          );
        }
      }

      return DownloadResult(filePath: destPath, totalBytes: contentLength);
    } on DownloadVerificationException {
      rethrow;
    } on DownloadNetworkException {
      rethrow;
    } on http.ClientException catch (e) {
      if (_cancelled) throw _cancellationException();
      throw DownloadNetworkException(url, e.message);
    } on TimeoutException {
      if (_cancelled) throw _cancellationException();
      throw DownloadNetworkException(url, '连接超时');
    } on SocketException catch (e) {
      if (_cancelled) throw _cancellationException();
      throw DownloadNetworkException(url, e.message);
    } on Exception catch (e) {
      if (_cancelled) throw _cancellationException();
      throw DownloadNetworkException(url, e.toString());
    } finally {
      _client.close();
    }
  }

  /// Cancels the active download. Idempotent.
  void cancel() {
    _cancelled = true;
    _client.close();
  }

  // ── Private helpers ──

  void _emitProgress(int bytes, int total) {
    final now = DateTime.now();
    final elapsed = now.difference(_lastProgressTime).inMilliseconds;
    final deltaBytes = bytes - _lastBytesDownloaded;

    final speed = elapsed > 0 ? (deltaBytes / (elapsed / 1000.0)) : 0.0;

    _lastProgressTime = now;
    _lastBytesDownloaded = bytes;

    onProgress?.call(
      DownloadProgress(
        bytesDownloaded: bytes,
        totalBytes: total,
        speedBytesPerSec: speed,
      ),
    );
  }

  Future<String> _computeSha256(String filePath) async {
    final file = File(filePath);
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Exception _cancellationException() => DownloadNetworkException(url, '下载已取消');
}
