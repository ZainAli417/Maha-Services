import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'R_Top_Bar.dart';
import 'View_Shortlisted_Detials.dart';
import 'shortlisting_provider.dart';

class Shortlisting extends StatefulWidget {
  const Shortlisting({super.key});

  @override
  State<Shortlisting> createState() => _ShortlistingState();
}

class _ShortlistingState extends State<Shortlisting> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showShadow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 10;
      if (show != _showShadow) setState(() => _showShadow = show);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return '•••@•••';
    final parts = email.split('@');
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '••@${domain[0]}•••';
    return '${local.substring(0, 2)}•••@${domain[0]}•••';
  }

  String _maskPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 4) return '•••-•••';
    return '•••-${cleaned.substring(cleaned.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          RecruiterSidebar(activeIndex: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: ChangeNotifierProvider(
        create: (_) => Shortlisting_provider(),
        builder: (context, _) {
          final prov = Provider.of<Shortlisting_provider>(context);
          return _buildBody(prov);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: 64,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.people_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Candidate Management',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              Text(
                'Analytics & Shortlisted Candidates',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: _showShadow ? const Color(0xFFE2E8F0) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildBody(Shortlisting_provider prov) {
    return prov.loading
        ? _buildLoading()
        : CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Analytics Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildAnalytics(prov),
          ),
        ),
        // Filters
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildFilters(prov),
          ),
        ),
        // Candidates Table
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: _buildCandidatesSection(prov),
          ),
        ),
        // Bottom action bar spacer
        if (prov.selectedUids.isNotEmpty)
          SliverToBoxAdapter(child: _buildActionBar(prov)),
      ],
    );
  }

  Widget _buildAnalytics(Shortlisting_provider prov) {
    final list = prov.candidates;

    // Calculate analytics
    final total = list.length;
    final avgScore = total > 0
        ? list
        .where((c) => c.matchScore != null)
        .map((c) {
      final score = c.matchScore!['overallScore'] ?? c.matchScore!['overall_score'] ?? 0;
      return (score is num) ? score.toDouble() : 0.0;
    })
        .fold(0.0, (a, b) => a + b) /
        list.where((c) => c.matchScore != null).length
        : 0.0;

    final highPerformers = list.where((c) {
      if (c.matchScore == null) return false;
      final score = c.matchScore!['overallScore'] ?? c.matchScore!['overall_score'] ?? 0;
      return (score is num ? score.toDouble() : 0.0) >= 80;
    }).length;

    // Nationality distribution
    final nationalityMap = <String, int>{};
    for (final c in list) {
      if (c.nationality.isNotEmpty) {
        nationalityMap[c.nationality] = (nationalityMap[c.nationality] ?? 0) + 1;
      }
    }

    // Score distribution
    final scoreRanges = {'90-100': 0, '80-89': 0, '70-79': 0, '60-69': 0, '<60': 0};
    for (final c in list) {
      if (c.matchScore == null) continue;
      final score = c.matchScore!['overallScore'] ?? c.matchScore!['overall_score'] ?? 0;
      final s = (score is num) ? score.toDouble() : 0.0;
      if (s >= 90) scoreRanges['90-100'] = scoreRanges['90-100']! + 1;
      else if (s >= 80) scoreRanges['80-89'] = scoreRanges['80-89']! + 1;
      else if (s >= 70) scoreRanges['70-79'] = scoreRanges['70-79']! + 1;
      else if (s >= 60) scoreRanges['60-69'] = scoreRanges['60-69']! + 1;
      else scoreRanges['<60'] = scoreRanges['<60']! + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),

        // KPI Cards
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                'Total Candidates',
                '$total',
                Icons.people_outline,
                const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                'Avg Match Score',
                '${avgScore.toStringAsFixed(1)}%',
                Icons.analytics_outlined,
                const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                'High Performers',
                '$highPerformers',
                Icons.star_outline,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                'Nationalities',
                '${nationalityMap.length}',
                Icons.public_outlined,
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Charts Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildScoreDistribution(scoreRanges),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildTopNationalities(nationalityMap),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(Map<String, int> scoreRanges) {
    final maxValue = scoreRanges.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Score Distribution',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Icon(Icons.bar_chart, size: 16, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 20),
          ...scoreRanges.entries.map((e) {
            final percentage = maxValue > 0 ? (e.value / maxValue) : 0.0;
            Color barColor;
            if (e.key == '90-100') barColor = const Color(0xFF10B981);
            else if (e.key == '80-89') barColor = const Color(0xFF3B82F6);
            else if (e.key == '70-79') barColor = const Color(0xFF8B5CF6);
            else if (e.key == '60-69') barColor = const Color(0xFFF59E0B);
            else barColor = const Color(0xFFEF4444);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      e.key,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: barColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${e.value}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopNationalities(Map<String, int> nationalityMap) {
    final sorted = nationalityMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();
    final total = nationalityMap.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Top Nationalities',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Icon(Icons.public, size: 16, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 20),
          if (top5.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No data',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            ...top5.map((e) {
              final percentage = total > 0 ? (e.value / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilters(Shortlisting_provider prov) {
    final natList = ['All', ...prov.nationalityOptions.toList()..sort()];
    final sortOpts = ['None', 'Name A→Z', 'Name Z→A', 'Score High→Low'];

    return Row(
      children: [
        Expanded(child: _buildSearchField(prov)),
        const SizedBox(width: 12),
        _buildDropdown(
          value: prov.selectedNationality ?? 'All',
          items: natList,
          width: 180,
          onChanged: (v) => prov.setNationalityFilter(v == 'All' ? null : v),
        ),
        const SizedBox(width: 12),
        _buildDropdown(
          value: prov.sortOption,
          items: sortOpts,
          width: 180,
          onChanged: prov.setSortOption,
        ),
        if (_hasFilters(prov)) ...[
          const SizedBox(width: 12),
          _buildClearBtn(prov),
        ],
      ],
    );
  }

  bool _hasFilters(Shortlisting_provider prov) =>
      prov.searchQuery.isNotEmpty ||
          (prov.selectedNationality != null && prov.selectedNationality!.isNotEmpty) ||
          prov.sortOption != 'None';

  Widget _buildSearchField(Shortlisting_provider prov) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: prov.setSearch,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search candidates...',
          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
          suffixIcon: prov.searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
            onPressed: () {
              _searchCtrl.clear();
              prov.setSearch('');
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required double width,
    required Function(String) onChanged,
  }) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildClearBtn(Shortlisting_provider prov) {
    return TextButton.icon(
      onPressed: () {
        _searchCtrl.clear();
        prov.clearSelection();
      },
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Clear'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(80, 40),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF334155)),
          const SizedBox(height: 16),
          Text('Loading candidates...', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildCandidatesSection(Shortlisting_provider prov) {
    final list = prov.searchQuery.isEmpty ? prov.candidates : prov.filtered;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No candidates found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
              const SizedBox(height: 8),
              Text('Try adjusting your filters', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(list.length),
        const SizedBox(height: 16),
        _buildTable(prov, list),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.list_alt, size: 18, color: const Color(0xFF334155)),
          const SizedBox(width: 12),
          Text('$count ${count == 1 ? 'Candidate' : 'Candidates'}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildTable(Shortlisting_provider prov, List<Candidate> list) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (ctx, i) => _buildRow(ctx, list[i], prov),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 60),
          _headerCell('Name', flex: 2),
          _headerCell('Email', flex: 2),
          _headerCell('Phone', flex: 2),
          _headerCell('Nationality', flex: 2),
          _headerCell('Match', flex: 1),
          const SizedBox(width: 100),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), letterSpacing: 0.3)),
    );
  }

  Widget _buildRow(BuildContext context, Candidate c, Shortlisting_provider prov) {
    final selected = prov.selectedUids.contains(c.uid);
    return InkWell(
      onTap: () => prov.toggleSelection(c.uid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: selected ? const Color(0xFFF8FAFC) : Colors.white,
        child: Row(
          children: [
            _buildAvatar(c),
            const SizedBox(width: 12),
            _cell(c.name, flex: 2),
            _cell(_maskEmail(c.email), flex: 2),
            _cell(_maskPhone(c.phone), flex: 2),
            _cell(c.nationality, flex: 2),
            _buildMatchScoreCell(c),
            SizedBox(width: 100, child: _buildViewBtn(context, c, prov)),
            SizedBox(width: 40, child: Checkbox(value: selected, onChanged: (v) => prov.toggleSelection(c.uid, value: v), activeColor: const Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchScoreCell(Candidate c) {
    if (c.matchScore == null) {
      return Expanded(flex: 1, child: Text('—', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))));
    }
    final overallScore = c.matchScore!['overall_score'] ?? c.matchScore!['overallScore'] ?? 0;
    final score = (overallScore is num) ? overallScore.toDouble() : 0.0;
    Color scoreColor;
    if (score >= 80) scoreColor = const Color(0xFF10B981);
    else if (score >= 60) scoreColor = const Color(0xFF3B82F6);
    else scoreColor = const Color(0xFFF59E0B);

    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: scoreColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text('${score.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: scoreColor)),
      ),
    );
  }

  Widget _buildAvatar(Candidate c) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        image: c.pictureUrl.isNotEmpty ? DecorationImage(image: NetworkImage(c.pictureUrl), fit: BoxFit.cover) : null,
      ),
      child: c.pictureUrl.isEmpty ? const Icon(Icons.person, size: 18, color: Color(0xFF64748B)) : null,
    );
  }

  Widget _cell(String text, {int flex = 1}) {
    return Expanded(flex: flex, child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis));
  }

  Widget _buildViewBtn(BuildContext ctx, Candidate c, Shortlisting_provider prov) {
    return TextButton(
      onPressed: () async {
        final profile = await prov.fetchProfile(c.uid);
        if (ctx.mounted) {
          showDialog(context: ctx, builder: (_) => CandidateDetailsDialog(candidate: c, profile: profile));
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF1E293B),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(80, 32),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: const Text('View'),
    );
  }

  Widget _buildActionBar(Shortlisting_provider prov) {
    return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF334155)),
                    const SizedBox(width: 8),
                    Text('${prov.selectedUids.length} selected', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _handleSend(prov),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send to Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
            ),
    );
  }

  Future<void> _handleSend(Shortlisting_provider prov) async {
    final id = await prov.sendSelectedCandidatesToAdmin(notes: 'Sent from dashboard');
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          id != null ? 'Success' : 'Error',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          id != null
              ? 'Request submitted successfully.\nID: $id'
              : 'Failed to send request.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}