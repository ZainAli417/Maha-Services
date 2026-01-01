// lib/services/cv_extractor.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../File_converter/parser_doc.dart';
import '../File_converter/type_detect.dart'; // (optional, keeps linter happy if used elsewhere)

class CvExtractionResult {
  final String rawText;
  final Map<String, dynamic> personalProfile;
  final List<Map<String, String>> educationalProfile;
  final String professionalSummary;
  final List<Map<String, dynamic>> experiences;
  final List<String> certifications;
  final List<String> publications;
  final List<String> awards;
  final List<String> references;

  CvExtractionResult({
    required this.rawText,
    required this.personalProfile,
    required this.educationalProfile,
    required this.professionalSummary,
    required this.experiences,
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
    experiences: [],
    certifications: [],
    publications: [],
    awards: [],
    references: [],
  );

  factory CvExtractionResult.fromJson(Map<String, dynamic> j) {
    final personal = (j['personalProfile'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
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
    if (j['experiences'] is List) {
      for (final e in (j['experiences'] as List)) {
        if (e is Map) exps.add(Map<String, dynamic>.from(e));
      }
    }

    List<String> listFrom(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) return v.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      return [];
    }

    return CvExtractionResult(
      rawText: (j['rawText'] ?? j['text'] ?? '').toString(),
      personalProfile: personal,
      educationalProfile: edu,
      professionalSummary: (j['professionalSummary'] ?? '').toString(),
      experiences: exps,
      certifications: listFrom(j['certifications']),
      publications: listFrom(j['publications']),
      awards: listFrom(j['awards']),
      references: listFrom(j['references']),
    );
  }
}

class CvExtractor {
  final String geminiApiKey;
  final String geminiModel; // e.g. 'gemini-2.5-flash'
  final Duration timeout;

  CvExtractor({
    required this.geminiApiKey,
    this.geminiModel = 'gemini-2.5-flash',
    this.timeout = const Duration(seconds: 90),
  });

  Future<CvExtractionResult> extractFromFileBytes(
      Uint8List bytes, {
        required String filename,
        String? geminiEndpointOverride, // if you use a proxy/backend; otherwise direct to Google API
      }) async {
    final detected = detectFileType(bytes, filename);

    try {
      if (detected == DetectedFile.pdf) {
        // PDF -> send the binary to Gemini directly (expected JSON response)
        final parsed = await _sendPdfToGemini(bytes, filename, geminiEndpointOverride);
        return parsed;
      }

      if (detected == DetectedFile.docx) {
        // DOCX -> parse locally to plain text, then send that text to Gemini for structured JSON
        String text;
        try {
          text = parseDocxBytes(bytes);
        } catch (e) {
          // fallback: try utf8 decode
          try {
            text = utf8.decode(bytes);
          } catch (_) {
            text = '';
          }
        }

        if (text.trim().isEmpty) {
          // If parsing produced no text, fallback to sending raw base64 (less ideal) or return empty
          // Prefer to fallback to remote if available
          if (geminiEndpointOverride != null) {
            return await _sendRawFileBase64ToGemini(bytes, filename, geminiEndpointOverride);
          } else {
            return CvExtractionResult.empty();
          }
        }

        return await _sendTextToGemini(text, filename, geminiEndpointOverride);
      }

      if (detected == DetectedFile.doc) {
        // Legacy .doc — cannot parse reliably client-side; try utf8 decode, then remote
        try {
          final text = utf8.decode(bytes);
          if (text.trim().isNotEmpty) return await _sendTextToGemini(text, filename, geminiEndpointOverride);
        } catch (_) {}
        if (geminiEndpointOverride != null) {
          return await _sendRawFileBase64ToGemini(bytes, filename, geminiEndpointOverride);
        }
        return CvExtractionResult.empty();
      }

      // TXT or unknown: decode text and send
      try {
        final text = utf8.decode(bytes);
        if (text.trim().isNotEmpty) return await _sendTextToGemini(text, filename, geminiEndpointOverride);
      } catch (_) {}
      return CvExtractionResult.empty();
    } catch (e) {
      return CvExtractionResult.empty();
    }
  }

  Future<CvExtractionResult> _sendPdfToGemini(Uint8List bytes, String filename, String? endpointOverride) async {
    final mimeType = 'application/pdf';
    final b64 = base64Encode(bytes);

    final promptText = _buildPrompt();

    final payload = {
      "contents": [
        {
          "parts": [
            {
              "inlineData": {"mimeType": mimeType, "data": b64}
            },
            {
              "text": promptText
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 40,
        "topP": 1,
      }
    };

    final respText = await _postToGemini(payload, endpointOverride);
    return _parseGeminiJsonResponse(respText);
  }

  Future<CvExtractionResult> _sendTextToGemini(String text, String filename, String? endpointOverride) async {
    final promptText = _buildPrompt();

    final payload = {
      "contents": [
        {
          "parts": [
            {
              "text": text
            },
            {
              "text": promptText
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 40,
        "topP": 1,
      }
    };

    final respText = await _postToGemini(payload, endpointOverride);
    return _parseGeminiJsonResponse(respText);
  }

  Future<CvExtractionResult> _sendRawFileBase64ToGemini(Uint8List bytes, String filename, String? endpointOverride) async {
    final mimeType = 'application/octet-stream';
    final b64 = base64Encode(bytes);
    final promptText = structure_doc();

    final payload = {
      "contents": [
        {
          "parts": [
            {
              "inlineData": {"mimeType": mimeType, "data": b64, "filename": filename}
            },
            {
              "text": promptText
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 40,
        "topP": 1,
      }
    };

    final respText = await _postToGemini(payload, endpointOverride);
    return _parseGeminiJsonResponse(respText);
  }

  String _buildPrompt() {
    return '''
Extract information from this CV/resume Use bold and Bullets notations FOR ARRAY data means list data should use bullets and return ONLY a JSON object with the following structure:

{
  "rawText": "full extracted text from the document",
  "personalProfile": {
    "name": "full name",
    "email": "email address", 
    "contactNumber": "phone number",
    "nationality": "nationality",
    "skills": ["skill1", "skill2", "skill3"]
  },
  "educationalProfile": [
    {
      "institutionName": "university/school name",
      "duration": "start year - end year",
      "majorSubjects": "field of study",
      "marksOrCgpa": "GPA or marks"
    }
  ],
  "professionalSummary": "brief professional summary",
  "experiences": [
    {
      "text": "job title, company, duration, responsibilities"
    }
  ],
  "certifications": ["cert1", "cert2"],
  "publications": ["pub1", "pub2"], 
  "awards": ["award1", "award2"],
  "references": ["reference1", "reference2"]
}

IMPORTANT: 
- Return ONLY the JSON object, no other text
- Use empty strings or empty arrays for missing fields
- Extract as much information as possible from the document
''';
  }
  String structure_doc() {
    return '''
Structure the Raw data into proper layout mentioned below. Use bold and Bullets notations FOR ARRAY data means list data should use bullets and return ONLY a JSON object with the following structure:

{
  "rawText": "full extracted text from the document",
  "personalProfile": {
    "name": "full name",
    "email": "email address", 
    "contactNumber": "phone number",
    "nationality": "nationality",
    "skills": ["skill1", "skill2", "skill3"]
  },
  "educationalProfile": [
    {
      "institutionName": "university/school name",
      "duration": "start year - end year",
      "majorSubjects": "field of study",
      "marksOrCgpa": "GPA or marks"
    }
  ],
  "professionalSummary": "brief professional summary",
  "experiences": [
    {
      "text": "job title, company, duration, responsibilities"
    }
  ],
  "certifications": ["cert1", "cert2"],
  "publications": ["pub1", "pub2"], 
  "awards": ["award1", "award2"],
  "references": ["reference1", "reference2"]
}

IMPORTANT: 
- Return ONLY the JSON object, no other text
- Use empty strings or empty arrays for missing fields
- Extract as much information as possible from the document
''';
  }

  Future<String> _postToGemini(Map<String, dynamic> payload, String? endpointOverride) async {
    final url = (endpointOverride != null && endpointOverride.isNotEmpty)
        ? Uri.parse(endpointOverride)
        : Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiApiKey');

    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload)).timeout(timeout);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Gemini API error ${resp.statusCode}: ${resp.body}');
    }

    return resp.body;
  }

  CvExtractionResult _parseGeminiJsonResponse(String apiResponseBody) {
    try {
      final body = jsonDecode(apiResponseBody) as Map<String, dynamic>;

      // gather text from candidates -> content -> parts[].text
      String responseText = '';

      if (body['candidates'] != null && body['candidates'] is List && (body['candidates'] as List).isNotEmpty) {
        final candidate = (body['candidates'] as List).first;
        if (candidate is Map && candidate['content'] != null && candidate['content']['parts'] != null) {
          final parts = candidate['content']['parts'] as List;
          for (final part in parts) {
            if (part is Map && part['text'] != null) {
              responseText += part['text'].toString();
            }
          }
        }
      }

      // Some endpoints return 'output' or different shape; fallback scanning keys for 'text'
      if (responseText.isEmpty) {
        // try to find any nested 'text' values
        void collectText(dynamic node) {
          if (node is Map) {
            node.forEach((k, v) {
              if (k == 'text' && v is String) responseText += v;
              collectText(v);
            });
          } else if (node is List) {
            for (final e in node) {
              collectText(e);
            }
          }
        }

        collectText(body);
      }

      if (responseText.trim().isEmpty) {
        // fallback: maybe top-level 'rawText' present
        if (body['rawText'] is String) {
          responseText = body['rawText'];
        } else if (body['text'] is String) {
          responseText = body['text'];
        }
      }

      if (responseText.trim().isEmpty) {
        return CvExtractionResult.empty();
      }

      // strip triple-backtick fences and any surrounding code block markers
      String clean = responseText.replaceAll(RegExp(r'```json', caseSensitive: false), '').replaceAll('```', '').trim();

      // some responses might include explanatory lines before JSON; find first '{'
      final firstBrace = clean.indexOf('{');
      if (firstBrace > 0) clean = clean.substring(firstBrace);

      final parsed = jsonDecode(clean) as Map<String, dynamic>;
      return CvExtractionResult.fromJson(parsed);
    } catch (e) {
      return CvExtractionResult.empty();
    }
  }

  static bool isSupportedFileType(String filename) {
    final ext = filename.toLowerCase();
    return ext.endsWith('.pdf') || ext.endsWith('.doc') || ext.endsWith('.docx') || ext.endsWith('.txt');
  }
}
