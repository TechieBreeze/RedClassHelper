import 'file_picker_models.dart';

abstract interface class FilePickerService {
  Future<PickedFile?> pickFile({
    required Set<String> allowedExtensions,
    String? dialogTitle,
  });
  Future<PickedFile?> pickFromDroppedPath(String path);
  Future<void> dispose();
}
