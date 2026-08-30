// One-off dev script: makes every seeded candidate apply to one job.
//
// Run with:
//   JOB_ID=<jobId> flutter test tool/seed/apply_to_job.dart
//
// It does exactly what pressing "Apply Now" does, by calling the same code:
// [JobApplicationsProvider.withoutContactDetails] strips the contact fields
// and [RoleProfileSnapshot.build] flattens the template answers. Reimplementing
// either here would let the seeded applications drift from real ones — and the
// redaction is the last thing that should ever drift.
//
// The two writes go in a single commit with a server-side increment, so the
// application and the job's applicationCount move together exactly as the
// app's batch does.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:job_portal/Screens/Job_Seeker/jobs_application_provider.dart';
import 'package:job_portal/core/onboarding/models/candidate_profile.dart';
import 'package:job_portal/core/onboarding/role_profile_snapshot.dart';
import 'package:job_portal/core/onboarding/role_templates.dart';

const _projectId = 'unisoft-tmp';
const _apiKey = 'AIzaSyCY36OFEa0K9qo9IHt7X9en6QE2gL0Duyc';
const _password = 'Zain@12345';

const _identity =
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword';
const _docs =
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

void main() {
  test('every seeded candidate applies to one job', () async {
    final jobId = Platform.environment['JOB_ID'] ?? '';
    expect(jobId, isNotEmpty, reason: 'set JOB_ID=<jobId>');

    final accounts = File('tool/seed/created_accounts.txt')
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.split(RegExp(r'\s+')))
        .toList();

    final templates = {
      for (final t in RoleTemplateCatalogue.templates) t.id: t,
    };

    final applied = <String>[];
    final skipped = <String>[];
    final failed = <String>[];

    // Read the job once — every applicant needs the same recruiterUid, and the
    // same status check the app performs before it lets anyone apply.
    final anyToken = await _signIn(accounts.first[0]);
    final job = await _get('Posted_jobs_public/$jobId', anyToken);
    expect(job, isNotNull, reason: 'job $jobId not found');

    final jobFields = job!['fields'] as Map<String, dynamic>;
    final status = _str(jobFields['status']).toLowerCase().trim();
    expect(status, 'active', reason: 'job is not accepting applications');

    final recruiterUid = _str(jobFields['recruiterUid']);
    expect(recruiterUid, isNotEmpty, reason: 'job has no recruiterUid');
    // ignore: avoid_print
    print('job "${_str(jobFields['title'])}" → recruiter $recruiterUid\n');

    for (final row in accounts) {
      final email = row[0];
      final uid = row[1];
      try {
        final token = await _signIn(email);

        // The app refuses a second application; so does this.
        final existing =
            await _get('applications/$uid/applied_jobs/$jobId', token);
        if (existing != null) {
          skipped.add('$email — already applied');
          // ignore: avoid_print
          print('⏭  $email  already applied');
          continue;
        }

        final seeker = await _get('Job_Seeker/$uid', token);
        final raw = _decode(seeker?['fields'] as Map<String, dynamic>? ?? {});
        final rawProfile = raw['candidateProfile'];
        if (rawProfile is! Map) {
          failed.add('$email — no candidateProfile');
          continue;
        }

        final redacted =
            JobApplicationsProvider.withoutContactDetails(rawProfile);

        final profile = CandidateProfile.fromJson(
            uid, Map<String, dynamic>.from(rawProfile));
        final template = templates[profile.targetRole.roleId];
        final roleProfile = template == null
            ? null
            : RoleProfileSnapshot.build(profile, template).toJson();

        await _commit(uid, jobId, {
          'userId': uid,
          'jobId': jobId,
          'recruiterUid': recruiterUid,
          'status': 'pending',
          'profileSnapshot': {
            'candidate_profile': redacted,
            'role_profile': ?roleProfile,
          },
        }, token);

        applied.add(email);
        // ignore: avoid_print
        print('✅ $email  ${profile.personalInfo.fullName} — '
            '${profile.targetRole.roleTitle}');
      } catch (e) {
        failed.add('$email — $e');
        // ignore: avoid_print
        print('❌ $email — $e');
      }
    }

    // ignore: avoid_print
    print('\n${applied.length} applied, ${skipped.length} skipped, '
        '${failed.length} failed');
    for (final f in failed) {
      // ignore: avoid_print
      print('   $f');
    }
    expect(failed, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 15)));
}

