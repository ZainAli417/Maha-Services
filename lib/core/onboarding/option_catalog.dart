/// Master option lists backing the searchable pickers in the onboarding form
/// engine.
///
/// The role-template specifications call for structured selection over free
/// text wherever a value can be enumerated (ICAO designators, licence classes,
/// regulators, engine models…). Those enumerations live here so several
/// templates can share one list and the admin editor can surface the same
/// choices.
abstract final class OptionCatalog {
  // ── Regulators & authorities ────────────────────────────────────────────
  static const authorities = [
    'FAA (USA)',
    'EASA (Europe)',
    'UK CAA',
    'CASA (Australia)',
    'Transport Canada',
    'GCAA (UAE)',
    'GACA (Saudi Arabia)',
    'DGCA (India)',
    'CAAP (Philippines)',
    'PCAA (Pakistan)',
    'CAAC (China)',
    'ANAC (Brazil)',
    'ICAO',
    'Military Authority',
    'Other NAA',
  ];

  static const militaryBranches = [
    'US Air Force',
    'US Navy',
    'US Marine Corps',
    'US Army',
    'US Coast Guard',
    'Royal Air Force',
    'Royal Navy',
    'British Army',
    'French Air and Space Force',
    'German Luftwaffe',
    'Pakistan Air Force',
    'Indian Air Force',
    'Royal Australian Air Force',
    'Royal Canadian Air Force',
    'UAE Air Force',
    'Royal Saudi Air Force',
    'Other (Specify)',
  ];

  static const employerTypesPilot = [
    'Airline',
    'Military Branch',
    'Charter / Part 135',
    'Corporate / Part 91',
    'Flight School',
    'Government',
    'Emergency Services',
    'Self-Employed',
  ];

  static const employerTypesMaintenance = [
    'Commercial Airline',
    'MRO (Maintenance Repair Org)',
    'Military Branch',
    'General Aviation / FBO',
    'Defense Contractor',
    'Government / Law Enforcement',
  ];

  static const employerTypesSafety = [
    'Commercial Airline (Part 121)',
    'Charter / Part 135',
    'Military Service Arm',
    'MRO / Maintenance Facility',
    'Airport Authority / Operator',
    'Civil Aviation Authority (CAA / FAA)',
    'Defense Contractor',
  ];

  static const airlinesAndOperators = [
    'Emirates', 'Qatar Airways', 'Etihad Airways', 'Turkish Airlines',
    'Lufthansa', 'British Airways', 'Air France', 'KLM', 'Delta Air Lines',
    'United Airlines', 'American Airlines', 'Southwest Airlines',
    'Singapore Airlines', 'Cathay Pacific', 'Qantas', 'Air Canada',
    'Ryanair', 'easyJet', 'IndiGo', 'Saudia', 'Flydubai', 'Air Arabia',
    'Pakistan International Airlines', 'NetJets', 'FedEx Express', 'UPS Airlines',
    'Atlas Air', 'Cargolux', 'DHL Aviation',
  ];

  static const mroOrganizations = [
    'Lufthansa Technik', 'AAR Corp', 'Delta TechOps', 'SR Technics',
    'ST Engineering', 'HAECO', 'AFI KLM E&M', 'Turkish Technic',
    'Emirates Engineering', 'Etihad Engineering', 'GE Aerospace',
    'Rolls-Royce', 'Safran', 'Pratt & Whitney', 'Collins Aerospace',
    'Standard Aero', 'Joramco', 'Sabena Technics',
  ];

  static const employmentStatus = [
    'Employed Full-Time',
    'Active Duty',
    'Reserve / Guard',
    'Contract / Freelance',
    'Furloughed',
    'Unemployed / Seeking Role',
  ];

  static const noticePeriods = [
    'Immediate',
    '15 Days',
    '30 Days',
    '60 Days',
    '90 Days',
  ];

