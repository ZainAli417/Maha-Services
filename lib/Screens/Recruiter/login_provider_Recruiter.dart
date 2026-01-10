import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginProvider_Recruiter with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Login with email, password, and expectedRole
  Future<String?> login({
    required String email,
    required String password,
    required String expectedRole, // NEW PARAM
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch user role from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('Recruiter')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return 'No Account Found. Please Register First.';
      }

      final userDoc = snapshot.docs.first;
      final role = userDoc['role'];

      // 2. Check role
      if (role != expectedRole) {
        _isLoading = false;
        notifyListeners();
        return 'This is not a Job Seeker account.';
      }

      // 3. Authenticate
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      _isLoading = false;
      notifyListeners();
      return null; // success

    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == 'user-not-found') {
        return 'No Account Found. Please Register First.';
      } else if (e.code == 'wrong-password') {
        return 'Invalid Password.';
      } else {
        return e.message ?? 'An error occurred.';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred. Our Team is Working On it.';
    }
  }
}
