// lib/file_converter/type_detect.dart
import 'dart:typed_data';

enum DetectedFile { pdf, docx, doc, txt, unknown }

DetectedFile detectFileType(Uint8List bytes, String filename) {
  if (bytes.length >= 4) {
    // PDF: starts with "%PDF"
    final header = String.fromCharCodes(bytes.sublist(0, 4));
    if (header == '%PDF') return DetectedFile.pdf;

    // ZIP (docx, pptx, xlsx) starts with PK\x03\x04
    if (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
      final fn = filename.toLowerCase();
      if (fn.endsWith('.docx')) return DetectedFile.docx;
      return DetectedFile.docx; // treat zip-like as docx by default
    }

    // DOC (Compound File Binary File) signature: D0 CF 11 E0 ...
    if (bytes.length >= 8 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      return DetectedFile.doc;
    }
  }

  // fallback via extension
  final ext = filename.toLowerCase();
  if (ext.endsWith('.txt')) return DetectedFile.txt;
  if (ext.endsWith('.pdf')) return DetectedFile.pdf;
  if (ext.endsWith('.docx')) return DetectedFile.docx;
  if (ext.endsWith('.doc')) return DetectedFile.doc;
  return DetectedFile.unknown;
}