  // ── Aircraft & engines (ICAO designators) ───────────────────────────────
  static const fixedWingTypes = [
    'A319', 'A320', 'A321', 'A20N', 'A21N', 'A332', 'A333', 'A339',
    'A342', 'A343', 'A345', 'A346', 'A359', 'A35K', 'A388',
    'B712', 'B733', 'B734', 'B735', 'B736', 'B737', 'B738', 'B739',
    'B38M', 'B39M', 'B744', 'B748', 'B752', 'B753', 'B762', 'B763',
    'B764', 'B772', 'B773', 'B77L', 'B77W', 'B788', 'B789', 'B78X',
    'E170', 'E175', 'E190', 'E195', 'E290', 'E295',
    'CRJ2', 'CRJ7', 'CRJ9', 'CRJX', 'DH8A', 'DH8C', 'DH8D',
    'AT43', 'AT45', 'AT72', 'AT76', 'SF34', 'J328',
    'C172', 'C182', 'C206', 'C208', 'C210', 'PA28', 'PA34', 'BE20', 'BE58',
    'C25A', 'C25B', 'C525', 'C550', 'C560', 'C56X', 'C680', 'C68A', 'C700',
    'GLF4', 'GLF5', 'GLF6', 'G650', 'G280', 'CL30', 'CL35', 'CL60', 'GL5T',
    'F2TH', 'F900', 'FA7X', 'FA8X', 'E55P', 'E50P', 'LJ45', 'LJ60',
    'C130', 'C17', 'C5M', 'KC135', 'KC46', 'A400', 'C295', 'C27J',
    'F16', 'F15', 'F18', 'F22', 'F35', 'EUFI', 'RFAL', 'MG29', 'SU30',
    'JF17', 'T38', 'HAWK', 'A10', 'B1', 'B52', 'P8', 'E3TF', 'AWACS',
  ];

  static const rotaryWingTypes = [
    'AS50', 'AS55', 'AS65', 'AS32', 'AS332', 'AS350', 'AS365',
    'B06', 'B407', 'B412', 'B429', 'B430', 'B505', 'B525',
    'EC20', 'EC25', 'EC30', 'EC35', 'EC45', 'EC55', 'EC75',
    'H120', 'H125', 'H130', 'H135', 'H145', 'H155', 'H160', 'H175', 'H215',
    'H225', 'S76', 'S92', 'S70', 'AW09', 'AW109', 'AW139', 'AW169', 'AW189',
    'R22', 'R44', 'R66', 'MD50', 'MD90',
    'AH64', 'UH60', 'CH47', 'CH53', 'MI8', 'MI17', 'MI24', 'UH1', 'OH58',
  ];

  static const engineModels = [
    'CFM56-3', 'CFM56-5B', 'CFM56-7B', 'LEAP-1A', 'LEAP-1B',
    'V2500', 'PW1100G', 'PW1500G', 'PW4000', 'PW2000', 'PW127', 'PW150',
    'GE90', 'GEnx-1B', 'GEnx-2B', 'GE9X', 'CF6-80', 'CF34-8', 'CF34-10',
    'Trent 700', 'Trent 800', 'Trent 900', 'Trent 1000', 'Trent XWB',
    'RB211', 'BR710', 'BR725', 'AE3007', 'PT6A', 'PT6C', 'TPE331',
    'T700', 'T58', 'T64', 'Arriel 1', 'Arriel 2', 'Arrius', 'Makila',
    'F110', 'F100', 'F119', 'F135', 'F404', 'F414', 'TF33', 'T56', 'AE2100',
    'APU GTCP131', 'APU GTCP331', 'APU APS3200', 'APU RE220',
  ];

  static const typeRatingCodes = [
    'A320 (A319/320/321)', 'A330', 'A350', 'A380', 'B737 (NG)', 'B737 MAX',
    'B747', 'B757/767', 'B777', 'B787', 'E170/190', 'CRJ Series',
    'DHC-8', 'ATR 42/72', 'CL-604/605 (CL60)', 'CL-350', 'GLEX',
    'G450/G550 (GLF5)', 'G650 (GLF6)', 'Falcon 900', 'Falcon 7X',
    'Citation 500 Series', 'Citation 525', 'Citation 560XL', 'Citation Latitude',
    'Legacy / Praetor', 'Phenom 100/300', 'King Air (BE20)',
    'Bell 412 (B412)', 'Sikorsky S-92 (SK92)', 'AW139', 'H145', 'H175',
  ];

  static const aircraftVariants = [
    'B737-800', 'B737-900ER', 'B737 MAX 8', 'B737 MAX 9', 'A320neo',
    'A321neo', 'A321LR', 'A330-900neo', 'A350-1000', 'B787-9', 'B777-300ER',
    'Bell 412EPI', 'AW139 Long Nose', 'S-92A', 'H145 D3',
  ];

