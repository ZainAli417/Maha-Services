import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'LIst_of_Applicants_provider.dart';

/// A strip of the filters currently narrowing the list, each removable.
///
/// The point is visibility. A filter set once and forgotten makes a short list
/// look like the whole list, and nothing on screen contradicts that. Showing
/// them — and letting one go with a tap, without reopening the sheet — is the
/// cheapest fix for the commonest filtering mistake.
class ActiveFiltersBar extends StatelessWidget {
  const ActiveFiltersBar({
    super.key,
    required this.provider,
    required this.shown,
    required this.total,
    this.horizontalPadding = 20,
  });

  final ApplicantsProvider provider;

  /// Counts for the list this bar sits above — passed in rather than read off
  /// the provider, because the shortlist screen shows a subset and "7 of 20"
  /// would be a lie there.
  final int shown;
  final int total;

  final double horizontalPadding;

  static const _primary = Color(0xFF6D28D9);
  static const _border = Color(0xFFDCE7EF);

  @override
  Widget build(BuildContext context) {
    final chips = provider.activeFilterChips;
    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFAFF),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text(
            '$shown of $total',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (_, i) => _Chip(
                  label: chips[i].label,
                  onRemove: chips[i].remove,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: provider.clearAllFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Clear all',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 10, right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ActiveFiltersBar._primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0B2239),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 13),
              color: ActiveFiltersBar._primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              tooltip: 'Remove $label',
            ),
          ],
        ),
      );
}
