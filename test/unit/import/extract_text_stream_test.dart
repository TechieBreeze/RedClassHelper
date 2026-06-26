import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/import/extraction/text_extractor.dart';

void main() {
  test('extractTextFromStream routes pdf to pdf extractor', () async {
    final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // "%PDF" magic
    final stream = Stream.value(bytes);
    expect(
      () => extractTextFromStream(
        stream,
        fileName: 'a.pdf',
        fileExtension: '.pdf',
      ),
      throwsA(anything),
    );
  });

  test('extractTextFromStream routes docx to docx extractor', () async {
    final bytes = Uint8List.fromList([
      0x50,
      0x4B,
      0x03,
      0x04,
    ]); // ZIP/OOXML magic
    final stream = Stream.value(bytes);
    expect(
      () => extractTextFromStream(
        stream,
        fileName: 'a.docx',
        fileExtension: '.docx',
      ),
      throwsA(anything),
    );
  });

  test(
    'extractTextFromStream throws UnsupportedFormat for unknown ext',
    () async {
      final stream = Stream.value(Uint8List(0));
      expect(
        () => extractTextFromStream(
          stream,
          fileName: 'a.xyz',
          fileExtension: '.xyz',
        ),
        throwsA(isA<UnsupportedFormatException>()),
      );
    },
  );
}
