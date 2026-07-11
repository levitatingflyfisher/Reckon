import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/bounty/domain/bounty_codec.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';

/// The cabin decision from the reckonBounty protocol spec §9, phrased as a
/// Reckon case. Note the trap the importer must refuse: the spec's worked
/// binary responses say p(buy), but a Reckon request is always multi and
/// nothing in a bare `p` names the option it affirms.
Case _cabinCase() => Case(
      id: '5f0a2b1c-9d4e-4f6a-8b3c-7e1d2a5b4c6d',
      createdAt: DateTime.utc(2026, 7, 11),
      deadline: DateTime.utc(2026, 7, 18),
      status: CaseStatus.open,
      question: 'Buy the vacation cabin?',
      optionA: 'Keep renting each summer',
      optionB: 'Buy the cabin',
      statedCriteria: const [
        Criterion(label: 'family time', weight: 2),
        Criterion(label: 'financial slack', weight: 1.5),
      ],
      stakes: Stakes.high,
      regretHorizon: RegretHorizon.years,
      category: 'housing',
    );

/// The spec §3.2 example response (hustlerBot80000, p = 0.35), inline so the
/// codec is tested against the wire law rather than our own output.
const _hustlerJson = '''
{
  "reckonbounty": "0.1",
  "kind": "response",
  "request_id": "5f0a2b1c-9d4e-4f6a-8b3c-7e1d2a5b4c6d",
  "id": "a1b2c3d4-1111-2222-3333-444455556666",
  "created_at": "2026-07-11T07:02:00Z",
  "bot": {
    "name": "hustlerBot80000",
    "operator": "anonymous",
    "model": "llamafile/Qwen2.5-7B-Instruct Q4_K_M, single pass + self-critique",
    "directory_url": null
  },
  "forecast": {
    "p": 0.35,
    "rationale": "Base rates for discretionary second-home satisfaction at >1x income are poor.",
    "base_rates": ["Second-home regret surveys"],
    "key_uncertainties": ["Drive tolerance with three kids"],
    "clarifying_questions": ["Whose estimate is the 20 weekends?"]
  }
}
''';

const _cautiousJson = '''
{
  "reckonbounty": "0.1",
  "kind": "response",
  "request_id": "5f0a2b1c-9d4e-4f6a-8b3c-7e1d2a5b4c6d",
  "id": "b2c3d4e5-2222-3333-4444-555566667777",
  "created_at": "2026-07-11T08:15:00Z",
  "bot": {"name": "cautiousBot", "model": "llamafile/Phi-3.5-mini-instruct Q5_K_M"},
  "forecast": {"p": 0.20, "rationale": "Usage projections rarely survive contact with winter."}
}
''';

