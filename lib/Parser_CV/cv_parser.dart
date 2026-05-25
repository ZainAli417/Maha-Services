// lib/services/cv_parser.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../main.dart';

class CvExtractionResult {
  final String rawText;
  final Map<String, dynamic> personalProfile;
  final List<Map<String, String>> educationalProfile;
  final String professionalSummary;
  final List<Map<String, dynamic>> professionalExperience;
  final List<Map<String, String>> certifications;
  final List<String> publications;
  final List<String> awards;
  final List<String> references;

  CvExtractionResult({
    required this.rawText,
    required this.personalProfile,
    required this.educationalProfile,
    required this.professionalSummary,
    required this.professionalExperience,
    required this.certifications,
    required this.publications,
    required this.awards,
    required this.references,
  });

  factory CvExtractionResult.empty() => CvExtractionResult(
    rawText: '',
    personalProfile: {},
    educationalProfile: [],
    professionalSummary: '',
    professionalExperience: [],
    certifications: [],
    publications: [],
    awards: [],
    references: [],
  );

  factory CvExtractionResult.fromJson(Map<String, dynamic> j) {
    final personal =
        (j['personalProfile'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v),
        ) ??
        {};

    final edu = <Map<String, String>>[];
    if (j['educationalProfile'] is List) {
      for (final e in (j['educationalProfile'] as List)) {
        if (e is Map) {
          edu.add({
            'institutionName': (e['institutionName'] ?? '').toString(),
            'duration': (e['duration'] ?? '').toString(),
            'majorSubjects': (e['majorSubjects'] ?? '').toString(),
            'marksOrCgpa': (e['marksOrCgpa'] ?? '').toString(),
          });
        }
      }
    }

    final exps = <Map<String, dynamic>>[];
    if (j['professionalExperience'] is List) {
      for (final e in (j['professionalExperience'] as List)) {
        if (e is Map) {
          exps.add({
            'organization': (e['organization'] ?? '').toString(),
            'duration': (e['duration'] ?? '').toString(),
            'role': (e['role'] ?? '').toString(),
            'duties': (e['duties'] ?? '').toString(),
            'rank': (e['rank'] ?? '').toString(),
            'unit': (e['unit'] ?? '').toString(),
            'command': (e['command'] ?? '').toString(),
            'location': (e['location'] ?? '').toString(),
            'aircraftType': (e['aircraftType'] ?? '').toString(),
            'flightHours': (e['flightHours'] ?? '').toString(),
            'startDate': (e['startDate'] ?? '').toString(),
            'endDate': (e['endDate'] ?? '').toString(),
          });
        }
      }
    }

    final certs = <Map<String, String>>[];
    if (j['certifications'] is List) {
      for (final c in (j['certifications'] as List)) {
        if (c is Map) {
          certs.add({
            'organization': (c['organization'] ?? '').toString(),
            'name': (c['name'] ?? '').toString(),
          });
        } else if (c is String && c.isNotEmpty) {
          certs.add({'organization': '', 'name': c});
        }
      }
    }

    List<String> listFrom(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) {
        return v
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    return CvExtractionResult(
      rawText: (j['rawText'] ?? j['text'] ?? '').toString(),
      personalProfile: personal,
      educationalProfile: edu,
      professionalSummary: (j['professionalSummary'] ?? '').toString(),
      professionalExperience: exps,
      certifications: certs,
      publications: listFrom(j['publications']),
      awards: listFrom(j['awards']),
      references: listFrom(j['references']),
    );
  }
}

class CvExtractor {
  final Duration timeout;

  CvExtractor({this.timeout = const Duration(seconds: 90)});

  Future<CvExtractionResult> extractFromFileBytes(
    Uint8List bytes, {
    required String filename,
  }) async {
    try {
      final response = await _callServerParser(bytes, filename);
      return response;
    } catch (e) {
      return CvExtractionResult.empty();
    }
  }

  Future<CvExtractionResult> _callServerParser(
    Uint8List fileBytes,
    String filename,
  ) async {
    final uri = Uri.parse('${Env.backendUrl}/cv-parser');

    try {
      final mimeType = _getMimeType(filename);
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        );

      final streamed = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = json.decode(response.body);
        return CvExtractionResult.fromJson(
          jsonResponse as Map<String, dynamic>,
        );
      } else {
        final errorBody = response.body;
        String errorMsg = 'Server API error (${response.statusCode})';

        try {
          final errorJson = json.decode(errorBody);
          if (errorJson['error'] != null) {
            errorMsg += ': ${errorJson['error']}';
          }
          if (errorJson['message'] != null) {
            errorMsg += ' - ${errorJson['message']}';
          }
        } catch (_) {
          if (errorBody.length < 200) {
            errorMsg += ': $errorBody';
          }
        }

        throw Exception(errorMsg);
      }
    } catch (error) {
      return CvExtractionResult.empty();
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'rtf':
        return 'application/rtf';
      default:
        return 'application/octet-stream';
    }
  }

  static bool isSupportedFileType(String filename) {
    final ext = filename.toLowerCase();
    return ext.endsWith('.pdf') ||
        ext.endsWith('.doc') ||
        ext.endsWith('.docx') ||
        ext.endsWith('.txt');
  }
}
