import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/rbac/user_role.dart';

/// Admin-facing read-only detail view of a user: identity, account metadata,
/// verification status, and uploaded documents (pulled from the job-seeker
/// profile doc when present).
class UserDetailPanel extends StatelessWidget {
  const UserDetailPanel({
    super.key,
    required this.uid,
    required this.userData,
  });

  final String uid;
  final Map<String, dynamic> userData;

  static Future<void> show(
    BuildContext context, {
    required String uid,
    required Map<String, dynamic> userData,
  }) {
    return showDialog(
      context: context,
      builder: (_) => UserDetailPanel(uid: uid, userData: userData),
    );
  }

  static const _ink = Color(0xFF0B2239);
  static const _muted = Color(0xFF5E7A8E);
  static const _border = Color(0xFFDCE7EF);
  static const _primary = Color(0xFF14507F);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final role = UserRole.fromFirestore(userData['role']?.toString());
    final name = (userData['name'] ?? '').toString();
    final email = (userData['email'] ?? '').toString();
    final status = (userData['account_status'] ?? 'active').toString();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 640,
        constraints: BoxConstraints(maxHeight: size.height * 0.85),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context, name, email, role, status),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Account'),
                    const SizedBox(height: 10),
                    _accountGrid(),
                    const SizedBox(height: 24),
                    _sectionTitle('Verification'),
                    const SizedBox(height: 10),
                    _verificationRow(),
                    const SizedBox(height: 24),
                    _sectionTitle('Documents'),
                    const SizedBox(height: 10),
                    _DocumentsList(uid: uid),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    String name,
    String email,
    UserRole? role,
    String status,
  ) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF15A99C), Color(0xFF14507F)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initials.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Unnamed user' : name,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(role?.displayLabel ?? 'Unknown role'),
                    _chip(status),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      );

  Widget _accountGrid() {
    final created = _formatTs(userData['created_at']);
    final deletedAt = _formatTs(userData['deleted_at']);
    final rows = <MapEntry<String, String>>[
      MapEntry('User ID', uid),
      MapEntry('Level', (userData['user_lvl'] ?? '—').toString()),
      MapEntry('Created', created),
      MapEntry(
        'Onboarding',
        (userData['onboarding_completed'] == true ||
                (userData['isNew']?.toString().toLowerCase() == 'no'))
            ? 'Completed'
            : 'Pending',
      ),
      if (deletedAt != '—') MapEntry('Deleted at', deletedAt),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      rows[i].key,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _verificationRow() {
    final emailVerified = userData['email_verified'] == true;
    final docsVerified = userData['documents_verified'] == true;
    return Row(
      children: [
        Expanded(
          child: _verifyTile('Email', emailVerified),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _verifyTile('Documents', docsVerified),
        ),
      ],
    );
  }

  Widget _verifyTile(String label, bool verified) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: verified ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: verified ? const Color(0xFF6EE7B7) : const Color(0xFFFED7AA),
          ),
        ),
        child: Row(
          children: [
            Icon(
              verified ? Icons.verified_rounded : Icons.pending_outlined,
              size: 18,
              color: verified
                  ? const Color(0xFF059669)
                  : const Color(0xFFB45309),
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ${verified ? 'Verified' : 'Pending'}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: verified
                    ? const Color(0xFF059669)
                    : const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );

  static String _formatTs(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('MMM d, yyyy · h:mm a').format(ts.toDate());
    }
    return '—';
  }
}

/// Loads and lists the user's uploaded documents from the Job_Seeker profile
/// doc (documents + certificationDocuments + experienceDocuments).
class _DocumentsList extends StatelessWidget {
  const _DocumentsList({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('Job_Seeker').doc(uid).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final data = snap.data?.data();
        final root = _unwrap(data);
        final docs = <Map<String, dynamic>>[
          ..._docsFrom(root['documents']),
          ..._docsFrom(root['certificationDocuments']),
          ..._docsFrom(root['experienceDocuments']),
        ];
        if (docs.isEmpty) {
          return Text(
            'No documents uploaded.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
          );
        }
        return Column(
          children: [
            for (final d in docs) _docTile(context, d),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? data) {
    if (data == null) return {};
    final ud = data['user_data'] ?? data['userData'];
    if (ud is Map) return Map<String, dynamic>.from(ud);
    return data;
  }

  List<Map<String, dynamic>> _docsFrom(dynamic list) {
    if (list is List) {
      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return const [];
  }

  Widget _docTile(BuildContext context, Map<String, dynamic> d) {
    final name = (d['name'] ?? 'Document').toString();
    final url = (d['url'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              size: 18, color: Color(0xFF14507F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ),
          if (url.isNotEmpty)
            TextButton.icon(
              onPressed: () => _open(url),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open'),
            ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
