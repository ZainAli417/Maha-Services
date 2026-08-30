import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Recruiter/LIst_of_Applicants_provider.dart';

/// A candidate with sensible defaults, so each test states only what it cares
/// about.
FilterableCandidate candidate({
  String name = 'jane',
  String status = 'pending',
  String jobTitle = 'Cyber Defence',
  String location = 'Islamabad, Pakistan',
  String country = 'Pakistan',
  String education = 'Aviation Sciences',
  String nationality = 'Pakistan',
  String professionalStatus = 'retired',
  String targetRole = 'Fighter Pilot',
  String retirementDate = '',
  bool sentToAdmin = false,
  List<String> aircraftTypes = const ['F16'],
  List<String> licences = const ['ATPL'],
  List<String> degrees = const ['BSc Aviation Sciences'],
  List<String> skills = const ['Formation Lead'],
  num? flightHours = 2680,
  num? yearsOfExperience,
  bool hasCertifications = true,
  bool hasPublications = false,
  bool hasAwards = false,
  DateTime? appliedAt,
  int? aiScore,
  String testStatus = '',
  int? testPercentage,
  String testVerdict = '',
}) =>
    (
      searchIndex: name,
      status: status,
      jobTitle: jobTitle,
      location: location,
      country: country,
      education: education,
      nationality: nationality,
      professionalStatus: professionalStatus,
      targetRole: targetRole,
      retirementDate: retirementDate,
      sentToAdmin: sentToAdmin,
      aircraftTypes: aircraftTypes,
      licences: licences,
      degrees: degrees,
      skills: skills,
      flightHours: flightHours,
      yearsOfExperience: yearsOfExperience,
      hasCertifications: hasCertifications,
      hasPublications: hasPublications,
      hasAwards: hasAwards,
      appliedAt: appliedAt ?? DateTime(2026, 8, 30),
      aiScore: aiScore,
      testStatus: testStatus,
      testPercentage: testPercentage,
      testVerdict: testVerdict,
    );

/// A spec with everything off, so each test switches on one thing.
ApplicantFilterSpec spec({
  String query = '',
  String status = 'All',
  String job = 'All',
  String location = 'All',
  String country = 'All',
  String education = 'All',
  String nationality = 'All',
  String professionalStatus = 'All',
  String retirement = 'All',
  Set<String> roles = const {},
  Set<String> aircraft = const {},
  Set<String> licences = const {},
  Set<String> degrees = const {},
  Set<String> skills = const {},
  num minFlightHours = 0,
  num minYears = 0,
  String testStage = 'All',
  num minAiScore = 0,
  num minTestScore = 0,
  bool matchAll = false,
  bool unreviewedOnly = false,
  bool certs = false,
  bool pubs = false,
  bool awards = false,
  DateTimeRange? dateRange,
}) =>
    ApplicantFilterSpec(
      query: query,
      status: status,
      job: job,
      location: location,
      country: country,
      education: education,
      nationality: nationality,
      professionalStatus: professionalStatus,
      retirement: retirement,
      roles: roles,
      aircraft: aircraft,
      licences: licences,
      degrees: degrees,
      skills: skills,
      minFlightHours: minFlightHours,
      minYears: minYears,
      testStage: testStage,
      minAiScore: minAiScore,
      minTestScore: minTestScore,
      matchAll: matchAll,
      unreviewedOnly: unreviewedOnly,
      certs: certs,
      pubs: pubs,
      awards: awards,
      dateRange: dateRange,
    );

