import 'aviation_catalogue.dart';
import 'models/aviation_role.dart';
import 'models/question.dart';
import 'option_catalog.dart';

/// Industries the role picker groups templates under.
class Industry {
  const Industry({
    required this.id,
    required this.title,
    required this.blurb,
  });

  final String id;
  final String title;
  final String blurb;
}

/// The role-template definition engine.
///
/// A template is a [RoleTemplate] whose questions carry `group` (the form
/// section), a structured [QuestionType], and a `mapsTo` path that projects the
/// answer onto [CandidateProfile]. High-density selection controls are the
/// default: raw text survives only where a value genuinely cannot be
/// enumerated (unit names, licence numbers, free narrative).
///
/// Reserved `mapsTo` paths (see `ProfileProjector`):
///   personalInfo.fullName | email | phone | summary
///   personalInfo.location.city | .country
///   personalInfo.citizenship | .workAuthorization
///   roleSpecificData.licensesAndRatings   → one LicenseEntry per value
///   roleSpecificData.licenseAuthority | licenseNumber | licenseExpiry
///   `roleSpecificData.flightHoursOrExperienceMetrics.<key>`
///   roleSpecificData.typeRatingsOrAircraftTypes
///   roleSpecificData.technicalCompetencies
///   roleSpecificData.toolsAndSystems
/// Anything else lands in `roleSpecificData.attributes.<questionId>`.
abstract final class RoleTemplateCatalogue {
  /// Bumped whenever the seeded templates change so an admin can re-seed.
  /// Bumped to 3: the phone field became [QuestionType.phone] and every
  /// document upload became optional. Published catalogues must be re-seeded
  /// from the admin panel for either change to reach existing environments.
  static const int seedVersion = 3;

  static const aviation = Industry(
    id: 'aviation',
    title: 'Aviation',
    blurb: 'Flight crew, engineering, safety, operations and ground services',
  );
  static const engineering = Industry(
    id: 'engineering',
    title: 'Engineering & Technology',
    blurb: 'Software, platform, data and quality engineering roles',
  );

  static const industries = [aviation, engineering];

  // ── Field factories ───────────────────────────────────────────────────────

