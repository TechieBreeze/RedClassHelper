// lib/data/llm_client/ffi_llm_client.dart
// ── FfiLlmClient: llama.cpp 直接 FFI 绑定 ──
//
// 使用 dart:ffi 直接加载 llama.cpp 共享库（libllama.so / llama.dll），
// 在进程内完成推理，无需独立服务器进程。
// 仅桌面端（Windows/Linux）支持——调用方（providers.dart）负责平台门控。

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';

import 'llm_client.dart';
import 'llm_error.dart';

// ── llama.cpp C 类型映射 ──

final class llama_model extends Opaque {}
final class llama_context extends Opaque {}
typedef llama_token = Int32;

// llama_model_params
final class llama_model_params extends Struct {
  @Int32()
  external int n_gpu_layers;

  @Int32()
  external int split_mode;

  @Int32()
  external int main_gpu;

  external Pointer<Float> tensor_split;

  external Pointer<Utf8> progress_callback_user_data;

  @Int32()
  external int vocab_only;

  @Int32()
  external int use_mmap;

  @Int32()
  external int use_mlock;

  @Int32()
  external int check_tensors;
}

// llama_context_params
final class llama_context_params extends Struct {
  @Uint32()
  external int seed;

  @Uint32()
  external int n_ctx;

  @Uint32()
  external int n_batch;

  @Uint32()
  external int n_threads;

  @Uint32()
  external int n_threads_batch;

  @Int8()
  external int rope_scaling_type;

  @Float()
  external double rope_freq_base;

  @Float()
  external double rope_freq_scale;

  @Float()
  external double yarn_ext_factor;

  @Float()
  external double yarn_attn_factor;

  @Float()
  external double yarn_beta_fast;

  @Float()
  external double yarn_beta_slow;

  @Uint32()
  external int yarn_orig_ctx;

  @Float()
  external double type_k;

  @Float()
  external double type_v;

  @Int32()
  external int embeddings;

  @Int32()
  external int offload_kqv;

  external Pointer<Utf8> abort_callback_user_data;

  @Int8()
  external int pooling_type;

  @Int32()
  external int causal_attn;

  @Int32()
  external int flash_attn;
}

// llama_batch (simplified — for inference we use single-token batches)
final class llama_batch extends Struct {
  @Int32()
  external int n_tokens;

  external Pointer<llama_token> token;

  external Pointer<Float> embd;

  external Pointer<Int32> pos;

  external Pointer<Int32> n_seq_id;

  external Pointer<Pointer<Int32>> seq_id;

  external Pointer<Int8> logits;
}

// llama_token_data
final class llama_token_data extends Struct {
  @llama_token()
  external int id;

  @Float()
  external double logit;

  @Float()
  external double p;
}

// llama_token_data_array
final class llama_token_data_array extends Struct {
  external Pointer<llama_token_data> data;

  @Size()
  external int size;

  @Int64()
  external int sorted;
}

// ── 原生函数类型定义 ──

typedef LlamaBackendInitNative = Void Function();
typedef LlamaBackendInitDart = void Function();

typedef LlamaModelDefaultParamsNative = llama_model_params Function();
typedef LlamaModelDefaultParamsDart = llama_model_params Function();

typedef LlamaContextDefaultParamsNative = llama_context_params Function();
typedef LlamaContextDefaultParamsDart = llama_context_params Function();

typedef LlamaModelLoadNative = Pointer<llama_model> Function(
  Pointer<Utf8> path,
  llama_model_params params,
);
typedef LlamaModelLoadDart = Pointer<llama_model> Function(
  Pointer<Utf8> path,
  llama_model_params params,
);

typedef LlamaFreeModelNative = Void Function(Pointer<llama_model> model);
typedef LlamaFreeModelDart = void Function(Pointer<llama_model> model);

typedef LlamaNewContextNative = Pointer<llama_context> Function(
  Pointer<llama_model> model,
  llama_context_params params,
);
typedef LlamaNewContextDart = Pointer<llama_context> Function(
  Pointer<llama_model> model,
  llama_context_params params,
);

typedef LlamaFreeNative = Void Function(Pointer<llama_context> ctx);
typedef LlamaFreeDart = void Function(Pointer<llama_context> ctx);

