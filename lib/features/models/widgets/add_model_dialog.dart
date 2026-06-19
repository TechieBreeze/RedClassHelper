// lib/features/models/widgets/add_model_dialog.dart
// ── Add custom model dialog ──
// Two-tab dialog: URL paste (with HTTPS + .gguf validation) and
// local file picker (with GGUF magic number validation).
// Returns ModelInfo? via showDialog().

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../providers/model_catalog_provider.dart';
import '../services/gguf_validator.dart';

/// Shows the AddModelDialog and returns a [ModelInfo] if the user added a model, or null.
Future<ModelInfo?> showAddModelDialog(BuildContext context) {
  return showDialog<ModelInfo?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AddModelDialog(),
  );
}

class _AddModelDialog extends StatefulWidget {
  const _AddModelDialog();

  @override
  State<_AddModelDialog> createState() => _AddModelDialogState();
}

class _AddModelDialogState extends State<_AddModelDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _urlController = TextEditingController();

  // Tab 1 (URL) state
  String? _urlError;

  // Tab 2 (Local file) state
  String? _selectedFilePath;
  String? _selectedFileSize;
  String? _fileError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _isUrlTab => _tabController.index == 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加自定义模型'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '从 URL 下载'),
                Tab(text: '选择本地文件'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUrlTab(),
                  _buildLocalFileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(_isUrlTab ? '添加并下载' : '导入模型'),
        ),
      ],
    );
  }

  Widget _buildUrlTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: '模型下载地址',
              hintText: '粘贴 HuggingFace 或 ModelScope GGUF 文件直链',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _validateUrl(),
            keyboardType: TextInputType.url,
          ),
          if (_urlError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _urlError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalFileTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('浏览…'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedFilePath != null
                      ? _selectedFilePath!.split(Platform.pathSeparator).last
                      : '未选择文件',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedFilePath != null) ...[
            Text(
              _selectedFilePath!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (_selectedFileSize != null) ...[
              const SizedBox(height: 4),
              Text(
                _selectedFileSize!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
          if (_fileError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _fileError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _validateUrl() {
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      setState(() => _urlError = null);
      return;
    }
    if (!text.startsWith('https://')) {
      setState(() => _urlError = '请输入有效的 HTTPS URL');
      return;
    }
    final uri = Uri.tryParse(text);
    if (uri == null) {
      setState(() => _urlError = '请输入有效的 HTTPS URL');
      return;
    }
    if (!uri.path.toLowerCase().endsWith('.gguf')) {
      setState(() => _urlError = '该地址不指向 .gguf 文件');
      return;
    }
    setState(() => _urlError = null);
  }

  Future<void> _pickFile() async {
    setState(() => _fileError = null);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    // Validate extension
    if (!filePath.toLowerCase().endsWith('.gguf')) {
      setState(() {
        _selectedFilePath = filePath;
        _selectedFileSize = null;
        _fileError = '仅支持 .gguf 文件';
      });
      return;
    }

    // Validate GGUF magic number
    final validationError = await GgufValidator.validateGgufFile(filePath);
    if (validationError != null) {
      setState(() {
        _selectedFilePath = filePath;
        _selectedFileSize = null;
        _fileError = validationError;
      });
      return;
    }

    final file = File(filePath);
    final sizeBytes = await file.length();
    final sizeDisplay = sizeBytes >= 1073741824
        ? '约 ${(sizeBytes / 1073741824).toStringAsFixed(1)} GB'
        : '约 ${(sizeBytes / 1048576).toStringAsFixed(0)} MB';

    setState(() {
      _selectedFilePath = filePath;
      _selectedFileSize = sizeDisplay;
      _fileError = null;
    });
  }

  bool get _canSubmit {
    if (_isUrlTab) {
      return _urlController.text.trim().isNotEmpty && _urlError == null;
    }
    return _selectedFilePath != null && _fileError == null;
  }

  void _submit() {
    if (_isUrlTab) {
      final url = _urlController.text.trim();
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final fileName =
          segments.isNotEmpty ? segments.last : 'custom_model.gguf';
      final name = fileName.endsWith('.gguf')
          ? fileName.substring(0, fileName.length - 5)
          : fileName;
      final modelId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '-');

      Navigator.of(context).pop(
        ModelInfo(
          id: modelId,
          name: name,
          tier: ModelTier.custom,
          sizeBytes: 0, // Unknown until downloaded
          sizeDisplay: '未知大小',
          ramRequirement: '未知',
          description: '自定义模型（URL 导入）',
          downloadUrl: url,
          sha256Hash: '',
        ),
      );
    } else {
      final filePath = _selectedFilePath!;
      final fileName = filePath.split(Platform.pathSeparator).last;
      final name = fileName.endsWith('.gguf')
          ? fileName.substring(0, fileName.length - 5)
          : fileName;
      final modelId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '-');

      Navigator.of(context).pop(
        ModelInfo(
          id: modelId,
          name: name,
          tier: ModelTier.custom,
          sizeBytes: 0, // Will be detected from file
          sizeDisplay: _selectedFileSize ?? '未知大小',
          ramRequirement: '未知',
          description: '自定义模型（本地导入）',
          downloadUrl: 'file://$filePath',
          sha256Hash: '',
        ),
      );
    }
  }
}
