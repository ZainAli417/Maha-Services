import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';
import 'LIst_of_Applicants_provider.dart';

/// Provider for AI-powered applicant matching using Groq Cloud
class AIMatchProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ UPDATED: Groq Cloud API Configuration
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  // static const String _model = 'llama-3.3-70b-versatile';
  static const String _model = 'llama-3.3-70b-versatile';

  // State management
  bool _isAnalyzing = false;
  String? _error;
  final Map<String, AIMatchResult> _matchResults = {};
  final Map<String, bool> _isProcessing = {};
  int _totalApplicants = 0;
  int _processedApplicants = 0;

  // Getters
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  Map<String, AIMatchResult> get matchResults => Map.from(_matchResults);
  double get progress => _totalApplicants > 0 ? _processedApplicants / _totalApplicants : 0.0;
  int get processedCount => _processedApplicants;
  int get totalCount => _totalApplicants;

  AIMatchResult? getMatchResult(String applicantId) => _matchResults[applicantId];
  bool isProcessingApplicant(String applicantId) => _isProcessing[applicantId] ?? false;

  /// Main method to analyze all applicants for a job
  Future<void> analyzeApplicants({
    required String jobId,
    required List<ApplicantRecord> applicants,
  }) async {
    if (_isAnalyzing) {
      debugPrint('⚠️ Analysis already in progress');
      return;
    }

    _isAnalyzing = true;
    _error = null;
    _matchResults.clear();
    _isProcessing.clear();
    notifyListeners();

    try {
      debugPrint('🚀 Starting AI analysis for ${applicants.length} total applicants');
      debugPrint('📋 All Applicant IDs: ${applicants.map((a) => a.userId).join(", ")}');

      final jobData = await _fetchJobData(jobId);
      if (jobData == null) {
        throw Exception('Job data not found for ID: $jobId');
      }

      debugPrint('✅ Job data fetched: ${jobData['title']}');

      // ✅ FILTER: Only analyze applicants that meet criteria
      final applicantsToAnalyze = <ApplicantRecord>[];
      final skippedAnalyzed = <String>[];
      final skippedStatus = <String>[];

      for (var applicant in applicants) {
        final status = applicant.status.toLowerCase();

        // Skip if status is shortlisted or rejected
        if (status == 'shortlisted' || status == 'rejected') {
          skippedStatus.add('${applicant.name} (${applicant.userId}) - Status: $status');
          debugPrint('⏭️ SKIPPED [STATUS]: ${applicant.name} - ${applicant.status}');
          continue;
        }

        // ✅ CHECK FIRESTORE: Skip if already has match_score
        try {
          final appDoc = await _firestore
              .collection('applications')
              .doc(applicant.userId)
              .collection('applied_jobs')
              .doc(applicant.docId)
              .get();

          final matchScore = appDoc.data()?['match_score'];

          if (matchScore != null) {
            skippedAnalyzed.add('${applicant.name} (${applicant.userId})');
            debugPrint('⏭️ SKIPPED [ALREADY ANALYZED]: ${applicant.name} - Has match_score in DB');
            continue;
          }
        } catch (e) {
          debugPrint('⚠️ Error checking match_score for ${applicant.name}: $e');
        }

        // This applicant needs analysis
        applicantsToAnalyze.add(applicant);
      }

      _totalApplicants = applicantsToAnalyze.length;
      _processedApplicants = 0;

      // ✅ DETAILED DEBUG SUMMARY
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('📊 ANALYSIS SUMMARY:');
      debugPrint('   Total Applicants: ${applicants.length}');
      debugPrint('   To Analyze: ${applicantsToAnalyze.length}');
      debugPrint('   Skipped (Already Analyzed): ${skippedAnalyzed.length}');
      debugPrint('   Skipped (Status): ${skippedStatus.length}');
      debugPrint('═══════════════════════════════════════════════════');

      if (applicantsToAnalyze.isNotEmpty) {
        debugPrint('🎯 CANDIDATES TO ANALYZE (${applicantsToAnalyze.length}):');
        for (var applicant in applicantsToAnalyze) {
          debugPrint('   ✓ ${applicant.name} (ID: ${applicant.userId})');
        }
      }

      if (skippedAnalyzed.isNotEmpty) {
        debugPrint('🔒 SKIPPED - ALREADY ANALYZED (${skippedAnalyzed.length}):');
        for (var name in skippedAnalyzed) {
          debugPrint('   ⏭️ $name');
        }
      }

      if (skippedStatus.isNotEmpty) {
        debugPrint('🚫 SKIPPED - STATUS (${skippedStatus.length}):');
        for (var name in skippedStatus) {
          debugPrint('   ⏭️ $name');
        }
      }

      debugPrint('═══════════════════════════════════════════════════');

      if (applicantsToAnalyze.isEmpty) {
        debugPrint('ℹ️ No new applicants to analyze');
        _isAnalyzing = false;
        notifyListeners();
        return;
      }

      await _processApplicantsInBatches(applicantsToAnalyze, jobData);
      debugPrint('🎉 Analysis complete! Processed $_processedApplicants applicants');

    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('❌ Error during analysis: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }



  Future<Map<String, dynamic>?> _fetchJobData(String jobId) async {
    try {
      final doc = await _firestore.collection('Posted_jobs_public').doc(jobId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Future<void> _processApplicantsInBatches(
      List<ApplicantRecord> applicants,
      Map<String, dynamic> jobData,
      ) async {
    const batchSize = 3;
    const delayBetweenBatches = Duration(milliseconds: 1000);

    for (var i = 0; i < applicants.length; i += batchSize) {
      final end = (i + batchSize < applicants.length) ? i + batchSize : applicants.length;
      final batch = applicants.sublist(i, end);

      await Future.wait(
        batch.map((applicant) => _analyzeApplicant(applicant, jobData)),
      );

      if (end < applicants.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }
  }

  Future<void> _analyzeApplicant(
      ApplicantRecord applicant,
      Map<String, dynamic> jobData,
      ) async {
    final applicantId = applicant.userId;

    try {
      _isProcessing[applicantId] = true;
      notifyListeners();

      final prompt = _buildMatchingPrompt(applicant, jobData);
      final response = await _callGroqAPI(prompt); // ✅ Switched to Groq
      final matchResult = _parseGroqResponse(response, applicant);

      _matchResults[applicantId] = matchResult;
      _processedApplicants++;
// ✅ Save match result to Firestore and LOCK the candidate
      await _firestore
          .collection('applications')
          .doc(applicant.userId)
          .collection('applied_jobs')
          .doc(applicant.docId)
          .update({
        'match_score': {
          'overallScore': matchResult.overallScore,
          'skillsMatch': matchResult.skillsMatch,
          'experienceMatch': matchResult.experienceMatch,
          'educationMatch': matchResult.educationMatch,
          'strengths': matchResult.strengths,
          'weaknesses': matchResult.weaknesses,
          'recommendation': matchResult.recommendation,
          'detailedAnalysis': matchResult.detailedAnalysis,
          'analyzedAt': FieldValue.serverTimestamp(),
          'locked': true, // 🔒 LOCK to prevent re-analysis
        }
      });

      debugPrint('💾 Saved & LOCKED match score for ${applicant.name}');

    } catch (e) {
      _matchResults[applicantId] = AIMatchResult(
        applicantId: applicantId,
        applicantName: applicant.name,
        overallScore: 0,
        skillsMatch: 0,
        experienceMatch: 0,
        educationMatch: 0,
        strengths: [],
        weaknesses: ['Analysis failed: $e'],
        recommendation: 'Unable to analyze',
        detailedAnalysis: 'An error occurred during analysis',
        timestamp: DateTime.now(),
      );
    } finally {
      _isProcessing[applicantId] = false;
      notifyListeners();
    }
  }

  String _buildMatchingPrompt(
      ApplicantRecord applicant,
      Map<String, dynamic> jobData,
      ) {
    String workExp = applicant.experiences.isEmpty
        ? 'No work experience'
        : applicant.experiences.take(3).map((e) => '${e['text']} (${e['duration']})').join('; ');

    String education = applicant.educations.isEmpty
        ? 'No education details'
        : applicant.educations.take(2).map((e) => '${e['majorSubjects']} at ${e['institutionName']}').join('; ');

    return '''
You are an expert HR system. Compare the candidate against the job.
Return a valid JSON object matching the requested structure.

JOB:
Title: ${jobData['title']}
Required Experience: ${jobData['experience']}
Key Skills: ${(jobData['skills'] as List?)?.join(', ')}

CANDIDATE:
Name: ${applicant.name}
Experience: ${applicant.experienceYears} years
Recent Roles: $workExp
Education: $education
Skills: ${applicant.skills.join(', ')}

JSON Structure:
{
  "overallScore": number,
  "skillsMatch": number,
  "experienceMatch": number,
  "educationMatch": number,
  "strengths": ["string"],
  "weaknesses": ["string"],
  "recommendation": "string",
  "detailedAnalysis": "string"
}
''';
  }

  // ✅ NEW: Groq Cloud API Call
  Future<String> _callGroqAPI(String prompt) async {
    final response = await http.post(
      Uri.parse(_groqApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Env.groqApiKey}', // Ensure you have groqApiKey in your Env class
      },
      body: jsonEncode({
        "model": _model,
        "messages": [
          {"role": "system", "content": "You are a professional HR recruiter. Output only valid JSON."},
          {"role": "user", "content": prompt}
        ],
        "response_format": {"type": "json_object"}, // Force JSON output
        "temperature": 0.1,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq error ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final String? content = jsonResponse['choices']?[0]?['message']?['content'];

    if (content == null || content.isEmpty) {
      throw Exception('Empty response from Groq');
    }

    return content.trim();
  }

  // ✅ UPDATED: Parsing logic for Groq
  AIMatchResult _parseGroqResponse(String textResponse, ApplicantRecord applicant) {
    try {
      final Map<String, dynamic> data = jsonDecode(textResponse);

      return AIMatchResult(
        applicantId: applicant.userId,
        applicantName: applicant.name,
        overallScore: _safeInt(data['overallScore']),
        skillsMatch: _safeInt(data['skillsMatch']),
        experienceMatch: _safeInt(data['experienceMatch']),
        educationMatch: _safeInt(data['educationMatch']),
        strengths: _safeStringList(data['strengths']),
        weaknesses: _safeStringList(data['weaknesses']),
        recommendation: data['recommendation']?.toString() ?? 'Not Recommended',
        detailedAnalysis: data['detailedAnalysis']?.toString() ?? '',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Groq JSON parsing failed: $e');
      return AIMatchResult(
        applicantId: applicant.userId,
        applicantName: applicant.name,
        overallScore: 0,
        skillsMatch: 0,
        experienceMatch: 0,
        educationMatch: 0,
        strengths: [],
        weaknesses: ['AI response parsing failed'],
        recommendation: 'Error',
        detailedAnalysis: 'Failed to parse AI response: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.clamp(0, 100);
    if (value is double) return value.round().clamp(0, 100);
    return 0;
  }

  List<String> _safeStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  void clearResults() {
    _matchResults.clear();
    _isProcessing.clear();
    _error = null;
    _processedApplicants = 0;
    _totalApplicants = 0;
    notifyListeners();
  }
}

/// AIMatchResult and other data classes remain identical to your original code
class AIMatchResult {
  final String applicantId;
  final String applicantName;
  final int overallScore;
  final int skillsMatch;
  final int experienceMatch;
  final int educationMatch;
  final List<String> strengths;
  final List<String> weaknesses;
  final String recommendation;
  final String detailedAnalysis;
  final DateTime timestamp;

  AIMatchResult({
    required this.applicantId,
    required this.applicantName,
    required this.overallScore,
    required this.skillsMatch,
    required this.experienceMatch,
    required this.educationMatch,
    required this.strengths,
    required this.weaknesses,
    required this.recommendation,
    required this.detailedAnalysis,
    required this.timestamp,
  });

  Color getScoreColor() {
    if (overallScore >= 80) return const Color(0xFF10B981);
    if (overallScore >= 60) return const Color(0xFF3B82F6);
    if (overallScore >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color getRecommendationColor() {
    switch (recommendation.toLowerCase()) {
      case 'highly recommended': return const Color(0xFF10B981);
      case 'recommended': return const Color(0xFF3B82F6);
      case 'consider': return const Color(0xFFF59E0B);
      default: return const Color(0xFFEF4444);
    }
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
//
// import '../../main.dart';
// import 'LIst_of_Applicants_provider.dart';
//
//
// /// Provider for AI-powered applicant matching using Gemini
// class AIMatchProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static const String _geminiApiUrl =
//       'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';
//
//   // State management
//   bool _isAnalyzing = false;
//   String? _error;
//   final Map<String, AIMatchResult> _matchResults = {};
//   final Map<String, bool> _isProcessing = {};
//   int _totalApplicants = 0;
//   int _processedApplicants = 0;
//
//   // Getters
//   bool get isAnalyzing => _isAnalyzing;
//   String? get error => _error;
//   Map<String, AIMatchResult> get matchResults => Map.from(_matchResults);
//   double get progress => _totalApplicants > 0 ? _processedApplicants / _totalApplicants : 0.0;
//   int get processedCount => _processedApplicants;
//   int get totalCount => _totalApplicants;
//
//   AIMatchResult? getMatchResult(String applicantId) => _matchResults[applicantId];
//   bool isProcessingApplicant(String applicantId) => _isProcessing[applicantId] ?? false;
//
//   /// Main method to analyze all applicants for a job
//   Future<void> analyzeApplicants({
//     required String jobId,
//     required List<ApplicantRecord> applicants,
//   }) async {
//     if (_isAnalyzing) {
//       debugPrint('⚠️ Analysis already in progress');
//       return;
//     }
//
//     _isAnalyzing = true;
//     _error = null;
//     _matchResults.clear();
//     _isProcessing.clear();
//     notifyListeners();
//
//     try {
//       debugPrint('🚀 Starting AI analysis for ${applicants.length} applicants');
//
//       final jobData = await _fetchJobData(jobId);
//       if (jobData == null) {
//         throw Exception('Job data not found for ID: $jobId');
//       }
//
//       debugPrint('✅ Job data fetched: ${jobData['title']}');
//
//       // ✅ FILTER: Only analyze applicants that meet criteria
//       final applicantsToAnalyze = applicants.where((applicant) {
//         // Skip if status is shortlisted or rejected
//         if (applicant.status.toLowerCase() == 'shortlisted' ||
//             applicant.status.toLowerCase() == 'rejected') {
//           debugPrint('⏭️ Skipping ${applicant.name} - Status: ${applicant.status}');
//           return false;
//         }
//
//         // Skip if already has match_score in profileSnapshot
//         final matchScore = applicant.profileSnapshot['match_score'];
//         if (matchScore != null) {
//           debugPrint('⏭️ Skipping ${applicant.name} - Already analyzed');
//           // Load existing score into memory
//           _matchResults[applicant.userId] = AIMatchResult(
//             applicantId: applicant.userId,
//             applicantName: applicant.name,
//             overallScore: matchScore['overallScore'] ?? 0,
//             skillsMatch: matchScore['skillsMatch'] ?? 0,
//             experienceMatch: matchScore['experienceMatch'] ?? 0,
//             educationMatch: matchScore['educationMatch'] ?? 0,
//             strengths: List<String>.from(matchScore['strengths'] ?? []),
//             weaknesses: List<String>.from(matchScore['weaknesses'] ?? []),
//             recommendation: matchScore['recommendation'] ?? '',
//             detailedAnalysis: matchScore['detailedAnalysis'] ?? '',
//             timestamp: DateTime.now(),
//           );
//           return false;
//         }
//
//         return true; // Analyze this applicant
//       }).toList();
//
//       _totalApplicants = applicantsToAnalyze.length;
//       _processedApplicants = 0;
//
//       if (applicantsToAnalyze.isEmpty) {
//         debugPrint('ℹ️ No new applicants to analyze');
//         _isAnalyzing = false;
//         notifyListeners();
//         return;
//       }
//
//       debugPrint('📊 Analyzing ${applicantsToAnalyze.length} new applicants (${applicants.length - applicantsToAnalyze.length} already analyzed or excluded)');
//
//       await _processApplicantsInBatches(applicantsToAnalyze, jobData);
//       debugPrint('🎉 Analysis complete! Processed $_processedApplicants applicants');
//
//     } catch (e, stackTrace) {
//       _error = e.toString();
//       debugPrint('❌ Error during analysis: $e');
//       debugPrint('Stack trace: $stackTrace');
//     } finally {
//       _isAnalyzing = false;
//       notifyListeners();
//     }
//   }
//
//   Future<Map<String, dynamic>?> _fetchJobData(String jobId) async {
//     try {
//       final doc = await _firestore.collection('Posted_jobs_public').doc(jobId).get();
//       if (!doc.exists) {
//         debugPrint('❌ Job document not found: $jobId');
//         return null;
//       }
//       return doc.data();
//     } catch (e) {
//       debugPrint('❌ Error fetching job data: $e');
//       return null;
//     }
//   }
//
//   Future<void> _processApplicantsInBatches(
//       List<ApplicantRecord> applicants,
//       Map<String, dynamic> jobData,
//       ) async {
//     const batchSize = 3; // Reduced to avoid rate limits
//     const delayBetweenBatches = Duration(milliseconds: 1500);
//
//     for (var i = 0; i < applicants.length; i += batchSize) {
//       final end = (i + batchSize < applicants.length) ? i + batchSize : applicants.length;
//       final batch = applicants.sublist(i, end);
//
//       await Future.wait(
//         batch.map((applicant) => _analyzeApplicant(applicant, jobData)),
//       );
//
//       if (end < applicants.length) {
//         await Future.delayed(delayBetweenBatches);
//       }
//     }
//   }
//
//   Future<void> _analyzeApplicant(
//       ApplicantRecord applicant,
//       Map<String, dynamic> jobData,
//       ) async {
//     final applicantId = applicant.userId;
//
//     try {
//       _isProcessing[applicantId] = true;
//       notifyListeners();
//
//       debugPrint('🔍 Analyzing applicant: ${applicant.name}');
//
//       final prompt = _buildMatchingPrompt(applicant, jobData);
//       final response = await _callGeminiAPI(prompt);
//       final matchResult = _parseGeminiResponse(response, applicant);
//
//       _matchResults[applicantId] = matchResult;
//       _processedApplicants++;
// // Save match result to Firestore
//       debugPrint('✅ Analyzed ${applicant.name}: ${matchResult.overallScore}%');
//       await _firestore
//           .collection('applications')
//           .doc(applicant.userId)
//           .collection('applied_jobs')
//           .doc(applicant.docId)
//           .update({
//         'match_score': {
//           'overallScore': matchResult.overallScore,
//           'skillsMatch': matchResult.skillsMatch,
//           'experienceMatch': matchResult.experienceMatch,
//           'educationMatch': matchResult.educationMatch,
//           'strengths': matchResult.strengths,
//           'weaknesses': matchResult.weaknesses,
//           'recommendation': matchResult.recommendation,
//           'detailedAnalysis': matchResult.detailedAnalysis,
//           'analyzedAt': FieldValue.serverTimestamp(),
//         }
//       });
//
//       debugPrint('💾 Saved match score to Firestore for ${applicant.name}');
//
//     } catch (e) {
//       debugPrint('❌ Error analyzing ${applicant.name}: $e');
//
//       _matchResults[applicantId] = AIMatchResult(
//         applicantId: applicantId,
//         applicantName: applicant.name,
//         overallScore: 0,
//         skillsMatch: 0,
//         experienceMatch: 0,
//         educationMatch: 0,
//         strengths: [],
//         weaknesses: ['Analysis failed: $e'],
//         recommendation: 'Unable to analyze',
//         detailedAnalysis: 'An error occurred during analysis',
//         timestamp: DateTime.now(),
//       );
//     } finally {
//       _isProcessing[applicantId] = false;
//       notifyListeners();
//     }
//   }
//
//   String _buildMatchingPrompt(
//       ApplicantRecord applicant,
//       Map<String, dynamic> jobData,
//       ) {
//     // Shortened work experience
//     String workExp = 'No work experience';
//     if (applicant.experiences.isNotEmpty) {
//       workExp = applicant.experiences.take(3).map((e) =>
//       '${e['text'] ?? 'N/A'} (${e['duration'] ?? 'N/A'})'
//       ).join('; ');
//     }
//
//     // Shortened education
//     String education = 'No education details';
//     if (applicant.educations.isNotEmpty) {
//       education = applicant.educations.take(2).map((e) =>
//       '${e['majorSubjects'] ?? 'N/A'} at ${e['institutionName'] ?? 'N/A'}'
//       ).join('; ');
//     }
//
//     return '''
// You are an expert HR system that outputs ONLY valid JSON.
//
// JOB:
// Title: ${jobData['title']}
// Location: ${jobData['location']}
// Required Experience: ${jobData['experience']}
// Key Skills: ${(jobData['skills'] as List?)?.join(', ')}
// Description: ${_truncate(jobData['description'] ?? '', 400)}
//
// CANDIDATE:
// Name: ${applicant.name}
// Experience: ${applicant.experienceYears} years
// Recent Roles: $workExp
// Education: $education
// Skills: ${applicant.skills.join(', ')}
//
// INSTRUCTION:
// Compare candidate against job. Return EXACTLY this JSON structure and NOTHING ELSE.
// Do not use markdown. Do not add explanations. Do not stop early.
// FORMAT OF RESPONSE (DUMMY IS GIVEN HERE)
// {
//   "overallScore": 87,
//   "skillsMatch": 92,
//   "experienceMatch": 85,
//   "educationMatch": 70,
//   "locationMatch": 100,
//   "strengths": ["Strong SKILLS AND WORKING DOMAINS "],
//   "weaknesses": ["Limited backend experience", "No leadership role yet"],
//   "recommendation": "Highly Recommended",
//   "detailedAnalysis": "Excellent technical fit with strong mobile development background. Lacks team leadership experience but compensates with delivery track record."
// }
//
// Scores are 0–100. Be realistic but decisive.
// Return only valid JSON. No trailing commas. No comments.
// ''';
//   }
//   String _truncate(String text, int maxLength) {
//     if (text.length <= maxLength) return text;
//     return '${text.substring(0, maxLength)}...';
//   }
//
//   Future<String> _callGeminiAPI(String prompt) async {
//     final response = await http.post(
//       Uri.parse('$_geminiApiUrl?key=${Env.geminiApiKey}'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         "contents": [{"parts": [{"text": prompt}]}],
//         "generationConfig": {
//           "responseMimeType": "application/json",   // ← THIS IS CRITICAL
//           "temperature": 0.2,
//         }
//       }),
//     );
//
//     if (response.statusCode != 200) {
//       throw Exception('Gemini error ${response.statusCode}: ${response.body}');
//     }
//
//     final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
//
//     // CORRECT WAY – extract only the text part
//     final String? rawJson = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
//
//     if (rawJson == null || rawJson.isEmpty) {
//       throw Exception('Empty or null response from Gemini');
//     }
//
//     // Now rawJson = '{\n "overallScore": 2,\n "skillsMatch": ... }'
//     return rawJson.trim();
//   }
//
//   AIMatchResult _parseGeminiResponse(String geminiTextResponse, ApplicantRecord applicant) {
//     try {
//       // geminiTextResponse is now ONLY the JSON string, e.g.:
//       // {\n "overallScore": 2,\n "skillsMatch": 0, ... }
//
//       String cleaned = geminiTextResponse.trim();
//
//       // Remove any stray markdown just in case
//       cleaned = cleaned.replaceAll(RegExp(r'^```json?\s*|\s*```$'), '');
//
//       // Final aggressive fix for broken strings or braces
//       cleaned = _fixBrokenJson(cleaned);
//
//       debugPrint('Attempting to parse JSON:\n$cleaned');
//
//       final Map<String, dynamic> data = jsonDecode(cleaned);
//
//       return AIMatchResult(
//         applicantId: applicant.userId,
//         applicantName: applicant.name,
//         overallScore: _safeInt(data['overallScore']),
//         skillsMatch: _safeInt(data['skillsMatch']),
//         experienceMatch: _safeInt(data['experienceMatch']),
//         educationMatch: _safeInt(data['educationMatch']),
//         strengths: _safeStringList(data['strengths']),
//         weaknesses: _safeStringList(data['weaknesses']),
//         recommendation: data['recommendation']?.toString() ?? 'Not Recommended',
//         detailedAnalysis: data['detailedAnalysis']?.toString() ?? '',
//         timestamp: DateTime.now(),
//       );
//     } catch (e) {
//       debugPrint('FINAL PARSING FAILED: $e');
//       debugPrint('OFFENDING TEXT:\n$geminiTextResponse');
//       // Return fallback
//       return AIMatchResult(
//         applicantId: applicant.userId,
//         applicantName: applicant.name,
//         overallScore: 0,
//         skillsMatch: 0,
//         experienceMatch: 0,
//         educationMatch: 0,
//         strengths: [],
//         weaknesses: ['AI response parsing failed'],
//         recommendation: 'Error',
//         detailedAnalysis: 'Failed to parse AI response: $e',
//         timestamp: DateTime.now(),
//       );
//     }
//   }
//
//   String _fixBrokenJson(String json) {
//     var fixed = json.trim();
//
//     // Fix unterminated strings
//     fixed = fixed.replaceAllMapped(RegExp(r':\s*"([^"]*)$'), (m) => ': "${m.group(1)}"');
//
//     // trailing commas
//     fixed = fixed.replaceAll(RegExp(r',\s*([\]}])'), r'$1');
//
//     // unclosed braces
//     int open = '{'.allMatches(fixed).length;
//     int close = '}'.allMatches(fixed).length;
//     while (close < open) {
//       fixed += '}';
//       close++;
//     }
//
//     return fixed;
//   }
//
//
//
//   int _safeInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value.clamp(0, 100);
//     if (value is double) return value.round().clamp(0, 100);
//     if (value is String) return int.tryParse(value)?.clamp(0, 100) ?? 0;
//     return 0;
//   }
//
//   List<String> _safeStringList(dynamic value) {
//     if (value == null) return [];
//     if (value is List) {
//       return value
//           .where((e) => e != null)
//           .map((e) => e.toString().trim())
//           .where((s) => s.isNotEmpty)
//           .take(5)
//           .toList();
//     }
//     return [];
//   }
//
//   void clearResults() {
//     _matchResults.clear();
//     _isProcessing.clear();
//     _error = null;
//     _processedApplicants = 0;
//     _totalApplicants = 0;
//     notifyListeners();
//   }
//
//   List<MapEntry<String, AIMatchResult>> getSortedResults({bool descending = true}) {
//     final entries = _matchResults.entries.toList();
//     entries.sort((a, b) => descending
//         ? b.value.overallScore.compareTo(a.value.overallScore)
//         : a.value.overallScore.compareTo(b.value.overallScore));
//     return entries;
//   }
// }
//
// /// Data class for AI match results/applications/9l8zQfeD8EOKBaQSesl1M2x4WTD2/applied_jobs/7FkXH5ge10sR5RqVHTdq
// class AIMatchResult {
//   final String applicantId;
//   final String applicantName;
//   final int overallScore;
//   final int skillsMatch;
//   final int experienceMatch;
//   final int educationMatch;
//   final List<String> strengths;
//   final List<String> weaknesses;
//   final String recommendation;
//   final String detailedAnalysis;
//   final DateTime timestamp;
//
//   AIMatchResult({
//     required this.applicantId,
//     required this.applicantName,
//     required this.overallScore,
//     required this.skillsMatch,
//     required this.experienceMatch,
//     required this.educationMatch,
//     required this.strengths,
//     required this.weaknesses,
//     required this.recommendation,
//     required this.detailedAnalysis,
//     required this.timestamp,
//   });
//
//   Color getScoreColor() {
//     if (overallScore >= 80) return const Color(0xFF10B981); // Green
//     if (overallScore >= 60) return const Color(0xFF3B82F6); // Blue
//     if (overallScore >= 40) return const Color(0xFFF59E0B); // Orange
//     return const Color(0xFFEF4444); // Red
//   }
//
//   /// Get recommendation badge color
//   Color getRecommendationColor() {
//     switch (recommendation.toLowerCase()) {
//       case 'highly recommended':
//         return const Color(0xFF10B981);
//       case 'recommended':
//         return const Color(0xFF3B82F6);
//       case 'consider':
//         return const Color(0xFFF59E0B);
//       default:
//         return const Color(0xFFEF4444);
//     }
//   }
//
//   Map<String, dynamic> toJson() => {
//     'applicantId': applicantId,
//     'applicantName': applicantName,
//     'overallScore': overallScore,
//     'skillsMatch': skillsMatch,
//     'experienceMatch': experienceMatch,
//     'educationMatch': educationMatch,
//     'strengths': strengths,
//     'weaknesses': weaknesses,
//     'recommendation': recommendation,
//     'detailedAnalysis': detailedAnalysis,
//     'timestamp': timestamp.toIso8601String(),
//   };
//
//   factory AIMatchResult.fromJson(Map<String, dynamic> json) => AIMatchResult(
//     applicantId: json['applicantId'] ?? '',
//     applicantName: json['applicantName'] ?? '',
//     overallScore: json['overallScore'] ?? 0,
//     skillsMatch: json['skillsMatch'] ?? 0,
//     experienceMatch: json['experienceMatch'] ?? 0,
//     educationMatch: json['educationMatch'] ?? 0,
//     strengths: List<String>.from(json['strengths'] ?? []),
//     weaknesses: List<String>.from(json['weaknesses'] ?? []),
//     recommendation: json['recommendation'] ?? '',
//     detailedAnalysis: json['detailedAnalysis'] ?? '',
//     timestamp: DateTime.parse(
//         json['timestamp'] ?? DateTime.now().toIso8601String()
//     ),
//   );
// }