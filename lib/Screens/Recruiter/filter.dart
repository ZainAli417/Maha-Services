import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'LIst_of_Applicants_provider.dart';

/// 🎯 COMPREHENSIVE FILTER WIDGET - 15 REAL FILTERS
/// Simply drop this widget anywhere and it will automatically filter applicants
class ApplicantFilterWidget extends StatefulWidget {
  final VoidCallback? onFilterApplied;

  const ApplicantFilterWidget({
    super.key,
    this.onFilterApplied,
  });

  @override
  State<ApplicantFilterWidget> createState() => _ApplicantFilterWidgetState();
}

class _ApplicantFilterWidgetState extends State<ApplicantFilterWidget> {
  // Local state for filters before applying
  String _tempStatusFilter = 'All';
  String _tempJobFilter = 'All';
  String _tempExperienceFilter = 'All';
  String _tempLocationFilter = 'All';
  String _tempEducationFilter = 'All';
  String _tempNationalityFilter = 'All';
  String _tempProfessionalStatusFilter = 'All';
  List<String> _tempSkillsFilter = [];
  DateTimeRange? _tempDateRange;
  RangeValues _tempExperienceYearsRange = RangeValues(0, 30);
  bool _tempHasCertifications = false;
  bool _tempHasPublications = false;
  bool _tempHasAwards = false;
  String _tempRetirementStatusFilter = 'All';
  String _tempSortBy = 'applied_desc';

