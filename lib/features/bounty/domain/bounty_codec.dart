import 'dart:convert';

import '../../case/domain/entities/case.dart';

/// One parsed BountyResponse (reckonBounty spec §3.2) — exactly one of [p]
/// (binary) or [distribution] (multi) is non-null. Wire shapes live here in
/// the codec, like the party feature's; nothing outside `features/bounty`
/// should touch raw bounty JSON.
class ParsedBountyResponse {
  const ParsedBountyResponse({
    required this.botName,
    this.botModel,
    this.requestId,
    this.responseId,
    this.createdAt,
    this.p,
    this.distribution,
    required this.rationale,
  });

  final String botName;
  final String? botModel;
  final String? requestId;
  final String? responseId;
  final DateTime? createdAt;

  /// Binary forecast, as parsed. A Reckon request is always `multi` (spec
  /// §3.2 defines `p` only for binary questions), and nothing in a bare `p`
  /// names the option it affirms — so [BountyCodec.leanFor] rejects it
  /// rather than guess and risk silently inverting the forecast.
  final double? p;

  /// Multi forecast: probability per option text, summing to 1 ± 0.001.
  final Map<String, double>? distribution;

  final String rationale;
}

/// Encoder/decoder for the reckonBounty v0.1 wire format (the protocol spec
/// is the law; this file is Reckon's reading of it). Pure Dart, no IO.
class BountyCodec {
  BountyCodec._();

  static const specVersion = '0.1';

  /// Auto-drafted resolution criteria: Reckon's ground truth is the asker's
  /// satisfaction judgment, not an objective event — the request says so.
  static const resolutionCriteria =
      'Asker records a satisfaction judgment at the scheduled check-in; '
      'positive means the chosen option was right.';

  /// Builds a spec §3.1 BountyRequest for [case_].
  ///
  /// [title] and [background] are the (possibly redacted, always
  /// user-previewed) question texts. [redaction] is `local-llm` or `manual`
  /// (spec §5). [horizon] is the resolution horizon: the case's
  /// resolutionCheckDate when one exists, else its deadline, else null —
  /// export is only offered on open cases, so in practice it is the
  /// deadline. `reply_by` is the deadline too: answers arriving after the
  /// user must decide can't help.
  ///
  /// The request id is the case id, so imported responses can be matched
  /// back to the decision they answer.
  static Map<String, dynamic> buildRequest(
    Case case_, {
    required String title,
    required String background,
    required String redaction,
    DateTime? horizon,
    DateTime Function()? now,
  }) {
    final createdAt = (now ?? DateTime.now)().toUtc();
    return {
      'reckonbounty': specVersion,
      'kind': 'request',
      'id': case_.id,
      'created_at': createdAt.toIso8601String(),
      'reply_by': case_.deadline?.toUtc().toIso8601String(),
      'privacy': {'tier': 'redacted', 'redaction': redaction},
      'question': {
        'type': 'multi',
        'title': title,
        'background': background,
        'options': [case_.optionA, case_.optionB],
        'resolution': {
          'criteria': resolutionCriteria,
          'horizon': horizon?.toUtc().toIso8601String(),
          'resolver': 'asker',
        },
      },
      'bounty': {
        'rail': 'none',
        'terms': 'per-answer',
        'amount': '0',
        'currency': 'none',
      },
      'client': {'app': 'reckon'},
    };
  }

  /// The starting background for the export preview, composed from what the
  /// case already knows. The user edits (and the redactor rewrites) from
  /// here; poll rationales are deliberately excluded — they are the user's
  /// private reasoning, not context a stranger needs.
  static String draftBackground(Case case_) {
    final sb = StringBuffer()
      ..write('Two options: "${case_.optionA}" or "${case_.optionB}".');
    if (case_.statedCriteria.isNotEmpty) {
      final criteria = case_.statedCriteria
          .map((c) => '${c.label} (weight ${_trimZeros(c.weight)})')
          .join(', ');
      sb.write(' What matters to the asker: $criteria.');
    }
    sb.write(' Stakes: ${case_.stakes.name}.'
        ' Regret horizon: ${case_.regretHorizon.name}.');
    if (case_.category != null && case_.category!.isNotEmpty) {
      sb.write(' Category: ${case_.category}.');
    }
    return sb.toString();
  }

