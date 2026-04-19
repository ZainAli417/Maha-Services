import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Future<bool> submitForgotPassword(BuildContext context) async {
    final trimmedEmail = _email.trim();
    // 1. Input Validation
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      // REPLACED: _showErrorFlushbar
      showErrorSnackBar(context, 'Please enter a valid email address.');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return true;
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
      return false;
    } catch (e) {
      // 3. Generic Error Handling
      showErrorSnackBar(
          context,
          'An unexpected error occurred. Please try again.'
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                    color: Colors.white.withValues(alpha: 0.1), // Bubbles
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