  static OnboardingQuestion _text(
    String id,
    String label, {
    required String group,
    bool required = false,
    String? help,
    String? hint,
    String? mapsTo,
    String? dependsOnId,
    List<String> dependsOnValues = const [],
    int span = 1,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.text,
        group: group,
        required: required,
        helpText: help,
        placeholder: hint,
        mapsTo: mapsTo,
        dependsOnId: dependsOnId,
        dependsOnValues: dependsOnValues,
        span: span,
      );

  static OnboardingQuestion _long(
    String id,
    String label, {
    required String group,
    String? mapsTo,
    String? hint,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.longText,
        group: group,
        placeholder: hint,
        mapsTo: mapsTo,
        span: 2,
      );

  static OnboardingQuestion _num(
    String id,
    String label, {
    required String group,
    String? unit,
    num? min,
    num? max,
    bool required = false,
    String? help,
    String? mapsTo,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.number,
        group: group,
        unit: unit,
        min: min ?? 0,
        max: max,
        required: required,
        helpText: help,
        mapsTo: mapsTo,
      );

  static OnboardingQuestion _single(
    String id,
    String label,
    List<String> options, {
    required String group,
    bool required = false,
    String? help,
    String? mapsTo,
    String? dependsOnId,
    List<String> dependsOnValues = const [],
    int span = 1,
    bool cvExtractable = true,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.singleSelect,
        options: options,
        group: group,
        required: required,
        helpText: help,
        mapsTo: mapsTo,
        dependsOnId: dependsOnId,
        dependsOnValues: dependsOnValues,
        span: span,
        cvExtractable: cvExtractable,
      );

  static OnboardingQuestion _multi(
    String id,
    String label,
    List<String> options, {
    required String group,
    bool required = false,
    String? help,
    String? mapsTo,
    String? dependsOnId,
    List<String> dependsOnValues = const [],
    int? maxSelect,
    int span = 2,
    bool cvExtractable = true,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.multiSelect,
        options: options,
        group: group,
        required: required,
        helpText: help,
        mapsTo: mapsTo,
        dependsOnId: dependsOnId,
        dependsOnValues: dependsOnValues,
        maxSelect: maxSelect,
        span: span,
        cvExtractable: cvExtractable,
      );

  static OnboardingQuestion _search(
    String id,
    String label,
    List<String> options, {
    required String group,
    bool required = false,
    bool allowCustom = false,
    String? help,
    String? hint,
    String? mapsTo,
    String? dependsOnId,
    List<String> dependsOnValues = const [],
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.searchSelect,
        options: options,
        group: group,
        required: required,
        allowCustom: allowCustom,
        helpText: help,
        placeholder: hint,
        mapsTo: mapsTo,
        dependsOnId: dependsOnId,
        dependsOnValues: dependsOnValues,
      );

  static OnboardingQuestion _searchMulti(
    String id,
    String label,
    List<String> options, {
    required String group,
    bool required = false,
    bool allowCustom = true,
    String? help,
    String? mapsTo,
    String? dependsOnId,
    List<String> dependsOnValues = const [],
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.searchMultiSelect,
        options: options,
        group: group,
        required: required,
        allowCustom: allowCustom,
        helpText: help,
        mapsTo: mapsTo,
        dependsOnId: dependsOnId,
        dependsOnValues: dependsOnValues,
        span: 2,
      );

  static OnboardingQuestion _tags(
    String id,
    String label, {
    required String group,
    String? help,
    String? hint,
    String? mapsTo,
    String? dependsOnId,
    List<String> dependsOnValues = const [],
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.tags,
        group: group,
        helpText: help,
        placeholder: hint,
        mapsTo: mapsTo,
        dependsOnId: dependsOnId,
        dependsOnValues: dependsOnValues,
        span: 2,
      );

  static OnboardingQuestion _date(
    String id,
    String label, {
    required String group,
    bool required = false,
    String? help,
    String? mapsTo,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.date,
        group: group,
        required: required,
        helpText: help,
        mapsTo: mapsTo,
      );

  static OnboardingQuestion _monthYear(
    String id,
    String label, {
    required String group,
    bool required = false,
    String? help,
    String? mapsTo,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.monthYear,
        group: group,
        required: required,
        helpText: help,
        mapsTo: mapsTo,
      );

  /// Declarations. Always [cvExtractable] = false: these carry legal weight
  /// (violations, incidents, enforcement history) and must be answered by the
  /// candidate, never inferred by a model from what a CV happens to omit.
  static OnboardingQuestion _yesNo(
    String id,
    String label, {
    required String group,
    bool required = false,
    String? help,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.yesNoDetail,
        group: group,
        required: required,
        helpText: help,
        span: 2,
        cvExtractable: false,
      );

  static OnboardingQuestion _bool(
    String id,
    String label, {
    required String group,
    String? help,
    bool cvExtractable = true,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.boolean,
        group: group,
        helpText: help,
        cvExtractable: cvExtractable,
      );

  static OnboardingQuestion _phone(
    String id,
    String label, {
    required String group,
    bool required = false,
    String? help,
    String? mapsTo,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.phone,
        group: group,
        required: required,
        helpText: help,
        mapsTo: mapsTo,
      );

  /// Uploads are never `required`. A document the candidate does not have to
  /// hand should not block them from finishing and being seen — they can add
  /// it from their profile later, and the recruiter can ask for it. Making
  /// these mandatory only produced abandoned drafts.
  static OnboardingQuestion _file(
    String id,
    String label, {
    required String group,
    String? help,
  }) =>
      OnboardingQuestion(
        id: id,
        label: label,
        type: QuestionType.file,
        group: group,
        required: false,
        helpText: help,
      );

  // ── Universal sections ────────────────────────────────────────────────────

  static const sPersonal = 'Personal Information';
  static const sMobility = 'Location & Mobility';
  static const sDocuments = 'Documents';

  /// Asked of every candidate regardless of template. Projects straight onto
  /// [CandidateProfile.personalInfo].
  static List<OnboardingQuestion> get universal => [
        _text('full_name', 'Full name',
            group: sPersonal,
            required: true,
            hint: 'As printed on your passport',
            mapsTo: 'personalInfo.fullName'),
        _text('email', 'Email address',
            group: sPersonal, required: true, mapsTo: 'personalInfo.email'),
        _phone('phone', 'Phone number',
            group: sPersonal,
            required: true,
            mapsTo: 'personalInfo.phone'),
        _text('city', 'City of residence',
            group: sPersonal, mapsTo: 'personalInfo.location.city'),
        _search('country', 'Country of residence', OptionCatalog.countries,
            group: sPersonal,
            required: true,
            mapsTo: 'personalInfo.location.country'),
        _text('secondary_email', 'Alternate email',
            group: sPersonal,
            hint: 'Optional — used if we cannot reach your primary inbox',
            mapsTo: 'personalInfo.secondaryEmail'),
        _date('date_of_birth', 'Date of birth',
            group: sPersonal,
            required: true,
            help: 'Required by employers for visa and licence processing.',
            mapsTo: 'personalInfo.dateOfBirth'),
        _tags('social_links', 'Professional links',
            group: sPersonal,
            hint: 'linkedin.com/in/you — press enter to add',
            mapsTo: 'personalInfo.socialLinks'),
        _long('summary', 'Professional summary',
            group: sPersonal,
            hint: 'Two or three sentences a recruiter reads first',
            mapsTo: 'personalInfo.summary'),
        _searchMulti('citizenship', 'Citizenship / passports held',
            OptionCatalog.countries,
            group: sMobility,
            required: true,
            allowCustom: false,
            mapsTo: 'personalInfo.citizenship'),
        _multi('work_authorization', 'Work authorization',
            OptionCatalog.workAuthorization,
            group: sMobility,
            required: true,
            mapsTo: 'personalInfo.workAuthorization',
            cvExtractable: false),
        _searchMulti('languages', 'Languages spoken', OptionCatalog.languages,
            group: sMobility, mapsTo: 'roleSpecificData.technicalCompetencies'),
        _multi('preferred_regions', 'Preferred regions', OptionCatalog.regions,
            group: sMobility, cvExtractable: false),
        _single('employment_type', 'Preferred employment type',
            OptionCatalog.employmentTypes,
            group: sMobility, cvExtractable: false),
        _bool('willing_relocate', 'Willing to relocate',
            group: sMobility, cvExtractable: false),
      ];

  /// Upload slots shared by every aviation template.
  static List<OnboardingQuestion> get _commonDocs => [
        _file('doc_resume', 'Resume / CV',
            group: sDocuments,
            help: 'PDF or DOCX, up to 10MB'),
      ];

  // ══════════════════════════════════════════════════════════════════════════
  // PILOT — from Pilot_Recruitment_Form_Specification
  // ══════════════════════════════════════════════════════════════════════════

  static const _pEmployer = 'Employer & Organization';
  static const _pAircraft = 'Aircraft Flown & Ratings';
  static const _pLicensing = 'Licensing & Certifications';
  static const _pHours = 'Flight Hours';
  static const _pMission = 'Mission & Sector Experience';
  static const _pRecency = 'Recency & Compliance';

  /// Every pilot employer type except the military one, derived from the
  /// option list so the conditional can never drift from the values the
  /// control actually offers.
  static final List<String> _civilEmployers = OptionCatalog.employerTypesPilot
      .where((e) => e != 'Military Branch')
      .toList();

  static List<OnboardingQuestion> get _pilotQuestions => [
        // SEC-1
        _single('employer_type', 'Current / past employer type',
            OptionCatalog.employerTypesPilot,
            group: _pEmployer,
            required: true,
            help: 'Drives which employer fields you are asked for next.',
            span: 2),
        _search('employer_name', 'Name of airline / company',
            OptionCatalog.airlinesAndOperators,
            group: _pEmployer,
            required: true,
            allowCustom: true,
            help: 'Search the operator list or type your own.',
            dependsOnId: 'employer_type',
            dependsOnValues: _civilEmployers),
        _search('military_branch', 'Military organization / service branch',
            OptionCatalog.militaryBranches,
            group: _pEmployer,
            required: true,
            allowCustom: true,
            dependsOnId: 'employer_type',
            dependsOnValues: const ['Military Branch']),
        _text('military_unit', 'Unit / squadron / command',
            group: _pEmployer,
            hint: 'e.g. 94th Fighter Squadron',
            dependsOnId: 'employer_type',
            dependsOnValues: const ['Military Branch']),
        _single('employment_status', 'Current employment status',
            OptionCatalog.employmentStatus,
            group: _pEmployer, required: true, cvExtractable: false),
        _single('notice_period', 'Notice period / availability',
            OptionCatalog.noticePeriods,
            group: _pEmployer, required: true, cvExtractable: false),

        // SEC-2
        _multi('primary_category', 'Primary category flown',
            const ['Fixed-Wing (Airplane)', 'Rotary-Wing (Helicopter)',
                'Powered-Lift / Tilt-Rotor'],
            group: _pAircraft,
            required: true,
            help: 'Controls which aircraft and flight-hour fields appear.'),
        _searchMulti('fixed_wing_types', 'Aircraft types flown (fixed-wing)',
            OptionCatalog.fixedWingTypes,
            group: _pAircraft,
            required: true,
            help: 'ICAO type designators.',
            mapsTo: 'roleSpecificData.typeRatingsOrAircraftTypes',
            dependsOnId: 'primary_category',
            dependsOnValues: const ['Fixed-Wing (Airplane)',
                'Powered-Lift / Tilt-Rotor']),
        _searchMulti('rotary_types', 'Aircraft types flown (rotary-wing)',
            OptionCatalog.rotaryWingTypes,
            group: _pAircraft,
            required: true,
            mapsTo: 'roleSpecificData.typeRatingsOrAircraftTypes',
            dependsOnId: 'primary_category',
            dependsOnValues: const ['Rotary-Wing (Helicopter)']),
        _search('primary_aircraft', 'Primary / current aircraft type',
            [...OptionCatalog.fixedWingTypes, ...OptionCatalog.rotaryWingTypes],
            group: _pAircraft,
            required: true,
            allowCustom: true,
            help: 'The single type you are currently active on.'),
        _searchMulti('type_ratings', 'Formal type ratings held',
            OptionCatalog.typeRatingCodes,
            group: _pAircraft,
            mapsTo: 'roleSpecificData.licensesAndRatings'),
        _tags('aircraft_variants', 'Variant / series experience',
            group: _pAircraft,
            hint: 'e.g. B737 MAX, A320neo — press enter to add',
            help: 'Optional detail for specialised operations.'),

        // SEC-3
        _multi('issuing_authority', 'Issuing aviation authority',
            OptionCatalog.authorities,
            group: _pLicensing,
            required: true,
            help: 'Hard filter for region-specific compliance.',
            mapsTo: 'roleSpecificData.licenseAuthority'),
        _single('license_level', 'Highest license level held',
            OptionCatalog.pilotLicenseLevels,
            group: _pLicensing,
            required: true,
            mapsTo: 'roleSpecificData.licensesAndRatings'),
        _text('license_number', 'License ID / number',
            group: _pLicensing,
            required: true,
            mapsTo: 'roleSpecificData.licenseNumber'),
        _multi('class_ratings', 'Class & ratings',
            OptionCatalog.pilotClassRatings,
            group: _pLicensing,
            required: true,
            mapsTo: 'roleSpecificData.licensesAndRatings'),
        _multi('instructor_ratings', 'Instructor ratings',
            OptionCatalog.instructorRatings,
            group: _pLicensing,
            mapsTo: 'roleSpecificData.licensesAndRatings'),
        _single('medical_class', 'Medical certificate class',
            OptionCatalog.medicalClasses,
            group: _pLicensing, required: true),
        _date('medical_expiry', 'Medical certificate expiry',
            group: _pLicensing,
            required: true,
            help: 'We alert you before it lapses.',
            mapsTo: 'roleSpecificData.licenseExpiry'),
        _single('english_proficiency', 'ICAO English language proficiency',
            OptionCatalog.englishProficiency,
            group: _pLicensing,
            required: true,
            help: 'Mandatory for international airline / charter deployment.'),

        // SEC-4
        _num('total_hours', 'Total flight hours (TT)',
            group: _pHours,
            unit: 'hrs',
            required: true,
            max: 40000,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.totalTime'),
        _num('pic_hours', 'Pilot in Command (PIC) hours',
            group: _pHours,
            unit: 'hrs',
            required: true,
            max: 40000,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.pic'),
        _num('sic_hours', 'Second in Command (SIC) hours',
            group: _pHours,
            unit: 'hrs',
            max: 40000,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.sic'),
        _num('fixed_wing_hours', 'Fixed-wing total time',
            group: _pHours,
            unit: 'hrs',
            max: 40000,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.fixedWing',
            ),
        _num('rotary_hours', 'Rotary-wing total time',
            group: _pHours,
            unit: 'hrs',
            max: 40000,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.rotaryWing',
            ),
        _num('multi_engine_hours', 'Multi-engine hours',
            group: _pHours,
            unit: 'hrs',
            required: true,
            max: 40000,
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.multiEngine'),
        _num('turbine_hours', 'Turbine / jet hours',
            group: _pHours,
            unit: 'hrs',
            required: true,
            max: 40000,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.turbine'),
        _num('ifr_hours', 'Actual instrument (IFR) hours',
            group: _pHours,
            unit: 'hrs',
            required: true,
            max: 20000,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.instrument',
            ),
        _num('night_hours', 'Night hours (total)',
            group: _pHours,
            unit: 'hrs',
            required: true,
            max: 20000,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.night'),
        _num('nvg_hours', 'Night Vision Goggle (NVG) hours',
            group: _pHours,
            unit: 'hrs',
            max: 10000,
            help: 'Required for tactical, HEMS and SAR roles.',
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.nvg'),

        // SEC-5
        _multi('commercial_sector', 'Commercial / airline sector experience',
            OptionCatalog.commercialSectors,
            group: _pMission),
        _multi('military_profile', 'Military operational profile',
            OptionCatalog.militaryProfiles,
            group: _pMission,
            dependsOnId: 'employer_type',
            dependsOnValues: const ['Military Branch']),
        _multi('helicopter_missions', 'Helicopter / special mission operations',
            OptionCatalog.helicopterMissions,
            group: _pMission,
            dependsOnId: 'primary_category',
            dependsOnValues: const ['Rotary-Wing (Helicopter)']),
        _single('security_clearance', 'Security clearance status',
            OptionCatalog.securityClearances,
            group: _pMission),

        // SEC-6
        _num('landings_day_90', 'Day landings in last 90 days',
            group: _pRecency,
            required: true,
            max: 500,
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.dayLandings90'),
        _num('landings_night_90', 'Night landings in last 90 days',
            group: _pRecency,
            required: true,
            max: 500,
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.nightLandings90'),
        _monthYear('last_checkride', 'Last checkride / IPC date',
            group: _pRecency, required: true),
        _yesNo('violation_history', 'Any violation or enforcement history?',
            group: _pRecency,
            required: true,
            help: 'Declare and explain — required for legal compliance.'),
        _yesNo('accident_history', 'Any accident or incident record?',
            group: _pRecency,
            required: true,
            help: 'Mandatory declaration for insurance underwriting.'),

        // SEC-7
        _file('doc_license', 'Pilot license copy',
            group: sDocuments),
        _file('doc_medical', 'Medical certificate copy',
            group: sDocuments),
        _file('doc_logbook', 'Verified logbook summary / export',
            group: sDocuments,
            help: 'ForeFlight / LogTen export, or your last 3 logbook pages.'),
        ..._commonDocs,
      ];

  // ══════════════════════════════════════════════════════════════════════════
  // MECHANIC — from Mechanic_Recruitment_Form_Specification
  // ══════════════════════════════════════════════════════════════════════════

  static const _mEmployer = 'Employer & Organization';
  static const _mTrades = 'Trades & Specializations';
  static const _mLicensing = 'Certifications & Licenses';
  static const _mAircraft = 'Aircraft & Facility Experience';
  static const _mExperience = 'Experience & Compliance';

  static final List<String> _civilMroEmployers =
      OptionCatalog.employerTypesMaintenance
          .where((e) => e != 'Military Branch')
          .toList();

  static List<OnboardingQuestion> get _mechanicQuestions => [
        // SEC-1
        _single('employer_type', 'Current / past employer type',
            OptionCatalog.employerTypesMaintenance,
            group: _mEmployer, required: true, span: 2),
        _search('employer_name', 'Name of airline / MRO / company',
            [...OptionCatalog.mroOrganizations,
                ...OptionCatalog.airlinesAndOperators],
            group: _mEmployer,
            required: true,
            allowCustom: true,
            dependsOnId: 'employer_type',
            dependsOnValues: _civilMroEmployers),
        _search('military_branch', 'Military branch / service arm',
            OptionCatalog.militaryBranches,
            group: _mEmployer,
            required: true,
            allowCustom: true,
            dependsOnId: 'employer_type',
            dependsOnValues: const ['Military Branch']),
        _text('military_unit', 'Unit / maintenance squadron / shop',
            group: _mEmployer,
            hint: 'e.g. 56th Component Maintenance Squadron',
            dependsOnId: 'employer_type',
            dependsOnValues: const ['Military Branch']),
        _single('employment_status', 'Current employment status',
            OptionCatalog.employmentStatus,
            group: _mEmployer, required: true, cvExtractable: false),
        _single('notice_period', 'Notice period / availability',
            OptionCatalog.noticePeriods,
            group: _mEmployer, required: true, cvExtractable: false),

        // SEC-2
        _multi('primary_trade', 'Primary maintenance trade',
            OptionCatalog.maintenanceTrades,
            group: _mTrades,
            required: true,
            help: 'Drives the specialisation questions below.',
            mapsTo: 'roleSpecificData.technicalCompetencies'),
        _multi('airframe_systems', 'Airframe systems experience',
            OptionCatalog.airframeSystems,
            group: _mTrades,
            mapsTo: 'roleSpecificData.technicalCompetencies',
            dependsOnId: 'primary_trade',
            dependsOnValues: const ['Airframe', 'Hydraulics / Pneumatics']),
        _multi('powerplant_skills', 'Engine / powerplant experience',
            OptionCatalog.powerplantSkills,
            group: _mTrades,
            mapsTo: 'roleSpecificData.technicalCompetencies',
            dependsOnId: 'primary_trade',
            dependsOnValues: const ['Powerplant / Engine']),
        _multi('avionics_skills', 'Avionics & electrical experience',
            OptionCatalog.avionicsSkills,
            group: _mTrades,
            mapsTo: 'roleSpecificData.technicalCompetencies',
            dependsOnId: 'primary_trade',
            dependsOnValues: const ['Avionics & Electrical']),
        _multi('armament_skills', 'Armament & weapons systems experience',
            OptionCatalog.armamentSkills,
            group: _mTrades,
            mapsTo: 'roleSpecificData.technicalCompetencies',
            dependsOnId: 'primary_trade',
            dependsOnValues: const ['Armament / Weapons Systems']),
        _multi('structures_ndt', 'Structural, composites & NDT',
            OptionCatalog.structuresNdtSkills,
            group: _mTrades,
            mapsTo: 'roleSpecificData.technicalCompetencies',
            dependsOnId: 'primary_trade',
            dependsOnValues: const ['Structures / Sheet Metal', 'Composites',
                'NDT / Inspection']),

        // SEC-3
        _multi('cert_authority', 'Regulatory certification authority',
            OptionCatalog.authorities,
            group: _mLicensing,
            required: true,
            mapsTo: 'roleSpecificData.licenseAuthority'),
        _multi('faa_licenses', 'FAA licenses held', OptionCatalog.faaLicenses,
            group: _mLicensing,
            mapsTo: 'roleSpecificData.licensesAndRatings',
            dependsOnId: 'cert_authority',
            dependsOnValues: const ['FAA (USA)']),
        _multi('easa_licenses', 'EASA / UK CAA Part-66 licenses held',
            OptionCatalog.easaPart66Licenses,
            group: _mLicensing,
            mapsTo: 'roleSpecificData.licensesAndRatings',
            dependsOnId: 'cert_authority',
            dependsOnValues: const ['EASA (Europe)', 'UK CAA']),
        _search('military_moc', 'Military occupational specialty / rating code',
            OptionCatalog.militarySpecialtyCodes,
            group: _mLicensing,
            allowCustom: true,
            dependsOnId: 'employer_type',
            dependsOnValues: const ['Military Branch']),
        _text('license_number', 'License number',
            group: _mLicensing,
            required: true,
            mapsTo: 'roleSpecificData.licenseNumber'),
        _date('license_expiry', 'License expiry date',
            group: _mLicensing, mapsTo: 'roleSpecificData.licenseExpiry'),
        _multi('sign_off_auth', 'Company release / sign-off authorizations',
            OptionCatalog.signOffAuthorizations,
            group: _mLicensing,
            dependsOnId: 'employer_type',
            dependsOnValues: _civilMroEmployers),

        // SEC-4
        _searchMulti('fixed_wing_maintained',
            'Aircraft types maintained (fixed-wing)', OptionCatalog.fixedWingTypes,
            group: _mAircraft,
            mapsTo: 'roleSpecificData.typeRatingsOrAircraftTypes'),
        _searchMulti('rotary_maintained',
            'Aircraft types maintained (rotary-wing)',
            OptionCatalog.rotaryWingTypes,
            group: _mAircraft,
            mapsTo: 'roleSpecificData.typeRatingsOrAircraftTypes'),
        _searchMulti('engine_models', 'Engine models maintained',
            OptionCatalog.engineModels,
            group: _mAircraft, mapsTo: 'roleSpecificData.toolsAndSystems'),
        _multi('maintenance_environment', 'Maintenance environment / facility',
            OptionCatalog.maintenanceEnvironments,
            group: _mAircraft, required: true),
        _tags('factory_courses', 'Factory / Gen-Fam course certificates',
            group: _mAircraft,
            hint: 'e.g. Boeing 737NG Gen Fam — press enter to add',
            help: 'ATA 104 Level 3 type courses.'),

        // SEC-5
        _num('total_experience_years', 'Total aviation maintenance experience',
            group: _mExperience,
            unit: 'yrs',
            required: true,
            max: 60,
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.totalYears'),
        _num('trade_experience_years', 'Experience in your primary trade',
            group: _mExperience,
            unit: 'yrs',
            required: true,
            max: 60,
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.tradeYears'),
        _single('toolbox_status', 'Toolbox / tooling status',
            OptionCatalog.toolboxStatus,
            group: _mExperience,
            required: true,
            help: 'A hard requirement at many civil MROs.',
            span: 2,
            cvExtractable: false),
        _single('security_clearance', 'Security clearance level',
            OptionCatalog.securityClearances,
            group: _mExperience),
        _yesNo('enforcement_history',
            'Any regulatory enforcement or sanction history?',
            group: _mExperience, required: true),

        // SEC-6
        _file('doc_license', 'Mechanic license / certificate copy',
            group: sDocuments),
        _file('doc_logbook', 'Logbook / training records / task cards',
            group: sDocuments),
        _file('doc_courses', 'Course / factory certificates',
            group: sDocuments),
        ..._commonDocs,
      ];

  // ══════════════════════════════════════════════════════════════════════════
  // SAFETY OFFICER — from Safety_Officer_Recruitment_Form_Specification
  // ══════════════════════════════════════════════════════════════════════════

  static const _sRole = 'Role & Background';
  static const _sSpecial = 'Safety Specializations';
  static const _sCreds = 'Certifications & Credentials';
  static const _sEnv = 'Operational Environment';
  static const _sExp = 'Experience & Leadership';

  static List<OnboardingQuestion> get _safetyQuestions => [
        // SEC-1
        _single('safety_role', 'Primary safety role / target title',
            OptionCatalog.safetyRoles,
            group: _sRole, required: true, span: 2),
        _multi('safety_background', 'Operational aviation background',
            OptionCatalog.safetyBackgrounds,
            group: _sRole,
            required: true,
            help: 'Matches your operational lineage to the right vacancies.'),
        _single('employer_type', 'Current / past employer type',
            OptionCatalog.employerTypesSafety,
            group: _sRole, required: true, span: 2),
        _search('employer_name', 'Organization / airline / military unit',
            [...OptionCatalog.airlinesAndOperators,
                ...OptionCatalog.mroOrganizations,
                ...OptionCatalog.militaryBranches],
            group: _sRole, required: true, allowCustom: true),
        _single('employment_status', 'Current employment status',
            OptionCatalog.employmentStatus,
            group: _sRole, required: true, cvExtractable: false),
        _single('notice_period', 'Notice period / availability',
            OptionCatalog.noticePeriods,
            group: _sRole, required: true, cvExtractable: false),

        // SEC-2
        _multi('safety_disciplines', 'Core safety disciplines / domains',
            OptionCatalog.safetyDisciplines,
            group: _sSpecial,
            required: true,
            mapsTo: 'roleSpecificData.technicalCompetencies'),
        _multi('flight_safety_skills', 'Flight operations safety experience',
            OptionCatalog.flightSafetySkills,
            group: _sSpecial,
            mapsTo: 'roleSpecificData.technicalCompetencies',
            dependsOnId: 'safety_background',
            dependsOnValues: const ['Pilot Background (Fixed-Wing)',
                'Pilot Background (Helicopter)',
                'Flight Dispatcher / Operations']),
        _multi('maintenance_safety_skills', 'Maintenance & engineering safety',
            OptionCatalog.maintenanceSafetySkills,
            group: _sSpecial,
            mapsTo: 'roleSpecificData.technicalCompetencies',
            dependsOnId: 'safety_background',
            dependsOnValues: const [
              'Aircraft Mechanic / Technician (A&P / Part-66)'
            ]),
        _multi('sms_skills', 'SMS implementation & risk management',
            OptionCatalog.smsSkills,
            group: _sSpecial,
            required: true,
            mapsTo: 'roleSpecificData.technicalCompetencies'),
        _multi('investigation_methods', 'Investigation & audit methodologies',
            OptionCatalog.investigationMethods,
            group: _sSpecial,
            mapsTo: 'roleSpecificData.technicalCompetencies'),

        // SEC-3
        _multi('safety_credentials', 'Safety & professional credentials',
            OptionCatalog.safetyCredentials,
            group: _sCreds,
            required: true,
            mapsTo: 'roleSpecificData.licensesAndRatings'),
        _multi('technical_licenses', 'Underlying technical licenses held',
            const [
              'Pilot License (ATPL / CPL / Military Wings)',
              'Aircraft Maintenance License (A&P / Part-66 / Military MOS)',
              'Dispatcher License',
              'ATC License',
              'None',
            ],
            group: _sCreds,
            required: true,
            help: 'Validates dual-qualification (e.g. rated pilot + FSO).',
            mapsTo: 'roleSpecificData.licensesAndRatings'),
        _multi('issuing_bodies', 'Issuing regulatory bodies / institutes',
            OptionCatalog.safetyBodies,
            group: _sCreds,
            required: true,
            mapsTo: 'roleSpecificData.licenseAuthority'),
        _single('security_clearance', 'Security clearance level',
            OptionCatalog.securityClearances,
            group: _sCreds),

        // SEC-4
        _multi('aviation_sectors', 'Aviation operational sectors',
            OptionCatalog.aviationSectors,
            group: _sEnv, required: true),
        _searchMulti('aircraft_familiarity', 'Aircraft types familiarity',
            [...OptionCatalog.fixedWingTypes, ...OptionCatalog.rotaryWingTypes],
            group: _sEnv,
            mapsTo: 'roleSpecificData.typeRatingsOrAircraftTypes'),
        _multi('safety_software', 'Safety software & FOQA tools',
            OptionCatalog.safetySoftware,
            group: _sEnv, mapsTo: 'roleSpecificData.toolsAndSystems'),

        // SEC-5
        _num('safety_experience_years', 'Total aviation safety experience',
            group: _sExp,
            unit: 'yrs',
            required: true,
            max: 60,
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.safetyYears'),
        _num('operational_experience', 'Total operational experience',
            group: _sExp,
            unit: 'hrs / yrs',
            max: 40000,
            help: 'Flight hours if you are a pilot, years if a technician.',
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.operational'),
        _multi('erp_roles', 'Emergency Response Planning (ERP) roles',
            OptionCatalog.erpRoles,
            group: _sExp),
        _yesNo('enforcement_history',
            'Any regulatory or enforcement incident record?',
            group: _sExp, required: true),

        // SEC-6
        _file('doc_safety_certs', 'Safety professional certificates',
            group: sDocuments,
            help: 'SMS, investigator or auditor certificates.'),
        _file('doc_technical_license',
            'Aviation technical licenses (pilot / A&P)',
            group: sDocuments),
        _file('doc_sample_report', 'Sample safety report / risk assessment',
            group: sDocuments,
            help: 'Redacted SMS policy, audit report or risk assessment.'),
        ..._commonDocs,
      ];

  // ══════════════════════════════════════════════════════════════════════════
  // CABIN CREW
  // ══════════════════════════════════════════════════════════════════════════

  static const _cRole = 'Role & Employer';
  static const _cExperience = 'Cabin Experience';
  static const _cTraining = 'Training & Certification';

  static List<OnboardingQuestion> get _cabinQuestions => [
        _single('cabin_position', 'Position held', OptionCatalog.cabinPositions,
            group: _cRole, required: true),
        _search('employer_name', 'Current / most recent airline',
            OptionCatalog.airlinesAndOperators,
            group: _cRole, required: true, allowCustom: true),
        _single('employment_status', 'Current employment status',
            OptionCatalog.employmentStatus,
            group: _cRole, required: true, cvExtractable: false),
        _single('notice_period', 'Notice period / availability',
            OptionCatalog.noticePeriods,
            group: _cRole, required: true, cvExtractable: false),
        _num('cabin_years', 'Years of cabin experience',
            group: _cExperience,
            unit: 'yrs',
            required: true,
            max: 50,
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.cabinYears'),
        _searchMulti('cabin_aircraft', 'Aircraft types served on',
            OptionCatalog.fixedWingTypes,
            group: _cExperience,
            required: true,
            mapsTo: 'roleSpecificData.typeRatingsOrAircraftTypes'),
        _multi('cabin_sectors', 'Sectors flown',
            const ['Short-Haul', 'Medium-Haul', 'Long-Haul', 'Ultra Long-Haul',
                'Charter', 'VIP / Private', 'Cargo'],
            group: _cExperience),
        _multi('cabin_service', 'Cabin classes served',
            const ['Economy', 'Premium Economy', 'Business', 'First',
                'Private / VVIP'],
            group: _cExperience),
        _multi('cabin_training', 'Current training & certification',
            OptionCatalog.cabinTraining,
            group: _cTraining,
            required: true,
            mapsTo: 'roleSpecificData.licensesAndRatings'),
        _date('sep_expiry', 'SEP / recurrent training valid until',
            group: _cTraining, mapsTo: 'roleSpecificData.licenseExpiry'),
        _num('height_cm', 'Height',
            group: _cTraining,
            unit: 'cm',
            min: 120,
            max: 220,
            help: 'Many carriers set a reach requirement.'),
        _bool('swim_certified', 'Swim / ditching certified', group: _cTraining),
        _file('doc_sep', 'SEP / training certificate', group: sDocuments),
        ..._commonDocs,
      ];

  // ══════════════════════════════════════════════════════════════════════════
  // ENGINEERING & TECHNOLOGY
  // ══════════════════════════════════════════════════════════════════════════

  static const _eRole = 'Role & Seniority';
  static const _eStack = 'Technical Stack';
  static const _ePractice = 'Engineering Practice';

  static List<OnboardingQuestion> _engineeringQuestions({
    required List<String> specialtyDefaults,
    bool infraFocus = false,
  }) =>
      [
        _single('seniority', 'Current seniority level',
            OptionCatalog.seniorityLevels,
            group: _eRole, required: true),
        _multi('specialties', 'Engineering specialisations',
            OptionCatalog.engineeringSpecialties,
            group: _eRole,
            required: true,
            mapsTo: 'roleSpecificData.technicalCompetencies'),
        _text('employer_name', 'Current / most recent employer',
            group: _eRole, required: true),
        _single('employment_status', 'Current employment status',
            OptionCatalog.employmentStatus,
            group: _eRole, required: true, cvExtractable: false),
        _single('notice_period', 'Notice period / availability',
            OptionCatalog.noticePeriods,
            group: _eRole, required: true, cvExtractable: false),
        _num('total_experience_years', 'Total engineering experience',
            group: _eRole,
            unit: 'yrs',
            required: true,
            max: 50,
            mapsTo:
                'roleSpecificData.flightHoursOrExperienceMetrics.totalYears'),
        _searchMulti('languages_used', 'Programming languages',
            OptionCatalog.programmingLanguages,
            group: _eStack,
            required: true,
            mapsTo: 'roleSpecificData.technicalCompetencies'),
        _searchMulti('frameworks_used', 'Frameworks & runtimes',
            OptionCatalog.frameworks,
            group: _eStack,
            required: specialtyDefaults.contains('Full-Stack'),
            mapsTo: 'roleSpecificData.toolsAndSystems'),
        _multi('cloud_platforms', 'Cloud platforms',
            OptionCatalog.cloudPlatforms,
            group: _eStack,
            required: infraFocus,
            mapsTo: 'roleSpecificData.toolsAndSystems'),
        _searchMulti('devops_tools', 'Infrastructure & CI/CD tooling',
            OptionCatalog.devopsTools,
            group: _eStack,
            required: infraFocus,
            mapsTo: 'roleSpecificData.toolsAndSystems'),
        _searchMulti('databases_used', 'Databases & data stores',
            OptionCatalog.databases,
            group: _eStack, mapsTo: 'roleSpecificData.toolsAndSystems'),
        _multi('practices', 'Engineering practices',
            const ['Code Review', 'TDD / Unit Testing', 'Pair Programming',
                'CI/CD Ownership', 'On-Call / Incident Response',
                'Design Docs / RFCs', 'Mentoring', 'Agile / Scrum'],
            group: _ePractice,
            mapsTo: 'roleSpecificData.technicalCompetencies'),
        _num('team_size', 'Largest team led or mentored',
            group: _ePractice,
            unit: 'people',
            max: 500,
            mapsTo: 'roleSpecificData.flightHoursOrExperienceMetrics.teamSize'),
        _tags('portfolio_links', 'Portfolio / repository links',
            group: _ePractice,
            hint: 'github.com/you — press enter to add'),
        _yesNo('non_compete', 'Bound by a non-compete or notice restriction?',
            group: _ePractice),
        ..._commonDocs,
      ];

  // ── Template assembly ─────────────────────────────────────────────────────

  static RoleTemplate _template(
    String id,
    String title,
    String category,
    String industry,
    List<OnboardingQuestion> specialised, {
    String? description,
  }) =>
      RoleTemplate(
        id: id,
        title: title,
        category: category,
        industry: industry,
        description: description,
        questions: [...universal, ...specialised],
      );

  /// High-fidelity templates authored from the role specifications.
  ///
  /// Built once: assembling every template walks several hundred question
  /// definitions, and the picker, the seeder and the profile editor all read
  /// it repeatedly.
  static List<RoleTemplate> get detailed => _detailed;
  static final List<RoleTemplate> _detailed = [
        // ── Aviation · Flight Crew ──
        _template('airline_pilot', 'Airline Pilot', 'Flight Crew',
            aviation.title, _pilotQuestions,
            description: 'Part 121 / 135 fixed-wing line pilots'),
        _template('captain', 'Captain', 'Flight Crew', aviation.title,
            _pilotQuestions),
        _template('first_officer', 'First Officer', 'Flight Crew',
            aviation.title, _pilotQuestions),
        _template('business_jet_pilot', 'Business / Corporate Jet Pilot',
            'Flight Crew', aviation.title, _pilotQuestions),
        _template('cargo_pilot', 'Cargo Pilot', 'Flight Crew', aviation.title,
            _pilotQuestions),
        _template('helicopter_pilot', 'Helicopter Pilot', 'Flight Crew',
            aviation.title, _pilotQuestions),
        _template('military_pilot', 'Military Pilot', 'Flight Crew',
            aviation.title, _pilotQuestions),
        _template('flight_instructor', 'Flight Instructor',
            'Instruction & Training', aviation.title, _pilotQuestions),

        // ── Aviation · Engineering & Maintenance ──
        _template('aircraft_mechanic', 'Aircraft Mechanic / Technician',
            'Engineering & Maintenance', aviation.title, _mechanicQuestions,
            description: 'A&P, Part-66 and military maintenance trades'),
        _template('maintenance_engineer', 'Aircraft Maintenance Engineer',
            'Engineering & Maintenance', aviation.title, _mechanicQuestions),
        _template('avionics_engineer', 'Avionics Engineer',
            'Engineering & Maintenance', aviation.title, _mechanicQuestions),
        _template('ap_technician', 'A&P Technician',
            'Engineering & Maintenance', aviation.title, _mechanicQuestions),
        _template('structures_technician', 'Structures / Composite Technician',
            'Engineering & Maintenance', aviation.title, _mechanicQuestions),

        // ── Aviation · Safety, Quality & Compliance ──
        _template('safety_officer', 'Aviation Safety Officer',
            'Safety, Quality & Compliance', aviation.title, _safetyQuestions,
            description: 'SMS, FOQA, investigation and audit professionals'),
        _template('sms_manager', 'SMS Manager',
            'Safety, Quality & Compliance', aviation.title, _safetyQuestions),
        _template('accident_investigator', 'Accident Investigator',
            'Safety, Quality & Compliance', aviation.title, _safetyQuestions),
        _template('compliance_officer', 'Quality & Compliance Officer',
            'Safety, Quality & Compliance', aviation.title, _safetyQuestions),

        // ── Aviation · Cabin Services ──
        _template('cabin_crew', 'Cabin Crew', 'Cabin Services', aviation.title,
            _cabinQuestions),
        _template('cabin_supervisor', 'Cabin Supervisor / Purser',
            'Cabin Services', aviation.title, _cabinQuestions),

        // ── Engineering & Technology ──
        _template(
            'software_engineer',
            'Software Engineer',
            'Software',
            engineering.title,
            _engineeringQuestions(specialtyDefaults: const ['Full-Stack'])),
        _template(
            'frontend_engineer',
            'Frontend Engineer',
            'Software',
            engineering.title,
            _engineeringQuestions(specialtyDefaults: const ['Frontend'])),
        _template(
            'backend_engineer',
            'Backend Engineer',
            'Software',
            engineering.title,
            _engineeringQuestions(specialtyDefaults: const ['Backend'])),
        _template(
            'mobile_engineer',
            'Mobile Engineer',
            'Software',
            engineering.title,
            _engineeringQuestions(specialtyDefaults: const ['Mobile'])),
        _template(
            'devops_engineer',
            'DevOps Engineer',
            'Platform & Infrastructure',
            engineering.title,
            _engineeringQuestions(
                specialtyDefaults: const ['Platform / Infrastructure'],
                infraFocus: true)),
        _template(
            'sre',
            'Site Reliability Engineer',
            'Platform & Infrastructure',
            engineering.title,
            _engineeringQuestions(
                specialtyDefaults: const ['Site Reliability'],
                infraFocus: true)),
        _template(
            'data_engineer',
            'Data Engineer',
            'Data & AI',
            engineering.title,
            _engineeringQuestions(specialtyDefaults: const ['Data Engineering'])),
        _template(
            'ml_engineer',
            'Machine Learning Engineer',
            'Data & AI',
            engineering.title,
            _engineeringQuestions(
                specialtyDefaults: const ['Machine Learning'])),
        _template(
            'qa_engineer',
            'QA / Test Automation Engineer',
            'Quality',
            engineering.title,
            _engineeringQuestions(
                specialtyDefaults: const ['QA / Test Automation'])),
      ];

  static final Set<String> _detailedIds =
      _detailed.map((r) => r.id).toSet();

  /// Legacy aviation roles that have no detailed template yet. They keep the
  /// original question banks so no profession disappears from the picker, and
  /// gain the universal personal section + a resume upload.
  /// Question ids that describe what a candidate *wants* or must *declare*,
  /// rather than what they have done. A CV cannot answer these honestly, so
  /// they are withheld from the extractor wherever they appear — including in
  /// the legacy catalogue, which predates the [OnboardingQuestion.cvExtractable]
  /// flag.
  static const _neverFromCv = {
    'notice_period',
    'employment_status',
    'employment_type',
    'preferred_regions',
    'willing_relocate',
    'work_authorization',
    'toolbox_status',
    'salary_expectation',
    'visa_status',
    'passport_valid',
    'shift_pref',
  };

  static OnboardingQuestion _applyExtractionPolicy(OnboardingQuestion q) {
    if (q.type == QuestionType.yesNoDetail || _neverFromCv.contains(q.id)) {
      return q.copyWith(cvExtractable: false);
    }
    return q;
  }

  static final List<RoleTemplate> _legacy = AviationCatalogue.roles
      .where((r) => !_detailedIds.contains(r.id))
      .map((r) => r.copyWith(
            industry: aviation.title,
            questions: [
              ...universal,
              ...r.questions
                  .where((q) => !_universalIds.contains(q.id))
                  .map(_applyExtractionPolicy),
              ..._commonDocs,
            ],
          ))
      .toList();

  static final Set<String> _universalIds =
      universal.map((q) => q.id).toSet();

  /// Everything the picker offers — detailed templates first, then the
  /// remaining professions from the legacy catalogue.
  static List<RoleTemplate> get templates => _templates;
  static final List<RoleTemplate> _templates = [..._detailed, ..._legacy];

  static final Map<String, RoleTemplate> _byId = {
    for (final t in _templates) t.id: t,
  };

  static RoleTemplate? byId(String id) => _byId[id];

  /// Templates grouped `industry → category → roles`, preserving order.
  static Map<String, Map<String, List<RoleTemplate>>> grouped(
      List<RoleTemplate> source) {
    final out = <String, Map<String, List<RoleTemplate>>>{};
    for (final t in source) {
      out
          .putIfAbsent(t.industry, () => <String, List<RoleTemplate>>{})
          .putIfAbsent(t.category, () => <RoleTemplate>[])
          .add(t);
    }
    return out;
  }
}
