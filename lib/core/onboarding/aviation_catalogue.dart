import 'models/aviation_role.dart';
import 'models/question.dart';

/// Default worldwide aviation role catalogue + reusable question banks.
///
/// This is the SEED source: the admin "Questionnaires" section writes it into
/// Firestore (`questionnaire_config`), after which it is fully admin-editable.
/// The onboarding engine always reads the live Firestore config, never this
/// file directly — so future edits never require an app release.
abstract final class AviationCatalogue {
  /// Bumped when the seed content changes so admins can re-seed intentionally.
  static const int seedVersion = 1;

  // ── Question factory helpers (keep the catalogue terse & consistent) ──────
  static OnboardingQuestion _text(String id, String label,
          {String? group, bool required = false, String? help}) =>
      OnboardingQuestion(
          id: id,
          label: label,
          type: QuestionType.text,
          group: group,
          required: required,
          helpText: help);

  static OnboardingQuestion _long(String id, String label, {String? group}) =>
      OnboardingQuestion(
          id: id, label: label, type: QuestionType.longText, group: group);

  static OnboardingQuestion _num(String id, String label,
          {String? unit, num? min, num? max, String? group}) =>
      OnboardingQuestion(
          id: id,
          label: label,
          type: QuestionType.number,
          unit: unit,
          min: min,
          max: max,
          group: group);

  static OnboardingQuestion _single(String id, String label, List<String> opts,
          {String? group, bool required = false}) =>
      OnboardingQuestion(
          id: id,
          label: label,
          type: QuestionType.singleSelect,
          options: opts,
          group: group,
          required: required);

  static OnboardingQuestion _multi(String id, String label, List<String> opts,
          {String? group}) =>
      OnboardingQuestion(
          id: id,
          label: label,
          type: QuestionType.multiSelect,
          options: opts,
          group: group);

  static OnboardingQuestion _bool(String id, String label, {String? group}) =>
      OnboardingQuestion(
          id: id, label: label, type: QuestionType.boolean, group: group);

  static OnboardingQuestion _date(String id, String label, {String? group}) =>
      OnboardingQuestion(
          id: id, label: label, type: QuestionType.date, group: group);

  // ── Shared option lists ───────────────────────────────────────────────────
  static const _regulators = [
    'FAA', 'EASA', 'UK CAA', 'ICAO', 'CASA', 'Transport Canada', 'GCAA (UAE)',
    'GACA (KSA)', 'CAAP', 'DGCA', 'Other',
  ];
  static const _regions = [
    'North America', 'Europe', 'Middle East', 'Africa', 'South Asia',
    'East Asia', 'Southeast Asia', 'Oceania', 'South America',
  ];
  static const _employmentTypes = [
    'Full-time', 'Part-time', 'Contract', 'Freelance', 'Seasonal',
  ];
  static const _noticePeriods = [
    'Immediate', '2 weeks', '1 month', '2 months', '3 months+',
  ];
  static const _education = [
    'High School', 'Diploma', 'Associate', 'Bachelor', 'Master', 'Doctorate',
  ];
  static const _clearance = [
    'None', 'Confidential', 'Secret', 'Top Secret', 'Top Secret/SCI',
  ];
  static const _experienceBands = [
    '0-1 years', '1-3 years', '3-5 years', '5-10 years', '10-20 years', '20+ years',
  ];
  static const _langs = [
    'English', 'Arabic', 'French', 'Spanish', 'German', 'Mandarin', 'Hindi',
    'Urdu', 'Russian', 'Portuguese',
  ];
  static const _medicalClass = ['Class 1', 'Class 2', 'Class 3', 'None'];
  static const _background = ['Civil', 'Military', 'Both'];

  // ── Reusable question banks ───────────────────────────────────────────────

  /// Universal questions asked of everyone (kept ~10).
  static List<OnboardingQuestion> get _common => [
        _text('current_position', 'Current position / title',
            group: 'Professional', required: true),
        _single('experience_band', 'Total years of experience', _experienceBands,
            group: 'Professional', required: true),
        _single('background', 'Career background', _background,
            group: 'Professional'),
        _multi('regulators', 'Regulatory authorities you hold credentials under',
            _regulators,
            group: 'Credentials'),
        _multi('preferred_regions', 'Preferred regions', _regions,
            group: 'Preferences'),
        _bool('willing_relocate', 'Willing to relocate', group: 'Preferences'),
        _single('employment_type', 'Preferred employment type', _employmentTypes,
            group: 'Preferences'),
        _single('notice_period', 'Notice period', _noticePeriods,
            group: 'Preferences'),
        _multi('languages', 'Languages spoken', _langs, group: 'Personal'),
        _single('education', 'Highest education', _education, group: 'Personal'),
        _bool('passport_valid', 'Hold a valid passport', group: 'Mobility'),
        _text('visa_status', 'Work authorization / visa status',
            group: 'Mobility'),
        _num('salary_expectation', 'Expected annual salary (USD)',
            unit: 'USD', group: 'Preferences'),
      ];

