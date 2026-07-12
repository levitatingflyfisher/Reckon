import 'dart:convert';
import 'dart:typed_data';

import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../../core/database/app_database.dart';
import '../../case/domain/entities/case.dart';
import '../../case/domain/entities/criterion.dart';
import '../../case/domain/entities/poll.dart';
import '../../export/data/export_service.dart';
import '../../export/data/import_service.dart';
import '../../export/domain/entities/export_bundle.dart';
import '../../outside_view/domain/entities/citation.dart';
import '../../outside_view/domain/entities/outside_view.dart';
import '../../outside_view/domain/entities/user_profile.dart';
import '../../predictions/domain/entities/model_prediction.dart';

/// Serializes all Reckon user data to/from a JSON [Uint8List] for encrypted
/// backup via sanctuary_backup_ui.
///
/// **Not** the same JSON shape as [ExportFormatters.toJson] — that formatter
/// deliberately drops row ids and a few fields (`revealed`, `communityVisible`,
/// `stratificationFactors`, `llmMode`, resolution ids) because it exists for
/// a human-readable share-out, not a faithful restore. This envelope keeps
/// every field a destructive-replace restore needs (SANCTUARY-BRIEF §4.W2:
/// "Export side: REUSE ExportService.gather() ... Restore side is NEW CODE").
///
/// The envelope carries `{app, schemaVersion}` so [restoreAll] can reject a
/// backup made by a different app or a future schema version — defense in
/// depth behind the OHBK AEAD context, which already binds a blob to
/// `'reckon-backup/v1'` and would fail to decrypt under any other app's key
/// (SANCTUARY-BRIEF §2.8).
class ReckonBackupSerializer implements BackupSerializer {
  ReckonBackupSerializer(this._db);
  final AppDatabase _db;

  static const _appId = 'reckon';

