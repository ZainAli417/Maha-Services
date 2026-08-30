// One-off dev seeder: creates 20 Firebase Auth accounts and writes a complete
// candidate profile for each.
//
// Run with:  flutter test tool/seed/seed_candidates.dart
//
// It is a test file only because that is the runner with Flutter's package
// resolution — nothing here is a test. The point of going through Dart rather
// than a shell script is [ProfileProjector]: the projected personalInfo and
// roleSpecificData are produced by the same code the onboarding form uses, so
// the seeded documents cannot drift from what the app writes.
//
// Firestore is reached over REST with each user's own ID token, so the writes
// satisfy the same `isUser(uid)` rule the app does.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:job_portal/core/onboarding/models/aviation_role.dart';
import 'package:job_portal/core/onboarding/models/candidate_profile.dart';
import 'package:job_portal/core/onboarding/profile_projector.dart';
import 'package:job_portal/core/onboarding/role_templates.dart';

const _projectId = 'unisoft-tmp';
const _apiKey = 'AIzaSyCY36OFEa0K9qo9IHt7X9en6QE2gL0Duyc';
const _password = 'Zain@12345';

const _identity = 'https://identitytoolkit.googleapis.com/v1/accounts';
const _firestore =
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

void main() {
  test('seed 20 Pakistan Air Force candidates', () async {
    final personas = jsonDecode(
      File('tool/seed/personas.json').readAsStringSync(),
    ) as List;

    final templates = {
      for (final t in RoleTemplateCatalogue.templates) t.id: t,
    };

    // A partial run is normal — the network can drop halfway through 20 round
    // trips. `SEED_SLOTS=16,17,18` re-seeds just those, so a retry does not
    // rewrite the documents that already landed.
    final only = (Platform.environment['SEED_SLOTS'] ?? '')
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();

    final created = <String>[];
    final failed = <String>[];

    for (final raw in personas) {
      final p = Map<String, dynamic>.from(raw as Map);
      final slot = p['slot'] as int;
      if (only.isNotEmpty && !only.contains(slot)) continue;
      final email = 'zain$slot@mail.com';
      final template = templates[p['roleId']];

      if (template == null) {
        failed.add('$email — no template "${p['roleId']}"');
        continue;
      }

      try {
        final auth = await _signUp(email, _password);
        final uid = auth.uid;
        final profile = _buildProfile(uid, p, template);

        // `toJson` stamps lastUpdated with a server sentinel, which has no
        // REST equivalent — replace it with a real time before encoding.
        final json = profile.toJson()
          ..['lastUpdated'] = DateTime.now().toUtc();

        await _write('Job_Seeker/$uid', {
          'uid': uid,
          'candidateProfile': json,
        }, auth.idToken);

        await _write('users/$uid', {
          'uid': uid,
          'name': p['name'],
          'email': email,
          'role': 'Job Seeker',
          'isNew': 'no',
          'account_status': 'active',
          'user_lvl': 'basic',
          'is_verified': true,
          'job_alerts_enabled': true,
          'onboarding_completed': true,
          'onboarding_status': 'completed',
          'targetRole': profile.targetRole.toJson(),
          'created_at': DateTime.now().toUtc(),
          'profileCompletedAt': DateTime.now().toUtc(),
        }, auth.idToken);

        created.add('$email  $uid  ${p['name']} — ${template.title}');
        // ignore: avoid_print
        print('✅ $email  $uid  ${p['name']} — ${template.title}');
      } catch (e) {
        failed.add('$email — $e');
        // ignore: avoid_print
        print('❌ $email — $e');
      }
    }

    // Append on a filtered re-run: overwriting would drop the accounts an
    // earlier pass already recorded, which is exactly when you need the list.
    File('tool/seed/created_accounts.txt').writeAsStringSync(
      '${created.join('\n')}\n',
      mode: only.isEmpty ? FileMode.write : FileMode.append,
    );

    // ignore: avoid_print
    print('\n${created.length} created, ${failed.length} failed');
    for (final f in failed) {
      // ignore: avoid_print
      print('   $f');
    }
    expect(failed, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Builds the same document the onboarding form would have written.
CandidateProfile _buildProfile(
  String uid,
  Map<String, dynamic> p,
  RoleTemplate template,
) {
  final answers = Map<String, dynamic>.from(p['answers'] as Map);
  final projected = ProfileProjector.project(template, answers);

  return CandidateProfile(
    uid: uid,
    targetRole: TargetRole(
      industry: template.industry,
      roleId: template.id,
      roleTitle: template.title,
    ),
    onboardingStatus: OnboardingStatus.completed,
    personalInfo: projected.personal.copyWith(
      // The form has no question for these — they are profile-manager fields,
      // and a seeded candidate should look like one who has filled them in.
      objectives: p['objectives'] as String? ?? '',
      skills: _strings(p['skills']),
      summary: p['summary'] as String? ?? projected.personal.summary,
    ),
    roleSpecificData: projected.roleData,
    experience: [
      for (final (i, e) in _maps(p['experience']).indexed)
        ExperienceEntry(
          id: 'exp_$i',
          title: _s(e['role']),
          company: _s(e['organization']),
          location: _s(e['location']),
          startDate: _s(e['startDate']),
          endDate: _s(e['endDate']),
          isCurrent: _s(e['endDate']).isEmpty,
          responsibilities: _s(e['duties'])
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList(),
        ),
    ],
    education: [
      for (final (i, e) in _maps(p['education']).indexed)
        EducationEntry(
          id: 'edu_$i',
          institution: _s(e['institutionName']),
          degree: _s(e['degree']),
          fieldOfStudy: _s(e['majorSubjects']),
          graduationYear: int.tryParse(_s(e['duration'])),
          grade: _s(e['marksOrCgpa']),
        ),
    ],
    certifications: [
      for (final (i, c) in _maps(p['certifications']).indexed)
        CertificationEntry(
          id: 'cert_$i',
          name: _s(c['name']),
          issuer: _s(c['organization']),
        ),
    ],
    answers: answers,
    completedSections: template.sections,
    professionalStatus: _s(p['professionalStatus']),
    expectedRetirementDate: _s(p['retirementDate']),
    publications: _strings(p['publications']),
    awards: _strings(p['awards']),
    references: _strings(p['references']),
    documents: ProfileProjector.documents(template, answers),
  );
}

String _s(dynamic v) => v?.toString().trim() ?? '';

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : const [];

// ── Firebase REST ──────────────────────────────────────────────────────────

typedef _Account = ({String uid, String idToken});

/// Creates the account, or signs in when it already exists so a re-run is
/// harmless rather than a hard failure halfway through the batch.
Future<_Account> _signUp(String email, String password) async {
  Future<_Account?> call(String verb) async {
    final res = await http.post(
      Uri.parse('$_identity:$verb?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (uid: j['localId'] as String, idToken: j['idToken'] as String);
  }

  final signedUp = await call('signUp');
  if (signedUp != null) return signedUp;

  final signedIn = await call('signInWithPassword');
  if (signedIn != null) return signedIn;

  throw StateError('could not create or sign in $email');
}

Future<void> _write(
  String path,
  Map<String, dynamic> data,
  String idToken,
) async {
  final res = await http.patch(
    Uri.parse('$_firestore/$path'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({'fields': _fields(data)}),
  );
  if (res.statusCode != 200) {
    throw StateError('write $path failed ${res.statusCode}: ${res.body}');
  }
}

Map<String, dynamic> _fields(Map<String, dynamic> m) =>
    {for (final e in m.entries) e.key: _value(e.value)};

/// Encodes a Dart value the way the Firestore REST API expects.
Map<String, dynamic> _value(dynamic v) {
  if (v == null) return {'nullValue': null};
  if (v is bool) return {'booleanValue': v};
  if (v is int) return {'integerValue': '$v'};
  if (v is double) return {'doubleValue': v};
  if (v is String) return {'stringValue': v};
  if (v is DateTime) return {'timestampValue': v.toUtc().toIso8601String()};
  if (v is List) {
    return {
      'arrayValue': {'values': v.map(_value).toList()},
    };
  }
  if (v is Map) {
    return {
      'mapValue': {
        'fields': _fields(Map<String, dynamic>.from(v)),
      },
    };
  }
  // Anything else is a bug in the caller, and silently coercing it would put
  // a wrong value in the database rather than stopping the run.
  throw ArgumentError('cannot encode ${v.runtimeType} for Firestore: $v');
}
