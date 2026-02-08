import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'Recruiter_provider_Job_listing.dart';

class PostJobDialog extends StatefulWidget {
  const PostJobDialog({super.key});

  @override
  _PostJobDialogState createState() => _PostJobDialogState();
}

class _PostJobDialogState extends State<PostJobDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Color scheme - Air Force Professional Theme
  static const Color primary = Color(0xFF1E3A5F); // Deep Air Force Blue
  static const Color secondary = Color(0xFF4A90A4); // Steel Blue
  static const Color accent = Color(0xFFFFFFFF); // Gold accent
  static const Color white = Color(0xFFFAFBFC);
  static const Color paleWhite = Color(0xFFF0F4F8);
  static const Color surfaceDark = Color(0xFF2C3E50);

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Scroll controller for web optimization
  final ScrollController _scrollController = ScrollController();

  // Focus nodes for keyboard navigation
  final Map<String, FocusNode> _focusNodes = {};

  final List<String> skillOptions = [
    'Aircraft Maintenance','Avionics Systems','Flight Operations','Radar Systems',
    'Navigation Systems','Aircraft Engines','Hydraulic Systems','Electrical Systems',
    'Flight Planning','Air Traffic Control','Weather Analysis','Mission Planning',
    'Safety Protocols','Emergency Procedures','Quality Assurance','Technical Documentation',
    'Pilot Training','Crew Resource Management','Aircraft Inspection','Ground Support Equipment'
  ];

  final List<String> benefitOptions = [
    'Military Health Insurance','Dental Coverage','Vision Coverage',
    'Military Retirement Plan','Base Housing','Family Support Services',
    'Educational Benefits','Professional Training','Commissary Privileges',
    'Base Recreational Facilities','Travel Allowances','Hazard Pay',
    'Flight Pay','Technical Certification Support','Career Development Programs'
  ];

  final List<String> workModeOptions = [
    'On-Base','Field Operations','Deployed Missions','Training Facilities'
  ];

  final List<String> rankRequirements = [
    'Enlisted Personnel','Non-Commissioned Officer (NCO)','Senior NCO',
    'Warrant Officer','Commissioned Officer','Senior Officer','Any Rank'
  ];

  final List<String> securityClearanceOptions = [
    'None Required','Confidential','Secret','Top Secret','Top Secret/SCI'
  ];

  final List<String> departmentOptions = [
    'Flight Operations','Aircraft Maintenance','Avionics','Ground Support',
    'Air Traffic Control','Weather Squadron','Security Forces','Logistics',
    'Intelligence','Communications','Medical','Administration','Training Command'
  ];

  final List<String> salaryTypeOptions = [
    'Base Pay + Allowances','Hourly Rate','Annual Salary','Per Diem','Contract Rate'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFocusNodes();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeFocusNodes() {
    final fields = [
      'title', 'company', 'description', 'responsibilities',
      'qualifications', 'salary', 'payDetails', 'yearsService', 'location'
    ];
    for (var field in fields) {
      _focusNodes[field] = FocusNode();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<job_listing_provider>(
      builder: (context, provider, child) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                  maxHeight: 850,
                  minHeight: 600,
                ),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                      spreadRadius: -10,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 60,
                      offset: const Offset(0, 30),
                      spreadRadius: -20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            scrollbars: true,
                            physics: const BouncingScrollPhysics(),
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeroSection(provider),
                                  const SizedBox(height: 32),
                                  _buildSection(
                                    title: 'Unit & Position Information',
                                    icon: Icons.military_tech_rounded,
                                    delay: 0,
                                    child: _buildUnitInfoSection(provider),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildSection(
                                    title: 'Position Description & Requirements',
                                    icon: Icons.description_outlined,
                                    delay: 1,
                                    child: _buildDescriptionSection(provider),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildSection(
                                    title: 'Compensation & Pay Information',
                                    icon: Icons.account_balance_wallet_outlined,
                                    delay: 2,
                                    child: _buildCompensationSection(provider),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildDeadlineAndContactRow(provider),
                                  const SizedBox(height: 24),
                                  _buildSection(
                                    title: 'Rank & Security Requirements',
                                    icon: Icons.security_rounded,
                                    delay: 3,
                                    child: _buildSecuritySection(provider),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildSection(
                                    title: 'Duty Type & Required Skills',
                                    icon: Icons.precision_manufacturing_rounded,
                                    delay: 4,
                                    child: _buildSkillsSection(provider),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildSection(
                                    title: 'Military Benefits & Incentives',
                                    icon: Icons.card_giftcard_rounded,
                                    delay: 5,
                                    child: _buildBenefitsSection(provider),
                                  ),
                                  const SizedBox(height: 40),
                                  _buildSubmitButton(provider),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.3), width: 1),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Air Force Job Posting',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Post aviation and support positions for Air Force personnel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: white.withOpacity(0.9),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(job_listing_provider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            secondary.withOpacity(0.1),
            primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: secondary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          _buildLogoUploader(provider),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unit Identification',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your unit emblem and fill in the position details below. This helps candidates identify official Air Force postings.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: surfaceDark.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (delay * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: primary, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitInfoSection(job_listing_provider provider) {
    return Column(
      children: [
        _buildAnimatedTextField(
          label: 'Position Title',
          initialValue: provider.tempTitle,
          onChanged: provider.updateTempTitle,
          validator: (v) => v!.trim().isEmpty ? 'Position title is required' : null,
          icon: Icons.work_outline,
          hintText: 'e.g., Aircraft Maintenance Technician, Pilot, Air Traffic Controller',
          focusNode: _focusNodes['title'],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildAnimatedTextField(
                label: 'Air Force Unit/Base',
                initialValue: provider.tempCompany ?? '',
                onChanged: provider.updateTempCompany,
                validator: (v) => v!.trim().isEmpty ? 'Unit/Base is required' : null,
                icon: Icons.location_city_rounded,
                hintText: 'e.g., 15th Wing, Edwards AFB',
                focusNode: _focusNodes['company'],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildAnimatedDropdown(
                label: 'Department/Squadron',
                value: provider.tempDepartment ?? departmentOptions.first,
                items: departmentOptions,
                onChanged: (val) => provider.updateTempDepartment(val!),
                icon: Icons.group_work_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(job_listing_provider provider) {
    return Column(
      children: [
        _buildAnimatedTextField(
          label: 'Position Description',
          initialValue: provider.tempDescription,
          onChanged: provider.updateTempDescription,
          validator: (v) => v!.trim().isEmpty ? 'Description is required' : null,
          maxLines: 4,
          icon: Icons.edit_note_rounded,
          hintText: 'Describe the role, mission support requirements, and operational responsibilities',
        ),
        const SizedBox(height: 20),
        _buildAnimatedTextField(
          label: 'Primary Duties & Responsibilities',
          initialValue: provider.tempResponsibilities ?? '',
          onChanged: provider.updateTempResponsibilities,
          validator: (v) => v!.trim().isEmpty ? 'Responsibilities are required' : null,
          maxLines: 3,
          icon: Icons.checklist_rounded,
          hintText: 'List key operational duties, maintenance tasks, or administrative responsibilities',
          focusNode: _focusNodes['responsibilities'],
        ),
        const SizedBox(height: 20),
        _buildAnimatedTextField(
          label: 'Required Qualifications & Training',
          initialValue: provider.tempQualifications ?? '',
          onChanged: provider.updateTempQualifications,
          validator: (v) => v!.trim().isEmpty ? 'Qualifications are required' : null,
          maxLines: 3,
          icon: Icons.school_outlined,
          hintText: 'Military training, certifications, technical schools, or civilian education required',
          focusNode: _focusNodes['qualifications'],
        ),
      ],
    );
  }

  Widget _buildCompensationSection(job_listing_provider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnimatedDropdown(
                label: 'Compensation Type',
                value: provider.tempSalaryType ?? salaryTypeOptions.first,
                items: salaryTypeOptions,
                onChanged: (val) => provider.updateTempSalaryType(val!),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildAnimatedTextField(
                label: 'Salary Range',
                initialValue: provider.tempSalary ?? '',
                onChanged: provider.updateTempSalary,
                validator: (v) => v!.trim().isEmpty ? 'Salary range is required' : null,
                icon: Icons.monetization_on_outlined,
                hintText: 'e.g., \$45,000 - \$65,000 or E-5 Base Pay + BAH',
                focusNode: _focusNodes['salary'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildAnimatedTextField(
          label: 'Additional Pay Details',
          initialValue: provider.tempPayDetails ?? '',
          onChanged: provider.updateTempPayDetails,
          maxLines: 2,
          icon: Icons.info_outline_rounded,
          hintText: 'Special pay, hazard pay, flight pay, bonuses, or allowances included',
          focusNode: _focusNodes['payDetails'],
        ),
      ],
    );
  }

  Widget _buildDeadlineAndContactRow(job_listing_provider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildAnimatedDatePicker(provider),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildAnimatedTextField(
            label: 'Contact Email',
            initialValue: provider.tempContactEmail ?? '',
            onChanged: provider.updateTempContactEmail,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Email is required';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Enter valid email';
              }
              return null;
            },
            icon: Icons.email_outlined,
            hintText: 'e.g., hr@airforce.mil',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(job_listing_provider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnimatedDropdown(
                label: 'Minimum Rank Required',
                value: provider.tempNature ?? rankRequirements.first,
                items: rankRequirements,
                onChanged: (val) => provider.updateTempNature(val!),
                icon: Icons.stars_rounded,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildAnimatedDropdown(
                label: 'Security Clearance',
                value: provider.tempExperience ?? securityClearanceOptions.first,
                items: securityClearanceOptions,
                onChanged: (val) => provider.updateTempExperience(val!),
                icon: Icons.verified_user_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedTextField(
                label: 'Years of Service Required',
                initialValue: provider.tempPay ?? '',
                onChanged: provider.updateTempPay,
                validator: (v) => v!.trim().isEmpty ? 'Years of service is required' : null,
                icon: Icons.timeline_rounded,
                hintText: 'e.g., 2-5 years, Entry Level, 10+ years',
                focusNode: _focusNodes['yearsService'],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildAnimatedTextField(
                label: 'Duty Location',
                initialValue: provider.tempLocation ?? '',
                onChanged: provider.updateTempLocation,
                validator: (v) => v!.trim().isEmpty ? 'Location is required' : null,
                icon: Icons.location_on_outlined,
                hintText: 'e.g., Edwards AFB, CA or Worldwide Assignment',
                focusNode: _focusNodes['location'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsSection(job_listing_provider provider) {
    return Column(
      children: [
        _buildEnhancedPillSelector(
          title: 'Duty Assignment Type',
          selectedItems: provider.tempWorkModes,
          availableItems: workModeOptions,
          color: secondary,
          onToggle: provider.toggleWorkMode,
          icon: Icons.business_center_outlined,
        ),
        const SizedBox(height: 24),
        _buildEnhancedPillSelector(
          title: 'Required Technical Skills',
          selectedItems: provider.tempSkills,
          availableItems: skillOptions,
          color: const Color(0xFF2E7D32),
          onToggle: provider.toggleSkill,
          icon: Icons.engineering_outlined,
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(job_listing_provider provider) {
    return _buildEnhancedPillSelector(
      title: 'Available Benefits & Allowances',
      selectedItems: provider.tempBenefits,
      availableItems: benefitOptions,
      color: const Color(0xFF1565C0),
      onToggle: provider.toggleBenefit,
      icon: Icons.card_giftcard_outlined,
    );
  }

  Widget _buildLogoUploader(job_listing_provider provider) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            withData: true,
          );
          if (result != null && result.files.isNotEmpty) {
            final file = result.files.first;
            if (file.bytes != null) {
              provider.updateTempLogo(file.bytes!, file.name);
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: paleWhite,
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: provider.tempLogoBytes != null ? accent : primary.withOpacity(0.3),
              width: provider.tempLogoBytes != null ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: provider.tempLogoBytes != null
                ? Image.memory(
              provider.tempLogoBytes!,
              fit: BoxFit.cover,
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 32,
                  color: primary.withOpacity(0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload\nEmblem',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: primary.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
    IconData? icon,
    String? hintText,
    FocusNode? focusNode,
    TextInputType? keyboardType,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: surfaceDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: icon != null
              ? Icon(icon, color: primary.withOpacity(0.6), size: 20)
              : null,
          filled: false,
          fillColor: paleWhite,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          errorStyle: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    final validValue = items.contains(value) ? value : items.first;

    return DropdownButtonFormField<String>(
      value: validValue,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
      onChanged: onChanged,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: surfaceDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: primary.withOpacity(0.6), size: 20)
            : null,
        filled: true,
        fillColor: paleWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
      dropdownColor: white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildAnimatedDatePicker(job_listing_provider provider) {
    return FormField<String>(
      initialValue: provider.tempDeadline,
      validator: (v) => provider.tempDeadline.isEmpty ? 'Deadline is required' : null,
      builder: (state) {
        String displayText = _formatDeadlineForDisplay(provider.tempDeadline);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Deadline',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  DateTime initialDate;
                  try {
                    initialDate = provider.tempDeadline.isNotEmpty
                        ? DateTime.parse(provider.tempDeadline)
                        : DateTime.now();
                  } catch (_) {
                    initialDate = DateTime.now();
                  }

                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    helpText: 'Select application deadline',
                    confirmText: 'Set deadline',
                    initialEntryMode: DatePickerEntryMode.calendar,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: primary,
                            onPrimary: white,
                            surface: white,
                            onSurface: surfaceDark,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    provider.updateTempDeadline(picked.toIso8601String());
                    state.didChange(provider.tempDeadline);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: paleWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.hasError
                          ? Colors.redAccent
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: primary.withOpacity(0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayText.isEmpty ? 'Select deadline' : displayText,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: displayText.isEmpty
                                ? Colors.grey.shade500
                                : surfaceDark,
                            fontWeight: displayText.isEmpty
                                ? FontWeight.w400
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (provider.tempDeadline.isNotEmpty)
                        AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 200),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                provider.updateTempDeadline('');
                                state.didChange(provider.tempDeadline);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  state.errorText ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedPillSelector({
    required String title,
    required List<String> selectedItems,
    required List<String> availableItems,
    required Color color,
    required void Function(String) onToggle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: surfaceDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: availableItems.map((item) {
            final isSelected = selectedItems.contains(item);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onToggle(item),
                  borderRadius: BorderRadius.circular(25),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.15) : paleWhite,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: color,
                          ),
                        ),
                        if (isSelected) const SizedBox(width: 6),
                        Text(
                          item,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? color : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(job_listing_provider provider) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: provider.isPosting
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [primary, primary.withOpacity(0.9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: provider.isPosting
              ? []
              : [
            BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: provider.isPosting
                ? null
                : () async {
              if (_formKey.currentState!.validate()) {
                final error = await provider.addJob();
                if (!context.mounted) return;
                if (error != null) {
                  _showErrorSnackBar(context, error);
                } else {
                  _showSuccessSnackBar(context);
                  Navigator.of(context).pop();
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: provider.isPosting
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.flight_takeoff_rounded,
                      color: white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Post Position Now',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Position posted successfully!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDeadlineForDisplay(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat.yMMMMd().format(dt);
    } catch (_) {
      return iso;
    }
  }
}