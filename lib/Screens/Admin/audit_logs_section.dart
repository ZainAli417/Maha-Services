import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/services/audit_log_service.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/pagination_bar.dart';

/// Admin audit-trail viewer with action filtering and cursor pagination.
class AuditLogsSection extends StatefulWidget {
  const AuditLogsSection({super.key});

  @override
  State<AuditLogsSection> createState() => _AuditLogsSectionState();
}

class _AuditLogsSectionState extends State<AuditLogsSection> {
  final _service = AuditLogService();
  static const _pageSize = 20;

  // Human-facing action filter options.
  static const _actionFilters = <String, String?>{
    'All actions': null,
    'Created': AuditAction.userCreated,
    'Role changed': AuditAction.userRoleChanged,
    'Suspended': AuditAction.userSuspended,
    'Activated': AuditAction.userActivated,
    'Deleted': AuditAction.userSoftDeleted,
    'Restored': AuditAction.userRestored,
    'Profile reset': AuditAction.userProfileReset,
    'Questionnaire': AuditAction.questionnairePublished,
  };

  String _selectedFilter = 'All actions';
  bool _loading = true;
  String? _error;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  // _cursors[i] is the startAfter cursor for page i (null for page 0). Grows as
  // the admin pages forward, enabling correct backward navigation too.
  List<DocumentSnapshot<Map<String, dynamic>>?> _cursors = [null];
  int _page = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _resetAndLoad();
  }

  void _resetAndLoad() {
    _cursors = [null];
    _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    if (page < 0 || page >= _cursors.length) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _service.fetchPage(
        limit: _pageSize,
        startAfter: _cursors[page],
        actionFilter: _actionFilters[_selectedFilter],
      );
      if (!mounted) return;
      final hasMore = snap.docs.length == _pageSize;
      // Record the cursor for the next page (last doc of this page).
      if (hasMore && snap.docs.isNotEmpty && _cursors.length == page + 1) {
        _cursors.add(snap.docs.last);
      }
      setState(() {
        _docs = snap.docs;
        _page = page;
        _hasMore = hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: EdgeInsets.all(isMobile ? 12 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterBar(),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Row(
      children: [
        const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _selectedFilter,
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(12),
          items: _actionFilters.keys
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedFilter = v);
            _resetAndLoad();
          },
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _resetAndLoad,
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView(message: 'Loading audit trail…');
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _resetAndLoad);
    }
    if (_docs.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No audit entries',
        subtitle: 'Admin actions will appear here as they happen.',
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _docs.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) => _row(_docs[i].data()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: PaginationBar(
            label: 'Page ${_page + 1}',
            canPrev: _page > 0,
            canNext: _hasMore,
            onPrev: _page > 0 ? () => _loadPage(_page - 1) : null,
            onNext: _hasMore ? () => _loadPage(_page + 1) : null,
          ),
        ),
      ],
    );
  }

  Widget _row(Map<String, dynamic> d) {
    final action = (d['action'] ?? '').toString();
    final actor = (d['actorEmail'] ?? d['actorUid'] ?? 'system').toString();
    final target = (d['targetLabel'] ?? d['targetId'] ?? '').toString();
    final ts = d['timestamp'];
    final when = ts is Timestamp
        ? DateFormat('MMM d, yyyy · h:mm a').format(ts.toDate())
        : '—';
    final details = d['details'];
    final detailStr = (details is Map && details.isNotEmpty)
        ? details.entries
            .where((e) => e.value != null)
            .map((e) => '${e.key}: ${e.value}')
            .join(', ')
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconFor(action), size: 16, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelFor(action),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$actor → ${target.isEmpty ? '—' : target}'
                  '${detailStr.isEmpty ? '' : '  ($detailStr)'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            when,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String action) {
    switch (action) {
      case AuditAction.userCreated:
        return Icons.person_add_rounded;
      case AuditAction.userRoleChanged:
        return Icons.swap_horiz_rounded;
      case AuditAction.userSuspended:
        return Icons.block_rounded;
      case AuditAction.userActivated:
        return Icons.check_circle_rounded;
      case AuditAction.userSoftDeleted:
        return Icons.delete_outline_rounded;
      case AuditAction.userRestored:
        return Icons.restore_rounded;
      case AuditAction.userProfileReset:
        return Icons.refresh_rounded;
      case AuditAction.questionnairePublished:
        return Icons.quiz_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  String _labelFor(String action) {
    switch (action) {
      case AuditAction.userCreated:
        return 'User created';
      case AuditAction.userRoleChanged:
        return 'Role changed';
      case AuditAction.userSuspended:
        return 'User suspended';
      case AuditAction.userActivated:
        return 'User activated';
      case AuditAction.userSoftDeleted:
        return 'User deleted';
      case AuditAction.userRestored:
        return 'User restored';
      case AuditAction.userProfileReset:
        return 'Profile reset';
      case AuditAction.questionnairePublished:
        return 'Questionnaire published';
      default:
        return action;
    }
  }
}