void main() {
  group('buildRequest', () {
    Map<String, dynamic> build({DateTime? horizon, Case? c}) =>
        BountyCodec.buildRequest(
          c ?? _cabinCase(),
          title: 'Buy the vacation cabin?',
          background: 'Family of five, single income.',
          redaction: 'manual',
          horizon: horizon,
          now: () => DateTime.utc(2026, 7, 11, 6, 30),
        );

    test('emits a spec-shaped BountyRequest envelope', () {
      final req = build();

      expect(req['reckonbounty'], '0.1');
      expect(req['kind'], 'request');
      expect(req['id'], '5f0a2b1c-9d4e-4f6a-8b3c-7e1d2a5b4c6d');
      expect(req['created_at'], '2026-07-11T06:30:00.000Z');
      expect(req['reply_by'], '2026-07-18T00:00:00.000Z'); // the deadline
      expect(req['privacy'], {'tier': 'redacted', 'redaction': 'manual'});
      expect(req['bounty'], {
        'rail': 'none',
        'terms': 'per-answer',
        'amount': '0',
        'currency': 'none',
      });
      expect(req['client'], {'app': 'reckon'});
    });

    test('question is multi over exactly the two options, resolver asker', () {
      final req = build(horizon: DateTime.utc(2027, 8, 1));
      final question = req['question'] as Map<String, dynamic>;

      expect(question['type'], 'multi');
      expect(question['title'], 'Buy the vacation cabin?');
      expect(question['background'], 'Family of five, single income.');
      expect(
          question['options'], ['Keep renting each summer', 'Buy the cabin']);
      final resolution = question['resolution'] as Map<String, dynamic>;
      expect(resolution['criteria'], contains('satisfaction judgment'));
      expect(resolution['criteria'], contains('chosen option was right'));
      expect(resolution['horizon'], '2027-08-01T00:00:00.000Z');
      expect(resolution['resolver'], 'asker');
    });

    test('no horizon and no deadline serialise as JSON null', () {
      final noDeadline = Case(
        id: 'c1',
        createdAt: DateTime.utc(2026, 7, 11),
        deadline: null,
        status: CaseStatus.open,
        question: 'q',
        optionA: 'A',
        optionB: 'B',
        statedCriteria: const [],
        stakes: Stakes.low,
        regretHorizon: RegretHorizon.weeks,
        category: null,
      );
      final req = build(c: noDeadline);

      expect(req['reply_by'], isNull);
      expect((req['question'] as Map)['resolution']['horizon'], isNull);
      // The whole request must round-trip as JSON.
      final decoded = jsonDecode(jsonEncode(req)) as Map<String, dynamic>;
      expect(decoded['kind'], 'request');
    });
  });

  group('draftBackground', () {
    test('composes options, criteria, stakes, horizon and category', () {
      final draft = BountyCodec.draftBackground(_cabinCase());

      expect(draft, contains('Keep renting each summer'));
      expect(draft, contains('Buy the cabin'));
      expect(draft, contains('family time'));
      expect(draft, contains('financial slack'));
      expect(draft, contains('high'));
      expect(draft, contains('years'));
      expect(draft, contains('housing'));
    });
  });

  group('parseResponses', () {
    test('parses the spec §3.2 example, ignoring unknown fields', () {
      final parsed = BountyCodec.parseResponses(_hustlerJson);

      expect(parsed, hasLength(1));
      final r = parsed.single;
      expect(r.botName, 'hustlerBot80000');
      expect(r.botModel, contains('Qwen2.5-7B'));
      expect(r.requestId, '5f0a2b1c-9d4e-4f6a-8b3c-7e1d2a5b4c6d');
      expect(r.responseId, 'a1b2c3d4-1111-2222-3333-444455556666');
      expect(r.createdAt, DateTime.utc(2026, 7, 11, 7, 2));
      expect(r.p, 0.35);
      expect(r.distribution, isNull);
      expect(r.rationale, contains('Base rates'));
    });

    test('parses a JSON array of responses', () {
      final parsed =
          BountyCodec.parseResponses('[$_hustlerJson, $_cautiousJson]');

      expect(parsed, hasLength(2));
      expect(parsed[0].botName, 'hustlerBot80000');
      expect(parsed[1].botName, 'cautiousBot');
      expect(parsed[1].p, 0.20);
    });

    test('accepts a multi distribution and validates it sums to one', () {
      final parsed = BountyCodec.parseResponses('''
{"reckonbounty": "0.1", "kind": "response",
 "bot": {"name": "distBot"},
 "forecast": {"distribution": {"Keep renting each summer": 0.65,
                               "Buy the cabin": 0.35},
              "rationale": "r"}}
''');

      expect(parsed.single.distribution,
          {'Keep renting each summer': 0.65, 'Buy the cabin': 0.35});
      expect(parsed.single.p, isNull);
    });

    test('a newer spec version still parses (forward compatibility)', () {
      final parsed = BountyCodec.parseResponses(
          '{"reckonbounty": "0.3", "kind": "response", "bot": {"name": "b"}, '
          '"forecast": {"p": 0.5, "rationale": "r"}}');
      expect(parsed.single.p, 0.5);
    });

    group('rejects with a precise error when', () {
      void expectRejects(String json, String needle) {
        expect(
          () => BountyCodec.parseResponses(json),
          throwsA(isA<FormatException>().having(
              (e) => e.message, 'message', contains(needle))),
        );
      }

      test('the input is not JSON', () {
        expectRejects('this is not json', 'not valid JSON');
      });

      test('the input is blank', () {
        expectRejects('   ', 'Nothing to import');
      });

      test('reckonbounty is missing', () {
        expectRejects(
            '{"kind": "response", "bot": {"name": "b"}, '
            '"forecast": {"p": 0.5}}',
            'reckonbounty');
      });

      test('reckonbounty is not a version string', () {
        expectRejects(
            '{"reckonbounty": "banana", "kind": "response", '
            '"bot": {"name": "b"}, "forecast": {"p": 0.5}}',
            'reckonbounty');
      });

      test('kind is not response', () {
        expectRejects(
            '{"reckonbounty": "0.1", "kind": "request", '
            '"bot": {"name": "b"}, "forecast": {"p": 0.5}}',
            'kind');
      });

      test('bot.name is missing', () {
        expectRejects(
            '{"reckonbounty": "0.1", "kind": "response", "bot": {}, '
            '"forecast": {"p": 0.5}}',
            'bot.name');
      });

      test('the forecast carries neither p nor distribution', () {
        expectRejects(
            '{"reckonbounty": "0.1", "kind": "response", '
            '"bot": {"name": "b"}, "forecast": {"rationale": "r"}}',
            'forecast');
      });

      test('p is out of range', () {
        expectRejects(
            '{"reckonbounty": "0.1", "kind": "response", '
            '"bot": {"name": "b"}, "forecast": {"p": 1.4}}',
            'p');
      });

      test('the distribution does not sum to one', () {
        expectRejects(
            '{"reckonbounty": "0.1", "kind": "response", '
            '"bot": {"name": "b"}, '
            '"forecast": {"distribution": {"A": 0.2, "B": 0.2}}}',
            'sum');
      });

      test('created_at is unparseable', () {
        expectRejects(
            '{"reckonbounty": "0.1", "kind": "response", '
            '"bot": {"name": "b"}, "forecast": {"p": 0.5}, '
            '"created_at": "yesterday-ish"}',
            'created_at');
      });

      test('an array entry is not an object — error names the position', () {
        expectRejects(
            '[{"reckonbounty": "0.1", "kind": "response", '
            '"bot": {"name": "b"}, "forecast": {"p": 0.5}}, 42]',
            'Response 2');
      });
    });
  });

  group('leanFor', () {
    ParsedBountyResponse parse(String json) =>
        BountyCodec.parseResponses(json).single;

    int lean(ParsedBountyResponse r) => BountyCodec.leanFor(
          r,
          optionA: 'Keep renting each summer',
          optionB: 'Buy the cabin',
        );

    test(
        'a bare binary p is rejected — the request is multi and nothing '
        'orients p to either option, so guessing risks inverting the forecast',
        () {
      for (final json in [_hustlerJson, _cautiousJson]) {
        expect(
          () => lean(parse(json)),
          throwsA(isA<FormatException>().having(
              (e) => e.message,
              'message',
              allOf(contains('Keep renting each summer'),
                  contains('Buy the cabin'), contains('distribution')))),
        );
      }
    });

    test('a distribution is matched by option text', () {
      final r = parse('{"reckonbounty": "0.1", "kind": "response", '
          '"bot": {"name": "b"}, '
          '"forecast": {"distribution": {"Keep renting each summer": 0.65, '
          '"Buy the cabin": 0.35}}}');
      expect(lean(r), 35);
    });

    test('matching is whitespace- and case-tolerant', () {
      final r = parse('{"reckonbounty": "0.1", "kind": "response", '
          '"bot": {"name": "b"}, '
          '"forecast": {"distribution": {"keep renting each summer": 0.6, '
          '" BUY THE CABIN ": 0.4}}}');
      expect(lean(r), 40);
    });

    test('an optionA-only match infers p(optionB) as the complement', () {
      final r = parse('{"reckonbounty": "0.1", "kind": "response", '
          '"bot": {"name": "b"}, '
          '"forecast": {"distribution": {"Keep renting each summer": 0.7, '
          '"something else entirely": 0.3}}}');
      expect(lean(r), 30);
    });

    test('unmatchable options are rejected with both option texts named', () {
      final r = parse('{"reckonbounty": "0.1", "kind": "response", '
          '"bot": {"name": "b"}, '
          '"forecast": {"distribution": {"yes": 0.7, "no": 0.3}}}');
      expect(
        () => lean(r),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('Keep renting each summer'), contains('Buy the cabin')))),
      );
    });
  });
}