  @override
  Future<Uint8List> dumpAll() async {
    final bundle = await ExportService(_db).gather();

    final payload = <String, dynamic>{
      'app': _appId,
      'schemaVersion': _db.schemaVersion,
      'generatedAt': bundle.generatedAt.toIso8601String(),
      'profile': {
        'sesBracket': bundle.profile.sesBracket,
        'religiosity': bundle.profile.religiosity,
        'relationshipStatus': bundle.profile.relationshipStatus,
      },
      'cases': bundle.cases.map(_caseToJson).toList(),
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  @override
  Future<void> restoreAll(Uint8List data) async {
    // jsonDecode/utf8.decode throw FormatException on malformed input —
    // that propagates as-is, which BackupController maps to
    // RestoreOutcome.corruptFile.
    final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;

    final app = json['app'] as String?;
    if (app != _appId) {
      throw FormatException(
        'This backup was made by a different app '
        '(expected "$_appId", got "${app ?? '<missing>'}")',
      );
    }

    final version = json['schemaVersion'] as int?;
    if (version == null) {
      throw const FormatException('Missing schemaVersion in backup payload');
    }
    if (version > _db.schemaVersion) {
      throw BackupSchemaException(version, _db.schemaVersion);
    }

    final casesJson = json['cases'] as List<dynamic>?;
    if (casesJson == null) {
      throw const FormatException('Missing cases in backup payload');
    }
    final profileJson = json['profile'] as Map<String, dynamic>?;

    final bundle = ExportBundle(
      generatedAt: _dateTime(json['generatedAt']) ?? DateTime.now(),
      profile: UserProfile(
        sesBracket: profileJson?['sesBracket'] as String?,
        religiosity: profileJson?['religiosity'] as String?,
        relationshipStatus: profileJson?['relationshipStatus'] as String?,
      ),
      cases: casesJson
          .cast<Map<String, dynamic>>()
          .map(_caseFromJson)
          .toList(),
    );

    await ImportService(_db).restoreAll(bundle);
  }

  Map<String, dynamic> _caseToJson(CaseExport e) => {
        'id': e.case_.id,
        'createdAt': e.case_.createdAt.toIso8601String(),
        'deadline': e.case_.deadline?.toIso8601String(),
        'status': e.case_.status.name,
        'question': e.case_.question,
        'optionA': e.case_.optionA,
        'optionB': e.case_.optionB,
        'statedCriteria': e.case_.statedCriteria.map((c) => c.toJson()).toList(),
        'stakes': e.case_.stakes.name,
        'regretHorizon': e.case_.regretHorizon.name,
        'category': e.case_.category,
        'communityVisible': e.case_.communityVisible,
        'polls': e.polls.map(_pollToJson).toList(),
        'outsideView':
            e.outsideView == null ? null : _outsideViewToJson(e.outsideView!),
        'resolution':
            e.resolution == null ? null : _resolutionToJson(e.resolution!),
        'predictions': e.predictions.map(_predictionToJson).toList(),
      };

  Map<String, dynamic> _pollToJson(Poll p) => {
        'id': p.id,
        'caseId': p.caseId,
        'createdAt': p.createdAt.toIso8601String(),
        'pollNumber': p.pollNumber,
        'lean': p.lean,
        'rationale': p.rationale,
        'confidence': p.confidence.name,
        'revealed': p.revealed,
      };

  Map<String, dynamic> _outsideViewToJson(OutsideView v) => {
        'id': v.id,
        'caseId': v.caseId,
        'generatedAt': v.generatedAt.toIso8601String(),
        'baseRateSummary': v.baseRateSummary,
        'referenceClassUsed': v.referenceClassUsed,
        'uncertaintyLevel': v.uncertaintyLevel,
        'stratificationFactors': v.stratificationFactors,
        'llmMode': v.llmMode,
        'modelVersion': v.modelVersion,
        'citations': v.citations.map((c) => c.toJson()).toList(),
      };

  Map<String, dynamic> _predictionToJson(ModelPrediction p) => {
        'id': p.id,
        'caseId': p.caseId,
        'modelVersion': p.modelVersion,
        'kind': p.kind.name,
        'predictedAt': p.predictedAt.toIso8601String(),
        'payload': p.payload,
        'score': p.score,
        'scoredAt': p.scoredAt?.toIso8601String(),
      };

  Map<String, dynamic> _resolutionToJson(ResolutionExport r) => {
        'decidedAt': r.decidedAt.toIso8601String(),
        'chosenOption': r.chosenOption,
        'resolutionCheckDate': r.resolutionCheckDate.toIso8601String(),
        'satisfactionScore': r.satisfactionScore,
        'reflection': r.reflection,
      };

  CaseExport _caseFromJson(Map<String, dynamic> json) {
    final pollsJson = (json['polls'] as List<dynamic>?) ?? const [];
    final outsideViewJson = json['outsideView'] as Map<String, dynamic>?;
    final resolutionJson = json['resolution'] as Map<String, dynamic>?;
    final predictionsJson = (json['predictions'] as List<dynamic>?) ?? const [];

    return CaseExport(
      case_: Case(
        id: json['id'] as String,
        createdAt: _dateTime(json['createdAt'])!,
        deadline: _dateTime(json['deadline']),
        status: CaseStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CaseStatus.open,
        ),
        question: json['question'] as String,
        optionA: json['optionA'] as String,
        optionB: json['optionB'] as String,
        statedCriteria: ((json['statedCriteria'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Criterion.fromJson)
            .toList(),
        stakes: Stakes.values.firstWhere(
          (e) => e.name == json['stakes'],
          orElse: () => Stakes.medium,
        ),
        regretHorizon: RegretHorizon.values.firstWhere(
          (e) => e.name == json['regretHorizon'],
          orElse: () => RegretHorizon.months,
        ),
        category: json['category'] as String?,
        communityVisible: json['communityVisible'] as bool? ?? false,
      ),
      polls: pollsJson.cast<Map<String, dynamic>>().map(_pollFromJson).toList(),
      outsideView:
          outsideViewJson == null ? null : _outsideViewFromJson(outsideViewJson),
      resolution:
          resolutionJson == null ? null : _resolutionFromJson(resolutionJson),
      predictions: predictionsJson
          .cast<Map<String, dynamic>>()
          .map(_predictionFromJson)
          .toList(),
    );
  }

  Poll _pollFromJson(Map<String, dynamic> json) => Poll(
        id: json['id'] as String,
        caseId: json['caseId'] as String,
        createdAt: _dateTime(json['createdAt'])!,
        pollNumber: json['pollNumber'] as int,
        lean: json['lean'] as int,
        confidence: Confidence.values.firstWhere(
          (e) => e.name == json['confidence'],
          orElse: () => Confidence.medium,
        ),
        rationale: json['rationale'] as String?,
        revealed: json['revealed'] as bool? ?? false,
      );

  OutsideView _outsideViewFromJson(Map<String, dynamic> json) => OutsideView(
        id: json['id'] as String,
        caseId: json['caseId'] as String,
        generatedAt: _dateTime(json['generatedAt'])!,
        baseRateSummary: json['baseRateSummary'] as String,
        referenceClassUsed: json['referenceClassUsed'] as String,
        uncertaintyLevel: json['uncertaintyLevel'] as String,
        stratificationFactors:
            (json['stratificationFactors'] as Map<String, dynamic>?) ?? const {},
        llmMode: json['llmMode'] as String,
        modelVersion: json['modelVersion'] as String,
        citations: Citation.listFromDynamic(
          json['citations'] as List<dynamic>?,
        ),
      );

  ModelPrediction _predictionFromJson(Map<String, dynamic> json) =>
      ModelPrediction(
        id: json['id'] as String,
        caseId: json['caseId'] as String,
        modelVersion: json['modelVersion'] as String,
        kind: PredictionKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => PredictionKind.outsideView,
        ),
        predictedAt: _dateTime(json['predictedAt'])!,
        payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
        score: (json['score'] as num?)?.toDouble(),
        scoredAt: _dateTime(json['scoredAt']),
      );

  ResolutionExport _resolutionFromJson(Map<String, dynamic> json) =>
      ResolutionExport(
        decidedAt: _dateTime(json['decidedAt'])!,
        chosenOption: json['chosenOption'] as String,
        resolutionCheckDate: _dateTime(json['resolutionCheckDate'])!,
        satisfactionScore: json['satisfactionScore'] as int?,
        reflection: json['reflection'] as String?,
      );

  DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    throw FormatException('Cannot parse DateTime from: $value');
  }
}
