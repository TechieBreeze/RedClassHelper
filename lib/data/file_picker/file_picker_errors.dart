sealed class FilePickerError {
  const FilePickerError(this.message);
  final String message;
}
class FilePickCancelled extends FilePickerError { const FilePickCancelled(): super('cancelled'); }
class FilePickPermissionDenied extends FilePickerError { const FilePickPermissionDenied([super.message = 'permission denied']); }
class FilePickUnsupportedMethod extends FilePickerError { const FilePickUnsupportedMethod([super.message = 'unsupported on this platform']); }
class FileReadError extends FilePickerError { const FileReadError(super.message); }
class FilePickUnknown extends FilePickerError { const FilePickUnknown(super.message); }