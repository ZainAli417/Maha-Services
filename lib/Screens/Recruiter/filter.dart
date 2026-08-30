import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'LIst_of_Applicants_provider.dart';

// ─── Tokens ────────────────────────────────────────────────────────────────
class _F {
  static const primary = Color(0xFF6D28D9);
  static const primaryLt = Color(0xFFF3EEFF);
  static const txt = Color(0xFF0B2239);
  static const txtSec = Color(0xFF5E7A8E);
  static const txtTert = Color(0xFF8AA5B5);
  static const border = Color(0xFFDCE7EF);
  static const bg = Color(0xFFF4F9FB);
  static const surface = Colors.white;

  static TextStyle t(double s, {FontWeight w = FontWeight.w500, Color? c}) =>
      GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c ?? txt);
}

/// The applicant filter sheet.
///
/// Filters are held locally while the sheet is open and only pushed to the
/// provider on Apply. That is what lets the sheet show a live "Show N
/// candidates" count — the recruiter finds out a combination returns nobody
/// before they commit to it, not after the list goes blank.
class ApplicantFilterWidget extends StatefulWidget {
  const ApplicantFilterWidget({super.key, this.onFilterApplied, this.scope});

  final VoidCallback? onFilterApplied;

  /// The list the filters will actually narrow.
  ///
  /// The shortlist screen passes the people already shortlisted for one job;
  /// null means the whole applicant pool. Without this the sheet counts
  /// against everyone and promises a number the screen cannot deliver.
  final List<ApplicantRecord>? scope;

  @override
  State<ApplicantFilterWidget> createState() => _ApplicantFilterWidgetState();
}

class _ApplicantFilterWidgetState extends State<ApplicantFilterWidget> {
  // ── Draft filter state ──
  String _status = 'All';
  String _job = 'All';
  String _country = 'All';
  String _location = 'All';
  String _education = 'All';
  String _nationality = 'All';
  String _professionalStatus = 'All';
  String _retirement = 'All';
  String _sort = 'applied_desc';

  Set<String> _roles = {};
  Set<String> _aircraft = {};
  Set<String> _licences = {};
  Set<String> _degrees = {};
  List<String> _skills = [];

