// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CasesTable extends Cases with TableInfo<$CasesTable, CaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deadlineMeta =
      const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
      'deadline', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionMeta =
      const VerificationMeta('question');
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
      'question', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _optionAMeta =
      const VerificationMeta('optionA');
  @override
  late final GeneratedColumn<String> optionA = GeneratedColumn<String>(
      'option_a', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _optionBMeta =
      const VerificationMeta('optionB');
  @override
  late final GeneratedColumn<String> optionB = GeneratedColumn<String>(
      'option_b', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statedCriteriaMeta =
      const VerificationMeta('statedCriteria');
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String>
      statedCriteria = GeneratedColumn<String>(
              'stated_criteria', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<dynamic>>($CasesTable.$converterstatedCriteria);
  static const VerificationMeta _stakesMeta = const VerificationMeta('stakes');
  @override
  late final GeneratedColumn<String> stakes = GeneratedColumn<String>(
      'stakes', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _regretHorizonMeta =
      const VerificationMeta('regretHorizon');
  @override
  late final GeneratedColumn<String> regretHorizon = GeneratedColumn<String>(
      'regret_horizon', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _communityVisibleMeta =
      const VerificationMeta('communityVisible');
  @override
  late final GeneratedColumn<bool> communityVisible = GeneratedColumn<bool>(
      'community_visible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("community_visible" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        deadline,
        status,
        question,
        optionA,
        optionB,
        statedCriteria,
        stakes,
        regretHorizon,
        category,
        communityVisible
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cases';
  @override
  VerificationContext validateIntegrity(Insertable<CaseRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta,
          deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('question')) {
      context.handle(_questionMeta,
          question.isAcceptableOrUnknown(data['question']!, _questionMeta));
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('option_a')) {
      context.handle(_optionAMeta,
          optionA.isAcceptableOrUnknown(data['option_a']!, _optionAMeta));
    } else if (isInserting) {
      context.missing(_optionAMeta);
    }
    if (data.containsKey('option_b')) {
      context.handle(_optionBMeta,
          optionB.isAcceptableOrUnknown(data['option_b']!, _optionBMeta));
    } else if (isInserting) {
      context.missing(_optionBMeta);
    }
    context.handle(_statedCriteriaMeta, const VerificationResult.success());
    if (data.containsKey('stakes')) {
      context.handle(_stakesMeta,
          stakes.isAcceptableOrUnknown(data['stakes']!, _stakesMeta));
    } else if (isInserting) {
      context.missing(_stakesMeta);
    }
    if (data.containsKey('regret_horizon')) {
      context.handle(
          _regretHorizonMeta,
          regretHorizon.isAcceptableOrUnknown(
              data['regret_horizon']!, _regretHorizonMeta));
    } else if (isInserting) {
      context.missing(_regretHorizonMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('community_visible')) {
      context.handle(
          _communityVisibleMeta,
          communityVisible.isAcceptableOrUnknown(
              data['community_visible']!, _communityVisibleMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaseRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      deadline: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deadline']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      question: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question'])!,
      optionA: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}option_a'])!,
      optionB: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}option_b'])!,
      statedCriteria: $CasesTable.$converterstatedCriteria.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}stated_criteria'])!),
      stakes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stakes'])!,
      regretHorizon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}regret_horizon'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      communityVisible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}community_visible'])!,
    );
  }

  @override
  $CasesTable createAlias(String alias) {
    return $CasesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<dynamic>, String> $converterstatedCriteria =
      const JsonListConverter();
}

class CaseRow extends DataClass implements Insertable<CaseRow> {
  final String id;
  final DateTime createdAt;
  final DateTime? deadline;
  final String status;
  final String question;
  final String optionA;
  final String optionB;
  final List<dynamic> statedCriteria;
  final String stakes;
  final String regretHorizon;
  final String? category;
  final bool communityVisible;
  const CaseRow(
      {required this.id,
      required this.createdAt,
      this.deadline,
      required this.status,
      required this.question,
      required this.optionA,
      required this.optionB,
      required this.statedCriteria,
      required this.stakes,
      required this.regretHorizon,
      this.category,
      required this.communityVisible});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['status'] = Variable<String>(status);
    map['question'] = Variable<String>(question);
    map['option_a'] = Variable<String>(optionA);
    map['option_b'] = Variable<String>(optionB);
    {
      map['stated_criteria'] = Variable<String>(
          $CasesTable.$converterstatedCriteria.toSql(statedCriteria));
    }
    map['stakes'] = Variable<String>(stakes);
    map['regret_horizon'] = Variable<String>(regretHorizon);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['community_visible'] = Variable<bool>(communityVisible);
    return map;
  }

  CasesCompanion toCompanion(bool nullToAbsent) {
    return CasesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      status: Value(status),
      question: Value(question),
      optionA: Value(optionA),
      optionB: Value(optionB),
      statedCriteria: Value(statedCriteria),
      stakes: Value(stakes),
      regretHorizon: Value(regretHorizon),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      communityVisible: Value(communityVisible),
    );
  }

  factory CaseRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaseRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      status: serializer.fromJson<String>(json['status']),
      question: serializer.fromJson<String>(json['question']),
      optionA: serializer.fromJson<String>(json['optionA']),
      optionB: serializer.fromJson<String>(json['optionB']),
      statedCriteria:
          serializer.fromJson<List<dynamic>>(json['statedCriteria']),
      stakes: serializer.fromJson<String>(json['stakes']),
      regretHorizon: serializer.fromJson<String>(json['regretHorizon']),
      category: serializer.fromJson<String?>(json['category']),
      communityVisible: serializer.fromJson<bool>(json['communityVisible']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'status': serializer.toJson<String>(status),
      'question': serializer.toJson<String>(question),
      'optionA': serializer.toJson<String>(optionA),
      'optionB': serializer.toJson<String>(optionB),
      'statedCriteria': serializer.toJson<List<dynamic>>(statedCriteria),
      'stakes': serializer.toJson<String>(stakes),
      'regretHorizon': serializer.toJson<String>(regretHorizon),
      'category': serializer.toJson<String?>(category),
      'communityVisible': serializer.toJson<bool>(communityVisible),
    };
  }

  CaseRow copyWith(
          {String? id,
          DateTime? createdAt,
          Value<DateTime?> deadline = const Value.absent(),
          String? status,
          String? question,
          String? optionA,
          String? optionB,
          List<dynamic>? statedCriteria,
          String? stakes,
          String? regretHorizon,
          Value<String?> category = const Value.absent(),
          bool? communityVisible}) =>
      CaseRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        deadline: deadline.present ? deadline.value : this.deadline,
        status: status ?? this.status,
        question: question ?? this.question,
        optionA: optionA ?? this.optionA,
        optionB: optionB ?? this.optionB,
        statedCriteria: statedCriteria ?? this.statedCriteria,
        stakes: stakes ?? this.stakes,
        regretHorizon: regretHorizon ?? this.regretHorizon,
        category: category.present ? category.value : this.category,
        communityVisible: communityVisible ?? this.communityVisible,
      );
  CaseRow copyWithCompanion(CasesCompanion data) {
    return CaseRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      status: data.status.present ? data.status.value : this.status,
      question: data.question.present ? data.question.value : this.question,
      optionA: data.optionA.present ? data.optionA.value : this.optionA,
      optionB: data.optionB.present ? data.optionB.value : this.optionB,
      statedCriteria: data.statedCriteria.present
          ? data.statedCriteria.value
          : this.statedCriteria,
      stakes: data.stakes.present ? data.stakes.value : this.stakes,
      regretHorizon: data.regretHorizon.present
          ? data.regretHorizon.value
          : this.regretHorizon,
      category: data.category.present ? data.category.value : this.category,
      communityVisible: data.communityVisible.present
          ? data.communityVisible.value
          : this.communityVisible,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaseRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('deadline: $deadline, ')
          ..write('status: $status, ')
          ..write('question: $question, ')
          ..write('optionA: $optionA, ')
          ..write('optionB: $optionB, ')
          ..write('statedCriteria: $statedCriteria, ')
          ..write('stakes: $stakes, ')
          ..write('regretHorizon: $regretHorizon, ')
          ..write('category: $category, ')
          ..write('communityVisible: $communityVisible')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      deadline,
      status,
      question,
      optionA,
      optionB,
      statedCriteria,
      stakes,
      regretHorizon,
      category,
      communityVisible);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaseRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.deadline == this.deadline &&
          other.status == this.status &&
          other.question == this.question &&
          other.optionA == this.optionA &&
          other.optionB == this.optionB &&
          other.statedCriteria == this.statedCriteria &&
          other.stakes == this.stakes &&
          other.regretHorizon == this.regretHorizon &&
          other.category == this.category &&
          other.communityVisible == this.communityVisible);
}