  int _activeFiltersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    final provider = context.read<ApplicantsProvider>();
    setState(() {
      _tempStatusFilter = provider.statusFilter;
      _tempJobFilter = provider.jobFilter;
      _tempExperienceFilter = provider.experienceFilter;
      _tempLocationFilter = provider.locationFilter;
      _tempEducationFilter = provider.educationFilter;
      _tempSkillsFilter = List.from(provider.skillsFilter);
      _tempDateRange = provider.appliedDateRange;
      _tempSortBy = provider.sortBy;
      _calculateActiveFilters();
    });
  }

  void _calculateActiveFilters() {
    _activeFiltersCount = 0;
    if (_tempStatusFilter != 'All') _activeFiltersCount++;
    if (_tempJobFilter != 'All') _activeFiltersCount++;
    if (_tempExperienceFilter != 'All') _activeFiltersCount++;
    if (_tempLocationFilter != 'All') _activeFiltersCount++;
    if (_tempEducationFilter != 'All') _activeFiltersCount++;
    if (_tempNationalityFilter != 'All') _activeFiltersCount++;
    if (_tempProfessionalStatusFilter != 'All') _activeFiltersCount++;
    if (_tempSkillsFilter.isNotEmpty) _activeFiltersCount++;
    if (_tempDateRange != null) _activeFiltersCount++;
    if (_tempExperienceYearsRange.start > 0 || _tempExperienceYearsRange.end < 30) _activeFiltersCount++;
    if (_tempHasCertifications) _activeFiltersCount++;
    if (_tempHasPublications) _activeFiltersCount++;
    if (_tempHasAwards) _activeFiltersCount++;
    if (_tempRetirementStatusFilter != 'All') _activeFiltersCount++;
  }

  void _applyFilters() {
    final provider = context.read<ApplicantsProvider>();

    provider.updateStatusFilter(_tempStatusFilter);
    provider.updateJobFilter(_tempJobFilter);
    provider.updateExperienceFilter(_tempExperienceFilter);
    provider.updateLocationFilter(_tempLocationFilter);
    provider.updateEducationFilter(_tempEducationFilter);
    provider.updateNationalityFilter(_tempNationalityFilter);
    provider.updateProfessionalStatusFilter(_tempProfessionalStatusFilter);
    provider.updateSkillsFilter(_tempSkillsFilter);
    provider.updateAppliedDateRange(_tempDateRange);
    provider.updateExperienceYearsRange(_tempExperienceYearsRange);
    provider.updateHasCertifications(_tempHasCertifications);
    provider.updateHasPublications(_tempHasPublications);
    provider.updateHasAwards(_tempHasAwards);
    provider.updateRetirementStatusFilter(_tempRetirementStatusFilter);
    provider.updateSorting(_tempSortBy);

    widget.onFilterApplied?.call();
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _tempStatusFilter = 'All';
      _tempJobFilter = 'All';
      _tempExperienceFilter = 'All';
      _tempLocationFilter = 'All';
      _tempEducationFilter = 'All';
      _tempNationalityFilter = 'All';
      _tempProfessionalStatusFilter = 'All';
      _tempSkillsFilter.clear();
      _tempDateRange = null;
      _tempExperienceYearsRange = RangeValues(0, 30);
      _tempHasCertifications = false;
      _tempHasPublications = false;
      _tempHasAwards = false;
      _tempRetirementStatusFilter = 'All';
      _tempSortBy = 'applied_desc';
      _calculateActiveFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer<ApplicantsProvider>(
              builder: (context, provider, _) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FILTER 1: Application Status
                      _buildFilterSection(
                        'Application Status',
                        Icons.assignment_turned_in,
                        _buildDropdownFilter(
                          value: _tempStatusFilter,
                          items: ['All', 'Pending', 'Shortlist', 'Rejected', 'Accepted'],
                          onChanged: (val) => setState(() {
                            _tempStatusFilter = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 2: Job Position
                      _buildFilterSection(
                        'Job Position',
                        Icons.work_outline,
                        _buildDropdownFilter(
                          value: _tempJobFilter,
                          items: ['All', ...provider.availableJobs.toList()],
                          onChanged: (val) => setState(() {
                            _tempJobFilter = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 3: Experience Level
                      _buildFilterSection(
                        'Experience Level',
                        Icons.workspace_premium,
                        _buildDropdownFilter(
                          value: _tempExperienceFilter,
                          items: ['All', 'Entry Level', '1-2 years', '3-5 years', '6-10 years', '10+ years'],
                          onChanged: (val) => setState(() {
                            _tempExperienceFilter = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 4: Experience Years Range
                      _buildFilterSection(
                        'Years of Experience (${_tempExperienceYearsRange.start.round()}-${_tempExperienceYearsRange.end.round()} years)',
                        Icons.trending_up,
                        RangeSlider(
                          values: _tempExperienceYearsRange,
                          min: 0,
                          max: 30,
                          divisions: 30,
                          activeColor: Color(0xFF8B5CF6),
                          labels: RangeLabels(
                            _tempExperienceYearsRange.start.round().toString(),
                            _tempExperienceYearsRange.end.round().toString(),
                          ),
                          onChanged: (values) => setState(() {
                            _tempExperienceYearsRange = values;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 5: Location
                      _buildFilterSection(
                        'Location',
                        Icons.location_on_outlined,
                        _buildDropdownFilter(
                          value: _tempLocationFilter,
                          items: ['All', ...provider.availableLocations.toList()],
                          onChanged: (val) => setState(() {
                            _tempLocationFilter = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 6: Education
                      _buildFilterSection(
                        'Education',
                        Icons.school_outlined,
                        _buildDropdownFilter(
                          value: _tempEducationFilter,
                          items: ['All', ...provider.availableEducations.toList()],
                          onChanged: (val) => setState(() {
                            _tempEducationFilter = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 7: Nationality
                      _buildFilterSection(
                        'Nationality',
                        Icons.flag_outlined,
                        _buildDropdownFilter(
                          value: _tempNationalityFilter,
                          items: ['All', ...provider.availableNationalities.toList()],
                          onChanged: (val) => setState(() {
                            _tempNationalityFilter = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 8: Professional Status
                      _buildFilterSection(
                        'Professional Status',
                        Icons.badge_outlined,
                        _buildDropdownFilter(
                          value: _tempProfessionalStatusFilter,
                          items: ['All', 'Serving', 'Retired', 'Available'],
                          onChanged: (val) => setState(() {
                            _tempProfessionalStatusFilter = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 9: Retirement Status
                      _buildFilterSection(
                        'Retirement Timeline',
                        Icons.event_available,
                        _buildDropdownFilter(
                          value: _tempRetirementStatusFilter,
                          items: ['All', 'Within 1 Year', '1-3 Years', '3-5 Years', '5+ Years'],
                          onChanged: (val) => setState(() {
                            _tempRetirementStatusFilter = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),

                      // FILTER 10: Skills (Multi-select)
                      _buildFilterSection(
                        'Required Skills (${_tempSkillsFilter.length} selected)',
                        Icons.psychology_outlined,
                        _buildSkillsSelector(provider.availableSkills.toList()),
                      ),

                      // FILTER 11: Has Certifications
                      _buildFilterSection(
                        'Certifications',
                        Icons.verified_outlined,
                        CheckboxListTile(
                          title: Text('Only candidates with certifications', style: GoogleFonts.poppins(fontSize: 14)),
                          value: _tempHasCertifications,
                          activeColor: Color(0xFF8B5CF6),
                          onChanged: (val) => setState(() {
                            _tempHasCertifications = val ?? false;
                            _calculateActiveFilters();
                          }),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),

                      // FILTER 12: Has Publications
                      _buildFilterSection(
                        'Publications',
                        Icons.article_outlined,
                        CheckboxListTile(
                          title: Text('Only candidates with publications', style: GoogleFonts.poppins(fontSize: 14)),
                          value: _tempHasPublications,
                          activeColor: Color(0xFF8B5CF6),
                          onChanged: (val) => setState(() {
                            _tempHasPublications = val ?? false;
                            _calculateActiveFilters();
                          }),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),

                      // FILTER 13: Has Awards
                      _buildFilterSection(
                        'Awards & Recognition',
                        Icons.emoji_events_outlined,
                        CheckboxListTile(
                          title: Text('Only candidates with awards', style: GoogleFonts.poppins(fontSize: 14)),
                          value: _tempHasAwards,
                          activeColor: Color(0xFF8B5CF6),
                          onChanged: (val) => setState(() {
                            _tempHasAwards = val ?? false;
                            _calculateActiveFilters();
                          }),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),

                      // FILTER 14: Application Date Range
                      _buildFilterSection(
                        'Application Date Range',
                        Icons.date_range,
                        _buildDateRangeSelector(),
                      ),

                      // FILTER 15: Sort By
                      _buildFilterSection(
                        'Sort By',
                        Icons.sort,
                        _buildDropdownFilter(
                          value: _tempSortBy,
                          items: [
                            'applied_desc',
                            'applied_asc',
                            'name_asc',
                            'name_desc',
                            'experience_desc',
                          ],
                          itemLabels: {
                            'applied_desc': 'Newest First',
                            'applied_asc': 'Oldest First',
                            'name_asc': 'Name (A-Z)',
                            'name_desc': 'Name (Z-A)',
                            'experience_desc': 'Most Experienced',
                          },
                          onChanged: (val) => setState(() {
                            _tempSortBy = val!;
                            _calculateActiveFilters();
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.filter_list, color: Color(0xFF8B5CF6), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_activeFiltersCount} filters active',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon, Widget content) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    Map<String, String>? itemLabels,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF0F172A)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(itemLabels?[item] ?? item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSkillsSelector(List<String> availableSkills) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableSkills.take(15).map((skill) {
        final isSelected = _tempSkillsFilter.contains(skill);
        return FilterChip(
          label: Text(skill),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _tempSkillsFilter.add(skill);
              } else {
                _tempSkillsFilter.remove(skill);
              }
              _calculateActiveFilters();
            });
          },
          backgroundColor: Color(0xFFF8FAFC),
          selectedColor: Color(0xFF8B5CF6).withOpacity(0.2),
          checkmarkColor: Color(0xFF8B5CF6),
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: isSelected ? Color(0xFF8B5CF6) : Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          side: BorderSide(
            color: isSelected ? Color(0xFF8B5CF6) : Color(0xFFE2E8F0),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSelector() {
    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _tempDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: Color(0xFF8B5CF6)),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          setState(() {
            _tempDateRange = range;
            _calculateActiveFilters();
          });
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B)),
            SizedBox(width: 12),
            Text(
              _tempDateRange == null
                  ? 'Select date range'
                  : '${_tempDateRange!.start.toString().split(' ')[0]} - ${_tempDateRange!.end.toString().split(' ')[0]}',
              style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF0F172A)),
            ),
            Spacer(),
            if (_tempDateRange != null)
              IconButton(
                icon: Icon(Icons.clear, size: 18),
                onPressed: () => setState(() {
                  _tempDateRange = null;
                  _calculateActiveFilters();
                }),
                color: Color(0xFF64748B),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Reset All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

