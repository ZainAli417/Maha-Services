// job_hub.dart - Enhanced Version with Smooth, Web-Friendly Scrolling
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuple/tuple.dart';
import 'JS_Top_Bar.dart';
import 'job_seeker_provider.dart';
import 'Job_seeker_Available_jobs.dart';

/// A ScrollBehavior that enables smooth inertia scrolling on web and desktop
class SmoothScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    // Allow touch, mouse, stylus...
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Use Clamping for Android, Bouncing for iOS; web/desktop will get a smooth curve
    return const BouncingScrollPhysics(parent: ClampingScrollPhysics());
  }
}

/// Enhanced job_hub with modern UI/UX and optimized performance
class job_hub extends StatefulWidget {
  const job_hub({super.key});

  @override
  State<job_hub> createState() => _job_hubState();
}

class _job_hubState extends State<job_hub>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isMessageFocused = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFocusListener();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  void _setupFocusListener() {
    _messageFocusNode.addListener(() {
      setState(() {
        _isMessageFocused = _messageFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: Scaffold(
        body: Row(
          children: [
            // NEW SIDEBAR - Add this
            JobSeekerSidebar(activeIndex: 3), // 3 = Job Hub index

            // YOUR EXISTING CONTENT - Wrap in Expanded
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildDashboardContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    // Responsive 3-column main layout:
    return Padding(
      padding: const EdgeInsets.all(0),
      child: LayoutBuilder(builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final isDesktop = maxW > 1100;
        final isTablet = maxW > 760 && maxW <= 1100;
        final isMobile = maxW <= 760;

        if (isDesktop) {
          return Column(
            children: [
              // Header above the 3-column layout
              _buildWelcomeSection(),

              const SizedBox(height: 16),

              // The 3 columns themselves fill remaining space
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Center column: main content (jobs list)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Expanded(
                            child: Selector<JobSeekerProvider, Tuple2<bool, List<Map<String, dynamic>>>>(
                              selector: (_, p) => Tuple2(
                                p.isLoadingActiveJobs,
                                p.filteredJobs,
                              ),
                              builder: (context, data, _) {
                                final isLoading = data.item1;
                                final jobs = data.item2;

                                if (isLoading) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (jobs.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.work_outline_rounded,
                                          size: 80,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No jobs available right now.\nPlease check back later.',
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return LiveJobsForSeeker(jobs: jobs);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Right column: AI Assistant (and potential extras)
                 /*   Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            /*child: _EnhancedAIAssistant(
                              messageController: _messageController,
                              messageFocusNode: _messageFocusNode,
                              isMessageFocused: _isMessageFocused,
                            ),

                             */
                          ),
                        ],
                      ),
                    ),

                  */


                  ],
                ),
              ),
            ],
          );
        }

       else {
          // Mobile: single column stacked top-to-bottom
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 12),
                // Filters collapsed into a compact horizontal chips row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                const SizedBox(height: 8),
                // Jobs list
                SizedBox(
                  height: 600,
                  child: Consumer<JobSeekerProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoadingActiveJobs) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final jobs = provider.filteredJobs;

                      if (jobs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_outline_rounded,
                                  size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No jobs available right now.\nPlease check back later.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return LiveJobsForSeeker(jobs: jobs);
                    },
                  ),
                ),
                const SizedBox(height: 12),
               /* _EnhancedAIAssistant(
                  messageController: _messageController,
                  messageFocusNode: _messageFocusNode,
                  isMessageFocused: _isMessageFocused,
                ),
                const SizedBox(height: 12),

                */
              ],
            ),
          );
        }


      }),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Job Hub !',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explore Jobs and Be a part of your Dream Company',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

}







class _EnhancedStatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;

  const _EnhancedStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  State<_EnhancedStatCard> createState() => _EnhancedStatCardState();
}

