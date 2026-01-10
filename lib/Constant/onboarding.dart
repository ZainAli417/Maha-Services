import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../SignUp /signup_provider.dart';
import '../extractor_CV/cv_extraction_UI.dart';

// Call this where your button triggers the dialog

/// Dialog content extracted into a widget so it can manage its own keys/state.
class RecruiterDialogContent extends StatefulWidget {
  const RecruiterDialogContent({super.key});

  @override
  State<RecruiterDialogContent> createState() => _RecruiterDialogContentState();
}

class _RecruiterDialogContentState extends State<RecruiterDialogContent> {
  final GlobalKey _cvSectionKey = GlobalKey();
  final GlobalKey<FormState> _formKeyAccount = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Get your SignupProvider instance (like `p` in your original code)
    final signupProvider = Provider.of<SignupProvider>(context, listen: false);

    // Replace `extractor` with your actual extractor variable if needed
    final extractor = null; // <-- replace with real extractor if required

    return SafeArea(
      child: Column(
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Recruiter Account',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                )
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Scrollable dialog body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ====== YOUR ORIGINAL CONTAINER (converted to inside dialog) ======
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade50,
                          Colors.purple.shade50.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.indigo.shade500,
                                    Colors.purple.shade500,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Do you have a CV/Resume?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Upload for faster registration',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
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
                              child: _buildActionButton(
                                context: context,
                                label: 'Upload CV',
                                icon: Icons.upload_file_rounded,
                                isPrimary: false,
                                onPressed: () {
                                  // Reveal CV upload and scroll into view
                                  signupProvider.revealCvUpload(reveal: true);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final ctx = _cvSectionKey.currentContext;
                                    if (ctx != null) {
                                      Scrollable.ensureVisible(
                                        ctx,
                                        duration: const Duration(milliseconds: 400),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                context: context,
                                label: 'Continue Manually',
                                icon: Icons.arrow_forward_rounded,
                                isPrimary: true,
                                onPressed: () {
                                  final okForm = _formKeyAccount.currentState?.validate() ?? false;
                                  final okEmail = signupProvider.validateEmail();
                                  final okPass = signupProvider.validatePasswords();

                                  if (!okForm || !okEmail || !okPass) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please fix all errors before proceeding')),
                                    );
                                    return;
                                  }

                                  signupProvider.revealNextPersonalField();
                                  signupProvider.goToStep(1);
                                  // If you had a step animation, trigger it here
                                },
                              ),
                            ),
                          ],
                        ),

                        // CV Upload Section
                        Consumer<SignupProvider>(
                          builder: (_, provider, __) {
                            if (!provider.showCvUploadSection) return const SizedBox.shrink();

                            return Container(
                              key: _cvSectionKey,
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.indigo.shade100),
                              ),
                              child: CvUploadSection(
                                extractor: extractor,
                                provider: provider,
                                onSuccess: () {
                                  // navigate on success
                                  context.go('/login');
                                },
                                onManualContinue: () {
                                  provider.revealCvUpload(reveal: false);
                                  provider.revealNextPersonalField();
                                  provider.goToStep(1);
                                  // you may want to close the dialog after continuing:
                                  // Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // === you can add more content under the container here ===
                ],
              ),
            ),
          ),

          // Footer buttons (optional)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // example: submit or close
                      Navigator.of(context).pop();
                    },
                    child: Text('Done', style: GoogleFonts.poppins()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
              : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isPrimary
              ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]
              : null,
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: isPrimary ? Colors.white : const Color(0xFF10B981)),
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : const Color(0xFF10B981),
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: isPrimary ? Colors.transparent : Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            elevation: isPrimary ? 0 : 0,
          ),
        ),
      ),
    );
  }
}