typedef LlamaModelDescNative = Pointer<Utf8> Function(
  Pointer<llama_model> model,
);
typedef LlamaModelDescDart = Pointer<Utf8> Function(
  Pointer<llama_model> model,
);

typedef LlamaNVocabNative = Int32 Function(Pointer<llama_model> model);
typedef LlamaNVocabDart = int Function(Pointer<llama_model> model);

typedef LlamaNCtxNative = Int32 Function(Pointer<llama_context> ctx);
typedef LlamaNCtxDart = int Function(Pointer<llama_context> ctx);

typedef LlamaTokenizeNative = Int32 Function(
  Pointer<llama_model> model,
  Pointer<Utf8> text,
  Int32 textLen,
  Pointer<llama_token> tokens,
  Int32 nMaxTokens,
  Int32 addBos,
  Int32 special,
);
typedef LlamaTokenizeDart = int Function(
  Pointer<llama_model> model,
  Pointer<Utf8> text,
  int textLen,
  Pointer<llama_token> tokens,
  int nMaxTokens,
  int addBos,
  int special,
);

typedef LlamaDecodeNative = Int32 Function(
  Pointer<llama_context> ctx,
  llama_batch batch,
);
typedef LlamaDecodeDart = int Function(
  Pointer<llama_context> ctx,
  llama_batch batch,
);

typedef LlamaTokenToPieceNative = Int32 Function(
  Pointer<llama_model> model,
  llama_token token,
  Pointer<Utf8> buf,
  Int32 length,
  Int32 lstrip,
  Int32 special,
);
typedef LlamaTokenToPieceDart = int Function(
  Pointer<llama_model> model,
  int token,
  Pointer<Utf8> buf,
  int length,
  int lstrip,
  int special,
);

typedef LlamaGetLogitsNative = Pointer<Float> Function(
  Pointer<llama_context> ctx,
);
typedef LlamaGetLogitsDart = Pointer<Float> Function(
  Pointer<llama_context> ctx,
);

typedef LlamaSampleTokenGreedyNative = llama_token Function(
  Pointer<llama_context> ctx,
  Pointer<llama_token_data_array> candidates,
);
typedef LlamaSampleTokenGreedyDart = int Function(
  Pointer<llama_context> ctx,
  Pointer<llama_token_data_array> candidates,
);

typedef LlamaBatchInitNative = llama_batch Function(
  Int32 nTokens,
  Int32 embd,
  Int32 nSeqMax,
);
typedef LlamaBatchInitDart = llama_batch Function(
  int nTokens,
  int embd,
  int nSeqMax,
);

// llama.cpp 线程安全互斥量包装
// llama.cpp 的 C API 不是线程安全的——同一时间内只允许一个线程调用推理函数。
// 我们在 Dart 侧使用互斥锁来串行化所有 FFI 调用。

typedef LlamaMutexInitNative = Pointer<Void> Function();
typedef LlamaMutexInitDart = Pointer<Void> Function();

typedef LlamaMutexLockNative = Void Function(Pointer<Void> mutex);
typedef LlamaMutexLockDart = void Function(Pointer<Void> mutex);

typedef LlamaMutexUnlockNative = Void Function(Pointer<Void> mutex);
typedef LlamaMutexUnlockDart = void Function(Pointer<Void> mutex);

typedef LlamaMutexFreeNative = Void Function(Pointer<Void> mutex);
typedef LlamaMutexFreeDart = void Function(Pointer<Void> mutex);

// ── FfiLlmClient ──

/// 通过 dart:ffi 直接绑定 llama.cpp 共享库的 LLM 客户端。
///
/// 在桌面平台（Windows/Linux）上使用，无需独立的 llama-server 进程。
/// 调用方（providers.dart）负责平台门控——本类不检查平台。
///
/// 生命周期：
///   1. 构造时记录库路径和模型路径
///   2. 首次 parse() 调用时懒加载模型
///   3. dispose() 释放模型和上下文
///
/// 线程安全：llama.cpp C API 不是线程安全的。本实现使用互斥锁
/// 确保同一时间内只有一个 parse() 调用活跃。
class FfiLlmClient implements LlmClient {
  /// llama.cpp 共享库路径。
  ///
  /// Windows: `llama.dll` 或绝对路径
  /// Linux:   `libllama.so` 或绝对路径
  /// 传入简单名称时由 DynamicLibrary.open() 搜索系统库路径。
  final String libraryPath;

