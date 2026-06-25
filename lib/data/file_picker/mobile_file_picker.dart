import 'package:file_picker/file_picker.dart' as fp;
import 'file_picker_service.dart';
import 'file_picker_models.dart';
import 'file_picker_errors.dart';

class MobileFilePickerService implements FilePickerService {
  @override
  Future<PickedFile?> pickFile({required Set<String> allowedExtensions, String? dialogTitle}) async {
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: allowedExtensions.toList(),
        withData: true,
      );
      if (result == null) return null;
      final f = result.files.single;
      if (f.bytes == null) {
        throw const FileReadError('Picked file has no bytes (withData failed)');
      }
      return PickedBytesFile(name: f.name, bytes: f.bytes!);
    } on FilePickerError {
      rethrow;
    } catch (e) {
      throw FilePickUnknown(e.toString());
    }
  }
  @override
  Future<PickedFile?> pickFromDroppedPath(String path) async {
    throw const FilePickUnsupportedMethod('Drop is desktop-only');
  }
  @override
  Future<void> dispose() async {}
}