  static List<OnboardingQuestion> get _pilot => [
        _num('total_hours', 'Total flight hours', unit: 'hrs', group: 'Flight Time'),
        _num('pic_hours', 'PIC hours', unit: 'hrs', group: 'Flight Time'),
        _num('sic_hours', 'SIC hours', unit: 'hrs', group: 'Flight Time'),
        _num('multi_engine_hours', 'Multi-engine hours',
            unit: 'hrs', group: 'Flight Time'),
        _num('turbine_hours', 'Turbine hours', unit: 'hrs', group: 'Flight Time'),
        _num('jet_hours', 'Jet hours', unit: 'hrs', group: 'Flight Time'),
        _num('sim_hours', 'Simulator hours', unit: 'hrs', group: 'Flight Time'),
        _multi('licenses', 'Licenses held',
            ['SPL', 'PPL', 'CPL', 'ATPL', 'MPL'], group: 'Credentials'),
        _multi('ratings', 'Ratings held',
            ['Instrument', 'Multi-Engine', 'Type Rating', 'Night', 'Instructor'],
            group: 'Credentials'),
        _text('type_ratings', 'Type ratings (e.g. B737, A320)',
            group: 'Credentials'),
        _text('aircraft_flown', 'Aircraft flown', group: 'Experience'),
        _single('medical_class', 'Medical certificate class', _medicalClass,
            group: 'Credentials'),
        _bool('crm_training', 'CRM training completed', group: 'Training'),
        _bool('human_factors', 'Human Factors training', group: 'Training'),
        _bool('dangerous_goods', 'Dangerous Goods certification',
            group: 'Training'),
      ];

  static List<OnboardingQuestion> get _maintenance => [
        _multi('mx_licenses', 'Maintenance licenses',
            ['A&P', 'EASA Part-66 A', 'EASA Part-66 B1', 'EASA Part-66 B2',
              'EASA Part-66 C', 'None'],
            group: 'Credentials'),
        _text('aircraft_types', 'Aircraft types worked on', group: 'Experience'),
        _text('engine_types', 'Engine / powerplant types', group: 'Experience'),
        _multi('mx_specialties', 'Specialties',
            ['Airframe', 'Powerplant', 'Avionics', 'Structures', 'Composites',
              'Hydraulics', 'Electrical', 'NDT'],
            group: 'Experience'),
        _bool('inspection_authorization', 'Hold Inspection Authorization (IA)',
            group: 'Credentials'),
        _text('approvals', 'Maintenance approvals held', group: 'Credentials'),
        _bool('borescope', 'Borescope / engine inspection experience',
            group: 'Experience'),
        _bool('line_maintenance', 'Line maintenance experience',
            group: 'Experience'),
        _bool('base_maintenance', 'Base / heavy maintenance experience',
            group: 'Experience'),
      ];

  static List<OnboardingQuestion> get _avionics => [
        _multi('avionics_specialties', 'Avionics specialties',
            ['Navigation', 'Communication', 'Radar', 'Autopilot', 'FMS',
              'Instruments', 'Wiring / EWIS'],
            group: 'Experience'),
        _bool('avionics_mods', 'Avionics modification / STC experience',
            group: 'Experience'),
        _text('avionics_platforms', 'Avionics platforms (e.g. Garmin, Honeywell)',
            group: 'Experience'),
      ];

  static List<OnboardingQuestion> get _cabin => [
        _text('cabin_aircraft', 'Aircraft types served on', group: 'Experience'),
        _num('cabin_years', 'Years of cabin experience', unit: 'yrs',
            group: 'Experience'),
        _bool('safety_training', 'Current safety & emergency training',
            group: 'Training'),
        _bool('first_aid', 'First aid / AED certified', group: 'Training'),
        _bool('service_training', 'Premium cabin service training',
            group: 'Training'),
        _single('cabin_position', 'Position',
            ['Cabin Crew', 'Senior Cabin Crew', 'Purser', 'Cabin Manager'],
            group: 'Professional'),
      ];