  /// GGUF 模型文件路径（绝对路径）。
  final String modelPath;

  /// 上下文窗口大小（默认 1024）。
  final int nCtx;

  /// 最大预测 token 数（默认 512）。
  final int nPredict;

  /// CPU 推理线程数（默认 0 = 自动检测）。
  final int nThreads;

  /// 单次 parse() 超时（默认 60 秒——FFI 推理比 HTTP 慢是正常的）。
  final Duration timeout;

  /// 最大重试次数（默认 3）。
  final int maxRetries;

  // ── 内部状态 ──

  DynamicLibrary? _lib;

  // 原生函数指针
  void Function()? _llamaBackendInit;
  llama_model_params Function()? _llamaModelDefaultParams;
  llama_context_params Function()? _llamaContextDefaultParams;
  Pointer<llama_model> Function(Pointer<Utf8>, llama_model_params)?
      _llamaModelLoad;
  void Function(Pointer<llama_model>)? _llamaFreeModel;
  Pointer<llama_context> Function(Pointer<llama_model>, llama_context_params)?
      _llamaNewContext;
  void Function(Pointer<llama_context>)? _llamaFree;
  Pointer<Utf8> Function(Pointer<llama_model>)? _llamaModelDesc;
  int Function(Pointer<llama_model>)? _llamaNVocab;
  int Function(Pointer<llama_context>)? _llamaNCtx;
  int Function(Pointer<llama_model>, Pointer<Utf8>, int, Pointer<llama_token>,
      int, int, int)? _llamaTokenize;
  int Function(Pointer<llama_context>, llama_batch)? _llamaDecode;
  int Function(Pointer<llama_model>, int, Pointer<Utf8>, int, int, int)?
      _llamaTokenToPiece;
  Pointer<Float> Function(Pointer<llama_context>)? _llamaGetLogits;
  int Function(Pointer<llama_context>,
      Pointer<llama_token_data_array>)? _llamaSampleTokenGreedy;
  llama_batch Function(int, int, int)? _llamaBatchInit;
  Pointer<Void> Function()? _llamaMutexInit;
  void Function(Pointer<Void>)? _llamaMutexLock;
  void Function(Pointer<Void>)? _llamaMutexUnlock;
  void Function(Pointer<Void>)? _llamaMutexFree;

  Pointer<llama_model>? _model;
  Pointer<llama_context>? _ctx;
  Pointer<Void>? _mutex;
  bool _loaded = false;
  bool _disposed = false;

  /// 创建 [FfiLlmClient]。
  ///
  /// [libraryPath] 是 llama.cpp 共享库的路径。默认值 `llama` 在 Linux 上
  /// 解析为 `libllama.so`，Windows 上解析为 `llama.dll`。
  ///
  /// [modelPath] 必须是到 .gguf 模型文件的绝对路径。
  FfiLlmClient({
    this.libraryPath = 'llama',
    required this.modelPath,
    this.nCtx = 1024,
    this.nPredict = 512,
    this.nThreads = 0,
    this.timeout = const Duration(seconds: 60),
    this.maxRetries = 3,
  });

