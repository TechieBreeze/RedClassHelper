import 'dart:typed_data';
import 'package:redclass/data/file_picker/file_picker_service.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';

class FakeFilePickerService implements FilePickerService {
  PickedFile? nextResult;
  Object? nextError;
  final List<({Set<String> extensions, String? title})> calls = [];

  @override
  Future<PickedFile?> pickFile({
    required Set<String> allowedExtensions,
    String? dialogTitle,
  }) async {
    calls.add((extensions: allowedExtensions, title: dialogTitle));
    if (nextError != null) throw nextError!;
    return nextResult;
  }

  @override
  Future<PickedFile?> pickFromDroppedPath(String path) async => null;
  @override
  Future<void> dispose() async {}
}

PickedFile fakePdfFile({String name = 'test.pdf'}) =>
    PickedBytesFile(name: name, bytes: Uint8List.fromList([1, 2, 3]));
