import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/export/domain/entities/export_bundle.dart';
import 'package:reckon/features/export/domain/formatters.dart';
import 'package:reckon/features/outside_view/domain/entities/citation.dart';
import 'package:reckon/features/outside_view/domain/entities/outside_view.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';

void main() {
  final bundle = ExportBundle(
    generatedAt: DateTime.utc(2026, 4, 22, 12, 0, 0),
    profile: const UserProfile(
      sesBracket: 'middle',
      religiosity: 'weekly',
      relationshipStatus: 'married',
    ),
    cases: [
      CaseExport(
        case_: Case(
          id: 'c-1',
          createdAt: DateTime.utc(2026, 4, 1),
          deadline: DateTime.utc(2026, 6, 1),
          status: CaseStatus.closed,
          question: 'Should I take the job?',
          optionA: 'Stay',
          optionB: 'Accept',
          statedCriteria: const [Criterion(label: 'comp', weight: 1.0)],
          stakes: Stakes.high,
          regretHorizon: RegretHorizon.years,
          category: 'career',
        ),
        polls: [
          Poll(
            id: 'p1',
            caseId: 'c-1',
            createdAt: DateTime.utc(2026, 4, 2),
            pollNumber: 1,
            lean: 60,
            confidence: Confidence.medium,
            rationale: 'pull of upside',
            revealed: true,
          ),
          Poll(
            id: 'p2',
            caseId: 'c-1',
            createdAt: DateTime.utc(2026, 4, 5),
            pollNumber: 2,
            lean: 70,
            confidence: Confidence.high,
            revealed: true,
          ),
        ],
        outsideView: OutsideView(
          id: 'ov-1',
          caseId: 'c-1',
          generatedAt: DateTime.utc(2026, 4, 1, 0, 1),
          baseRateSummary: 'Most knowledge-worker moves work out.',
          referenceClassUsed: 'career / job offer evaluation',
          uncertaintyLevel: 'medium',
          stratificationFactors: const {'ses': 'middle'},
          llmMode: 'private',
          modelVersion: 'gemma-3-1b-it',
          citations: const [
            Citation(
              author: 'BLS',
              title: 'Employee Tenure in 2024',
              url: 'https://www.bls.gov/tenure',
            ),
          ],
        ),
        resolution: ResolutionExport(
          decidedAt: DateTime.utc(2026, 4, 10),
          chosenOption: 'b',
          resolutionCheckDate: DateTime.utc(2026, 10, 10),
          satisfactionScore: 2,
          reflection: 'glad I took it',
        ),
      ),
    ],
  );

  group('toJson', () {
    test('produces stable schemaVersion + generatedAt', () {
      final json = ExportFormatters.toJson(bundle);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['schemaVersion'], 1);
      expect(decoded['generatedAt'], '2026-04-22T12:00:00.000Z');
    });

    test('serialises case + polls + outside view + resolution', () {
      final decoded = jsonDecode(ExportFormatters.toJson(bundle))
          as Map<String, dynamic>;
      final cases = decoded['cases'] as List;
      expect(cases, hasLength(1));
      final c = cases.first as Map<String, dynamic>;
      expect(c['question'], 'Should I take the job?');
      expect((c['polls'] as List), hasLength(2));
      expect(c['outsideView']['modelVersion'], 'gemma-3-1b-it');
      final citations = c['outsideView']['citations'] as List;
      expect(citations, hasLength(1));
      expect(citations.first['title'], 'Employee Tenure in 2024');
      expect(citations.first['url'], 'https://www.bls.gov/tenure');
      expect(c['resolution']['satisfactionScore'], 2);
    });

    test('produces valid JSON even with null optional fields', () {
      final minimal = ExportBundle(
        generatedAt: DateTime.utc(2026, 4, 22),
        profile: const UserProfile(),
        cases: const [],
      );
      final json = ExportFormatters.toJson(minimal);
      expect(() => jsonDecode(json), returnsNormally);
    });
  });

  group('toMarkdown', () {
    test('includes case question, polls, and resolution', () {
      final md = ExportFormatters.toMarkdown(bundle);
      expect(md, contains('# Reckon export'));
      expect(md, contains('## Should I take the job?'));
      expect(md, contains('Poll 1'));
      expect(md, contains('Poll 2'));
      expect(md, contains('### Resolution'));
      expect(md, contains('Satisfaction: 2'));
    });

    test('includes outside-view citations as markdown links', () {
      final md = ExportFormatters.toMarkdown(bundle);
      expect(md, contains('Sources'));
      expect(
        md,
        contains('[Employee Tenure in 2024](https://www.bls.gov/tenure)'),
      );
      expect(md, contains('BLS'));
    });

    test('omits profile section when empty', () {
      final noProfile = ExportBundle(
        generatedAt: DateTime.utc(2026, 4, 22),
        profile: const UserProfile(),
        cases: const [],
      );
      final md = ExportFormatters.toMarkdown(noProfile);
      expect(md, isNot(contains('## Profile')));
    });

    test('handles zero cases', () {
      final empty = ExportBundle(
        generatedAt: DateTime.utc(2026, 4, 22),
        profile: const UserProfile(),
        cases: const [],
      );
      final md = ExportFormatters.toMarkdown(empty);
      expect(md, contains('Cases: 0'));
    });
  });
}
