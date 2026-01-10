import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
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
    if (_email.isEmpty || !_email.contains('@')) {
      _showErrorFlushbar(context, 'Please enter a valid email address.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: _email);
      _showSuccessDialog(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showErrorFlushbar(context, 'No user found for that email.');
      } else if (e.code == 'invalid-email') {
        _showErrorFlushbar(context, 'The email address is badly formatted.');
      } else {
        _showErrorFlushbar(
            context, e.message ?? 'Failed to send password reset email.');
      }
    } catch (e) {
      _showErrorFlushbar(
          context, 'An unexpected error occurred. Please try again.');
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

  void _showErrorFlushbar(BuildContext context, String message) {
    Flushbar(
      message: message,
      backgroundColor: Colors.red,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      messageText: Text(
        message,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      isDismissible: true,
    ).show(context);
  }
}
