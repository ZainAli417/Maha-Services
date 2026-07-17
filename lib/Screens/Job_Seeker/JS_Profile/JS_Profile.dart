// js_profile_screen.dart
// ignore_for_file: invalid_use_of_protected_member

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Recruiter/LIst_of_Applicants.dart';
import '../JS_Top_Bar.dart';
import '../../../Constant/js_header.dart';
import 'JS_Profile_Provider.dart';
import 'JS_Profile_Sidebar.dart';

class ProfileScreen_NEW extends StatefulWidget {
  const ProfileScreen_NEW({super.key});

  @override
  State<ProfileScreen_NEW> createState() => _JSProfileScreenState();
}

class _JSProfileScreenState extends State<ProfileScreen_NEW>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final ScrollController _stepScrollController = ScrollController();
  final TextEditingController _profSummaryCtrl = TextEditingController();

  bool _didLoad = false;
  // Controllers for form fields
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _secondaryEmailCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _nationalityCtrl = TextEditingController();
  final TextEditingController _objectivesCtrl = TextEditingController();
  final TextEditingController _personalSummaryCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _institutionCtrl = TextEditingController();
  final TextEditingController _eduStartYearCtrl = TextEditingController();
  final TextEditingController _eduEndYearCtrl = TextEditingController();
  final TextEditingController _majorCtrl = TextEditingController();
  final TextEditingController _marksCtrl = TextEditingController();
  final TextEditingController _experienceTextCtrl = TextEditingController();
  final TextEditingController _singleLineCtrl = TextEditingController();

  // ✅ ADD THESE EXPERIENCE CONTROLLERS:
  final TextEditingController _expOrgCtrl = TextEditingController();
  final TextEditingController _expRoleCtrl = TextEditingController();
  final TextEditingController _expDurationCtrl = TextEditingController();
  final TextEditingController _expDutiesCtrl = TextEditingController();
  final TextEditingController _expRankCtrl = TextEditingController();
  final TextEditingController _expUnitCtrl = TextEditingController();
  final TextEditingController _expLocationCtrl = TextEditingController();
  final TextEditingController _expFlightHoursCtrl = TextEditingController();
  final TextEditingController _expAircraftTypeCtrl = TextEditingController();
  final TextEditingController _expCommandCtrl = TextEditingController();
  final TextEditingController _expStartDateCtrl = TextEditingController();
  final TextEditingController _expEndDateCtrl = TextEditingController();

  // ✅ ADD CERTIFICATION CONTROLLERS:
  final TextEditingController _certNameCtrl = TextEditingController();
  final TextEditingController _certOrgCtrl = TextEditingController();

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller, {
    DateTime? initialDate,
    Function(String)? onDateSelected, // ✅ NEW: Callback parameter
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1930),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF14507F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dateString = picked.toString().split(' ')[0];
      controller.text = dateString;

      // ✅ NEW: Call the callback to update provider
      if (onDateSelected != null) {
        debugPrint(
          '[_selectDate] Date selected: $dateString, calling onDateSelected callback',
        );
        onDateSelected(dateString);
      } else {
        debugPrint(
          '[_selectDate] WARNING: Date selected but no callback provided!',
        );
      }
    }
  }

  // ✅ NEW: Month/Year picker for experience dates
  Future<void> _selectMonthYear(
    BuildContext context,
    TextEditingController controller, {
    DateTime? initialDate,
  }) async {
    final DateTime now = initialDate ?? DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Select Month & Year',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SizedBox(
                width: 300,
                height: 300,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              selectedYear--;
                            });
                          },
                        ),
                        Text(
                          '$selectedYear',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              selectedYear++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = month == selectedMonth;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedMonth = month;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF14507F)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  _getMonthName(month),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.text =
                        '${_getMonthName(selectedMonth)} $selectedYear';
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14507F),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectYear(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final int currentYear = DateTime.now().year;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Year',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1930),
              lastDate: DateTime(currentYear + 10),
              selectedDate: controller.text.isNotEmpty
                  ? DateTime(int.tryParse(controller.text) ?? currentYear)
                  : DateTime(currentYear),
              onChanged: (DateTime dateTime) {
                controller.text = dateTime.year.toString();
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  final List<String> _stepTitles = [
    'Personal Info',
    'Education Info',
    'Professional Info',
    'Questionnaire',
    'Experience',
    'Certifications',
    'Publications',
    'Awards',
    'References',
    // 'Documents'
  ];

  final List<IconData> _stepIcons = [
    Icons.supervised_user_circle_outlined,
    Icons.school_outlined,
    Icons.work_outline,
    Icons.quiz_outlined,
    Icons.work_history_outlined,
    Icons.verified,
    Icons.file_copy_outlined,
    Icons.video_file_outlined,
    Icons.assured_workload_outlined,
    Icons.group_add_outlined, // FontAwesomeIcons.folder,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubicEmphasized,
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<ProfileProvider_NEW>(context, listen: false);
      prov.loadAllSectionsOnce().then((_) {
        _nameCtrl.text = prov.name;
        _emailCtrl.text = prov.email;
        _secondaryEmailCtrl.text = prov.secondaryEmail;
        _contactCtrl.text = prov.contactNumber;
        _nationalityCtrl.text = prov.nationality;
        _objectivesCtrl.text = prov.objectives;
        _personalSummaryCtrl.text = prov.personalSummary;
        _dobCtrl.text = prov.dob;
        _profSummaryCtrl.text = prov.professionalProfileSummary;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _stepScrollController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _secondaryEmailCtrl.dispose();
    _contactCtrl.dispose();
    _nationalityCtrl.dispose();
    _objectivesCtrl.dispose();
    _personalSummaryCtrl.dispose();
    _dobCtrl.dispose();
    _institutionCtrl.dispose();
    _eduStartYearCtrl.dispose();
    _eduEndYearCtrl.dispose();
    _majorCtrl.dispose();
    _marksCtrl.dispose();
    _experienceTextCtrl.dispose();
    _singleLineCtrl.dispose();
    _profSummaryCtrl.dispose();

    // ✅ ADD THESE:
    _expOrgCtrl.dispose();
    _expRoleCtrl.dispose();
    _expDurationCtrl.dispose();
    _expDutiesCtrl.dispose();
    _expRankCtrl.dispose();
    _expUnitCtrl.dispose();
    _expLocationCtrl.dispose();
    _expFlightHoursCtrl.dispose();
    _expAircraftTypeCtrl.dispose();
    _expCommandCtrl.dispose();
    _expStartDateCtrl.dispose();
    _expEndDateCtrl.dispose();
    _certNameCtrl.dispose();
    _certOrgCtrl.dispose();

    super.dispose();
  }

  void _scrollToCurrentStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_stepScrollController.hasClients) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        const itemWidth = 180.0;
        final targetOffset = (_currentStep * itemWidth) - (screenWidth / 4);
        _stepScrollController.animateTo(
          targetOffset.clamp(
            0.0,
            _stepScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < 768;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile;
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: isMobile
            ? const Drawer(child: JobSeekerSidebar(activeIndex: 1, isDrawer: true))
            : null,
        body: Row(
          children: [
            if (!isMobile) const JobSeekerSidebar(activeIndex: 1),
            Expanded(
              child: FadeTransition(
                opacity: _animController,
                child: _buildContent(context),
              ),
            ),
          ],
        ),
        floatingActionButton: null,
      ),
    );
  }

  void _showSidebarSheet(ProfileProvider_NEW prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: JSProfileSidebar(provider: prov),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isMobile = _isMobile;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FB),
      body: Consumer<ProfileProvider_NEW>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return _buildBrandedLoader();
          }
          if (isMobile) {
            return Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildMainContent(prov)),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildMainContent(prov)),
                  ],
                ),
              ),
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: JSProfileSidebar(provider: prov),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandedLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2EC4B6).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your profile…',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3E5C76),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return JobSeekerHeader(
      icon: Icons.person_add_alt_outlined,
      title: 'Profile',
      subtitle: 'One-click profile analyzer & CV builder',
      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
      trailing: _buildProgressIndicator(),
    );
  }

  Widget _buildProgressIndicator() {
    final isMobile = _isMobile;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 16,
        vertical: isMobile ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF43E0D2).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Step ${_currentStep + 1} of ${_stepTitles.length}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF43E0D2),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            Container(
              width: 100,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentStep + 1) / _stepTitles.length,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43E0D2), Color(0xFF2EC4B6)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent(ProfileProvider_NEW prov) {
    final isMobile = _isMobile;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 20,
        isMobile ? 0 : 20, // Reduced top padding to use dead space
        isMobile ? 5 : 20,
        isMobile ? 10 : 20,
      ),
      child: Column(
        children: [
          // Capsule list + the content it reveals sit directly in the main
          // area as ONE seamless container — no sub-card, same background.
          _buildStepIndicators(),
          SizedBox(height: isMobile ? 8 : 24),
          Expanded(
            child: RepaintBoundary(
              child: Container(
                key: ValueKey<int>(_currentStep),
                child: _buildCurrentStepContent(prov),
              ),
            ),
          ),
          _buildNavigationButtons(prov),
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    final isMobile = _isMobile;
    return SizedBox(
      height: isMobile ? 40 : 54,
      child: ListView.builder(
        controller: _stepScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _stepTitles.length,
        cacheExtent: 700,
        itemBuilder: (context, index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _currentStep = index);
                  _scrollToCurrentStep();
                },
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 18,
                    vertical: isMobile ? 7 : 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF14507F), Color(0xFF0A2E4F)],
                          )
                        : null,
                    color: isActive
                        ? null
                        : (isCompleted
                            ? const Color(0xFFE4F6F4)
                            : const Color(0xFFF4F9FB)),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF43E0D2)
                          : (isCompleted
                              ? const Color(0xFF2EC4B6).withValues(alpha: 0.4)
                              : const Color(0xFFDCE7EF)),
                      width: isActive ? 1.4 : 1,
                    ),
                    boxShadow: null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : _stepIcons[index],
                        color: isActive
                            ? const Color(0xFF43E0D2)
                            : (isCompleted
                                ? const Color(0xFF15A99C)
                                : const Color(0xFF8AA5B5)),
                        size: isMobile ? 14 : 18,
                      ),
                      SizedBox(width: isMobile ? 5 : 8),
                      Text(
                        _stepTitles[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 11.5 : 13.5,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : (isCompleted
                                  ? const Color(0xFF15A99C)
                                  : const Color(0xFF5E7A8E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index < _stepTitles.length - 1)
                Container(
                  width: isMobile ? 12 : 22,
                  height: 2,
                  margin: EdgeInsets.symmetric(horizontal: isMobile ? 3 : 7),
                  decoration: BoxDecoration(
                    color: index < _currentStep
                        ? const Color(0xFF2EC4B6)
                        : const Color(0xFFDCE7EF),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Branded section sub-header: tiny teal eyebrow + bold navy title.
  Widget _sectionHeader(String eyebrow, String title, {IconData? icon}) {
    final isMobile = _isMobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 9.5 : 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: const Color(0xFF15A99C),
          ),
        ),
        SizedBox(height: isMobile ? 3 : 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: isMobile ? 16 : 18, color: const Color(0xFF14507F)),
              SizedBox(width: isMobile ? 6 : 8),
            ],
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 15 : 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B2239),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Brand gradient primary action button (teal→navy) used for "Add ..." actions.
  Widget _brandAddButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isMobile = _isMobile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 22,
            vertical: isMobile ? 11 : 13,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isMobile ? 16 : 18, color: Colors.white),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Thin teal-tinted divider.
  Widget _brandDivider() => Container(
        height: 1,
        color: const Color(0xFFDCE7EF),
      );

  // Branded white entry card with brand border, soft shadow and left accent bar.
  Widget _entryCard({
    required Color accent,
    required IconData icon,
    required VoidCallback onRemoveTap,
    required String title,
    String? subtitle,
  }) {
    final isMobile = _isMobile;
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        border: Border.all(color: const Color(0xFFDCE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2239).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: isMobile ? 46 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent, const Color(0xFF2EC4B6)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        color: accent, size: isMobile ? 18 : 20),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B2239),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 11 : 12,
                              color: const Color(0xFF5E7A8E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRemoveTap,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(ProfileProvider_NEW prov) {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfo(prov);
      case 1:
        return _buildEducation(prov);
      case 2:
        return _buildProfessionalProfile(prov);
      case 3:
        return _buildQuestionnaire(prov);
      case 4:
        return _buildExperience(prov);
      case 5:
        return _buildCertifications(prov);
      case 6:
        return _buildPublications(prov);
      case 7:
        return _buildAwards(prov);
      case 8:
        return _buildReferences(prov);
      default:
        return const SizedBox();
    }
  }

  // ── Questionnaire (read-only, filled during signup onboarding) ────────────
  Widget _buildQuestionnaire(ProfileProvider_NEW prov) {
    final isMobile = _isMobile;
    final responses = prov.questionnaireResponses;

    if (responses.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Onboarding',
              'Questionnaire',
              icon: Icons.quiz_outlined,
            ),
            SizedBox(height: isMobile ? 20 : 28),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 20 : 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F9FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE7EF)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_late_outlined,
                    color: Color(0xFF8AA5B5),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No questionnaire responses yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3E5C76),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The answers you provide during onboarding will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 11.5 : 13,
                      color: const Color(0xFF5E7A8E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Group responses by their 'group' label, preserving first-seen order.
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in responses) {
      final g = (r['group'] ?? 'General').toString();
      grouped.putIfAbsent(g, () => []).add(r);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            prov.questionnaireRole.isEmpty
                ? 'Onboarding'
                : prov.questionnaireRole,
            'Questionnaire',
            icon: Icons.quiz_outlined,
          ),
          SizedBox(height: isMobile ? 16 : 22),
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 10.5 : 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: const Color(0xFF15A99C),
                    ),
                  ),
                ),
                ...entry.value.map((r) => _questionnaireCard(r)),
                SizedBox(height: isMobile ? 8 : 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _questionnaireCard(Map<String, dynamic> r) {
    final isMobile = _isMobile;
    final question = (r['question'] ?? '').toString();
    final unit = (r['unit'] ?? '').toString();
    final raw = r['answer'];
    String answer;
    if (raw is List) {
      answer = raw.map((e) => e.toString()).join(', ');
    } else if (raw is bool) {
      answer = raw ? 'Yes' : 'No';
    } else {
      answer = raw?.toString() ?? '';
    }
    if (unit.isNotEmpty && answer.isNotEmpty) answer = '$answer $unit';

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        border: Border.all(color: const Color(0xFFDCE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2239).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14507F), Color(0xFF2EC4B6)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5E7A8E),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    answer.isEmpty ? '—' : answer,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 13.5 : 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B2239),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.person_outline,
          //       color: const Color(0xFF14507F),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Personal Information',
          //       style: GoogleFonts.plusJakartaSans(
          //         fontSize: 18,
          //         fontWeight: FontWeight.w600,
          //         color: const Color(0xFF0F172A),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _pickAndUploadProfilePic(prov),
                  child: Stack(
                    children: [
                      Container(
                        width: _isMobile ? 56 : 80,
                        height: _isMobile ? 56 : 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF2EC4B6), width: 2),
                          gradient: prov.profilePicUrl.isEmpty
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF14507F),
                                    Color(0xFF2EC4B6),
                                  ],
                                )
                              : null,
                          image: prov.profilePicUrl.isNotEmpty
                              ? DecorationImage(
                                  // Decode at target size — an 80px avatar
                                  // never needs a full-res network decode.
                                  image: ResizeImage(
                                    NetworkImage(prov.profilePicUrl),
                                    width: 200,
                                    height: 200,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: prov.profilePicUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: _isMobile ? 28 : 40,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(_isMobile ? 5 : 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14507F),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: _isMobile ? 10 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: _isMobile ? 12 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isMobile)
                      Text(
                        'Upload Profile Photo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    if (!_isMobile) const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                      icon: Icons.person_outline,
                      onChanged: prov.updateName,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isMobile
              ? Column(
                  children: [
                    _buildTextField(
                      label: 'Email Address',
                      controller: _emailCtrl,
                      icon: Icons.email_outlined,
                      onChanged: prov.updateEmail,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Secondary Email',
                      controller: _secondaryEmailCtrl,
                      icon: Icons.email_outlined,
                      onChanged: prov.updateSecondaryEmail,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Email Address',
                        controller: _emailCtrl,
                        icon: Icons.email_outlined,
                        onChanged: prov.updateEmail,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Secondary Email',
                        controller: _secondaryEmailCtrl,
                        icon: Icons.email_outlined,
                        onChanged: prov.updateSecondaryEmail,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          _isMobile
              ? Column(
                  children: [
                    _buildTextField(
                      label: 'Contact Number',
                      controller: _contactCtrl,
                      icon: Icons.phone_outlined,
                      onChanged: prov.updateContactNumber,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Nationality',
                      controller: _nationalityCtrl,
                      icon: Icons.public,
                      onChanged: prov.updateNationality,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Contact Number',
                        controller: _contactCtrl,
                        icon: Icons.phone_outlined,
                        onChanged: prov.updateContactNumber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Nationality',
                        controller: _nationalityCtrl,
                        icon: Icons.public,
                        onChanged: prov.updateNationality,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          _isMobile
              ? Column(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          _selectDate(
                            context,
                            _dobCtrl,
                            initialDate: _dobCtrl.text.isNotEmpty
                                ? DateTime.tryParse(_dobCtrl.text)
                                : DateTime(1930),
                            onDateSelected: (dateString) {
                              prov.updateDob(dateString);
                            },
                          );
                        },
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'Date of Birth',
                            controller: _dobCtrl,
                            icon: Icons.calendar_today_outlined,
                            onChanged: (v) => prov.updateDob(v),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Career Objectives',
                      controller: _objectivesCtrl,
                      icon: Icons.lightbulb_outline,
                      maxLines: 3,
                      onChanged: prov.updateObjectives,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            debugPrint('[DOB] Date picker opened');
                            _selectDate(
                              context,
                              _dobCtrl,
                              initialDate: _dobCtrl.text.isNotEmpty
                                  ? DateTime.tryParse(_dobCtrl.text)
                                  : DateTime(1930),
                              onDateSelected: (dateString) {
                                debugPrint(
                                  '[DOB] Date selected from picker: $dateString',
                                );
                                prov.updateDob(dateString);
                                debugPrint(
                                  '[DOB] Provider updated - dirty flag: ${prov.personalDirty}',
                                );
                              },
                            );
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(
                              label: 'Date of Birth',
                              controller: _dobCtrl,
                              icon: Icons.calendar_today_outlined,
                              onChanged: (v) {
                                debugPrint(
                                  '[DOB] TextField onChanged called: $v (This should NOT happen for date picker)',
                                );
                                prov.updateDob(v);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Career Objectives',
                        controller: _objectivesCtrl,
                        icon: Icons.lightbulb_outline,
                        maxLines: 3,
                        onChanged: prov.updateObjectives,
                      ),
                    ),
                  ],
                ),
          // const SizedBox(height: 20),
          // _buildTextField(
          //   label: 'Professional Summary',
          //   controller: _personalSummaryCtrl,
          //   icon: Icons.description_outlined,
          //   maxLines: 5,
          //   hint: 'Provide a brief overview of yourself...',
          //   onChanged: prov.updatePersonalSummary,
          // ),
          // const SizedBox(height: 24),
          // const Divider(height: 1),
          const SizedBox(height: 14),
          _buildSkillsSection(prov),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(ProfileProvider_NEW prov) {
    final isMobile = _isMobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Expertise', 'Skills', icon: Icons.interests_outlined),
        SizedBox(height: isMobile ? 12 : 16),
        if (prov.skillsList.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prov.skillsList.asMap().entries.map((e) {
              return Container(
                padding:
                    const EdgeInsets.only(left: 12, right: 6, top: 7, bottom: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F6F4),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF2EC4B6).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF14507F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => prov.removeSkillAt(e.key),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14507F).withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF14507F),
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        SizedBox(height: isMobile ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: prov.skillController,
                decoration: InputDecoration(
                  hintText: 'Add a skill',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF8AA5B5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F9FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCE7EF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCE7EF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF2EC4B6), width: 1.6),
                  ),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF0B2239),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => prov.addSkillEntry(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2EC4B6).withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEducation(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.school_outlined,
          //       color: const Color(0xFF14507F),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Education Background',
          //       style: GoogleFonts.plusJakartaSans(
          //         fontSize: 18,
          //         fontWeight: FontWeight.w600,
          //         color: const Color(0xFF0F172A),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),
          _buildTextField(
            label: 'Institution Name',
            controller: _institutionCtrl,
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 12),
          _isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _selectYear(context, _eduStartYearCtrl),
                            child: AbsorbPointer(
                              child: _buildTextField(
                                label: 'Start Year',
                                controller: _eduStartYearCtrl,
                                icon: Icons.calendar_today,
                                hint: 'Start',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectYear(context, _eduEndYearCtrl),
                            child: AbsorbPointer(
                              child: _buildTextField(
                                label: 'End Year',
                                controller: _eduEndYearCtrl,
                                icon: Icons.calendar_today,
                                hint: 'End',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Major Subjects',
                      controller: _majorCtrl,
                      icon: Icons.menu_book_outlined,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  _selectYear(context, _eduStartYearCtrl),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  label: 'Start Year',
                                  controller: _eduStartYearCtrl,
                                  icon: Icons.calendar_today,
                                  hint: 'Start',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  _selectYear(context, _eduEndYearCtrl),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  label: 'End Year',
                                  controller: _eduEndYearCtrl,
                                  icon: Icons.calendar_today,
                                  hint: 'End',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Major Subjects',
                        controller: _majorCtrl,
                        icon: Icons.menu_book_outlined,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Marks / CGPA',
            controller: _marksCtrl,
            icon: Icons.grade_outlined,
          ),
          const SizedBox(height: 20),
          _brandAddButton(
            label: 'Add Education',
            icon: Icons.add_circle_outline,
            onTap: () {
              prov.tempSchool = _institutionCtrl.text;
              prov.tempEduStart = _eduStartYearCtrl.text;
              prov.tempEduEnd = _eduEndYearCtrl.text;
              prov.tempFieldOfStudy = _majorCtrl.text;
              prov.tempDegree = _marksCtrl.text;
              prov.addEducationEntry(context);
              _institutionCtrl.clear();
              _eduStartYearCtrl.clear();
              _eduEndYearCtrl.clear();
              _majorCtrl.clear();
              _marksCtrl.clear();
            },
          ),
          if (prov.educationalProfile.isNotEmpty) ...[
            SizedBox(height: _isMobile ? 20 : 32),
            _brandDivider(),
            SizedBox(height: _isMobile ? 16 : 24),
            _sectionHeader('Saved', 'Added Education'),
            SizedBox(height: _isMobile ? 12 : 16),
            ...prov.educationalProfile.asMap().entries.map((e) {
              final item = e.value;
              return _entryCard(
                accent: const Color(0xFF14507F),
                icon: Icons.school_outlined,
                onRemoveTap: () => prov.removeEducationAt(e.key),
                title: item['institutionName']?.toString() ?? 'Institution',
                subtitle:
                    '${item['duration'] ?? ''} • ${item['majorSubjects'] ?? ''}',
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildProfessionalProfile(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     const Icon(
          //       Icons.work_outline,
          //       color: Color(0xFF14507F),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Professional Profile',
          //       style: GoogleFonts.plusJakartaSans(
          //         fontSize: 18,
          //         fontWeight: FontWeight.w600,
          //         color: const Color(0xFF0F172A),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),
          _buildTextField(
            label: 'Professional Summary',
            controller: _profSummaryCtrl,
            icon: Icons.description_outlined,
            maxLines: 8,
            hint:
                'Provide a detailed overview of your professional background...',
            onChanged: (v) {
              prov.professionalProfileSummary = v;
              prov.professionalProfileDirty = true; // ✅ CORRECT
              prov.notifyListeners();
            },
          ),
          const SizedBox(height: 20),
          // const Divider(height: 1),
          // const SizedBox(height: 24),

          // ✅ NEW: Professional Record Section
          // Row(
          //   children: [
          //     const Icon(
          //       Icons.assignment_ind_outlined,
          //       color: Color(0xFF64748B),
          //       size: 20,
          //     ),
          //     const SizedBox(width: 8),
          //     Text(
          //       'Professional Record',
          //       style: GoogleFonts.plusJakartaSans(
          //         fontSize: 15,
          //         fontWeight: FontWeight.w600,
          //         color: const Color(0xFF475569),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 16),

          // Status Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14507F).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF14507F),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Service Status',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3E5C76),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE7EF)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value:
                        (prov.professionalStatus == 'serving' ||
                            prov.professionalStatus == 'retired')
                        ? prov.professionalStatus
                        : null,
                    hint: Text(
                      'Select status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    isExpanded: true,
                    items: ['serving', 'retired'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value == 'serving' ? 'Currently Serving' : 'Retired',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        prov.updateProfessionalStatus(newValue);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          if (prov.professionalStatus == 'serving') ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                final expRetCtrl = TextEditingController(
                  text: prov.expectedRetirementDate,
                );
                _selectDate(
                  context,
                  expRetCtrl,
                  initialDate: prov.expectedRetirementDate.isNotEmpty
                      ? DateTime.tryParse(prov.expectedRetirementDate)
                      : DateTime.now(),
                ).then((_) {
                  if (expRetCtrl.text.isNotEmpty) {
                    prov.updateExpectedRetirementDate(expRetCtrl.text);
                  }
                });
              },
              child: AbsorbPointer(
                child: _buildTextField(
                  label: 'Expected Retirement Date',
                  controller: TextEditingController(
                    text: prov.expectedRetirementDate,
                  ),
                  icon: Icons.calendar_today_outlined,
                  onChanged: prov.updateExpectedRetirementDate,
                ),
              ),
            ),
          ],

          if (prov.professionalStatus == 'retired') ...[
            const SizedBox(height: 16),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  final retCtrl = TextEditingController(
                    text: prov.retirementDate,
                  );
                  _selectDate(
                    context,
                    retCtrl,
                    initialDate: prov.retirementDate.isNotEmpty
                        ? DateTime.tryParse(prov.retirementDate)
                        : DateTime.now(),
                  ).then((_) {
                    if (retCtrl.text.isNotEmpty) {
                      prov.updateRetirementDate(retCtrl.text);
                    }
                  });
                },
                child: AbsorbPointer(
                  child: _buildTextField(
                    label: 'Date of Retirement',
                    controller: TextEditingController(
                      text: prov.retirementDate,
                    ),
                    icon: Icons.calendar_today_outlined,
                    onChanged: prov.updateRetirementDate,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperience(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     const Icon(
          //       Icons.flight_takeoff,
          //       color: Color(0xFF14507F),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Professional Experience',
          //       style: GoogleFonts.plusJakartaSans(
          //         fontSize: 18,
          //         fontWeight: FontWeight.w600,
          //         color: const Color(0xFF0F172A),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),
          _buildTextField(
            label: 'Organization / Unit / Squadron',
            controller: _expOrgCtrl,
            icon: Icons.business_outlined,
            hint: 'e.g., No. 9 Squadron, PAF Base Masroor',
            onChanged: (v) => prov.tempCompany = v,
          ),
          const SizedBox(height: 12),

          _isMobile
              ? Column(
                  children: [
                    _buildTextField(
                      label: 'Rank / Position',
                      controller: _expRankCtrl,
                      icon: Icons.military_tech,
                      hint: 'e.g., Squadron Leader',
                      onChanged: (v) => prov.tempRank = v,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Role / Designation',
                      controller: _expRoleCtrl,
                      icon: Icons.badge_outlined,
                      hint: 'e.g., Fighter Pilot',
                      onChanged: (v) => prov.tempRole = v,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Rank / Position',
                        controller: _expRankCtrl,
                        icon: Icons.military_tech,
                        hint: 'e.g., Squadron Leader',
                        onChanged: (v) => prov.tempRank = v,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Role / Designation',
                        controller: _expRoleCtrl,
                        icon: Icons.badge_outlined,
                        hint: 'e.g., Fighter Pilot',
                        onChanged: (v) => prov.tempRole = v,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          _isMobile
              ? Column(
                  children: [
                    _buildTextField(
                      label: 'Command / Base',
                      controller: _expCommandCtrl,
                      icon: Icons.location_city,
                      hint: 'e.g., Central Air Command',
                      onChanged: (v) => prov.tempCommand = v,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Location',
                      controller: _expLocationCtrl,
                      icon: Icons.place_outlined,
                      hint: 'e.g., Karachi, Pakistan',
                      onChanged: (v) => prov.tempLocation = v,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Command / Base',
                        controller: _expCommandCtrl,
                        icon: Icons.location_city,
                        hint: 'e.g., Central Air Command',
                        onChanged: (v) => prov.tempCommand = v,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Location',
                        controller: _expLocationCtrl,
                        icon: Icons.place_outlined,
                        hint: 'e.g., Karachi, Pakistan',
                        onChanged: (v) => prov.tempLocation = v,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          _isMobile
              ? Column(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () async {
                          await _selectMonthYear(context, _expStartDateCtrl);
                          if (_expStartDateCtrl.text.isNotEmpty) {
                            prov.tempExpStart = _expStartDateCtrl.text;
                            prov.notifyListeners();
                          }
                        },
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'Start Date',
                            controller: _expStartDateCtrl,
                            icon: Icons.calendar_today_outlined,
                            hint: 'e.g., Jan 2018',
                            onChanged: (v) => prov.tempExpStart = v,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () async {
                          await _selectMonthYear(context, _expEndDateCtrl);
                          if (_expEndDateCtrl.text.isNotEmpty) {
                            prov.tempExpEnd = _expEndDateCtrl.text;
                            prov.notifyListeners();
                          }
                        },
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'End Date (or Present)',
                            controller: _expEndDateCtrl,
                            icon: Icons.calendar_today_outlined,
                            hint: 'e.g., Dec 2022 or Present',
                            onChanged: (v) => prov.tempExpEnd = v,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Aircraft Type (if applicable)',
                      controller: _expAircraftTypeCtrl,
                      icon: Icons.flight,
                      hint: 'e.g., F-16, JF-17, C-130',
                      onChanged: (v) => prov.tempAircraftType = v,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            await _selectMonthYear(context, _expStartDateCtrl);
                            if (_expStartDateCtrl.text.isNotEmpty) {
                              prov.tempExpStart = _expStartDateCtrl.text;
                              prov.notifyListeners();
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(
                              label: 'Start Date',
                              controller: _expStartDateCtrl,
                              icon: Icons.calendar_today_outlined,
                              hint: 'e.g., Jan 2018',
                              onChanged: (v) => prov.tempExpStart = v,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            await _selectMonthYear(context, _expEndDateCtrl);
                            if (_expEndDateCtrl.text.isNotEmpty) {
                              prov.tempExpEnd = _expEndDateCtrl.text;
                              prov.notifyListeners();
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(
                              label: 'End Date (or Present)',
                              controller: _expEndDateCtrl,
                              icon: Icons.calendar_today_outlined,
                              hint: 'e.g., Dec 2022 or Present',
                              onChanged: (v) => prov.tempExpEnd = v,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Aircraft Type (if applicable)',
                        controller: _expAircraftTypeCtrl,
                        icon: Icons.flight,
                        hint: 'e.g., F-16, JF-17, C-130',
                        onChanged: (v) => prov.tempAircraftType = v,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 16),

          _buildTextField(
            label: 'Flight Hours (if applicable)',
            controller: _expFlightHoursCtrl,
            icon: Icons.access_time,
            hint: 'e.g., 1500 hours',
            onChanged: (v) => prov.tempFlightHours = v,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            label: 'Key Responsibilities, Missions & Achievements',
            controller: _expDutiesCtrl,
            icon: Icons.checklist_rounded,
            maxLines: 6,
            hint:
                'Describe operational duties, mission types, leadership roles, training conducted, awards received, and key achievements...',
            onChanged: (v) => prov.tempExpDescription = v,
          ),
          const SizedBox(height: 20),

          _brandAddButton(
            label: 'Add Experience',
            icon: Icons.add_circle_outline,
            onTap: () {
              if (prov.tempCompany.trim().isEmpty &&
                  prov.tempRole.trim().isEmpty &&
                  prov.tempExpDescription.trim().isEmpty) {
                showErrorTop(
                  context,
                  "Please fill at least organization, role, or duties",
                );
                return;
              }

              prov.addExperienceEntry(context);

              // ✅ Clear all controllers after adding
              _expOrgCtrl.clear();
              _expRoleCtrl.clear();
              _expDurationCtrl.clear();
              _expDutiesCtrl.clear();
              _expRankCtrl.clear();
              _expUnitCtrl.clear();
              _expLocationCtrl.clear();
              _expFlightHoursCtrl.clear();
              _expAircraftTypeCtrl.clear();
              _expCommandCtrl.clear();
              _expStartDateCtrl.clear();
              _expEndDateCtrl.clear();
            },
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF14507F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.attach_file,
                    color: Color(0xFF14507F), size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                'Supporting Documents (Optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3E5C76),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload certificates, commendations, or supporting documents (Max 5MB each)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          Material(
            color: const Color(0xFF14507F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _pickAndUploadExperienceDoc(prov),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _isMobile ? 12 : 16,
                  vertical: _isMobile ? 10 : 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: _isMobile ? 16 : 18,
                      color: const Color(0xFF14507F),
                    ),
                    SizedBox(width: _isMobile ? 6 : 8),
                    Text(
                      'Upload Document',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: _isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF14507F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (prov.experienceDocuments.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...prov.experienceDocuments.asMap().entries.map((e) {
              final doc = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBE3F3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Color(0xFF2178B5),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc['name']?.toString() ?? 'Document',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => prov.removeExperienceDocumentAt(e.key),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (prov.professionalExperience.isNotEmpty) ...[
            const SizedBox(height: 32),
            _brandDivider(),
            const SizedBox(height: 24),
            _sectionHeader('Saved', 'Added Experience'),
            const SizedBox(height: 16),

            ...prov.professionalExperience.asMap().entries.map((e) {
              final item = e.value;
              final organization = item['organization']?.toString() ?? '';
              final role = item['role']?.toString() ?? '';
              final duration = item['duration']?.toString() ?? '';
              final duties = item['duties']?.toString() ?? '';
              final rank = item['rank']?.toString() ?? '';
              final unit = item['unit']?.toString() ?? '';
              final location = item['location']?.toString() ?? '';
              final command = item['command']?.toString() ?? '';
              final aircraftType = item['aircraftType']?.toString() ?? '';
              final flightHours = item['flightHours']?.toString() ?? '';

              return Container(
                margin: EdgeInsets.only(bottom: _isMobile ? 12 : 16),
                padding: EdgeInsets.all(_isMobile ? 14 : 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_isMobile ? 14 : 16),
                  border: Border.all(color: const Color(0xFFDCE7EF)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B2239).withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(_isMobile ? 8 : 12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF14507F,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              _isMobile ? 8 : 10,
                            ),
                          ),
                          child: Icon(
                            Icons.flight_takeoff,
                            color: const Color(0xFF14507F),
                            size: _isMobile ? 20 : 24,
                          ),
                        ),
                        SizedBox(width: _isMobile ? 10 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (role.isNotEmpty)
                                Text(
                                  role,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: _isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              if (rank.isNotEmpty) ...[
                                SizedBox(height: _isMobile ? 2 : 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.military_tech,
                                      size: _isMobile ? 12 : 14,
                                      color: const Color(0xFF14507F),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      rank,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: _isMobile ? 11 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF14507F),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (organization.isNotEmpty) ...[
                                SizedBox(height: _isMobile ? 4 : 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_outlined,
                                      size: _isMobile ? 11 : 13,
                                      color: const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        organization,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: _isMobile ? 11 : 13,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (command.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_city,
                                      size: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      command,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place_outlined,
                                      size: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      location,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (duration.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      duration,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => prov.removeExperienceAt(e.key),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    if (aircraftType.isNotEmpty || flightHours.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            if (aircraftType.isNotEmpty) ...[
                              const Icon(
                                Icons.flight,
                                size: 16,
                                color: Color(0xFF14507F),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                aircraftType,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                            if (aircraftType.isNotEmpty &&
                                flightHours.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Container(
                                  width: 1,
                                  height: 16,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                            if (flightHours.isNotEmpty) ...[
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF14507F),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$flightHours hrs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (duties.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),
                      Text(
                        duties,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.6,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCertifications(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     const Icon(
          //       Icons.card_membership_outlined,
          //       color: Color(0xFF14507F),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Certifications',
          //       style: GoogleFonts.plusJakartaSans(
          //         fontSize: 18,
          //         fontWeight: FontWeight.w600,
          //         color: const Color(0xFF0F172A),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),
          _buildTextField(
            label: 'Certification Name',
            controller: _certNameCtrl,
            icon: Icons.verified_outlined,
            hint: 'e.g., Advanced Flight Safety Certification',
            onChanged: (v) => prov.tempCertName = v,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Issuing Organization',
            controller: _certOrgCtrl,
            icon: Icons.business_outlined,
            hint: 'e.g., Civil Aviation Authority',
            onChanged: (v) => prov.tempCertInstitution = v,
          ),
          const SizedBox(height: 20),

          _brandAddButton(
            label: 'Add Certification',
            icon: Icons.add_circle_outline,
            onTap: () {
              prov.addCertificationEntry(context);
              _certNameCtrl.clear();
              _certOrgCtrl.clear();
            },
          ),
          // ✅ NEW: Supporting Documents Section
          const SizedBox(height: 32),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF14507F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.attach_file,
                    color: Color(0xFF14507F), size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                'Supporting Documents (Optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3E5C76),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload certification copies or supporting documents (Max 5MB each)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          Material(
            color: const Color(0xFF14507F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _pickAndUploadCertificationDoc(prov),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.upload_file,
                      size: 18,
                      color: Color(0xFF14507F),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Document',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF14507F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (prov.certificationDocuments.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...prov.certificationDocuments.asMap().entries.map((e) {
              final doc = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBE3F3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Color(0xFF2178B5),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc['name']?.toString() ?? 'Document',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          prov.removeCertificationDocumentAt(e.key),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (prov.certifications.isNotEmpty) ...[
            const SizedBox(height: 32),
            _brandDivider(),
            const SizedBox(height: 24),
            _sectionHeader('Saved', 'Added Certifications'),
            const SizedBox(height: 16),

            ...prov.certifications.asMap().entries.map((e) {
              final cert = e.value;
              final organization = cert['organization'] ?? '';
              final name = cert['name'] ?? 'Certification';

              return _entryCard(
                accent: const Color(0xFF15A99C),
                icon: Icons.verified_outlined,
                onRemoveTap: () => prov.removeCertificationAt(e.key),
                title: name,
                subtitle: organization.isNotEmpty ? organization : '—',
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPublications(ProfileProvider_NEW prov) {
    return _buildListSection(
      title: 'Publications',
      icon: Icons.article_outlined,
      items: prov.publications,
      controller: _singleLineCtrl,
      hint: 'Publication title',
      onAdd: () {
        prov.addPublication(_singleLineCtrl.text);
        _singleLineCtrl.clear();
      },
      onRemove: prov.removePublicationAt,
      itemIcon: Icons.description_outlined,
    );
  }

  Widget _buildAwards(ProfileProvider_NEW prov) {
    return _buildListSection(
      title: 'Awards & Honors',
      icon: Icons.emoji_events_outlined,
      items: prov.awards,
      controller: _singleLineCtrl,
      hint: 'Award name',
      onAdd: () {
        prov.addAward(_singleLineCtrl.text);
        _singleLineCtrl.clear();
      },
      onRemove: prov.removeAwardAt,
      itemIcon: Icons.military_tech_outlined,
    );
  }

  Widget _buildReferences(ProfileProvider_NEW prov) {
    return _buildListSection(
      title: 'References',
      icon: Icons.people_outline,
      items: prov.references,
      controller: _singleLineCtrl,
      hint: 'Reference details',
      onAdd: () {
        prov.addReference(_singleLineCtrl.text);
        _singleLineCtrl.clear();
      },
      onRemove: prov.removeReferenceAt,
      itemIcon: Icons.person_outline,
    );
  }

  Widget _buildListSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required IconData itemIcon,
  }) {
    final isMobile = _isMobile;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Section', title, icon: icon),
          SizedBox(height: isMobile ? 16 : 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 12 : 13,
                      color: const Color(0xFF8AA5B5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isMobile ? 10 : 12,
                    ),
                    isDense: isMobile,
                    filled: true,
                    fillColor: const Color(0xFFF4F9FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCE7EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCE7EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF2EC4B6), width: 1.6),
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 13 : 14,
                    color: const Color(0xFF0B2239),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 11 : 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2EC4B6).withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      size: isMobile ? 16 : 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            SizedBox(height: isMobile ? 20 : 32),
            _brandDivider(),
            SizedBox(height: isMobile ? 16 : 24),
            _sectionHeader('Saved', 'Added $title'),
            SizedBox(height: isMobile ? 12 : 16),
            ...items.asMap().entries.map((e) {
              return _entryCard(
                accent: const Color(0xFF14507F),
                icon: itemIcon,
                onRemoveTap: () => onRemove(e.key),
                title: e.value,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDocuments(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                color: Color(0xFF14507F),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Documents',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Material(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _pickAndUploadDocument(prov),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Document',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (prov.documents.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Text(
              'Uploaded Documents',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ...prov.documents.asMap().entries.map((e) {
              final item = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name']?.toString() ?? 'Document',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['contentType']?.toString() ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        prov.removeDocumentAt(e.key);
                        prov.saveDocumentsSection(context);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ProfileProvider_NEW prov) {
    // ✅ NEW: Check if current section has unsaved changes
    bool isDirty = false;
    switch (_currentStep) {
      case 0:
        isDirty = prov.personalDirty;
        break;
      case 1:
        isDirty = prov.educationDirty;
        break;
      case 2:
        isDirty = prov.professionalProfileDirty;
        break;
      case 3:
        isDirty = false; // Questionnaire is read-only
        break;
      case 4:
        isDirty = prov.experienceDirty;
        break;
      case 5:
        isDirty = prov.certificationsDirty;
        break;
      case 6:
        isDirty = prov.publicationsDirty;
        break;
      case 7:
        isDirty = prov.awardsDirty;
        break;
      case 8:
        isDirty = prov.referencesDirty;
        break;
    }

    final isMobile = _isMobile;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 15 : 16,
          isMobile ? 16 : 24,
          isMobile ? 10 : 24, // Extra bottom padding to clear Android buttons
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,

          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _currentStep--);
                    _scrollToCurrentStep();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 24,
                      vertical: isMobile ? 9 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF14507F),
                        width: 1.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left,
                          size: isMobile ? 16 : 20,
                          color: const Color(0xFF14507F),
                        ),
                        SizedBox(width: isMobile ? 4 : 8),
                        Text(
                          isMobile ? 'Back' : 'Previous',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF14507F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const SizedBox(),
            Row(
              children: [
                if (_currentStep != 3)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () async {
                      await _saveCurrentSection(prov);
                      if (mounted) setState(() {});
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 24,
                        vertical: isMobile ? 9 : 14,
                      ),
                      decoration: BoxDecoration(
                        // Dirty -> warm (amber→coral) to keep the unsaved
                        // signal; saved -> brand teal→navy gradient.
                        gradient: LinearGradient(
                          colors: isDirty
                              ? const [Color(0xFFFFB020), Color(0xFFFF7A59)]
                              : const [Color(0xFF2EC4B6), Color(0xFF14507F)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isDirty
                                    ? const Color(0xFFFF7A59)
                                    : const Color(0xFF2EC4B6))
                                .withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDirty ? Icons.warning_amber_rounded : Icons.check,
                            size: isMobile ? 16 : 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: isMobile ? 4 : 8),
                          Text(
                            isDirty
                                ? (isMobile ? 'Save' : 'Save Changes')
                                : 'Saved',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 11 : 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_currentStep < _stepTitles.length - 1) ...[
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () async {
                        // ✅ NEW: Check if there are unsaved changes
                        if (isDirty) {
                          final shouldProceed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Unsaved Changes',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'You have unsaved changes. Do you want to save them before proceeding?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    'Discard',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFEF4444),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context, true);
                                    await _saveCurrentSection(prov);
                                    // ✅ Wait for save to complete before moving to next step
                                    Future.delayed(
                                      const Duration(milliseconds: 300),
                                      () {
                                        if (mounted) {
                                          setState(() => _currentStep++);
                                          _scrollToCurrentStep();
                                        }
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                  child: Text(
                                    'Save & Continue',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldProceed == false) {
                            setState(() => _currentStep++);
                            _scrollToCurrentStep();
                          }
                        } else {
                          setState(() => _currentStep++);
                          _scrollToCurrentStep();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 14 : 24,
                          vertical: isMobile ? 9 : 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF14507F).withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Next',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isMobile ? 11 : 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: isMobile ? 4 : 8),
                            Icon(
                              Icons.chevron_right,
                              size: isMobile ? 16 : 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (isMobile) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showSidebarSheet(prov),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF14507F),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              size: 16,
                              color: Color(0xFF14507F),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stats',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF14507F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCurrentSection(ProfileProvider_NEW prov) async {
    switch (_currentStep) {
      case 0:
        await prov.savePersonalSection(context);
        break;
      case 1:
        await prov.saveEducationSection(context);
        break;
      case 2:
        await prov.saveProfessionalProfileSection(context);
        break;
      case 3:
        break; // Questionnaire is read-only — nothing to save
      case 4:
        await prov.saveExperienceSection(context);
        break;
      case 5:
        await prov.saveCertificationsSection(context);
        break;
      case 6:
        await prov.savePublicationsSection(context);
        break;
      case 7:
        await prov.saveAwardsSection(context);
        break;
      case 8:
        await prov.saveReferencesSection(context);
        break;
    }

    // ✅ Force UI update after save
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    final isMobile = _isMobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 4 : 5),
              decoration: BoxDecoration(
                color: const Color(0xFF14507F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF14507F),
                size: isMobile ? 12 : 14,
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3E5C76),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 5 : 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 13,
              color: const Color(0xFF8AA5B5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 13,
            ),
            isDense: isMobile,
            filled: true,
            fillColor: const Color(0xFFF4F9FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCE7EF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCE7EF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2EC4B6),
                width: 1.6,
              ),
            ),
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0B2239),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _pickAndUploadProfilePic(ProfileProvider_NEW prov) async {
    Uint8List? bytes;
    String fileName = '';

    if (kIsWeb) {
      final res = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.image,
      );
      if (res == null) return;
      final file = res.files.first;
      bytes = file.bytes;
      fileName = file.name;
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      bytes = await picked.readAsBytes();
      fileName = picked.name;
    }

    if (bytes == null) return;
    final mimeType =
        lookupMimeType(fileName, headerBytes: bytes) ?? "image/jpeg";
    await prov.uploadProfilePicture(bytes, fileName, mimeType: mimeType);
  }

  Future<void> _pickAndUploadDocument(ProfileProvider_NEW prov) async {
    final res = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (res == null) return;

    final file = res.files.first;
    Uint8List? bytes;

    if (kIsWeb) {
      bytes = file.bytes;
    } else {
      if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
    }

    if (bytes == null) return;

    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    final entry = await prov.uploadDocument(
      bytes,
      file.name,
      mimeType: mimeType,
    );
    if (entry != null) {
      showSuccessLight(context, "Document Upload Successfully");
    } else {
      showErrorTop(context, "Failed to Upload Document");
    }
  }

  // ✅ NEW: Experience document picker
  Future<void> _pickAndUploadExperienceDoc(ProfileProvider_NEW prov) async {
    final res = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (res == null) return;

    final file = res.files.first;
    Uint8List? bytes;

    if (kIsWeb) {
      bytes = file.bytes;
    } else {
      if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
    }

    if (bytes == null) return;

    // Check 5MB limit
    if (bytes.length > 5 * 1024 * 1024) {
      showErrorTop(context, "File Size Limit 5MB Exceeded");
      return;
    }

    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    final entry = await prov.uploadExperienceDocument(
      bytes,
      file.name,
      mimeType: mimeType,
    );

    if (entry != null) {
      showSuccessLight(context, "Experience Document Attached");
    } else {
      showErrorTop(context, "Failed to attach Document");
    }
  }

  // ✅ NEW: Certification document picker
  Future<void> _pickAndUploadCertificationDoc(ProfileProvider_NEW prov) async {
    final res = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (res == null) return;

    final file = res.files.first;
    Uint8List? bytes;

    if (kIsWeb) {
      bytes = file.bytes;
    } else {
      if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
    }

    if (bytes == null) return;

    // Check 5MB limit
    if (bytes.length > 5 * 1024 * 1024) {
      showErrorTop(context, "File Size limit 5MB Exceeded");
      return;
    }

    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    final entry = await prov.uploadCertificationDocument(
      Uint8List.fromList(bytes),
      file.name,
      mimeType: mimeType,
    );

    if (entry != null) {
      showSuccessLight(context, "Certification Document Attached");
    } else {
      showErrorTop(context, "Failed To Attached Document");
    }
  }
}

void showTopNotification(
  BuildContext context,
  String message, {
  required Color backgroundColor,
  required IconData icon,
}) {
  final overlay = Overlay.of(context);

  final isMobile = MediaQuery.sizeOf(context).width < 768;

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 30,
      left: isMobile ? 20 : 400,
      right: isMobile ? 20 : 380,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 5), () {
    overlayEntry.remove();
  });
}

void showSuccessLight(BuildContext context, String message) {
  showTopNotification(
    context,
    message,
    backgroundColor: const Color(0xFF10B981),
    icon: Icons.check_circle_outline,
  );
}

void showErrorTop(BuildContext context, String message) {
  showTopNotification(
    context,
    message,
    backgroundColor: const Color(0xFF7F1D1D),
    icon: Icons.error,
  );
}