  /// Tolerant parse of pasted response JSON: one BountyResponse object or an
  /// array of them. Unknown fields are ignored (spec §3 forward
  /// compatibility); missing or malformed mandatory fields throw a
  /// [FormatException] whose message names the field and, in an array, the
  /// offending position.
  static List<ParsedBountyResponse> parseResponses(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException(
          'Nothing to import — paste a BountyResponse JSON object or an '
          'array of them.');
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      throw FormatException('That is not valid JSON: ${e.message}');
    }
    final items = decoded is List ? decoded : [decoded];
    return [
      for (var i = 0; i < items.length; i++)
        _parseOne(items[i], position: i + 1, inArray: items.length > 1),
    ];
  }

  /// Maps a response's forecast onto Reckon's lean scale (0 = fully
  /// optionA, 100 = fully optionB — the LeanSlider orientation).
  ///
  ///  * A bare binary `p` is rejected (see [ParsedBountyResponse.p]): the
  ///    exported request is `multi`, so `p` carries no option orientation
  ///    and reading it either way risks inverting the forecast — the exact
  ///    silent corruption the sealed record must never absorb.
  ///  * A `distribution` is matched by option text, whitespace- and
  ///    case-tolerantly: a key matching [optionB] gives p(optionB)
  ///    directly; failing that, a key matching [optionA] gives it as the
  ///    complement. Neither matching is a [FormatException] — a forecast
  ///    about different options must never enter this case's record.
  static int leanFor(
    ParsedBountyResponse response, {
    required String optionA,
    required String optionB,
  }) {
    double pB;
    final dist = response.distribution;
    if (dist == null) {
      // The parser guarantees one of p/distribution is present.
      throw FormatException(
          '${response.botName}: answered with a bare binary "p", but this '
          'request is multi — nothing says which option that probability '
          'affirms. It needs a distribution naming this decision\'s options '
          '("$optionA" / "$optionB").');
    } else {
      String norm(String s) => s.trim().toLowerCase();
      double? valueFor(String option) {
        for (final e in dist.entries) {
          if (norm(e.key) == norm(option)) return e.value;
        }
        return null;
      }

      final pOptionB = valueFor(optionB);
      final pOptionA = valueFor(optionA);
      if (pOptionB != null) {
        pB = pOptionB;
      } else if (pOptionA != null) {
        pB = 1 - pOptionA;
      } else {
        throw FormatException(
            '${response.botName}: the forecast distribution '
            '(${dist.keys.join(', ')}) does not mention either of this '
            'decision\'s options ("$optionA" / "$optionB").');
      }
    }
    return (pB * 100).round().clamp(0, 100);
  }

  // ---------------------------------------------------------------------
  // parsing internals
  // ---------------------------------------------------------------------

  static final _versionShape = RegExp(r'^\d+(\.\d+)*$');

  static ParsedBountyResponse _parseOne(
    dynamic item, {
    required int position,
    required bool inArray,
  }) {
    final where = inArray ? 'Response $position: ' : '';
    FormatException reject(String why) => FormatException('$where$why');

    if (item is! Map<String, dynamic>) {
      throw reject('expected a JSON object, got ${item.runtimeType}.');
    }

    final version = item['reckonbounty'];
    if (version is! String || !_versionShape.hasMatch(version)) {
      throw reject('"reckonbounty" must be a spec version string like '
          '"$specVersion" — got ${jsonEncode(version)}.');
    }
    // Any well-formed version is accepted: §3 says unknown fields are
    // ignored, so a newer minor version's response still reads correctly.

    final kind = item['kind'];
    if (kind != 'response') {
      throw reject(
          '"kind" must be "response" — got ${jsonEncode(kind)}.');
    }

    final bot = item['bot'];
    final botName = bot is Map<String, dynamic> ? bot['name'] : null;
    if (botName is! String || botName.trim().isEmpty) {
      throw reject('"bot.name" is required and must be a non-empty string.');
    }

    DateTime? createdAt;
    final rawCreatedAt = item['created_at'];
    if (rawCreatedAt != null) {
      createdAt =
          rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null;
      if (createdAt == null) {
        throw reject('"created_at" is not an ISO-8601 timestamp: '
            '${jsonEncode(rawCreatedAt)}.');
      }
    }

    final forecast = item['forecast'];
    if (forecast is! Map<String, dynamic>) {
      throw reject('"forecast" object is required.');
    }
    final rawP = forecast['p'];
    final rawDist = forecast['distribution'];
    double? p;
    Map<String, double>? distribution;
    if (rawP != null) {
      if (rawP is! num || rawP < 0 || rawP > 1) {
        throw reject('"forecast.p" must be a number in [0, 1] — got '
            '${jsonEncode(rawP)}.');
      }
      p = rawP.toDouble();
    } else if (rawDist != null) {
      if (rawDist is! Map<String, dynamic> || rawDist.isEmpty) {
        throw reject('"forecast.distribution" must be a non-empty object of '
            'option → probability.');
      }
      distribution = {};
      var sum = 0.0;
      for (final e in rawDist.entries) {
        final v = e.value;
        if (v is! num || v < 0 || v > 1) {
          throw reject('"forecast.distribution" entry '
              '${jsonEncode(e.key)} must be a number in [0, 1] — got '
              '${jsonEncode(v)}.');
        }
        distribution[e.key] = v.toDouble();
        sum += v;
      }
      if ((sum - 1.0).abs() > 0.001) {
        throw reject('"forecast.distribution" must sum to 1 ± 0.001 — it '
            'sums to ${sum.toStringAsFixed(3)}.');
      }
    } else {
      throw reject('the "forecast" needs either "p" (binary) or '
          '"distribution" (multi).');
    }

    return ParsedBountyResponse(
      botName: botName.trim(),
      botModel: bot['model'] is String ? bot['model'] as String : null,
      requestId: item['request_id'] is String
          ? item['request_id'] as String
          : null,
      responseId: item['id'] is String ? item['id'] as String : null,
      createdAt: createdAt,
      p: p,
      distribution: distribution,
      rationale:
          forecast['rationale'] is String ? forecast['rationale'] as String : '',
    );
  }

  static String _trimZeros(double d) {
    final s = d.toString();
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}
