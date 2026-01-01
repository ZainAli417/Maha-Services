// file: cv_analyzer_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;

import '../main.dart';

class CVAnalyzerBackendProvider extends ChangeNotifier {
  // State management
  bool _isLoading = false;
  double _progress = 0.0;
  String? _error;
  double? _score;
  String? _advisory;
  List<Map<String, dynamic>> _highlights = [];

  // Cancellation support
  bool _isCancelled = false;
  Timer? _progressTimer;

  // Getters
  bool get isLoading => _isLoading;
  double get progress => _progress;
  String? get error => _error;
  double? get score => _score;
  String? get advisory => _advisory;
  List<Map<String, dynamic>> get highlights => _highlights;

  final bool useDirectGemini;
  final String geminiApiKey;
  final String geminiModel;

  // Constants
  static const int maxFileBytes = 2 * 1024 * 1024; // 2 MB
  static const Duration requestTimeout = Duration(seconds: 120);
  static const int maxRetries = 3;

  // Supported file types
  static const List<String> supportedExtensions = [
    'pdf', 'doc', 'docx', 'txt', 'rtf'
  ];

  CVAnalyzerBackendProvider({
    this.useDirectGemini = true,
    String? geminiApiKey, // accept nullable
    this.geminiModel = 'gemini-2.5-flash',
 // }) : geminiApiKey = geminiApiKey ?? ''; // init list sets final field
  }) : geminiApiKey = geminiApiKey ?? Env.geminiApiKey; // init list sets final field

