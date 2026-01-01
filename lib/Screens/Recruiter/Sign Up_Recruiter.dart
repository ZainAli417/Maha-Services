import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../Constant/Header_Nav.dart';
import '../../SignUp /signup_provider.dart';
import 'Signup_Provider_Recruiter.dart';


class Recruiter_SignUpScreen extends StatefulWidget {
  const Recruiter_SignUpScreen({super.key});
  @override
  State<Recruiter_SignUpScreen> createState() => _Recruiter_SignUpScreenState();
}

class _Recruiter_SignUpScreenState extends State<Recruiter_SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each field
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  double _opacity = 0;

  // Toggle states for hiding/showing passwords
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  @override
  void initState() {
    super.initState();
    // Fade in the form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1;
      });
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void R_showFlushbar(BuildContext context, String message, bool isError) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: isError ? Colors.red : Colors.green,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  void R_onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<SignUpProvider_Recruiter>(context, listen: false);
    final error = await provider.signUp(
      name: "${_firstName.text.trim()} ${_lastName.text.trim()}",
      email: _email.text.trim(),
      password: _password.text,
    );

    if (error != null) {
      R_showFlushbar(context, error, true);
    } else {
      R_showFlushbar(context, "Signup Successful!", false);
      Future.delayed(const Duration(seconds: 1), ()
      {

        context.pushReplacement('/recruiter-login');
      }
      );
    }
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
              padding: const EdgeInsets.fromLTRB(100,5,100,5),

              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  return Row(
                    children: [
                      // ───────────── LEFT COLUMN (Form) ─────────────
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    // ─── Heading ───
                                    Center(
                                      child: Text(
                                        "Ready to Hire Global Talents?\n Sign Up Today",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    // ─── First & Last Name Row ───
                                    Row(
                                      children: [
                                        // First Name Column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "First Name",
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              _buildCapsuleField(
                                                controller: _firstName,
                                                hintText: "John",
                                                keyboardType:
                                                TextInputType.name,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Last Name Column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Last Name",
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              _buildCapsuleField(
                                                controller: _lastName,
                                                hintText: "Adam",
                                                keyboardType:
                                                TextInputType.name,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // ─── Email & Role Row ───
                                    Row(
                                      children: [
                                        // Email Column
                                        Expanded(
                                          flex: 2,
                                          child: Column(
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
                                                suffixIcon:
                                                Icons.email_outlined,
                                                isEmail: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        // Role Column (Read-Only)
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Register As",
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                enabled: false,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor:
                                                  Color(0xffEBEDF2),
                                                  contentPadding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                    vertical: 12,
                                                    horizontal: 16,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.gpp_good,
                                                    color: Color(0xff5C738A),
                                                  ),
                                                  hintText: 'Recruiter',

                                                  hintStyle: GoogleFonts.montserrat(
                                                    color: Color(0xff5C738A),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                    borderSide: BorderSide(
                                                        color: Color(0xFF64748B)),
                                                  ),
                                                  enabledBorder:
                                                  OutlineInputBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                    borderSide: BorderSide(
                                                        color:Color(0xFF64748B)
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                  OutlineInputBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                    borderSide: BorderSide(
                                                      color: primaryColor,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // ─── Password ───
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Password",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _password,
                                          obscureText: _obscurePassword,
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return "Required";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            hintText: "Enter your password",
                                            hintStyle: GoogleFonts.montserrat(
                                              color: Color(0xff5C738A),
                                            ),
                                            filled: true,
                                            fillColor: Color(0xffEBEDF2),
                                            contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Color(0xff5C738A),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                  !_obscurePassword;
                                                });
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                                                                      color: Color(0xff5C738A),
),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                                                                      color: Color(0xff5C738A),
),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 2),
                                            ),
                                            focusedErrorBorder:
                                            OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // ─── Confirm Password ───
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Confirm Password",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _confirmPassword,
                                          obscureText: _obscureConfirm,
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return "Required";
                                            }
                                            if (val != _password.text) {
                                              return "Passwords do not match";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            hintText: "Confirm your password",
                                            hintStyle: GoogleFonts.montserrat(
                                              color: Color(0xff5C738A),
                                            ),
                                            filled: true,
                                            fillColor: Color(0xffEBEDF2),
                                            contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureConfirm
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Color(0xff5C738A),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirm =
                                                  !_obscureConfirm;
                                                });
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                                                                      color: Color(0xff5C738A),
),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                                                                      color: Color(0xff5C738A),
),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 2),
                                            ),
                                            focusedErrorBorder:
                                            OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
// ─── Sign Up Button ───
                                    // ─── Sign Up Button ───
                                    Consumer<SignupProvider>(
                                      builder: (_, provider, __) {
                                        return Align(
                                          alignment: Alignment.center, // prevent full-width stretch
                                          child: SizedBox(
                                            height: 50,
                                            width: 300, // adjust to desired narrower width
                                            child: ElevatedButton(
                                              onPressed: provider.isLoading ? () {} : R_onSubmit, // keep enabled to preserve color
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
                                                "Sign Up",
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

                                    const SizedBox(height: 15),

                                    // ─── Links Row ───
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            GoRouter.of(context).replace('/recover-password');
                                          },
                                          style: TextButton.styleFrom(
                                              foregroundColor: primaryColor),
                                          child: Text(
                                            "Forgot Password?",
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        TextButton(
                                          onPressed: () {
                                            GoRouter.of(context).replace('/recruiter-login');
                                          },
                                          style: TextButton.styleFrom(
                                              foregroundColor: primaryColor),
                                          child: Text(
                                            "Already have an account? Login",
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ───────────── RIGHT COLUMN (SVG) ─────────────
                      if (isWide)
                        SizedBox(
                          width: 800,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SvgPicture.asset(
                              "images/signup_recruiter.svg",
                              fit: BoxFit.contain,
                            )
                          ),
                        ),
                    ],
                  );
                },

              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single capsule‐style text field without internal label
  Widget _buildCapsuleField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool isEmail = false,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword
          ? (controller == _password ? _obscurePassword : _obscureConfirm)
          : false,
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
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Color(0xffEBEDF2),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (controller == _password
                ? (_obscurePassword
                ? Icons.visibility_off
                : Icons.visibility)
                : (_obscureConfirm
                ? Icons.visibility_off
                : Icons.visibility)),
            color: Color(0xff5C738A),
          ),
          onPressed: () {
            setState(() {
              if (controller == _password) {
                _obscurePassword = !_obscurePassword;
              } else {
                _obscureConfirm = !_obscureConfirm;
              }
            });
          },
        )
            : (suffixIcon != null
            ? Icon(suffixIcon, color: Color(0xff5C738A))
            : null),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(                                                    color: Color(0xff5C738A),
),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(                                                    color: Color(0xff5C738A),
),
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
