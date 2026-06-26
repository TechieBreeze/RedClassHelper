import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'file_picker_service.dart';
import 'file_picker_models.dart';
import 'file_picker_errors.dart';

class DesktopFilePickerService implements FilePickerService {
  @override
  Future<PickedFile?> pickFile({
    required Set<String> allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: allowedExtensions.toList(),
        dialogTitle: dialogTitle,
      );
      if (result == null) return null;
      final f = result.files.single;
      if (f.path == null) {
        throw const FileReadError('Picked file has no path');
      }
      return PickedPathFile(name: f.name, path: f.path!, length: f.size);
    } on FilePickerError {
      rethrow;
    } catch (e) {
      throw FilePickUnknown(e.toString());
    }
  }

  @override
  Future<PickedFile?> pickFromDroppedPath(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileReadError('Dropped path does not exist: $path');
    }
    return PickedPathFile(
      name: path.split(Platform.pathSeparator).last,
      path: path,
      length: await file.length(),
    );
  }

  @override
  Future<void> dispose() async {}
}
