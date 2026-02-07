// js_profile_screen.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../Recruiter/LIst_of_Applicants.dart';
import '../JS_Top_Bar.dart';
import 'JS_Profile_Provider.dart';
import 'JS_Profile_Sidebar.dart';

class ProfileScreen_NEW extends StatefulWidget {
  const ProfileScreen_NEW({super.key});

  @override
  State<ProfileScreen_NEW> createState() => _JSProfileScreenState();
}

class _JSProfileScreenState extends State<ProfileScreen_NEW>
    with TickerProviderStateMixin {
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
  final TextEditingController _durationCtrl = TextEditingController();
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
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
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
        print(
          '[_selectDate] Date selected: $dateString, calling onDateSelected callback',
        );
        onDateSelected(dateString);
      } else {
        print('[_selectDate] WARNING: Date selected but no callback provided!');
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
                style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  _getMonthName(month),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
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
                    style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.text =
                        '${_getMonthName(selectedMonth)} $selectedYear';
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            );
          },
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
    'Experience',
    'Certifications',
    'Publications',
    'Awards',
    'References',
    // 'Documents'
  ];

  final List<IconData> _stepIcons = [
    FontAwesomeIcons.user,
    FontAwesomeIcons.graduationCap,
    FontAwesomeIcons.briefcase,
    FontAwesomeIcons.clock,
    FontAwesomeIcons.certificate,
    FontAwesomeIcons.fileAlt,
    FontAwesomeIcons.award,
    FontAwesomeIcons.users,
    // FontAwesomeIcons.folder,
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
    _durationCtrl.dispose();
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
        final screenWidth = MediaQuery.of(context).size.width;
        final itemWidth = 180.0;
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

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: Scaffold(
        body: Row(
          children: [
            JobSeekerSidebar(activeIndex: 1),
            Expanded(
              child: FadeTransition(
                opacity: _animController,
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Consumer<ProfileProvider_NEW>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
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

  Widget _buildTopBar() {
    const Color kPrimaryBlue = Color(0xFF1E40AF);
    const Color kTextPrimary = Color(0xFF0F172A);
    const Color kTextSecondary = Color(0xFF475569);
    const Color kBorderLight = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Left Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_add_alt_outlined,
              size: 24,
              color: kPrimaryBlue,
            ),
          ),

          const SizedBox(width: 14),

          // Title & Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  height: 1.2,
                ),
              ),
              Text(
                'One Click Profile Analyzer & CV Builder',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: kTextSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ✅ Progress Indicator on Right
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Step ${_currentStep + 1} of ${_stepTitles.length}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 100,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentStep + 1) / _stepTitles.length,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ProfileProvider_NEW prov) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStepIndicators(),
          const SizedBox(height: 24),
          Expanded(
            child: RepaintBoundary( child: Container(
              key: ValueKey<int>(_currentStep),
              child:


              _buildCurrentStepContent(prov),
            ),
              // child: AnimatedSwitcher(
              //   duration: const Duration(milliseconds: 550),
              //   switchInCurve: Curves.easeInExpo,
              //   switchOutCurve: Curves.easeInOutCubicEmphasized,
              //   transitionBuilder: (child, animation) {
              //     return FadeTransition(opacity: animation, child: child);
              //   },
              //
              // ),
            ),
          ),
          // const SizedBox(height: 20),
          _buildNavigationButtons(prov),
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        controller: _stepScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _stepTitles.length,
        itemBuilder: (context, index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _currentStep = index);
                  // ✅ REMOVED: Animation reset causes glitch
                  // _animController.reset();
                  // _animController.forward();
                  _scrollToCurrentStep();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF6366F1).withOpacity(0.08)
                        : (isCompleted
                              ? const Color(0xFF10B981).withOpacity(0.08)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF6366F1).withOpacity(0.3)
                          : (isCompleted
                                ? const Color(0xFF10B981).withOpacity(0.3)
                                : Colors.grey.shade200),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : _stepIcons[index],
                        color: isActive
                            ? const Color(0xFF6366F1)
                            : (isCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF64748B)),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _stepTitles[index],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF0F172A)
                              : (isCompleted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index < _stepTitles.length - 1)
                Container(
                  width: 24,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: index < _currentStep
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          );
        },
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
        return _buildExperience(prov);
      case 4:
        return _buildCertifications(prov);
      case 5:
        return _buildPublications(prov);
      case 6:
        return _buildAwards(prov);
      case 7:
        return _buildReferences(prov);
      // case 8:
      //   return _buildDocuments(prov);
      default:
        return const SizedBox();
    }
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
          //       color: const Color(0xFF6366F1),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Personal Information',
          //       style: GoogleFonts.poppins(
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
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.indigo),
                          gradient: prov.profilePicUrl.isEmpty
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                )
                              : null,
                          image: prov.profilePicUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(prov.profilePicUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: prov.profilePicUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Profile Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
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
          Row(
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
          const SizedBox(height: 20),
          Row(
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      print('[DOB] Date picker opened');
                      _selectDate(
                        context,
                        _dobCtrl,
                        initialDate: _dobCtrl.text.isNotEmpty
                            ? DateTime.tryParse(_dobCtrl.text)
                            : DateTime(1990),
                        onDateSelected: (dateString) {
                          print('[DOB] Date selected from picker: $dateString');
                          prov.updateDob(dateString);
                          print(
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
                          print(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.interests_outlined,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Skills',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prov.skillsList.asMap().entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => prov.removeSkillAt(e.key),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF6366F1),
                      size: 16,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: prov.skillController,
                decoration: InputDecoration(
                  hintText: 'Add a skill',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => prov.addSkillEntry(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
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
          //       color: const Color(0xFF6366F1),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Education Background',
          //       style: GoogleFonts.poppins(
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Duration',
                  controller: _durationCtrl,
                  icon: Icons.access_time,
                  hint: 'e.g. 2016 - 2020',
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
          Material(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                prov.tempSchool = _institutionCtrl.text;
                prov.tempEduStart = _durationCtrl.text;
                prov.tempFieldOfStudy = _majorCtrl.text;
                prov.tempDegree = _marksCtrl.text;
                prov.addEducationEntry(context);
                _institutionCtrl.clear();
                _durationCtrl.clear();
                _majorCtrl.clear();
                _marksCtrl.clear();
              },
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
                      Icons.add_circle_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Education',
                      style: GoogleFonts.poppins(
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
          if (prov.educationalProfile.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Text(
              'Added Education',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ...prov.educationalProfile.asMap().entries.map((e) {
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
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['institutionName']?.toString() ??
                                'Institution',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['duration'] ?? ''} • ${item['majorSubjects'] ?? ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => prov.removeEducationAt(e.key),
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

  Widget _buildProfessionalProfile(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     const Icon(
          //       Icons.work_outline,
          //       color: Color(0xFF6366F1),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Professional Profile',
          //       style: GoogleFonts.poppins(
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
          //       style: GoogleFonts.poppins(
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
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Service Status',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: prov.professionalStatus.isEmpty
                        ? null
                        : prov.professionalStatus,
                    hint: Text(
                      'Select status',
                      style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(fontSize: 14),
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
          //       color: Color(0xFF6366F1),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Professional Experience',
          //       style: GoogleFonts.poppins(
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
          const SizedBox(height: 16),

          Row(
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
          const SizedBox(height: 16),

          Row(
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
          const SizedBox(height: 16),

          Row(
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

          Material(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
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
                      Icons.add_circle_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Experience',
                      style: GoogleFonts.poppins(
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

          // Rest of the code remains the same (documents section and display section)
          // const SizedBox(height: 32),
          // const Divider(height: 1),
          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.attach_file, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 8),
              Text(
                'Supporting Documents (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload certificates, commendations, or supporting documents (Max 5MB each)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          Material(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _pickAndUploadExperienceDoc(prov),
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
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Document',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1),
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
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Color(0xFF0284C7),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc['name']?.toString() ?? 'Document',
                        style: GoogleFonts.poppins(
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
            const Divider(height: 1),
            const SizedBox(height: 24),
            Text(
              'Added Experience',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
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
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.flight_takeoff,
                            color: Color(0xFF6366F1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (role.isNotEmpty)
                                Text(
                                  role,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              if (rank.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.military_tech,
                                      size: 14,
                                      color: Color(0xFF6366F1),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      rank,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF6366F1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (organization.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business_outlined,
                                      size: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        organization,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
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
                                      style: GoogleFonts.poppins(
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
                                      style: GoogleFonts.poppins(
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
                                      style: GoogleFonts.poppins(
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
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                aircraftType,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$flightHours hrs',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                        style: GoogleFonts.poppins(
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
          //       color: Color(0xFF6366F1),
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'Certifications',
          //       style: GoogleFonts.poppins(
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

          Material(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                prov.addCertificationEntry(context);
                _certNameCtrl.clear();
                _certOrgCtrl.clear();
              },
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
                      Icons.add_circle_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Certification',
                      style: GoogleFonts.poppins(
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
          // ✅ NEW: Supporting Documents Section
          const SizedBox(height: 32),

          // const Divider(height: 1),
          // const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.attach_file, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 8),
              Text(
                'Supporting Documents (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload certification copies or supporting documents (Max 5MB each)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          Material(
            color: const Color(0xFF6366F1).withOpacity(0.1),
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
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Document',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1),
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
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Color(0xFF0284C7),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc['name']?.toString() ?? 'Document',
                        style: GoogleFonts.poppins(
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
            const Divider(height: 1),
            const SizedBox(height: 24),
            Text(
              'Added Certifications',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            ...prov.certifications.asMap().entries.map((e) {
              final cert = e.value;
              final organization = cert['organization'] ?? '';
              final name = cert['name'] ?? 'Certification';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (organization.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.business_outlined,
                                  size: 12,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  organization,
                                  style: GoogleFonts.poppins(
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
                      onPressed: () => prov.removeCertificationAt(e.key),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.add, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Text(
              'Added $title',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((e) {
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
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        itemIcon,
                        color: const Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemove(e.key),
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

  Widget _buildDocuments(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Documents',
                style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
                        color: const Color(0xFFEF4444).withOpacity(0.1),
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
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['contentType']?.toString() ?? '',
                            style: GoogleFonts.poppins(
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
        isDirty = prov.experienceDirty;
        break;
      case 4:
        isDirty = prov.certificationsDirty;
        break;
      case 5:
        isDirty = prov.publicationsDirty;
        break;
      case 6:
        isDirty = prov.awardsDirty;
        break;
      case 7:
        isDirty = prov.referencesDirty;
        break;
    }

    return Row(
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Previous',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
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
            Material(
              // ✅ CHANGED: Red if dirty, green if clean
              color: isDirty
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () async {
                  await _saveCurrentSection(prov);
                  if (mounted) setState(() {});
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDirty ? Icons.warning_amber_rounded : Icons.check,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDirty ? 'Save Changes' : 'Saved',
                        style: GoogleFonts.poppins(
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
            if (_currentStep < _stepTitles.length - 1) ...[
              const SizedBox(width: 12),
              Material(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
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
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            'You have unsaved changes. Do you want to save them before proceeding?',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Discard',
                                style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Colors.white,
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
        await prov.saveExperienceSection(context);
        break;
      case 4:
        await prov.saveCertificationsSection(context);
        break;
      case 5:
        await prov.savePublicationsSection(context);
        break;
      case 6:
        await prov.saveAwardsSection(context);
        break;
      case 7:
        await prov.saveReferencesSection(context);
        break;
      case 8:
        await prov.saveDocumentsSection(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 1.5,
              ),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF0F172A),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _pickAndUploadProfilePic(ProfileProvider_NEW prov) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.image,
    );
    if (res == null) return;

    final file = res.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    await prov.uploadProfilePicture(
      Uint8List.fromList(bytes),
      file.name,
      mimeType: mimeType,
    );
  }

  Future<void> _pickAndUploadDocument(ProfileProvider_NEW prov) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (res == null) return;

    final file = res.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    final entry = await prov.uploadDocument(
      Uint8List.fromList(bytes),
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
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (res == null) return;

    final file = res.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    // Check 5MB limit
    if (bytes.length > 5 * 1024 * 1024) {
      showErrorTop(context, "FIle Size Limit 5Mb Exceed");
      return;
    }

    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    final entry = await prov.uploadExperienceDocument(
      Uint8List.fromList(bytes),
      file.name,
      mimeType: mimeType,
    );

    if (entry != null) {
      showSuccessLight(context, "Experience Document Attached");
    } else {
      showErrorTop(context, "Failed to attached Document");
    }
  }

  // ✅ NEW: Certification document picker
  Future<void> _pickAndUploadCertificationDoc(ProfileProvider_NEW prov) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (res == null) return;

    final file = res.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    // Check 5MB limit
    if (bytes.length > 5 * 1024 * 1024) {
      showErrorTop(context, "FIle Size limit 5Mb Exceed");

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

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 30,
      left: 400,
      right: 380,
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
                color: Colors.black.withOpacity(0.25),
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
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
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