  // ── Licensing ───────────────────────────────────────────────────────────
  static const pilotLicenseLevels = [
    'ATPL (Airline Transport)',
    'CPL (Commercial)',
    'MPL (Multi-Crew)',
    'PPL (Private)',
    'Military Rating / Wings',
  ];

  static const pilotClassRatings = [
    'Single-Engine Land (SEL)',
    'Multi-Engine Land (MEL)',
    'Single-Engine Sea (SES)',
    'Multi-Engine Sea (MES)',
    'Helicopter',
    'Instrument Rating (IR)',
  ];

  static const instructorRatings = [
    'None',
    'CFI',
    'CFII (Instrument)',
    'MEI (Multi-Engine)',
    'TRI (Type Rating Instructor)',
    'TRE (Type Rating Examiner)',
    'SFI (Synthetic Flight Instructor)',
    'SFE (Synthetic Flight Examiner)',
  ];

  static const medicalClasses = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Military Flight Physical',
  ];

  static const englishProficiency = [
    'Level 4 (Operational)',
    'Level 5 (Extended)',
    'Level 6 (Expert)',
  ];

  static const faaLicenses = [
    'Airframe (A)',
    'Powerplant (P)',
    'Full A&P License',
    'Inspection Authorization (IA)',
    'FCC General Radiotelephone (GROL)',
  ];

  static const easaPart66Licenses = [
    'Category A (Line Maintenance)',
    'Category B1.1 (Fixed-Wing Turbine)',
    'Category B1.2 (Fixed-Wing Piston)',
    'Category B1.3 (Helicopter Turbine)',
    'Category B1.4 (Helicopter Piston)',
    'Category B2 (Avionics)',
    'Category B3',
    'Category C (Base Maintenance)',
  ];

  static const militarySpecialtyCodes = [
    'USAF AFSC 2A3X3 (Tactical Aircraft Maintenance)',
    'USAF AFSC 2A6X1 (Aerospace Propulsion)',
    'USAF AFSC 2A5X1 (Airlift/Special Mission Maintenance)',
    'USAF AFSC 2A6X6 (Electrical & Environmental)',
    'US Navy NEC 8300 (Aviation Maintenance)',
    'US Navy NEC 8342 (Avionics)',
    'US Army MOS 15T (UH-60 Repairer)',
    'US Army MOS 15U (CH-47 Repairer)',
    'US Army MOS 15Y (AH-64 Armament)',
    'US Army MOS 15N (Avionics Mechanic)',
    'USMC MOS 6112 (Helicopter Mechanic)',
    'Other (Specify)',
  ];

  static const securityClearances = [
    'None',
    'Confidential',
    'Secret',
    'Top Secret',
    'TS/SCI',
    'NATO Secret',
  ];

  // ── Mission & sector ────────────────────────────────────────────────────
  static const commercialSectors = [
    'Part 121 (Major/Regional Airline)',
    'Part 135 (On-Demand Charter)',
    'Part 91 (Corporate)',
    'ETOPS',
    'CAT II/III Precision Approach',
    'Long-Haul',
    'Short-Haul',
    'Cargo / Freight',
  ];

  static const militaryProfiles = [
    'Tactical / Fighter',
    'Strategic Airlift / Heavy',
    'Combat SAR',
    'Special Operations',
    'Maritime Patrol',
    'Air Refueling',
    'Reconnaissance / ISR',
    'Training Command',
  ];

  static const helicopterMissions = [
    'Offshore / Oil & Gas (Helideck)',
    'HEMS / Air Ambulance',
    'Hoist / Sling / External Load',
    'Firefighting / Bambi Bucket',
    'VIP / Corporate',
    'Mountain Flying',
    'Law Enforcement / Police',
    'Utility / Powerline',
  ];

  // ── Maintenance trades ──────────────────────────────────────────────────
  static const maintenanceTrades = [
    'Airframe',
    'Powerplant / Engine',
    'Avionics & Electrical',
    'Armament / Weapons Systems',
    'Structures / Sheet Metal',
    'Composites',
    'Hydraulics / Pneumatics',
    'NDT / Inspection',
    'Workshop / Component Overhaul',
  ];

  static const airframeSystems = [
    'Landing Gear',
    'Flight Controls',
    'Environmental Control Systems (ECS)',
    'Fuel Systems',
    'Hydraulics',
    'Pneumatics',
    'Rigging',
  ];

  static const powerplantSkills = [
    'Turbofan',
    'Turboprop',
    'Turboshaft (Helicopter)',
    'Piston Engines',
    'APU (Auxiliary Power Unit)',
    'Engine Run-up Qualified',
    'Borescope Inspection',
  ];

  static const avionicsSkills = [
    'Navigation Systems',
    'Radar & Sensor Systems',
    'Flight Deck / Glass Cockpit',
    'Wiring / Wire Harness Fabrication',
    'Auto-Flight / Autopilot',
    'IFE (In-Flight Entertainment)',
    'Communications / SATCOM',
  ];

  static const armamentSkills = [
    'Gun Systems / Cannons',
    'Missile Launch Rails',
    'Bomb Racks / Stores Management',
    'Ordnance Handling',
    'Ejection Seat / Escape Systems',
    'Defensive Countermeasures (Chaff/Flare)',
  ];

  static const structuresNdtSkills = [
    'Sheet Metal Repair',
    'Carbon Fiber / Composite Repair',
    'Structural Inspection',
    'NDT Level I',
    'NDT Level II',
    'NDT Level III',
    'Eddy Current',
    'Ultrasonic',
    'Radiographic',
    'Dye Penetrant',
  ];

  static const maintenanceEnvironments = [
    'Line Maintenance',
    'Base / Heavy Maintenance',
    'Engine MRO Shop',
    'Component / Backshop',
    'Flight Line (Military)',
    'Depot Level Maintenance',
  ];

  static const signOffAuthorizations = [
    'Company Certifying Staff (CRS)',
    'Run-Up & Taxi Authorization',
    'RII (Required Inspection Item) Inspector',
    'Dual Release (EASA/FAA)',
  ];

  static const toolboxStatus = [
    'Has Own Shadowed/Etched Mechanics Toolkit',
    'Minimum Toolkit Available',
    'No Own Tools (Requires Facility Tools)',
  ];

  // ── Safety ──────────────────────────────────────────────────────────────
  static const safetyRoles = [
    'Safety Manager (SMS)',
    'Flight Safety Officer (FSO)',
    'Ground Safety Officer',
    'Maintenance Safety Manager',
    'Flight Data Analyst (FDA/FOQA)',
    'Quality & Safety Auditor',
    'Accident Investigator',
    'Risk & Compliance Manager',
  ];

  static const safetyBackgrounds = [
    'Pilot Background (Fixed-Wing)',
    'Pilot Background (Helicopter)',
    'Aircraft Mechanic / Technician (A&P / Part-66)',
    'Air Traffic Controller (ATC)',
    'Flight Dispatcher / Operations',
    'Military Aviation Safety',
    'Airport Operations',
  ];

  static const safetyDisciplines = [
    'Safety Management Systems (SMS)',
    'Flight Data Monitoring (FDM / FOQA)',
    'Aircraft Accident & Incident Investigation',
    'Human Factors & CRM',
    'Quality Assurance (QA) & Compliance',
    'Flight Operational Quality Assurance',
    'Airworthiness & Maintenance Safety',
    'Emergency Response Planning (ERP)',
    'Airport & Ramp Safety',
  ];

  static const flightSafetySkills = [
    'FOQA / FDM Data Analysis',
    'Line Operations Safety Audit (LOSA)',
    'Flight Crew Human Factors',
    'CRM / TEM Instructor',
    'Runway Safety / Incursion Prevention',
    'Airspace / Airfield Hazard Analysis',
  ];

  static const maintenanceSafetySkills = [
    'Maintenance Human Factors (MEDA)',
    'Maintenance Error Investigation',
    'Tooling & FOD Prevention',
    'Airworthiness Risk Assessment',
    'Hangars & Ramp Safety',
    'Hazardous Material (Hazmat / Dangerous Goods)',
  ];

  static const smsSkills = [
    'SMS Development & Rollout (ICAO Doc 9859)',
    'Hazard Identification & Risk Assessment (HIRA)',
    'Safety Risk Management (SRM)',
    'Safety Assurance & Performance Indicators (SPIs / SPTs)',
    'Just Culture Implementation',
  ];

  static const investigationMethods = [
    'ICAO Annex 13 Accident Investigation',
    'Root Cause Analysis (RCA)',
    'BowTie Analysis',
    '5 Whys',
    'IATA Operational Safety Audit (IOSA)',
    'IS-BAO / IS-BAH Auditing',
    'Regulatory Compliance Auditing',
  ];

  static const safetyCredentials = [
    'ICAO / FAA / EASA SMS Manager Certificate',
    'Qualified Aircraft Accident Investigator',
    'Certified Safety Professional (CSP)',
    'CMIOSH',
    'NEBOSH International General Certificate (IGC)',
    'NEBOSH Health & Safety at Work Award (HSA)',
    'NEBOSH International Diploma',
    'NEBOSH Environmental Management Certificate',
    'ISO 45001 Lead Auditor',
    'ISO 9001 Lead Auditor',
    'IOSA Auditor',
    'CRM / Human Factors Facilitator',
  ];

  static const safetyBodies = [
    'FAA',
    'EASA',
    'ICAO',
    'UK CAA',
    'BCSP',
    'NEBOSH',
    'CQI / IRCA',
    'IATA Training Institute',
    'Military Safety Center',
  ];

  static const safetySoftware = [
    'Coruson (Ideagen)',
    'Q-Pulse',
    'AQD',
    'Flight Data Connect',
    'CEFA FAS',
    'BowTieXP',
    'SMS Pro',
    'EtQ Reliance',
    'Vistair',
    'Custom Safety Reporting System',
  ];

  static const aviationSectors = [
    'Commercial Airlines (Passenger)',
    'Commercial Airlines (Cargo)',
    'Military Aviation (Tactical)',
    'Military Aviation (Heavy / Transport)',
    'Military Aviation (Rotary)',
    'General Aviation / VIP Corporate',
    'MRO & Heavy Maintenance',
    'Airport Authorities & Airfield Operations',
    'Rotary-Wing / Offshore HEMS',
  ];

  static const erpRoles = [
    'Crisis Management Team Lead',
    'Emergency Command Center Operator',
    'Go-Team / On-Scene Commander',
    'Family Assistance Program Lead',
  ];

  // ── Cabin crew ──────────────────────────────────────────────────────────
  static const cabinPositions = [
    'Cabin Crew',
    'Senior Cabin Crew',
    'Purser',
    'Cabin Services Manager',
  ];

  static const cabinTraining = [
    'Safety & Emergency Procedures (SEP)',
    'First Aid / AED',
    'Dangerous Goods',
    'Aviation Security (AVSEC)',
    'CRM',
    'Premium Cabin Service',
    'Ditching / Water Survival',
  ];

  // ── Engineering & technology ────────────────────────────────────────────
  static const programmingLanguages = [
    'Dart', 'JavaScript', 'TypeScript', 'Python', 'Java', 'Kotlin', 'Swift',
    'Go', 'Rust', 'C', 'C++', 'C#', 'Ruby', 'PHP', 'Scala', 'Elixir', 'SQL',
    'Bash / Shell',
  ];

  static const frameworks = [
    'Flutter', 'React', 'Next.js', 'Angular', 'Vue', 'Svelte', 'Node.js',
    'Express', 'NestJS', 'Django', 'FastAPI', 'Flask', 'Spring Boot',
    '.NET', 'Rails', 'Laravel', 'React Native', 'SwiftUI', 'Jetpack Compose',
  ];

  static const cloudPlatforms = [
    'AWS', 'Google Cloud', 'Microsoft Azure', 'Firebase', 'Vercel',
    'DigitalOcean', 'Cloudflare', 'Heroku', 'On-Premise / Bare Metal',
  ];

  static const devopsTools = [
    'Docker', 'Kubernetes', 'Terraform', 'Ansible', 'Pulumi', 'Helm',
    'Jenkins', 'GitHub Actions', 'GitLab CI', 'CircleCI', 'ArgoCD',
    'Prometheus', 'Grafana', 'Datadog', 'ELK Stack', 'Sentry',
    'Nginx', 'Kafka', 'RabbitMQ', 'Redis',
  ];

  static const databases = [
    'PostgreSQL', 'MySQL', 'MongoDB', 'Firestore', 'DynamoDB', 'Redis',
    'Cassandra', 'Elasticsearch', 'BigQuery', 'Snowflake', 'SQLite',
    'Oracle', 'SQL Server',
  ];

  static const engineeringSpecialties = [
    'Frontend', 'Backend', 'Full-Stack', 'Mobile', 'Platform / Infrastructure',
    'Data Engineering', 'Machine Learning', 'Security', 'QA / Test Automation',
    'Embedded / Firmware', 'Site Reliability',
  ];

  static const seniorityLevels = [
    'Intern',
    'Junior (0-2 yrs)',
    'Mid-Level (2-5 yrs)',
    'Senior (5-8 yrs)',
    'Staff / Lead (8-12 yrs)',
    'Principal / Architect (12+ yrs)',
    'Engineering Manager',
    'Director / VP',
  ];

  // ── Universal ───────────────────────────────────────────────────────────
  static const countries = [
    'Afghanistan', 'Australia', 'Austria', 'Bahrain', 'Bangladesh', 'Belgium',
    'Brazil', 'Canada', 'China', 'Denmark', 'Egypt', 'Ethiopia', 'France',
    'Germany', 'Ghana', 'Greece', 'Hong Kong', 'India', 'Indonesia', 'Iraq',
    'Ireland', 'Italy', 'Japan', 'Jordan', 'Kenya', 'Kuwait', 'Lebanon',
    'Malaysia', 'Maldives', 'Mexico', 'Morocco', 'Nepal', 'Netherlands',
    'New Zealand', 'Nigeria', 'Norway', 'Oman', 'Pakistan', 'Philippines',
    'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia', 'Saudi Arabia',
    'Singapore', 'South Africa', 'South Korea', 'Spain', 'Sri Lanka', 'Sweden',
    'Switzerland', 'Thailand', 'Turkey', 'Ukraine', 'United Arab Emirates',
    'United Kingdom', 'United States', 'Vietnam', 'Other',
  ];

  static const workAuthorization = [
    'Citizen — no sponsorship required',
    'Permanent Resident',
    'Valid Work Visa (current country)',
    'GCC Residency / Iqama',
    'EU Work Permit',
    'US H-1B',
    'US Green Card',
    'UK Skilled Worker Visa',
    'Requires Sponsorship',
    'Open to Relocation with Sponsorship',
  ];

  static const languages = [
    'English', 'Arabic', 'French', 'Spanish', 'German', 'Mandarin', 'Hindi',
    'Urdu', 'Russian', 'Portuguese', 'Italian', 'Turkish', 'Japanese',
    'Korean', 'Bengali', 'Malay', 'Dutch', 'Swahili',
  ];

  static const educationLevels = [
    'High School',
    'Diploma',
    'Associate Degree',
    'Bachelor Degree',
    'Master Degree',
    'Doctorate',
    'Military Academy / Training',
    'Vocational / Technical',
  ];

  static const employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Seasonal',
    'Rotational (FIFO)',
  ];

  static const regions = [
    'North America',
    'Latin America',
    'Europe',
    'Middle East',
    'Africa',
    'South Asia',
    'East Asia',
    'Southeast Asia',
    'Oceania',
  ];
  /// Study fields the candidates on this platform actually hold, so the
  /// education row is a pick rather than free text. `allowCustom` stays on
  /// wherever this is used — the list is a shortcut, not a gate.
  static const fieldsOfStudy = [
    'Aeronautical Engineering',
    'Aerospace Engineering',
    'Aircraft Maintenance Engineering',
    'Avionics Engineering',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Electronics & Communication Engineering',
    'Civil Engineering',
    'Industrial Engineering',
    'Computer Science',
    'Software Engineering',
    'Information Technology',
    'Data Science',
    'Cybersecurity',
    'Aviation Management',
    'Air Transport Management',
    'Airport Operations',
    'Aviation Safety',
    'Occupational Health & Safety',
    'Air Traffic Management',
    'Flight Operations / Dispatch',
    'Meteorology',
    'Logistics & Supply Chain',
    'Business Administration',
    'Human Resources',
    'Finance & Accounting',
    'Physics',
    'Mathematics',
    'Military Science',
    'Other',
  ];

  /// Bodies that issue the certificates candidates list. Deliberately built
  /// from the authority, safety-body, operator and MRO catalogues rather than
  /// retyped, so a rename in one place cannot leave this list stale.
  static final List<String> certificationIssuers = <String>{
    ...authorities,
    ...safetyBodies,
    ...airlinesAndOperators,
    ...mroOrganizations,
  }.toList()
    ..sort();
}
