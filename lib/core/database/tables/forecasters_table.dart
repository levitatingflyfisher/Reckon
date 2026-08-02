import 'package:drift/drift.dart';
import '../converters.dart';

/// The registry of forecast participants — everyone who may "duel" the user
/// on a decision: persona prompts over the resident on-device model, BYOK
/// cloud models, OpenAI-compatible endpoints, and imported bounty bots. Their
/// forecasts land in [ModelPredictions]; this table only holds identity and
/// configuration. Secrets (API keys) never live here — they belong in secure
/// storage.
@DataClassName('ForecasterRow')
class Forecasters extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();

  /// 'persona' | 'localModel' | 'anthropicByok' | 'openaiCompat' |
  /// 'stove' | 'bountyBot' — the [ForecasterKind] name.
  TextColumn get kind => text()();

  /// JSON map of kind-specific, non-secret configuration (e.g. a persona's
  /// stance sentence, an endpoint's base_url + model).
  TextColumn get configJson => text().map(const JsonMapConverter())();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
