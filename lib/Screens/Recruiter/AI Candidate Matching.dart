import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'AI Candidate Matching_Provider.dart';
import 'LIst_of_Applicants_provider.dart';

class AIMatchScoreScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const AIMatchScoreScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<AIMatchScoreScreen> createState() => _AIMatchScoreScreenState();
}

class _AIMatchScoreScreenState extends State<AIMatchScoreScreen> {
  final Random _random = Random();
  String _currentStatus = 'Initializing AI analysis...';
  int _currentStepIndex = 0;

  final List<String> _processingStatuses = [
    'Reading candidate resumes...',
    'Extracting skills and experience...',
    'Analyzing education backgrounds...',
    'Evaluating work history...',
    'Comparing with job requirements...',
    'Calculating skill matches...',
    'Assessing cultural fit...',
    'Evaluating project experience...',
    'Analyzing technical expertise...',
    'Computing compatibility scores...',
    'Reviewing certifications...',
    'Evaluating career progression...',
    'Analyzing communication skills...',
    'Computing final match scores...',
  ];

  @override
  void initState() {
    super.initState();
    _startRandomStatusUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  void _startRandomStatusUpdates() {
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _currentStepIndex = (_currentStepIndex + 1) % 3;
          _currentStatus = _processingStatuses[_random.nextInt(_processingStatuses.length)];
        });

        final aiProvider = context.read<AIMatchProvider>();
        if (aiProvider.isAnalyzing) {
          _startRandomStatusUpdates();
        }
      }
    });
  }

  void _startAnalysis() async {
    final aiProvider = context.read<AIMatchProvider>();
    final applicantsProvider = context.read<ApplicantsProvider>();
    final applicants = applicantsProvider.applicants;

    if (applicants.isEmpty) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No applicants found for this job')),
      );
      return;
    }

    await aiProvider.analyzeApplicants(
      jobId: widget.jobId,
      applicants: applicants,
    );

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Consumer<AIMatchProvider>(
                builder: (context, provider, _) {
                  if (provider.error != null) {
                    return _buildErrorDialog(provider.error!);
                  }
                  return _buildProcessingDialog(provider);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingDialog(AIMatchProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie Animation with Progress Badge
          _buildAnimationSection(provider),

          const SizedBox(height: 28),

          // Title
          Text(
            'AI Analysis in Progress',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 16),

          // Progress Details
          _buildProgressInfo(provider),

          const SizedBox(height: 24),

          // Processing Steps
          _buildProcessingSteps(),

          const SizedBox(height: 20),

          // Current Status
          _buildStatusIndicator(),

          const SizedBox(height: 16),

          // Info Text
          Text(
            'Analyzing candidate profiles...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationSection(AIMatchProvider provider) {
    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lottie Animation
          SizedBox(
            width: 140,
            height: 140,
            child: Lottie.asset(
              'images/ai.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),

          // Progress Badge
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${(provider.progress * 100).round()}%',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(AIMatchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Processing ${provider.processedCount} of ${provider.totalCount}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingSteps() {
    final steps = [
      {'icon': Icons.description_outlined, 'label': 'Reading'},
      {'icon': Icons.psychology_outlined, 'label': 'Analyzing'},
      {'icon': Icons.analytics_outlined, 'label': 'Scoring'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final isActive = _currentStepIndex == index;
        final step = steps[index];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: isActive ? 52 : 44,
                height: isActive ? 52 : 44,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  )
                      : null,
                  color: isActive ? null : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : null,
                ),
                child: Icon(
                  step['icon'] as IconData,
                  size: isActive ? 24 : 20,
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step['label'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isActive ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusIndicator() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Container(
        key: ValueKey<String>(_currentStatus),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _currentStatus,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDialog(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Analysis Failed',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.2),
              ),
            ),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF991B1B),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {});
                  _startAnalysis();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}