  static List<OnboardingQuestion> get _atc => [
        _multi('atc_ratings', 'ATC ratings',
            ['Aerodrome', 'Approach', 'Approach Radar', 'Area', 'Area Radar'],
            group: 'Credentials'),
        _single('atc_facility', 'Facility type',
            ['Tower', 'Approach/TRACON', 'Area/Center', 'Flight Service'],
            group: 'Experience'),
        _bool('atc_license_current', 'Current ATC license', group: 'Credentials'),
        _bool('radar_endorsement', 'Radar endorsement', group: 'Credentials'),
      ];

  static List<OnboardingQuestion> get _dispatch => [
        _bool('dispatch_license', 'Hold a Flight Dispatcher license',
            group: 'Credentials'),
        _text('ops_systems', 'Operations / flight-planning systems used',
            group: 'Experience'),
        _bool('weather_analysis', 'Weather analysis proficiency',
            group: 'Skills'),
        _bool('weight_balance', 'Weight & balance proficiency', group: 'Skills'),
      ];

  static List<OnboardingQuestion> get _ground => [
        _multi('ground_functions', 'Ground functions',
            ['Ramp', 'Baggage', 'Pushback', 'Marshalling', 'De-icing',
              'Fueling', 'Cargo / Load', 'GSE Operation'],
            group: 'Experience'),
        _bool('gse_licensed', 'Licensed to operate ground support equipment',
            group: 'Credentials'),
        _single('shift_pref', 'Shift preference',
            ['Day', 'Night', 'Rotating', 'Any'], group: 'Preferences'),
        _bool('dg_awareness', 'Dangerous Goods awareness training',
            group: 'Training'),
      ];

  static List<OnboardingQuestion> get _safety => [
        _bool('sms_experience', 'Safety Management System (SMS) experience',
            group: 'Experience'),
        _multi('safety_domains', 'Domains',
            ['Flight Safety', 'Ground Safety', 'Occupational', 'Quality',
              'Compliance', 'Audit'],
            group: 'Experience'),
        _bool('auditor_qualified', 'Qualified auditor', group: 'Credentials'),
        _text('safety_certs', 'Safety / quality certifications',
            group: 'Credentials'),
      ];

  static List<OnboardingQuestion> get _management => [
        _num('team_size', 'Largest team managed', unit: 'people',
            group: 'Leadership'),
        _num('budget_managed', 'Largest budget managed (USD)', unit: 'USD',
            group: 'Leadership'),
        _multi('mgmt_domains', 'Management domains',
            ['Operations', 'Maintenance', 'Crew', 'Training', 'Commercial',
              'Safety', 'Finance'],
            group: 'Leadership'),
      ];

  static List<OnboardingQuestion> get _security => [
        _single('clearance', 'Security clearance', _clearance,
            group: 'Credentials'),
        _bool('avsec_trained', 'Aviation security (AVSEC) trained',
            group: 'Training'),
        _bool('screening_experience', 'Screening / access-control experience',
            group: 'Experience'),
      ];

  /// A short bank of role-agnostic extras appended to every role to reach
  /// ~20 questions and capture recognition/portfolio data.
  static List<OnboardingQuestion> get _extras => [
        _multi('safety_training_extra', 'Recurrent training completed',
            ['CRM', 'Human Factors', 'SMS', 'Dangerous Goods', 'First Aid',
              'Fire & Smoke', 'Security'],
            group: 'Training'),
        _text('memberships', 'Professional memberships', group: 'Recognition'),
        _text('awards', 'Awards & honours', group: 'Recognition'),
        _long('summary', 'Professional summary'),
      ];

  /// Builds a role from its specialized banks + shared common/extras.
  static AviationRole _role(
    String id,
    String title,
    String category,
    List<OnboardingQuestion> specialized, {
    String? description,
  }) {
    return AviationRole(
      id: id,
      title: title,
      category: category,
      description: description,
      questions: [..._common, ...specialized, ..._extras],
    );
  }

