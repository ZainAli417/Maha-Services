import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'Recruiter_provider_Job_listing.dart';

class PostJobDialog extends StatefulWidget {
  const PostJobDialog({super.key});

  @override
  _PostJobDialogState createState() => _PostJobDialogState();
}

class _PostJobDialogState extends State<PostJobDialog> {
  final _formKey = GlobalKey<FormState>();
  static const Color primary = Color(0xFF6366F1); // Air Force Blue
  static const Color secondary = Color(0xFF87CEEB); // Sky Blue
  static const Color white = Color(0xFFFAFAFA);
  static const Color paleWhite = Color(0xFFF5F5F5);
  static Color primaryLight = primary.withOpacity(0.2);
  static Color primaryDark = primary.withOpacity(0.8);

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
  Widget build(BuildContext context) {
    return Consumer<job_listing_provider>( // Wrap with Consumer
        builder: (context, provider, child) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                              Icons.flight_rounded, color: primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Air Force Job Posting',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Post aviation and support positions for Air Force personnel',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionCard(
                              title: 'Unit & Position Information',
                              icon: Icons.military_tech_rounded,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLogoUploader(provider),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildTextField(
                                            label: 'Position Title',
                                            initialValue: provider.tempTitle,
                                            onChanged: provider.updateTempTitle,
                                            validator: (v) =>
                                            v!.trim().isEmpty
                                                ? 'Required'
                                                : null,
                                            icon: Icons.work_outline,
                                            hintText: 'e.g., Aircraft Maintenance Technician, Pilot, Air Traffic Controller',
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildTextField(
                                                  label: 'Air Force Unit/Base',
                                                  initialValue: provider
                                                      .tempCompany ?? '',
                                                  onChanged: provider
                                                      .updateTempCompany,
                                                  validator: (v) =>
                                                  v!.trim().isEmpty
                                                      ? 'Required'
                                                      : null,
                                                  icon: Icons
                                                      .location_city_rounded,
                                                  hintText: 'e.g., 15th Wing, Edwards AFB',
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildDropdownField(
                                                  label: 'Department/Squadron',
                                                  value: provider
                                                      .tempDepartment ??
                                                      departmentOptions.first,
                                                  items: departmentOptions,
                                                  onChanged: (val) =>
                                                      provider
                                                          .updateTempDepartment(
                                                          val!),
                                                  icon: Icons
                                                      .group_work_outlined,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSectionCard(
                              title: 'Position Description & Requirements',
                              icon: Icons.description_outlined,
                              children: [
                                _buildTextField(
                                  label: 'Position Description',
                                  initialValue: provider.tempDescription,
                                  onChanged: provider.updateTempDescription,
                                  validator: (v) =>
                                  v!.trim().isEmpty ? 'Required' : null,
                                  maxLines: 4,
                                  icon: Icons.edit_note_rounded,
                                  hintText: 'Describe the role, mission support requirements, and operational responsibilities',
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'Primary Duties & Responsibilities',
                                  initialValue: provider.tempResponsibilities ??
                                      '',
                                  onChanged: provider
                                      .updateTempResponsibilities,
                                  validator: (v) =>
                                  v!.trim().isEmpty ? 'Required' : null,
                                  maxLines: 3,
                                  icon: Icons.checklist_rounded,
                                  hintText: 'List key operational duties, maintenance tasks, or administrative responsibilities',
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'Required Qualifications & Training',
                                  initialValue: provider.tempQualifications ??
                                      '',
                                  onChanged: provider.updateTempQualifications,
                                  validator: (v) =>
                                  v!.trim().isEmpty ? 'Required' : null,
                                  maxLines: 3,
                                  icon: Icons.school_outlined,
                                  hintText: 'Military training, certifications, technical schools, or civilian education required',
                                ),
                              ],
                            ),




                            const SizedBox(height: 16),
                            _buildSectionCard(
                              title: 'Compensation & Pay Information',
                              icon: Icons.attach_money_rounded,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Compensation Type',
                                        value: provider.tempSalaryType ??
                                            salaryTypeOptions.first,
                                        items: salaryTypeOptions,
                                        onChanged: (val) =>
                                            provider.updateTempSalaryType(val!),
                                        icon: Icons.payments_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Salary Range',
                                        initialValue: provider.tempSalary ?? '',
                                        onChanged: provider.updateTempSalary,
                                        validator: (v) =>
                                        v!.trim().isEmpty ? 'Required' : null,
                                        icon: Icons.monetization_on_outlined,
                                        hintText: 'e.g., \$45,000 - \$65,000 or E-5 Base Pay + BAH',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'Additional Pay Details',
                                  initialValue: provider.tempPayDetails ?? '',
                                  onChanged: provider.updateTempPayDetails,
                                  maxLines: 2,
                                  icon: Icons.info_outline_rounded,
                                  hintText: 'Special pay, hazard pay, flight pay, bonuses, or allowances included',
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center, // ensures middle alignment
                              children: [
                                // ---------------- DEADLINE PICKER ----------------
                                Expanded(
                                  flex: 1,
                                  child: FormField<String>(
                                    initialValue: provider.tempDeadline,
                                    validator: (v) =>
                                    provider.tempDeadline.isEmpty ? 'Deadline is required' : null,
                                    builder: (state) {
                                      String displayText =
                                      _formatDeadlineForDisplay(provider.tempDeadline);
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Application Deadline',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          GestureDetector(
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
                                              );

                                              if (picked != null) {
                                                provider.updateTempDeadline(picked.toIso8601String());
                                                state.didChange(provider.tempDeadline);
                                              }
                                            },
                                            child: Container(
                                              height: 48, // 👈 fixed height to match TextFormField
                                              padding:
                                              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).cardColor,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.grey.withOpacity(0.25)),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.calendar_today_outlined, size: 18),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      displayText.isEmpty
                                                          ? 'Select deadline'
                                                          : displayText,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13.5,
                                                        color: displayText.isEmpty
                                                            ? Colors.grey
                                                            : Colors.black87,
                                                        fontWeight: displayText.isEmpty
                                                            ? FontWeight.w400
                                                            : FontWeight.w500,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (provider.tempDeadline.isNotEmpty)
                                                    InkWell(
                                                      borderRadius: BorderRadius.circular(8),
                                                      onTap: () {
                                                        provider.updateTempDeadline('');
                                                        state.didChange(provider.tempDeadline);
                                                      },
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(6.0),
                                                        child: Icon(Icons.clear, size: 16),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (state.hasError)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                                              child: Text(
                                                state.errorText ?? '',
                                                style: GoogleFonts.poppins(
                                                  color: Theme.of(context).colorScheme.error,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // ---------------- CONTACT EMAIL FIELD ----------------
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 76, // 👈 matches total column height (label + input)
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contact Email',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          height: 48, // 👈 same as deadline container
                                          child: TextFormField(
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
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                              hintText: 'e.g., hr@airforce.mil',
                                              hintStyle: GoogleFonts.poppins(
                                                fontSize: 13.5,
                                                color: Colors.grey,
                                              ),
                                              contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide:
                                                BorderSide(color: Colors.grey.withOpacity(0.25)),
                                              ),
                                            ),
                                            style: GoogleFonts.poppins(fontSize: 13.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),


                            const SizedBox(height: 16),
                            _buildSectionCard(
                              title: 'Rank & Security Requirements',
                              icon: Icons.security_rounded,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Minimum Rank Required',
                                        value: provider.tempNature ??
                                            rankRequirements.first,
                                        items: rankRequirements,
                                        onChanged: (val) =>
                                            provider.updateTempNature(val!),
                                        icon: Icons.stars_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Security Clearance',
                                        value: provider.tempExperience ??
                                            securityClearanceOptions.first,
                                        items: securityClearanceOptions,
                                        onChanged: (val) =>
                                            provider.updateTempExperience(val!),
                                        icon: Icons.verified_user_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Years of Service Required',
                                        initialValue: provider.tempPay ?? '',
                                        onChanged: provider.updateTempPay,
                                        validator: (v) =>
                                        v!.trim().isEmpty ? 'Required' : null,
                                        icon: Icons.timeline_rounded,
                                        hintText: 'e.g., 2-5 years, Entry Level, 10+ years',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Duty Location',
                                        initialValue: provider.tempLocation ??
                                            '',
                                        onChanged: provider.updateTempLocation,
                                        validator: (v) =>
                                        v!.trim().isEmpty ? 'Required' : null,
                                        icon: Icons.location_on_outlined,
                                        hintText: 'e.g., Edwards AFB, CA or Worldwide Assignment',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSectionCard(
                              title: 'Duty Type & Required Skills',
                              icon: Icons.precision_manufacturing_rounded,
                              children: [
                                _buildPillSelector(
                                  title: 'Duty Assignment Type',
                                  selectedItems: provider.tempWorkModes,
                                  availableItems: workModeOptions,
                                  color: primary,
                                  onToggle: (item) {
                                    print(
                                        'Work mode toggle called: $item'); // Debug line
                                    provider.toggleWorkMode(item);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildPillSelector(
                                  title: 'Required Technical Skills',
                                  selectedItems: provider.tempSkills,
                                  availableItems: skillOptions,
                                  color: const Color(0xFF228B22),
                                  onToggle: (item) {
                                    print(
                                        'Skill toggle called: $item'); // Debug line
                                    provider.toggleSkill(item);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSectionCard(
                              title: 'Military Benefits & Incentives',
                              icon: Icons.card_giftcard_rounded,
                              children: [
                                _buildPillSelector(
                                  title: 'Available Benefits & Allowances',
                                  selectedItems: provider.tempBenefits,
                                  availableItems: benefitOptions,
                                  color: const Color(0xFFB8860B),
                                  onToggle: (item) {
                                    print(
                                        'Benefit toggle called: $item'); // Debug line
                                    provider.toggleBenefit(item);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [primary, primaryDark],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: provider.isPosting
                                    ? null
                                    : () async {
                                  if (_formKey.currentState!.validate()) {
                                    final error = await provider.addJob();
                                    if (!context.mounted) return;
                                    if (error != null) {
                                      ScaffoldMessenger
                                          .of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .circular(12)),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger
                                          .of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Position posted successfully! 🚀'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .circular(12)),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: provider.isPosting
                                    ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.flight_takeoff_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Post Position Now',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  String _formatDeadlineForDisplay(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat.yMMMMd().format(dt); // e.g., "October 28, 2025"
    } catch (_) {
      return iso; // fallback if format unexpected
    }
  }


  Widget _buildPillSelector({
    required String title,
    required List<String> selectedItems,
    required List<String> availableItems,
    required Color color,
    required void Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableItems.map((item) {
            final isSelected = selectedItems.contains(item);
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  print('Pill tapped: $item, isSelected: $isSelected'); // Debug line
                  onToggle(item);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Icon(Icons.check_rounded, size: 16, color: color),
                      if (isSelected)
                        const SizedBox(width: 4),
                      Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? color : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLogoUploader(job_listing_provider provider) {
    return Column(
      children: [
        Text(
          'Unit Emblem',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
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
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: paleWhite,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: primaryLight, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: provider.tempLogoBytes != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: Image.memory(
                provider.tempLogoBytes!,
                fit: BoxFit.cover,
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_rounded,
                    size: 28, color: primary),
                const SizedBox(height: 4),
                Text(
                  'Upload',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: primary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
    IconData? icon,
    String? hintText,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon, color: primary, size: 20) : null,
        filled: true,
        fillColor: paleWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value, // make nullable for safety
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    final validValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: validValue,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: primary, size: 20) : null,
        filled: true,
        fillColor: paleWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
      ),
    );
  }



}