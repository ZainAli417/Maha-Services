// lib/services/job_alert_service.dart
//
// Centralized service for broadcasting job alert emails to subscribed users.
// When a recruiter posts a new job, this queries Firestore for all users who
// have `job_alerts_enabled == true` and writes a notification document to the
// `job_alert_queue` collection. A Firebase Cloud Function (onCreate trigger)
// picks up the queue document and sends the actual emails.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class JobAlertService {
  static final _firestore = FirebaseFirestore.instance;

  // Broadcast logic removed as it's now handled by the standalone Node.js server

  /// Updates the `job_alerts_enabled` field for the given user.
  static Future<void> updateAlertPreference(String uid, bool enabled) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'job_alerts_enabled': enabled,
      });
      debugPrint(
        '✅ JobAlertService: Alert preference updated for $uid → $enabled',
      );
    } catch (e) {
      debugPrint('❌ JobAlertService: Failed to update preference — $e');
    }
  }

  /// Reads the current alert preference for a user.
  static Future<bool> getAlertPreference(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      return data['job_alerts_enabled'] == true;
    } catch (e) {
      debugPrint('❌ JobAlertService: Failed to read preference — $e');
      return false;
    }
  }
}
