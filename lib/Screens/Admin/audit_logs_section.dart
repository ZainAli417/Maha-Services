import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/services/audit_log_service.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/pagination_bar.dart';
import 'widgets/admin_header.dart';

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
      color: const Color(0xFFF6F7FB),
      child: ListView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        children: [
          AdminGradientHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Audit Logs',
            subtitle: 'Immutable, timestamped trail of every admin action.',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F766E), Color(0xFF0891B2), Color(0xFF2563EB)],
            ),
            actions: [
              AdminHeaderButton(
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                onPressed: _resetAndLoad,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _filterChips(),
          const SizedBox(height: 16),
          Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9EDF5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _body(),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final key in _actionFilters.keys)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: key,
                selected: _selectedFilter == key,
                color: _colorForFilter(key),
                onTap: () {
                  setState(() => _selectedFilter = key);
                  _resetAndLoad();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView(message: 'Loading audit trail…');
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _resetAndLoad);
    }
    if (_docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No audit entries',
          subtitle: 'Admin actions will appear here as they happen.',
          compact: true,
        ),
      );
    }
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          itemCount: _docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, i) => _row(_docs[i].data()),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        Padding(
          padding: const EdgeInsets.all(10),
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
            .join(' · ')
        : '';
    final color = _colorFor(action);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF1F7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(action), size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _labelFor(action),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$actor  →  ${target.isEmpty ? '—' : target}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                if (detailStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detailStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 13, color: Color(0xFFCBD5E1)),
              const SizedBox(width: 4),
              Text(
                when,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFor(String action) {
    switch (action) {
      case AuditAction.userCreated:
        return const Color(0xFF6366F1);
      case AuditAction.userRoleChanged:
        return const Color(0xFF0EA5E9);
      case AuditAction.userSuspended:
        return const Color(0xFFF59E0B);
      case AuditAction.userActivated:
        return const Color(0xFF10B981);
      case AuditAction.userSoftDeleted:
        return const Color(0xFFEF4444);
      case AuditAction.userRestored:
        return const Color(0xFF10B981);
      case AuditAction.userProfileReset:
        return const Color(0xFF8B5CF6);
      case AuditAction.questionnairePublished:
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _colorForFilter(String key) {
    final action = _actionFilters[key];
    return action == null ? const Color(0xFF4F46E5) : _colorFor(action);
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

/// Pill filter chip; fills with its action color when selected.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