  /// 加载 llama.cpp 共享库并解析所有原生函数符号。
  ///
  /// 在首次 parse() 调用时懒加载；也可显式调用以提前初始化。
  ///
  /// 抛出 [LlmConnectionException] 如果：
  /// - 找不到共享库
  /// - 缺少必需的原生函数符号
  void _resolveSymbols() {
    if (_lib != null) return;

    // 加载共享库
    try {
      _lib = DynamicLibrary.open(libraryPath);
    } on ArgumentError catch (e) {
      throw LlmConnectionException(
        serverUrl: libraryPath,
        originalError: 'Failed to load library: ${e.message}',
      );
    }

    // 解析原生函数符号
    try {
      _llamaBackendInit =
          _lib!.lookupFunction<LlamaBackendInitNative, LlamaBackendInitDart>(
        'llama_backend_init',
      );

      _llamaModelDefaultParams = _lib!
          .lookupFunction<LlamaModelDefaultParamsNative,
              LlamaModelDefaultParamsDart>('llama_model_default_params');

      _llamaContextDefaultParams = _lib!
          .lookupFunction<LlamaContextDefaultParamsNative,
              LlamaContextDefaultParamsDart>('llama_context_default_params');

      _llamaModelLoad = _lib!
          .lookupFunction<LlamaModelLoadNative, LlamaModelLoadDart>(
        'llama_model_load',
      );

      _llamaFreeModel =
          _lib!.lookupFunction<LlamaFreeModelNative, LlamaFreeModelDart>(
        'llama_free_model',
      );

      _llamaNewContext =
          _lib!.lookupFunction<LlamaNewContextNative, LlamaNewContextDart>(
        'llama_new_context_with_model',
      );

      _llamaFree = _lib!.lookupFunction<LlamaFreeNative, LlamaFreeDart>(
        'llama_free',
      );

      _llamaModelDesc =
          _lib!.lookupFunction<LlamaModelDescNative, LlamaModelDescDart>(
        'llama_model_desc',
      );

      _llamaNVocab =
          _lib!.lookupFunction<LlamaNVocabNative, LlamaNVocabDart>(
        'llama_n_vocab',
      );

      _llamaNCtx = _lib!.lookupFunction<LlamaNCtxNative, LlamaNCtxDart>(
        'llama_n_ctx',
      );

      _llamaTokenize =
          _lib!.lookupFunction<LlamaTokenizeNative, LlamaTokenizeDart>(
        'llama_tokenize',
      );

      _llamaDecode =
          _lib!.lookupFunction<LlamaDecodeNative, LlamaDecodeDart>(
        'llama_decode',
      );

      _llamaTokenToPiece = _lib!
          .lookupFunction<LlamaTokenToPieceNative, LlamaTokenToPieceDart>(
        'llama_token_to_piece',
      );

      _llamaGetLogits =
          _lib!.lookupFunction<LlamaGetLogitsNative, LlamaGetLogitsDart>(
        'llama_get_logits',
      );

      _llamaSampleTokenGreedy = _lib!
          .lookupFunction<LlamaSampleTokenGreedyNative,
              LlamaSampleTokenGreedyDart>('llama_sample_token_greedy');

      _llamaBatchInit =
          _lib!.lookupFunction<LlamaBatchInitNative, LlamaBatchInitDart>(
        'llama_batch_init',
      );

      // 互斥量函数（可选——旧版 llama.cpp 可能不导出）
      try {
        _llamaMutexInit =
            _lib!.lookupFunction<LlamaMutexInitNative, LlamaMutexInitDart>(
          'llama_mutex_init',
        );
        _llamaMutexLock =
            _lib!.lookupFunction<LlamaMutexLockNative, LlamaMutexLockDart>(
          'llama_mutex_lock',
        );
        _llamaMutexUnlock =
            _lib!.lookupFunction<LlamaMutexUnlockNative, LlamaMutexUnlockDart>(
          'llama_mutex_unlock',
        );
        _llamaMutexFree =
            _lib!.lookupFunction<LlamaMutexFreeNative, LlamaMutexFreeDart>(
          'llama_mutex_free',
        );
      } on ArgumentError {
        // 互斥量不可用——使用 Dart 侧同步替代方案
        _llamaMutexInit = null;
        _llamaMutexLock = null;
        _llamaMutexUnlock = null;
        _llamaMutexFree = null;
      }
    } on ArgumentError catch (e) {
      throw LlmConnectionException(
        serverUrl: libraryPath,
        originalError: 'Missing required symbol: ${e.message}',
      );
    }
  }

