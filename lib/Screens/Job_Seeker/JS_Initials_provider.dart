// TopNavProvider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/onboarding/candidate_profile_service.dart';

class JS_TopNavProvider extends ChangeNotifier {
  String _initials = '';
  String get initials => _initials;

  JS_TopNavProvider() {
    _fetchInitials();
  }

  Future<void> _fetchInitials() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _updateInitials('');
        return;
      }

      final docSnap = await FirebaseFirestore.instance
          .collection('Job_Seeker')
          .doc(user.uid)
          .get();

      if (!docSnap.exists) {
        _updateInitials('');
        return;
      }

      final fullName = _extractName(user.uid, docSnap.data());

      _updateInitials(_generateInitials(fullName));
    } catch (e) {
      debugPrint('TopNavProvider: Error fetching initials: $e');
      _updateInitials('');
    }
  }

  String? _extractName(String uid, Map<String, dynamic>? data) {
    final name =
        CandidateProfileService.parse(uid, data)?.personalInfo.fullName.trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  String _generateInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '';

    final parts = fullName.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      // First name + Last name initials
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.length == 1 && parts.first.length >= 2) {
      // First two letters of single name
      return parts.first.substring(0, 2).toUpperCase();
    } else if (parts.first.isNotEmpty) {
      // Single letter
      return parts.first[0].toUpperCase();
    }

    return '';
  }

  void _updateInitials(String value) {
    _initials = value;
    notifyListeners();
  }

  // Public method to refresh initials (useful after profile updates)
  Future<void> refresh() => _fetchInitials();
}
