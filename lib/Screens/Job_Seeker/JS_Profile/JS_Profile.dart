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

class _JSProfileScreenState extends State<ProfileScreen_NEW> with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final ScrollController _stepScrollController = ScrollController();

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
  final TextEditingController _profSummaryCtrl = TextEditingController();

  bool _didLoad = false;

  final List<String> _stepTitles = [
    'Personal Info',
    'Education',
    'Professional Profile',
    'Experience',
    'Certifications',
    'Publications',
    'Awards',
    'References',
    'Documents'
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
    FontAwesomeIcons.folder,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
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
    super.dispose();
  }

  void _scrollToCurrentStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_stepScrollController.hasClients) {
        final screenWidth = MediaQuery.of(context).size.width;
        final itemWidth = 180.0;
        final targetOffset = (_currentStep * itemWidth) - (screenWidth / 4);
        _stepScrollController.animateTo(
          targetOffset.clamp(0.0, _stepScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

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
      backgroundColor: const Color(0xFFF9FAFB),
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
                    left: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(-2, 0),
                    ),
                  ],
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
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Complete Your Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_currentStep),
                child: _buildCurrentStepContent(prov),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                  _animController.reset();
                  _animController.forward();
                  _scrollToCurrentStep();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF6366F1).withOpacity(0.08)
                        : (isCompleted ? const Color(0xFF10B981).withOpacity(0.08) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF6366F1).withOpacity(0.3)
                          : (isCompleted ? const Color(0xFF10B981).withOpacity(0.3) : Colors.grey.shade200),
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
                            : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _stepTitles[index],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF0F172A)
                              : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF475569)),
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
                    color: index < _currentStep ? const Color(0xFF10B981) : Colors.grey.shade200,
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
      case 8:
        return _buildDocuments(prov);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalInfo(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              Text(
                'Personal Information',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: prov.profilePicUrl.isEmpty
                          ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadProfilePic(prov),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
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
                child: _buildTextField(
                  label: 'Date of Birth (YYYY-MM-DD)',
                  controller: _dobCtrl,
                  icon: Icons.calendar_today_outlined,
                  onChanged: prov.updateDob,
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
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Professional Summary',
            controller: _personalSummaryCtrl,
            icon: Icons.description_outlined,
            maxLines: 5,
            hint: 'Provide a brief overview of yourself...',
            onChanged: prov.updatePersonalSummary,
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
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
            const Icon(Icons.interests_outlined, color: Color(0xFF6366F1), size: 20),
            const SizedBox(width: 8),
            Text(
              'Skills',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
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
                    child: const Icon(Icons.close, color: Color(0xFF6366F1), size: 16),
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
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
          Row(
            children: [
              Icon(Icons.school_outlined, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              Text(
                'Education Background',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Add Education',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
                      child: const Icon(Icons.school_outlined, color: Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['institutionName']?.toString() ?? 'Institution',
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
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
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
          Row(
            children: [
              Icon(Icons.work_outline, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              Text(
                'Professional Profile',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Professional Summary',
            controller: _profSummaryCtrl,
            icon: Icons.description_outlined,
            maxLines: 8,
            hint: 'Provide a detailed overview of your professional background...',
            onChanged: (v) {
              prov.professionalProfileSummary = v;
              prov.markPersonalDirty();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExperience(ProfileProvider_NEW prov) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              Text(
                'Professional Experience',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Experience Details',
            controller: _experienceTextCtrl,
            icon: Icons.work_outline,
            maxLines: 5,
            hint: 'Job title, Company, Duration, Key responsibilities...',
          ),
          const SizedBox(height: 20),
          Material(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                prov.tempCompany = '';
                prov.tempRole = '';
                prov.tempExpStart = '';
                prov.tempExpEnd = '';
                prov.tempExpDescription = _experienceTextCtrl.text.trim();
                prov.addExperienceEntry(context);
                _experienceTextCtrl.clear();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Add Experience',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                      child: const Icon(Icons.work_outline, color: Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['text']?.toString() ?? 'Experience',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => prov.removeExperienceAt(e.key),
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
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

  Widget _buildCertifications(ProfileProvider_NEW prov) {
    return _buildListSection(
      title: 'Certifications',
      icon: Icons.card_membership_outlined,
      items: prov.certifications,
      controller: _singleLineCtrl,
      hint: 'Certification name',
      onAdd: () {
        prov.tempCertName = _singleLineCtrl.text.trim();
        prov.addCertificationEntry(context);
        _singleLineCtrl.clear();
      },
      onRemove: prov.removeCertificationAt,
      itemIcon: Icons.verified_outlined,
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
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                      child: Icon(itemIcon, color: const Color(0xFF6366F1), size: 20),
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
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
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
              Icon(Icons.folder_outlined, color: const Color(0xFF6366F1), size: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Document',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
                      child: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFFEF4444), size: 20),
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
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _currentStep--);
                _animController.reset();
                _animController.forward();
                _scrollToCurrentStep();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, size: 20, color: Color(0xFF475569)),
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
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _saveCurrentSection(prov),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Save Section',
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
                  onTap: () {
                    setState(() => _currentStep++);
                    _animController.reset();
                    _animController.forward();
                    _scrollToCurrentStep();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                        const Icon(Icons.chevron_right, size: 20, color: Colors.white),
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

  void _saveCurrentSection(ProfileProvider_NEW prov) {
    switch (_currentStep) {
      case 0:
        prov.savePersonalSection(context);
        break;
      case 1:
        prov.saveEducationSection(context);
        break;
      case 2:
        prov.saveProfessionalProfileSection(context);
        break;
      case 3:
        prov.saveExperienceSection(context);
        break;
      case 4:
        prov.saveCertificationsSection(context);
        break;
      case 5:
        prov.savePublicationsSection(context);
        break;
      case 6:
        prov.saveAwardsSection(context);
        break;
      case 7:
        prov.saveReferencesSection(context);
        break;
      case 8:
        prov.saveDocumentsSection(context);
        break;
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
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
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
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0F172A)),
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
    await prov.uploadProfilePicture(Uint8List.fromList(bytes), file.name, mimeType: mimeType);
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
    final entry = await prov.uploadDocument(Uint8List.fromList(bytes), file.name, mimeType: mimeType);
    if (entry != null) {
      _showWebNotification(context, 'Document uploaded successfully', isSuccess: true);
    } else {
      _showWebNotification(context, 'Failed to upload document', isSuccess: false);
    }
  }

  void _showWebNotification(BuildContext context, String message, {required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSuccess ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isSuccess ? 'Success' : 'Error',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}