import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class JobDetailModal extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const JobDetailModal({
    super.key,
    required this.jobData,
  });

  @override
  State<JobDetailModal> createState() => _JobDetailModalState();
}

class _JobDetailModalState extends State<JobDetailModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Air Force Color Palette
  static const Color airForceBlue = Color(0xFF1B365D);
  static const Color skyBlue = Color(0xFF3485E4);
  static const Color cloudWhite = Color(0xFFF8FAFC);
  static const Color steelGray = Color(0xFF64748B);
  static const Color accentGold = Color(0xFFCD9D08);
  static const Color jetBlack = Color(0xFF0F172A);
  static const Color successGreen = Color(0xFF07B67C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cloudWhite,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildJobHeader(),
                      const SizedBox(height: 24),
                      _buildCompensationCard(),
                      const SizedBox(height: 20),
                      _buildJobDetailsGrid(),
                      const SizedBox(height: 20),
                      _buildDescriptionSection(),
                      const SizedBox(height: 20),
                      _buildResponsibilitiesSection(),
                      const SizedBox(height: 20),
                      _buildQualificationsSection(),
                      const SizedBox(height: 20),
                      _buildSkillsSection(),
                      const SizedBox(height: 20),
                      _buildBenefitsSection(),
                      const SizedBox(height: 20),
                      _buildWorkModesSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 70,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: airForceBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () => _shareJob(),
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border, color: Colors.white),
          onPressed: () => _bookmarkJob(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                airForceBlue,
                skyBlue.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: 10,
                child: Icon(
                  Icons.flight,
                  size: 80,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Job Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildJobHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: airForceBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.jobData['logoUrl'] != null &&
                  widget.jobData['logoUrl'].toString().isNotEmpty)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: skyBlue.withOpacity(0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.jobData['logoUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultLogo(),
                    ),
                  ),
                )
              else
                _buildDefaultLogo(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.jobData['title'] ?? 'Job Title',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: jetBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.jobData['company'] ?? 'Company Name',
                      style: TextStyle(
                        fontSize: 16,
                        color: steelGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.location_on_outlined,
                widget.jobData['location'] ?? 'Location',
                skyBlue,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.work_outline,
                widget.jobData['nature'] ?? 'Full Time',
                accentGold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [airForceBlue, skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.business,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildCompensationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [successGreen, successGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: successGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Compensation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.jobData['salaryType'] != null)
            Text(
              widget.jobData['salaryType'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            widget.jobData['salary'] ?? widget.jobData['pay'] ?? 'Competitive',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (widget.jobData['payDetails'] != null &&
              widget.jobData['payDetails'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.jobData['payDetails'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: airForceBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Job Information', Icons.info_outline),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Department',
                  widget.jobData['department'] ?? 'N/A',
                  Icons.apartment_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  'Experience',
                  widget.jobData['experience'] ?? 'N/A',
                  Icons.trending_up_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            'Application Deadline',
            widget.jobData['deadline'] ?? 'N/A',
            Icons.schedule_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _buildExpandableSection(
      'Job Description',
      Icons.description_outlined,
      widget.jobData['description'] ?? 'No description available',
    );
  }

  Widget _buildResponsibilitiesSection() {
    return _buildExpandableSection(
      'Key Responsibilities',
      Icons.checklist_outlined,
      widget.jobData['responsibilities'] ?? 'No responsibilities listed',
    );
  }

  Widget _buildQualificationsSection() {
    return _buildExpandableSection(
      'Qualifications',
      Icons.school_outlined,
      widget.jobData['qualifications'] ?? 'No qualifications specified',
    );
  }

  Widget _buildSkillsSection() {
    final skills = widget.jobData['skills'] as List<dynamic>? ?? [];
    if (skills.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: airForceBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Required Skills', Icons.psychology_outlined),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((skill) => _buildSkillChip(skill.toString()))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = widget.jobData['benefits'] as List<dynamic>? ?? [];
    if (benefits.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: airForceBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Benefits & Perks', Icons.card_giftcard_outlined),
          const SizedBox(height: 16),
          ...benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: successGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: jetBlack,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWorkModesSection() {
    final workModes = widget.jobData['workModes'] as List<dynamic>? ?? [];
    if (workModes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: airForceBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Work Arrangements', Icons.work_history_outlined),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: workModes
                .map((mode) => _buildWorkModeChip(mode.toString()))
                .toList(),
          ),
        ],
      ),
    );
  }




// Inside your Job Details widget:





  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: airForceBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: jetBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(String title, IconData icon, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: airForceBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, icon),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: steelGray,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: airForceBlue, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: steelGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: jetBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cloudWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: skyBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: airForceBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: steelGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: jetBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(value),
            icon: Icon(Icons.copy_outlined, color: airForceBlue, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: skyBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: skyBlue.withOpacity(0.3)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: skyBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWorkModeChip(String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentGold.withOpacity(0.3)),
      ),
      child: Text(
        mode,
        style: TextStyle(
          fontSize: 12,
          color: accentGold,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _shareJob() {
    // Implement share functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality would be implemented here'),
        backgroundColor: airForceBlue,
      ),
    );
  }

  void _bookmarkJob() {
    // Implement bookmark functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job bookmarked successfully'),
        backgroundColor: successGreen,
      ),
    );
  }




  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }
}