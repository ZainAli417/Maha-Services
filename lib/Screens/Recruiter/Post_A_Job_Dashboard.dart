// job_hub.dart - Professional Enhanced Version
import 'package:flutter/material.dart';
import 'package:job_portal/Constant/recruiter_AI.dart';
import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Job_Seeker/job_seeker_provider.dart';
import 'Recruiter_Available_jobs_NEW.dart';

/// Professional Job Posting Screen with responsive design and smooth animations
class JobPostingScreen extends StatefulWidget {
  const JobPostingScreen({super.key});

  @override
  State<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<JobPostingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Fade animation for overall content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Slide animation for content entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Stagger animation for list items
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations sequentially
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _slideController.forward();
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Row(
        children: [
          RecruiterSidebar(activeIndex: 1),
          Expanded(
            child:Padding(padding: EdgeInsetsGeometry.all(0),

              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildResponsiveContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 768 && screenWidth <= 1200;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isLargeScreen) {
          // Desktop layout - Side by side
          return _buildDesktopLayout(context, constraints);
        } else if (isMediumScreen) {
          // Tablet layout - Adjusted proportions
          return _buildTabletLayout(context, constraints);
        } else {
          // Mobile layout - Stacked
          return _buildMobileLayout(context, constraints);
        }
      },
    );
  }

  // Desktop Layout (>1200px)
  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column - Job Listings
          Expanded(
            flex: 4,
            child: RepaintBoundary(
              child: _buildJobListSection(context, constraints),
            ),
          ),
          const SizedBox(width: 20),
          // Right Column - AI Assistant
          Expanded(
            flex: 2,
            child: RepaintBoundary(
              child: _buildAIAssistantSection(context, constraints),
            ),
          ),
        ],
      ),
    );
  }

  // Tablet Layout (768-1200px)
  Widget _buildTabletLayout(BuildContext context, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Listings
          Expanded(
            flex: 2,
            child: RepaintBoundary(
              child: _buildJobListSection(context, constraints),
            ),
          ),
          const SizedBox(width: 20),
          // AI Assistant (smaller on tablet)
          Expanded(
            flex: 1,
            child: RepaintBoundary(
              child: _buildAIAssistantSection(context, constraints),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Layout (<768px)
  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.work_outline), text: 'Jobs'),
                Tab(icon: Icon(Icons.smart_toy_outlined), text: 'AI Assistant'),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildJobListSection(context, constraints),
                  ),
                ),
                RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildAIAssistantSection(context, constraints),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Job List Section
  Widget _buildJobListSection(BuildContext context, BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with animation
        AnimatedBuilder(
          animation: _staggerController,
          builder: (context, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _staggerController,
                  curve: const Interval(0, 0.3, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _staggerController,
                    curve: const Interval(0, 0.3, curve: Curves.easeOut),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        // Job List
        Expanded(
          child: AnimatedBuilder(
            animation: _staggerController,
            builder: (context, child) {
              return FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _staggerController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              );
            },
            child: _buildJobStreamBuilder(),
          ),
        ),
      ],
    );
  }

  // Section Header

  // Job Stream Builder
  Widget _buildJobStreamBuilder() {
    return Consumer<JobSeekerProvider>(
      builder: (context, provider, _) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: provider.allJobsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final jobs = snapshot.data ?? [];

            if (jobs.isEmpty) {
              return _buildEmptyState();
            }

            return RepaintBoundary(
              child: JobListView_New(jobs: jobs),
            );
          },
        );
      },
    );
  }

  // Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading opportunities...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Error State
  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // Trigger rebuild
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Positions Available',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no job postings.\nCheck back soon for new opportunities!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AI Assistant Section
  Widget _buildAIAssistantSection(
      BuildContext context,
      BoxConstraints constraints,
      ) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _staggerController,
              curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _staggerController,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(

        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GeminiChatWidget(),
        ),
      ),
    );
  }
}