class _EnhancedStatCardState extends State<_EnhancedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withOpacity(0.08),
                    blurRadius: 8 + _elevationAnimation.value,
                    offset: Offset(0, 2 + _elevationAnimation.value / 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildIconContainer(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatValue(),
                      const SizedBox(height: 4),
                      _buildStatLabel(),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        widget.icon,
        color: widget.iconColor,
        size: 22,
      ),
    );
  }

  Widget _buildStatValue() {
    return Text(
      widget.value,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildStatLabel() {
    return Text(
      widget.label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF6B7280),
        letterSpacing: -0.1,
      ),
    );
  }

  void _onHover(bool isHovered) {
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
}
/*
/// AI Assistant and helper components (unchanged functional behavior)
class _EnhancedAIAssistant extends StatefulWidget {
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final bool isMessageFocused;

  const _EnhancedAIAssistant({
    required this.messageController,
    required this.messageFocusNode,
    required this.isMessageFocused,
  });

  @override
  State<_EnhancedAIAssistant> createState() => _EnhancedAIAssistantState();
}

class _EnhancedAIAssistantState extends State<_EnhancedAIAssistant>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  bool _isAnalyzing = false;

  // Air Force Color Palette
  static const Color airForceBlue = Color(0xFF1B365D);
  static const Color skyBlue = Color(0xFF3485E4);
  static const Color cloudWhite = Color(0xFFF8FAFC);
  static const Color steelGray = Color(0xFF64748B);
  static const Color accentGold = Color(0xFFCD9D08);
  static const Color jetBlack = Color(0xFF0F172A);
  static const Color successGreen = Color(0xFF07B67C);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cloudWhite,
            Colors.white.withOpacity(0.98),
            cloudWhite.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: skyBlue.withOpacity(0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: airForceBlue.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: skyBlue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIHeader(),
            const SizedBox(height: 18),
            _buildMessageInput(),
            const SizedBox(height: 22),
            _buildQuickActions(),
            const SizedBox(height: 18),
            _buildProfileAnalysisSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAIHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: skyBlue.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.chat_outlined,
                color: airForceBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Career Assistant',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: jetBlack,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: successGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: successGreen.withOpacity(0.25),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Online & Ready',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: successGreen,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: skyBlue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: skyBlue.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: skyBlue,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ask me about your profile, career goals, or job search strategy.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    letterSpacing: -0.1,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    final isFocused = widget.isMessageFocused;
    final hasText = widget.messageController.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isFocused ? Colors.white : Colors.grey[50],
        border: Border.all(
          color: isFocused ? skyBlue.withOpacity(0.8) : Colors.grey.withOpacity(0.2),
          width: isFocused ? 2.0 : 1,
        ),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: skyBlue.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            _buildAttachmentButton(),
            const SizedBox(width: 10),

            // Text input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 120,
                ),
                child: TextField(
                  controller: widget.messageController,
                  // focusNode: widget.messageFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: jetBlack,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your message ...',
                    filled: false,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Voice/Send button
            _buildActionButton(),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _handleAttachment,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.attach_file_rounded,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final hasText = widget.messageController.text.trim().isNotEmpty;
    final isFocused = widget.isMessageFocused;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(6),
      child: Material(
        color: hasText ? skyBlue : (isFocused ? skyBlue.withOpacity(0.1) : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(24),
        elevation: hasText ? 2 : 0,
        shadowColor: skyBlue.withOpacity(0.18),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: hasText ? _handleSendMessage : _handleVoiceInput,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                hasText ? Icons.send_rounded : Icons.mic_rounded,
                key: ValueKey(hasText),
                color: hasText ? Colors.white : (isFocused ? skyBlue : Colors.grey.shade700),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAttachment() {
    // Implement attachment functionality
  }

  void _handleVoiceInput() {
    // Implement voice input functionality
  }

  void _handleSendMessage() {
    // Implement send message logic or keep existing
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: jetBlack,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionTile(Icons.work_outline_rounded, 'Job Match'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickActionTile(Icons.trending_up_rounded, 'Skill Gap'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickActionTile(Icons.article_outlined, 'Resume'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionTile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade800),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProfileAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF07B67C), const Color(0xFF07B67C).withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF07B67C).withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'AI-powered insights & recommendations',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAnalyzeButton(),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAnalyzing ? Colors.grey.shade600 : const Color(0xFF1B365D),
                elevation: _isAnalyzing ? 0 : 8,
                shadowColor: const Color(0xFF1B365D).withOpacity(0.28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isAnalyzing ? null : _handleAnalyzeProfile,
              child: _isAnalyzing
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Text('Analyzing...', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ],
              )
                  : Text('Analyze My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ),
        );
      },
    );
  }

  void _handleAnalyzeProfile() async {
    setState(() {
      _isAnalyzing = true;
    });

    _shimmerController.repeat();

    // Simulate analysis delay
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });
      _shimmerController.stop();
      // TODO: Navigate to profile analysis results
    }
  }
}
*/