  num _minHours = 0;
  num _minYears = 0;
  String _testStage = 'All';
  num _minAi = 0;
  num _minTest = 0;
  bool _matchAll = false;
  bool _unreviewed = false;
  bool _certs = false;
  bool _pubs = false;
  bool _awards = false;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final p = context.read<ApplicantsProvider>();
    _status = p.statusFilter;
    _job = p.jobFilter;
    _country = p.countryFilter;
    _location = p.locationFilter;
    _education = p.educationFilter;
    _nationality = p.nationalityFilter;
    _professionalStatus = p.professionalStatusFilter;
    _retirement = p.retirementStatusFilter;
    _sort = p.sortBy;
    _roles = {...p.roleFilter};
    _aircraft = {...p.aircraftFilter};
    _licences = {...p.licenceFilter};
    _degrees = {...p.degreeFilter};
    _skills = [...p.skillsFilter];
    _minHours = p.minFlightHours;
    _minYears = p.minYears;
    _testStage = p.testStage;
    _minAi = p.minAiScore;
    _minTest = p.minTestScore;
    _matchAll = p.matchAll;
    _unreviewed = p.unreviewedOnly;
    _certs = p.hasCertifications;
    _pubs = p.hasPublications;
    _awards = p.hasAwards;
    _dateRange = p.appliedDateRange;
  }

  /// How many filters the recruiter has actually set — drives the badge and
  /// tells them whether Reset will do anything.
  int get _activeCount => [
        _status != 'All',
        _job != 'All',
        _country != 'All',
        _location != 'All',
        _education != 'All',
        _nationality != 'All',
        _professionalStatus != 'All',
        _retirement != 'All',
        _roles.isNotEmpty,
        _aircraft.isNotEmpty,
        _licences.isNotEmpty,
        _degrees.isNotEmpty,
        _skills.isNotEmpty,
        _minHours > 0,
        _minYears > 0,
        _testStage != 'All',
        _minAi > 0,
        _minTest > 0,
        _unreviewed,
        _certs,
        _pubs,
        _awards,
        _dateRange != null,
      ].where((x) => x).length;

  int _preview(ApplicantsProvider p) => p.previewCountIn(
        widget.scope ?? p.allApplicants,
        roles: _roles,
        aircraft: _aircraft,
        licences: _licences,
        degrees: _degrees,
        skills: _skills,
        status: _status,
        job: _job,
        country: _country,
        education: _education,
        nationality: _nationality,
        professionalStatus: _professionalStatus,
        retirement: _retirement,
        minHours: _minHours,
        minYearsValue: _minYears,
        testStageValue: _testStage,
        minAi: _minAi,
        minTest: _minTest,
        certs: _certs,
        pubs: _pubs,
        awards: _awards,
        unreviewed: _unreviewed,
        all: _matchAll,
        dateRange: _dateRange,
      );

  void _apply() {
    final p = context.read<ApplicantsProvider>()
      ..updateStatusFilter(_status)
      ..updateJobFilter(_job)
      ..updateCountryFilter(_country)
      ..updateLocationFilter(_location)
      ..updateEducationFilter(_education)
      ..updateNationalityFilter(_nationality)
      ..updateProfessionalStatusFilter(_professionalStatus)
      ..updateRetirementStatusFilter(_retirement)
      ..updateRoleFilter(_roles)
      ..updateAircraftFilter(_aircraft)
      ..updateLicenceFilter(_licences)
      ..updateDegreeFilter(_degrees)
      ..updateSkillsFilter(_skills)
      ..updateMinFlightHours(_minHours)
      ..updateMinYears(_minYears)
      ..updateTestStage(_testStage)
      ..updateMinAiScore(_minAi)
      ..updateMinTestScore(_minTest)
      ..updateMatchAll(_matchAll)
      ..updateUnreviewedOnly(_unreviewed)
      ..updateHasCertifications(_certs)
      ..updateHasPublications(_pubs)
      ..updateHasAwards(_awards)
      ..updateAppliedDateRange(_dateRange)
      ..updateSorting(_sort);
    p.updateSorting(_sort);
    widget.onFilterApplied?.call();
    Navigator.of(context).pop();
  }

  void _reset() => setState(() {
        _status = _job = _country = _location = 'All';
        _education = _nationality = _professionalStatus = _retirement = 'All';
        _sort = 'applied_desc';
        _roles = {};
        _aircraft = {};
        _licences = {};
        _degrees = {};
        _skills = [];
        _minHours = 0;
        _minYears = 0;
        _testStage = 'All';
        _minAi = 0;
        _minTest = 0;
        _matchAll = false;
        _unreviewed = _certs = _pubs = _awards = false;
        _dateRange = null;
      });

  /// One-tap combinations that answer a question a recruiter actually has.
  ///
  /// Each is a shortcut for filters that already exist, so nothing here can
  /// return a result the manual controls could not.
  void _applyPreset(String preset, ApplicantsProvider p) {
    setState(() {
      _reset();
      switch (preset) {
        case 'unreviewed':
          _unreviewed = true;
        case 'high_hours':
          // Half the best figure in the pool: a threshold that stays sensible
          // whether these are 200-hour cadets or 5,000-hour captains.
          // Half the best figure in the pool, per unit — a threshold that
          // stays sensible whether these are 200-hour cadets or 5,000-hour
          // captains, and does not compare hours against years.
          _minHours = (p.maxFlightHoursSeen / 2).floorToDouble();
          _minYears = (p.maxYearsSeen / 2).floorToDouble();
        case 'type_rated':
          _licences = {...p.availableLicences};
        case 'recent':
          final now = DateTime.now();
          _dateRange = DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          );
        case 'decorated':
          _awards = true;
        case 'graduates':
          _degrees = {...p.availableDegrees};
        case 'passed_test':
          _testStage = 'Passed';
        case 'awaiting_test':
          // Invited but not finished — who to chase before the 24 hours run
          // out, which is the question the day after a batch goes out.
          _testStage = 'In progress';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ApplicantsProvider>();
    final count = _preview(p);
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 768;

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      decoration: const BoxDecoration(
        color: _F.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const Divider(height: 1, color: _F.border),
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 22,
                16,
                isMobile ? 16 : 22,
                16,
              ),
              children: [
                _presets(p),
                const SizedBox(height: 18),

                _section('Quick filters', Icons.bolt_rounded, [
                  _switchRow(
                    'Not yet sent to admin',
                    'Hides candidates already in a request',
                    _unreviewed,
                    (v) => setState(() => _unreviewed = v),
                  ),
                  _switchRow(
                    'Match all selections',
                    _matchAll
                        ? 'A candidate must have every value you pick'
                        : 'A candidate needs any one of the values you pick',
                    _matchAll,
                    (v) => setState(() => _matchAll = v),
                  ),
                ]),

                _section('Role & application', Icons.badge_outlined, [
                  _chips(
                    'Target role',
                    p.availableRoles,
                    _roles,
                    (v) => setState(() => _roles = v),
                  ),
                  _dropdown('Applied to job', _job, p.availableJobs,
                      (v) => setState(() => _job = v)),
                  _dropdown(
                    'Application status',
                    _status,
                    const {'pending', 'shortlist', 'accepted', 'rejected'},
                    (v) => setState(() => _status = v),
                  ),
                  _dateRow(context),
                ]),

                _section('Qualifications', Icons.workspace_premium_outlined, [
                  _chips(
                    'Licences & ratings',
                    p.availableLicences,
                    _licences,
                    (v) => setState(() => _licences = v),
                  ),
                  _chips(
                    'Aircraft types',
                    p.availableAircraft,
                    _aircraft,
                    (v) => setState(() => _aircraft = v),
                  ),
                  _chips(
                    'Skills & competencies',
                    p.availableSkills,
                    _skills.toSet(),
                    (v) => setState(() => _skills = v.toList()),
                  ),
                ]),

                _section('Experience', Icons.insights_outlined, [
                  _metricSlider(p),
                  _dropdown(
                    'Service status',
                    _professionalStatus,
                    const {'serving', 'retired', 'civilian'},
                    (v) => setState(() => _professionalStatus = v),
                  ),
                  _dropdown(
                    'Retiring within',
                    _retirement,
                    const {
                      'Within 1 Year',
                      '1-3 Years',
                      '3-5 Years',
                      '5+ Years',
                    },
                    (v) => setState(() => _retirement = v),
                  ),
                ]),

                _section('Assessment', Icons.quiz_outlined, [
                  _dropdown(
                    'Test stage',
                    _testStage,
                    const {
                      'Not invited',
                      'Invited',
                      'In progress',
                      'Completed',
                      'Expired',
                      'Passed',
                      'Failed',
                    },
                    (v) => setState(() => _testStage = v),
                  ),
                  // Both thresholds treat a missing score as "not judged"
                  // rather than as zero, so raising either one hides
                  // candidates nobody has assessed instead of ranking them
                  // last. The hint says so, because that is surprising.
                  _threshold(
                    label: 'Minimum AI match score',
                    hint: 'Hides candidates who have not been analysed',
                    value: _minAi,
                    ceiling: 100,
                    onChanged: (v) => setState(() => _minAi = v),
                  ),
                  _threshold(
                    label: 'Minimum test score (%)',
                    hint: 'Hides candidates whose score has not been released',
                    value: _minTest,
                    ceiling: 100,
                    onChanged: (v) => setState(() => _minTest = v),
                  ),
                ]),

                _section('Education', Icons.school_outlined, [
                  _chips(
                    'Degree held',
                    p.availableDegrees,
                    _degrees,
                    (v) => setState(() => _degrees = v),
                  ),
                  _dropdown('Field of study', _education, p.availableEducations,
                      (v) => setState(() => _education = v)),
                ]),

                _section('Location', Icons.public_rounded, [
                  _dropdown('Country', _country, p.availableCountries,
                      (v) => setState(() => _country = v)),
                  _dropdown('City / region', _location, p.availableLocations,
                      (v) => setState(() => _location = v)),
                  _dropdown('Nationality', _nationality,
                      p.availableNationalities,
                      (v) => setState(() => _nationality = v)),
                ]),

                _section('Record', Icons.folder_open_outlined, [
                  _switchRow('Has certifications', null, _certs,
                      (v) => setState(() => _certs = v)),
                  _switchRow('Has publications', null, _pubs,
                      (v) => setState(() => _pubs = v)),
                  _switchRow('Has awards', null, _awards,
                      (v) => setState(() => _awards = v)),
                ]),

                _section('Sort', Icons.swap_vert_rounded, [
                  _sortPicker(),
                ]),
              ],
            ),
          ),
          _footer(count),
        ],
      ),
    );
  }

  // ── Chrome ──────────────────────────────────────────────────────────────

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _F.primaryLt,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.tune_rounded,
                  size: 18, color: _F.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Filter candidates',
                      style: _F.t(16, w: FontWeight.w800)),
                  Text(
                    _activeCount == 0
                        ? 'No filters applied'
                        : '$_activeCount filter${_activeCount == 1 ? '' : 's'} active',
                    style: _F.t(11, c: _F.txtTert),
                  ),
                ],
              ),
            ),
            if (_activeCount > 0)
              TextButton(
                onPressed: _reset,
                child: Text('Reset',
                    style: _F.t(12, w: FontWeight.w700, c: _F.primary)),
              ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded,
                  size: 20, color: _F.txtSec),
            ),
          ],
        ),
      );

  Widget _footer(int count) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _F.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: count == 0 ? null : _apply,
              style: FilledButton.styleFrom(
                backgroundColor: _F.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // A disabled button with an honest label beats an enabled one
              // that empties the list.
              child: Text(
                count == 0
                    ? 'No candidates match these filters'
                    : 'Show $count candidate${count == 1 ? '' : 's'}',
                style: _F.t(14, w: FontWeight.w700, c: Colors.white),
              ),
            ),
          ),
        ),
      );

  Widget _presets(ApplicantsProvider p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK PICKS',
              style: _F.t(10, w: FontWeight.w800, c: _F.txtTert)
                  .copyWith(letterSpacing: 0.7)),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _preset('New applicants', Icons.fiber_new_rounded,
                  () => _applyPreset('unreviewed', p)),
              _preset('Most experienced', Icons.trending_up_rounded,
                  () => _applyPreset('high_hours', p)),
              if (p.availableLicences.isNotEmpty)
                _preset('Licensed only', Icons.verified_outlined,
                    () => _applyPreset('type_rated', p)),
              _preset('Applied this week', Icons.schedule_rounded,
                  () => _applyPreset('recent', p)),
              _preset('Award winners', Icons.military_tech_outlined,
                  () => _applyPreset('decorated', p)),
              _preset('Passed the test', Icons.verified_rounded,
                  () => _applyPreset('passed_test', p)),
              _preset('Test in progress', Icons.hourglass_bottom_rounded,
                  () => _applyPreset('awaiting_test', p)),
              if (p.availableDegrees.isNotEmpty)
                _preset('Degree holders', Icons.school_outlined,
                    () => _applyPreset('graduates', p)),
            ],
          ),
        ],
      );

  Widget _preset(String label, IconData icon, VoidCallback onTap) =>
      Material(
        color: _F.bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _F.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: _F.primary),
                const SizedBox(width: 6),
                Text(label, style: _F.t(12, w: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  // ── Controls ────────────────────────────────────────────────────────────

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: _F.primary),
                const SizedBox(width: 7),
                Text(title.toUpperCase(),
                    style: _F.t(10, w: FontWeight.w800, c: _F.txtSec)
                        .copyWith(letterSpacing: 0.7)),
              ],
            ),
            const SizedBox(height: 11),
            ...children,
          ],
        ),
      );

  Widget _dropdown(
    String label,
    String value,
    Set<String> options,
    ValueChanged<String> onChanged,
  ) {
    if (options.isEmpty) return const SizedBox.shrink();
    final items = ['All', ...options.toList()..sort()];
    // A stale selection — an option that vanished when the data changed —
    // would make DropdownButton assert, so fall back to All.
    final safe = items.contains(value) ? value : 'All';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _F.t(11, w: FontWeight.w600, c: _F.txtSec)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: safe == 'All' ? _F.bg : _F.primaryLt,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: safe == 'All' ? _F.border : _F.primary),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safe,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(10),
                style: _F.t(13),
                items: [
                  for (final o in items)
                    DropdownMenuItem(
                      value: o,
                      child: Text(
                        o == 'All' ? 'Any' : o,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => onChanged(v ?? 'All'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(
    String label,
    Set<String> options,
    Set<String> selected,
    ValueChanged<Set<String>> onChanged,
  ) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: _F.t(11, w: FontWeight.w600, c: _F.txtSec)),
              const Spacer(),
              if (selected.isNotEmpty)
                GestureDetector(
                  onTap: () => onChanged({}),
                  child: Text('Clear',
                      style: _F.t(10, w: FontWeight.w700, c: _F.primary)),
                ),
            ],
          ),
          const SizedBox(height: 7),
          _ChipPicker(
            options: options.toList()..sort(),
            selected: selected,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _metricSlider(ApplicantsProvider p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two sliders, not one. Flight hours and years of service are
          // different units, and a candidate who has one usually does not have
          // the other — a pilot logs hours, an engineer logs years.
          _threshold(
            label: 'Minimum flight hours',
            hint: 'Only candidates who log flight time',
            value: _minHours,
            ceiling: p.maxFlightHoursSeen,
            onChanged: (v) => setState(() => _minHours = v),
          ),
          _threshold(
            label: 'Minimum years of experience',
            hint: 'Only candidates with years on record',
            value: _minYears,
            ceiling: p.maxYearsSeen,
            onChanged: (v) => setState(() => _minYears = v),
          ),
        ],
      );

  Widget _threshold({
    required String label,
    required String hint,
    required num value,
    required num ceiling,
    required ValueChanged<double> onChanged,
  }) {
    // Nobody in this pool records this measure, so the control would only ever
    // filter everyone out.
    if (ceiling <= 0) return const SizedBox.shrink();
    final max = ceiling.toDouble();
    final v = value.toDouble().clamp(0.0, max);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: _F.t(11, w: FontWeight.w600, c: _F.txtSec)),
              ),
              Text(
                v == 0 ? 'Any' : v.round().toString(),
                style: _F.t(12, w: FontWeight.w800, c: _F.primary),
              ),
            ],
          ),
          if (v > 0)
            Text(hint, style: _F.t(10, c: _F.txtTert)),
          Slider(
            value: v,
            max: max,
            divisions: max >= 20 ? 20 : max.round().clamp(1, 20),
            activeColor: _F.primary,
            label: v.round().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _switchRow(
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: _F.t(13, w: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle, style: _F.t(10.5, c: _F.txtTert)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: _F.primary,
            ),
          ],
        ),
      );

  Widget _dateRow(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Applied between',
                style: _F.t(11, w: FontWeight.w600, c: _F.txtSec)),
            const SizedBox(height: 5),
            InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 3),
                  lastDate: now,
                  initialDateRange: _dateRange,
                );
                if (picked != null) setState(() => _dateRange = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _dateRange == null ? _F.bg : _F.primaryLt,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: _dateRange == null ? _F.border : _F.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        size: 16, color: _F.txtSec),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _dateRange == null
                            ? 'Any date'
                            : '${_d(_dateRange!.start)} → ${_d(_dateRange!.end)}',
                        style: _F.t(13),
                      ),
                    ),
                    if (_dateRange != null)
                      GestureDetector(
                        onTap: () => setState(() => _dateRange = null),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: _F.txtSec),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  static String _d(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _sortPicker() {
    const options = {
      'applied_desc': 'Newest first',
      'applied_asc': 'Oldest first',
      'metric_desc': 'Most hours / years',
      'test_desc': 'Highest test score',
      'metric_asc': 'Fewest hours / years',
      'score_desc': 'Best AI match',
      'name_asc': 'Name A–Z',
      'name_desc': 'Name Z–A',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in options.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: _sort == e.key,
            onSelected: (_) => setState(() => _sort = e.key),
            labelStyle: _F.t(
              12,
              w: FontWeight.w600,
              c: _sort == e.key ? Colors.white : _F.txt,
            ),
            selectedColor: _F.primary,
            backgroundColor: _F.bg,
            side: BorderSide(
                color: _sort == e.key ? _F.primary : _F.border),
            showCheckmark: false,
          ),
      ],
    );
  }
}

