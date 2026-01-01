// lib/Screens/Job_Seeker/sign_up_steps.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/widgets/signup_widgets.dart';

class SignUpSteps {
  final String role;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController nationalityController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final TextEditingController fatherController;
  final TextEditingController skillController;
  final DateTime? dob;
  final String? imageDataUrl;
  final List<Map<String, String>> educations;
  final List<Map<String, String>> experiences;
  final List<String> skills;
  final List<String> certs;
  final List<String> refs;
  final bool obscurePassword;
  final bool obscureConfirm;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Function(String) onRoleChanged;
  final Function(DateTime) onDobChanged;
  final VoidCallback onObscurePasswordToggle;
  final VoidCallback onObscureConfirmToggle;
  final VoidCallback onPickImage;
  final VoidCallback onAddEducation;
  final VoidCallback onAddExperience;
  final VoidCallback onAddSkill;
  final Function(int) onRemoveEducation;
  final Function(int) onRemoveExperience;
  final Function(String) onRemoveSkill;
  final Function(String) onRemoveCert;
  final Function(String) onRemoveRef;
  final VoidCallback onAddCert;
  final VoidCallback onAddRef;
  final PageController reviewPageController;
  final int currentReviewPage;
  final ValueChanged<int> onReviewPageChanged;
  Gradient get _recruiterGradient =>   LinearGradient(
    colors: [
       const Color(0xFFF59E0B).withOpacity(0.12),
      const Color(0xFFEC4899).withOpacity(0.12),
    ],
  );

  Color get _recruiterBorderColor => const Color(0xFFF59E0B); // 0xFFF59E0B @ 30%

  Color get _recruiterAccentColor => const Color.fromRGBO(236, 72, 153, 1); // solid accent (0xFFEC4899)
  SignUpSteps({
    required this.role,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.nationalityController,
    required this.passwordController,
    required this.confirmController,
    required this.fatherController,
    required this.skillController,
    required this.dob,
    required this.imageDataUrl,
    required this.educations,
    required this.experiences,
    required this.skills,
    required this.certs,
    required this.refs,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.onRoleChanged,
    required this.onDobChanged,
    required this.onObscurePasswordToggle,
    required this.onObscureConfirmToggle,
    required this.onPickImage,
    required this.onAddEducation,
    required this.onAddExperience,
    required this.onAddSkill,
    required this.onRemoveEducation,
    required this.onRemoveExperience,
    required this.onRemoveSkill,
    required this.onRemoveCert,
    required this.onRemoveRef,
    required this.onAddCert,
    required this.onAddRef,
    required this.reviewPageController,
    required this.currentReviewPage,
    required this.onReviewPageChanged,
  });

