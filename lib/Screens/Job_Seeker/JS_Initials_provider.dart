// TopNavProvider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          .collection('job_seeker')
          .doc(user.uid)
          .get();

      if (!docSnap.exists) {
        _updateInitials('');
        return;
      }

      final data = docSnap.data();
      final fullName = _extractName(data);

      _updateInitials(_generateInitials(fullName));
    } catch (e) {
      debugPrint('TopNavProvider: Error fetching initials: $e');
      _updateInitials('');
    }
  }

  String? _extractName(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Check nested user_data.personalProfile.name
    if (data['user_data'] is Map) {
      final userData = data['user_data'] as Map<String, dynamic>;

      if (userData['personalProfile'] is Map) {
        final personalProfile = userData['personalProfile'] as Map<String, dynamic>;
        final name = personalProfile['name'];
        if (name is String && name.trim().isNotEmpty) {
          return name.trim();
        }
      }

      // Fallback: check user_data.name directly
      final userName = userData['name'];
      if (userName is String && userName.trim().isNotEmpty) {
        return userName.trim();
      }
    }

    // Fallback: check direct name field
    final directName = data['name'];
    if (directName is String && directName.trim().isNotEmpty) {
      return directName.trim();
    }

    return null;
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