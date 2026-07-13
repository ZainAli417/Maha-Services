import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/onboarding/aviation_catalogue.dart';
import 'package:job_portal/core/onboarding/models/aviation_role.dart';
import 'package:job_portal/core/onboarding/models/question.dart';

void main() {
  group('AviationCatalogue', () {
    final roles = AviationCatalogue.roles;

    test('is non-empty and comprehensive', () {
      expect(roles.length, greaterThanOrEqualTo(40));
    });

    test('every role has a stable id, title, category and questions', () {
      for (final r in roles) {
        expect(r.id.trim(), isNotEmpty, reason: r.title);
        expect(r.title.trim(), isNotEmpty, reason: r.id);
        expect(r.category.trim(), isNotEmpty, reason: r.id);
        expect(r.questions, isNotEmpty, reason: r.id);
      }
    });

    test('role ids are globally unique', () {
      final ids = roles.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('question ids are unique within each role', () {
      for (final r in roles) {
        final ids = r.questions.map((q) => q.id).toList();
        expect(ids.toSet().length, ids.length,
            reason: 'duplicate question id in ${r.id}');
      }
    });

    test('select questions carry options', () {
      for (final r in roles) {
        for (final q in r.questions) {
          if (q.type == QuestionType.singleSelect ||
              q.type == QuestionType.multiSelect) {
            expect(q.options, isNotEmpty,
                reason: '${r.id}/${q.id} has no options');
          }
        }
      }
    });
  });

  group('serialization round-trip', () {
    test('every role survives toJson/fromJson unchanged', () {
      for (final r in AviationCatalogue.roles) {
        final restored = AviationRole.fromJson(r.toJson());
        expect(restored.id, r.id);
        expect(restored.title, r.title);
        expect(restored.category, r.category);
        expect(restored.questions.length, r.questions.length);
        for (var i = 0; i < r.questions.length; i++) {
          final a = r.questions[i];
          final b = restored.questions[i];
          expect(b.id, a.id);
          expect(b.type, a.type);
          expect(b.options, a.options);
          expect(b.required, a.required);
        }
      }
    });

    test('QuestionType falls back to text for unknown values', () {
      expect(QuestionType.fromJson('nonsense'), QuestionType.text);
      expect(QuestionType.fromJson(null), QuestionType.text);
      expect(QuestionType.fromJson('multiSelect'), QuestionType.multiSelect);
    });
  });
}