  Widget getJobSeekerStep(int step) {
    switch (step) {
      case 0:
        return _roleStep();
      case 1:
        return _singleFieldStep(label: 'Full Name', hint: 'e.g., Jane Smith', controller: nameController, icon: Icons.person_outline_rounded);
      case 2:
        return _singleFieldStep(label: 'Email Address', hint: 'e.g., jane@email.com', controller: emailController, icon: Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress);
      case 3:
        return _singleFieldStep(label: 'Phone Number', hint: 'e.g., +1 234 567 8900', controller: phoneController, icon: Icons.phone_outlined, keyboard: TextInputType.phone);
      case 4:
        return _singleFieldStep(label: 'Nationality', hint: 'e.g., Pakistani', controller: nationalityController, icon: Icons.account_circle_outlined, keyboard: TextInputType.text);
      case 5:
        return _passwordStep();
      case 6:
        return _dobFatherStep();
      case 7:
        return _imageUploadStep();
      case 8:
        return _educationStep();
      case 9:
        return _experienceStep();
      case 10:
        return _skillsStep();
      case 11:
        return _certificationsStep();
      case 12:
        return _referencesStep();
      case 13:
        return _reviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget getRecruiterStep(int step) {
    switch (step) {
      case 0:
        return _roleStep();
      case 1:
        return _singleFieldStep(label: 'Full Name', hint: 'e.g., John Doe', controller: nameController, icon: Icons.person_outline_rounded);
      case 2:
        return _singleFieldStep(label: 'Email Address', hint: 'e.g., john@company.com', controller: emailController, icon: Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress);
      case 3:
        return _singleFieldStep(label: 'Phone Number', hint: 'e.g., +1 234 567 8900', controller: phoneController, icon: Icons.phone_outlined, keyboard: TextInputType.phone);
      case 4:
        return _singleFieldStep(label: 'Nationality', hint: 'e.g., American', controller: nationalityController, icon: Icons.flag_outlined);
      case 5:
        return _passwordStep();
      case 6:
        return _reviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _roleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Aboard! 🚀', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Choose your role to unlock tailored features', style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        _roleCard('Job Seeker', 'Find your dream job', Icons.work_outline_rounded, role == 'Job Seeker', primaryColor),
        const SizedBox(height: 16),
        _roleCard('Recruiter', 'Discover top talent', Icons.business_center_outlined, role == 'Recruiter', secondaryColor),
      ],
    );
  }

  Widget _roleCard(String title, String subtitle, IconData icon, bool selected, Color color) {
    final bool isRecruiter = title == 'Recruiter';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onRoleChanged(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // use recruiter gradient when recruiter and selected
            gradient: isRecruiter && selected ? _recruiterGradient : (selected ? LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]) : null),
            color: (isRecruiter && selected) ? null : (selected ? null : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRecruiter && selected ? _recruiterBorderColor : (selected ? color : Colors.grey.shade200),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? (isRecruiter ? _recruiterAccentColor.withOpacity(0.2) : color.withOpacity(0.2)) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: selected ? (isRecruiter ? _recruiterAccentColor : color) : Colors.grey.shade600, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRecruiter ? _recruiterAccentColor : color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _singleFieldStep({required String label, required String hint, required TextEditingController controller, required IconData icon, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Please provide your $label', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        SignUpWidgets.elegantTextField(controller: controller, label: hint, icon: icon, keyboardType: keyboard),
      ],
    );
  }

  Widget _passwordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Secure Your Account 🔒', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Create a strong password to protect your account', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        SignUpWidgets.elegantTextField(
          controller: passwordController,
          label: 'Password (min. 6 characters)',
          icon: Icons.lock_outline_rounded,
          obscure: obscurePassword,
          suffix: IconButton(
            icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade600),
            onPressed: onObscurePasswordToggle,
          ),
        ),
        const SizedBox(height: 16),
        SignUpWidgets.elegantTextField(
          controller: confirmController,
          label: 'Confirm Password',
          icon: Icons.lock_person_outlined,
          obscure: obscureConfirm,
          suffix: IconButton(
            icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade600),
            onPressed: onObscureConfirmToggle,
          ),
        ),
      ],
    );
  }

  Widget _dobFatherStep() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Information', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text('Help us know you better', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 32),

          // 1. Father's Name Field
          SignUpWidgets.elegantTextField(
            controller: fatherController,
            label: 'Father\'s Name',
            icon: Icons.family_restroom_outlined,
          ),
          const SizedBox(height: 16),

          // NOTE: Nationality removed from here because it's now its own dedicated step (index 4)

          // 3. Date of Birth Picker (Unchanged)
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(now.year - 20),
                firstDate: DateTime(1900),
                lastDate: now,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: primaryColor),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onDobChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xff5C738A),),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: primaryColor, size: 22),
                  const SizedBox(width: 16),
                  Text(
                    dob == null ? 'Select Date of Birth' : dob!.toLocal().toIso8601String().split('T').first,
                    style: GoogleFonts.poppins(fontSize: 15, color: dob == null ? Colors.grey.shade600 : Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _imageUploadStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Photo 📸', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('A professional photo makes a great first impression', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: imageDataUrl != null ? MemoryImage(base64Decode(imageDataUrl!.split(',').last)) : null,
                  child: imageDataUrl == null ? Icon(Icons.person_outline_rounded, size: 60, color: Colors.grey.shade400) : null,
                ),
              ),
              const SizedBox(height: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ElevatedButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(imageDataUrl == null ? 'Upload Photo' : 'Change Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Max size: 2MB • JPG, PNG', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _educationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Education 🎓', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  const SizedBox(height: 4),
                  Text('Add your academic background', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                onPressed: onAddEducation,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (educations.isEmpty)
          SignUpWidgets.buildEmptyState('No education added yet', Icons.school_outlined)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: educations.length,
            itemBuilder: (context, index) {
              final edu = educations[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xff5C738A),),
                  boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school_outlined, color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(edu['degree'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(edu['institution'] ?? '', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                          if (edu['from']!.isNotEmpty || edu['to']!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('${edu['from']} - ${edu['to']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                      onPressed: () => onRemoveEducation(index),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _experienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Work Experience 💼', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  const SizedBox(height: 4),
                  Text('Showcase your professional journey', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                onPressed: onAddExperience,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (experiences.isEmpty)
          SignUpWidgets.buildEmptyState('No experience added yet', Icons.work_outline_rounded)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: experiences.length,
            itemBuilder: (context, index) {
              final exp = experiences[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xff5C738A),),
                  boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.work_outline_rounded, color: secondaryColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp['title'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          if (exp['duration']!.isNotEmpty) Text(exp['duration'] ?? '', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                      onPressed: () => onRemoveExperience(index),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _skillsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Skills ⚡', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Add skills that make you stand out', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SignUpWidgets.elegantTextField(
                controller: skillController,
                label: 'e.g., Flutter, React, Python',
                icon: Icons.lightbulb_outline_rounded,
              ),
            ),
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: onAddSkill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (skills.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No skills added yet', style: GoogleFonts.poppins(color: Colors.grey.shade500)),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentColor.withOpacity(0.15), accentColor.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Text(s, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onRemoveSkill(s),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _certificationsStep() {
    return _simpleListStep(
      title: 'Certifications 🏆',
      subtitle: 'Add your professional certifications',
      items: certs,
      icon: Icons.verified_outlined,
      color: const Color(0xFF10B981),
      onAdd: onAddCert,
      onRemove: onRemoveCert,
    );
  }

  Widget _referencesStep() {
    return _simpleListStep(
      title: 'References 👥',
      subtitle: 'Add professional references',
      items: refs,
      icon: Icons.group_outlined,
      color: const Color(0xFFF59E0B),
      onAdd: onAddRef,
      onRemove: onRemoveRef,
    );
  }

  Widget _simpleListStep({
    required String title,
    required String subtitle,
    required List<String> items,
    required IconData icon,
    required Color color,
    required VoidCallback onAdd,
    required Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (items.isEmpty)
          SignUpWidgets.buildEmptyState('No items added yet', icon)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(s, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onRemove(s),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _reviewStep() {

    // 1. Collect all review cards into a list.
    final List<Widget> reviewCards = [
      // --- Account Details Card (Always visible) ---
      SignUpWidgets.buildReviewCard('Account Details', {
        'Role': role,
        'Name': nameController.text,
        'Email': emailController.text,
        'Phone': phoneController.text,
        if (nationalityController.text.isNotEmpty) 'Nationality': nationalityController.text,
      }, Icons.person_outline_rounded, primaryColor),
    ];

    // 2. Conditionally add Job Seeker specific cards
    if (role == 'Job Seeker') {
      reviewCards.addAll([
        // --- Personal Details Card ---
        SignUpWidgets.buildReviewCard('Personal Details', {
          'Date of Birth': dob?.toLocal().toIso8601String().split('T').first ?? 'N/A',
          'Father\'s Name': fatherController.text,
        }, Icons.family_restroom_outlined, secondaryColor),

        // --- Skills Card ---
        if (skills.isNotEmpty)
          SignUpWidgets.buildReviewCard('Skills', {
            'Skills': skills.join(', '),
          }, Icons.lightbulb_outline_rounded, accentColor),

        // --- Education Card ---
        if (educations.isNotEmpty)
          SignUpWidgets.buildReviewCard('Education', {
            'Entries': '${educations.length} education record(s) added',
          }, Icons.school_outlined, primaryColor),

        // --- Experience Card ---
        if (experiences.isNotEmpty)
          SignUpWidgets.buildReviewCard('Experience', {
            'Entries': '${experiences.length} experience record(s) added',
          }, Icons.work_outline_rounded, secondaryColor),
      ]);
    }

    // 3. Build the Column with the carousel structure
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Almost There! ✨', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Review your information before submitting', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 24),

        // --- Paginator/Carousel Area ---
        SizedBox(
          height: 400, // Give the PageView a constrained height
          child: Stack(
            alignment: Alignment.center,
            children: [
              // PageView (The actual card swiper)
              PageView(
                controller: reviewPageController, // Use the passed controller
                onPageChanged: onReviewPageChanged, // Use the passed callback
                children: reviewCards,
              ),

              // Left Arrow Button
              Positioned(
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
                  onPressed: currentReviewPage > 0 // Use the passed index
                      ? () {
                    reviewPageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  }
                      : null,
                ),
              ),

              // Right Arrow Button
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54),
                  onPressed: currentReviewPage < reviewCards.length - 1 // Use the passed index
                      ? () {
                    reviewPageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  }
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- Pagination Dots (Optional, but highly recommended) ---
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(reviewCards.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 8.0,
                width: currentReviewPage == index ? 24.0 : 8.0, // Use the passed index
                decoration: BoxDecoration(
                  color: currentReviewPage == index ? primaryColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              );
            }),
          ),
        ),
      ],

    );
  }
}
