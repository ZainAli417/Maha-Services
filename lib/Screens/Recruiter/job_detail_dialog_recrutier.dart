import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'Recruiter_provider_Job_listing.dart';

class JobDetailModal_recruiter extends StatelessWidget {
  final Map<String, dynamic> jobData;

  const JobDetailModal_recruiter({
    super.key,
    required this.jobData,
  });

  // --- Professional Color Palette (Slate & Indigo) ---
  static const Color _bgSurface = Colors.white;
  static const Color _bgBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color _textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color _textSecondary = Color(0xFF64748B); // Slate 500
  static const Color _accentPrimary = Color(0xFF4F46E5); // Indigo 600
  static const Color _borderColor = Color(0xFFE2E8F0); // Slate 200
  static const Color _dangerColor = Color(0xFFEF4444); // Red 500
  static const Color _successColor = Color(0xFF10B981); // Emerald 500

  @override
  Widget build(BuildContext context) {
    // Responsive width control

    return Dialog(
      backgroundColor: _bgSurface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0, // Flat design
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          color: _bgSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            // 1. Professional Header
            _buildHeader(context),
            const Divider(height: 1, color: _borderColor),

            // 2. Scrollable Content
            Expanded(
              child: Container(
                color: _bgBackground,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Meta Row
                      _buildMetaRow(),
                      const SizedBox(height: 24),

                      // Main Content Area
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // About the Role
                          _buildSectionTitle('About the Role'),
                          _buildRichText(jobData['description'] ?? 'No description provided.'),
                          const SizedBox(height: 24),

                          // Key Responsibilities
                          _buildSectionTitle('Key Responsibilities'),
                          _buildRichText(jobData['responsibilities'] ?? 'Not specified.'),
                          const SizedBox(height: 24),

                          // Qualifications
                          _buildSectionTitle('Qualifications'),
                          _buildRichText(jobData['qualifications'] ?? 'Not specified.'),
                          const SizedBox(height: 32),

                          // Horizontal Cards Section (Perks, Benefits, etc.)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 550, // Fixed width for each card
                                  child: _buildSidebarDetails(),
                                ),
                                // Add more cards here if needed
                                // const SizedBox(width: 16),
                                // SizedBox(width: 300, child: _buildAnotherCard()),
                              ],
                            ),
                          ),
                        ],
                      )
                      // Mobile: Show sidebar content at bottom
                      // if (!isDesktop) ...[
                      //   const SizedBox(height: 32),
                      //   const Divider(color: _borderColor),
                      //   const SizedBox(height: 24),
                      //   _buildSidebarDetails(),
                      // ],
                    ],
                  ),
                ),
              ),
            ),

            // 3. Sticky Action Footer
            const Divider(height: 1, color: _borderColor),
            _buildFooterActions(context),
          ],
        ),
      ),
    );
  }

  // --- Header Section ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: jobData['logoUrl'] != null && jobData['logoUrl'].isNotEmpty
                  ? Image.network(jobData['logoUrl'], fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.business, color: _textSecondary)),
            ),
          ),
          const SizedBox(width: 16),
          // Title & Company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobData['title'] ?? 'Untitled Position',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jobData['company'] ?? 'Unknown Company',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Close Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: _textSecondary),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  // --- Meta Row (Salary, Type, Location) ---
  Widget _buildMetaRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildMetaItem(Icons.payments_outlined, 'Salary',
                jobData['salary'] ?? jobData['pay'] ?? 'Not disclosed'),
            const VerticalDivider(color: _borderColor, width: 32),
            _buildMetaItem(Icons.work_outline, 'Job Type',
                jobData['nature'] ?? 'Full-time'),
            const VerticalDivider(color: _borderColor, width: 32),
            _buildMetaItem(Icons.location_on_outlined, 'Location',
                jobData['location'] ?? 'Remote'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _textSecondary),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
          ),
        ],
      ),
    );
  }

  // --- Sidebar Widgets ---
  Widget _buildSidebarDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skills Card
        _buildSidebarCard(
          title: 'Required Skills',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (jobData['skills'] as List<dynamic>? ?? [])
                .map((e) => _buildChip(e.toString(), _accentPrimary))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Work Mode Card
        _buildSidebarCard(
          title: 'Work Arrangements',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (jobData['workModes'] as List<dynamic>? ?? [])
                .map((e) => _buildChip(e.toString(), Colors.orange.shade700))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Benefits Card
        _buildSidebarCard(
          title: 'Perks & Benefits',
          child: Column(
            children: (jobData['benefits'] as List<dynamic>? ?? [])
                .map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 16, color: _successColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.toString(), style: GoogleFonts.inter(fontSize: 13, color: _textPrimary))),
                ],
              ),
            ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Additional Info
        _buildSidebarCard(
          title: 'Additional Info',
          child: Column(
            children: [
              _buildInfoRow('Department', jobData['department']),
              _buildInfoRow('Experience', jobData['experience']),
              _buildInfoRow('Deadline', jobData['deadline']),
              _buildInfoRow('Contact', jobData['contactEmail']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // --- Admin Footer ---
  Widget _buildFooterActions(BuildContext context) {
    final status = jobData['status'] as String? ?? 'active';
    final jobId = jobData['id'] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Status Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _bgBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Text(
                  'Job Status:',
                  style: GoogleFonts.inter(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: status == 'active',
                  activeColor: _successColor,
                  onChanged: (val) async {
                    final provider = Provider.of<job_listing_provider>(context, listen: false);
                    final error = await provider.toggleJobStatus(jobId, status);
                    if (error == null) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(val ? 'Job Activated' : 'Job Paused'), backgroundColor: _textPrimary));
                    }
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'active' ? 'Active' : 'Paused',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: status == 'active' ? _successColor : _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Delete Button
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Archive Job'),
                  content: const Text('Are you sure?.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Archive', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                final provider = Provider.of<job_listing_provider>(context, listen: false);
                await provider.deleteJob(jobId);
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.dark_mode_outlined, size: 20, color: _dangerColor),
            label: Text('Archive Job', style: GoogleFonts.inter(color: _dangerColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      ),
    );
  }

  Widget _buildRichText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        height: 1.6,
        color: const Color(0xFF334155), // Slate 700
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: _textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}