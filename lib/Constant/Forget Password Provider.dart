import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ForgotPasswordProvider with ChangeNotifier {
  String _email = '';
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get email => _email;
  bool get isLoading => _isLoading;

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  Future<void> submitForgotPassword(BuildContext context) async {
    // 1. Input Validation
    if (_email.isEmpty || !_email.contains('@')) {
      // REPLACED: _showErrorFlushbar
      showErrorSnackBar(context, 'Please enter a valid email address.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: _email);
      _showSuccessDialog(context); // You might want to update this to a Green SnackBar too!
    } on FirebaseAuthException catch (e) {
      // 2. Firebase Error Handling
      if (e.code == 'user-not-found') {
        showErrorSnackBar(context, 'No user found for that email.');
      } else if (e.code == 'invalid-email') {
        showErrorSnackBar(context, 'The email address is badly formatted.');
      } else {
        showErrorSnackBar(
            context,
            e.message ?? 'Failed to send password reset email.'
        );
      }
    } catch (e) {
      // 3. Generic Error Handling
      showErrorSnackBar(
          context,
          'An unexpected error occurred. Please try again.'
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void _showSuccessDialog(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
                  children: [
                    Lottie.asset(
                      'images/success.json',
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Check Your Mailbox',
                      textAlign: TextAlign.center, // center text
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'If your email exists, a password reset link has been sent to your email.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation =
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curvedAnimation,
          child: child,
        );
      },
    );
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFC72C41),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 40),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Oh Snap!",
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          message,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Decorative bubble logic (Optional)
            Positioned(
              bottom: 0,
              left: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                ),
                child: Transform.translate(
                  offset: const Offset(-10, 20),
                  child: Container(
                    height: 80,
                    width: 80,
                    color: Colors.white.withOpacity(0.1), // Bubbles
                  ),
                ),
              ),
            )
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(20), // Floats comfortably
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
