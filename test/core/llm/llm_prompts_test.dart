import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_prompts.dart';
import 'package:reckon/features/case/domain/entities/case.dart';

void main() {
  group('forecasterSeed', () {
    test('demands one flat JSON line with lean toward option B', () {
      final prompt = LlmPrompts.forecasterSeed(null);
      expect(prompt, contains('"lean"'));
      expect(prompt, contains('"rationale"'));
      expect(prompt, contains('option B'));
    });

    test('embeds the persona stance when given, omits it when null', () {
      const stance = 'Distrusts the story that makes this case feel special.';
      expect(LlmPrompts.forecasterSeed(stance), contains(stance));
      expect(LlmPrompts.forecasterSeed(null), isNot(contains('stance:')));
    });

    test('stays short — the whole on-device context is 4096 tokens', () {
      // ~4 chars/token; the seed prompt must leave room for the decision
      // brief and the reply.
      expect(LlmPrompts.forecasterSeed('a persona sentence').length,
          lessThan(1200));
    });
  });

  group('decisionBrief', () {
    test('carries both options with their lean orientation', () {
      final brief = LlmPrompts.decisionBrief(Case(
        id: 'c1',
        createdAt: DateTime(2026, 7, 11),
        deadline: null,
        status: CaseStatus.open,
        question: 'Move to the cabin?',
        optionA: 'Stay in town',
        optionB: 'Move',
        statedCriteria: const [],
        stakes: Stakes.high,
        regretHorizon: RegretHorizon.years,
        category: 'relocation',
      ));

      expect(brief, contains('Move to the cabin?'));
      expect(brief, contains('Option A (lean 0): Stay in town'));
      expect(brief, contains('Option B (lean 100): Move'));
      expect(brief, contains('high'));
    });
  });
}
