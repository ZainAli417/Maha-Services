// file: cv_analyzer_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;

import '../main.dart';

class CVAnalyzerBackendProvider extends ChangeNotifier {
  bool _isLoading = false;
  double _progress = 0.0;
  String? _error;
  double? _score;
  String? _advisory;
  List<Map<String, dynamic>> _highlights = [];

  bool _isCancelled = false;
  Timer? _progressTimer;

  bool get isLoading => _isLoading;
  double get progress => _progress;
  String? get error => _error;
  double? get score => _score;
  String? get advisory => _advisory;
  List<Map<String, dynamic>> get highlights => _highlights;

  static const int maxFileBytes = 2 * 1024 * 1024;
  static const Duration requestTimeout = Duration(seconds: 120);
  static const int maxRetries = 3;

  static const List<String> supportedExtensions = [
    'pdf', 'doc', 'docx', 'txt', 'rtf'
  ];

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

  void cancel() {
    _isCancelled = true;
    _progressTimer?.cancel();
    _setLoading(false);
    _setError('Operation cancelled by user');
  }

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

  Future<void> _validateFile(PlatformFile file) async {
    final extension = file.extension?.toLowerCase() ?? '';
    if (!supportedExtensions.contains(extension)) {
      throw Exception(
          'Unsupported file type: .$extension\nSupported: ${supportedExtensions.join(", ")}'
      );
    }

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

  Future<int> _getFileSize(PlatformFile file) async {
    if (file.size > 0) return file.size;
    if (file.bytes != null) return file.bytes!.lengthInBytes;
    if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
      return await io.File(file.path!).length();
    }
    return 0;
  }

  Future<Uint8List> _getFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes!;
    }

    if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
      return await io.File(file.path!).readAsBytes();
    }

    throw Exception('Unable to read file content');
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

  Future<void> analyzeCV({
    required PlatformFile file,
    required String roleName,
    required String jobDescription,
  }) async {
    _isCancelled = false;
    _setError(null);
    _setResult(sc: null, adv: null, hl: []);
    _setLoading(true);
    _setProgress(0.0);

    try {
      if (roleName.trim().isEmpty) {
        throw Exception('Role name is required');
      }

      _animateProgress(from: 0.0, to: 0.08, durationMs: 500);
      await _validateFile(file);

      await _analyzeWithServer(file, roleName, jobDescription);

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

  Future<void> _analyzeWithServer(
      PlatformFile file,
      String roleName,
      String jobDescription,
      ) async {
    _animateProgress(from: _progress, to: 0.25, durationMs: 1000);
    final fileBytes = await _getFileBytes(file);
    final base64Data = base64Encode(fileBytes);
    final mimeType = _getMimeType(file.name);

    _setProgress(0.30);

    _animateProgress(from: 0.30, to: 0.85, durationMs: 4000);
    final result = await _callServerWithRetry(
      fileData: base64Data,
      mimeType: mimeType,
      roleName: roleName,
      jobDescription: jobDescription,
    );

    _progressTimer?.cancel();
    _setProgress(0.90);

    await Future.delayed(const Duration(milliseconds: 300));
    _parseAndSetResult(result);

    _setProgress(1.0);
  }

  Future<Map<String, dynamic>> _callServerWithRetry({
    required String fileData,
    required String mimeType,
    required String roleName,
    required String jobDescription,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      if (_isCancelled) throw Exception('Operation cancelled');

      try {
        return await _callServerAPI(
          fileData: fileData,
          mimeType: mimeType,
          roleName: roleName,
          jobDescription: jobDescription,
        );
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;

        if (attempt < maxRetries) {
          final delaySeconds = (2 << (attempt - 1));
          debugPrint('Retry attempt $attempt after $delaySeconds seconds...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }

    throw lastError ?? Exception('Failed after $maxRetries attempts');
  }

  Future<Map<String, dynamic>> _callServerAPI({
    required String fileData,
    required String mimeType,
    required String roleName,
    required String jobDescription,
  }) async {
    final uri = Uri.parse('${Env.backendUrl}/cv-analysis');

    final payload = {
      'fileData': fileData,
      'mimeType': mimeType,
      'roleName': roleName,
      'jobDescription': jobDescription,
    };

    final response = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    )
        .timeout(requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse as Map<String, dynamic>;
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
  }

  void _parseAndSetResult(Map<String, dynamic> response) {
    try {
      final score = _parseScore(response['score']);
      final advisory = response['advisory']?.toString().trim() ?? 'Analysis completed';
      final highlights = _parseHighlights(response['highlights']);

      if (score < 0 || score > 100) {
        throw Exception('Score must be between 0 and 100');
      }

      _setResult(sc: score, adv: advisory, hl: highlights);

    } catch (e) {
      throw Exception('Failed to parse server response: ${e.toString()}');
    }
  }

  double _parseScore(dynamic score) {
    if (score == null) return 0.0;
    if (score is num) return score.toDouble().clamp(0.0, 100.0);
    final parsed = double.tryParse(score.toString()) ?? 0.0;
    return parsed.clamp(0.0, 100.0);
  }

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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

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