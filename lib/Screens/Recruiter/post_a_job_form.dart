import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'R_Top_Bar.dart';
import 'Recruiter_provider_Job_listing.dart';
import '../../Widgets/quill_editor.dart';
import '../../Constant/recruiter_AI.dart';

// ─── Colors (mirrors Dashboard_Recruiter) ────────────────────────────────────
const Color _primary = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF3B82F6);
const Color _background = Color(0xFFF8FAFC);
const Color _surface = Color(0xFFFFFFFF);
const Color _textDark = Color(0xFF0F172A);
const Color _textMid = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _paleBlue = Color(0xFFEFF6FF);
const Color _secondary = Color(0xFF4A90A4);
const Color _surfaceDark = Color(0xFF2C3E50);
const Color _paleWhite = Color(0xFFF0F4F8);

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen>
    with SingleTickerProviderStateMixin {
  // ─── form + scroll ────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ─── animation ────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ─── focus nodes ──────────────────────────────────────────────────────────
  final Map<String, FocusNode> _fn = {};

  // ─── responsive ───────────────────────────────────────────────────────────
  bool _isMobile = false;

  // ─── option lists ─────────────────────────────────────────────────────────
  static const _skills = [
    'Aircraft Maintenance',
    'Avionics Systems',
    'Flight Operations',
    'Radar Systems',
    'Navigation Systems',
    'Aircraft Engines',
    'Hydraulic Systems',
    'Electrical Systems',
    'Flight Planning',
    'Air Traffic Control',
    'Weather Analysis',
    'Mission Planning',
    'Safety Protocols',
    'Emergency Procedures',
    'Quality Assurance',
    'Technical Documentation',
    'Pilot Training',
    'Crew Resource Management',
    'Aircraft Inspection',
    'Ground Support Equipment',
  ];
  static const _benefits = [
    'Military Health Insurance',
    'Dental Coverage',
    'Vision Coverage',
    'Military Retirement Plan',
    'Base Housing',
    'Family Support Services',
    'Educational Benefits',
    'Professional Training',
    'Commissary Privileges',
    'Base Recreational Facilities',
    'Travel Allowances',
    'Hazard Pay',
    'Flight Pay',
    'Technical Certification Support',
    'Career Development Programs',
  ];
  static const _workModes = [
    'On-Base',
    'Field Operations',
    'Deployed Missions',
    'Training Facilities',
  ];
  static const _rankOptions = [
    'Enlisted Personnel',
    'Non-Commissioned Officer (NCO)',
    'Senior NCO',
    'Warrant Officer',
    'Commissioned Officer',
    'Senior Officer',
    'Any Rank',
  ];
  static const _clearanceOpts = [
    'None Required',
    'Confidential',
    'Secret',
    'Top Secret',
    'Top Secret/SCI',
  ];
  static const _departmentOpts = [
    'Flight Operations',
    'Aircraft Maintenance',
    'Avionics',
    'Ground Support',
    'Air Traffic Control',
    'Weather Squadron',
    'Security Forces',
    'Logistics',
    'Intelligence',
    'Communications',
    'Medical',
    'Administration',
    'Training Command',
  ];
  static const _salaryTypeOpts = [
    'Base Pay + Allowances',
    'Hourly Rate',
    'Annual Salary',
    'Per Diem',
    'Contract Rate',
  ];

  // ─── lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    for (final f in [
      'title',
      'company',
      'salary',
      'payDetails',
      'yearsService',
      'location',
      'email',
    ]) {
      _fn[f] = FocusNode();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    for (final n in _fn.values) n.dispose();
    super.dispose();
  }

  // ─── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    _isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: _isMobile
          ? Drawer(child: RecruiterSidebar(activeIndex: 1, isDrawer: true))
          : null,
      body: Stack(
        children: [
          Row(
            children: [
              if (!_isMobile) const RecruiterSidebar(activeIndex: 1),
              Expanded(
                flex: 7,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      _buildAppBar(),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),
              if (!_isMobile)
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: _border)),
                    ),
                    child: AIJDBuilderWidget(onClose: () {}),
                  ),
                ),
            ],
          ),
          if (_isMobile) const _PostJobAIFloatingChat(),
        ],
      ),
    );
  }

  // ─── APP BAR (mirrors dashboard _buildMobileAppBar style for all sizes) ──
  Widget _buildAppBar() {
    return SafeArea(bottom: false, child: Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: Row(
        children: [
          if (_isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 24, color: _textDark),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 4),
          ],
          // Icon badge — matches dashboard style
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.flight_takeoff_outlined,
              size: 20,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post a Position',
                  style: GoogleFonts.poppins(
                    fontSize: _isMobile ? 15 : 18,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                if (!_isMobile)
                  Text(
                    'Fill in the details below to publish a new listing',
                    style: GoogleFonts.poppins(fontSize: 12, color: _textMid),
                  ),
              ],
            ),
          ),
          // Back button
          // GestureDetector(
          //   onTap: () => Navigator.of(context).maybePop(),
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: _paleBlue,
          //       borderRadius: BorderRadius.circular(8),
          //       border: Border.all(color: _accent.withOpacity(0.3)),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: _accent),
          //         const SizedBox(width: 4),
          //         Text('Back', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _accent)),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    ),);
  }

  // ─── BODY ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Consumer<job_listing_provider>(
      builder: (context, provider, _) {
        final hPad = _isMobile ? 16.0 : 40.0;
        return SingleChildScrollView(
          controller: _scrollCtrl,
          padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 40),
          child: Form(
            key: _formKey,
            child: _isMobile
                ? _buildMobileLayout(provider)
                : _buildDesktopLayout(provider),
          ),
        );
      },
    );
  }

  // ─── DESKTOP: two-column grid ─────────────────────────────────────────────
  Widget _buildDesktopLayout(job_listing_provider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo + unit header row
        _buildUnitHeader(provider),
        const SizedBox(height: 32),
        _sectionLabel('Position Details', Icons.work_outline_rounded),
        const SizedBox(height: 14),
        _buildTwoCol(
          _field(
            label: 'Position Title',
            initial: provider.tempTitle,
            onChange: provider.updateTempTitle,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            icon: Icons.badge_outlined,
            hint: 'e.g., Aircraft Maintenance Technician',
            fn: _fn['title'],
          ),
          _field(
            label: 'Air Force Unit / Base',
            initial: provider.tempCompany ?? '',
            onChange: provider.updateTempCompany,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            icon: Icons.location_city_rounded,
            hint: 'e.g., 15th Wing',
            fn: _fn['company'],
          ),
        ),
        const SizedBox(height: 16),
        _buildTwoCol(
          _dropdown(
            label: 'Department / Squadron',
            value: provider.tempDepartment ?? _departmentOpts.first,
            items: _departmentOpts,
            onChange: (v) => provider.updateTempDepartment(v!),
            icon: Icons.group_work_outlined,
          ),
          _dropdown(
            label: 'Compensation Type',
            value: provider.tempSalaryType ?? _salaryTypeOpts.first,
            items: _salaryTypeOpts,
            onChange: (v) => provider.updateTempSalaryType(v!),
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _buildTwoCol(
          _field(
            label: 'Salary Range',
            initial: provider.tempSalary ?? '',
            onChange: provider.updateTempSalary,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            icon: Icons.monetization_on_outlined,
            hint: 'e.g., \$45,000 – \$65,000',
            fn: _fn['salary'],
          ),
          _field(
            label: 'Additional Pay Details',
            initial: provider.tempPayDetails ?? '',
            onChange: provider.updateTempPayDetails,
            icon: Icons.info_outline_rounded,
            hint: 'Hazard pay, flight pay…',
            fn: _fn['payDetails'],
          ),
        ),
        const SizedBox(height: 32),

        _sectionLabel('Description & Requirements', Icons.description_outlined),
        const SizedBox(height: 14),
        AppRichTextEditor(
          label: 'Position Description',
          initialDelta: provider.tempDescription,
          onChanged: provider.updateTempDescription,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          hintText: 'Describe the role and mission support…',
          minLines: 5,
          isMobile: false,
        ),
        const SizedBox(height: 16),
        AppRichTextEditor(
          label: 'Primary Duties & Responsibilities',
          initialDelta: provider.tempResponsibilities,
          onChanged: provider.updateTempResponsibilities,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          hintText: 'List key duties — use bullets for clarity…',
          minLines: 5,
          isMobile: false,
        ),
        const SizedBox(height: 16),
        AppRichTextEditor(
          label: 'Required Qualifications & Training',
          initialDelta: provider.tempQualifications,
          onChanged: provider.updateTempQualifications,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          hintText: 'Training, certifications, years of service…',
          minLines: 5,
          isMobile: false,
        ),
        const SizedBox(height: 32),

        _sectionLabel('Rank, Security & Location', Icons.security_rounded),
        const SizedBox(height: 14),
        _buildTwoCol(
          _dropdown(
            label: 'Rank Required',
            value: provider.tempNature ?? _rankOptions.first,
            items: _rankOptions,
            onChange: (v) => provider.updateTempNature(v!),
            icon: Icons.stars_rounded,
          ),
          _dropdown(
            label: 'Security Clearance',
            value: provider.tempExperience ?? _clearanceOpts.first,
            items: _clearanceOpts,
            onChange: (v) => provider.updateTempExperience(v!),
            icon: Icons.verified_user_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _buildTwoCol(
          _field(
            label: 'Years of Service',
            initial: provider.tempPay ?? '',
            onChange: provider.updateTempPay,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            icon: Icons.timeline_rounded,
            hint: 'e.g., 2–5 years',
            fn: _fn['yearsService'],
          ),
          _field(
            label: 'Duty Location',
            initial: provider.tempLocation ?? '',
            onChange: provider.updateTempLocation,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            icon: Icons.location_on_outlined,
            hint: 'e.g., Edwards AFB, CA',
            fn: _fn['location'],
          ),
        ),
        const SizedBox(height: 32),

        _sectionLabel('Deadline & Contact', Icons.calendar_today_outlined),
        const SizedBox(height: 14),
        _buildTwoCol(
          _datePicker(provider),
          _field(
            label: 'Contact Email',
            initial: provider.tempContactEmail ?? '',
            onChange: provider.updateTempContactEmail,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
                return 'Invalid email';
              return null;
            },
            icon: Icons.email_outlined,
            hint: 'e.g., hr@airforce.mil',
            keyboard: TextInputType.emailAddress,
            fn: _fn['email'],
          ),
        ),
        const SizedBox(height: 32),

        _sectionLabel(
          'Duty Type & Skills',
          Icons.precision_manufacturing_rounded,
        ),
        const SizedBox(height: 14),
        _pillSelector(
          title: 'Duty Assignment Type',
          selected: provider.tempWorkModes,
          all: _workModes,
          color: _secondary,
          onToggle: provider.toggleWorkMode,
          icon: Icons.business_center_outlined,
        ),
        const SizedBox(height: 20),
        _pillSelector(
          title: 'Required Technical Skills',
          selected: provider.tempSkills,
          all: _skills,
          color: const Color(0xFF2E7D32),
          onToggle: provider.toggleSkill,
          icon: Icons.engineering_outlined,
        ),
        const SizedBox(height: 32),

        _sectionLabel('Benefits & Incentives', Icons.card_giftcard_outlined),
        const SizedBox(height: 14),
        _pillSelector(
          title: 'Available Benefits & Allowances',
          selected: provider.tempBenefits,
          all: _benefits,
          color: const Color(0xFF1565C0),
          onToggle: provider.toggleBenefit,
          icon: Icons.card_giftcard_outlined,
        ),
        const SizedBox(height: 40),

        _buildSubmit(provider),
      ],
    );
  }

  // ─── MOBILE: single-column ────────────────────────────────────────────────
  Widget _buildMobileLayout(job_listing_provider provider) {
    const gap = SizedBox(height: 14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUnitHeader(provider),
        const SizedBox(height: 24),

        _sectionLabel('Position Details', Icons.work_outline_rounded),
        gap,
        _field(
          label: 'Position Title',
          initial: provider.tempTitle,
          onChange: provider.updateTempTitle,
          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          icon: Icons.badge_outlined,
          hint: 'e.g., Aircraft Maintenance Technician',
          fn: _fn['title'],
        ),
        gap,
        _field(
          label: 'Air Force Unit / Base',
          initial: provider.tempCompany ?? '',
          onChange: provider.updateTempCompany,
          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          icon: Icons.location_city_rounded,
          hint: 'e.g., 15th Wing',
          fn: _fn['company'],
        ),
        gap,
        _dropdown(
          label: 'Department / Squadron',
          value: provider.tempDepartment ?? _departmentOpts.first,
          items: _departmentOpts,
          onChange: (v) => provider.updateTempDepartment(v!),
          icon: Icons.group_work_outlined,
        ),
        gap,
        _dropdown(
          label: 'Compensation Type',
          value: provider.tempSalaryType ?? _salaryTypeOpts.first,
          items: _salaryTypeOpts,
          onChange: (v) => provider.updateTempSalaryType(v!),
          icon: Icons.payments_outlined,
        ),
        gap,
        _field(
          label: 'Salary Range',
          initial: provider.tempSalary ?? '',
          onChange: provider.updateTempSalary,
          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          icon: Icons.monetization_on_outlined,
          hint: 'e.g., \$45,000 – \$65,000',
          fn: _fn['salary'],
        ),
        gap,
        _field(
          label: 'Additional Pay Details',
          initial: provider.tempPayDetails ?? '',
          onChange: provider.updateTempPayDetails,
          icon: Icons.info_outline_rounded,
          hint: 'Hazard pay, flight pay…',
          fn: _fn['payDetails'],
        ),
        const SizedBox(height: 24),

        _sectionLabel('Description & Requirements', Icons.description_outlined),
        gap,
        AppRichTextEditor(
          label: 'Position Description',
          initialDelta: provider.tempDescription,
          onChanged: provider.updateTempDescription,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          hintText: 'Describe the role and mission support…',
          minLines: 4,
          isMobile: true,
        ),
        gap,
        AppRichTextEditor(
          label: 'Primary Duties & Responsibilities',
          initialDelta: provider.tempResponsibilities,
          onChanged: provider.updateTempResponsibilities,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          hintText: 'List key duties — use bullets for clarity…',
          minLines: 4,
          isMobile: true,
        ),
        gap,
        AppRichTextEditor(
          label: 'Required Qualifications & Training',
          initialDelta: provider.tempQualifications,
          onChanged: provider.updateTempQualifications,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          hintText: 'Training, certifications, years of service…',
          minLines: 4,
          isMobile: true,
        ),
        const SizedBox(height: 24),

        _sectionLabel('Rank, Security & Location', Icons.security_rounded),
        gap,
        _dropdown(
          label: 'Rank Required',
          value: provider.tempNature ?? _rankOptions.first,
          items: _rankOptions,
          onChange: (v) => provider.updateTempNature(v!),
          icon: Icons.stars_rounded,
        ),
        gap,
        _dropdown(
          label: 'Security Clearance',
          value: provider.tempExperience ?? _clearanceOpts.first,
          items: _clearanceOpts,
          onChange: (v) => provider.updateTempExperience(v!),
          icon: Icons.verified_user_rounded,
        ),
        gap,
        _field(
          label: 'Years of Service',
          initial: provider.tempPay ?? '',
          onChange: provider.updateTempPay,
          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          icon: Icons.timeline_rounded,
          hint: 'e.g., 2–5 years',
          fn: _fn['yearsService'],
        ),
        gap,
        _field(
          label: 'Duty Location',
          initial: provider.tempLocation ?? '',
          onChange: provider.updateTempLocation,
          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          icon: Icons.location_on_outlined,
          hint: 'e.g., Edwards AFB, CA',
          fn: _fn['location'],
        ),
        const SizedBox(height: 24),

        _sectionLabel('Deadline & Contact', Icons.calendar_today_outlined),
        gap,
        _datePicker(provider),
        gap,
        _field(
          label: 'Contact Email',
          initial: provider.tempContactEmail ?? '',
          onChange: provider.updateTempContactEmail,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
              return 'Invalid email';
            return null;
          },
          icon: Icons.email_outlined,
          hint: 'e.g., hr@airforce.mil',
          keyboard: TextInputType.emailAddress,
          fn: _fn['email'],
        ),
        const SizedBox(height: 24),

        _sectionLabel(
          'Duty Type & Skills',
          Icons.precision_manufacturing_rounded,
        ),
        gap,
        _pillSelector(
          title: 'Duty Assignment Type',
          selected: provider.tempWorkModes,
          all: _workModes,
          color: _secondary,
          onToggle: provider.toggleWorkMode,
          icon: Icons.business_center_outlined,
        ),
        const SizedBox(height: 16),
        _pillSelector(
          title: 'Required Technical Skills',
          selected: provider.tempSkills,
          all: _skills,
          color: const Color(0xFF2E7D32),
          onToggle: provider.toggleSkill,
          icon: Icons.engineering_outlined,
        ),
        const SizedBox(height: 24),

        _sectionLabel('Benefits & Incentives', Icons.card_giftcard_outlined),
        gap,
        _pillSelector(
          title: 'Available Benefits & Allowances',
          selected: provider.tempBenefits,
          all: _benefits,
          color: const Color(0xFF1565C0),
          onToggle: provider.toggleBenefit,
          icon: Icons.card_giftcard_outlined,
        ),
        const SizedBox(height: 32),

        _buildSubmit(provider),
      ],
    );
  }

  // ─── UNIT HEADER (logo + emblem row, flat — no card) ─────────────────────
  Widget _buildUnitHeader(job_listing_provider provider) {
    Future<void> pick() async {
      if (kIsWeb) {
        final r = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (r != null && r.files.isNotEmpty) {
          final f = r.files.first;
          if (f.bytes != null) provider.updateTempLogo(f.bytes!, f.name);
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          provider.updateTempLogo(bytes, picked.name);
        }
      }
    }

    final avatar = GestureDetector(
      onTap: () => Future.microtask(pick),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isMobile ? 64 : 80,
        height: _isMobile ? 64 : 80,
        decoration: BoxDecoration(
          color: _paleWhite,
          shape: BoxShape.circle,
          border: Border.all(
            color: provider.tempLogoBytes != null ? _accent : _border,
            width: provider.tempLogoBytes != null ? 2.5 : 1.5,
          ),
        ),
        child: ClipOval(
          child: provider.tempLogoBytes != null
              ? Image.memory(provider.tempLogoBytes!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: _isMobile ? 22 : 26,
                      color: _textMid,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Emblem',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: _textMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unit Identification',
                style: GoogleFonts.poppins(
                  fontSize: _isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap the circle to upload your unit emblem',
                style: GoogleFonts.poppins(
                  fontSize: _isMobile ? 11 : 12,
                  color: _textMid,
                ),
              ),
            ],
          ),
        ),
        if (provider.tempLogoBytes != null)
          TextButton.icon(
            onPressed: () => Future.microtask(pick),
            icon: const Icon(Icons.edit_rounded, size: 14, color: _accent),
            label: Text(
              'Change',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: _paleBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }

  // ─── SECTION LABEL (flat divider style, no card) ──────────────────────────
  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: _isMobile ? 17 : 18, color: _primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: _isMobile ? 13 : 15,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: _border, thickness: 1)),
      ],
    );
  }

  // ─── TWO-COL HELPER ───────────────────────────────────────────────────────
  Widget _buildTwoCol(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  // ─── TEXT FIELD ───────────────────────────────────────────────────────────
  Widget _field({
    required String label,
    required String initial,
    required Function(String) onChange,
    String? Function(String?)? validator,
    IconData? icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
    FocusNode? fn,
  }) {
    final radius = _isMobile ? 10.0 : 12.0;
    final fs = _isMobile ? 13.0 : 14.0;
    final ls = _isMobile ? 12.0 : 13.0;

    return TextFormField(
      initialValue: initial,
      maxLines: maxLines,
      onChanged: onChange,
      validator: validator,
      focusNode: fn,
      keyboardType: keyboard,
      style: GoogleFonts.poppins(
        fontSize: fs,
        color: _surfaceDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(
                icon,
                size: _isMobile ? 18 : 20,
                color: _primary.withOpacity(0.55),
              )
            : null,
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: ls,
          color: _textMid,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: ls,
          color: _textMid.withOpacity(0.7),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── DROPDOWN ─────────────────────────────────────────────────────────────
  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChange,
    IconData? icon,
  }) {
    final valid = items.contains(value) ? value : items.first;
    final radius = _isMobile ? 10.0 : 12.0;
    final fs = _isMobile ? 13.0 : 14.0;
    final ls = _isMobile ? 12.0 : 13.0;

    return DropdownButtonFormField<String>(
      value: valid,
      isExpanded: true,
      items: items
          .map(
            (i) => DropdownMenuItem(
              value: i,
              child: Text(
                i,
                style: GoogleFonts.poppins(
                  fontSize: _isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChange,
      style: GoogleFonts.poppins(
        fontSize: fs,
        color: _surfaceDark,
        fontWeight: FontWeight.w500,
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
      dropdownColor: _surface,
      borderRadius: BorderRadius.circular(radius),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(
                icon,
                size: _isMobile ? 18 : 20,
                color: _primary.withOpacity(0.55),
              )
            : null,
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _primary, width: 1.8),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: ls,
          color: _textMid,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── DATE PICKER ──────────────────────────────────────────────────────────
  Widget _datePicker(job_listing_provider provider) {
    final display = _fmtDate(provider.tempDeadline);
    final radius = _isMobile ? 10.0 : 12.0;
    final fs = _isMobile ? 13.0 : 14.0;
    final ls = _isMobile ? 12.0 : 13.0;

    return TextFormField(
      readOnly: true,
      initialValue: display,
      key: ValueKey('dl_${provider.tempDeadline}'),
      validator: (_) =>
          provider.tempDeadline.isEmpty ? 'Deadline required' : null,
      style: GoogleFonts.poppins(
        fontSize: fs,
        color: _surfaceDark,
        fontWeight: FontWeight.w500,
      ),
      onTap: () async {
        DateTime init;
        try {
          init = provider.tempDeadline.isNotEmpty
              ? DateTime.parse(provider.tempDeadline)
              : DateTime.now();
        } catch (_) {
          init = DateTime.now();
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: init,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          helpText: 'Select application deadline',
          confirmText: 'Set deadline',
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: _primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: _surfaceDark,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null)
          provider.updateTempDeadline(picked.toIso8601String());
      },
      decoration: InputDecoration(
        labelText: 'Application Deadline',
        hintText: 'Select date',
        prefixIcon: Icon(
          Icons.calendar_today_outlined,
          size: _isMobile ? 18 : 20,
          color: _primary.withOpacity(0.55),
        ),
        suffixIcon: provider.tempDeadline.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16, color: _textMid),
                onPressed: () => provider.updateTempDeadline(''),
              )
            : null,
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _primary, width: 1.8),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: ls,
          color: _textMid,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── PILL SELECTOR ────────────────────────────────────────────────────────
  Widget _pillSelector({
    required String title,
    required List<String> selected,
    required List<String> all,
    required Color color,
    required void Function(String) onToggle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: _isMobile ? 15 : 17, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: _isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: _isMobile ? 6 : 8,
          runSpacing: _isMobile ? 6 : 8,
          children: all.map((item) {
            final on = selected.contains(item);
            return GestureDetector(
              onTap: () => Future.microtask(() => onToggle(item)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: _isMobile ? 11 : 14,
                  vertical: _isMobile ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: on ? color.withOpacity(0.12) : _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: on ? color : _border,
                    width: on ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (on) ...[
                      Icon(
                        Icons.check_rounded,
                        size: _isMobile ? 12 : 14,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: _isMobile ? 11 : 12,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: on ? color : _textMid,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── SUBMIT BUTTON (mirrors dashboard gradient button) ────────────────────
  Widget _buildSubmit(job_listing_provider provider) {
    return SizedBox(
      width: double.infinity,
      height: _isMobile ? 50 : 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: provider.isPosting
              ? LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade500],
                )
              : const LinearGradient(colors: [_primary, _accent]),
          borderRadius: BorderRadius.circular(_isMobile ? 12 : 14),
          boxShadow: provider.isPosting
              ? []
              : [
                  BoxShadow(
                    color: _primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_isMobile ? 12 : 14),
            ),
          ),
          onPressed: provider.isPosting
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  if ((provider.tempDepartment ?? '').isEmpty)
                    provider.updateTempDepartment(_departmentOpts.first);
                  if ((provider.tempNature ?? '').isEmpty)
                    provider.updateTempNature(_rankOptions.first);
                  if ((provider.tempExperience ?? '').isEmpty)
                    provider.updateTempExperience(_clearanceOpts.first);
                  if ((provider.tempSalaryType ?? '').isEmpty)
                    provider.updateTempSalaryType(_salaryTypeOpts.first);
                  if (_formKey.currentState!.validate()) {
                    final err = await provider.addJob();
                    if (!context.mounted) return;
                    if (err != null) {
                      _snack(context, err, isError: true);
                    } else {
                      _snack(context, 'Position posted successfully!');
                      Future.delayed(Duration.zero, () {
                        if (context.mounted) Navigator.of(context).maybePop();
                      });
                    }
                  }
                },
          child: provider.isPosting
              ? const SizedBox(
                  height: 22,
                  width: 22,
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
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isMobile ? 'Post Position' : 'Post Position Now',
                      style: GoogleFonts.poppins(
                        fontSize: _isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── SNACKBAR ─────────────────────────────────────────────────────────────
  void _snack(BuildContext ctx, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  // ─── DATE FORMAT ──────────────────────────────────────────────────────────
  String _fmtDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      return DateFormat.yMMMMd().format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ─── Post Job Floating AI Chat (Mobile) ──────────────────────────────────
class _PostJobAIFloatingChat extends StatefulWidget {
  const _PostJobAIFloatingChat();

  @override
  State<_PostJobAIFloatingChat> createState() => _PostJobAIFloatingChatState();
}

class _PostJobAIFloatingChatState extends State<_PostJobAIFloatingChat> {
  bool _showChat = false;

  void _toggleChat() => setState(() => _showChat = !_showChat);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showChat)
          Positioned(
            right: 16,
            bottom: 80,
            child: AIJDBuilderWidget(onClose: _toggleChat),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF4F46E5),
            child: InkWell(
              onTap: _toggleChat,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showChat ? Icons.close : Icons.smart_toy,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recruite.AI',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