  // State setters
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setProgress(double p) {
    if (_isCancelled) return;
    _progress = p.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  void _setResult({double? sc, String? adv, List<Map<String, dynamic>>? hl}) {
    _score = sc;
    _advisory = adv;
    _highlights = hl ?? [];
    notifyListeners();
  }

  /// Cancel ongoing operation
  void cancel() {
    _isCancelled = true;
    _progressTimer?.cancel();
    _setLoading(false);
    _setError('Operation cancelled by user');
  }

  /// Smooth progress animation
  void _animateProgress({
    required double from,
    required double to,
    required int durationMs,
  }) {
    _progressTimer?.cancel();
    _setProgress(from);

    final steps = (durationMs / 50).round();
    final increment = (to - from) / steps;
    int currentStep = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isCancelled || currentStep >= steps) {
        timer.cancel();
        if (!_isCancelled) _setProgress(to);
        return;
      }
      currentStep++;
      _setProgress(from + (increment * currentStep));
    });
  }

  /// Validate file before processing
  Future<void> _validateFile(PlatformFile file) async {
    // Check extension
    final extension = file.extension?.toLowerCase() ?? '';
    if (!supportedExtensions.contains(extension)) {
      throw Exception(
          'Unsupported file type: .$extension\nSupported: ${supportedExtensions.join(", ")}'
      );
    }

    // Check size
    final size = await _getFileSize(file);
    if (size == 0) {
      throw Exception('File is empty or cannot be read');
    }
    if (size > maxFileBytes) {
      throw Exception(
          'File size (${_formatBytes(size)}) exceeds maximum (${_formatBytes(maxFileBytes)})'
      );
    }
  }

  /// Get file size reliably across platforms
  Future<int> _getFileSize(PlatformFile file) async {
    if (file.size > 0) return file.size;
    if (file.bytes != null) return file.bytes!.lengthInBytes;
    if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
      return await io.File(file.path!).length();
    }
    return 0;
  }

  /// Get file bytes reliably
  Future<Uint8List> _getFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes!;
    }

    if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
      return await io.File(file.path!).readAsBytes();
    }

    throw Exception('Unable to read file content');
  }

  /// Get MIME type for file
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

  /// Main analysis entry point
  Future<void> analyzeCV({
    required PlatformFile file,
    required String roleName,
    required String jobDescription,
  }) async {
    // Reset state
    _isCancelled = false;
    _setError(null);
    _setResult(sc: null, adv: null, hl: []);
    _setLoading(true);
    _setProgress(0.0);

    try {
      // Validate inputs
      if (roleName.trim().isEmpty) {
        throw Exception('Role name is required');
      }

      // Validate file
      _animateProgress(from: 0.0, to: 0.08, durationMs: 500);
      await _validateFile(file);

      // Route to appropriate backend
      if (useDirectGemini) {
        await _analyzeWithGemini(file, roleName, jobDescription);
      }

    } catch (e) {
      if (!_isCancelled) {
        _setError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      _progressTimer?.cancel();
      _setLoading(false);
      if (!_isCancelled && _progress < 1.0) {
        _setProgress(1.0);
      }
    }
  }

  /// Analyze using Gemini API directly (lets Gemini parse the file)
  Future<void> _analyzeWithGemini(
      PlatformFile file,
      String roleName,
      String jobDescription,
      ) async {
    if (geminiApiKey.isEmpty) {
      throw Exception('Gemini API key is required');
    }

    // Read file bytes
    _animateProgress(from: _progress, to: 0.25, durationMs: 1000);
    final fileBytes = await _getFileBytes(file);
    final base64Data = base64Encode(fileBytes);
    final mimeType = _getMimeType(file.name);

    _setProgress(0.30);

    // Build prompt
    final prompt = _buildAnalysisPrompt(roleName, jobDescription);

    // Call Gemini with retry logic
    _animateProgress(from: 0.30, to: 0.85, durationMs: 4000);
    final result = await _callGeminiWithRetry(
      prompt: prompt,
      fileData: base64Data,
      mimeType: mimeType,
    );

    _progressTimer?.cancel();
    _setProgress(0.90);

    // Parse and set results
    await Future.delayed(const Duration(milliseconds: 300));
    _parseAndSetResult(result);

    _setProgress(1.0);
  }

  /// Call Gemini API with automatic retry and exponential backoff
  Future<String> _callGeminiWithRetry({
    required String prompt,
    required String fileData,
    required String mimeType,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      if (_isCancelled) throw Exception('Operation cancelled');

      try {
        return await _callGeminiAPI(
          prompt: prompt,
          fileData: fileData,
          mimeType: mimeType,
        );
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;

        if (attempt < maxRetries) {
          // Exponential backoff: 2s, 4s, 8s...
          final delaySeconds = (2 << (attempt - 1));
          debugPrint('Retry attempt $attempt after $delaySeconds seconds...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }

    throw lastError ?? Exception('Failed after $maxRetries attempts');
  }

  /// Make actual Gemini API call
  Future<String> _callGeminiAPI({
    required String prompt,
    required String fileData,
    required String mimeType,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent',
    );

    // Build payload with inline file data
    final payload = {
      'contents': [
        {
          'parts': [
            {
              'text': prompt,
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': fileData,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.6,
        'topK': 40,
        'topP': 0.95,
        'responseMimeType': 'application/json',
      },
      'systemInstruction': {
        'parts': [
          {
            'text': '''You are a professional CV analysis assistant and ATC System. 
Analyze CV against the parameters sent to you thoroughly and provide structured feedback.
Always return valid JSON matching the exact schema specified in the prompt.
Be objective, constructive, and specific in your analysis.'''
          }
        ]
      },
    };

    final response = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': geminiApiKey,
      },
      body: json.encode(payload),
    )
        .timeout(requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonResponse = json.decode(response.body);
      return _extractTextFromGeminiResponse(jsonResponse);
    } else {
      final errorBody = response.body;
      String errorMsg = 'Gemini API error (${response.statusCode})';

      try {
        final errorJson = json.decode(errorBody);
        if (errorJson['error']?['message'] != null) {
          errorMsg += ': ${errorJson['error']['message']}';
        }
      } catch (_) {
        if (errorBody.length < 200) {
          errorMsg += ': $errorBody';
        }
      }

      throw Exception(errorMsg);
    }
  }

  /// Extract text response from Gemini API response
  String _extractTextFromGeminiResponse(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No candidates in response');
      }

      final content = candidates[0]['content'];
      final parts = content?['parts'] as List?;

      if (parts == null || parts.isEmpty) {
        throw Exception('No parts in response');
      }

      final text = parts[0]['text']?.toString() ?? '';
      if (text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      return text;
    } catch (e) {
      throw Exception('Failed to parse Gemini response: ${e.toString()}');
    }
  }


  /// Build analysis prompt
  String _buildAnalysisPrompt(String roleName, String jobDescription) {
    return '''Analyze the attached CV/resume document for the following position:

**Role:** $roleName

**Job Description:**
$jobDescription

**Analysis Requirements:**
1. Calculate an overall match score (0-100) based on skills, experience, and qualifications
2. Identify key strengths that align with the user selected role
3. Point out gaps or areas for improvement for the role user wants
4. Provide actionable recommendations according t JOb description given to you
5. Highlight relevant experience and skills

**Output Format:**
Return a JSON object with this exact structure:
{
  "score": <number 0-100>,
  "advisory": "<comprehensive analysis paragraph covering match assessment, strengths, weaknesses, and recommendations>",
  "highlights": [
    {
      "type": "strength|weakness|skill|experience|gap",
      "text": "<concise title/summary>",
      "detail": "<detailed explanation>"
    }
  ]
}

**Important:**
- Be specific and reference actual content from the CV
- Provide at least 5-8 highlights covering different aspects
- Keep advisory concise but comprehensive (3-5 sentences)
- Ensure score reflects true alignment with job requirements
- Return ONLY the JSON object, no markdown formatting or extra text''';
  }

  /// Parse API response and update state
  void _parseAndSetResult(String responseText) {
    try {
      // Clean potential markdown formatting
      String cleaned = responseText.trim();

      // Remove markdown code blocks if present
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }

      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      cleaned = cleaned.trim();

      // Parse JSON
      final decoded = json.decode(cleaned) as Map<String, dynamic>;

      // Extract fields with validation
      final score = _parseScore(decoded['score']);
      final advisory = decoded['advisory']?.toString().trim() ?? 'Analysis completed';
      final highlights = _parseHighlights(decoded['highlights']);

      // Validate score range
      if (score < 0 || score > 100) {
        throw Exception('Score must be between 0 and 100');
      }

      _setResult(sc: score, adv: advisory, hl: highlights);

    } catch (e) {
      // Provide helpful error with sample of response
      final sample = responseText.length > 200
          ? '${responseText.substring(0, 200)}...'
          : responseText;
      throw Exception(
          'Failed to parse response: ${e.toString()}\nResponse sample: $sample'
      );
    }
  }

  /// Parse score with validation
  double _parseScore(dynamic score) {
    if (score == null) return 0.0;
    if (score is num) return score.toDouble().clamp(0.0, 100.0);
    final parsed = double.tryParse(score.toString()) ?? 0.0;
    return parsed.clamp(0.0, 100.0);
  }

  /// Parse highlights array
  List<Map<String, dynamic>> _parseHighlights(dynamic highlights) {
    if (highlights is! List) return [];

    return highlights
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) =>
    item['type'] != null &&
        item['text'] != null
    )
        .toList();
  }

  /// Format bytes for human-readable display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Reset to initial state
  void reset() {
    cancel();
    _isCancelled = false;
    _setError(null);
    _setProgress(0.0);
    _setResult(sc: null, adv: null, hl: []);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}