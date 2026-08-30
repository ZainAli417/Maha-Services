import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../main.dart' show Env;
import 'models/aviation_role.dart';
import 'models/candidate_profile.dart';
import 'models/question.dart';
import '../../services/backend_api.dart';

/// What the extractor produced from a CV, already shaped for the dynamic form.
class RoleCvExtraction {
  const RoleCvExtraction({
    this.answers = const {},
    this.personalInfo,
    this.experience = const [],
    this.education = const [],
    this.certifications = const [],
    this.confidence = 0,
    this.notes = const [],
    this.error,
  });

  /// Values keyed by question id, already coerced to each question's type.
  final Map<String, dynamic> answers;
  final PersonalInfo? personalInfo;
  final List<ExperienceEntry> experience;
  final List<EducationEntry> education;
  final List<CertificationEntry> certifications;

  /// 0–1 self-reported extraction confidence.
  final double confidence;

  /// Human-readable notes about what could not be found.
  final List<String> notes;
  final String? error;

  bool get failed => error != null;

  int get filledCount =>
      answers.length + experience.length + education.length + certifications.length;

  static const failedEmpty = RoleCvExtraction(error: 'extraction-failed');
}

/// Sends a CV plus the selected role's field schema to the backend, which
/// prompts Gemini for strictly-validated JSON matching that schema.
///
/// The schema travels with the request rather than living on the server, so
/// admin edits to a role template take effect without a backend deploy.
class CvExtractionService {
  CvExtractionService({http.Client? client, this.timeout = const Duration(seconds: 120)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// Options above this count are truncated before being sent — the prompt
  /// stays inside a sane token budget and the model may still answer with an
  /// off-list value, which [_coerce] snaps back onto the list when it can.
  static const _maxOptionsPerField = 60;

  static const _supportedExtensions = {'pdf', 'doc', 'docx', 'txt', 'rtf'};

  static bool isSupported(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return _supportedExtensions.contains(ext);
  }

  static String mimeTypeFor(String filename) {
    switch (filename.toLowerCase().split('.').last) {
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

  Future<RoleCvExtraction> extract(
    Uint8List bytes, {
    required String filename,
    required RoleTemplate template,
  }) async {
    try {
      // multipart/form-data, not base64 in JSON. The bytes go over the wire as
      // bytes: no 33% encoding tax, no multi-megabyte string for the server to
      // JSON.parse, and the upload is not bound by express.json()'s body limit.
      // MultipartRequest behaves the same on web and Android.
      final request =
          http.MultipartRequest('POST', Uri.parse('${Env.backendUrl}/cv-extract'))
            ..headers.addAll(await BackendApi.headers(multipart: true))
            ..files.add(http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: filename,
              contentType: MediaType.parse(mimeTypeFor(filename)),
            ))
            // Nested values have to be JSON strings — a form field is flat text.
            // The server accepts either these or a parsed JSON body.
            ..fields['role'] = jsonEncode({
              'id': template.id,
              'title': template.title,
              'industry': template.industry,
              'category': template.category,
            })
            ..fields['schema'] = jsonEncode(_schemaFor(template));

      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('⚠️ /cv-extract ${response.statusCode}: ${response.body}');
        // 413 (too large) and 415 (bytes did not look like a document the
        // server accepts) are both things the candidate can act on, so say what
        // happened instead of showing a bare status code.
        if (response.statusCode == 413) {
          return const RoleCvExtraction(
            error: 'That file was too large to upload. '
                'Try a smaller file, or fill the form in manually.',
          );
        }
        if (response.statusCode == 415) {
          return const RoleCvExtraction(
            error: 'That file did not look like a PDF, DOC, DOCX or TXT. '
                'Try another file, or fill the form in manually.',
          );
        }
        return RoleCvExtraction(
          error: 'Extraction service returned ${response.statusCode}',
        );
      }

      final body = jsonDecode(response.body);
      if (body is! Map) return RoleCvExtraction.failedEmpty;
      return _parse(Map<String, dynamic>.from(body), template);
    } catch (e) {
      debugPrint('⚠️ CvExtractionService.extract: $e');
      return RoleCvExtraction(error: e.toString());
    }
  }

  /// Compact field descriptors — only what the model needs to fill a value.
  ///
  /// Fields the CV cannot honestly answer are withheld entirely: uploads,
  /// availability and relocation preferences, and every legal declaration.
  /// Keeping them out shortens the prompt (cheaper, faster, more accurate on
  /// what remains) and removes any chance of the model inventing an answer to
  /// a question with legal weight.
  List<Map<String, dynamic>> _schemaFor(RoleTemplate template) {
    return [
      for (final q in template.questions)
        if (q.type != QuestionType.file && q.cvExtractable)
          {
            'id': q.id,
            'label': q.label,
            'type': _wireType(q.type),
            'section': q.group ?? 'General',
            if (q.unit != null) 'unit': q.unit,
            if (q.required) 'required': true,
            if (q.helpText != null) 'hint': q.helpText,
            if (q.options.isNotEmpty)
              'options': q.options.take(_maxOptionsPerField).toList(),
            if (q.options.length > _maxOptionsPerField) 'optionsTruncated': true,
            if (q.allowCustom) 'allowCustom': true,
          },
    ];
  }

  static String _wireType(QuestionType t) {
    switch (t) {
      case QuestionType.number:
        return 'number';
      case QuestionType.boolean:
        return 'boolean';
      case QuestionType.date:
        return 'date';
      case QuestionType.monthYear:
        return 'monthYear';
      case QuestionType.singleSelect:
      case QuestionType.searchSelect:
        return 'singleSelect';
      case QuestionType.multiSelect:
      case QuestionType.searchMultiSelect:
        return 'multiSelect';
      case QuestionType.tags:
        return 'tags';
      case QuestionType.yesNoDetail:
        return 'yesNoDetail';
      case QuestionType.longText:
        return 'longText';
      case QuestionType.text:
      case QuestionType.file:
      // A phone number is a plain string on the wire. The extractor returns
      // whatever the CV printed; the control re-splits it into country and
      // number on the way into the form.
      case QuestionType.phone:
        return 'text';
    }
  }

  RoleCvExtraction _parse(Map<String, dynamic> body, RoleTemplate template) {
    final rawAnswers = body['answers'];
    final answers = <String, dynamic>{};
    if (rawAnswers is Map) {
      final byId = {for (final q in template.questions) q.id: q};
      rawAnswers.forEach((key, value) {
        final q = byId[key.toString()];
        if (q == null) return;
        final coerced = coerceAnswer(q, value);
        if (coerced != null) answers[q.id] = coerced;
      });
    }

    return RoleCvExtraction(
      answers: answers,
      personalInfo: body['personalInfo'] is Map
          ? PersonalInfo.fromJson(Map<String, dynamic>.from(body['personalInfo']))
          : null,
      experience: _entries(
        body['experience'],
        (i, m) => ExperienceEntry.fromJson({...m, 'id': m['id'] ?? 'exp_$i'}),
      ),
      education: _entries(
        body['education'],
        (i, m) => EducationEntry.fromJson({...m, 'id': m['id'] ?? 'edu_$i'}),
      ),
      certifications: _entries(
        body['certifications'],
        (i, m) => CertificationEntry.fromJson({...m, 'id': m['id'] ?? 'cert_$i'}),
      ),
      confidence: body['confidence'] is num
          ? (body['confidence'] as num).toDouble().clamp(0, 1)
          : 0,
      notes: (body['notes'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  static List<T> _entries<T>(
    dynamic raw,
    T Function(int index, Map<String, dynamic> map) build,
  ) {
    if (raw is! List) return const [];
    final out = <T>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is Map) out.add(build(i, Map<String, dynamic>.from(item)));
    }
    return out;
  }

  /// Snaps a model-produced value onto the question's own type and options.
  /// Returning null drops the value so the candidate fills it in themselves —
  /// always preferable to seeding the form with something unusable.
  @visibleForTesting
  static dynamic coerceAnswer(OnboardingQuestion q, dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;

    switch (q.type) {
      case QuestionType.number:
        final n = value is num ? value : num.tryParse(_digits(value.toString()));
        if (n == null) return null;
        if (q.min != null && n < q.min!) return null;
        if (q.max != null && n > q.max!) return null;
        return n;

      case QuestionType.boolean:
        if (value is bool) return value;
        final s = value.toString().toLowerCase().trim();
        if (s == 'true' || s == 'yes') return true;
        if (s == 'false' || s == 'no') return false;
        return null;

      case QuestionType.yesNoDetail:
        if (value is Map) {
          final v = value['value'];
          final flag = v is bool
              ? v
              : v?.toString().toLowerCase().trim() == 'yes' ||
                  v?.toString().toLowerCase().trim() == 'true';
          return {'value': flag, 'details': value['details']?.toString() ?? ''};
        }
        final s = value.toString().toLowerCase().trim();
        if (s == 'yes' || s == 'true') return {'value': true, 'details': ''};
        if (s == 'no' || s == 'false') return {'value': false, 'details': ''};
        return null;

      case QuestionType.singleSelect:
      case QuestionType.searchSelect:
        final match = matchOption(q.options, value.toString());
        if (match != null) return match;
        return q.allowCustom ? value.toString().trim() : null;

      case QuestionType.multiSelect:
      case QuestionType.searchMultiSelect:
        final raw = value is List ? value : [value];
        final out = <String>[];
        for (final item in raw) {
          final match = matchOption(q.options, item.toString());
          if (match != null) {
            if (!out.contains(match)) out.add(match);
          } else if (q.allowCustom) {
            final s = item.toString().trim();
            if (s.isNotEmpty && !out.contains(s)) out.add(s);
          }
        }
        if (out.isEmpty) return null;
        return q.maxSelect != null && out.length > q.maxSelect!
            ? out.take(q.maxSelect!).toList()
            : out;

      case QuestionType.tags:
        final raw = value is List ? value : value.toString().split(',');
        final out = raw
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        return out.isEmpty ? null : out;

      case QuestionType.date:
        final parsed = _parseDate(value.toString());
        return parsed?.toIso8601String();

      case QuestionType.monthYear:
        return _parseMonthYear(value.toString());

      case QuestionType.text:
      case QuestionType.longText:
      case QuestionType.file:
      case QuestionType.phone:
        final s = value.toString().trim();
        return s.isEmpty ? null : s;
    }
  }

  static String _digits(String s) {
    final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(s.replaceAll(',', ''));
    return m?.group(0) ?? '';
  }

  /// Exact match first, then case-insensitive, then a prefix/token/containment
  /// pass so "ATPL" resolves to "ATPL (Airline Transport)".
  @visibleForTesting
  static String? matchOption(List<String> options, String value) {
    if (options.isEmpty) return null;
    final v = value.trim();
    if (v.isEmpty) return null;
    for (final o in options) {
      if (o == v) return o;
    }
    final lower = v.toLowerCase();
    for (final o in options) {
      if (o.toLowerCase() == lower) return o;
    }
    for (final o in options) {
      final ol = o.toLowerCase();
      if (ol.startsWith(lower) || lower.startsWith(ol)) return o;
    }
    // Whole-token pass, so a bare acronym reaches the option that spells it
    // out ("IR" -> "Instrument Rating (IR)").
    final tokenHits = options
        .where((o) => o
            .toLowerCase()
            .split(RegExp(r'[^a-z0-9]+'))
            .where((t) => t.isNotEmpty)
            .contains(lower))
        .toList();
    if (tokenHits.length == 1) return tokenHits.first;

    // Loosest pass. Both it and the token pass demand a unique hit: when a
    // value could plausibly be two different options, leaving the field empty
    // for the candidate to answer beats silently picking the wrong one.
    if (lower.length >= 3) {
      final contains =
          options.where((o) => o.toLowerCase().contains(lower)).toList();
      if (contains.length == 1) return contains.first;
    }
    return null;
  }

  static DateTime? _parseDate(String raw) {
    final direct = DateTime.tryParse(raw.trim());
    if (direct != null) return direct;
    final my = _parseMonthYear(raw);
    if (my == null) return null;
    final parts = my.split('/');
    return DateTime(int.parse(parts[1]), int.parse(parts[0]));
  }

  /// Normalizes anything month-and-year shaped to `MM/YYYY`.
  static String? _parseMonthYear(String raw) {
    final s = raw.trim();
    final slash = RegExp(r'^(\d{1,2})[/\-](\d{4})$').firstMatch(s);
    if (slash != null) {
      final m = int.parse(slash.group(1)!);
      if (m >= 1 && m <= 12) {
        return '${m.toString().padLeft(2, '0')}/${slash.group(2)}';
      }
    }
    final iso = DateTime.tryParse(s);
    if (iso != null) {
      return '${iso.month.toString().padLeft(2, '0')}/${iso.year}';
    }
    const months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final named = RegExp(r'([A-Za-z]{3,})\s*,?\s*((?:19|20)\d{2})').firstMatch(s);
    if (named != null) {
      final idx = months.indexOf(named.group(1)!.toLowerCase().substring(0, 3));
      if (idx >= 0) {
        return '${(idx + 1).toString().padLeft(2, '0')}/${named.group(2)}';
      }
    }
    final yearOnly = RegExp(r'^((?:19|20)\d{2})$').firstMatch(s);
    if (yearOnly != null) return '01/${yearOnly.group(1)}';
    return null;
  }

  void dispose() => _client.close();
}