void main() {
  group('a filter nobody set excludes nobody', () {
    test('an empty spec passes everyone', () {
      expect(spec().matches(candidate()), isTrue);
      expect(
        spec().matches(candidate(
          aircraftTypes: const [],
          licences: const [],
          skills: const [],
          degrees: const [],
          flightHours: null,
        )),
        isTrue,
      );
    });

    test('an empty multi-select does not exclude a candidate with no values',
        () {
      // The regression that matters: filtering on nothing must not quietly
      // drop everyone whose role template has no aircraft or licences.
      expect(
        spec().matches(candidate(aircraftTypes: const [], licences: const [])),
        isTrue,
      );
    });
  });

  group('multi-select match mode', () {
    final pilot = candidate(aircraftTypes: const ['F16', 'JF17']);

    test('any: one overlapping value is enough', () {
      expect(spec(aircraft: {'F16', 'C130'}).matches(pilot), isTrue);
    });

    test('all: every chosen value must be present', () {
      expect(
        spec(aircraft: {'F16', 'C130'}, matchAll: true).matches(pilot),
        isFalse,
      );
      expect(
        spec(aircraft: {'F16', 'JF17'}, matchAll: true).matches(pilot),
        isTrue,
      );
    });
  });

  group('hours and years are separate measures', () {
    test('a flight-hours threshold keeps candidates at or above it', () {
      expect(spec(minFlightHours: 2000).matches(candidate()), isTrue);
      expect(
        spec(minFlightHours: 3000).matches(candidate(flightHours: 2680)),
        isFalse,
      );
    });

    test('a flight-hours threshold excludes candidates who do not fly', () {
      // A loadmaster has no hours because hours are not part of the job.
      // Treating that as zero would be the same as "has flown nothing", which
      // is a different claim.
      expect(
        spec(minFlightHours: 100).matches(
          candidate(flightHours: null, yearsOfExperience: 14),
        ),
        isFalse,
      );
    });

    test('a years threshold does not read flight hours', () {
      // The bug this replaced: one pooled number meant "at least 500" matched
      // 500 hours and 500 years alike, so every pilot passed a years filter.
      expect(
        spec(minYears: 500).matches(candidate(flightHours: 2680)),
        isFalse,
      );
      expect(
        spec(minYears: 10).matches(
          candidate(flightHours: null, yearsOfExperience: 14),
        ),
        isTrue,
      );
    });

    test('zero means no lower bound on either measure', () {
      expect(
        spec().matches(
          candidate(flightHours: null, yearsOfExperience: null),
        ),
        isTrue,
      );
    });

    test('both thresholds together demand both measures', () {
      final pilot = candidate(flightHours: 2680, yearsOfExperience: 16);
      expect(
        spec(minFlightHours: 2000, minYears: 10).matches(pilot),
        isTrue,
      );
      expect(
        spec(minFlightHours: 2000, minYears: 20).matches(pilot),
        isFalse,
      );
    });
  });

  group('single-value filters', () {
    test('match case-insensitively', () {
      expect(
        spec(professionalStatus: 'RETIRED').matches(candidate()),
        isTrue,
      );
      expect(spec(status: 'Pending').matches(candidate()), isTrue);
    });

    test('exclude a candidate whose value differs', () {
      expect(
        spec(country: 'United Arab Emirates').matches(candidate()),
        isFalse,
      );
    });
  });

  group('role filter', () {
    test('is exact, not an overlap test', () {
      // Role is one value per candidate, so "any of these roles" is a
      // membership check rather than the list intersection used elsewhere.
      expect(
        spec(roles: {'Fighter Pilot', 'Test Pilot'}).matches(candidate()),
        isTrue,
      );
      expect(spec(roles: {'Loadmaster'}).matches(candidate()), isFalse);
    });
  });

  group('unreviewed only', () {
    test('hides candidates already sent to the admin', () {
      expect(
        spec(unreviewedOnly: true).matches(candidate(sentToAdmin: true)),
        isFalse,
      );
      expect(spec(unreviewedOnly: true).matches(candidate()), isTrue);
    });
  });

  group('retirement window', () {
    String inYears(double years) => DateTime.now()
        .add(Duration(days: (years * 365).round()))
        .toIso8601String();

    test('bands are exclusive of one another', () {
      final soon = candidate(retirementDate: inYears(0.5));
      expect(spec(retirement: 'Within 1 Year').matches(soon), isTrue);
      expect(spec(retirement: '1-3 Years').matches(soon), isFalse);
    });

    test('a candidate with no retirement date is excluded, not crashed on', () {
      expect(
        spec(retirement: 'Within 1 Year').matches(candidate()),
        isFalse,
      );
      expect(
        spec(retirement: 'Within 1 Year')
            .matches(candidate(retirementDate: 'sometime next year')),
        isFalse,
      );
    });
  });

  group('applied date range', () {
    test('includes the whole end day', () {
      // The end date is a day, not an instant. Someone who applied at 4pm on
      // the last day of the range still applied within it.
      final range = DateTimeRange(
        start: DateTime(2026, 8, 29),
        end: DateTime(2026, 8, 30),
      );
      expect(
        spec(dateRange: range)
            .matches(candidate(appliedAt: DateTime(2026, 8, 30, 16))),
        isTrue,
      );
      expect(
        spec(dateRange: range)
            .matches(candidate(appliedAt: DateTime(2026, 8, 28))),
        isFalse,
      );
    });
  });

  group('record flags', () {
    test('only exclude when the flag is on', () {
      expect(spec(awards: true).matches(candidate(hasAwards: false)), isFalse);
      expect(spec(awards: true).matches(candidate(hasAwards: true)), isTrue);
      expect(spec().matches(candidate(hasAwards: false)), isTrue);
    });
  });

  group('search query', () {
    test('matches against the prebuilt index', () {
      expect(spec(query: 'jane').matches(candidate(name: 'jane doe')), isTrue);
      expect(spec(query: 'zzz').matches(candidate(name: 'jane doe')), isFalse);
    });
  });

  test('filters combine as AND', () {
    final c = candidate(flightHours: 2680, country: 'Pakistan');
    expect(spec(minFlightHours: 2000, country: 'Pakistan').matches(c), isTrue);
    expect(spec(minFlightHours: 3000, country: 'Pakistan').matches(c), isFalse);
  });

  group('assessment stage', () {
    test('"Not invited" finds only candidates with no assessment at all', () {
      final s = spec(testStage: 'Not invited');
      expect(s.matches(candidate(testStatus: '')), isTrue);
      expect(s.matches(candidate(testStatus: 'invited')), isFalse);
      expect(s.matches(candidate(testStatus: 'submitted')), isFalse);
    });

    test('"In progress" covers accepted as well as started', () {
      final s = spec(testStage: 'In progress');
      expect(s.matches(candidate(testStatus: 'accepted')), isTrue);
      expect(s.matches(candidate(testStatus: 'in_progress')), isTrue);
      expect(s.matches(candidate(testStatus: 'invited')), isFalse);
    });

    test('"Completed" is about sitting the test, not about the score', () {
      final s = spec(testStage: 'Completed');
      // Submitted but not yet released: the recruiter has no number, and the
      // stage filter must still find them.
      expect(s.matches(candidate(testStatus: 'submitted', testVerdict: '')), isTrue);
      expect(s.matches(candidate(testStatus: 'expired')), isFalse);
    });

    test('"Passed" and "Failed" only match a released verdict', () {
      expect(
        spec(testStage: 'Passed')
            .matches(candidate(testStatus: 'submitted', testVerdict: 'pass')),
        isTrue,
      );
      expect(
        spec(testStage: 'Passed')
            .matches(candidate(testStatus: 'submitted', testVerdict: 'fail')),
        isFalse,
      );
      // Sat the test, score not released yet — there is no verdict to match,
      // so claiming they passed would be inventing one.
      expect(
        spec(testStage: 'Passed')
            .matches(candidate(testStatus: 'submitted', testVerdict: '')),
        isFalse,
      );
      expect(
        spec(testStage: 'Failed')
            .matches(candidate(testStatus: 'submitted', testVerdict: 'fail')),
        isTrue,
      );
    });

    test('"All" leaves everyone in', () {
      final s = spec();
      for (final status in ['', 'invited', 'in_progress', 'submitted', 'expired']) {
        expect(s.matches(candidate(testStatus: status)), isTrue, reason: status);
      }
    });
  });

  group('score thresholds', () {
    // Same rule as flight hours: an absent score is not a low score. A
    // candidate nobody has analysed has not been judged, and a threshold that
    // silently reads them as 0 quietly buries them.
    test('an AI threshold excludes an unanalysed candidate', () {
      final s = spec(minAiScore: 60);
      expect(s.matches(candidate(aiScore: 82)), isTrue);
      expect(s.matches(candidate(aiScore: 41)), isFalse);
      expect(s.matches(candidate(aiScore: null)), isFalse);
    });

    test('a test threshold excludes someone who has not sat it', () {
      final s = spec(minTestScore: 70);
      expect(s.matches(candidate(testPercentage: 85)), isTrue);
      expect(s.matches(candidate(testPercentage: 55)), isFalse);
      expect(s.matches(candidate(testPercentage: null)), isFalse);
    });

    test('a test threshold ignores the AI score, and the other way round', () {
      // The two are different measurements of different things. Pooling them
      // is exactly the mistake that made one "min 500" match flight hours and
      // years alike.
      expect(spec(minTestScore: 70).matches(candidate(aiScore: 95, testPercentage: 20)),
          isFalse);
      expect(spec(minAiScore: 70).matches(candidate(aiScore: 20, testPercentage: 95)),
          isFalse);
    });

    test('zero means no threshold, so an unscored candidate still shows', () {
      expect(spec().matches(candidate(aiScore: null, testPercentage: null)), isTrue);
    });
  });

  group('a spec is scope-agnostic', () {
    // The shortlist screen filters the people already shortlisted for one job,
    // not every applicant. That works because the spec only ever answers
    // "does this one candidate pass" — the caller decides which list to run it
    // over. The bug it replaced ran the filter against the whole pool and
    // handed a 17-person shortlist back all 20 applicants.
    test('evaluates each candidate independently', () {
      final s = spec(roles: {'Fighter Pilot'});
      final pool = [
        candidate(targetRole: 'Fighter Pilot'),
        candidate(targetRole: 'Loadmaster'),
        candidate(targetRole: 'Fighter Pilot'),
      ];
      final shortlist = pool.take(2).toList();

      expect(pool.where(s.matches).length, 2);
      expect(shortlist.where(s.matches).length, 1);
    });
  });
}
