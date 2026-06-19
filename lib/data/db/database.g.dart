// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QuestionBanksTable extends QuestionBanks
    with TableInfo<$QuestionBanksTable, QuestionBank> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionBanksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionCountMeta = const VerificationMeta(
    'questionCount',
  );
  @override
  late final GeneratedColumn<int> questionCount = GeneratedColumn<int>(
    'question_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    source,
    questionCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_banks';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionBank> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('question_count')) {
      context.handle(
        _questionCountMeta,
        questionCount.isAcceptableOrUnknown(
          data['question_count']!,
          _questionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionBank map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionBank(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      questionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuestionBanksTable createAlias(String alias) {
    return $QuestionBanksTable(attachedDatabase, alias);
  }
}

class QuestionBank extends DataClass implements Insertable<QuestionBank> {
  /// UUID 主键（D-08 共享 String id 类型）
  final String id;

  /// 题库名称（用户可见，如"2024秋-数据库原理"）
  final String name;

  /// 来源路径或描述（文件路径 / 手动输入）
  final String source;

  /// 解析出的题目总数
  final int questionCount;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime updatedAt;
  const QuestionBank({
    required this.id,
    required this.name,
    required this.source,
    required this.questionCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    map['question_count'] = Variable<int>(questionCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuestionBanksCompanion toCompanion(bool nullToAbsent) {
    return QuestionBanksCompanion(
      id: Value(id),
      name: Value(name),
      source: Value(source),
      questionCount: Value(questionCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuestionBank.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionBank(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      questionCount: serializer.fromJson<int>(json['questionCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'questionCount': serializer.toJson<int>(questionCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuestionBank copyWith({
    String? id,
    String? name,
    String? source,
    int? questionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuestionBank(
    id: id ?? this.id,
    name: name ?? this.name,
    source: source ?? this.source,
    questionCount: questionCount ?? this.questionCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuestionBank copyWithCompanion(QuestionBanksCompanion data) {
    return QuestionBank(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      questionCount: data.questionCount.present
          ? data.questionCount.value
          : this.questionCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionBank(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('questionCount: $questionCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, source, questionCount, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionBank &&
          other.id == this.id &&
          other.name == this.name &&
          other.source == this.source &&
          other.questionCount == this.questionCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuestionBanksCompanion extends UpdateCompanion<QuestionBank> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> source;
  final Value<int> questionCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuestionBanksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.questionCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionBanksCompanion.insert({
    required String id,
    required String name,
    required String source,
    required int questionCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       source = Value(source),
       questionCount = Value(questionCount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QuestionBank> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? source,
    Expression<int>? questionCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (questionCount != null) 'question_count': questionCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionBanksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? source,
    Value<int>? questionCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuestionBanksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (questionCount.present) {
      map['question_count'] = Variable<int>(questionCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionBanksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('questionCount: $questionCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, Question> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES question_banks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stemMeta = const VerificationMeta('stem');
  @override
  late final GeneratedColumn<String> stem = GeneratedColumn<String>(
    'stem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctJsonMeta = const VerificationMeta(
    'correctJson',
  );
  @override
  late final GeneratedColumn<String> correctJson = GeneratedColumn<String>(
    'correct_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankId,
    type,
    stem,
    optionsJson,
    correctJson,
    rawText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Question> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('stem')) {
      context.handle(
        _stemMeta,
        stem.isAcceptableOrUnknown(data['stem']!, _stemMeta),
      );
    } else if (isInserting) {
      context.missing(_stemMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionsJsonMeta);
    }
    if (data.containsKey('correct_json')) {
      context.handle(
        _correctJsonMeta,
        correctJson.isAcceptableOrUnknown(
          data['correct_json']!,
          _correctJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctJsonMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Question map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Question(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      stem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stem'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      correctJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_json'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class Question extends DataClass implements Insertable<Question> {
  /// UUID 主键（与 QuestionBank 共享 String id 类型，D-08）
  final String id;

  /// 所属题库 FK → question_banks.id（D-09：级联删除）
  final String bankId;

  /// 题型：'single' | 'multiple'
  final String type;

  /// 题干纯文本
  final String stem;

  /// 选项 JSON 数组：[{"key":"A","text":"..."}, ...]
  final String optionsJson;

  /// 正确答案 JSON 数组：["A"] 或 ["A","C"]
  final String correctJson;

  /// 原始文本（供 LLM 重放 / 调试）
  final String rawText;

  /// 创建时间
  final DateTime createdAt;
  const Question({
    required this.id,
    required this.bankId,
    required this.type,
    required this.stem,
    required this.optionsJson,
    required this.correctJson,
    required this.rawText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bank_id'] = Variable<String>(bankId);
    map['type'] = Variable<String>(type);
    map['stem'] = Variable<String>(stem);
    map['options_json'] = Variable<String>(optionsJson);
    map['correct_json'] = Variable<String>(correctJson);
    map['raw_text'] = Variable<String>(rawText);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      bankId: Value(bankId),
      type: Value(type),
      stem: Value(stem),
      optionsJson: Value(optionsJson),
      correctJson: Value(correctJson),
      rawText: Value(rawText),
      createdAt: Value(createdAt),
    );
  }

  factory Question.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Question(
      id: serializer.fromJson<String>(json['id']),
      bankId: serializer.fromJson<String>(json['bankId']),
      type: serializer.fromJson<String>(json['type']),
      stem: serializer.fromJson<String>(json['stem']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      correctJson: serializer.fromJson<String>(json['correctJson']),
      rawText: serializer.fromJson<String>(json['rawText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bankId': serializer.toJson<String>(bankId),
      'type': serializer.toJson<String>(type),
      'stem': serializer.toJson<String>(stem),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'correctJson': serializer.toJson<String>(correctJson),
      'rawText': serializer.toJson<String>(rawText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Question copyWith({
    String? id,
    String? bankId,
    String? type,
    String? stem,
    String? optionsJson,
    String? correctJson,
    String? rawText,
    DateTime? createdAt,
  }) => Question(
    id: id ?? this.id,
    bankId: bankId ?? this.bankId,
    type: type ?? this.type,
    stem: stem ?? this.stem,
    optionsJson: optionsJson ?? this.optionsJson,
    correctJson: correctJson ?? this.correctJson,
    rawText: rawText ?? this.rawText,
    createdAt: createdAt ?? this.createdAt,
  );
  Question copyWithCompanion(QuestionsCompanion data) {
    return Question(
      id: data.id.present ? data.id.value : this.id,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      type: data.type.present ? data.type.value : this.type,
      stem: data.stem.present ? data.stem.value : this.stem,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      correctJson: data.correctJson.present
          ? data.correctJson.value
          : this.correctJson,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Question(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('type: $type, ')
          ..write('stem: $stem, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('correctJson: $correctJson, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankId,
    type,
    stem,
    optionsJson,
    correctJson,
    rawText,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Question &&
          other.id == this.id &&
          other.bankId == this.bankId &&
          other.type == this.type &&
          other.stem == this.stem &&
          other.optionsJson == this.optionsJson &&
          other.correctJson == this.correctJson &&
          other.rawText == this.rawText &&
          other.createdAt == this.createdAt);
}

class QuestionsCompanion extends UpdateCompanion<Question> {
  final Value<String> id;
  final Value<String> bankId;
  final Value<String> type;
  final Value<String> stem;
  final Value<String> optionsJson;
  final Value<String> correctJson;
  final Value<String> rawText;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.bankId = const Value.absent(),
    this.type = const Value.absent(),
    this.stem = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.correctJson = const Value.absent(),
    this.rawText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionsCompanion.insert({
    required String id,
    required String bankId,
    required String type,
    required String stem,
    required String optionsJson,
    required String correctJson,
    required String rawText,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bankId = Value(bankId),
       type = Value(type),
       stem = Value(stem),
       optionsJson = Value(optionsJson),
       correctJson = Value(correctJson),
       rawText = Value(rawText),
       createdAt = Value(createdAt);
  static Insertable<Question> custom({
    Expression<String>? id,
    Expression<String>? bankId,
    Expression<String>? type,
    Expression<String>? stem,
    Expression<String>? optionsJson,
    Expression<String>? correctJson,
    Expression<String>? rawText,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankId != null) 'bank_id': bankId,
      if (type != null) 'type': type,
      if (stem != null) 'stem': stem,
      if (optionsJson != null) 'options_json': optionsJson,
      if (correctJson != null) 'correct_json': correctJson,
      if (rawText != null) 'raw_text': rawText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? bankId,
    Value<String>? type,
    Value<String>? stem,
    Value<String>? optionsJson,
    Value<String>? correctJson,
    Value<String>? rawText,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return QuestionsCompanion(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      type: type ?? this.type,
      stem: stem ?? this.stem,
      optionsJson: optionsJson ?? this.optionsJson,
      correctJson: correctJson ?? this.correctJson,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (stem.present) {
      map['stem'] = Variable<String>(stem.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (correctJson.present) {
      map['correct_json'] = Variable<String>(correctJson.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('type: $type, ')
          ..write('stem: $stem, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('correctJson: $correctJson, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WrongLedgerEntriesTable extends WrongLedgerEntries
    with TableInfo<$WrongLedgerEntriesTable, WrongLedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WrongLedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES questions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timesWrongMeta = const VerificationMeta(
    'timesWrong',
  );
  @override
  late final GeneratedColumn<int> timesWrong = GeneratedColumn<int>(
    'times_wrong',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstWrongAtMeta = const VerificationMeta(
    'firstWrongAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstWrongAt = GeneratedColumn<DateTime>(
    'first_wrong_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastWrongAtMeta = const VerificationMeta(
    'lastWrongAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastWrongAt = GeneratedColumn<DateTime>(
    'last_wrong_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masteredAtMeta = const VerificationMeta(
    'masteredAt',
  );
  @override
  late final GeneratedColumn<DateTime> masteredAt = GeneratedColumn<DateTime>(
    'mastered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionId,
    timesWrong,
    firstWrongAt,
    lastWrongAt,
    masteredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wrong_ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WrongLedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('times_wrong')) {
      context.handle(
        _timesWrongMeta,
        timesWrong.isAcceptableOrUnknown(data['times_wrong']!, _timesWrongMeta),
      );
    } else if (isInserting) {
      context.missing(_timesWrongMeta);
    }
    if (data.containsKey('first_wrong_at')) {
      context.handle(
        _firstWrongAtMeta,
        firstWrongAt.isAcceptableOrUnknown(
          data['first_wrong_at']!,
          _firstWrongAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstWrongAtMeta);
    }
    if (data.containsKey('last_wrong_at')) {
      context.handle(
        _lastWrongAtMeta,
        lastWrongAt.isAcceptableOrUnknown(
          data['last_wrong_at']!,
          _lastWrongAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastWrongAtMeta);
    }
    if (data.containsKey('mastered_at')) {
      context.handle(
        _masteredAtMeta,
        masteredAt.isAcceptableOrUnknown(data['mastered_at']!, _masteredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WrongLedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WrongLedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      timesWrong: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_wrong'],
      )!,
      firstWrongAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_wrong_at'],
      )!,
      lastWrongAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_wrong_at'],
      )!,
      masteredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mastered_at'],
      ),
    );
  }

  @override
  $WrongLedgerEntriesTable createAlias(String alias) {
    return $WrongLedgerEntriesTable(attachedDatabase, alias);
  }
}

class WrongLedgerEntry extends DataClass
    implements Insertable<WrongLedgerEntry> {
  /// 自增主键
  final int id;

  /// 关联题目 FK（表级 UNIQUE 约束：一题至多一条错题记录）
  final String questionId;

  /// 累计答错次数
  final int timesWrong;

  /// 首次答错时间
  final DateTime firstWrongAt;

  /// 最近一次答错时间
  final DateTime lastWrongAt;

  /// 掌握时间（null = 尚未掌握；非 null = 已从错题本毕业）
  final DateTime? masteredAt;
  const WrongLedgerEntry({
    required this.id,
    required this.questionId,
    required this.timesWrong,
    required this.firstWrongAt,
    required this.lastWrongAt,
    this.masteredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['times_wrong'] = Variable<int>(timesWrong);
    map['first_wrong_at'] = Variable<DateTime>(firstWrongAt);
    map['last_wrong_at'] = Variable<DateTime>(lastWrongAt);
    if (!nullToAbsent || masteredAt != null) {
      map['mastered_at'] = Variable<DateTime>(masteredAt);
    }
    return map;
  }

  WrongLedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return WrongLedgerEntriesCompanion(
      id: Value(id),
      questionId: Value(questionId),
      timesWrong: Value(timesWrong),
      firstWrongAt: Value(firstWrongAt),
      lastWrongAt: Value(lastWrongAt),
      masteredAt: masteredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(masteredAt),
    );
  }

  factory WrongLedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WrongLedgerEntry(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      timesWrong: serializer.fromJson<int>(json['timesWrong']),
      firstWrongAt: serializer.fromJson<DateTime>(json['firstWrongAt']),
      lastWrongAt: serializer.fromJson<DateTime>(json['lastWrongAt']),
      masteredAt: serializer.fromJson<DateTime?>(json['masteredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'timesWrong': serializer.toJson<int>(timesWrong),
      'firstWrongAt': serializer.toJson<DateTime>(firstWrongAt),
      'lastWrongAt': serializer.toJson<DateTime>(lastWrongAt),
      'masteredAt': serializer.toJson<DateTime?>(masteredAt),
    };
  }

  WrongLedgerEntry copyWith({
    int? id,
    String? questionId,
    int? timesWrong,
    DateTime? firstWrongAt,
    DateTime? lastWrongAt,
    DateTime? masteredAt,
  }) => WrongLedgerEntry(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    timesWrong: timesWrong ?? this.timesWrong,
    firstWrongAt: firstWrongAt ?? this.firstWrongAt,
    lastWrongAt: lastWrongAt ?? this.lastWrongAt,
    masteredAt: masteredAt ?? this.masteredAt,
  );
  WrongLedgerEntry copyWithCompanion(WrongLedgerEntriesCompanion data) {
    return WrongLedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      timesWrong: data.timesWrong.present
          ? data.timesWrong.value
          : this.timesWrong,
      firstWrongAt: data.firstWrongAt.present
          ? data.firstWrongAt.value
          : this.firstWrongAt,
      lastWrongAt: data.lastWrongAt.present
          ? data.lastWrongAt.value
          : this.lastWrongAt,
      masteredAt: data.masteredAt.present
          ? data.masteredAt.value
          : this.masteredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WrongLedgerEntry(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('timesWrong: $timesWrong, ')
          ..write('firstWrongAt: $firstWrongAt, ')
          ..write('lastWrongAt: $lastWrongAt, ')
          ..write('masteredAt: $masteredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questionId,
    timesWrong,
    firstWrongAt,
    lastWrongAt,
    masteredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WrongLedgerEntry &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.timesWrong == this.timesWrong &&
          other.firstWrongAt == this.firstWrongAt &&
          other.lastWrongAt == this.lastWrongAt &&
          other.masteredAt == this.masteredAt);
}

class WrongLedgerEntriesCompanion extends UpdateCompanion<WrongLedgerEntry> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<int> timesWrong;
  final Value<DateTime> firstWrongAt;
  final Value<DateTime> lastWrongAt;
  final Value<DateTime?> masteredAt;
  const WrongLedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.timesWrong = const Value.absent(),
    this.firstWrongAt = const Value.absent(),
    this.lastWrongAt = const Value.absent(),
    this.masteredAt = const Value.absent(),
  });
  WrongLedgerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required int timesWrong,
    required DateTime firstWrongAt,
    required DateTime lastWrongAt,
    this.masteredAt = const Value.absent(),
  }) : questionId = Value(questionId),
       timesWrong = Value(timesWrong),
       firstWrongAt = Value(firstWrongAt),
       lastWrongAt = Value(lastWrongAt);
  static Insertable<WrongLedgerEntry> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<int>? timesWrong,
    Expression<DateTime>? firstWrongAt,
    Expression<DateTime>? lastWrongAt,
    Expression<DateTime>? masteredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (timesWrong != null) 'times_wrong': timesWrong,
      if (firstWrongAt != null) 'first_wrong_at': firstWrongAt,
      if (lastWrongAt != null) 'last_wrong_at': lastWrongAt,
      if (masteredAt != null) 'mastered_at': masteredAt,
    });
  }

  WrongLedgerEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? questionId,
    Value<int>? timesWrong,
    Value<DateTime>? firstWrongAt,
    Value<DateTime>? lastWrongAt,
    Value<DateTime?>? masteredAt,
  }) {
    return WrongLedgerEntriesCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      timesWrong: timesWrong ?? this.timesWrong,
      firstWrongAt: firstWrongAt ?? this.firstWrongAt,
      lastWrongAt: lastWrongAt ?? this.lastWrongAt,
      masteredAt: masteredAt ?? this.masteredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (timesWrong.present) {
      map['times_wrong'] = Variable<int>(timesWrong.value);
    }
    if (firstWrongAt.present) {
      map['first_wrong_at'] = Variable<DateTime>(firstWrongAt.value);
    }
    if (lastWrongAt.present) {
      map['last_wrong_at'] = Variable<DateTime>(lastWrongAt.value);
    }
    if (masteredAt.present) {
      map['mastered_at'] = Variable<DateTime>(masteredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WrongLedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('timesWrong: $timesWrong, ')
          ..write('firstWrongAt: $firstWrongAt, ')
          ..write('lastWrongAt: $lastWrongAt, ')
          ..write('masteredAt: $masteredAt')
          ..write(')'))
        .toString();
  }
}

class $AnswerAttemptsTable extends AnswerAttempts
    with TableInfo<$AnswerAttemptsTable, AnswerAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnswerAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES questions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _givenAnswerJsonMeta = const VerificationMeta(
    'givenAnswerJson',
  );
  @override
  late final GeneratedColumn<String> givenAnswerJson = GeneratedColumn<String>(
    'given_answer_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionId,
    givenAnswerJson,
    isCorrect,
    mode,
    elapsedMs,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnswerAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('given_answer_json')) {
      context.handle(
        _givenAnswerJsonMeta,
        givenAnswerJson.isAcceptableOrUnknown(
          data['given_answer_json']!,
          _givenAnswerJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_givenAnswerJsonMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_isCorrectMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnswerAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      givenAnswerJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}given_answer_json'],
      )!,
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnswerAttemptsTable createAlias(String alias) {
    return $AnswerAttemptsTable(attachedDatabase, alias);
  }
}

class AnswerAttempt extends DataClass implements Insertable<AnswerAttempt> {
  /// 自增主键
  final int id;

  /// 关联题目 FK（题目删除时级联删除记录）
  final String questionId;

  /// 用户提交的答案 JSON 数组：["A"] 或 ["B","D"]
  final String givenAnswerJson;

  /// 本次作答是否正确
  final bool isCorrect;

  /// 复习模式：'random' | 'review' | 'spotcheck'
  final String mode;

  /// 作答耗时（毫秒）
  final int elapsedMs;

  /// 作答时间
  final DateTime createdAt;
  const AnswerAttempt({
    required this.id,
    required this.questionId,
    required this.givenAnswerJson,
    required this.isCorrect,
    required this.mode,
    required this.elapsedMs,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['given_answer_json'] = Variable<String>(givenAnswerJson);
    map['is_correct'] = Variable<bool>(isCorrect);
    map['mode'] = Variable<String>(mode);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnswerAttemptsCompanion toCompanion(bool nullToAbsent) {
    return AnswerAttemptsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      givenAnswerJson: Value(givenAnswerJson),
      isCorrect: Value(isCorrect),
      mode: Value(mode),
      elapsedMs: Value(elapsedMs),
      createdAt: Value(createdAt),
    );
  }

  factory AnswerAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerAttempt(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      givenAnswerJson: serializer.fromJson<String>(json['givenAnswerJson']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      mode: serializer.fromJson<String>(json['mode']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'givenAnswerJson': serializer.toJson<String>(givenAnswerJson),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'mode': serializer.toJson<String>(mode),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnswerAttempt copyWith({
    int? id,
    String? questionId,
    String? givenAnswerJson,
    bool? isCorrect,
    String? mode,
    int? elapsedMs,
    DateTime? createdAt,
  }) => AnswerAttempt(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    givenAnswerJson: givenAnswerJson ?? this.givenAnswerJson,
    isCorrect: isCorrect ?? this.isCorrect,
    mode: mode ?? this.mode,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    createdAt: createdAt ?? this.createdAt,
  );
  AnswerAttempt copyWithCompanion(AnswerAttemptsCompanion data) {
    return AnswerAttempt(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      givenAnswerJson: data.givenAnswerJson.present
          ? data.givenAnswerJson.value
          : this.givenAnswerJson,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      mode: data.mode.present ? data.mode.value : this.mode,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerAttempt(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('givenAnswerJson: $givenAnswerJson, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('mode: $mode, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questionId,
    givenAnswerJson,
    isCorrect,
    mode,
    elapsedMs,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerAttempt &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.givenAnswerJson == this.givenAnswerJson &&
          other.isCorrect == this.isCorrect &&
          other.mode == this.mode &&
          other.elapsedMs == this.elapsedMs &&
          other.createdAt == this.createdAt);
}

class AnswerAttemptsCompanion extends UpdateCompanion<AnswerAttempt> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<String> givenAnswerJson;
  final Value<bool> isCorrect;
  final Value<String> mode;
  final Value<int> elapsedMs;
  final Value<DateTime> createdAt;
  const AnswerAttemptsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.givenAnswerJson = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.mode = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnswerAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required String givenAnswerJson,
    required bool isCorrect,
    required String mode,
    required int elapsedMs,
    required DateTime createdAt,
  }) : questionId = Value(questionId),
       givenAnswerJson = Value(givenAnswerJson),
       isCorrect = Value(isCorrect),
       mode = Value(mode),
       elapsedMs = Value(elapsedMs),
       createdAt = Value(createdAt);
  static Insertable<AnswerAttempt> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<String>? givenAnswerJson,
    Expression<bool>? isCorrect,
    Expression<String>? mode,
    Expression<int>? elapsedMs,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (givenAnswerJson != null) 'given_answer_json': givenAnswerJson,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (mode != null) 'mode': mode,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnswerAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? questionId,
    Value<String>? givenAnswerJson,
    Value<bool>? isCorrect,
    Value<String>? mode,
    Value<int>? elapsedMs,
    Value<DateTime>? createdAt,
  }) {
    return AnswerAttemptsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      givenAnswerJson: givenAnswerJson ?? this.givenAnswerJson,
      isCorrect: isCorrect ?? this.isCorrect,
      mode: mode ?? this.mode,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (givenAnswerJson.present) {
      map['given_answer_json'] = Variable<String>(givenAnswerJson.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('givenAnswerJson: $givenAnswerJson, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('mode: $mode, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES questions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, questionId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  /// 自增主键
  final int id;

  /// 关联题目 FK（表级 UNIQUE 约束：一题至多收藏一次）
  final String questionId;

  /// 收藏时间
  final DateTime createdAt;
  const Bookmark({
    required this.id,
    required this.questionId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      questionId: Value(questionId),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith({int? id, String? questionId, DateTime? createdAt}) =>
      Bookmark(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        createdAt: createdAt ?? this.createdAt,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<DateTime> createdAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required DateTime createdAt,
  }) : questionId = Value(questionId),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<String>? questionId,
    Value<DateTime>? createdAt,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ParseJobsTable extends ParseJobs
    with TableInfo<$ParseJobsTable, ParseJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParseJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultCountMeta = const VerificationMeta(
    'resultCount',
  );
  @override
  late final GeneratedColumn<int> resultCount = GeneratedColumn<int>(
    'result_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourcePath,
    status,
    progress,
    resultCount,
    errorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parse_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ParseJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcePathMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('result_count')) {
      context.handle(
        _resultCountMeta,
        resultCount.isAcceptableOrUnknown(
          data['result_count']!,
          _resultCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resultCountMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ParseJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParseJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      resultCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}result_count'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ParseJobsTable createAlias(String alias) {
    return $ParseJobsTable(attachedDatabase, alias);
  }
}

class ParseJob extends DataClass implements Insertable<ParseJob> {
  /// 任务 UUID（文本主键）
  final String id;

  /// 源文件路径
  final String sourcePath;

  /// 状态：'pending' | 'running' | 'succeeded' | 'failed' | 'cancelled'
  final String status;

  /// 进度 0.0–1.0
  final double progress;

  /// 解析出的题目数量
  final int resultCount;

  /// 失败原因（成功时为 null）
  final String? errorMessage;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;
  const ParseJob({
    required this.id,
    required this.sourcePath,
    required this.status,
    required this.progress,
    required this.resultCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_path'] = Variable<String>(sourcePath);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    map['result_count'] = Variable<int>(resultCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ParseJobsCompanion toCompanion(bool nullToAbsent) {
    return ParseJobsCompanion(
      id: Value(id),
      sourcePath: Value(sourcePath),
      status: Value(status),
      progress: Value(progress),
      resultCount: Value(resultCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ParseJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParseJob(
      id: serializer.fromJson<String>(json['id']),
      sourcePath: serializer.fromJson<String>(json['sourcePath']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      resultCount: serializer.fromJson<int>(json['resultCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourcePath': serializer.toJson<String>(sourcePath),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'resultCount': serializer.toJson<int>(resultCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ParseJob copyWith({
    String? id,
    String? sourcePath,
    String? status,
    double? progress,
    int? resultCount,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ParseJob(
    id: id ?? this.id,
    sourcePath: sourcePath ?? this.sourcePath,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    resultCount: resultCount ?? this.resultCount,
    errorMessage: errorMessage ?? this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ParseJob copyWithCompanion(ParseJobsCompanion data) {
    return ParseJob(
      id: data.id.present ? data.id.value : this.id,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      resultCount: data.resultCount.present
          ? data.resultCount.value
          : this.resultCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParseJob(')
          ..write('id: $id, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('resultCount: $resultCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourcePath,
    status,
    progress,
    resultCount,
    errorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParseJob &&
          other.id == this.id &&
          other.sourcePath == this.sourcePath &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.resultCount == this.resultCount &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ParseJobsCompanion extends UpdateCompanion<ParseJob> {
  final Value<String> id;
  final Value<String> sourcePath;
  final Value<String> status;
  final Value<double> progress;
  final Value<int> resultCount;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ParseJobsCompanion({
    this.id = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.resultCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParseJobsCompanion.insert({
    required String id,
    required String sourcePath,
    required String status,
    required double progress,
    required int resultCount,
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourcePath = Value(sourcePath),
       status = Value(status),
       progress = Value(progress),
       resultCount = Value(resultCount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ParseJob> custom({
    Expression<String>? id,
    Expression<String>? sourcePath,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? resultCount,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePath != null) 'source_path': sourcePath,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (resultCount != null) 'result_count': resultCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParseJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourcePath,
    Value<String>? status,
    Value<double>? progress,
    Value<int>? resultCount,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ParseJobsCompanion(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      resultCount: resultCount ?? this.resultCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (resultCount.present) {
      map['result_count'] = Variable<int>(resultCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParseJobsCompanion(')
          ..write('id: $id, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('resultCount: $resultCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParseLogsTable extends ParseLogs
    with TableInfo<$ParseLogsTable, ParseLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParseLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _parseJobIdMeta = const VerificationMeta(
    'parseJobId',
  );
  @override
  late final GeneratedColumn<String> parseJobId = GeneratedColumn<String>(
    'parse_job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES parse_jobs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextJsonMeta = const VerificationMeta(
    'contextJson',
  );
  @override
  late final GeneratedColumn<String> contextJson = GeneratedColumn<String>(
    'context_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parseJobId,
    level,
    message,
    contextJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parse_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ParseLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parse_job_id')) {
      context.handle(
        _parseJobIdMeta,
        parseJobId.isAcceptableOrUnknown(
          data['parse_job_id']!,
          _parseJobIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parseJobIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('context_json')) {
      context.handle(
        _contextJsonMeta,
        contextJson.isAcceptableOrUnknown(
          data['context_json']!,
          _contextJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ParseLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParseLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      parseJobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parse_job_id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      contextJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ParseLogsTable createAlias(String alias) {
    return $ParseLogsTable(attachedDatabase, alias);
  }
}

class ParseLog extends DataClass implements Insertable<ParseLog> {
  /// 自增主键
  final int id;

  /// 关联解析任务 FK（任务删除时级联删除日志）
  final String parseJobId;

  /// 日志级别：'info' | 'warn' | 'error'
  final String level;

  /// 日志消息
  final String message;

  /// 附加上下文 JSON（文件偏移量 / 行号等）
  final String contextJson;

  /// 日志时间
  final DateTime createdAt;
  const ParseLog({
    required this.id,
    required this.parseJobId,
    required this.level,
    required this.message,
    required this.contextJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['parse_job_id'] = Variable<String>(parseJobId);
    map['level'] = Variable<String>(level);
    map['message'] = Variable<String>(message);
    map['context_json'] = Variable<String>(contextJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ParseLogsCompanion toCompanion(bool nullToAbsent) {
    return ParseLogsCompanion(
      id: Value(id),
      parseJobId: Value(parseJobId),
      level: Value(level),
      message: Value(message),
      contextJson: Value(contextJson),
      createdAt: Value(createdAt),
    );
  }

  factory ParseLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParseLog(
      id: serializer.fromJson<int>(json['id']),
      parseJobId: serializer.fromJson<String>(json['parseJobId']),
      level: serializer.fromJson<String>(json['level']),
      message: serializer.fromJson<String>(json['message']),
      contextJson: serializer.fromJson<String>(json['contextJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parseJobId': serializer.toJson<String>(parseJobId),
      'level': serializer.toJson<String>(level),
      'message': serializer.toJson<String>(message),
      'contextJson': serializer.toJson<String>(contextJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ParseLog copyWith({
    int? id,
    String? parseJobId,
    String? level,
    String? message,
    String? contextJson,
    DateTime? createdAt,
  }) => ParseLog(
    id: id ?? this.id,
    parseJobId: parseJobId ?? this.parseJobId,
    level: level ?? this.level,
    message: message ?? this.message,
    contextJson: contextJson ?? this.contextJson,
    createdAt: createdAt ?? this.createdAt,
  );
  ParseLog copyWithCompanion(ParseLogsCompanion data) {
    return ParseLog(
      id: data.id.present ? data.id.value : this.id,
      parseJobId: data.parseJobId.present
          ? data.parseJobId.value
          : this.parseJobId,
      level: data.level.present ? data.level.value : this.level,
      message: data.message.present ? data.message.value : this.message,
      contextJson: data.contextJson.present
          ? data.contextJson.value
          : this.contextJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParseLog(')
          ..write('id: $id, ')
          ..write('parseJobId: $parseJobId, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('contextJson: $contextJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, parseJobId, level, message, contextJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParseLog &&
          other.id == this.id &&
          other.parseJobId == this.parseJobId &&
          other.level == this.level &&
          other.message == this.message &&
          other.contextJson == this.contextJson &&
          other.createdAt == this.createdAt);
}

class ParseLogsCompanion extends UpdateCompanion<ParseLog> {
  final Value<int> id;
  final Value<String> parseJobId;
  final Value<String> level;
  final Value<String> message;
  final Value<String> contextJson;
  final Value<DateTime> createdAt;
  const ParseLogsCompanion({
    this.id = const Value.absent(),
    this.parseJobId = const Value.absent(),
    this.level = const Value.absent(),
    this.message = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ParseLogsCompanion.insert({
    this.id = const Value.absent(),
    required String parseJobId,
    required String level,
    required String message,
    required String contextJson,
    required DateTime createdAt,
  }) : parseJobId = Value(parseJobId),
       level = Value(level),
       message = Value(message),
       contextJson = Value(contextJson),
       createdAt = Value(createdAt);
  static Insertable<ParseLog> custom({
    Expression<int>? id,
    Expression<String>? parseJobId,
    Expression<String>? level,
    Expression<String>? message,
    Expression<String>? contextJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parseJobId != null) 'parse_job_id': parseJobId,
      if (level != null) 'level': level,
      if (message != null) 'message': message,
      if (contextJson != null) 'context_json': contextJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ParseLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? parseJobId,
    Value<String>? level,
    Value<String>? message,
    Value<String>? contextJson,
    Value<DateTime>? createdAt,
  }) {
    return ParseLogsCompanion(
      id: id ?? this.id,
      parseJobId: parseJobId ?? this.parseJobId,
      level: level ?? this.level,
      message: message ?? this.message,
      contextJson: contextJson ?? this.contextJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parseJobId.present) {
      map['parse_job_id'] = Variable<String>(parseJobId.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (contextJson.present) {
      map['context_json'] = Variable<String>(contextJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParseLogsCompanion(')
          ..write('id: $id, ')
          ..write('parseJobId: $parseJobId, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('contextJson: $contextJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestionBanksTable questionBanks = $QuestionBanksTable(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $WrongLedgerEntriesTable wrongLedgerEntries =
      $WrongLedgerEntriesTable(this);
  late final $AnswerAttemptsTable answerAttempts = $AnswerAttemptsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $ParseJobsTable parseJobs = $ParseJobsTable(this);
  late final $ParseLogsTable parseLogs = $ParseLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    questionBanks,
    questions,
    wrongLedgerEntries,
    answerAttempts,
    bookmarks,
    parseJobs,
    parseLogs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'question_banks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('questions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'questions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wrong_ledger_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'questions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_attempts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'questions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bookmarks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'parse_jobs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('parse_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$QuestionBanksTableCreateCompanionBuilder =
    QuestionBanksCompanion Function({
      required String id,
      required String name,
      required String source,
      required int questionCount,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$QuestionBanksTableUpdateCompanionBuilder =
    QuestionBanksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> source,
      Value<int> questionCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$QuestionBanksTableReferences
    extends BaseReferences<_$AppDatabase, $QuestionBanksTable, QuestionBank> {
  $$QuestionBanksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$QuestionsTable, List<Question>>
  _questionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.questions,
    aliasName: 'question_banks__id__questions__bank_id',
  );

  $$QuestionsTableProcessedTableManager get questionsRefs {
    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.bankId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuestionBanksTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionBanksTable> {
  $$QuestionBanksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> questionsRefs(
    Expression<bool> Function($$QuestionsTableFilterComposer f) f,
  ) {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.bankId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionBanksTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionBanksTable> {
  $$QuestionBanksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionBanksTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionBanksTable> {
  $$QuestionBanksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> questionsRefs<T extends Object>(
    Expression<T> Function($$QuestionsTableAnnotationComposer a) f,
  ) {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.bankId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionBanksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestionBanksTable,
          QuestionBank,
          $$QuestionBanksTableFilterComposer,
          $$QuestionBanksTableOrderingComposer,
          $$QuestionBanksTableAnnotationComposer,
          $$QuestionBanksTableCreateCompanionBuilder,
          $$QuestionBanksTableUpdateCompanionBuilder,
          (QuestionBank, $$QuestionBanksTableReferences),
          QuestionBank,
          PrefetchHooks Function({bool questionsRefs})
        > {
  $$QuestionBanksTableTableManager(_$AppDatabase db, $QuestionBanksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionBanksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionBanksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionBanksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> questionCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionBanksCompanion(
                id: id,
                name: name,
                source: source,
                questionCount: questionCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String source,
                required int questionCount,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuestionBanksCompanion.insert(
                id: id,
                name: name,
                source: source,
                questionCount: questionCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionBanksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (questionsRefs) db.questions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (questionsRefs)
                    await $_getPrefetchedData<
                      QuestionBank,
                      $QuestionBanksTable,
                      Question
                    >(
                      currentTable: table,
                      referencedTable: $$QuestionBanksTableReferences
                          ._questionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$QuestionBanksTableReferences(
                            db,
                            table,
                            p0,
                          ).questionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.bankId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$QuestionBanksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestionBanksTable,
      QuestionBank,
      $$QuestionBanksTableFilterComposer,
      $$QuestionBanksTableOrderingComposer,
      $$QuestionBanksTableAnnotationComposer,
      $$QuestionBanksTableCreateCompanionBuilder,
      $$QuestionBanksTableUpdateCompanionBuilder,
      (QuestionBank, $$QuestionBanksTableReferences),
      QuestionBank,
      PrefetchHooks Function({bool questionsRefs})
    >;
typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      required String id,
      required String bankId,
      required String type,
      required String stem,
      required String optionsJson,
      required String correctJson,
      required String rawText,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<String> id,
      Value<String> bankId,
      Value<String> type,
      Value<String> stem,
      Value<String> optionsJson,
      Value<String> correctJson,
      Value<String> rawText,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$QuestionsTableReferences
    extends BaseReferences<_$AppDatabase, $QuestionsTable, Question> {
  $$QuestionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuestionBanksTable _bankIdTable(_$AppDatabase db) =>
      db.questionBanks.createAlias('questions__bank_id__question_banks__id');

  $$QuestionBanksTableProcessedTableManager get bankId {
    final $_column = $_itemColumn<String>('bank_id')!;

    final manager = $$QuestionBanksTableTableManager(
      $_db,
      $_db.questionBanks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bankIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WrongLedgerEntriesTable, List<WrongLedgerEntry>>
  _wrongLedgerEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.wrongLedgerEntries,
        aliasName: 'questions__id__wrong_ledger_entries__question_id',
      );

  $$WrongLedgerEntriesTableProcessedTableManager get wrongLedgerEntriesRefs {
    final manager = $$WrongLedgerEntriesTableTableManager(
      $_db,
      $_db.wrongLedgerEntries,
    ).filter((f) => f.questionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _wrongLedgerEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AnswerAttemptsTable, List<AnswerAttempt>>
  _answerAttemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.answerAttempts,
    aliasName: 'questions__id__answer_attempts__question_id',
  );

  $$AnswerAttemptsTableProcessedTableManager get answerAttemptsRefs {
    final manager = $$AnswerAttemptsTableTableManager(
      $_db,
      $_db.answerAttempts,
    ).filter((f) => f.questionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_answerAttemptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'questions__id__bookmarks__question_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.questionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctJson => $composableBuilder(
    column: $table.correctJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionBanksTableFilterComposer get bankId {
    final $$QuestionBanksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.questionBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionBanksTableFilterComposer(
            $db: $db,
            $table: $db.questionBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> wrongLedgerEntriesRefs(
    Expression<bool> Function($$WrongLedgerEntriesTableFilterComposer f) f,
  ) {
    final $$WrongLedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wrongLedgerEntries,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WrongLedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.wrongLedgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> answerAttemptsRefs(
    Expression<bool> Function($$AnswerAttemptsTableFilterComposer f) f,
  ) {
    final $$AnswerAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answerAttempts,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.answerAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctJson => $composableBuilder(
    column: $table.correctJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionBanksTableOrderingComposer get bankId {
    final $$QuestionBanksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.questionBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionBanksTableOrderingComposer(
            $db: $db,
            $table: $db.questionBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get stem =>
      $composableBuilder(column: $table.stem, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctJson => $composableBuilder(
    column: $table.correctJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$QuestionBanksTableAnnotationComposer get bankId {
    final $$QuestionBanksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.questionBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionBanksTableAnnotationComposer(
            $db: $db,
            $table: $db.questionBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> wrongLedgerEntriesRefs<T extends Object>(
    Expression<T> Function($$WrongLedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$WrongLedgerEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.wrongLedgerEntries,
          getReferencedColumn: (t) => t.questionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WrongLedgerEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.wrongLedgerEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> answerAttemptsRefs<T extends Object>(
    Expression<T> Function($$AnswerAttemptsTableAnnotationComposer a) f,
  ) {
    final $$AnswerAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answerAttempts,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.answerAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestionsTable,
          Question,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (Question, $$QuestionsTableReferences),
          Question,
          PrefetchHooks Function({
            bool bankId,
            bool wrongLedgerEntriesRefs,
            bool answerAttemptsRefs,
            bool bookmarksRefs,
          })
        > {
  $$QuestionsTableTableManager(_$AppDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bankId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> stem = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String> correctJson = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion(
                id: id,
                bankId: bankId,
                type: type,
                stem: stem,
                optionsJson: optionsJson,
                correctJson: correctJson,
                rawText: rawText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bankId,
                required String type,
                required String stem,
                required String optionsJson,
                required String correctJson,
                required String rawText,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion.insert(
                id: id,
                bankId: bankId,
                type: type,
                stem: stem,
                optionsJson: optionsJson,
                correctJson: correctJson,
                rawText: rawText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bankId = false,
                wrongLedgerEntriesRefs = false,
                answerAttemptsRefs = false,
                bookmarksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wrongLedgerEntriesRefs) db.wrongLedgerEntries,
                    if (answerAttemptsRefs) db.answerAttempts,
                    if (bookmarksRefs) db.bookmarks,
                  ],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (bankId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bankId,
                                    referencedTable: $$QuestionsTableReferences
                                        ._bankIdTable(db),
                                    referencedColumn: $$QuestionsTableReferences
                                        ._bankIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wrongLedgerEntriesRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          WrongLedgerEntry
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._wrongLedgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).wrongLedgerEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (answerAttemptsRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          AnswerAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._answerAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).answerAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          Bookmark
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestionsTable,
      Question,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (Question, $$QuestionsTableReferences),
      Question,
      PrefetchHooks Function({
        bool bankId,
        bool wrongLedgerEntriesRefs,
        bool answerAttemptsRefs,
        bool bookmarksRefs,
      })
    >;
typedef $$WrongLedgerEntriesTableCreateCompanionBuilder =
    WrongLedgerEntriesCompanion Function({
      Value<int> id,
      required String questionId,
      required int timesWrong,
      required DateTime firstWrongAt,
      required DateTime lastWrongAt,
      Value<DateTime?> masteredAt,
    });
typedef $$WrongLedgerEntriesTableUpdateCompanionBuilder =
    WrongLedgerEntriesCompanion Function({
      Value<int> id,
      Value<String> questionId,
      Value<int> timesWrong,
      Value<DateTime> firstWrongAt,
      Value<DateTime> lastWrongAt,
      Value<DateTime?> masteredAt,
    });

final class $$WrongLedgerEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WrongLedgerEntriesTable,
          WrongLedgerEntry
        > {
  $$WrongLedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QuestionsTable _questionIdTable(_$AppDatabase db) => db.questions
      .createAlias('wrong_ledger_entries__question_id__questions__id');

  $$QuestionsTableProcessedTableManager get questionId {
    final $_column = $_itemColumn<String>('question_id')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WrongLedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WrongLedgerEntriesTable> {
  $$WrongLedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesWrong => $composableBuilder(
    column: $table.timesWrong,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstWrongAt => $composableBuilder(
    column: $table.firstWrongAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWrongAt => $composableBuilder(
    column: $table.lastWrongAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionId {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WrongLedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WrongLedgerEntriesTable> {
  $$WrongLedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesWrong => $composableBuilder(
    column: $table.timesWrong,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstWrongAt => $composableBuilder(
    column: $table.firstWrongAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWrongAt => $composableBuilder(
    column: $table.lastWrongAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionId {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WrongLedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WrongLedgerEntriesTable> {
  $$WrongLedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timesWrong => $composableBuilder(
    column: $table.timesWrong,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstWrongAt => $composableBuilder(
    column: $table.firstWrongAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastWrongAt => $composableBuilder(
    column: $table.lastWrongAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => column,
  );

  $$QuestionsTableAnnotationComposer get questionId {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WrongLedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WrongLedgerEntriesTable,
          WrongLedgerEntry,
          $$WrongLedgerEntriesTableFilterComposer,
          $$WrongLedgerEntriesTableOrderingComposer,
          $$WrongLedgerEntriesTableAnnotationComposer,
          $$WrongLedgerEntriesTableCreateCompanionBuilder,
          $$WrongLedgerEntriesTableUpdateCompanionBuilder,
          (WrongLedgerEntry, $$WrongLedgerEntriesTableReferences),
          WrongLedgerEntry,
          PrefetchHooks Function({bool questionId})
        > {
  $$WrongLedgerEntriesTableTableManager(
    _$AppDatabase db,
    $WrongLedgerEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WrongLedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WrongLedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WrongLedgerEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<int> timesWrong = const Value.absent(),
                Value<DateTime> firstWrongAt = const Value.absent(),
                Value<DateTime> lastWrongAt = const Value.absent(),
                Value<DateTime?> masteredAt = const Value.absent(),
              }) => WrongLedgerEntriesCompanion(
                id: id,
                questionId: questionId,
                timesWrong: timesWrong,
                firstWrongAt: firstWrongAt,
                lastWrongAt: lastWrongAt,
                masteredAt: masteredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionId,
                required int timesWrong,
                required DateTime firstWrongAt,
                required DateTime lastWrongAt,
                Value<DateTime?> masteredAt = const Value.absent(),
              }) => WrongLedgerEntriesCompanion.insert(
                id: id,
                questionId: questionId,
                timesWrong: timesWrong,
                firstWrongAt: firstWrongAt,
                lastWrongAt: lastWrongAt,
                masteredAt: masteredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WrongLedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (questionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionId,
                                referencedTable:
                                    $$WrongLedgerEntriesTableReferences
                                        ._questionIdTable(db),
                                referencedColumn:
                                    $$WrongLedgerEntriesTableReferences
                                        ._questionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WrongLedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WrongLedgerEntriesTable,
      WrongLedgerEntry,
      $$WrongLedgerEntriesTableFilterComposer,
      $$WrongLedgerEntriesTableOrderingComposer,
      $$WrongLedgerEntriesTableAnnotationComposer,
      $$WrongLedgerEntriesTableCreateCompanionBuilder,
      $$WrongLedgerEntriesTableUpdateCompanionBuilder,
      (WrongLedgerEntry, $$WrongLedgerEntriesTableReferences),
      WrongLedgerEntry,
      PrefetchHooks Function({bool questionId})
    >;
typedef $$AnswerAttemptsTableCreateCompanionBuilder =
    AnswerAttemptsCompanion Function({
      Value<int> id,
      required String questionId,
      required String givenAnswerJson,
      required bool isCorrect,
      required String mode,
      required int elapsedMs,
      required DateTime createdAt,
    });
typedef $$AnswerAttemptsTableUpdateCompanionBuilder =
    AnswerAttemptsCompanion Function({
      Value<int> id,
      Value<String> questionId,
      Value<String> givenAnswerJson,
      Value<bool> isCorrect,
      Value<String> mode,
      Value<int> elapsedMs,
      Value<DateTime> createdAt,
    });

final class $$AnswerAttemptsTableReferences
    extends BaseReferences<_$AppDatabase, $AnswerAttemptsTable, AnswerAttempt> {
  $$AnswerAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QuestionsTable _questionIdTable(_$AppDatabase db) =>
      db.questions.createAlias('answer_attempts__question_id__questions__id');

  $$QuestionsTableProcessedTableManager get questionId {
    final $_column = $_itemColumn<String>('question_id')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnswerAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $AnswerAttemptsTable> {
  $$AnswerAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get givenAnswerJson => $composableBuilder(
    column: $table.givenAnswerJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionId {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswerAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnswerAttemptsTable> {
  $$AnswerAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get givenAnswerJson => $composableBuilder(
    column: $table.givenAnswerJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionId {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswerAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnswerAttemptsTable> {
  $$AnswerAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get givenAnswerJson => $composableBuilder(
    column: $table.givenAnswerJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$QuestionsTableAnnotationComposer get questionId {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswerAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnswerAttemptsTable,
          AnswerAttempt,
          $$AnswerAttemptsTableFilterComposer,
          $$AnswerAttemptsTableOrderingComposer,
          $$AnswerAttemptsTableAnnotationComposer,
          $$AnswerAttemptsTableCreateCompanionBuilder,
          $$AnswerAttemptsTableUpdateCompanionBuilder,
          (AnswerAttempt, $$AnswerAttemptsTableReferences),
          AnswerAttempt,
          PrefetchHooks Function({bool questionId})
        > {
  $$AnswerAttemptsTableTableManager(
    _$AppDatabase db,
    $AnswerAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnswerAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnswerAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnswerAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> givenAnswerJson = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnswerAttemptsCompanion(
                id: id,
                questionId: questionId,
                givenAnswerJson: givenAnswerJson,
                isCorrect: isCorrect,
                mode: mode,
                elapsedMs: elapsedMs,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionId,
                required String givenAnswerJson,
                required bool isCorrect,
                required String mode,
                required int elapsedMs,
                required DateTime createdAt,
              }) => AnswerAttemptsCompanion.insert(
                id: id,
                questionId: questionId,
                givenAnswerJson: givenAnswerJson,
                isCorrect: isCorrect,
                mode: mode,
                elapsedMs: elapsedMs,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnswerAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (questionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionId,
                                referencedTable: $$AnswerAttemptsTableReferences
                                    ._questionIdTable(db),
                                referencedColumn:
                                    $$AnswerAttemptsTableReferences
                                        ._questionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AnswerAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnswerAttemptsTable,
      AnswerAttempt,
      $$AnswerAttemptsTableFilterComposer,
      $$AnswerAttemptsTableOrderingComposer,
      $$AnswerAttemptsTableAnnotationComposer,
      $$AnswerAttemptsTableCreateCompanionBuilder,
      $$AnswerAttemptsTableUpdateCompanionBuilder,
      (AnswerAttempt, $$AnswerAttemptsTableReferences),
      AnswerAttempt,
      PrefetchHooks Function({bool questionId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      required String questionId,
      required DateTime createdAt,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      Value<String> questionId,
      Value<DateTime> createdAt,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuestionsTable _questionIdTable(_$AppDatabase db) =>
      db.questions.createAlias('bookmarks__question_id__questions__id');

  $$QuestionsTableProcessedTableManager get questionId {
    final $_column = $_itemColumn<String>('question_id')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionId {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionId {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$QuestionsTableAnnotationComposer get questionId {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, $$BookmarksTableReferences),
          Bookmark,
          PrefetchHooks Function({bool questionId})
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                questionId: questionId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionId,
                required DateTime createdAt,
              }) => BookmarksCompanion.insert(
                id: id,
                questionId: questionId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (questionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionId,
                                referencedTable: $$BookmarksTableReferences
                                    ._questionIdTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._questionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, $$BookmarksTableReferences),
      Bookmark,
      PrefetchHooks Function({bool questionId})
    >;
typedef $$ParseJobsTableCreateCompanionBuilder =
    ParseJobsCompanion Function({
      required String id,
      required String sourcePath,
      required String status,
      required double progress,
      required int resultCount,
      Value<String?> errorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ParseJobsTableUpdateCompanionBuilder =
    ParseJobsCompanion Function({
      Value<String> id,
      Value<String> sourcePath,
      Value<String> status,
      Value<double> progress,
      Value<int> resultCount,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ParseJobsTableReferences
    extends BaseReferences<_$AppDatabase, $ParseJobsTable, ParseJob> {
  $$ParseJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ParseLogsTable, List<ParseLog>>
  _parseLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.parseLogs,
    aliasName: 'parse_jobs__id__parse_logs__parse_job_id',
  );

  $$ParseLogsTableProcessedTableManager get parseLogsRefs {
    final manager = $$ParseLogsTableTableManager(
      $_db,
      $_db.parseLogs,
    ).filter((f) => f.parseJobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_parseLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ParseJobsTableFilterComposer
    extends Composer<_$AppDatabase, $ParseJobsTable> {
  $$ParseJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resultCount => $composableBuilder(
    column: $table.resultCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> parseLogsRefs(
    Expression<bool> Function($$ParseLogsTableFilterComposer f) f,
  ) {
    final $$ParseLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.parseLogs,
      getReferencedColumn: (t) => t.parseJobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParseLogsTableFilterComposer(
            $db: $db,
            $table: $db.parseLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ParseJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParseJobsTable> {
  $$ParseJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resultCount => $composableBuilder(
    column: $table.resultCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParseJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParseJobsTable> {
  $$ParseJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get resultCount => $composableBuilder(
    column: $table.resultCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> parseLogsRefs<T extends Object>(
    Expression<T> Function($$ParseLogsTableAnnotationComposer a) f,
  ) {
    final $$ParseLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.parseLogs,
      getReferencedColumn: (t) => t.parseJobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParseLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.parseLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ParseJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParseJobsTable,
          ParseJob,
          $$ParseJobsTableFilterComposer,
          $$ParseJobsTableOrderingComposer,
          $$ParseJobsTableAnnotationComposer,
          $$ParseJobsTableCreateCompanionBuilder,
          $$ParseJobsTableUpdateCompanionBuilder,
          (ParseJob, $$ParseJobsTableReferences),
          ParseJob,
          PrefetchHooks Function({bool parseLogsRefs})
        > {
  $$ParseJobsTableTableManager(_$AppDatabase db, $ParseJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParseJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParseJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParseJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourcePath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> resultCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParseJobsCompanion(
                id: id,
                sourcePath: sourcePath,
                status: status,
                progress: progress,
                resultCount: resultCount,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourcePath,
                required String status,
                required double progress,
                required int resultCount,
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ParseJobsCompanion.insert(
                id: id,
                sourcePath: sourcePath,
                status: status,
                progress: progress,
                resultCount: resultCount,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ParseJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parseLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (parseLogsRefs) db.parseLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (parseLogsRefs)
                    await $_getPrefetchedData<
                      ParseJob,
                      $ParseJobsTable,
                      ParseLog
                    >(
                      currentTable: table,
                      referencedTable: $$ParseJobsTableReferences
                          ._parseLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ParseJobsTableReferences(
                            db,
                            table,
                            p0,
                          ).parseLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.parseJobId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ParseJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParseJobsTable,
      ParseJob,
      $$ParseJobsTableFilterComposer,
      $$ParseJobsTableOrderingComposer,
      $$ParseJobsTableAnnotationComposer,
      $$ParseJobsTableCreateCompanionBuilder,
      $$ParseJobsTableUpdateCompanionBuilder,
      (ParseJob, $$ParseJobsTableReferences),
      ParseJob,
      PrefetchHooks Function({bool parseLogsRefs})
    >;
typedef $$ParseLogsTableCreateCompanionBuilder =
    ParseLogsCompanion Function({
      Value<int> id,
      required String parseJobId,
      required String level,
      required String message,
      required String contextJson,
      required DateTime createdAt,
    });
typedef $$ParseLogsTableUpdateCompanionBuilder =
    ParseLogsCompanion Function({
      Value<int> id,
      Value<String> parseJobId,
      Value<String> level,
      Value<String> message,
      Value<String> contextJson,
      Value<DateTime> createdAt,
    });

final class $$ParseLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ParseLogsTable, ParseLog> {
  $$ParseLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ParseJobsTable _parseJobIdTable(_$AppDatabase db) =>
      db.parseJobs.createAlias('parse_logs__parse_job_id__parse_jobs__id');

  $$ParseJobsTableProcessedTableManager get parseJobId {
    final $_column = $_itemColumn<String>('parse_job_id')!;

    final manager = $$ParseJobsTableTableManager(
      $_db,
      $_db.parseJobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parseJobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ParseLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ParseLogsTable> {
  $$ParseLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ParseJobsTableFilterComposer get parseJobId {
    final $$ParseJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parseJobId,
      referencedTable: $db.parseJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParseJobsTableFilterComposer(
            $db: $db,
            $table: $db.parseJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ParseLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParseLogsTable> {
  $$ParseLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ParseJobsTableOrderingComposer get parseJobId {
    final $$ParseJobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parseJobId,
      referencedTable: $db.parseJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParseJobsTableOrderingComposer(
            $db: $db,
            $table: $db.parseJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ParseLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParseLogsTable> {
  $$ParseLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ParseJobsTableAnnotationComposer get parseJobId {
    final $$ParseJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parseJobId,
      referencedTable: $db.parseJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParseJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.parseJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ParseLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParseLogsTable,
          ParseLog,
          $$ParseLogsTableFilterComposer,
          $$ParseLogsTableOrderingComposer,
          $$ParseLogsTableAnnotationComposer,
          $$ParseLogsTableCreateCompanionBuilder,
          $$ParseLogsTableUpdateCompanionBuilder,
          (ParseLog, $$ParseLogsTableReferences),
          ParseLog,
          PrefetchHooks Function({bool parseJobId})
        > {
  $$ParseLogsTableTableManager(_$AppDatabase db, $ParseLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParseLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParseLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParseLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> parseJobId = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> contextJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ParseLogsCompanion(
                id: id,
                parseJobId: parseJobId,
                level: level,
                message: message,
                contextJson: contextJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String parseJobId,
                required String level,
                required String message,
                required String contextJson,
                required DateTime createdAt,
              }) => ParseLogsCompanion.insert(
                id: id,
                parseJobId: parseJobId,
                level: level,
                message: message,
                contextJson: contextJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ParseLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parseJobId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (parseJobId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.parseJobId,
                                referencedTable: $$ParseLogsTableReferences
                                    ._parseJobIdTable(db),
                                referencedColumn: $$ParseLogsTableReferences
                                    ._parseJobIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ParseLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParseLogsTable,
      ParseLog,
      $$ParseLogsTableFilterComposer,
      $$ParseLogsTableOrderingComposer,
      $$ParseLogsTableAnnotationComposer,
      $$ParseLogsTableCreateCompanionBuilder,
      $$ParseLogsTableUpdateCompanionBuilder,
      (ParseLog, $$ParseLogsTableReferences),
      ParseLog,
      PrefetchHooks Function({bool parseJobId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestionBanksTableTableManager get questionBanks =>
      $$QuestionBanksTableTableManager(_db, _db.questionBanks);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$WrongLedgerEntriesTableTableManager get wrongLedgerEntries =>
      $$WrongLedgerEntriesTableTableManager(_db, _db.wrongLedgerEntries);
  $$AnswerAttemptsTableTableManager get answerAttempts =>
      $$AnswerAttemptsTableTableManager(_db, _db.answerAttempts);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$ParseJobsTableTableManager get parseJobs =>
      $$ParseJobsTableTableManager(_db, _db.parseJobs);
  $$ParseLogsTableTableManager get parseLogs =>
      $$ParseLogsTableTableManager(_db, _db.parseLogs);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppDatabase>,
          AppDatabase,
          FutureOr<AppDatabase>
        >
    with $FutureModifier<AppDatabase>, $FutureProvider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $FutureProviderElement<AppDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppDatabase> create(Ref ref) {
    return appDatabase(ref);
  }
}

String _$appDatabaseHash() => r'392699d736908052654b0d27d7af0ebca642a795';
