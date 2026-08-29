import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// A file the candidate attached to a `file` question.
class UploadedDocument {
  const UploadedDocument({
    required this.name,
    required this.url,
    required this.size,
    required this.contentType,
    required this.path,
  });

  final String name;
  final String url;
  final int size;
  final String contentType;

  /// Storage path, kept so the file can be replaced or removed later.
  final String path;

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'size': size,
        'contentType': contentType,
        'path': path,
      };

  factory UploadedDocument.fromJson(Map<String, dynamic> j) => UploadedDocument(
        name: (j['name'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        size: j['size'] is int ? j['size'] as int : 0,
        contentType: (j['contentType'] ?? '').toString(),
        path: (j['path'] ?? '').toString(),
      );

  String get readableSize {
    if (size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Uploads onboarding attachments to `Job_Seeker/{uid}/onboarding_documents/`.
class OnboardingUploadService {
  OnboardingUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Matches the storage rule for this prefix.
  static const int maxBytes = 10 * 1024 * 1024;

  static const allowedContentTypes = {
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/zip',
    'text/plain',
    'text/csv',
    'image/jpeg',
    'image/png',
  };

  Future<UploadedDocument> upload({
    required String uid,
    required String questionId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.length > maxBytes) {
      throw const OnboardingUploadException('File exceeds the 10MB limit.');
    }
    if (!allowedContentTypes.contains(contentType)) {
      throw OnboardingUploadException('Unsupported file type: $contentType');
    }

    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'Job_Seeker/$uid/onboarding_documents/${questionId}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();

    return UploadedDocument(
      name: filename,
      url: url,
      size: bytes.length,
      contentType: contentType,
      path: path,
    );
  }

  Future<void> remove(UploadedDocument doc) async {
    if (doc.path.isEmpty) return;
    await _storage.ref(doc.path).delete();
  }
}

class OnboardingUploadException implements Exception {
  const OnboardingUploadException(this.message);
  final String message;
  @override
  String toString() => message;
}
