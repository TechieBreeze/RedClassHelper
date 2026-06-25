import 'dart:io' show Platform;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'file_picker_service.dart';
import 'mobile_file_picker.dart';
import 'desktop_file_picker.dart';

part 'file_picker_providers.g.dart';

@Riverpod(keepAlive: true)
FilePickerService filePickerService(Ref ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return MobileFilePickerService();
  }
  return DesktopFilePickerService();
}
