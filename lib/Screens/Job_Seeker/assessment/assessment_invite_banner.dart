import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// A standing reminder of any assessment the candidate still has to sit.
///
/// The invitation also goes out by email, but an email is easy to miss and the
/// window is 24 hours. This is the safety net: a candidate who opens the app
/// at all cannot fail to see it.
///
/// Renders nothing when there is nothing outstanding, so it costs a row of
/// vertical space only when it has something to say.
class AssessmentInviteBanner extends StatelessWidget {
  const AssessmentInviteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // No status filter in the query: a second clause alongside candidateUid
      // would need a composite index, and a candidate has a handful of these
      // at most. Filtering happens below.
      stream: FirebaseFirestore.instance
          .collection('assessments')
          .where('candidateUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        const open = {'invited', 'accepted', 'in_progress'};
        final pending = snap.data!.docs
            .where((d) => open.contains((d.data()['status'] ?? '').toString()))
            .toList()
          ..sort((a, b) {
            final x = a.data()['expiresAt'] as Timestamp?;
            final y = b.data()['expiresAt'] as Timestamp?;
            if (x == null || y == null) return 0;
            return x.compareTo(y);
          });

        if (pending.isEmpty) return const SizedBox.shrink();

        final doc = pending.first;
        final data = doc.data();
        final started = (data['status'] ?? '') == 'in_progress';
        final expires = (data['expiresAt'] as Timestamp?)?.toDate();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.go('/assessment/${doc.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        started ? Icons.play_circle_outline_rounded : Icons.quiz_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            started
                                ? 'Your assessment is still running'
                                : 'You have an online assessment to complete',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle(data, expires, started, pending.length),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 19),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _subtitle(
    Map<String, dynamic> data,
    DateTime? expires,
    bool started,
    int total,
  ) {
    final job = (data['jobTitle'] ?? '').toString();
    final parts = <String>[
      if (job.isNotEmpty) job,
      if (started)
        'Continue where you left off — the clock is running'
      else if (expires != null)
        _remaining(expires),
      if (total > 1) '+${total - 1} more',
    ];
    return parts.join('  ·  ');
  }

  static String _remaining(DateTime expires) {
    final left = expires.difference(DateTime.now());
    if (left.isNegative) return 'Expired';
    if (left.inHours >= 1) return '${left.inHours}h left to start';
    return '${left.inMinutes}m left to start';
  }
}