/// A searchable chip list.
///
/// Aircraft and licence lists run to dozens of entries once a pool is real, so
/// the search box appears past a threshold rather than always — a six-item
/// list does not need one.
class _ChipPicker extends StatefulWidget {
  const _ChipPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_ChipPicker> createState() => _ChipPickerState();
}

class _ChipPickerState extends State<_ChipPicker> {
  static const _searchThreshold = 10;
  static const _collapsedLimit = 12;

  final _search = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final matching = q.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.toLowerCase().contains(q))
            .toList();

    // Selected values stay visible even when collapsed — a chip you cannot see
    // is a filter you forget you set.
    final visible = _expanded || matching.length <= _collapsedLimit
        ? matching
        : [
            ...matching.where(widget.selected.contains),
            ...matching
                .where((o) => !widget.selected.contains(o))
                .take(_collapsedLimit),
          ];
    final hidden = matching.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.options.length >= _searchThreshold) ...[
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: _F.t(12.5),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search ${widget.options.length} options…',
              hintStyle: _F.t(12.5, c: _F.txtTert),
              prefixIcon:
                  const Icon(Icons.search_rounded, size: 17, color: _F.txtTert),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              filled: true,
              fillColor: _F.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: _F.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: _F.border),
              ),
            ),
          ),
          const SizedBox(height: 9),
        ],
        if (visible.isEmpty)
          Text('Nothing matches "$q"', style: _F.t(12, c: _F.txtTert))
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final o in visible)
                _Chip(
                  label: o,
                  selected: widget.selected.contains(o),
                  onTap: () {
                    final next = {...widget.selected};
                    next.contains(o) ? next.remove(o) : next.add(o);
                    widget.onChanged(next);
                  },
                ),
            ],
          ),
        if (hidden > 0)
          TextButton(
            onPressed: () => setState(() => _expanded = true),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Show $hidden more',
                style: _F.t(11, w: FontWeight.w700, c: _F.primary)),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? _F.primary : _F.bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: selected ? _F.primary : _F.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: _F.t(
                    12,
                    w: FontWeight.w600,
                    c: selected ? Colors.white : _F.txt,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