  /// The full default catalogue. Grouped by category for the picker.
  static List<AviationRole> get roles => [
        // ── Flight Crew ──
        _role('airline_pilot', 'Airline Pilot', 'Flight Crew', _pilot),
        _role('captain', 'Captain', 'Flight Crew', _pilot),
        _role('first_officer', 'First Officer', 'Flight Crew', _pilot),
        _role('business_jet_pilot', 'Business / Corporate Jet Pilot',
            'Flight Crew', _pilot),
        _role('cargo_pilot', 'Cargo Pilot', 'Flight Crew', _pilot),
        _role('ferry_pilot', 'Ferry Pilot', 'Flight Crew', _pilot),
        _role('flight_engineer', 'Flight Engineer', 'Flight Crew', [
          ..._pilot.take(7),
          _text('systems_experience', 'Aircraft systems experience',
              group: 'Experience'),
        ]),
        // ── Instruction & Training ──
        _role('flight_instructor', 'Flight Instructor', 'Instruction & Training', [
          ..._pilot,
          _multi('instructor_ratings', 'Instructor ratings',
              ['CFI', 'CFII', 'MEI', 'TRI', 'TRE', 'SFI', 'SFE'],
              group: 'Credentials'),
        ]),
        _role('simulator_instructor', 'Simulator Instructor',
            'Instruction & Training', _pilot),
        _role('check_airman', 'Check Airman / Examiner',
            'Instruction & Training', _pilot),
        _role('ground_instructor', 'Ground Instructor',
            'Instruction & Training', [
          _multi('subjects', 'Subjects taught',
              ['Air Law', 'Navigation', 'Meteorology', 'Systems',
                'Human Factors', 'Performance'],
              group: 'Experience'),
        ]),
        // ── Military & Test ──
        _role('military_pilot', 'Military Pilot', 'Military & Test', [
          ..._pilot,
          _text('platforms', 'Military platforms flown', group: 'Experience'),
        ]),
        _role('fighter_pilot', 'Fighter Pilot', 'Military & Test', _pilot),
        _role('transport_pilot', 'Military Transport Pilot', 'Military & Test',
            _pilot),
        _role('test_pilot', 'Test Pilot', 'Military & Test', [
          ..._pilot,
          _bool('test_school', 'Graduate of a test pilot school',
              group: 'Credentials'),
        ]),
        // ── Rotary & Unmanned ──
        _role('helicopter_pilot', 'Helicopter Pilot', 'Rotary & Unmanned', [
          ..._pilot,
          _text('rotary_types', 'Rotorcraft types', group: 'Experience'),
        ]),
        _role('uav_pilot', 'UAV / Drone Pilot', 'Rotary & Unmanned', [
          _multi('uav_certs', 'UAS credentials',
              ['Part 107', 'EASA Open', 'EASA Specific', 'BVLOS', 'None'],
              group: 'Credentials'),
          _text('uav_platforms', 'UAS platforms operated', group: 'Experience'),
          _num('uav_hours', 'UAS operating hours', unit: 'hrs',
              group: 'Experience'),
        ]),
        // ── Engineering & Maintenance ──
        _role('maintenance_engineer', 'Aircraft Maintenance Engineer',
            'Engineering & Maintenance', _maintenance),
        _role('avionics_engineer', 'Avionics Engineer',
            'Engineering & Maintenance', [..._maintenance, ..._avionics]),
        _role('aircraft_mechanic', 'Aircraft Mechanic',
            'Engineering & Maintenance', _maintenance),
        _role('ap_technician', 'A&P Technician',
            'Engineering & Maintenance', _maintenance),
        _role('powerplant_technician', 'Powerplant Technician',
            'Engineering & Maintenance', _maintenance),
        _role('structures_technician', 'Structures Technician',
            'Engineering & Maintenance', _maintenance),
        _role('composite_technician', 'Composite Repair Technician',
            'Engineering & Maintenance', _maintenance),
        _role('maintenance_planner', 'Maintenance Planner',
            'Engineering & Maintenance', [
          _text('planning_systems', 'Planning systems (AMOS, TRAX, etc.)',
              group: 'Experience'),
          _bool('reliability', 'Reliability program experience',
              group: 'Experience'),
        ]),
        _role('qa_inspector', 'Quality Assurance Inspector',
            'Engineering & Maintenance', [..._maintenance, ..._safety]),
        // ── Cabin Services ──
        _role('cabin_crew', 'Cabin Crew', 'Cabin Services', _cabin),
        _role('cabin_supervisor', 'Cabin Supervisor / Purser',
            'Cabin Services', _cabin),
        // ── Operations & Dispatch ──
        _role('flight_dispatcher', 'Flight Dispatcher',
            'Operations & Dispatch', _dispatch),
        _role('flight_ops_officer', 'Flight Operations Officer',
            'Operations & Dispatch', _dispatch),
        _role('ops_controller', 'Operations Controller (OCC)',
            'Operations & Dispatch', _dispatch),
        _role('crew_scheduler', 'Crew Scheduler',
            'Operations & Dispatch', [
          _text('rostering_systems', 'Rostering systems used',
              group: 'Experience'),
          _bool('ftl_knowledge', 'Flight Time Limitations (FTL) knowledge',
              group: 'Skills'),
        ]),
        _role('logistics_coordinator', 'Logistics Coordinator',
            'Operations & Dispatch', [
          _multi('logistics_areas', 'Areas',
              ['AOG', 'Spares', 'Customs', 'Warehousing', 'Freight'],
              group: 'Experience'),
        ]),
        // ── Air Traffic ──
        _role('air_traffic_controller', 'Air Traffic Controller',
            'Air Traffic', _atc),
        // ── Airport & Ground Operations ──
        _role('airport_ops_officer', 'Airport Operations Officer',
            'Airport & Ground Ops', _ground),
        _role('ground_ops_supervisor', 'Ground Operations Supervisor',
            'Airport & Ground Ops', [..._ground, ..._management.take(1)]),
        _role('ramp_agent', 'Ramp Agent', 'Airport & Ground Ops', _ground),
        _role('loadmaster', 'Loadmaster', 'Airport & Ground Ops', [
          ..._ground,
          _bool('load_planning', 'Load planning / W&B experience',
              group: 'Skills'),
        ]),
        _role('fuel_specialist', 'Fuel Operations Specialist',
            'Airport & Ground Ops', _ground),
        _role('aircraft_cleaner', 'Aircraft Cleaner', 'Airport & Ground Ops', [
          _single('shift_pref', 'Shift preference',
              ['Day', 'Night', 'Rotating', 'Any'], group: 'Preferences'),
        ]),
        // ── Safety, Quality & Compliance ──
        _role('safety_officer', 'Safety Officer',
            'Safety, Quality & Compliance', _safety),
        _role('sms_manager', 'SMS Manager',
            'Safety, Quality & Compliance', [..._safety, ..._management]),
        _role('compliance_officer', 'Compliance Officer',
            'Safety, Quality & Compliance', _safety),
        // ── Regulatory & Security ──
        _role('aviation_security_officer', 'Aviation Security Officer',
            'Regulatory & Security', _security),
        _role('regulatory_inspector', 'Regulatory Inspector',
            'Regulatory & Security', [..._safety, ..._security]),
        // ── Management ──
        _role('airport_manager', 'Airport Manager', 'Management',
            _management),
        _role('fleet_manager', 'Fleet Manager', 'Management', _management),
        _role('training_manager', 'Training Manager', 'Management',
            [..._management]),
        _role('aviation_consultant', 'Aviation Consultant', 'Management', [
          _multi('consulting_areas', 'Consulting areas',
              ['Operations', 'Safety', 'Regulatory', 'Commercial',
                'Maintenance', 'Training'],
              group: 'Experience'),
        ]),
        // ── Medical, Weather & Emergency ──
        _role('medical_examiner', 'Aviation Medical Examiner',
            'Medical, Weather & Emergency', [
          _bool('ame_authorized', 'Authorized Aviation Medical Examiner',
              group: 'Credentials'),
          _text('ame_authority', 'Authorizing authority', group: 'Credentials'),
        ]),
        _role('meteorologist', 'Aviation Meteorologist',
            'Medical, Weather & Emergency', [
          _text('forecast_systems', 'Forecasting systems used',
              group: 'Experience'),
        ]),
        _role('rff_personnel', 'Rescue & Fire Fighting (RFF) Personnel',
            'Medical, Weather & Emergency', [
          _bool('rff_certified', 'RFF certified', group: 'Credentials'),
          _bool('hazmat', 'HazMat trained', group: 'Training'),
        ]),
        _role('sar_coordinator', 'Search & Rescue Coordinator',
            'Medical, Weather & Emergency', [..._safety]),
        // ── Other ──
        _role('other', 'Other Aviation Professional', 'Other', [
          _text('role_title', 'Your specific role', group: 'Professional'),
          _long('role_description', 'Describe your role & expertise'),
        ]),
      ];
}