  /// 加载 GGUF 模型文件并创建推理上下文。
  ///
  /// 懒加载：首次 parse() 调用时自动触发。
  void _loadModel() {
    if (_loaded) return;
    _resolveSymbols();

    try {
      // 初始化后端
      _llamaBackendInit!();

      // 创建互斥量（如果可用）
      if (_llamaMutexInit != null) {
        _mutex = _llamaMutexInit!();
      }

      // 加载模型
      final modelPathNative = modelPath.toNativeUtf8();
      try {
        final mParams = _llamaModelDefaultParams!();
        _model = _llamaModelLoad!(modelPathNative, mParams);
        if (_model == nullptr) {
          throw LlmConnectionException(
            serverUrl: modelPath,
            originalError: 'llama_model_load returned null',
          );
        }
      } finally {
        calloc.free(modelPathNative);
      }

      // 创建上下文
      final cParams = _llamaContextDefaultParams!();
      cParams
        ..n_ctx = nCtx
        ..n_threads = nThreads
        ..n_batch = 512
        ..seed = 42;
      _ctx = _llamaNewContext!(_model!, cParams);
      if (_ctx == nullptr) {
        _llamaFreeModel!(_model!);
        _model = nullptr;
        throw LlmConnectionException(
          serverUrl: modelPath,
          originalError: 'llama_new_context_with_model returned null',
        );
      }

      _loaded = true;
    } catch (e) {
      if (e is LlmConnectionException) rethrow;
      throw LlmConnectionException(
        serverUrl: modelPath,
        originalError: 'Model load failed: $e',
      );
    }
  }

  /// 释放 llama.cpp 资源（模型、上下文、互斥量、库句柄）。
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    if (_ctx != nullptr) {
      _llamaFree!(_ctx!);
      _ctx = nullptr;
    }
    if (_model != nullptr) {
      _llamaFreeModel!(_model!);
      _model = nullptr;
    }
    if (_mutex != nullptr && _llamaMutexFree != null) {
      _llamaMutexFree!(_mutex!);
      _mutex = nullptr;
    }