class CasesCompanion extends UpdateCompanion<CaseRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deadline;
  final Value<String> status;
  final Value<String> question;
  final Value<String> optionA;
  final Value<String> optionB;
  final Value<List<dynamic>> statedCriteria;
  final Value<String> stakes;
  final Value<String> regretHorizon;
  final Value<String?> category;
  final Value<bool> communityVisible;
  final Value<int> rowid;
  const CasesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deadline = const Value.absent(),
    this.status = const Value.absent(),
    this.question = const Value.absent(),
    this.optionA = const Value.absent(),
    this.optionB = const Value.absent(),
    this.statedCriteria = const Value.absent(),
    this.stakes = const Value.absent(),
    this.regretHorizon = const Value.absent(),
    this.category = const Value.absent(),
    this.communityVisible = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CasesCompanion.insert({
    required String id,
    required DateTime createdAt,
    this.deadline = const Value.absent(),
    required String status,
    required String question,
    required String optionA,
    required String optionB,
    required List<dynamic> statedCriteria,
    required String stakes,
    required String regretHorizon,
    this.category = const Value.absent(),
    this.communityVisible = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        status = Value(status),
        question = Value(question),
        optionA = Value(optionA),
        optionB = Value(optionB),
        statedCriteria = Value(statedCriteria),
        stakes = Value(stakes),
        regretHorizon = Value(regretHorizon);
  static Insertable<CaseRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deadline,
    Expression<String>? status,
    Expression<String>? question,
    Expression<String>? optionA,
    Expression<String>? optionB,
    Expression<String>? statedCriteria,
    Expression<String>? stakes,
    Expression<String>? regretHorizon,
    Expression<String>? category,
    Expression<bool>? communityVisible,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (deadline != null) 'deadline': deadline,
      if (status != null) 'status': status,
      if (question != null) 'question': question,
      if (optionA != null) 'option_a': optionA,
      if (optionB != null) 'option_b': optionB,
      if (statedCriteria != null) 'stated_criteria': statedCriteria,
      if (stakes != null) 'stakes': stakes,
      if (regretHorizon != null) 'regret_horizon': regretHorizon,
      if (category != null) 'category': category,
      if (communityVisible != null) 'community_visible': communityVisible,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CasesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime?>? deadline,
      Value<String>? status,
      Value<String>? question,
      Value<String>? optionA,
      Value<String>? optionB,
      Value<List<dynamic>>? statedCriteria,
      Value<String>? stakes,
      Value<String>? regretHorizon,
      Value<String?>? category,
      Value<bool>? communityVisible,
      Value<int>? rowid}) {
    return CasesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      question: question ?? this.question,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      statedCriteria: statedCriteria ?? this.statedCriteria,
      stakes: stakes ?? this.stakes,
      regretHorizon: regretHorizon ?? this.regretHorizon,
      category: category ?? this.category,
      communityVisible: communityVisible ?? this.communityVisible,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (optionA.present) {
      map['option_a'] = Variable<String>(optionA.value);
    }
    if (optionB.present) {
      map['option_b'] = Variable<String>(optionB.value);
    }
    if (statedCriteria.present) {
      map['stated_criteria'] = Variable<String>(
          $CasesTable.$converterstatedCriteria.toSql(statedCriteria.value));
    }
    if (stakes.present) {
      map['stakes'] = Variable<String>(stakes.value);
    }
    if (regretHorizon.present) {
      map['regret_horizon'] = Variable<String>(regretHorizon.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (communityVisible.present) {
      map['community_visible'] = Variable<bool>(communityVisible.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CasesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('deadline: $deadline, ')
          ..write('status: $status, ')
          ..write('question: $question, ')
          ..write('optionA: $optionA, ')
          ..write('optionB: $optionB, ')
          ..write('statedCriteria: $statedCriteria, ')
          ..write('stakes: $stakes, ')
          ..write('regretHorizon: $regretHorizon, ')
          ..write('category: $category, ')
          ..write('communityVisible: $communityVisible, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PollsTable extends Polls with TableInfo<$PollsTable, PollRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PollsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
      'case_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cases (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _pollNumberMeta =
      const VerificationMeta('pollNumber');
  @override
  late final GeneratedColumn<int> pollNumber = GeneratedColumn<int>(
      'poll_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _leanMeta = const VerificationMeta('lean');
  @override
  late final GeneratedColumn<int> lean = GeneratedColumn<int>(
      'lean', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _rationaleMeta =
      const VerificationMeta('rationale');
  @override
  late final GeneratedColumn<String> rationale = GeneratedColumn<String>(
      'rationale', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
      'confidence', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _revealedMeta =
      const VerificationMeta('revealed');
  @override
  late final GeneratedColumn<bool> revealed = GeneratedColumn<bool>(
      'revealed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("revealed" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        caseId,
        createdAt,
        pollNumber,
        lean,
        rationale,
        confidence,
        revealed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'polls';
  @override
  VerificationContext validateIntegrity(Insertable<PollRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(_caseIdMeta,
          caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta));
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('poll_number')) {
      context.handle(
          _pollNumberMeta,
          pollNumber.isAcceptableOrUnknown(
              data['poll_number']!, _pollNumberMeta));
    } else if (isInserting) {
      context.missing(_pollNumberMeta);
    }
    if (data.containsKey('lean')) {
      context.handle(
          _leanMeta, lean.isAcceptableOrUnknown(data['lean']!, _leanMeta));
    } else if (isInserting) {
      context.missing(_leanMeta);
    }
    if (data.containsKey('rationale')) {
      context.handle(_rationaleMeta,
          rationale.isAcceptableOrUnknown(data['rationale']!, _rationaleMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('revealed')) {
      context.handle(_revealedMeta,
          revealed.isAcceptableOrUnknown(data['revealed']!, _revealedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PollRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PollRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      caseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}case_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      pollNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}poll_number'])!,
      lean: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lean'])!,
      rationale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rationale']),
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}confidence'])!,
      revealed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}revealed'])!,
    );
  }

  @override
  $PollsTable createAlias(String alias) {
    return $PollsTable(attachedDatabase, alias);
  }
}

class PollRow extends DataClass implements Insertable<PollRow> {
  final String id;
  final String caseId;
  final DateTime createdAt;
  final int pollNumber;
  final int lean;
  final String? rationale;
  final String confidence;
  final bool revealed;
  const PollRow(
      {required this.id,
      required this.caseId,
      required this.createdAt,
      required this.pollNumber,
      required this.lean,
      this.rationale,
      required this.confidence,
      required this.revealed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['poll_number'] = Variable<int>(pollNumber);
    map['lean'] = Variable<int>(lean);
    if (!nullToAbsent || rationale != null) {
      map['rationale'] = Variable<String>(rationale);
    }
    map['confidence'] = Variable<String>(confidence);
    map['revealed'] = Variable<bool>(revealed);
    return map;
  }

  PollsCompanion toCompanion(bool nullToAbsent) {
    return PollsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      createdAt: Value(createdAt),
      pollNumber: Value(pollNumber),
      lean: Value(lean),
      rationale: rationale == null && nullToAbsent
          ? const Value.absent()
          : Value(rationale),
      confidence: Value(confidence),
      revealed: Value(revealed),
    );
  }

  factory PollRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PollRow(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      pollNumber: serializer.fromJson<int>(json['pollNumber']),
      lean: serializer.fromJson<int>(json['lean']),
      rationale: serializer.fromJson<String?>(json['rationale']),
      confidence: serializer.fromJson<String>(json['confidence']),
      revealed: serializer.fromJson<bool>(json['revealed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'pollNumber': serializer.toJson<int>(pollNumber),
      'lean': serializer.toJson<int>(lean),
      'rationale': serializer.toJson<String?>(rationale),
      'confidence': serializer.toJson<String>(confidence),
      'revealed': serializer.toJson<bool>(revealed),
    };
  }

  PollRow copyWith(
          {String? id,
          String? caseId,
          DateTime? createdAt,
          int? pollNumber,
          int? lean,
          Value<String?> rationale = const Value.absent(),
          String? confidence,
          bool? revealed}) =>
      PollRow(
        id: id ?? this.id,
        caseId: caseId ?? this.caseId,
        createdAt: createdAt ?? this.createdAt,
        pollNumber: pollNumber ?? this.pollNumber,
        lean: lean ?? this.lean,
        rationale: rationale.present ? rationale.value : this.rationale,
        confidence: confidence ?? this.confidence,
        revealed: revealed ?? this.revealed,
      );
  PollRow copyWithCompanion(PollsCompanion data) {
    return PollRow(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      pollNumber:
          data.pollNumber.present ? data.pollNumber.value : this.pollNumber,
      lean: data.lean.present ? data.lean.value : this.lean,
      rationale: data.rationale.present ? data.rationale.value : this.rationale,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      revealed: data.revealed.present ? data.revealed.value : this.revealed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PollRow(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('pollNumber: $pollNumber, ')
          ..write('lean: $lean, ')
          ..write('rationale: $rationale, ')
          ..write('confidence: $confidence, ')
          ..write('revealed: $revealed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, caseId, createdAt, pollNumber, lean, rationale, confidence, revealed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PollRow &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.createdAt == this.createdAt &&
          other.pollNumber == this.pollNumber &&
          other.lean == this.lean &&
          other.rationale == this.rationale &&
          other.confidence == this.confidence &&
          other.revealed == this.revealed);
}

class PollsCompanion extends UpdateCompanion<PollRow> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<DateTime> createdAt;
  final Value<int> pollNumber;
  final Value<int> lean;
  final Value<String?> rationale;
  final Value<String> confidence;
  final Value<bool> revealed;
  final Value<int> rowid;
  const PollsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pollNumber = const Value.absent(),
    this.lean = const Value.absent(),
    this.rationale = const Value.absent(),
    this.confidence = const Value.absent(),
    this.revealed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PollsCompanion.insert({
    required String id,
    required String caseId,
    required DateTime createdAt,
    required int pollNumber,
    required int lean,
    this.rationale = const Value.absent(),
    required String confidence,
    this.revealed = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        caseId = Value(caseId),
        createdAt = Value(createdAt),
        pollNumber = Value(pollNumber),
        lean = Value(lean),
        confidence = Value(confidence);
  static Insertable<PollRow> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<DateTime>? createdAt,
    Expression<int>? pollNumber,
    Expression<int>? lean,
    Expression<String>? rationale,
    Expression<String>? confidence,
    Expression<bool>? revealed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (createdAt != null) 'created_at': createdAt,
      if (pollNumber != null) 'poll_number': pollNumber,
      if (lean != null) 'lean': lean,
      if (rationale != null) 'rationale': rationale,
      if (confidence != null) 'confidence': confidence,
      if (revealed != null) 'revealed': revealed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PollsCompanion copyWith(
      {Value<String>? id,
      Value<String>? caseId,
      Value<DateTime>? createdAt,
      Value<int>? pollNumber,
      Value<int>? lean,
      Value<String?>? rationale,
      Value<String>? confidence,
      Value<bool>? revealed,
      Value<int>? rowid}) {
    return PollsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      createdAt: createdAt ?? this.createdAt,
      pollNumber: pollNumber ?? this.pollNumber,
      lean: lean ?? this.lean,
      rationale: rationale ?? this.rationale,
      confidence: confidence ?? this.confidence,
      revealed: revealed ?? this.revealed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (pollNumber.present) {
      map['poll_number'] = Variable<int>(pollNumber.value);
    }
    if (lean.present) {
      map['lean'] = Variable<int>(lean.value);
    }
    if (rationale.present) {
      map['rationale'] = Variable<String>(rationale.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (revealed.present) {
      map['revealed'] = Variable<bool>(revealed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PollsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('pollNumber: $pollNumber, ')
          ..write('lean: $lean, ')
          ..write('rationale: $rationale, ')
          ..write('confidence: $confidence, ')
          ..write('revealed: $revealed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResolutionsTable extends Resolutions
    with TableInfo<$ResolutionsTable, ResolutionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResolutionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
      'case_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cases (id)'));
  static const VerificationMeta _decidedAtMeta =
      const VerificationMeta('decidedAt');
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
      'decided_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _chosenOptionMeta =
      const VerificationMeta('chosenOption');
  @override
  late final GeneratedColumn<String> chosenOption = GeneratedColumn<String>(
      'chosen_option', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resolutionCheckDateMeta =
      const VerificationMeta('resolutionCheckDate');
  @override
  late final GeneratedColumn<DateTime> resolutionCheckDate =
      GeneratedColumn<DateTime>('resolution_check_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _satisfactionScoreMeta =
      const VerificationMeta('satisfactionScore');
  @override
  late final GeneratedColumn<int> satisfactionScore = GeneratedColumn<int>(
      'satisfaction_score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _reflectionMeta =
      const VerificationMeta('reflection');
  @override
  late final GeneratedColumn<String> reflection = GeneratedColumn<String>(
      'reflection', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        caseId,
        decidedAt,
        chosenOption,
        resolutionCheckDate,
        satisfactionScore,
        reflection
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resolutions';
  @override
  VerificationContext validateIntegrity(Insertable<ResolutionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(_caseIdMeta,
          caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta));
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('decided_at')) {
      context.handle(_decidedAtMeta,
          decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta));
    } else if (isInserting) {
      context.missing(_decidedAtMeta);
    }
    if (data.containsKey('chosen_option')) {
      context.handle(
          _chosenOptionMeta,
          chosenOption.isAcceptableOrUnknown(
              data['chosen_option']!, _chosenOptionMeta));
    } else if (isInserting) {
      context.missing(_chosenOptionMeta);
    }
    if (data.containsKey('resolution_check_date')) {
      context.handle(
          _resolutionCheckDateMeta,
          resolutionCheckDate.isAcceptableOrUnknown(
              data['resolution_check_date']!, _resolutionCheckDateMeta));
    } else if (isInserting) {
      context.missing(_resolutionCheckDateMeta);
    }
    if (data.containsKey('satisfaction_score')) {
      context.handle(
          _satisfactionScoreMeta,
          satisfactionScore.isAcceptableOrUnknown(
              data['satisfaction_score']!, _satisfactionScoreMeta));
    }
    if (data.containsKey('reflection')) {
      context.handle(
          _reflectionMeta,
          reflection.isAcceptableOrUnknown(
              data['reflection']!, _reflectionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResolutionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResolutionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      caseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}case_id'])!,
      decidedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}decided_at'])!,
      chosenOption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chosen_option'])!,
      resolutionCheckDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}resolution_check_date'])!,
      satisfactionScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}satisfaction_score']),
      reflection: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reflection']),
    );
  }

  @override
  $ResolutionsTable createAlias(String alias) {
    return $ResolutionsTable(attachedDatabase, alias);
  }
}

class ResolutionRow extends DataClass implements Insertable<ResolutionRow> {
  final String id;
  final String caseId;
  final DateTime decidedAt;
  final String chosenOption;
  final DateTime resolutionCheckDate;
  final int? satisfactionScore;
  final String? reflection;
  const ResolutionRow(
      {required this.id,
      required this.caseId,
      required this.decidedAt,
      required this.chosenOption,
      required this.resolutionCheckDate,
      this.satisfactionScore,
      this.reflection});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    map['decided_at'] = Variable<DateTime>(decidedAt);
    map['chosen_option'] = Variable<String>(chosenOption);
    map['resolution_check_date'] = Variable<DateTime>(resolutionCheckDate);
    if (!nullToAbsent || satisfactionScore != null) {
      map['satisfaction_score'] = Variable<int>(satisfactionScore);
    }
    if (!nullToAbsent || reflection != null) {
      map['reflection'] = Variable<String>(reflection);
    }
    return map;
  }

  ResolutionsCompanion toCompanion(bool nullToAbsent) {
    return ResolutionsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      decidedAt: Value(decidedAt),
      chosenOption: Value(chosenOption),
      resolutionCheckDate: Value(resolutionCheckDate),
      satisfactionScore: satisfactionScore == null && nullToAbsent
          ? const Value.absent()
          : Value(satisfactionScore),
      reflection: reflection == null && nullToAbsent
          ? const Value.absent()
          : Value(reflection),
    );
  }

  factory ResolutionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResolutionRow(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      decidedAt: serializer.fromJson<DateTime>(json['decidedAt']),
      chosenOption: serializer.fromJson<String>(json['chosenOption']),
      resolutionCheckDate:
          serializer.fromJson<DateTime>(json['resolutionCheckDate']),
      satisfactionScore: serializer.fromJson<int?>(json['satisfactionScore']),
      reflection: serializer.fromJson<String?>(json['reflection']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'decidedAt': serializer.toJson<DateTime>(decidedAt),
      'chosenOption': serializer.toJson<String>(chosenOption),
      'resolutionCheckDate': serializer.toJson<DateTime>(resolutionCheckDate),
      'satisfactionScore': serializer.toJson<int?>(satisfactionScore),
      'reflection': serializer.toJson<String?>(reflection),
    };
  }

  ResolutionRow copyWith(
          {String? id,
          String? caseId,
          DateTime? decidedAt,
          String? chosenOption,
          DateTime? resolutionCheckDate,
          Value<int?> satisfactionScore = const Value.absent(),
          Value<String?> reflection = const Value.absent()}) =>
      ResolutionRow(
        id: id ?? this.id,
        caseId: caseId ?? this.caseId,
        decidedAt: decidedAt ?? this.decidedAt,
        chosenOption: chosenOption ?? this.chosenOption,
        resolutionCheckDate: resolutionCheckDate ?? this.resolutionCheckDate,
        satisfactionScore: satisfactionScore.present
            ? satisfactionScore.value
            : this.satisfactionScore,
        reflection: reflection.present ? reflection.value : this.reflection,
      );
  ResolutionRow copyWithCompanion(ResolutionsCompanion data) {
    return ResolutionRow(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      chosenOption: data.chosenOption.present
          ? data.chosenOption.value
          : this.chosenOption,
      resolutionCheckDate: data.resolutionCheckDate.present
          ? data.resolutionCheckDate.value
          : this.resolutionCheckDate,
      satisfactionScore: data.satisfactionScore.present
          ? data.satisfactionScore.value
          : this.satisfactionScore,
      reflection:
          data.reflection.present ? data.reflection.value : this.reflection,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResolutionRow(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('chosenOption: $chosenOption, ')
          ..write('resolutionCheckDate: $resolutionCheckDate, ')
          ..write('satisfactionScore: $satisfactionScore, ')
          ..write('reflection: $reflection')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, caseId, decidedAt, chosenOption,
      resolutionCheckDate, satisfactionScore, reflection);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResolutionRow &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.decidedAt == this.decidedAt &&
          other.chosenOption == this.chosenOption &&
          other.resolutionCheckDate == this.resolutionCheckDate &&
          other.satisfactionScore == this.satisfactionScore &&
          other.reflection == this.reflection);
}

class ResolutionsCompanion extends UpdateCompanion<ResolutionRow> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<DateTime> decidedAt;
  final Value<String> chosenOption;
  final Value<DateTime> resolutionCheckDate;
  final Value<int?> satisfactionScore;
  final Value<String?> reflection;
  final Value<int> rowid;
  const ResolutionsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.chosenOption = const Value.absent(),
    this.resolutionCheckDate = const Value.absent(),
    this.satisfactionScore = const Value.absent(),
    this.reflection = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResolutionsCompanion.insert({
    required String id,
    required String caseId,
    required DateTime decidedAt,
    required String chosenOption,
    required DateTime resolutionCheckDate,
    this.satisfactionScore = const Value.absent(),
    this.reflection = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        caseId = Value(caseId),
        decidedAt = Value(decidedAt),
        chosenOption = Value(chosenOption),
        resolutionCheckDate = Value(resolutionCheckDate);
  static Insertable<ResolutionRow> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<DateTime>? decidedAt,
    Expression<String>? chosenOption,
    Expression<DateTime>? resolutionCheckDate,
    Expression<int>? satisfactionScore,
    Expression<String>? reflection,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (chosenOption != null) 'chosen_option': chosenOption,
      if (resolutionCheckDate != null)
        'resolution_check_date': resolutionCheckDate,
      if (satisfactionScore != null) 'satisfaction_score': satisfactionScore,
      if (reflection != null) 'reflection': reflection,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResolutionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? caseId,
      Value<DateTime>? decidedAt,
      Value<String>? chosenOption,
      Value<DateTime>? resolutionCheckDate,
      Value<int?>? satisfactionScore,
      Value<String?>? reflection,
      Value<int>? rowid}) {
    return ResolutionsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      decidedAt: decidedAt ?? this.decidedAt,
      chosenOption: chosenOption ?? this.chosenOption,
      resolutionCheckDate: resolutionCheckDate ?? this.resolutionCheckDate,
      satisfactionScore: satisfactionScore ?? this.satisfactionScore,
      reflection: reflection ?? this.reflection,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (chosenOption.present) {
      map['chosen_option'] = Variable<String>(chosenOption.value);
    }
    if (resolutionCheckDate.present) {
      map['resolution_check_date'] =
          Variable<DateTime>(resolutionCheckDate.value);
    }
    if (satisfactionScore.present) {
      map['satisfaction_score'] = Variable<int>(satisfactionScore.value);
    }
    if (reflection.present) {
      map['reflection'] = Variable<String>(reflection.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResolutionsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('chosenOption: $chosenOption, ')
          ..write('resolutionCheckDate: $resolutionCheckDate, ')
          ..write('satisfactionScore: $satisfactionScore, ')
          ..write('reflection: $reflection, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutsideViewsTable extends OutsideViews
    with TableInfo<$OutsideViewsTable, OutsideViewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutsideViewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
      'case_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cases (id)'));
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _baseRateSummaryMeta =
      const VerificationMeta('baseRateSummary');
  @override
  late final GeneratedColumn<String> baseRateSummary = GeneratedColumn<String>(
      'base_rate_summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _referenceClassUsedMeta =
      const VerificationMeta('referenceClassUsed');
  @override
  late final GeneratedColumn<String> referenceClassUsed =
      GeneratedColumn<String>('reference_class_used', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _uncertaintyLevelMeta =
      const VerificationMeta('uncertaintyLevel');
  @override
  late final GeneratedColumn<String> uncertaintyLevel = GeneratedColumn<String>(
      'uncertainty_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stratificationFactorsMeta =
      const VerificationMeta('stratificationFactors');
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
      stratificationFactors = GeneratedColumn<String>(
              'stratification_factors', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Map<String, dynamic>>(
              $OutsideViewsTable.$converterstratificationFactors);
  static const VerificationMeta _llmModeMeta =
      const VerificationMeta('llmMode');
  @override
  late final GeneratedColumn<String> llmMode = GeneratedColumn<String>(
      'llm_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelVersionMeta =
      const VerificationMeta('modelVersion');
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
      'model_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _citationsMeta =
      const VerificationMeta('citations');
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>?, String>
      citations = GeneratedColumn<String>('citations', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<dynamic>?>(
              $OutsideViewsTable.$convertercitationsn);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        caseId,
        generatedAt,
        baseRateSummary,
        referenceClassUsed,
        uncertaintyLevel,
        stratificationFactors,
        llmMode,
        modelVersion,
        citations
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outside_views';
  @override
  VerificationContext validateIntegrity(Insertable<OutsideViewRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(_caseIdMeta,
          caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta));
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('base_rate_summary')) {
      context.handle(
          _baseRateSummaryMeta,
          baseRateSummary.isAcceptableOrUnknown(
              data['base_rate_summary']!, _baseRateSummaryMeta));
    } else if (isInserting) {
      context.missing(_baseRateSummaryMeta);
    }
    if (data.containsKey('reference_class_used')) {
      context.handle(
          _referenceClassUsedMeta,
          referenceClassUsed.isAcceptableOrUnknown(
              data['reference_class_used']!, _referenceClassUsedMeta));
    } else if (isInserting) {
      context.missing(_referenceClassUsedMeta);
    }
    if (data.containsKey('uncertainty_level')) {
      context.handle(
          _uncertaintyLevelMeta,
          uncertaintyLevel.isAcceptableOrUnknown(
              data['uncertainty_level']!, _uncertaintyLevelMeta));
    } else if (isInserting) {
      context.missing(_uncertaintyLevelMeta);
    }
    context.handle(
        _stratificationFactorsMeta, const VerificationResult.success());
    if (data.containsKey('llm_mode')) {
      context.handle(_llmModeMeta,
          llmMode.isAcceptableOrUnknown(data['llm_mode']!, _llmModeMeta));
    } else if (isInserting) {
      context.missing(_llmModeMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
          _modelVersionMeta,
          modelVersion.isAcceptableOrUnknown(
              data['model_version']!, _modelVersionMeta));
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    context.handle(_citationsMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutsideViewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutsideViewRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      caseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}case_id'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      baseRateSummary: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}base_rate_summary'])!,
      referenceClassUsed: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reference_class_used'])!,
      uncertaintyLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}uncertainty_level'])!,
      stratificationFactors: $OutsideViewsTable.$converterstratificationFactors
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}stratification_factors'])!),
      llmMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}llm_mode'])!,
      modelVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_version'])!,
      citations: $OutsideViewsTable.$convertercitationsn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.string, data['${effectivePrefix}citations'])),
    );
  }

  @override
  $OutsideViewsTable createAlias(String alias) {
    return $OutsideViewsTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, dynamic>, String>
      $converterstratificationFactors = const JsonMapConverter();
  static TypeConverter<List<dynamic>, String> $convertercitations =
      const JsonListConverter();
  static TypeConverter<List<dynamic>?, String?> $convertercitationsn =
      NullAwareTypeConverter.wrap($convertercitations);
}

class OutsideViewRow extends DataClass implements Insertable<OutsideViewRow> {
  final String id;
  final String caseId;
  final DateTime generatedAt;
  final String baseRateSummary;
  final String referenceClassUsed;
  final String uncertaintyLevel;
  final Map<String, dynamic> stratificationFactors;
  final String llmMode;
  final String modelVersion;

  /// Curated literature citations ([{author, title, url}]) snapshotted from the
  /// reference class at generation time. Nullable: rows written before v3 have
  /// none, and are read back as an empty list.
  final List<dynamic>? citations;
  const OutsideViewRow(
      {required this.id,
      required this.caseId,
      required this.generatedAt,
      required this.baseRateSummary,
      required this.referenceClassUsed,
      required this.uncertaintyLevel,
      required this.stratificationFactors,
      required this.llmMode,
      required this.modelVersion,
      this.citations});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['base_rate_summary'] = Variable<String>(baseRateSummary);
    map['reference_class_used'] = Variable<String>(referenceClassUsed);
    map['uncertainty_level'] = Variable<String>(uncertaintyLevel);
    {
      map['stratification_factors'] = Variable<String>($OutsideViewsTable
          .$converterstratificationFactors
          .toSql(stratificationFactors));
    }
    map['llm_mode'] = Variable<String>(llmMode);
    map['model_version'] = Variable<String>(modelVersion);
    if (!nullToAbsent || citations != null) {
      map['citations'] = Variable<String>(
          $OutsideViewsTable.$convertercitationsn.toSql(citations));
    }
    return map;
  }

  OutsideViewsCompanion toCompanion(bool nullToAbsent) {
    return OutsideViewsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      generatedAt: Value(generatedAt),
      baseRateSummary: Value(baseRateSummary),
      referenceClassUsed: Value(referenceClassUsed),
      uncertaintyLevel: Value(uncertaintyLevel),
      stratificationFactors: Value(stratificationFactors),
      llmMode: Value(llmMode),
      modelVersion: Value(modelVersion),
      citations: citations == null && nullToAbsent
          ? const Value.absent()
          : Value(citations),
    );
  }

  factory OutsideViewRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutsideViewRow(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      baseRateSummary: serializer.fromJson<String>(json['baseRateSummary']),
      referenceClassUsed:
          serializer.fromJson<String>(json['referenceClassUsed']),
      uncertaintyLevel: serializer.fromJson<String>(json['uncertaintyLevel']),
      stratificationFactors: serializer
          .fromJson<Map<String, dynamic>>(json['stratificationFactors']),
      llmMode: serializer.fromJson<String>(json['llmMode']),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      citations: serializer.fromJson<List<dynamic>?>(json['citations']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'baseRateSummary': serializer.toJson<String>(baseRateSummary),
      'referenceClassUsed': serializer.toJson<String>(referenceClassUsed),
      'uncertaintyLevel': serializer.toJson<String>(uncertaintyLevel),
      'stratificationFactors':
          serializer.toJson<Map<String, dynamic>>(stratificationFactors),
      'llmMode': serializer.toJson<String>(llmMode),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'citations': serializer.toJson<List<dynamic>?>(citations),
    };
  }

  OutsideViewRow copyWith(
          {String? id,
          String? caseId,
          DateTime? generatedAt,
          String? baseRateSummary,
          String? referenceClassUsed,
          String? uncertaintyLevel,
          Map<String, dynamic>? stratificationFactors,
          String? llmMode,
          String? modelVersion,
          Value<List<dynamic>?> citations = const Value.absent()}) =>
      OutsideViewRow(
        id: id ?? this.id,
        caseId: caseId ?? this.caseId,
        generatedAt: generatedAt ?? this.generatedAt,
        baseRateSummary: baseRateSummary ?? this.baseRateSummary,
        referenceClassUsed: referenceClassUsed ?? this.referenceClassUsed,
        uncertaintyLevel: uncertaintyLevel ?? this.uncertaintyLevel,
        stratificationFactors:
            stratificationFactors ?? this.stratificationFactors,
        llmMode: llmMode ?? this.llmMode,
        modelVersion: modelVersion ?? this.modelVersion,
        citations: citations.present ? citations.value : this.citations,
      );
  OutsideViewRow copyWithCompanion(OutsideViewsCompanion data) {
    return OutsideViewRow(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      baseRateSummary: data.baseRateSummary.present
          ? data.baseRateSummary.value
          : this.baseRateSummary,
      referenceClassUsed: data.referenceClassUsed.present
          ? data.referenceClassUsed.value
          : this.referenceClassUsed,
      uncertaintyLevel: data.uncertaintyLevel.present
          ? data.uncertaintyLevel.value
          : this.uncertaintyLevel,
      stratificationFactors: data.stratificationFactors.present
          ? data.stratificationFactors.value
          : this.stratificationFactors,
      llmMode: data.llmMode.present ? data.llmMode.value : this.llmMode,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      citations: data.citations.present ? data.citations.value : this.citations,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutsideViewRow(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('baseRateSummary: $baseRateSummary, ')
          ..write('referenceClassUsed: $referenceClassUsed, ')
          ..write('uncertaintyLevel: $uncertaintyLevel, ')
          ..write('stratificationFactors: $stratificationFactors, ')
          ..write('llmMode: $llmMode, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('citations: $citations')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      caseId,
      generatedAt,
      baseRateSummary,
      referenceClassUsed,
      uncertaintyLevel,
      stratificationFactors,
      llmMode,
      modelVersion,
      citations);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutsideViewRow &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.generatedAt == this.generatedAt &&
          other.baseRateSummary == this.baseRateSummary &&
          other.referenceClassUsed == this.referenceClassUsed &&
          other.uncertaintyLevel == this.uncertaintyLevel &&
          other.stratificationFactors == this.stratificationFactors &&
          other.llmMode == this.llmMode &&
          other.modelVersion == this.modelVersion &&
          other.citations == this.citations);
}

class OutsideViewsCompanion extends UpdateCompanion<OutsideViewRow> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<DateTime> generatedAt;
  final Value<String> baseRateSummary;
  final Value<String> referenceClassUsed;
  final Value<String> uncertaintyLevel;
  final Value<Map<String, dynamic>> stratificationFactors;
  final Value<String> llmMode;
  final Value<String> modelVersion;
  final Value<List<dynamic>?> citations;
  final Value<int> rowid;
  const OutsideViewsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.baseRateSummary = const Value.absent(),
    this.referenceClassUsed = const Value.absent(),
    this.uncertaintyLevel = const Value.absent(),
    this.stratificationFactors = const Value.absent(),
    this.llmMode = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.citations = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutsideViewsCompanion.insert({
    required String id,
    required String caseId,
    required DateTime generatedAt,
    required String baseRateSummary,
    required String referenceClassUsed,
    required String uncertaintyLevel,
    required Map<String, dynamic> stratificationFactors,
    required String llmMode,
    required String modelVersion,
    this.citations = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        caseId = Value(caseId),
        generatedAt = Value(generatedAt),
        baseRateSummary = Value(baseRateSummary),
        referenceClassUsed = Value(referenceClassUsed),
        uncertaintyLevel = Value(uncertaintyLevel),
        stratificationFactors = Value(stratificationFactors),
        llmMode = Value(llmMode),
        modelVersion = Value(modelVersion);
  static Insertable<OutsideViewRow> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<DateTime>? generatedAt,
    Expression<String>? baseRateSummary,
    Expression<String>? referenceClassUsed,
    Expression<String>? uncertaintyLevel,
    Expression<String>? stratificationFactors,
    Expression<String>? llmMode,
    Expression<String>? modelVersion,
    Expression<String>? citations,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (baseRateSummary != null) 'base_rate_summary': baseRateSummary,
      if (referenceClassUsed != null)
        'reference_class_used': referenceClassUsed,
      if (uncertaintyLevel != null) 'uncertainty_level': uncertaintyLevel,
      if (stratificationFactors != null)
        'stratification_factors': stratificationFactors,
      if (llmMode != null) 'llm_mode': llmMode,
      if (modelVersion != null) 'model_version': modelVersion,
      if (citations != null) 'citations': citations,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutsideViewsCompanion copyWith(
      {Value<String>? id,
      Value<String>? caseId,
      Value<DateTime>? generatedAt,
      Value<String>? baseRateSummary,
      Value<String>? referenceClassUsed,
      Value<String>? uncertaintyLevel,
      Value<Map<String, dynamic>>? stratificationFactors,
      Value<String>? llmMode,
      Value<String>? modelVersion,
      Value<List<dynamic>?>? citations,
      Value<int>? rowid}) {
    return OutsideViewsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      generatedAt: generatedAt ?? this.generatedAt,
      baseRateSummary: baseRateSummary ?? this.baseRateSummary,
      referenceClassUsed: referenceClassUsed ?? this.referenceClassUsed,
      uncertaintyLevel: uncertaintyLevel ?? this.uncertaintyLevel,
      stratificationFactors:
          stratificationFactors ?? this.stratificationFactors,
      llmMode: llmMode ?? this.llmMode,
      modelVersion: modelVersion ?? this.modelVersion,
      citations: citations ?? this.citations,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (baseRateSummary.present) {
      map['base_rate_summary'] = Variable<String>(baseRateSummary.value);
    }
    if (referenceClassUsed.present) {
      map['reference_class_used'] = Variable<String>(referenceClassUsed.value);
    }
    if (uncertaintyLevel.present) {
      map['uncertainty_level'] = Variable<String>(uncertaintyLevel.value);
    }
    if (stratificationFactors.present) {
      map['stratification_factors'] = Variable<String>($OutsideViewsTable
          .$converterstratificationFactors
          .toSql(stratificationFactors.value));
    }
    if (llmMode.present) {
      map['llm_mode'] = Variable<String>(llmMode.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (citations.present) {
      map['citations'] = Variable<String>(
          $OutsideViewsTable.$convertercitationsn.toSql(citations.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutsideViewsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('baseRateSummary: $baseRateSummary, ')
          ..write('referenceClassUsed: $referenceClassUsed, ')
          ..write('uncertaintyLevel: $uncertaintyLevel, ')
          ..write('stratificationFactors: $stratificationFactors, ')
          ..write('llmMode: $llmMode, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('citations: $citations, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReferenceClassesTable extends ReferenceClasses
    with TableInfo<$ReferenceClassesTable, ReferenceClassRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferenceClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subcategoryMeta =
      const VerificationMeta('subcategory');
  @override
  late final GeneratedColumn<String> subcategory = GeneratedColumn<String>(
      'subcategory', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseRateDescriptionMeta =
      const VerificationMeta('baseRateDescription');
  @override
  late final GeneratedColumn<String> baseRateDescription =
      GeneratedColumn<String>('base_rate_description', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stratificationVariablesMeta =
      const VerificationMeta('stratificationVariables');
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String>
      stratificationVariables = GeneratedColumn<String>(
              'stratification_variables', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<dynamic>>(
              $ReferenceClassesTable.$converterstratificationVariables);
  static const VerificationMeta _sourcesMeta =
      const VerificationMeta('sources');
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String> sources =
      GeneratedColumn<String>('sources', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<dynamic>>(
              $ReferenceClassesTable.$convertersources);
  static const VerificationMeta _commonCriteriaMeta =
      const VerificationMeta('commonCriteria');
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String>
      commonCriteria = GeneratedColumn<String>(
              'common_criteria', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<dynamic>>(
              $ReferenceClassesTable.$convertercommonCriteria);
  static const VerificationMeta _commonRegretPatternsMeta =
      const VerificationMeta('commonRegretPatterns');
  @override
  late final GeneratedColumn<String> commonRegretPatterns =
      GeneratedColumn<String>('common_regret_patterns', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _uncertaintyLevelMeta =
      const VerificationMeta('uncertaintyLevel');
  @override
  late final GeneratedColumn<String> uncertaintyLevel = GeneratedColumn<String>(
      'uncertainty_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<String> lastUpdated = GeneratedColumn<String>(
      'last_updated', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        category,
        subcategory,
        baseRateDescription,
        stratificationVariables,
        sources,
        commonCriteria,
        commonRegretPatterns,
        uncertaintyLevel,
        lastUpdated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_classes';
  @override
  VerificationContext validateIntegrity(Insertable<ReferenceClassRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('subcategory')) {
      context.handle(
          _subcategoryMeta,
          subcategory.isAcceptableOrUnknown(
              data['subcategory']!, _subcategoryMeta));
    } else if (isInserting) {
      context.missing(_subcategoryMeta);
    }
    if (data.containsKey('base_rate_description')) {
      context.handle(
          _baseRateDescriptionMeta,
          baseRateDescription.isAcceptableOrUnknown(
              data['base_rate_description']!, _baseRateDescriptionMeta));
    } else if (isInserting) {
      context.missing(_baseRateDescriptionMeta);
    }
    context.handle(
        _stratificationVariablesMeta, const VerificationResult.success());
    context.handle(_sourcesMeta, const VerificationResult.success());
    context.handle(_commonCriteriaMeta, const VerificationResult.success());
    if (data.containsKey('common_regret_patterns')) {
      context.handle(
          _commonRegretPatternsMeta,
          commonRegretPatterns.isAcceptableOrUnknown(
              data['common_regret_patterns']!, _commonRegretPatternsMeta));
    } else if (isInserting) {
      context.missing(_commonRegretPatternsMeta);
    }
    if (data.containsKey('uncertainty_level')) {
      context.handle(
          _uncertaintyLevelMeta,
          uncertaintyLevel.isAcceptableOrUnknown(
              data['uncertainty_level']!, _uncertaintyLevelMeta));
    } else if (isInserting) {
      context.missing(_uncertaintyLevelMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferenceClassRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferenceClassRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      subcategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subcategory'])!,
      baseRateDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}base_rate_description'])!,
      stratificationVariables: $ReferenceClassesTable
          .$converterstratificationVariables
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}stratification_variables'])!),
      sources: $ReferenceClassesTable.$convertersources.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sources'])!),
      commonCriteria: $ReferenceClassesTable.$convertercommonCriteria.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}common_criteria'])!),
      commonRegretPatterns: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}common_regret_patterns'])!,
      uncertaintyLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}uncertainty_level'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_updated'])!,
    );
  }

  @override
  $ReferenceClassesTable createAlias(String alias) {
    return $ReferenceClassesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<dynamic>, String>
      $converterstratificationVariables = const JsonListConverter();
  static TypeConverter<List<dynamic>, String> $convertersources =
      const JsonListConverter();
  static TypeConverter<List<dynamic>, String> $convertercommonCriteria =
      const JsonListConverter();
}

class ReferenceClassRow extends DataClass
    implements Insertable<ReferenceClassRow> {
  final String id;
  final String category;
  final String subcategory;
  final String baseRateDescription;
  final List<dynamic> stratificationVariables;
  final List<dynamic> sources;
  final List<dynamic> commonCriteria;
  final String commonRegretPatterns;
  final String uncertaintyLevel;
  final String lastUpdated;
  const ReferenceClassRow(
      {required this.id,
      required this.category,
      required this.subcategory,
      required this.baseRateDescription,
      required this.stratificationVariables,
      required this.sources,
      required this.commonCriteria,
      required this.commonRegretPatterns,
      required this.uncertaintyLevel,
      required this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['subcategory'] = Variable<String>(subcategory);
    map['base_rate_description'] = Variable<String>(baseRateDescription);
    {
      map['stratification_variables'] = Variable<String>($ReferenceClassesTable
          .$converterstratificationVariables
          .toSql(stratificationVariables));
    }
    {
      map['sources'] = Variable<String>(
          $ReferenceClassesTable.$convertersources.toSql(sources));
    }
    {
      map['common_criteria'] = Variable<String>($ReferenceClassesTable
          .$convertercommonCriteria
          .toSql(commonCriteria));
    }
    map['common_regret_patterns'] = Variable<String>(commonRegretPatterns);
    map['uncertainty_level'] = Variable<String>(uncertaintyLevel);
    map['last_updated'] = Variable<String>(lastUpdated);
    return map;
  }

  ReferenceClassesCompanion toCompanion(bool nullToAbsent) {
    return ReferenceClassesCompanion(
      id: Value(id),
      category: Value(category),
      subcategory: Value(subcategory),
      baseRateDescription: Value(baseRateDescription),
      stratificationVariables: Value(stratificationVariables),
      sources: Value(sources),
      commonCriteria: Value(commonCriteria),
      commonRegretPatterns: Value(commonRegretPatterns),
      uncertaintyLevel: Value(uncertaintyLevel),
      lastUpdated: Value(lastUpdated),
    );
  }

  factory ReferenceClassRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceClassRow(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      subcategory: serializer.fromJson<String>(json['subcategory']),
      baseRateDescription:
          serializer.fromJson<String>(json['baseRateDescription']),
      stratificationVariables:
          serializer.fromJson<List<dynamic>>(json['stratificationVariables']),
      sources: serializer.fromJson<List<dynamic>>(json['sources']),
      commonCriteria:
          serializer.fromJson<List<dynamic>>(json['commonCriteria']),
      commonRegretPatterns:
          serializer.fromJson<String>(json['commonRegretPatterns']),
      uncertaintyLevel: serializer.fromJson<String>(json['uncertaintyLevel']),
      lastUpdated: serializer.fromJson<String>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'subcategory': serializer.toJson<String>(subcategory),
      'baseRateDescription': serializer.toJson<String>(baseRateDescription),
      'stratificationVariables':
          serializer.toJson<List<dynamic>>(stratificationVariables),
      'sources': serializer.toJson<List<dynamic>>(sources),
      'commonCriteria': serializer.toJson<List<dynamic>>(commonCriteria),
      'commonRegretPatterns': serializer.toJson<String>(commonRegretPatterns),
      'uncertaintyLevel': serializer.toJson<String>(uncertaintyLevel),
      'lastUpdated': serializer.toJson<String>(lastUpdated),
    };
  }

  ReferenceClassRow copyWith(
          {String? id,
          String? category,
          String? subcategory,
          String? baseRateDescription,
          List<dynamic>? stratificationVariables,
          List<dynamic>? sources,
          List<dynamic>? commonCriteria,
          String? commonRegretPatterns,
          String? uncertaintyLevel,
          String? lastUpdated}) =>
      ReferenceClassRow(
        id: id ?? this.id,
        category: category ?? this.category,
        subcategory: subcategory ?? this.subcategory,
        baseRateDescription: baseRateDescription ?? this.baseRateDescription,
        stratificationVariables:
            stratificationVariables ?? this.stratificationVariables,
        sources: sources ?? this.sources,
        commonCriteria: commonCriteria ?? this.commonCriteria,
        commonRegretPatterns: commonRegretPatterns ?? this.commonRegretPatterns,
        uncertaintyLevel: uncertaintyLevel ?? this.uncertaintyLevel,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
  ReferenceClassRow copyWithCompanion(ReferenceClassesCompanion data) {
    return ReferenceClassRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      subcategory:
          data.subcategory.present ? data.subcategory.value : this.subcategory,
      baseRateDescription: data.baseRateDescription.present
          ? data.baseRateDescription.value
          : this.baseRateDescription,
      stratificationVariables: data.stratificationVariables.present
          ? data.stratificationVariables.value
          : this.stratificationVariables,
      sources: data.sources.present ? data.sources.value : this.sources,
      commonCriteria: data.commonCriteria.present
          ? data.commonCriteria.value
          : this.commonCriteria,
      commonRegretPatterns: data.commonRegretPatterns.present
          ? data.commonRegretPatterns.value
          : this.commonRegretPatterns,
      uncertaintyLevel: data.uncertaintyLevel.present
          ? data.uncertaintyLevel.value
          : this.uncertaintyLevel,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceClassRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('baseRateDescription: $baseRateDescription, ')
          ..write('stratificationVariables: $stratificationVariables, ')
          ..write('sources: $sources, ')
          ..write('commonCriteria: $commonCriteria, ')
          ..write('commonRegretPatterns: $commonRegretPatterns, ')
          ..write('uncertaintyLevel: $uncertaintyLevel, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      category,
      subcategory,
      baseRateDescription,
      stratificationVariables,
      sources,
      commonCriteria,
      commonRegretPatterns,
      uncertaintyLevel,
      lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceClassRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.baseRateDescription == this.baseRateDescription &&
          other.stratificationVariables == this.stratificationVariables &&
          other.sources == this.sources &&
          other.commonCriteria == this.commonCriteria &&
          other.commonRegretPatterns == this.commonRegretPatterns &&
          other.uncertaintyLevel == this.uncertaintyLevel &&
          other.lastUpdated == this.lastUpdated);
}

class ReferenceClassesCompanion extends UpdateCompanion<ReferenceClassRow> {
  final Value<String> id;
  final Value<String> category;
  final Value<String> subcategory;
  final Value<String> baseRateDescription;
  final Value<List<dynamic>> stratificationVariables;
  final Value<List<dynamic>> sources;
  final Value<List<dynamic>> commonCriteria;
  final Value<String> commonRegretPatterns;
  final Value<String> uncertaintyLevel;
  final Value<String> lastUpdated;
  final Value<int> rowid;
  const ReferenceClassesCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.baseRateDescription = const Value.absent(),
    this.stratificationVariables = const Value.absent(),
    this.sources = const Value.absent(),
    this.commonCriteria = const Value.absent(),
    this.commonRegretPatterns = const Value.absent(),
    this.uncertaintyLevel = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReferenceClassesCompanion.insert({
    required String id,
    required String category,
    required String subcategory,
    required String baseRateDescription,
    required List<dynamic> stratificationVariables,
    required List<dynamic> sources,
    required List<dynamic> commonCriteria,
    required String commonRegretPatterns,
    required String uncertaintyLevel,
    required String lastUpdated,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        category = Value(category),
        subcategory = Value(subcategory),
        baseRateDescription = Value(baseRateDescription),
        stratificationVariables = Value(stratificationVariables),
        sources = Value(sources),
        commonCriteria = Value(commonCriteria),
        commonRegretPatterns = Value(commonRegretPatterns),
        uncertaintyLevel = Value(uncertaintyLevel),
        lastUpdated = Value(lastUpdated);
  static Insertable<ReferenceClassRow> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<String>? baseRateDescription,
    Expression<String>? stratificationVariables,
    Expression<String>? sources,
    Expression<String>? commonCriteria,
    Expression<String>? commonRegretPatterns,
    Expression<String>? uncertaintyLevel,
    Expression<String>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (baseRateDescription != null)
        'base_rate_description': baseRateDescription,
      if (stratificationVariables != null)
        'stratification_variables': stratificationVariables,
      if (sources != null) 'sources': sources,
      if (commonCriteria != null) 'common_criteria': commonCriteria,
      if (commonRegretPatterns != null)
        'common_regret_patterns': commonRegretPatterns,
      if (uncertaintyLevel != null) 'uncertainty_level': uncertaintyLevel,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReferenceClassesCompanion copyWith(
      {Value<String>? id,
      Value<String>? category,
      Value<String>? subcategory,
      Value<String>? baseRateDescription,
      Value<List<dynamic>>? stratificationVariables,
      Value<List<dynamic>>? sources,
      Value<List<dynamic>>? commonCriteria,
      Value<String>? commonRegretPatterns,
      Value<String>? uncertaintyLevel,
      Value<String>? lastUpdated,
      Value<int>? rowid}) {
    return ReferenceClassesCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      baseRateDescription: baseRateDescription ?? this.baseRateDescription,
      stratificationVariables:
          stratificationVariables ?? this.stratificationVariables,
      sources: sources ?? this.sources,
      commonCriteria: commonCriteria ?? this.commonCriteria,
      commonRegretPatterns: commonRegretPatterns ?? this.commonRegretPatterns,
      uncertaintyLevel: uncertaintyLevel ?? this.uncertaintyLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(subcategory.value);
    }
    if (baseRateDescription.present) {
      map['base_rate_description'] =
          Variable<String>(baseRateDescription.value);
    }
    if (stratificationVariables.present) {
      map['stratification_variables'] = Variable<String>($ReferenceClassesTable
          .$converterstratificationVariables
          .toSql(stratificationVariables.value));
    }
    if (sources.present) {
      map['sources'] = Variable<String>(
          $ReferenceClassesTable.$convertersources.toSql(sources.value));
    }
    if (commonCriteria.present) {
      map['common_criteria'] = Variable<String>($ReferenceClassesTable
          .$convertercommonCriteria
          .toSql(commonCriteria.value));
    }
    if (commonRegretPatterns.present) {
      map['common_regret_patterns'] =
          Variable<String>(commonRegretPatterns.value);
    }
    if (uncertaintyLevel.present) {
      map['uncertainty_level'] = Variable<String>(uncertaintyLevel.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<String>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceClassesCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('baseRateDescription: $baseRateDescription, ')
          ..write('stratificationVariables: $stratificationVariables, ')
          ..write('sources: $sources, ')
          ..write('commonCriteria: $commonCriteria, ')
          ..write('commonRegretPatterns: $commonRegretPatterns, ')
          ..write('uncertaintyLevel: $uncertaintyLevel, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _sesBracketMeta =
      const VerificationMeta('sesBracket');
  @override
  late final GeneratedColumn<String> sesBracket = GeneratedColumn<String>(
      'ses_bracket', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _religiosityMeta =
      const VerificationMeta('religiosity');
  @override
  late final GeneratedColumn<String> religiosity = GeneratedColumn<String>(
      'religiosity', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _relationshipStatusMeta =
      const VerificationMeta('relationshipStatus');
  @override
  late final GeneratedColumn<String> relationshipStatus =
      GeneratedColumn<String>('relationship_status', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sesBracket, religiosity, relationshipStatus];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfileRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ses_bracket')) {
      context.handle(
          _sesBracketMeta,
          sesBracket.isAcceptableOrUnknown(
              data['ses_bracket']!, _sesBracketMeta));
    }
    if (data.containsKey('religiosity')) {
      context.handle(
          _religiosityMeta,
          religiosity.isAcceptableOrUnknown(
              data['religiosity']!, _religiosityMeta));
    }
    if (data.containsKey('relationship_status')) {
      context.handle(
          _relationshipStatusMeta,
          relationshipStatus.isAcceptableOrUnknown(
              data['relationship_status']!, _relationshipStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sesBracket: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ses_bracket']),
      religiosity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}religiosity']),
      relationshipStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}relationship_status']),
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final int id;
  final String? sesBracket;
  final String? religiosity;
  final String? relationshipStatus;
  const UserProfileRow(
      {required this.id,
      this.sesBracket,
      this.religiosity,
      this.relationshipStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sesBracket != null) {
      map['ses_bracket'] = Variable<String>(sesBracket);
    }
    if (!nullToAbsent || religiosity != null) {
      map['religiosity'] = Variable<String>(religiosity);
    }
    if (!nullToAbsent || relationshipStatus != null) {
      map['relationship_status'] = Variable<String>(relationshipStatus);
    }
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      sesBracket: sesBracket == null && nullToAbsent
          ? const Value.absent()
          : Value(sesBracket),
      religiosity: religiosity == null && nullToAbsent
          ? const Value.absent()
          : Value(religiosity),
      relationshipStatus: relationshipStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(relationshipStatus),
    );
  }

  factory UserProfileRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<int>(json['id']),
      sesBracket: serializer.fromJson<String?>(json['sesBracket']),
      religiosity: serializer.fromJson<String?>(json['religiosity']),
      relationshipStatus:
          serializer.fromJson<String?>(json['relationshipStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sesBracket': serializer.toJson<String?>(sesBracket),
      'religiosity': serializer.toJson<String?>(religiosity),
      'relationshipStatus': serializer.toJson<String?>(relationshipStatus),
    };
  }

  UserProfileRow copyWith(
          {int? id,
          Value<String?> sesBracket = const Value.absent(),
          Value<String?> religiosity = const Value.absent(),
          Value<String?> relationshipStatus = const Value.absent()}) =>
      UserProfileRow(
        id: id ?? this.id,
        sesBracket: sesBracket.present ? sesBracket.value : this.sesBracket,
        religiosity: religiosity.present ? religiosity.value : this.religiosity,
        relationshipStatus: relationshipStatus.present
            ? relationshipStatus.value
            : this.relationshipStatus,
      );
  UserProfileRow copyWithCompanion(UserProfileCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      sesBracket:
          data.sesBracket.present ? data.sesBracket.value : this.sesBracket,
      religiosity:
          data.religiosity.present ? data.religiosity.value : this.religiosity,
      relationshipStatus: data.relationshipStatus.present
          ? data.relationshipStatus.value
          : this.relationshipStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('sesBracket: $sesBracket, ')
          ..write('religiosity: $religiosity, ')
          ..write('relationshipStatus: $relationshipStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sesBracket, religiosity, relationshipStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.sesBracket == this.sesBracket &&
          other.religiosity == this.religiosity &&
          other.relationshipStatus == this.relationshipStatus);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<int> id;
  final Value<String?> sesBracket;
  final Value<String?> religiosity;
  final Value<String?> relationshipStatus;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.sesBracket = const Value.absent(),
    this.religiosity = const Value.absent(),
    this.relationshipStatus = const Value.absent(),
  });
  UserProfileCompanion.insert({
    this.id = const Value.absent(),
    this.sesBracket = const Value.absent(),
    this.religiosity = const Value.absent(),
    this.relationshipStatus = const Value.absent(),
  });
  static Insertable<UserProfileRow> custom({
    Expression<int>? id,
    Expression<String>? sesBracket,
    Expression<String>? religiosity,
    Expression<String>? relationshipStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sesBracket != null) 'ses_bracket': sesBracket,
      if (religiosity != null) 'religiosity': religiosity,
      if (relationshipStatus != null) 'relationship_status': relationshipStatus,
    });
  }

  UserProfileCompanion copyWith(
      {Value<int>? id,
      Value<String?>? sesBracket,
      Value<String?>? religiosity,
      Value<String?>? relationshipStatus}) {
    return UserProfileCompanion(
      id: id ?? this.id,
      sesBracket: sesBracket ?? this.sesBracket,
      religiosity: religiosity ?? this.religiosity,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sesBracket.present) {
      map['ses_bracket'] = Variable<String>(sesBracket.value);
    }
    if (religiosity.present) {
      map['religiosity'] = Variable<String>(religiosity.value);
    }
    if (relationshipStatus.present) {
      map['relationship_status'] = Variable<String>(relationshipStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('sesBracket: $sesBracket, ')
          ..write('religiosity: $religiosity, ')
          ..write('relationshipStatus: $relationshipStatus')
          ..write(')'))
        .toString();
  }
}

class $CommunityForecastsTable extends CommunityForecasts
    with TableInfo<$CommunityForecastsTable, CommunityForecastRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommunityForecastsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'community_forecasts';
  @override
  VerificationContext validateIntegrity(
      Insertable<CommunityForecastRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommunityForecastRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommunityForecastRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
    );
  }

  @override
  $CommunityForecastsTable createAlias(String alias) {
    return $CommunityForecastsTable(attachedDatabase, alias);
  }
}

class CommunityForecastRow extends DataClass
    implements Insertable<CommunityForecastRow> {
  final String id;
  const CommunityForecastRow({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    return map;
  }

  CommunityForecastsCompanion toCompanion(bool nullToAbsent) {
    return CommunityForecastsCompanion(
      id: Value(id),
    );
  }

  factory CommunityForecastRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommunityForecastRow(
      id: serializer.fromJson<String>(json['id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
    };
  }

  CommunityForecastRow copyWith({String? id}) => CommunityForecastRow(
        id: id ?? this.id,
      );
  CommunityForecastRow copyWithCompanion(CommunityForecastsCompanion data) {
    return CommunityForecastRow(
      id: data.id.present ? data.id.value : this.id,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommunityForecastRow(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommunityForecastRow && other.id == this.id);
}

class CommunityForecastsCompanion
    extends UpdateCompanion<CommunityForecastRow> {
  final Value<String> id;
  final Value<int> rowid;
  const CommunityForecastsCompanion({
    this.id = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommunityForecastsCompanion.insert({
    required String id,
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<CommunityForecastRow> custom({
    Expression<String>? id,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommunityForecastsCompanion copyWith({Value<String>? id, Value<int>? rowid}) {
    return CommunityForecastsCompanion(
      id: id ?? this.id,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommunityForecastsCompanion(')
          ..write('id: $id, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelPredictionsTable extends ModelPredictions
    with TableInfo<$ModelPredictionsTable, ModelPredictionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelPredictionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
      'case_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cases (id)'));
  static const VerificationMeta _modelVersionMeta =
      const VerificationMeta('modelVersion');
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
      'model_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _predictedAtMeta =
      const VerificationMeta('predictedAt');
  @override
  late final GeneratedColumn<DateTime> predictedAt = GeneratedColumn<DateTime>(
      'predicted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
      payload = GeneratedColumn<String>('payload', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Map<String, dynamic>>(
              $ModelPredictionsTable.$converterpayload);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
      'score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _scoredAtMeta =
      const VerificationMeta('scoredAt');
  @override
  late final GeneratedColumn<DateTime> scoredAt = GeneratedColumn<DateTime>(
      'scored_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, caseId, modelVersion, kind, predictedAt, payload, score, scoredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_predictions';
  @override
  VerificationContext validateIntegrity(Insertable<ModelPredictionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(_caseIdMeta,
          caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta));
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
          _modelVersionMeta,
          modelVersion.isAcceptableOrUnknown(
              data['model_version']!, _modelVersionMeta));
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('predicted_at')) {
      context.handle(
          _predictedAtMeta,
          predictedAt.isAcceptableOrUnknown(
              data['predicted_at']!, _predictedAtMeta));
    } else if (isInserting) {
      context.missing(_predictedAtMeta);
    }
    context.handle(_payloadMeta, const VerificationResult.success());
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('scored_at')) {
      context.handle(_scoredAtMeta,
          scoredAt.isAcceptableOrUnknown(data['scored_at']!, _scoredAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModelPredictionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelPredictionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      caseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}case_id'])!,
      modelVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_version'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      predictedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}predicted_at'])!,
      payload: $ModelPredictionsTable.$converterpayload.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!),
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}score']),
      scoredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}scored_at']),
    );
  }

  @override
  $ModelPredictionsTable createAlias(String alias) {
    return $ModelPredictionsTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, dynamic>, String> $converterpayload =
      const JsonMapConverter();
}

class ModelPredictionRow extends DataClass
    implements Insertable<ModelPredictionRow> {
  final String id;
  final String caseId;
  final String modelVersion;
  final String kind;
  final DateTime predictedAt;
  final Map<String, dynamic> payload;
  final double? score;
  final DateTime? scoredAt;
  const ModelPredictionRow(
      {required this.id,
      required this.caseId,
      required this.modelVersion,
      required this.kind,
      required this.predictedAt,
      required this.payload,
      this.score,
      this.scoredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    map['model_version'] = Variable<String>(modelVersion);
    map['kind'] = Variable<String>(kind);
    map['predicted_at'] = Variable<DateTime>(predictedAt);
    {
      map['payload'] = Variable<String>(
          $ModelPredictionsTable.$converterpayload.toSql(payload));
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    if (!nullToAbsent || scoredAt != null) {
      map['scored_at'] = Variable<DateTime>(scoredAt);
    }
    return map;
  }

  ModelPredictionsCompanion toCompanion(bool nullToAbsent) {
    return ModelPredictionsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      modelVersion: Value(modelVersion),
      kind: Value(kind),
      predictedAt: Value(predictedAt),
      payload: Value(payload),
      score:
          score == null && nullToAbsent ? const Value.absent() : Value(score),
      scoredAt: scoredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(scoredAt),
    );
  }

  factory ModelPredictionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelPredictionRow(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      kind: serializer.fromJson<String>(json['kind']),
      predictedAt: serializer.fromJson<DateTime>(json['predictedAt']),
      payload: serializer.fromJson<Map<String, dynamic>>(json['payload']),
      score: serializer.fromJson<double?>(json['score']),
      scoredAt: serializer.fromJson<DateTime?>(json['scoredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'kind': serializer.toJson<String>(kind),
      'predictedAt': serializer.toJson<DateTime>(predictedAt),
      'payload': serializer.toJson<Map<String, dynamic>>(payload),
      'score': serializer.toJson<double?>(score),
      'scoredAt': serializer.toJson<DateTime?>(scoredAt),
    };
  }

  ModelPredictionRow copyWith(
          {String? id,
          String? caseId,
          String? modelVersion,
          String? kind,
          DateTime? predictedAt,
          Map<String, dynamic>? payload,
          Value<double?> score = const Value.absent(),
          Value<DateTime?> scoredAt = const Value.absent()}) =>
      ModelPredictionRow(
        id: id ?? this.id,
        caseId: caseId ?? this.caseId,
        modelVersion: modelVersion ?? this.modelVersion,
        kind: kind ?? this.kind,
        predictedAt: predictedAt ?? this.predictedAt,
        payload: payload ?? this.payload,
        score: score.present ? score.value : this.score,
        scoredAt: scoredAt.present ? scoredAt.value : this.scoredAt,
      );
  ModelPredictionRow copyWithCompanion(ModelPredictionsCompanion data) {
    return ModelPredictionRow(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      kind: data.kind.present ? data.kind.value : this.kind,
      predictedAt:
          data.predictedAt.present ? data.predictedAt.value : this.predictedAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      score: data.score.present ? data.score.value : this.score,
      scoredAt: data.scoredAt.present ? data.scoredAt.value : this.scoredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelPredictionRow(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('kind: $kind, ')
          ..write('predictedAt: $predictedAt, ')
          ..write('payload: $payload, ')
          ..write('score: $score, ')
          ..write('scoredAt: $scoredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, caseId, modelVersion, kind, predictedAt, payload, score, scoredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelPredictionRow &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.modelVersion == this.modelVersion &&
          other.kind == this.kind &&
          other.predictedAt == this.predictedAt &&
          other.payload == this.payload &&
          other.score == this.score &&
          other.scoredAt == this.scoredAt);
}

class ModelPredictionsCompanion extends UpdateCompanion<ModelPredictionRow> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<String> modelVersion;
  final Value<String> kind;
  final Value<DateTime> predictedAt;
  final Value<Map<String, dynamic>> payload;
  final Value<double?> score;
  final Value<DateTime?> scoredAt;
  final Value<int> rowid;
  const ModelPredictionsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.kind = const Value.absent(),
    this.predictedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.score = const Value.absent(),
    this.scoredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelPredictionsCompanion.insert({
    required String id,
    required String caseId,
    required String modelVersion,
    required String kind,
    required DateTime predictedAt,
    required Map<String, dynamic> payload,
    this.score = const Value.absent(),
    this.scoredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        caseId = Value(caseId),
        modelVersion = Value(modelVersion),
        kind = Value(kind),
        predictedAt = Value(predictedAt),
        payload = Value(payload);
  static Insertable<ModelPredictionRow> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<String>? modelVersion,
    Expression<String>? kind,
    Expression<DateTime>? predictedAt,
    Expression<String>? payload,
    Expression<double>? score,
    Expression<DateTime>? scoredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (modelVersion != null) 'model_version': modelVersion,
      if (kind != null) 'kind': kind,
      if (predictedAt != null) 'predicted_at': predictedAt,
      if (payload != null) 'payload': payload,
      if (score != null) 'score': score,
      if (scoredAt != null) 'scored_at': scoredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelPredictionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? caseId,
      Value<String>? modelVersion,
      Value<String>? kind,
      Value<DateTime>? predictedAt,
      Value<Map<String, dynamic>>? payload,
      Value<double?>? score,
      Value<DateTime?>? scoredAt,
      Value<int>? rowid}) {
    return ModelPredictionsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      modelVersion: modelVersion ?? this.modelVersion,
      kind: kind ?? this.kind,
      predictedAt: predictedAt ?? this.predictedAt,
      payload: payload ?? this.payload,
      score: score ?? this.score,
      scoredAt: scoredAt ?? this.scoredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (predictedAt.present) {
      map['predicted_at'] = Variable<DateTime>(predictedAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(
          $ModelPredictionsTable.$converterpayload.toSql(payload.value));
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (scoredAt.present) {
      map['scored_at'] = Variable<DateTime>(scoredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelPredictionsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('kind: $kind, ')
          ..write('predictedAt: $predictedAt, ')
          ..write('payload: $payload, ')
          ..write('score: $score, ')
          ..write('scoredAt: $scoredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PartiesTable extends Parties with TableInfo<$PartiesTable, PartyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _votingMethodMeta =
      const VerificationMeta('votingMethod');
  @override
  late final GeneratedColumn<String> votingMethod = GeneratedColumn<String>(
      'voting_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _optionsMeta =
      const VerificationMeta('options');
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String> options =
      GeneratedColumn<String>('options', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<dynamic>>($PartiesTable.$converteroptions);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _closedMeta = const VerificationMeta('closed');
  @override
  late final GeneratedColumn<bool> closed = GeneratedColumn<bool>(
      'closed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("closed" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, votingMethod, options, createdAt, closed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parties';
  @override
  VerificationContext validateIntegrity(Insertable<PartyRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('voting_method')) {
      context.handle(
          _votingMethodMeta,
          votingMethod.isAcceptableOrUnknown(
              data['voting_method']!, _votingMethodMeta));
    } else if (isInserting) {
      context.missing(_votingMethodMeta);
    }
    context.handle(_optionsMeta, const VerificationResult.success());
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('closed')) {
      context.handle(_closedMeta,
          closed.isAcceptableOrUnknown(data['closed']!, _closedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PartyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PartyRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      votingMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voting_method'])!,
      options: $PartiesTable.$converteroptions.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}options'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      closed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}closed'])!,
    );
  }

  @override
  $PartiesTable createAlias(String alias) {
    return $PartiesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<dynamic>, String> $converteroptions =
      const JsonListConverter();
}

class PartyRow extends DataClass implements Insertable<PartyRow> {
  final String id;
  final String title;

  /// 'approval' | 'ranked' — the [VotingMethod] name.
  final String votingMethod;

  /// JSON list of `{id, label}` option maps.
  final List<dynamic> options;
  final DateTime createdAt;
  final bool closed;
  const PartyRow(
      {required this.id,
      required this.title,
      required this.votingMethod,
      required this.options,
      required this.createdAt,
      required this.closed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['voting_method'] = Variable<String>(votingMethod);
    {
      map['options'] =
          Variable<String>($PartiesTable.$converteroptions.toSql(options));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['closed'] = Variable<bool>(closed);
    return map;
  }

  PartiesCompanion toCompanion(bool nullToAbsent) {
    return PartiesCompanion(
      id: Value(id),
      title: Value(title),
      votingMethod: Value(votingMethod),
      options: Value(options),
      createdAt: Value(createdAt),
      closed: Value(closed),
    );
  }

  factory PartyRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PartyRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      votingMethod: serializer.fromJson<String>(json['votingMethod']),
      options: serializer.fromJson<List<dynamic>>(json['options']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      closed: serializer.fromJson<bool>(json['closed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'votingMethod': serializer.toJson<String>(votingMethod),
      'options': serializer.toJson<List<dynamic>>(options),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'closed': serializer.toJson<bool>(closed),
    };
  }

  PartyRow copyWith(
          {String? id,
          String? title,
          String? votingMethod,
          List<dynamic>? options,
          DateTime? createdAt,
          bool? closed}) =>
      PartyRow(
        id: id ?? this.id,
        title: title ?? this.title,
        votingMethod: votingMethod ?? this.votingMethod,
        options: options ?? this.options,
        createdAt: createdAt ?? this.createdAt,
        closed: closed ?? this.closed,
      );
  PartyRow copyWithCompanion(PartiesCompanion data) {
    return PartyRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      votingMethod: data.votingMethod.present
          ? data.votingMethod.value
          : this.votingMethod,
      options: data.options.present ? data.options.value : this.options,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      closed: data.closed.present ? data.closed.value : this.closed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PartyRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('votingMethod: $votingMethod, ')
          ..write('options: $options, ')
          ..write('createdAt: $createdAt, ')
          ..write('closed: $closed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, votingMethod, options, createdAt, closed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartyRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.votingMethod == this.votingMethod &&
          other.options == this.options &&
          other.createdAt == this.createdAt &&
          other.closed == this.closed);
}

class PartiesCompanion extends UpdateCompanion<PartyRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> votingMethod;
  final Value<List<dynamic>> options;
  final Value<DateTime> createdAt;
  final Value<bool> closed;
  final Value<int> rowid;
  const PartiesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.votingMethod = const Value.absent(),
    this.options = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.closed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PartiesCompanion.insert({
    required String id,
    required String title,
    required String votingMethod,
    required List<dynamic> options,
    required DateTime createdAt,
    this.closed = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        votingMethod = Value(votingMethod),
        options = Value(options),
        createdAt = Value(createdAt);
  static Insertable<PartyRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? votingMethod,
    Expression<String>? options,
    Expression<DateTime>? createdAt,
    Expression<bool>? closed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (votingMethod != null) 'voting_method': votingMethod,
      if (options != null) 'options': options,
      if (createdAt != null) 'created_at': createdAt,
      if (closed != null) 'closed': closed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PartiesCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? votingMethod,
      Value<List<dynamic>>? options,
      Value<DateTime>? createdAt,
      Value<bool>? closed,
      Value<int>? rowid}) {
    return PartiesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      votingMethod: votingMethod ?? this.votingMethod,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      closed: closed ?? this.closed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (votingMethod.present) {
      map['voting_method'] = Variable<String>(votingMethod.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(
          $PartiesTable.$converteroptions.toSql(options.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (closed.present) {
      map['closed'] = Variable<bool>(closed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartiesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('votingMethod: $votingMethod, ')
          ..write('options: $options, ')
          ..write('createdAt: $createdAt, ')
          ..write('closed: $closed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PartyBallotsTable extends PartyBallots
    with TableInfo<$PartyBallotsTable, PartyBallotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartyBallotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _partyIdMeta =
      const VerificationMeta('partyId');
  @override
  late final GeneratedColumn<String> partyId = GeneratedColumn<String>(
      'party_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES parties (id)'));
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _approvalsMeta =
      const VerificationMeta('approvals');
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String> approvals =
      GeneratedColumn<String>('approvals', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<dynamic>>($PartyBallotsTable.$converterapprovals);
  static const VerificationMeta _rankingMeta =
      const VerificationMeta('ranking');
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String> ranking =
      GeneratedColumn<String>('ranking', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<dynamic>>($PartyBallotsTable.$converterranking);
  static const VerificationMeta _submittedAtMeta =
      const VerificationMeta('submittedAt');
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
      'submitted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, partyId, method, approvals, ranking, submittedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'party_ballots';
  @override
  VerificationContext validateIntegrity(Insertable<PartyBallotRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('party_id')) {
      context.handle(_partyIdMeta,
          partyId.isAcceptableOrUnknown(data['party_id']!, _partyIdMeta));
    } else if (isInserting) {
      context.missing(_partyIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    context.handle(_approvalsMeta, const VerificationResult.success());
    context.handle(_rankingMeta, const VerificationResult.success());
    if (data.containsKey('submitted_at')) {
      context.handle(
          _submittedAtMeta,
          submittedAt.isAcceptableOrUnknown(
              data['submitted_at']!, _submittedAtMeta));
    } else if (isInserting) {
      context.missing(_submittedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PartyBallotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PartyBallotRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      partyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}party_id'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      approvals: $PartyBallotsTable.$converterapprovals.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}approvals'])!),
      ranking: $PartyBallotsTable.$converterranking.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ranking'])!),
      submittedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}submitted_at'])!,
    );
  }

  @override
  $PartyBallotsTable createAlias(String alias) {
    return $PartyBallotsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<dynamic>, String> $converterapprovals =
      const JsonListConverter();
  static TypeConverter<List<dynamic>, String> $converterranking =
      const JsonListConverter();
}

class PartyBallotRow extends DataClass implements Insertable<PartyBallotRow> {
  final String id;
  final String partyId;

  /// 'approval' | 'ranked'.
  final String method;

  /// JSON list of approved option ids (approval ballots; empty otherwise).
  final List<dynamic> approvals;

  /// JSON list of option ids, most→least preferred (ranked ballots; empty
  /// otherwise).
  final List<dynamic> ranking;
  final DateTime submittedAt;
  const PartyBallotRow(
      {required this.id,
      required this.partyId,
      required this.method,
      required this.approvals,
      required this.ranking,
      required this.submittedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['party_id'] = Variable<String>(partyId);
    map['method'] = Variable<String>(method);
    {
      map['approvals'] = Variable<String>(
          $PartyBallotsTable.$converterapprovals.toSql(approvals));
    }
    {
      map['ranking'] =
          Variable<String>($PartyBallotsTable.$converterranking.toSql(ranking));
    }
    map['submitted_at'] = Variable<DateTime>(submittedAt);
    return map;
  }

  PartyBallotsCompanion toCompanion(bool nullToAbsent) {
    return PartyBallotsCompanion(
      id: Value(id),
      partyId: Value(partyId),
      method: Value(method),
      approvals: Value(approvals),
      ranking: Value(ranking),
      submittedAt: Value(submittedAt),
    );
  }

  factory PartyBallotRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PartyBallotRow(
      id: serializer.fromJson<String>(json['id']),
      partyId: serializer.fromJson<String>(json['partyId']),
      method: serializer.fromJson<String>(json['method']),
      approvals: serializer.fromJson<List<dynamic>>(json['approvals']),
      ranking: serializer.fromJson<List<dynamic>>(json['ranking']),
      submittedAt: serializer.fromJson<DateTime>(json['submittedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'partyId': serializer.toJson<String>(partyId),
      'method': serializer.toJson<String>(method),
      'approvals': serializer.toJson<List<dynamic>>(approvals),
      'ranking': serializer.toJson<List<dynamic>>(ranking),
      'submittedAt': serializer.toJson<DateTime>(submittedAt),
    };
  }

  PartyBallotRow copyWith(
          {String? id,
          String? partyId,
          String? method,
          List<dynamic>? approvals,
          List<dynamic>? ranking,
          DateTime? submittedAt}) =>
      PartyBallotRow(
        id: id ?? this.id,
        partyId: partyId ?? this.partyId,
        method: method ?? this.method,
        approvals: approvals ?? this.approvals,
        ranking: ranking ?? this.ranking,
        submittedAt: submittedAt ?? this.submittedAt,
      );
  PartyBallotRow copyWithCompanion(PartyBallotsCompanion data) {
    return PartyBallotRow(
      id: data.id.present ? data.id.value : this.id,
      partyId: data.partyId.present ? data.partyId.value : this.partyId,
      method: data.method.present ? data.method.value : this.method,
      approvals: data.approvals.present ? data.approvals.value : this.approvals,
      ranking: data.ranking.present ? data.ranking.value : this.ranking,
      submittedAt:
          data.submittedAt.present ? data.submittedAt.value : this.submittedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PartyBallotRow(')
          ..write('id: $id, ')
          ..write('partyId: $partyId, ')
          ..write('method: $method, ')
          ..write('approvals: $approvals, ')
          ..write('ranking: $ranking, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, partyId, method, approvals, ranking, submittedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartyBallotRow &&
          other.id == this.id &&
          other.partyId == this.partyId &&
          other.method == this.method &&
          other.approvals == this.approvals &&
          other.ranking == this.ranking &&
          other.submittedAt == this.submittedAt);
}

class PartyBallotsCompanion extends UpdateCompanion<PartyBallotRow> {
  final Value<String> id;
  final Value<String> partyId;
  final Value<String> method;
  final Value<List<dynamic>> approvals;
  final Value<List<dynamic>> ranking;
  final Value<DateTime> submittedAt;
  final Value<int> rowid;
  const PartyBallotsCompanion({
    this.id = const Value.absent(),
    this.partyId = const Value.absent(),
    this.method = const Value.absent(),
    this.approvals = const Value.absent(),
    this.ranking = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PartyBallotsCompanion.insert({
    required String id,
    required String partyId,
    required String method,
    required List<dynamic> approvals,
    required List<dynamic> ranking,
    required DateTime submittedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        partyId = Value(partyId),
        method = Value(method),
        approvals = Value(approvals),
        ranking = Value(ranking),
        submittedAt = Value(submittedAt);
  static Insertable<PartyBallotRow> custom({
    Expression<String>? id,
    Expression<String>? partyId,
    Expression<String>? method,
    Expression<String>? approvals,
    Expression<String>? ranking,
    Expression<DateTime>? submittedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partyId != null) 'party_id': partyId,
      if (method != null) 'method': method,
      if (approvals != null) 'approvals': approvals,
      if (ranking != null) 'ranking': ranking,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PartyBallotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? partyId,
      Value<String>? method,
      Value<List<dynamic>>? approvals,
      Value<List<dynamic>>? ranking,
      Value<DateTime>? submittedAt,
      Value<int>? rowid}) {
    return PartyBallotsCompanion(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      method: method ?? this.method,
      approvals: approvals ?? this.approvals,
      ranking: ranking ?? this.ranking,
      submittedAt: submittedAt ?? this.submittedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (partyId.present) {
      map['party_id'] = Variable<String>(partyId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (approvals.present) {
      map['approvals'] = Variable<String>(
          $PartyBallotsTable.$converterapprovals.toSql(approvals.value));
    }
    if (ranking.present) {
      map['ranking'] = Variable<String>(
          $PartyBallotsTable.$converterranking.toSql(ranking.value));
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartyBallotsCompanion(')
          ..write('id: $id, ')
          ..write('partyId: $partyId, ')
          ..write('method: $method, ')
          ..write('approvals: $approvals, ')
          ..write('ranking: $ranking, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CasesTable cases = $CasesTable(this);
  late final $PollsTable polls = $PollsTable(this);
  late final $ResolutionsTable resolutions = $ResolutionsTable(this);
  late final $OutsideViewsTable outsideViews = $OutsideViewsTable(this);
  late final $ReferenceClassesTable referenceClasses =
      $ReferenceClassesTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $CommunityForecastsTable communityForecasts =
      $CommunityForecastsTable(this);
  late final $ModelPredictionsTable modelPredictions =
      $ModelPredictionsTable(this);
  late final $PartiesTable parties = $PartiesTable(this);
  late final $PartyBallotsTable partyBallots = $PartyBallotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cases,
        polls,
        resolutions,
        outsideViews,
        referenceClasses,
        userProfile,
        communityForecasts,
        modelPredictions,
        parties,
        partyBallots
      ];
}

typedef $$CasesTableCreateCompanionBuilder = CasesCompanion Function({
  required String id,
  required DateTime createdAt,
  Value<DateTime?> deadline,
  required String status,
  required String question,
  required String optionA,
  required String optionB,
  required List<dynamic> statedCriteria,
  required String stakes,
  required String regretHorizon,
  Value<String?> category,
  Value<bool> communityVisible,
  Value<int> rowid,
});
typedef $$CasesTableUpdateCompanionBuilder = CasesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime?> deadline,
  Value<String> status,
  Value<String> question,
  Value<String> optionA,
  Value<String> optionB,
  Value<List<dynamic>> statedCriteria,
  Value<String> stakes,
  Value<String> regretHorizon,
  Value<String?> category,
  Value<bool> communityVisible,
  Value<int> rowid,
});

final class $$CasesTableReferences
    extends BaseReferences<_$AppDatabase, $CasesTable, CaseRow> {
  $$CasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PollsTable, List<PollRow>> _pollsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.polls,
          aliasName: $_aliasNameGenerator(db.cases.id, db.polls.caseId));

  $$PollsTableProcessedTableManager get pollsRefs {
    final manager = $$PollsTableTableManager($_db, $_db.polls)
        .filter((f) => f.caseId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_pollsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ResolutionsTable, List<ResolutionRow>>
      _resolutionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.resolutions,
          aliasName: $_aliasNameGenerator(db.cases.id, db.resolutions.caseId));

  $$ResolutionsTableProcessedTableManager get resolutionsRefs {
    final manager = $$ResolutionsTableTableManager($_db, $_db.resolutions)
        .filter((f) => f.caseId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_resolutionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$OutsideViewsTable, List<OutsideViewRow>>
      _outsideViewsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.outsideViews,
          aliasName: $_aliasNameGenerator(db.cases.id, db.outsideViews.caseId));

  $$OutsideViewsTableProcessedTableManager get outsideViewsRefs {
    final manager = $$OutsideViewsTableTableManager($_db, $_db.outsideViews)
        .filter((f) => f.caseId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_outsideViewsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ModelPredictionsTable, List<ModelPredictionRow>>
      _modelPredictionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.modelPredictions,
              aliasName: $_aliasNameGenerator(
                  db.cases.id, db.modelPredictions.caseId));

  $$ModelPredictionsTableProcessedTableManager get modelPredictionsRefs {
    final manager =
        $$ModelPredictionsTableTableManager($_db, $_db.modelPredictions)
            .filter((f) => f.caseId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_modelPredictionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CasesTableFilterComposer extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optionA => $composableBuilder(
      column: $table.optionA, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optionB => $composableBuilder(
      column: $table.optionB, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
      get statedCriteria => $composableBuilder(
          column: $table.statedCriteria,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get stakes => $composableBuilder(
      column: $table.stakes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regretHorizon => $composableBuilder(
      column: $table.regretHorizon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get communityVisible => $composableBuilder(
      column: $table.communityVisible,
      builder: (column) => ColumnFilters(column));

  Expression<bool> pollsRefs(
      Expression<bool> Function($$PollsTableFilterComposer f) f) {
    final $$PollsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.polls,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PollsTableFilterComposer(
              $db: $db,
              $table: $db.polls,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> resolutionsRefs(
      Expression<bool> Function($$ResolutionsTableFilterComposer f) f) {
    final $$ResolutionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.resolutions,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ResolutionsTableFilterComposer(
              $db: $db,
              $table: $db.resolutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> outsideViewsRefs(
      Expression<bool> Function($$OutsideViewsTableFilterComposer f) f) {
    final $$OutsideViewsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.outsideViews,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OutsideViewsTableFilterComposer(
              $db: $db,
              $table: $db.outsideViews,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> modelPredictionsRefs(
      Expression<bool> Function($$ModelPredictionsTableFilterComposer f) f) {
    final $$ModelPredictionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.modelPredictions,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ModelPredictionsTableFilterComposer(
              $db: $db,
              $table: $db.modelPredictions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CasesTableOrderingComposer
    extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optionA => $composableBuilder(
      column: $table.optionA, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optionB => $composableBuilder(
      column: $table.optionB, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statedCriteria => $composableBuilder(
      column: $table.statedCriteria,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stakes => $composableBuilder(
      column: $table.stakes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regretHorizon => $composableBuilder(
      column: $table.regretHorizon,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get communityVisible => $composableBuilder(
      column: $table.communityVisible,
      builder: (column) => ColumnOrderings(column));
}

class $$CasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get optionA =>
      $composableBuilder(column: $table.optionA, builder: (column) => column);

  GeneratedColumn<String> get optionB =>
      $composableBuilder(column: $table.optionB, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get statedCriteria =>
      $composableBuilder(
          column: $table.statedCriteria, builder: (column) => column);

  GeneratedColumn<String> get stakes =>
      $composableBuilder(column: $table.stakes, builder: (column) => column);

  GeneratedColumn<String> get regretHorizon => $composableBuilder(
      column: $table.regretHorizon, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get communityVisible => $composableBuilder(
      column: $table.communityVisible, builder: (column) => column);

  Expression<T> pollsRefs<T extends Object>(
      Expression<T> Function($$PollsTableAnnotationComposer a) f) {
    final $$PollsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.polls,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PollsTableAnnotationComposer(
              $db: $db,
              $table: $db.polls,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> resolutionsRefs<T extends Object>(
      Expression<T> Function($$ResolutionsTableAnnotationComposer a) f) {
    final $$ResolutionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.resolutions,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ResolutionsTableAnnotationComposer(
              $db: $db,
              $table: $db.resolutions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> outsideViewsRefs<T extends Object>(
      Expression<T> Function($$OutsideViewsTableAnnotationComposer a) f) {
    final $$OutsideViewsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.outsideViews,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OutsideViewsTableAnnotationComposer(
              $db: $db,
              $table: $db.outsideViews,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> modelPredictionsRefs<T extends Object>(
      Expression<T> Function($$ModelPredictionsTableAnnotationComposer a) f) {
    final $$ModelPredictionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.modelPredictions,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ModelPredictionsTableAnnotationComposer(
              $db: $db,
              $table: $db.modelPredictions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CasesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CasesTable,
    CaseRow,
    $$CasesTableFilterComposer,
    $$CasesTableOrderingComposer,
    $$CasesTableAnnotationComposer,
    $$CasesTableCreateCompanionBuilder,
    $$CasesTableUpdateCompanionBuilder,
    (CaseRow, $$CasesTableReferences),
    CaseRow,
    PrefetchHooks Function(
        {bool pollsRefs,
        bool resolutionsRefs,
        bool outsideViewsRefs,
        bool modelPredictionsRefs})> {
  $$CasesTableTableManager(_$AppDatabase db, $CasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> deadline = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> question = const Value.absent(),
            Value<String> optionA = const Value.absent(),
            Value<String> optionB = const Value.absent(),
            Value<List<dynamic>> statedCriteria = const Value.absent(),
            Value<String> stakes = const Value.absent(),
            Value<String> regretHorizon = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<bool> communityVisible = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CasesCompanion(
            id: id,
            createdAt: createdAt,
            deadline: deadline,
            status: status,
            question: question,
            optionA: optionA,
            optionB: optionB,
            statedCriteria: statedCriteria,
            stakes: stakes,
            regretHorizon: regretHorizon,
            category: category,
            communityVisible: communityVisible,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            Value<DateTime?> deadline = const Value.absent(),
            required String status,
            required String question,
            required String optionA,
            required String optionB,
            required List<dynamic> statedCriteria,
            required String stakes,
            required String regretHorizon,
            Value<String?> category = const Value.absent(),
            Value<bool> communityVisible = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CasesCompanion.insert(
            id: id,
            createdAt: createdAt,
            deadline: deadline,
            status: status,
            question: question,
            optionA: optionA,
            optionB: optionB,
            statedCriteria: statedCriteria,
            stakes: stakes,
            regretHorizon: regretHorizon,
            category: category,
            communityVisible: communityVisible,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CasesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {pollsRefs = false,
              resolutionsRefs = false,
              outsideViewsRefs = false,
              modelPredictionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (pollsRefs) db.polls,
                if (resolutionsRefs) db.resolutions,
                if (outsideViewsRefs) db.outsideViews,
                if (modelPredictionsRefs) db.modelPredictions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pollsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CasesTableReferences._pollsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CasesTableReferences(db, table, p0).pollsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.caseId == item.id),
                        typedResults: items),
                  if (resolutionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CasesTableReferences._resolutionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CasesTableReferences(db, table, p0)
                                .resolutionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.caseId == item.id),
                        typedResults: items),
                  if (outsideViewsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CasesTableReferences._outsideViewsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CasesTableReferences(db, table, p0)
                                .outsideViewsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.caseId == item.id),
                        typedResults: items),
                  if (modelPredictionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CasesTableReferences
                            ._modelPredictionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CasesTableReferences(db, table, p0)
                                .modelPredictionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.caseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CasesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CasesTable,
    CaseRow,
    $$CasesTableFilterComposer,
    $$CasesTableOrderingComposer,
    $$CasesTableAnnotationComposer,
    $$CasesTableCreateCompanionBuilder,
    $$CasesTableUpdateCompanionBuilder,
    (CaseRow, $$CasesTableReferences),
    CaseRow,
    PrefetchHooks Function(
        {bool pollsRefs,
        bool resolutionsRefs,
        bool outsideViewsRefs,
        bool modelPredictionsRefs})>;
typedef $$PollsTableCreateCompanionBuilder = PollsCompanion Function({
  required String id,
  required String caseId,
  required DateTime createdAt,
  required int pollNumber,
  required int lean,
  Value<String?> rationale,
  required String confidence,
  Value<bool> revealed,
  Value<int> rowid,
});
typedef $$PollsTableUpdateCompanionBuilder = PollsCompanion Function({
  Value<String> id,
  Value<String> caseId,
  Value<DateTime> createdAt,
  Value<int> pollNumber,
  Value<int> lean,
  Value<String?> rationale,
  Value<String> confidence,
  Value<bool> revealed,
  Value<int> rowid,
});

final class $$PollsTableReferences
    extends BaseReferences<_$AppDatabase, $PollsTable, PollRow> {
  $$PollsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CasesTable _caseIdTable(_$AppDatabase db) =>
      db.cases.createAlias($_aliasNameGenerator(db.polls.caseId, db.cases.id));

  $$CasesTableProcessedTableManager? get caseId {
    if ($_item.caseId == null) return null;
    final manager = $$CasesTableTableManager($_db, $_db.cases)
        .filter((f) => f.id($_item.caseId!));
    final item = $_typedResult.readTableOrNull(_caseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PollsTableFilterComposer extends Composer<_$AppDatabase, $PollsTable> {
  $$PollsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pollNumber => $composableBuilder(
      column: $table.pollNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lean => $composableBuilder(
      column: $table.lean, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rationale => $composableBuilder(
      column: $table.rationale, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get revealed => $composableBuilder(
      column: $table.revealed, builder: (column) => ColumnFilters(column));

  $$CasesTableFilterComposer get caseId {
    final $$CasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableFilterComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PollsTableOrderingComposer
    extends Composer<_$AppDatabase, $PollsTable> {
  $$PollsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pollNumber => $composableBuilder(
      column: $table.pollNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lean => $composableBuilder(
      column: $table.lean, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rationale => $composableBuilder(
      column: $table.rationale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get revealed => $composableBuilder(
      column: $table.revealed, builder: (column) => ColumnOrderings(column));

  $$CasesTableOrderingComposer get caseId {
    final $$CasesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableOrderingComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PollsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PollsTable> {
  $$PollsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get pollNumber => $composableBuilder(
      column: $table.pollNumber, builder: (column) => column);

  GeneratedColumn<int> get lean =>
      $composableBuilder(column: $table.lean, builder: (column) => column);

  GeneratedColumn<String> get rationale =>
      $composableBuilder(column: $table.rationale, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<bool> get revealed =>
      $composableBuilder(column: $table.revealed, builder: (column) => column);

  $$CasesTableAnnotationComposer get caseId {
    final $$CasesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableAnnotationComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PollsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PollsTable,
    PollRow,
    $$PollsTableFilterComposer,
    $$PollsTableOrderingComposer,
    $$PollsTableAnnotationComposer,
    $$PollsTableCreateCompanionBuilder,
    $$PollsTableUpdateCompanionBuilder,
    (PollRow, $$PollsTableReferences),
    PollRow,
    PrefetchHooks Function({bool caseId})> {
  $$PollsTableTableManager(_$AppDatabase db, $PollsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PollsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PollsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PollsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> caseId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> pollNumber = const Value.absent(),
            Value<int> lean = const Value.absent(),
            Value<String?> rationale = const Value.absent(),
            Value<String> confidence = const Value.absent(),
            Value<bool> revealed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PollsCompanion(
            id: id,
            caseId: caseId,
            createdAt: createdAt,
            pollNumber: pollNumber,
            lean: lean,
            rationale: rationale,
            confidence: confidence,
            revealed: revealed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String caseId,
            required DateTime createdAt,
            required int pollNumber,
            required int lean,
            Value<String?> rationale = const Value.absent(),
            required String confidence,
            Value<bool> revealed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PollsCompanion.insert(
            id: id,
            caseId: caseId,
            createdAt: createdAt,
            pollNumber: pollNumber,
            lean: lean,
            rationale: rationale,
            confidence: confidence,
            revealed: revealed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PollsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({caseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (caseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.caseId,
                    referencedTable: $$PollsTableReferences._caseIdTable(db),
                    referencedColumn:
                        $$PollsTableReferences._caseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PollsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PollsTable,
    PollRow,
    $$PollsTableFilterComposer,
    $$PollsTableOrderingComposer,
    $$PollsTableAnnotationComposer,
    $$PollsTableCreateCompanionBuilder,
    $$PollsTableUpdateCompanionBuilder,
    (PollRow, $$PollsTableReferences),
    PollRow,
    PrefetchHooks Function({bool caseId})>;
typedef $$ResolutionsTableCreateCompanionBuilder = ResolutionsCompanion
    Function({
  required String id,
  required String caseId,
  required DateTime decidedAt,
  required String chosenOption,
  required DateTime resolutionCheckDate,
  Value<int?> satisfactionScore,
  Value<String?> reflection,
  Value<int> rowid,
});
typedef $$ResolutionsTableUpdateCompanionBuilder = ResolutionsCompanion
    Function({
  Value<String> id,
  Value<String> caseId,
  Value<DateTime> decidedAt,
  Value<String> chosenOption,
  Value<DateTime> resolutionCheckDate,
  Value<int?> satisfactionScore,
  Value<String?> reflection,
  Value<int> rowid,
});

final class $$ResolutionsTableReferences
    extends BaseReferences<_$AppDatabase, $ResolutionsTable, ResolutionRow> {
  $$ResolutionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CasesTable _caseIdTable(_$AppDatabase db) => db.cases
      .createAlias($_aliasNameGenerator(db.resolutions.caseId, db.cases.id));

  $$CasesTableProcessedTableManager? get caseId {
    if ($_item.caseId == null) return null;
    final manager = $$CasesTableTableManager($_db, $_db.cases)
        .filter((f) => f.id($_item.caseId!));
    final item = $_typedResult.readTableOrNull(_caseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ResolutionsTableFilterComposer
    extends Composer<_$AppDatabase, $ResolutionsTable> {
  $$ResolutionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
      column: $table.decidedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chosenOption => $composableBuilder(
      column: $table.chosenOption, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get resolutionCheckDate => $composableBuilder(
      column: $table.resolutionCheckDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get satisfactionScore => $composableBuilder(
      column: $table.satisfactionScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reflection => $composableBuilder(
      column: $table.reflection, builder: (column) => ColumnFilters(column));

  $$CasesTableFilterComposer get caseId {
    final $$CasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableFilterComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ResolutionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ResolutionsTable> {
  $$ResolutionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
      column: $table.decidedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chosenOption => $composableBuilder(
      column: $table.chosenOption,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get resolutionCheckDate => $composableBuilder(
      column: $table.resolutionCheckDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get satisfactionScore => $composableBuilder(
      column: $table.satisfactionScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reflection => $composableBuilder(
      column: $table.reflection, builder: (column) => ColumnOrderings(column));

  $$CasesTableOrderingComposer get caseId {
    final $$CasesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableOrderingComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ResolutionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResolutionsTable> {
  $$ResolutionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumn<String> get chosenOption => $composableBuilder(
      column: $table.chosenOption, builder: (column) => column);

  GeneratedColumn<DateTime> get resolutionCheckDate => $composableBuilder(
      column: $table.resolutionCheckDate, builder: (column) => column);

  GeneratedColumn<int> get satisfactionScore => $composableBuilder(
      column: $table.satisfactionScore, builder: (column) => column);

  GeneratedColumn<String> get reflection => $composableBuilder(
      column: $table.reflection, builder: (column) => column);

  $$CasesTableAnnotationComposer get caseId {
    final $$CasesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableAnnotationComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ResolutionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ResolutionsTable,
    ResolutionRow,
    $$ResolutionsTableFilterComposer,
    $$ResolutionsTableOrderingComposer,
    $$ResolutionsTableAnnotationComposer,
    $$ResolutionsTableCreateCompanionBuilder,
    $$ResolutionsTableUpdateCompanionBuilder,
    (ResolutionRow, $$ResolutionsTableReferences),
    ResolutionRow,
    PrefetchHooks Function({bool caseId})> {
  $$ResolutionsTableTableManager(_$AppDatabase db, $ResolutionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResolutionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResolutionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResolutionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> caseId = const Value.absent(),
            Value<DateTime> decidedAt = const Value.absent(),
            Value<String> chosenOption = const Value.absent(),
            Value<DateTime> resolutionCheckDate = const Value.absent(),
            Value<int?> satisfactionScore = const Value.absent(),
            Value<String?> reflection = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResolutionsCompanion(
            id: id,
            caseId: caseId,
            decidedAt: decidedAt,
            chosenOption: chosenOption,
            resolutionCheckDate: resolutionCheckDate,
            satisfactionScore: satisfactionScore,
            reflection: reflection,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String caseId,
            required DateTime decidedAt,
            required String chosenOption,
            required DateTime resolutionCheckDate,
            Value<int?> satisfactionScore = const Value.absent(),
            Value<String?> reflection = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResolutionsCompanion.insert(
            id: id,
            caseId: caseId,
            decidedAt: decidedAt,
            chosenOption: chosenOption,
            resolutionCheckDate: resolutionCheckDate,
            satisfactionScore: satisfactionScore,
            reflection: reflection,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ResolutionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({caseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (caseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.caseId,
                    referencedTable:
                        $$ResolutionsTableReferences._caseIdTable(db),
                    referencedColumn:
                        $$ResolutionsTableReferences._caseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ResolutionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ResolutionsTable,
    ResolutionRow,
    $$ResolutionsTableFilterComposer,
    $$ResolutionsTableOrderingComposer,
    $$ResolutionsTableAnnotationComposer,
    $$ResolutionsTableCreateCompanionBuilder,
    $$ResolutionsTableUpdateCompanionBuilder,
    (ResolutionRow, $$ResolutionsTableReferences),
    ResolutionRow,
    PrefetchHooks Function({bool caseId})>;
typedef $$OutsideViewsTableCreateCompanionBuilder = OutsideViewsCompanion
    Function({
  required String id,
  required String caseId,
  required DateTime generatedAt,
  required String baseRateSummary,
  required String referenceClassUsed,
  required String uncertaintyLevel,
  required Map<String, dynamic> stratificationFactors,
  required String llmMode,
  required String modelVersion,
  Value<List<dynamic>?> citations,
  Value<int> rowid,
});
typedef $$OutsideViewsTableUpdateCompanionBuilder = OutsideViewsCompanion
    Function({
  Value<String> id,
  Value<String> caseId,
  Value<DateTime> generatedAt,
  Value<String> baseRateSummary,
  Value<String> referenceClassUsed,
  Value<String> uncertaintyLevel,
  Value<Map<String, dynamic>> stratificationFactors,
  Value<String> llmMode,
  Value<String> modelVersion,
  Value<List<dynamic>?> citations,
  Value<int> rowid,
});

final class $$OutsideViewsTableReferences
    extends BaseReferences<_$AppDatabase, $OutsideViewsTable, OutsideViewRow> {
  $$OutsideViewsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CasesTable _caseIdTable(_$AppDatabase db) => db.cases
      .createAlias($_aliasNameGenerator(db.outsideViews.caseId, db.cases.id));

  $$CasesTableProcessedTableManager? get caseId {
    if ($_item.caseId == null) return null;
    final manager = $$CasesTableTableManager($_db, $_db.cases)
        .filter((f) => f.id($_item.caseId!));
    final item = $_typedResult.readTableOrNull(_caseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OutsideViewsTableFilterComposer
    extends Composer<_$AppDatabase, $OutsideViewsTable> {
  $$OutsideViewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseRateSummary => $composableBuilder(
      column: $table.baseRateSummary,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referenceClassUsed => $composableBuilder(
      column: $table.referenceClassUsed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uncertaintyLevel => $composableBuilder(
      column: $table.uncertaintyLevel,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Map<String, dynamic>, Map<String, dynamic>,
          String>
      get stratificationFactors => $composableBuilder(
          column: $table.stratificationFactors,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get llmMode => $composableBuilder(
      column: $table.llmMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<dynamic>?, List<dynamic>, String>
      get citations => $composableBuilder(
          column: $table.citations,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$CasesTableFilterComposer get caseId {
    final $$CasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableFilterComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OutsideViewsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutsideViewsTable> {
  $$OutsideViewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseRateSummary => $composableBuilder(
      column: $table.baseRateSummary,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceClassUsed => $composableBuilder(
      column: $table.referenceClassUsed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uncertaintyLevel => $composableBuilder(
      column: $table.uncertaintyLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stratificationFactors => $composableBuilder(
      column: $table.stratificationFactors,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get llmMode => $composableBuilder(
      column: $table.llmMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get citations => $composableBuilder(
      column: $table.citations, builder: (column) => ColumnOrderings(column));

  $$CasesTableOrderingComposer get caseId {
    final $$CasesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableOrderingComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OutsideViewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutsideViewsTable> {
  $$OutsideViewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<String> get baseRateSummary => $composableBuilder(
      column: $table.baseRateSummary, builder: (column) => column);

  GeneratedColumn<String> get referenceClassUsed => $composableBuilder(
      column: $table.referenceClassUsed, builder: (column) => column);

  GeneratedColumn<String> get uncertaintyLevel => $composableBuilder(
      column: $table.uncertaintyLevel, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
      get stratificationFactors => $composableBuilder(
          column: $table.stratificationFactors, builder: (column) => column);

  GeneratedColumn<String> get llmMode =>
      $composableBuilder(column: $table.llmMode, builder: (column) => column);

  GeneratedColumn<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>?, String> get citations =>
      $composableBuilder(column: $table.citations, builder: (column) => column);

  $$CasesTableAnnotationComposer get caseId {
    final $$CasesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableAnnotationComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OutsideViewsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutsideViewsTable,
    OutsideViewRow,
    $$OutsideViewsTableFilterComposer,
    $$OutsideViewsTableOrderingComposer,
    $$OutsideViewsTableAnnotationComposer,
    $$OutsideViewsTableCreateCompanionBuilder,
    $$OutsideViewsTableUpdateCompanionBuilder,
    (OutsideViewRow, $$OutsideViewsTableReferences),
    OutsideViewRow,
    PrefetchHooks Function({bool caseId})> {
  $$OutsideViewsTableTableManager(_$AppDatabase db, $OutsideViewsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutsideViewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutsideViewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutsideViewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> caseId = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<String> baseRateSummary = const Value.absent(),
            Value<String> referenceClassUsed = const Value.absent(),
            Value<String> uncertaintyLevel = const Value.absent(),
            Value<Map<String, dynamic>> stratificationFactors =
                const Value.absent(),
            Value<String> llmMode = const Value.absent(),
            Value<String> modelVersion = const Value.absent(),
            Value<List<dynamic>?> citations = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutsideViewsCompanion(
            id: id,
            caseId: caseId,
            generatedAt: generatedAt,
            baseRateSummary: baseRateSummary,
            referenceClassUsed: referenceClassUsed,
            uncertaintyLevel: uncertaintyLevel,
            stratificationFactors: stratificationFactors,
            llmMode: llmMode,
            modelVersion: modelVersion,
            citations: citations,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String caseId,
            required DateTime generatedAt,
            required String baseRateSummary,
            required String referenceClassUsed,
            required String uncertaintyLevel,
            required Map<String, dynamic> stratificationFactors,
            required String llmMode,
            required String modelVersion,
            Value<List<dynamic>?> citations = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutsideViewsCompanion.insert(
            id: id,
            caseId: caseId,
            generatedAt: generatedAt,
            baseRateSummary: baseRateSummary,
            referenceClassUsed: referenceClassUsed,
            uncertaintyLevel: uncertaintyLevel,
            stratificationFactors: stratificationFactors,
            llmMode: llmMode,
            modelVersion: modelVersion,
            citations: citations,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OutsideViewsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({caseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (caseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.caseId,
                    referencedTable:
                        $$OutsideViewsTableReferences._caseIdTable(db),
                    referencedColumn:
                        $$OutsideViewsTableReferences._caseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$OutsideViewsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutsideViewsTable,
    OutsideViewRow,
    $$OutsideViewsTableFilterComposer,
    $$OutsideViewsTableOrderingComposer,
    $$OutsideViewsTableAnnotationComposer,
    $$OutsideViewsTableCreateCompanionBuilder,
    $$OutsideViewsTableUpdateCompanionBuilder,
    (OutsideViewRow, $$OutsideViewsTableReferences),
    OutsideViewRow,
    PrefetchHooks Function({bool caseId})>;
typedef $$ReferenceClassesTableCreateCompanionBuilder
    = ReferenceClassesCompanion Function({
  required String id,
  required String category,
  required String subcategory,
  required String baseRateDescription,
  required List<dynamic> stratificationVariables,
  required List<dynamic> sources,
  required List<dynamic> commonCriteria,
  required String commonRegretPatterns,
  required String uncertaintyLevel,
  required String lastUpdated,
  Value<int> rowid,
});
typedef $$ReferenceClassesTableUpdateCompanionBuilder
    = ReferenceClassesCompanion Function({
  Value<String> id,
  Value<String> category,
  Value<String> subcategory,
  Value<String> baseRateDescription,
  Value<List<dynamic>> stratificationVariables,
  Value<List<dynamic>> sources,
  Value<List<dynamic>> commonCriteria,
  Value<String> commonRegretPatterns,
  Value<String> uncertaintyLevel,
  Value<String> lastUpdated,
  Value<int> rowid,
});

class $$ReferenceClassesTableFilterComposer
    extends Composer<_$AppDatabase, $ReferenceClassesTable> {
  $$ReferenceClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseRateDescription => $composableBuilder(
      column: $table.baseRateDescription,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
      get stratificationVariables => $composableBuilder(
          column: $table.stratificationVariables,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
      get sources => $composableBuilder(
          column: $table.sources,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
      get commonCriteria => $composableBuilder(
          column: $table.commonCriteria,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get commonRegretPatterns => $composableBuilder(
      column: $table.commonRegretPatterns,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uncertaintyLevel => $composableBuilder(
      column: $table.uncertaintyLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$ReferenceClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReferenceClassesTable> {
  $$ReferenceClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseRateDescription => $composableBuilder(
      column: $table.baseRateDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stratificationVariables => $composableBuilder(
      column: $table.stratificationVariables,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sources => $composableBuilder(
      column: $table.sources, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get commonCriteria => $composableBuilder(
      column: $table.commonCriteria,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get commonRegretPatterns => $composableBuilder(
      column: $table.commonRegretPatterns,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uncertaintyLevel => $composableBuilder(
      column: $table.uncertaintyLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$ReferenceClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReferenceClassesTable> {
  $$ReferenceClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => column);

  GeneratedColumn<String> get baseRateDescription => $composableBuilder(
      column: $table.baseRateDescription, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String>
      get stratificationVariables => $composableBuilder(
          column: $table.stratificationVariables, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get sources =>
      $composableBuilder(column: $table.sources, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get commonCriteria =>
      $composableBuilder(
          column: $table.commonCriteria, builder: (column) => column);

  GeneratedColumn<String> get commonRegretPatterns => $composableBuilder(
      column: $table.commonRegretPatterns, builder: (column) => column);

  GeneratedColumn<String> get uncertaintyLevel => $composableBuilder(
      column: $table.uncertaintyLevel, builder: (column) => column);

  GeneratedColumn<String> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$ReferenceClassesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReferenceClassesTable,
    ReferenceClassRow,
    $$ReferenceClassesTableFilterComposer,
    $$ReferenceClassesTableOrderingComposer,
    $$ReferenceClassesTableAnnotationComposer,
    $$ReferenceClassesTableCreateCompanionBuilder,
    $$ReferenceClassesTableUpdateCompanionBuilder,
    (
      ReferenceClassRow,
      BaseReferences<_$AppDatabase, $ReferenceClassesTable, ReferenceClassRow>
    ),
    ReferenceClassRow,
    PrefetchHooks Function()> {
  $$ReferenceClassesTableTableManager(
      _$AppDatabase db, $ReferenceClassesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReferenceClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReferenceClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReferenceClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> subcategory = const Value.absent(),
            Value<String> baseRateDescription = const Value.absent(),
            Value<List<dynamic>> stratificationVariables = const Value.absent(),
            Value<List<dynamic>> sources = const Value.absent(),
            Value<List<dynamic>> commonCriteria = const Value.absent(),
            Value<String> commonRegretPatterns = const Value.absent(),
            Value<String> uncertaintyLevel = const Value.absent(),
            Value<String> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReferenceClassesCompanion(
            id: id,
            category: category,
            subcategory: subcategory,
            baseRateDescription: baseRateDescription,
            stratificationVariables: stratificationVariables,
            sources: sources,
            commonCriteria: commonCriteria,
            commonRegretPatterns: commonRegretPatterns,
            uncertaintyLevel: uncertaintyLevel,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String category,
            required String subcategory,
            required String baseRateDescription,
            required List<dynamic> stratificationVariables,
            required List<dynamic> sources,
            required List<dynamic> commonCriteria,
            required String commonRegretPatterns,
            required String uncertaintyLevel,
            required String lastUpdated,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReferenceClassesCompanion.insert(
            id: id,
            category: category,
            subcategory: subcategory,
            baseRateDescription: baseRateDescription,
            stratificationVariables: stratificationVariables,
            sources: sources,
            commonCriteria: commonCriteria,
            commonRegretPatterns: commonRegretPatterns,
            uncertaintyLevel: uncertaintyLevel,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReferenceClassesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReferenceClassesTable,
    ReferenceClassRow,
    $$ReferenceClassesTableFilterComposer,
    $$ReferenceClassesTableOrderingComposer,
    $$ReferenceClassesTableAnnotationComposer,
    $$ReferenceClassesTableCreateCompanionBuilder,
    $$ReferenceClassesTableUpdateCompanionBuilder,
    (
      ReferenceClassRow,
      BaseReferences<_$AppDatabase, $ReferenceClassesTable, ReferenceClassRow>
    ),
    ReferenceClassRow,
    PrefetchHooks Function()>;
typedef $$UserProfileTableCreateCompanionBuilder = UserProfileCompanion
    Function({
  Value<int> id,
  Value<String?> sesBracket,
  Value<String?> religiosity,
  Value<String?> relationshipStatus,
});
typedef $$UserProfileTableUpdateCompanionBuilder = UserProfileCompanion
    Function({
  Value<int> id,
  Value<String?> sesBracket,
  Value<String?> religiosity,
  Value<String?> relationshipStatus,
});

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sesBracket => $composableBuilder(
      column: $table.sesBracket, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get religiosity => $composableBuilder(
      column: $table.religiosity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relationshipStatus => $composableBuilder(
      column: $table.relationshipStatus,
      builder: (column) => ColumnFilters(column));
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sesBracket => $composableBuilder(
      column: $table.sesBracket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get religiosity => $composableBuilder(
      column: $table.religiosity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relationshipStatus => $composableBuilder(
      column: $table.relationshipStatus,
      builder: (column) => ColumnOrderings(column));
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sesBracket => $composableBuilder(
      column: $table.sesBracket, builder: (column) => column);

  GeneratedColumn<String> get religiosity => $composableBuilder(
      column: $table.religiosity, builder: (column) => column);

  GeneratedColumn<String> get relationshipStatus => $composableBuilder(
      column: $table.relationshipStatus, builder: (column) => column);
}

class $$UserProfileTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfileTable,
    UserProfileRow,
    $$UserProfileTableFilterComposer,
    $$UserProfileTableOrderingComposer,
    $$UserProfileTableAnnotationComposer,
    $$UserProfileTableCreateCompanionBuilder,
    $$UserProfileTableUpdateCompanionBuilder,
    (
      UserProfileRow,
      BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileRow>
    ),
    UserProfileRow,
    PrefetchHooks Function()> {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> sesBracket = const Value.absent(),
            Value<String?> religiosity = const Value.absent(),
            Value<String?> relationshipStatus = const Value.absent(),
          }) =>
              UserProfileCompanion(
            id: id,
            sesBracket: sesBracket,
            religiosity: religiosity,
            relationshipStatus: relationshipStatus,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> sesBracket = const Value.absent(),
            Value<String?> religiosity = const Value.absent(),
            Value<String?> relationshipStatus = const Value.absent(),
          }) =>
              UserProfileCompanion.insert(
            id: id,
            sesBracket: sesBracket,
            religiosity: religiosity,
            relationshipStatus: relationshipStatus,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfileTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfileTable,
    UserProfileRow,
    $$UserProfileTableFilterComposer,
    $$UserProfileTableOrderingComposer,
    $$UserProfileTableAnnotationComposer,
    $$UserProfileTableCreateCompanionBuilder,
    $$UserProfileTableUpdateCompanionBuilder,
    (
      UserProfileRow,
      BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileRow>
    ),
    UserProfileRow,
    PrefetchHooks Function()>;
typedef $$CommunityForecastsTableCreateCompanionBuilder
    = CommunityForecastsCompanion Function({
  required String id,
  Value<int> rowid,
});
typedef $$CommunityForecastsTableUpdateCompanionBuilder
    = CommunityForecastsCompanion Function({
  Value<String> id,
  Value<int> rowid,
});

class $$CommunityForecastsTableFilterComposer
    extends Composer<_$AppDatabase, $CommunityForecastsTable> {
  $$CommunityForecastsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));
}

class $$CommunityForecastsTableOrderingComposer
    extends Composer<_$AppDatabase, $CommunityForecastsTable> {
  $$CommunityForecastsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));
}

class $$CommunityForecastsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommunityForecastsTable> {
  $$CommunityForecastsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$CommunityForecastsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CommunityForecastsTable,
    CommunityForecastRow,
    $$CommunityForecastsTableFilterComposer,
    $$CommunityForecastsTableOrderingComposer,
    $$CommunityForecastsTableAnnotationComposer,
    $$CommunityForecastsTableCreateCompanionBuilder,
    $$CommunityForecastsTableUpdateCompanionBuilder,
    (
      CommunityForecastRow,
      BaseReferences<_$AppDatabase, $CommunityForecastsTable,
          CommunityForecastRow>
    ),
    CommunityForecastRow,
    PrefetchHooks Function()> {
  $$CommunityForecastsTableTableManager(
      _$AppDatabase db, $CommunityForecastsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommunityForecastsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommunityForecastsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommunityForecastsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CommunityForecastsCompanion(
            id: id,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<int> rowid = const Value.absent(),
          }) =>
              CommunityForecastsCompanion.insert(
            id: id,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CommunityForecastsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CommunityForecastsTable,
    CommunityForecastRow,
    $$CommunityForecastsTableFilterComposer,
    $$CommunityForecastsTableOrderingComposer,
    $$CommunityForecastsTableAnnotationComposer,
    $$CommunityForecastsTableCreateCompanionBuilder,
    $$CommunityForecastsTableUpdateCompanionBuilder,
    (
      CommunityForecastRow,
      BaseReferences<_$AppDatabase, $CommunityForecastsTable,
          CommunityForecastRow>
    ),
    CommunityForecastRow,
    PrefetchHooks Function()>;
typedef $$ModelPredictionsTableCreateCompanionBuilder
    = ModelPredictionsCompanion Function({
  required String id,
  required String caseId,
  required String modelVersion,
  required String kind,
  required DateTime predictedAt,
  required Map<String, dynamic> payload,
  Value<double?> score,
  Value<DateTime?> scoredAt,
  Value<int> rowid,
});
typedef $$ModelPredictionsTableUpdateCompanionBuilder
    = ModelPredictionsCompanion Function({
  Value<String> id,
  Value<String> caseId,
  Value<String> modelVersion,
  Value<String> kind,
  Value<DateTime> predictedAt,
  Value<Map<String, dynamic>> payload,
  Value<double?> score,
  Value<DateTime?> scoredAt,
  Value<int> rowid,
});

final class $$ModelPredictionsTableReferences extends BaseReferences<
    _$AppDatabase, $ModelPredictionsTable, ModelPredictionRow> {
  $$ModelPredictionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CasesTable _caseIdTable(_$AppDatabase db) => db.cases.createAlias(
      $_aliasNameGenerator(db.modelPredictions.caseId, db.cases.id));

  $$CasesTableProcessedTableManager? get caseId {
    if ($_item.caseId == null) return null;
    final manager = $$CasesTableTableManager($_db, $_db.cases)
        .filter((f) => f.id($_item.caseId!));
    final item = $_typedResult.readTableOrNull(_caseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ModelPredictionsTableFilterComposer
    extends Composer<_$AppDatabase, $ModelPredictionsTable> {
  $$ModelPredictionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get predictedAt => $composableBuilder(
      column: $table.predictedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Map<String, dynamic>, Map<String, dynamic>,
          String>
      get payload => $composableBuilder(
          column: $table.payload,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scoredAt => $composableBuilder(
      column: $table.scoredAt, builder: (column) => ColumnFilters(column));

  $$CasesTableFilterComposer get caseId {
    final $$CasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableFilterComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ModelPredictionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelPredictionsTable> {
  $$ModelPredictionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get predictedAt => $composableBuilder(
      column: $table.predictedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scoredAt => $composableBuilder(
      column: $table.scoredAt, builder: (column) => ColumnOrderings(column));

  $$CasesTableOrderingComposer get caseId {
    final $$CasesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableOrderingComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ModelPredictionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelPredictionsTable> {
  $$ModelPredictionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get predictedAt => $composableBuilder(
      column: $table.predictedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<DateTime> get scoredAt =>
      $composableBuilder(column: $table.scoredAt, builder: (column) => column);

  $$CasesTableAnnotationComposer get caseId {
    final $$CasesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.cases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CasesTableAnnotationComposer(
              $db: $db,
              $table: $db.cases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ModelPredictionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ModelPredictionsTable,
    ModelPredictionRow,
    $$ModelPredictionsTableFilterComposer,
    $$ModelPredictionsTableOrderingComposer,
    $$ModelPredictionsTableAnnotationComposer,
    $$ModelPredictionsTableCreateCompanionBuilder,
    $$ModelPredictionsTableUpdateCompanionBuilder,
    (ModelPredictionRow, $$ModelPredictionsTableReferences),
    ModelPredictionRow,
    PrefetchHooks Function({bool caseId})> {
  $$ModelPredictionsTableTableManager(
      _$AppDatabase db, $ModelPredictionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelPredictionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelPredictionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelPredictionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> caseId = const Value.absent(),
            Value<String> modelVersion = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<DateTime> predictedAt = const Value.absent(),
            Value<Map<String, dynamic>> payload = const Value.absent(),
            Value<double?> score = const Value.absent(),
            Value<DateTime?> scoredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ModelPredictionsCompanion(
            id: id,
            caseId: caseId,
            modelVersion: modelVersion,
            kind: kind,
            predictedAt: predictedAt,
            payload: payload,
            score: score,
            scoredAt: scoredAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String caseId,
            required String modelVersion,
            required String kind,
            required DateTime predictedAt,
            required Map<String, dynamic> payload,
            Value<double?> score = const Value.absent(),
            Value<DateTime?> scoredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ModelPredictionsCompanion.insert(
            id: id,
            caseId: caseId,
            modelVersion: modelVersion,
            kind: kind,
            predictedAt: predictedAt,
            payload: payload,
            score: score,
            scoredAt: scoredAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ModelPredictionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({caseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (caseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.caseId,
                    referencedTable:
                        $$ModelPredictionsTableReferences._caseIdTable(db),
                    referencedColumn:
                        $$ModelPredictionsTableReferences._caseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ModelPredictionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ModelPredictionsTable,
    ModelPredictionRow,
    $$ModelPredictionsTableFilterComposer,
    $$ModelPredictionsTableOrderingComposer,
    $$ModelPredictionsTableAnnotationComposer,
    $$ModelPredictionsTableCreateCompanionBuilder,
    $$ModelPredictionsTableUpdateCompanionBuilder,
    (ModelPredictionRow, $$ModelPredictionsTableReferences),
    ModelPredictionRow,
    PrefetchHooks Function({bool caseId})>;
typedef $$PartiesTableCreateCompanionBuilder = PartiesCompanion Function({
  required String id,
  required String title,
  required String votingMethod,
  required List<dynamic> options,
  required DateTime createdAt,
  Value<bool> closed,
  Value<int> rowid,
});
typedef $$PartiesTableUpdateCompanionBuilder = PartiesCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> votingMethod,
  Value<List<dynamic>> options,
  Value<DateTime> createdAt,
  Value<bool> closed,
  Value<int> rowid,
});

final class $$PartiesTableReferences
    extends BaseReferences<_$AppDatabase, $PartiesTable, PartyRow> {
  $$PartiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PartyBallotsTable, List<PartyBallotRow>>
      _partyBallotsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.partyBallots,
              aliasName:
                  $_aliasNameGenerator(db.parties.id, db.partyBallots.partyId));

  $$PartyBallotsTableProcessedTableManager get partyBallotsRefs {
    final manager = $$PartyBallotsTableTableManager($_db, $_db.partyBallots)
        .filter((f) => f.partyId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_partyBallotsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PartiesTableFilterComposer
    extends Composer<_$AppDatabase, $PartiesTable> {
  $$PartiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get votingMethod => $composableBuilder(
      column: $table.votingMethod, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
      get options => $composableBuilder(
          column: $table.options,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get closed => $composableBuilder(
      column: $table.closed, builder: (column) => ColumnFilters(column));

  Expression<bool> partyBallotsRefs(
      Expression<bool> Function($$PartyBallotsTableFilterComposer f) f) {
    final $$PartyBallotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.partyBallots,
        getReferencedColumn: (t) => t.partyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartyBallotsTableFilterComposer(
              $db: $db,
              $table: $db.partyBallots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PartiesTableOrderingComposer
    extends Composer<_$AppDatabase, $PartiesTable> {
  $$PartiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get votingMethod => $composableBuilder(
      column: $table.votingMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get options => $composableBuilder(
      column: $table.options, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get closed => $composableBuilder(
      column: $table.closed, builder: (column) => ColumnOrderings(column));
}

class $$PartiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartiesTable> {
  $$PartiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get votingMethod => $composableBuilder(
      column: $table.votingMethod, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get closed =>
      $composableBuilder(column: $table.closed, builder: (column) => column);

  Expression<T> partyBallotsRefs<T extends Object>(
      Expression<T> Function($$PartyBallotsTableAnnotationComposer a) f) {
    final $$PartyBallotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.partyBallots,
        getReferencedColumn: (t) => t.partyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartyBallotsTableAnnotationComposer(
              $db: $db,
              $table: $db.partyBallots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PartiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PartiesTable,
    PartyRow,
    $$PartiesTableFilterComposer,
    $$PartiesTableOrderingComposer,
    $$PartiesTableAnnotationComposer,
    $$PartiesTableCreateCompanionBuilder,
    $$PartiesTableUpdateCompanionBuilder,
    (PartyRow, $$PartiesTableReferences),
    PartyRow,
    PrefetchHooks Function({bool partyBallotsRefs})> {
  $$PartiesTableTableManager(_$AppDatabase db, $PartiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> votingMethod = const Value.absent(),
            Value<List<dynamic>> options = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> closed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PartiesCompanion(
            id: id,
            title: title,
            votingMethod: votingMethod,
            options: options,
            createdAt: createdAt,
            closed: closed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String votingMethod,
            required List<dynamic> options,
            required DateTime createdAt,
            Value<bool> closed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PartiesCompanion.insert(
            id: id,
            title: title,
            votingMethod: votingMethod,
            options: options,
            createdAt: createdAt,
            closed: closed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PartiesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({partyBallotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (partyBallotsRefs) db.partyBallots],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (partyBallotsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PartiesTableReferences._partyBallotsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PartiesTableReferences(db, table, p0)
                                .partyBallotsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.partyId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PartiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PartiesTable,
    PartyRow,
    $$PartiesTableFilterComposer,
    $$PartiesTableOrderingComposer,
    $$PartiesTableAnnotationComposer,
    $$PartiesTableCreateCompanionBuilder,
    $$PartiesTableUpdateCompanionBuilder,
    (PartyRow, $$PartiesTableReferences),
    PartyRow,
    PrefetchHooks Function({bool partyBallotsRefs})>;
typedef $$PartyBallotsTableCreateCompanionBuilder = PartyBallotsCompanion
    Function({
  required String id,
  required String partyId,
  required String method,
  required List<dynamic> approvals,
  required List<dynamic> ranking,
  required DateTime submittedAt,
  Value<int> rowid,
});
typedef $$PartyBallotsTableUpdateCompanionBuilder = PartyBallotsCompanion
    Function({
  Value<String> id,
  Value<String> partyId,
  Value<String> method,
  Value<List<dynamic>> approvals,
  Value<List<dynamic>> ranking,
  Value<DateTime> submittedAt,
  Value<int> rowid,
});

final class $$PartyBallotsTableReferences
    extends BaseReferences<_$AppDatabase, $PartyBallotsTable, PartyBallotRow> {
  $$PartyBallotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PartiesTable _partyIdTable(_$AppDatabase db) =>
      db.parties.createAlias(
          $_aliasNameGenerator(db.partyBallots.partyId, db.parties.id));

  $$PartiesTableProcessedTableManager? get partyId {
    if ($_item.partyId == null) return null;
    final manager = $$PartiesTableTableManager($_db, $_db.parties)
        .filter((f) => f.id($_item.partyId!));
    final item = $_typedResult.readTableOrNull(_partyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PartyBallotsTableFilterComposer
    extends Composer<_$AppDatabase, $PartyBallotsTable> {
  $$PartyBallotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
      get approvals => $composableBuilder(
          column: $table.approvals,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
      get ranking => $composableBuilder(
          column: $table.ranking,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => ColumnFilters(column));

  $$PartiesTableFilterComposer get partyId {
    final $$PartiesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partyId,
        referencedTable: $db.parties,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartiesTableFilterComposer(
              $db: $db,
              $table: $db.parties,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PartyBallotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PartyBallotsTable> {
  $$PartyBallotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get approvals => $composableBuilder(
      column: $table.approvals, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ranking => $composableBuilder(
      column: $table.ranking, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => ColumnOrderings(column));

  $$PartiesTableOrderingComposer get partyId {
    final $$PartiesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partyId,
        referencedTable: $db.parties,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartiesTableOrderingComposer(
              $db: $db,
              $table: $db.parties,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PartyBallotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartyBallotsTable> {
  $$PartyBallotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get approvals =>
      $composableBuilder(column: $table.approvals, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get ranking =>
      $composableBuilder(column: $table.ranking, builder: (column) => column);

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => column);

  $$PartiesTableAnnotationComposer get partyId {
    final $$PartiesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partyId,
        referencedTable: $db.parties,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartiesTableAnnotationComposer(
              $db: $db,
              $table: $db.parties,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PartyBallotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PartyBallotsTable,
    PartyBallotRow,
    $$PartyBallotsTableFilterComposer,
    $$PartyBallotsTableOrderingComposer,
    $$PartyBallotsTableAnnotationComposer,
    $$PartyBallotsTableCreateCompanionBuilder,
    $$PartyBallotsTableUpdateCompanionBuilder,
    (PartyBallotRow, $$PartyBallotsTableReferences),
    PartyBallotRow,
    PrefetchHooks Function({bool partyId})> {
  $$PartyBallotsTableTableManager(_$AppDatabase db, $PartyBallotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartyBallotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartyBallotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartyBallotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> partyId = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<List<dynamic>> approvals = const Value.absent(),
            Value<List<dynamic>> ranking = const Value.absent(),
            Value<DateTime> submittedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PartyBallotsCompanion(
            id: id,
            partyId: partyId,
            method: method,
            approvals: approvals,
            ranking: ranking,
            submittedAt: submittedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String partyId,
            required String method,
            required List<dynamic> approvals,
            required List<dynamic> ranking,
            required DateTime submittedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PartyBallotsCompanion.insert(
            id: id,
            partyId: partyId,
            method: method,
            approvals: approvals,
            ranking: ranking,
            submittedAt: submittedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PartyBallotsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({partyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (partyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.partyId,
                    referencedTable:
                        $$PartyBallotsTableReferences._partyIdTable(db),
                    referencedColumn:
                        $$PartyBallotsTableReferences._partyIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PartyBallotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PartyBallotsTable,
    PartyBallotRow,
    $$PartyBallotsTableFilterComposer,
    $$PartyBallotsTableOrderingComposer,
    $$PartyBallotsTableAnnotationComposer,
    $$PartyBallotsTableCreateCompanionBuilder,
    $$PartyBallotsTableUpdateCompanionBuilder,
    (PartyBallotRow, $$PartyBallotsTableReferences),
    PartyBallotRow,
    PrefetchHooks Function({bool partyId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CasesTableTableManager get cases =>
      $$CasesTableTableManager(_db, _db.cases);
  $$PollsTableTableManager get polls =>
      $$PollsTableTableManager(_db, _db.polls);
  $$ResolutionsTableTableManager get resolutions =>
      $$ResolutionsTableTableManager(_db, _db.resolutions);
  $$OutsideViewsTableTableManager get outsideViews =>
      $$OutsideViewsTableTableManager(_db, _db.outsideViews);
  $$ReferenceClassesTableTableManager get referenceClasses =>
      $$ReferenceClassesTableTableManager(_db, _db.referenceClasses);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$CommunityForecastsTableTableManager get communityForecasts =>
      $$CommunityForecastsTableTableManager(_db, _db.communityForecasts);
  $$ModelPredictionsTableTableManager get modelPredictions =>
      $$ModelPredictionsTableTableManager(_db, _db.modelPredictions);
  $$PartiesTableTableManager get parties =>
      $$PartiesTableTableManager(_db, _db.parties);
  $$PartyBallotsTableTableManager get partyBallots =>
      $$PartyBallotsTableTableManager(_db, _db.partyBallots);
}
