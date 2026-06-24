import 'dart:convert';

import 'entities/export_bundle.dart';

/// Pure formatters — no IO, no Flutter deps. Tested directly.
class ExportFormatters {
  const ExportFormatters._();

  static String toJson(ExportBundle bundle) {
    final map = <String, dynamic>{
      'schemaVersion': 1,
      'generatedAt': bundle.generatedAt.toIso8601String(),
      'profile': {
        'sesBracket': bundle.profile.sesBracket,
        'religiosity': bundle.profile.religiosity,
        'relationshipStatus': bundle.profile.relationshipStatus,
      },
      'cases': bundle.cases.map(_caseToJson).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static String toMarkdown(ExportBundle bundle) {
    final sb = StringBuffer()
      ..writeln('# Reckon export')
      ..writeln()
      ..writeln('Generated: ${bundle.generatedAt.toIso8601String()}')
      ..writeln('Cases: ${bundle.cases.length}')
      ..writeln();

    if (bundle.profile.hasAny) {
      sb
        ..writeln('## Profile')
        ..writeln();
      if (bundle.profile.sesBracket != null) {
        sb.writeln('- SES bracket: ${bundle.profile.sesBracket}');
      }
      if (bundle.profile.religiosity != null) {
        sb.writeln('- Religiosity: ${bundle.profile.religiosity}');
      }
      if (bundle.profile.relationshipStatus != null) {
        sb.writeln('- Relationship status: ${bundle.profile.relationshipStatus}');
      }
      sb.writeln();
    }

    for (final c in bundle.cases) {
      _caseToMarkdown(sb, c);
    }

    return sb.toString();
  }

  static Map<String, dynamic> _caseToJson(CaseExport e) {
    return {
      'id': e.case_.id,
      'createdAt': e.case_.createdAt.toIso8601String(),
      'deadline': e.case_.deadline?.toIso8601String(),
      'status': e.case_.status.name,
      'question': e.case_.question,
      'optionA': e.case_.optionA,
      'optionB': e.case_.optionB,
      'statedCriteria':
          e.case_.statedCriteria.map((c) => c.toJson()).toList(),
      'stakes': e.case_.stakes.name,
      'regretHorizon': e.case_.regretHorizon.name,
      'category': e.case_.category,
      'polls': e.polls
          .map((p) => {
                'pollNumber': p.pollNumber,
                'createdAt': p.createdAt.toIso8601String(),
                'lean': p.lean,
                'confidence': p.confidence.name,
                'rationale': p.rationale,
              })
          .toList(),
      'outsideView': e.outsideView == null
          ? null
          : {
              'generatedAt': e.outsideView!.generatedAt.toIso8601String(),
              'baseRateSummary': e.outsideView!.baseRateSummary,
              'referenceClassUsed': e.outsideView!.referenceClassUsed,
              'uncertaintyLevel': e.outsideView!.uncertaintyLevel,
              'modelVersion': e.outsideView!.modelVersion,
              'citations':
                  e.outsideView!.citations.map((c) => c.toJson()).toList(),
            },
      'resolution': e.resolution == null
          ? null
          : {
              'decidedAt': e.resolution!.decidedAt.toIso8601String(),
              'chosenOption': e.resolution!.chosenOption,
              'resolutionCheckDate':
                  e.resolution!.resolutionCheckDate.toIso8601String(),
              'satisfactionScore': e.resolution!.satisfactionScore,
              'reflection': e.resolution!.reflection,
            },
    };
  }

  static void _caseToMarkdown(StringBuffer sb, CaseExport e) {
    sb
      ..writeln('## ${e.case_.question}')
      ..writeln()
      ..writeln('- Created: ${e.case_.createdAt.toIso8601String()}')
      ..writeln('- Status: ${e.case_.status.name}')
      ..writeln('- Option A: ${e.case_.optionA}')
      ..writeln('- Option B: ${e.case_.optionB}')
      ..writeln(
          '- Stakes: ${e.case_.stakes.name} · Horizon: ${e.case_.regretHorizon.name}');
    if (e.case_.deadline != null) {
      sb.writeln('- Deadline: ${e.case_.deadline!.toIso8601String()}');
    }
    if (e.case_.category != null) {
      sb.writeln('- Category: ${e.case_.category}');
    }
    if (e.case_.statedCriteria.isNotEmpty) {
      final labels =
          e.case_.statedCriteria.map((c) => c.label).join(', ');
      sb.writeln('- Stated criteria: $labels');
    }
    sb.writeln();

    if (e.outsideView != null) {
      sb
        ..writeln('### Outside view')
        ..writeln()
        ..writeln('_${e.outsideView!.referenceClassUsed}_')
        ..writeln()
        ..writeln(e.outsideView!.baseRateSummary)
        ..writeln();
      final citations = e.outsideView!.citations;
      if (citations.isNotEmpty) {
        sb
          ..writeln('**Sources**')
          ..writeln();
        for (final c in citations) {
          final suffix = c.author.isNotEmpty ? ' — ${c.author}' : '';
          if (c.hasLink) {
            sb.writeln('- [${c.title}](${c.url})$suffix');
          } else {
            sb.writeln('- ${c.title}$suffix');
          }
        }
        sb.writeln();
      }
    }

    if (e.polls.isNotEmpty) {
      sb
        ..writeln('### Polls')
        ..writeln();
      for (final p in e.polls) {
        sb.write(
            '- Poll ${p.pollNumber} (${p.createdAt.toIso8601String()}) — lean ${p.lean}, confidence ${p.confidence.name}');
        if (p.rationale != null && p.rationale!.isNotEmpty) {
          sb.write(' — ${p.rationale}');
        }
        sb.writeln();
      }
      sb.writeln();
    }

    if (e.resolution != null) {
      sb
        ..writeln('### Resolution')
        ..writeln()
        ..writeln('- Decided: ${e.resolution!.decidedAt.toIso8601String()}')
        ..writeln('- Chose: ${e.resolution!.chosenOption}')
        ..writeln(
            '- Check-in scheduled: ${e.resolution!.resolutionCheckDate.toIso8601String()}');
      if (e.resolution!.satisfactionScore != null) {
        sb.writeln('- Satisfaction: ${e.resolution!.satisfactionScore}');
      }
      if (e.resolution!.reflection != null &&
          e.resolution!.reflection!.isNotEmpty) {
        sb.writeln('- Reflection: ${e.resolution!.reflection}');
      }
      sb.writeln();
    }

    sb.writeln('---');
    sb.writeln();
  }
}
