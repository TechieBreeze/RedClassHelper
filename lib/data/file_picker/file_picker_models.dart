import 'dart:io';
import 'dart:typed_data';

sealed class PickedFile {
  const PickedFile();
  String get name;
  Stream<Uint8List> openRead();
}

class PickedPathFile extends PickedFile {
  const PickedPathFile({required this.path, required this.name, required this.length});
  @override final String path;
  @override final String name;
  final int length;
  @override Stream<Uint8List> openRead() => File(path).openRead().map(Uint8List.fromList);
}

class PickedBytesFile extends PickedFile {
  const PickedBytesFile({required this.bytes, required this.name});
  @override final Uint8List bytes;
  @override final String name;
  @override Stream<Uint8List> openRead() => Stream.value(bytes);
}