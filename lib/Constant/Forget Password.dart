import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'Header_Nav.dart';
import 'Forget Password Provider.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ─── Precache SVG image ───

      // ─── Fade in the form ───
      setState(() {
        _opacity = 1;
      });
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }



  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ForgotPasswordProvider>(context, listen: false);
    provider.setEmail(_email.text.trim()); // set the email in the provider
    await provider.submitForgotPassword(context);
  }


  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const HeaderNav(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 500),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    return Row(
                      children: [
                        // ─── LEFT COLUMN: RESET FORM ───
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Text(
                                          "Forgot Password",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Email",
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildCapsuleField(
                                            controller: _email,
                                            hintText: "johndoe@email.com",
                                            keyboardType:
                                            TextInputType.emailAddress,
                                            suffixIcon: Icons.email_outlined,
                                            isEmail: true,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      Consumer<ForgotPasswordProvider>(
                                        builder: (_, provider, __) {
                                          return Align(
                                            alignment: Alignment.center, // prevent full-width stretch
                                            child: SizedBox(
                                              height: 50,
                                              width: 300, // adjust to desired narrower width
                                              child: ElevatedButton(
                                                onPressed: provider.isLoading ? () {} : _onSubmit, // keep enabled to preserve color
                                                style: ButtonStyle(
                                                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                                        (states) {
                                                      if (provider.isLoading) {
                                                        return primaryColor.withOpacity(0.7);
                                                      }
                                                      return primaryColor;
                                                    },
                                                  ),
                                                  // ensure the disabled/pressed states don’t default to grey:
                                                  foregroundColor: WidgetStateProperty.all(Colors.white),
                                                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(25),
                                                    ),
                                                  ),
                                                  elevation: WidgetStateProperty.all(0),
                                                ),
                                                child: provider.isLoading
                                                    ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                                    : Text(
                                                  "Send Reset Link",
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ─── RIGHT COLUMN: SVG IMAGE (only on wide screens) ───
                        if (isWide)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: SvgPicture.asset(
                                "images/forgot.svg",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a capsule‐style text field without an internal label
  Widget _buildCapsuleField({
    required TextEditingController controller,
    required String hintText,
    bool isEmail = false,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: false,
      validator: validator ??
              (val) {
            if (val == null || val.trim().isEmpty) return "Required";
            if (isEmail && !val.contains("@")) return "Enter valid email";
            return null;
          },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.montserrat(
          color: Color(0xff5C738A),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Color(0xffEBEDF2),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Color(0xff5C738A))
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