// ── Firebase REST ──────────────────────────────────────────────────────────

Future<String> _signIn(String email) async {
  final res = await http.post(
    Uri.parse('$_identity?key=$_apiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': _password,
      'returnSecureToken': true,
    }),
  );
  if (res.statusCode != 200) {
    throw StateError('sign in $email failed ${res.statusCode}: ${res.body}');
  }
  return (jsonDecode(res.body) as Map<String, dynamic>)['idToken'] as String;
}

/// Returns null for a document that does not exist, and throws on anything
/// else — a 403 must not read as "no application yet".
Future<Map<String, dynamic>?> _get(String path, String token) async {
  final res = await http.get(
    Uri.parse('$_docs/$path'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (res.statusCode == 404) return null;
  if (res.statusCode != 200) {
    throw StateError('read $path failed ${res.statusCode}: ${res.body}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Writes the application and bumps the job's counter in one commit, the way
/// the app's WriteBatch does: either both land or neither does.
Future<void> _commit(
  String uid,
  String jobId,
  Map<String, dynamic> application,
  String token,
) async {
  const base = 'projects/$_projectId/databases/(default)/documents';
  final res = await http.post(
    Uri.parse(
        'https://firestore.googleapis.com/v1/$base:commit'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'writes': [
        {
          'update': {
            'name': '$base/applications/$uid/applied_jobs/$jobId',
            'fields': _fields(application),
          },
          // appliedAt is stamped by the server, exactly as FieldValue does.
          'updateTransforms': [
            {'fieldPath': 'appliedAt', 'setToServerValue': 'REQUEST_TIME'},
          ],
        },
        {
          'transform': {
            'document': '$base/Posted_jobs_public/$jobId',
            'fieldTransforms': [
              {
                'fieldPath': 'applicationCount',
                'increment': {'integerValue': '1'},
              },
            ],
          },
        },
      ],
    }),
  );
  if (res.statusCode != 200) {
    throw StateError('commit failed ${res.statusCode}: ${res.body}');
  }
}

// ── Firestore value encoding ───────────────────────────────────────────────

String _str(dynamic v) =>
    v is Map ? (v['stringValue'] ?? '').toString() : (v?.toString() ?? '');

Map<String, dynamic> _fields(Map<String, dynamic> m) =>
    {for (final e in m.entries) e.key: _value(e.value)};

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
      'mapValue': {'fields': _fields(Map<String, dynamic>.from(v))},
    };
  }
  throw ArgumentError('cannot encode ${v.runtimeType} for Firestore: $v');
}

/// Turns a Firestore REST document back into plain Dart, so the redaction and
/// the model see the same shape they would from the SDK.
dynamic _decode(dynamic v) {
  if (v is Map<String, dynamic> && v.length == 1) {
    final key = v.keys.first;
    final val = v.values.first;
    switch (key) {
      case 'nullValue':
        return null;
      case 'booleanValue':
        return val as bool;
      case 'integerValue':
        return int.tryParse(val.toString()) ?? 0;
      case 'doubleValue':
        return (val as num).toDouble();
      case 'stringValue':
      case 'timestampValue':
        return val.toString();
      case 'arrayValue':
        final values = (val as Map)['values'] as List? ?? const [];
        return values.map(_decode).toList();
      case 'mapValue':
        final fields = (val as Map)['fields'] as Map<String, dynamic>? ?? {};
        return {for (final e in fields.entries) e.key: _decode(e.value)};
    }
  }
  if (v is Map<String, dynamic>) {
    return {for (final e in v.entries) e.key: _decode(e.value)};
  }
  return v;
}
