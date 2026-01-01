import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../Constant/Header_Nav.dart';
import 'login_provider_Recruiter.dart';

class Recruiter_LoginScreen extends StatefulWidget {
  const Recruiter_LoginScreen({super.key});
  @override
  State<Recruiter_LoginScreen> createState() => _Recruiter_LoginScreenState();
}

class _Recruiter_LoginScreenState extends State<Recruiter_LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for email & password only
  final _email = TextEditingController();
  final _password = TextEditingController();

  double _opacity = 0;
  bool _obscurePassword = true;

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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showFlushbar(BuildContext context, String message, bool isError) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: isError ? Colors.red : Colors.green,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }


  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<LoginProvider_Recruiter>(context, listen: false);
    final error = await provider.login(
      email: _email.text.trim(),
      password: _password.text,
      expectedRole: 'Recruiter',
    );


    if (error != null) {
      _showFlushbar(context, error, true);
    }
    else {
      _showFlushbar(context, "Login Successful!", false);
      Future.delayed(const Duration(seconds: 1), () {

        context.pushReplacement('/recruiter-dashboard');
      });
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
              padding: const EdgeInsets.fromLTRB(180, 5, 180, 5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;

                  return Row(
                    children: [
                      // ───── LEFT COLUMN: SVG IMAGE ─────
                      if (isWide)
                        SizedBox(
                          width: 700,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SvgPicture.asset(
                              "images/login_recruiter.svg",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // ───── RIGHT COLUMN: LOGIN FORM ─────
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
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
                                    // ─── Heading ───
                                    Center(
                                      child: Text(
                                        "Login to your account",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // ─── Email Field ───
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
                                    const SizedBox(height: 24),

                                    // ─── Password Field ───
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
                                                fontWeight: FontWeight.w400),
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
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade200,
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
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),

                                    // ─── Login Button ───
                                    Consumer<LoginProvider_Recruiter>(
                                      builder: (_, provider, __) {
                                        return Align(
                                          alignment: Alignment
                                              .center, // prevent full-width stretch
                                          child: SizedBox(
                                            height: 50,
                                            width:
                                                300, // adjust to desired narrower width
                                            child: ElevatedButton(
                                              onPressed: provider.isLoading
                                                  ? () {}
                                                  : _onLogin, // keep enabled to preserve color
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    WidgetStateProperty
                                                        .resolveWith<Color>(
                                                  (states) {
                                                    if (provider.isLoading) {
                                                      return primaryColor
                                                          .withOpacity(0.7);
                                                    }
                                                    return primaryColor;
                                                  },
                                                ),
                                                // ensure the disabled/pressed states don’t default to grey:
                                                foregroundColor:
                                                    WidgetStateProperty.all(
                                                        Colors.white),
                                                shape: WidgetStateProperty.all<
                                                    RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                ),
                                                elevation:
                                                    WidgetStateProperty.all(0),
                                              ),
                                              child: provider.isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : Text(
                                                      "Login",
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // ─── Forgot & "New here? Create Account" Row ───
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            context.go('/recover-password');
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
                                            context.go('/recruiter-signup');
                                          },
                                          style: TextButton.styleFrom(
                                              foregroundColor: primaryColor),
                                          child: Text(
                                            "New here? Create Account",
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

  /// Builds a single capsule‐style text field without an internal label
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
          fontWeight: FontWeight.w400,
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
