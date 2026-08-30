import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/rbac/hiring_pipeline.dart';

void main() {
  group('stages only go forward', () {
    test('the next stage is allowed', () {
      expect(HiringPipeline.canMove(from: 'shortlist', to: 'screening'), isTrue);
      expect(HiringPipeline.canMove(from: 'interview', to: 'technical'), isTrue);
    });

    test('skipping ahead is allowed', () {
      // Advancing straight to Offer is a decision the admin is entitled to
      // make; only going backwards rewrites what already happened.
      expect(HiringPipeline.canMove(from: 'shortlist', to: 'offer'), isTrue);
    });

    test('going back is refused', () {
      expect(HiringPipeline.canMove(from: 'interview', to: 'screening'), isFalse);
      expect(HiringPipeline.canMove(from: 'handover', to: 'shortlist'), isFalse);
      expect(HiringPipeline.canMove(from: 'offer', to: 'interview'), isFalse);
    });

    test('staying put is allowed, so a double click is not an error', () {
      expect(HiringPipeline.canMove(from: 'interview', to: 'interview'), isTrue);
    });
  });

  group('terminal outcomes', () {
    test('a candidate can be rejected from any live stage', () {
      for (final stage in HiringPipeline.stages) {
        expect(
          HiringPipeline.canMove(from: stage.toLowerCase(), to: 'rejected'),
          isTrue,
          reason: stage,
        );
      }
    });

    test('nothing moves out of a rejection', () {
      // Reopening someone is a new decision and belongs in a new request,
      // where it stays visible. Editing the old record hides it.
      expect(HiringPipeline.canMove(from: 'rejected', to: 'interview'), isFalse);
      expect(HiringPipeline.canMove(from: 'rejected', to: 'shortlist'), isFalse);
      expect(HiringPipeline.canMove(from: 'rejected', to: 'rejected'), isFalse);
    });

    test('rejected is not a stage on the bar', () {
      expect(HiringPipeline.indexOf('rejected'), -1);
      expect(HiringPipeline.isTerminal('rejected'), isTrue);
    });
  });

  group('aliases', () {
    test('the names the data actually uses map to real stages', () {
      // Written by three different code paths over time; all mean Shortlist.
      expect(HiringPipeline.indexOf('shortlisted'), 0);
      expect(HiringPipeline.indexOf('pending'), 0);
      expect(HiringPipeline.indexOf('Shortlist'), 0);
      expect(HiringPipeline.indexOf('hired'), HiringPipeline.indexOf('handover'));
    });

    test('an alias is subject to the same lock', () {
      expect(HiringPipeline.canMove(from: 'hired', to: 'interview'), isFalse);
      expect(HiringPipeline.canMove(from: 'interview', to: 'shortlisted'), isFalse);
    });
  });

  group('unknown values do not strand a candidate', () {
    test('an unrecognised current stage still allows a move forward', () {
      // An old document with a status nobody writes any more must not lock
      // the candidate out of the pipeline entirely.
      expect(HiringPipeline.canMove(from: 'legacy_thing', to: 'interview'), isTrue);
    });

    test('a move to an unrecognised stage is refused', () {
      expect(HiringPipeline.canMove(from: 'shortlist', to: 'nonsense'), isFalse);
    });
  });

  group('next', () {
    test('walks the pipeline in order and stops at the end', () {
      expect(HiringPipeline.next('shortlist'), 'screening');
      expect(HiringPipeline.next('offer'), 'handover');
      expect(HiringPipeline.next('handover'), isNull);
      expect(HiringPipeline.next('rejected'), isNull);
    });
  });

  group('allowedFrom', () {
    test('offers this stage and everything after it', () {
      expect(HiringPipeline.allowedFrom('interview'),
          ['interview', 'technical', 'offer', 'handover']);
    });

    test('offers nothing once a candidate is rejected', () {
      expect(HiringPipeline.allowedFrom('rejected'), isEmpty);
    });

    test('a fresh candidate can be sent anywhere forward', () {
      expect(HiringPipeline.allowedFrom('shortlist').length,
          HiringPipeline.stages.length);
    });
  });

  group('refusal reasons say what to do instead', () {
    test('a backwards move names both stages', () {
      final reason =
          HiringPipeline.refusalReason(from: 'interview', to: 'screening');
      expect(reason, contains('interview'));
      expect(reason, contains('screening'));
    });

    test('a terminal state points at sending them through again', () {
      final reason =
          HiringPipeline.refusalReason(from: 'rejected', to: 'interview');
      expect(reason.toLowerCase(), contains('new decision'));
    });
  });
}
