// TopNavProvider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Fetches the current user’s full name from Firestore, then exposes
/// the first two letters as `initials`.
class R_TopNavProvider extends ChangeNotifier {
  String _initials = '';
  String get initials => _initials;

  R_TopNavProvider() {
    _fetchInitials();
  }

  Future<void> _fetchInitials() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;
      final fs = FirebaseFirestore.instance;

      // Read the recruiter document
      final docSnap = await fs.collection('recruiter').doc(uid).get();
      if (!docSnap.exists) {
        _initials = '';
        notifyListeners();
        return;
      }

      final data = docSnap.data();
      String? fullName;

      if (data != null) {
        // If 'user_data' is a nested map on the recruiter doc
        if (data['user_data'] is Map && (data['user_data'] as Map).containsKey('name')) {
          final v = (data['user_data'] as Map)['name'];
          if (v is String && v.trim().isNotEmpty) fullName = v.trim();
        }

        // Also support the case where 'name' is stored directly on the recruiter doc
        if (fullName == null && data['name'] is String && (data['name'] as String).trim().isNotEmpty) {
          fullName = (data['name'] as String).trim();
        }
      }

      if (fullName != null && fullName.isNotEmpty) {
        final letters = fullName.replaceAll(RegExp(r'\s+'), '');
        _initials = letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();
      } else {
        _initials = '';
      }

      notifyListeners();
    } catch (e) {
      _initials = '';
      notifyListeners();
    }
  }
}
