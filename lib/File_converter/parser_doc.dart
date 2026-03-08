// lib/file_converter/parser_doc.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Extract plain text from .docx bytes by reading word/document.xml.
/// Returns combined paragraphs separated by '\n'. Returns '' if nothing found.
String parseDocxBytes(Uint8List bytes) {
  // decode zip (.docx is a zip package)
  final archive = ZipDecoder().decodeBytes(bytes, verify: false);

  // find main document.xml
  final archiveFile = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
    orElse: () => ArchiveFile('word/document.xml', 0, Uint8List(0)),
  );

  final contentObj = archiveFile.content;

  // normalize content bytes
  final List<int> contentBytes = (contentObj is List<int>)
      ? contentObj
      : List<int>.from(contentObj as Iterable);

  if (contentBytes.isEmpty) return '';

  final xmlString = utf8.decode(contentBytes, allowMalformed: true);
  final xmlDoc = XmlDocument.parse(xmlString);
  final buffer = StringBuffer();

  // extract paragraph text: join descendant w:t nodes
  final paragraphs = xmlDoc.findAllElements('w:p');
  for (final p in paragraphs) {
    final texts = p.findAllElements('w:t').map((e) => e.text).join();
    if (texts.trim().isNotEmpty) buffer.writeln(texts.trim());
  }

  return buffer.toString().trim();
}
