import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';
import 'LIst_of_Applicants_provider.dart';
import '../../services/backend_api.dart';

/// Provider for AI-powered applicant matching using Node.js Backend + Groq Cloud
class AIMatchProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ UPDATED: Backend API Configuration
  final String apiUrl = '${Env.backendUrl}/ai-match';

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
  double get progress =>
      _totalApplicants > 0 ? _processedApplicants / _totalApplicants : 0.0;
  int get processedCount => _processedApplicants;
  int get totalCount => _totalApplicants;

  AIMatchResult? getMatchResult(String applicantId) =>
      _matchResults[applicantId];
  bool isProcessingApplicant(String applicantId) =>
      _isProcessing[applicantId] ?? false;

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
      debugPrint(
        '🚀 Starting AI analysis for ${applicants.length} total applicants',
      );
      debugPrint(
        '📋 All Applicant IDs: ${applicants.map((a) => a.userId).join(", ")}',
      );

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
          skippedStatus.add(
            '${applicant.name} (${applicant.userId}) - Status: $status',
          );
          debugPrint(
            '⏭️ SKIPPED [STATUS]: ${applicant.name} - ${applicant.status}',
          );
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
            debugPrint(
              '⏭️ SKIPPED [ALREADY ANALYZED]: ${applicant.name} - Has match_score in DB',
            );
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
        debugPrint(
          '🔒 SKIPPED - ALREADY ANALYZED (${skippedAnalyzed.length}):',
        );
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
      debugPrint(
        '🎉 Analysis complete! Processed $_processedApplicants applicants',
      );
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
      final doc = await _firestore
          .collection('Posted_jobs_public')
          .doc(jobId)
          .get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Error fetching job data: $e');
      return null;
    }
  }

  Future<void> _processApplicantsInBatches(
    List<ApplicantRecord> applicants,
    Map<String, dynamic> jobData,
  ) async {
    const batchSize = 3;
    const delayBetweenBatches = Duration(milliseconds: 1000);

    debugPrint(
      '📦 Processing ${applicants.length} applicants in batches of $batchSize',
    );

    for (var i = 0; i < applicants.length; i += batchSize) {
      final end = (i + batchSize < applicants.length)
          ? i + batchSize
          : applicants.length;
      final batch = applicants.sublist(i, end);

      debugPrint(
        '🔄 Processing batch ${(i ~/ batchSize) + 1}: Applicants ${i + 1}-$end',
      );

      await Future.wait(
        batch.map((applicant) => _analyzeApplicant(applicant, jobData)),
      );

      if (end < applicants.length) {
        debugPrint('⏳ Waiting before next batch...');
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

      debugPrint('🔍 [${applicant.name}] Starting analysis...');

      // ✅ Call backend API instead of Groq directly
      final matchResult = await _callBackendAPI(applicant, jobData);

      _matchResults[applicantId] = matchResult;
      _processedApplicants++;

      debugPrint(
        '✅ [${applicant.name}] Analysis complete! Score: ${matchResult.overallScore}',
      );

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
            },
          });

      debugPrint(
        '💾 [${applicant.name}] Saved & LOCKED match score to Firestore',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [${applicant.name}] Analysis failed: $e');
      debugPrint('Stack trace: $stackTrace');

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

  /// ✅ NEW: Call Backend API instead of Groq directly
  Future<AIMatchResult> _callBackendAPI(
    ApplicantRecord applicant,
    Map<String, dynamic> jobData,
  ) async {
    try {
      debugPrint('🌐 [${applicant.name}] Sending request to backend: $apiUrl');

      // Prepare applicant data
      final String workExp = applicant.experiences.isEmpty
          ? 'No work experience'
          : applicant.experiences
                .take(3)
                .map((e) => '${e['text']} (${e['duration']})')
                .join('; ');

      final String education = applicant.educations.isEmpty
          ? 'No education details'
          : applicant.educations
                .take(2)
                .map((e) => '${e['majorSubjects']} at ${e['institutionName']}')
                .join('; ');

      // Build request payload
      final requestPayload = {
        'applicant': {
          'id': applicant.userId,
          'name': applicant.name,
          // These used to be one key, 'experienceYears', fed from a count of
          // previous jobs -- so a 2,680-hour pilot was scored as having two
          // years of experience.
          'flightHours': applicant.flightHours,
          'yearsOfExperience': applicant.yearsOfExperience,
          'previousRolesListed': applicant.roleCount,
          'licences': applicant.licences,
          'aircraftTypes': applicant.aircraftTypes,
          'targetRole': applicant.targetRole,
          'workExperience': workExp,
          'education': education,
          'skills': applicant.skills,
        },
        'job': {
          'title': jobData['title'],
          'experience': jobData['experience'],
          'skills': jobData['skills'] ?? [],
        },
      };

      debugPrint(
        '📤 [${applicant.name}] Request payload: ${jsonEncode(requestPayload)}',
      );

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: await BackendApi.headers(),
            body: jsonEncode(requestPayload),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Backend request timed out after 30 seconds',
              );
            },
          );

      debugPrint(
        '📥 [${applicant.name}] Response status: ${response.statusCode}',
      );
      debugPrint('📥 [${applicant.name}] Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Backend error ${response.statusCode}: ${response.body}',
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // ✅ Parse response from backend
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
    } catch (e, stackTrace) {
      debugPrint('❌ [${applicant.name}] Backend API call failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.clamp(0, 100);
    if (value is double) return value.round().clamp(0, 100);
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed?.clamp(0, 100) ?? 0;
    }
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
      case 'highly recommended':
        return const Color(0xFF10B981);
      case 'recommended':
        return const Color(0xFF3B82F6);
      case 'consider':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }
}