    _loaded = false;
    _lib = null;
    // 注意：不要关闭 DynamicLibrary——Dart VM 在进程退出时自动管理。
  }

  @override
  Future<ParseCandidate> parse(String rawText, {String? bankName}) async {
    if (_disposed) {
      throw StateError('FfiLlmClient has been disposed');
    }
    _loadModel();

    String lastError = '';
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _attemptParse(rawText, bankName: bankName)
            .timeout(timeout);
      } on TimeoutException {
        lastError = 'FFI inference timeout on attempt $attempt';
        if (attempt == maxRetries) {
          throw LlmRetryExhaustedException(
            attempts: maxRetries,
            lastError: lastError,
          );
        }
      } on LlmJsonParseException {
        rethrow;
      } on LlmConnectionException {
        lastError = 'FFI inference error on attempt $attempt';
        if (attempt == maxRetries) {
          throw LlmRetryExhaustedException(
            attempts: maxRetries,
            lastError: lastError,
          );
        }
      }
    }
    throw LlmRetryExhaustedException(
      attempts: maxRetries,
      lastError: lastError,
    );
  }

  /// 单次 FFI 推理尝试。
  ///
  /// 1. 加锁（互斥量）
  /// 2. 构建提示词模板
  /// 3. 分词输入
  /// 4. 运行推理循环
  /// 5. 收集并解码输出 token
  /// 6. 解锁
  /// 7. 解析 JSON 输出为 ParseCandidate
  Future<ParseCandidate> _attemptParse(
    String rawText, {
    String? bankName,
  }) async {
    // 加锁
    if (_mutex != nullptr && _llamaMutexLock != null) {
      _llamaMutexLock!(_mutex!);
    }

    try {
      final prompt = _buildPrompt(rawText);

      // 分词
      final tokens = _tokenize(prompt);

      // 推理循环
      final output = _inferenceLoop(tokens);

      // 解析输出
      return _parseOutput(output, rawText, bankName);
    } finally {
      // 解锁
      if (_mutex != nullptr && _llamaMutexUnlock != null) {
        _llamaMutexUnlock!(_mutex!);
      }
    }
  }

  /// 将提示词文本分词为 token 序列。
  List<int> _tokenize(String text) {
    final textNative = text.toNativeUtf8();
    try {
      final textLen = text.length;
      // 分配内存——最多 nCtx 个 token
      final tokensPtr = calloc<Int32>(nCtx);
      try {
        final nTokens = _llamaTokenize!(
          _model!,
          textNative,
          textLen,
          tokensPtr,
          nCtx,
          1, // add_bos = true
          0, // special = false
        );

        if (nTokens < 0) {
          throw LlmConnectionException(
            serverUrl: modelPath,
            originalError: 'llama_tokenize returned $nTokens',
          );
        }

        return List<int>.generate(nTokens, (i) => tokensPtr[i]);
      } finally {
        calloc.free(tokensPtr);
      }
    } finally {
      calloc.free(textNative);
    }
  }

  /// 运行自回归推理循环。
  ///
  /// 逐个 token 解码，直到遇到 EOS token 或达到 nPredict 上限。
  String _inferenceLoop(List<int> tokens) {
    final nCtx = this.nCtx;
    final eosToken = _findEosToken();

    // 批量处理初始 token
    final batchSize = _llamaNCtx!(_ctx!);
    for (var i = 0; i < tokens.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, tokens.length);
      final chunk = tokens.sublist(i, end);
      if (chunk.isEmpty) break;

      final batch = _llamaBatchInit!(chunk.length, 0, 2);
      final tokenPtr = calloc<llama_token>(chunk.length);
      final posPtr = calloc<Int32>(chunk.length);
      final nSeqIdPtr = calloc<Int32>(chunk.length);
      final seqIdPtr = calloc<Pointer<Int32>>(chunk.length);

      try {
        for (var j = 0; j < chunk.length; j++) {
          tokenPtr[j] = chunk[j];
          posPtr[j] = i + j;
          nSeqIdPtr[j] = 1;
          final innerSeqId = calloc<Int32>(1);
          innerSeqId[0] = 0;
          seqIdPtr[j] = innerSeqId;
        }
        batch
          ..token = tokenPtr
          ..pos = posPtr
          ..n_seq_id = nSeqIdPtr
          ..seq_id = seqIdPtr
          ..logits = (i + chunk.length == tokens.length) ? 1 : 0;

        final code = _llamaDecode!(_ctx!, batch);
        if (code != 0) {
          throw LlmConnectionException(
            serverUrl: modelPath,
            originalError: 'llama_decode returned $code during prompt eval',
          );
        }
      } finally {
        for (var j = 0; j < chunk.length; j++) {
          if (seqIdPtr[j] != nullptr) calloc.free(seqIdPtr[j]);
        }
        calloc.free(tokenPtr);
        calloc.free(posPtr);
        calloc.free(nSeqIdPtr);
        calloc.free(seqIdPtr);
      }
    }

    // 自回归生成
    final outputTokens = <int>[];
    for (var i = 0; i < nPredict; i++) {
      // 采样下一个 token
      final sampledToken = _greedySample();
      if (sampledToken == eosToken) break;
      outputTokens.add(sampledToken);

      // 解码下一个 token
      final nextBatch = _llamaBatchInit!(1, 0, 2);
      final nextTokenPtr = calloc<llama_token>(1);
      final nextPosPtr = calloc<Int32>(1);
      final nextNSeqIdPtr = calloc<Int32>(1);
      final nextSeqIdPtr = calloc<Pointer<Int32>>(1);

      try {
        nextTokenPtr[0] = sampledToken;
        nextPosPtr[0] = tokens.length + i;
        nextNSeqIdPtr[0] = 1;
        final innerSeqId = calloc<Int32>(1);
        innerSeqId[0] = 0;
        nextSeqIdPtr[0] = innerSeqId;
        nextBatch
          ..token = nextTokenPtr
          ..pos = nextPosPtr
          ..n_seq_id = nextNSeqIdPtr
          ..seq_id = nextSeqIdPtr
          ..logits = 1;

        final code = _llamaDecode!(_ctx!, nextBatch);
        if (code != 0) {
          throw LlmConnectionException(
            serverUrl: modelPath,
            originalError: 'llama_decode returned $code during generation',
          );
        }
      } finally {
        if (nextSeqIdPtr[0] != nullptr) calloc.free(nextSeqIdPtr[0]);
        calloc.free(nextTokenPtr);
        calloc.free(nextPosPtr);
        calloc.free(nextNSeqIdPtr);
        calloc.free(nextSeqIdPtr);
      }
    }

    // 解码 token 为文本
    return _detokenize(outputTokens);
  }

  /// 贪心采样——选择得分最高的 token。
  ///
  /// 从上下文中获取最新 token 的 logits，为词汇表中的每个 token 填充
  /// 候选数组，然后调用 llama_sample_token_greedy 选择最优 token。
  int _greedySample() {
    final nVocab = _llamaNVocab!(_model!);
    final logitsPtr = _llamaGetLogits!(_ctx!);

    // 分配候选 token 数组
    final candidatesPtr = calloc<llama_token_data>(nVocab);
    final candidatesArrayPtr = calloc<llama_token_data_array>();

    try {
      // 从 logits 填充候选数组
      for (var i = 0; i < nVocab; i++) {
        candidatesPtr[i]
          ..id = i
          ..logit = logitsPtr[i]
          ..p = 0.0;
      }

      candidatesArrayPtr.ref
        ..data = candidatesPtr
        ..size = nVocab
        ..sorted = 0;

      final token = _llamaSampleTokenGreedy!(_ctx!, candidatesArrayPtr);
      return token;
    } finally {
      calloc.free(candidatesPtr);
      calloc.free(candidatesArrayPtr);
    }
  }

  /// 在词汇表中查找 EOS token。
  int _findEosToken() {
    // llama.cpp 标准 EOS token ID 通常为 2（Llama/ Qwen 系列）
    // 在支持的模型系列（Llama 2, Qwen2, Qwen2.5, Mistral）上，
    // EOS token ID 为 2。此处返回标准值。
    return 2;
  }

  /// 将 token 序列解码为文本字符串。
  String _detokenize(List<int> tokens) {
    final buf = StringBuffer();
    final pieceBuf = calloc<Utf8>(256);

    try {
      for (final token in tokens) {
        final len = _llamaTokenToPiece!(_model!, token, pieceBuf, 256, 0, 0);
        if (len < 0) continue;
        buf.write(pieceBuf.toDartString(length: len));
      }
    } finally {
      calloc.free(pieceBuf);
    }

    return buf.toString();
  }

  /// 解析 LLM 输出 JSON 为 ParseCandidate。
  ParseCandidate _parseOutput(
    String output,
    String rawText,
    String? bankName,
  ) {
    final trimmed = output.trim();

    // 移除可能的 Markdown 代码块包裹
    String jsonStr = trimmed;
    if (jsonStr.startsWith('```')) {
      final endIdx = jsonStr.lastIndexOf('```');
      if (endIdx > 3) {
        jsonStr = jsonStr.substring(3, endIdx).trim();
        // 移除可能的语言标识符行
        final newlineIdx = jsonStr.indexOf('\n');
        if (newlineIdx > 0 && jsonStr.substring(0, newlineIdx).trim() == 'json') {
          jsonStr = jsonStr.substring(newlineIdx + 1).trim();
        }
      }
    }

    final Map<String, dynamic> llmJson;
    try {
      llmJson = jsonDecode(jsonStr) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw LlmJsonParseException(
        rawResponse: output,
        parseError: e.message,
      );
    }

    final candidateJson = <String, dynamic>{
      'rawText': rawText,
      'candidateType': _mapCandidateType(
        llmJson['type'] as String? ?? 'unknown',
      ),
      'title': llmJson['title'] as String? ?? '',
      'options':
          (llmJson['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      'answer': llmJson['answer'] as String? ?? '',
      'explanation': llmJson['explanation'] as String? ?? '',
    };

    final candidate = ParseCandidate.fromJson(candidateJson);
    return candidate.copyWith(
      metadata: {
        'source': 'ffi',
        if (bankName != null) 'bankName': bankName,
      },
    );
  }

  /// 将 LLM type 字段值映射到 ParseCandidate candidateType 枚举值。
  String _mapCandidateType(String llmType) {
    return switch (llmType) {
      'single' => 'single_choice',
      'multiple' => 'multi_choice',
      'truefalse' => 'true_false',
      'short_answer' => 'short_answer',
      _ => 'unknown',
    };
  }

  /// 构建 Qwen2.5 聊天模板提示词。
  String _buildPrompt(String rawText) {
    return '<|im_start|>system\n'
        'Extract the following Chinese exam question into JSON.\n'
        'Output ONLY valid JSON matching the schema. '
        'No prose. No markdown fences. End with }.<|im_end|>\n'
        '<|im_start|>user\n'
        '$rawText<|im_end|>\n'
        '<|im_start|>assistant\n';
  }
}
