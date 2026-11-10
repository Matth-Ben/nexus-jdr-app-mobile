// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedReferenceEntriesTable extends CachedReferenceEntries
    with TableInfo<$CachedReferenceEntriesTable, CachedReferenceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedReferenceEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, payload, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_reference_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedReferenceEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CachedReferenceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedReferenceEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedReferenceEntriesTable createAlias(String alias) {
    return $CachedReferenceEntriesTable(attachedDatabase, alias);
  }
}

class CachedReferenceEntry extends DataClass
    implements Insertable<CachedReferenceEntry> {
  /// Ex. `'race_catalog'`, ou paramétré par `classId` pour les sorts :
  /// `'spell_catalog:12'` (voir `SupabaseCharacterCreationRepository
  /// .fetchSpellCatalog`).
  final String key;

  /// `jsonEncode` d'une map structurée `{sousEnsemble: [lignes brutes...]}`
  /// — voir `ReferenceDataCache.put`.
  final String payload;
  final DateTime cachedAt;
  const CachedReferenceEntry({
    required this.key,
    required this.payload,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['payload'] = Variable<String>(payload);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedReferenceEntriesCompanion toCompanion(bool nullToAbsent) {
    return CachedReferenceEntriesCompanion(
      key: Value(key),
      payload: Value(payload),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedReferenceEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedReferenceEntry(
      key: serializer.fromJson<String>(json['key']),
      payload: serializer.fromJson<String>(json['payload']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedReferenceEntry copyWith({
    String? key,
    String? payload,
    DateTime? cachedAt,
  }) => CachedReferenceEntry(
    key: key ?? this.key,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedReferenceEntry copyWithCompanion(CachedReferenceEntriesCompanion data) {
    return CachedReferenceEntry(
      key: data.key.present ? data.key.value : this.key,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedReferenceEntry(')
          ..write('key: $key, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, payload, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedReferenceEntry &&
          other.key == this.key &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt);
}

class CachedReferenceEntriesCompanion
    extends UpdateCompanion<CachedReferenceEntry> {
  final Value<String> key;
  final Value<String> payload;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedReferenceEntriesCompanion({
    this.key = const Value.absent(),
    this.payload = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedReferenceEntriesCompanion.insert({
    required String key,
    required String payload,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       payload = Value(payload),
       cachedAt = Value(cachedAt);
  static Insertable<CachedReferenceEntry> custom({
    Expression<String>? key,
    Expression<String>? payload,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedReferenceEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? payload,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedReferenceEntriesCompanion(
      key: key ?? this.key,
      payload: payload ?? this.payload,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedReferenceEntriesCompanion(')
          ..write('key: $key, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingCharacterWritesTable extends PendingCharacterWrites
    with TableInfo<$PendingCharacterWritesTable, PendingCharacterWrite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingCharacterWritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failureCountMeta = const VerificationMeta(
    'failureCount',
  );
  @override
  late final GeneratedColumn<int> failureCount = GeneratedColumn<int>(
    'failure_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _abandonedMeta = const VerificationMeta(
    'abandoned',
  );
  @override
  late final GeneratedColumn<bool> abandoned = GeneratedColumn<bool>(
    'abandoned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("abandoned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastFailureMessageMeta =
      const VerificationMeta('lastFailureMessage');
  @override
  late final GeneratedColumn<String> lastFailureMessage =
      GeneratedColumn<String>(
        'last_failure_message',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    characterId,
    ownerId,
    kind,
    targetId,
    payload,
    queuedAt,
    failureCount,
    abandoned,
    lastFailureMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_character_writes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingCharacterWrite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('failure_count')) {
      context.handle(
        _failureCountMeta,
        failureCount.isAcceptableOrUnknown(
          data['failure_count']!,
          _failureCountMeta,
        ),
      );
    }
    if (data.containsKey('abandoned')) {
      context.handle(
        _abandonedMeta,
        abandoned.isAcceptableOrUnknown(data['abandoned']!, _abandonedMeta),
      );
    }
    if (data.containsKey('last_failure_message')) {
      context.handle(
        _lastFailureMessageMeta,
        lastFailureMessage.isAcceptableOrUnknown(
          data['last_failure_message']!,
          _lastFailureMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    ownerId,
    characterId,
    kind,
    targetId,
  };
  @override
  PendingCharacterWrite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingCharacterWrite(
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      failureCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failure_count'],
      )!,
      abandoned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}abandoned'],
      )!,
      lastFailureMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_failure_message'],
      ),
    );
  }

  @override
  $PendingCharacterWritesTable createAlias(String alias) {
    return $PendingCharacterWritesTable(attachedDatabase, alias);
  }
}

class PendingCharacterWrite extends DataClass
    implements Insertable<PendingCharacterWrite> {
  final String characterId;
  final String ownerId;
  final String kind;
  final String targetId;
  final String payload;
  final DateTime queuedAt;
  final int failureCount;
  final bool abandoned;
  final String? lastFailureMessage;
  const PendingCharacterWrite({
    required this.characterId,
    required this.ownerId,
    required this.kind,
    required this.targetId,
    required this.payload,
    required this.queuedAt,
    required this.failureCount,
    required this.abandoned,
    this.lastFailureMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_id'] = Variable<String>(characterId);
    map['owner_id'] = Variable<String>(ownerId);
    map['kind'] = Variable<String>(kind);
    map['target_id'] = Variable<String>(targetId);
    map['payload'] = Variable<String>(payload);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['failure_count'] = Variable<int>(failureCount);
    map['abandoned'] = Variable<bool>(abandoned);
    if (!nullToAbsent || lastFailureMessage != null) {
      map['last_failure_message'] = Variable<String>(lastFailureMessage);
    }
    return map;
  }

  PendingCharacterWritesCompanion toCompanion(bool nullToAbsent) {
    return PendingCharacterWritesCompanion(
      characterId: Value(characterId),
      ownerId: Value(ownerId),
      kind: Value(kind),
      targetId: Value(targetId),
      payload: Value(payload),
      queuedAt: Value(queuedAt),
      failureCount: Value(failureCount),
      abandoned: Value(abandoned),
      lastFailureMessage: lastFailureMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailureMessage),
    );
  }

  factory PendingCharacterWrite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingCharacterWrite(
      characterId: serializer.fromJson<String>(json['characterId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      kind: serializer.fromJson<String>(json['kind']),
      targetId: serializer.fromJson<String>(json['targetId']),
      payload: serializer.fromJson<String>(json['payload']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      failureCount: serializer.fromJson<int>(json['failureCount']),
      abandoned: serializer.fromJson<bool>(json['abandoned']),
      lastFailureMessage: serializer.fromJson<String?>(
        json['lastFailureMessage'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterId': serializer.toJson<String>(characterId),
      'ownerId': serializer.toJson<String>(ownerId),
      'kind': serializer.toJson<String>(kind),
      'targetId': serializer.toJson<String>(targetId),
      'payload': serializer.toJson<String>(payload),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'failureCount': serializer.toJson<int>(failureCount),
      'abandoned': serializer.toJson<bool>(abandoned),
      'lastFailureMessage': serializer.toJson<String?>(lastFailureMessage),
    };
  }

  PendingCharacterWrite copyWith({
    String? characterId,
    String? ownerId,
    String? kind,
    String? targetId,
    String? payload,
    DateTime? queuedAt,
    int? failureCount,
    bool? abandoned,
    Value<String?> lastFailureMessage = const Value.absent(),
  }) => PendingCharacterWrite(
    characterId: characterId ?? this.characterId,
    ownerId: ownerId ?? this.ownerId,
    kind: kind ?? this.kind,
    targetId: targetId ?? this.targetId,
    payload: payload ?? this.payload,
    queuedAt: queuedAt ?? this.queuedAt,
    failureCount: failureCount ?? this.failureCount,
    abandoned: abandoned ?? this.abandoned,
    lastFailureMessage: lastFailureMessage.present
        ? lastFailureMessage.value
        : this.lastFailureMessage,
  );
  PendingCharacterWrite copyWithCompanion(
    PendingCharacterWritesCompanion data,
  ) {
    return PendingCharacterWrite(
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      payload: data.payload.present ? data.payload.value : this.payload,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      failureCount: data.failureCount.present
          ? data.failureCount.value
          : this.failureCount,
      abandoned: data.abandoned.present ? data.abandoned.value : this.abandoned,
      lastFailureMessage: data.lastFailureMessage.present
          ? data.lastFailureMessage.value
          : this.lastFailureMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingCharacterWrite(')
          ..write('characterId: $characterId, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('failureCount: $failureCount, ')
          ..write('abandoned: $abandoned, ')
          ..write('lastFailureMessage: $lastFailureMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    characterId,
    ownerId,
    kind,
    targetId,
    payload,
    queuedAt,
    failureCount,
    abandoned,
    lastFailureMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingCharacterWrite &&
          other.characterId == this.characterId &&
          other.ownerId == this.ownerId &&
          other.kind == this.kind &&
          other.targetId == this.targetId &&
          other.payload == this.payload &&
          other.queuedAt == this.queuedAt &&
          other.failureCount == this.failureCount &&
          other.abandoned == this.abandoned &&
          other.lastFailureMessage == this.lastFailureMessage);
}

class PendingCharacterWritesCompanion
    extends UpdateCompanion<PendingCharacterWrite> {
  final Value<String> characterId;
  final Value<String> ownerId;
  final Value<String> kind;
  final Value<String> targetId;
  final Value<String> payload;
  final Value<DateTime> queuedAt;
  final Value<int> failureCount;
  final Value<bool> abandoned;
  final Value<String?> lastFailureMessage;
  final Value<int> rowid;
  const PendingCharacterWritesCompanion({
    this.characterId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.targetId = const Value.absent(),
    this.payload = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.failureCount = const Value.absent(),
    this.abandoned = const Value.absent(),
    this.lastFailureMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingCharacterWritesCompanion.insert({
    required String characterId,
    required String ownerId,
    required String kind,
    this.targetId = const Value.absent(),
    required String payload,
    required DateTime queuedAt,
    this.failureCount = const Value.absent(),
    this.abandoned = const Value.absent(),
    this.lastFailureMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : characterId = Value(characterId),
       ownerId = Value(ownerId),
       kind = Value(kind),
       payload = Value(payload),
       queuedAt = Value(queuedAt);
  static Insertable<PendingCharacterWrite> custom({
    Expression<String>? characterId,
    Expression<String>? ownerId,
    Expression<String>? kind,
    Expression<String>? targetId,
    Expression<String>? payload,
    Expression<DateTime>? queuedAt,
    Expression<int>? failureCount,
    Expression<bool>? abandoned,
    Expression<String>? lastFailureMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (ownerId != null) 'owner_id': ownerId,
      if (kind != null) 'kind': kind,
      if (targetId != null) 'target_id': targetId,
      if (payload != null) 'payload': payload,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (failureCount != null) 'failure_count': failureCount,
      if (abandoned != null) 'abandoned': abandoned,
      if (lastFailureMessage != null)
        'last_failure_message': lastFailureMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingCharacterWritesCompanion copyWith({
    Value<String>? characterId,
    Value<String>? ownerId,
    Value<String>? kind,
    Value<String>? targetId,
    Value<String>? payload,
    Value<DateTime>? queuedAt,
    Value<int>? failureCount,
    Value<bool>? abandoned,
    Value<String?>? lastFailureMessage,
    Value<int>? rowid,
  }) {
    return PendingCharacterWritesCompanion(
      characterId: characterId ?? this.characterId,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      targetId: targetId ?? this.targetId,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
      failureCount: failureCount ?? this.failureCount,
      abandoned: abandoned ?? this.abandoned,
      lastFailureMessage: lastFailureMessage ?? this.lastFailureMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (failureCount.present) {
      map['failure_count'] = Variable<int>(failureCount.value);
    }
    if (abandoned.present) {
      map['abandoned'] = Variable<bool>(abandoned.value);
    }
    if (lastFailureMessage.present) {
      map['last_failure_message'] = Variable<String>(lastFailureMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingCharacterWritesCompanion(')
          ..write('characterId: $characterId, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('failureCount: $failureCount, ')
          ..write('abandoned: $abandoned, ')
          ..write('lastFailureMessage: $lastFailureMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncAlertsTable extends SyncAlerts
    with TableInfo<$SyncAlertsTable, SyncAlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncAlertsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterNameMeta = const VerificationMeta(
    'characterName',
  );
  @override
  late final GeneratedColumn<String> characterName = GeneratedColumn<String>(
    'character_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataKindMeta = const VerificationMeta(
    'dataKind',
  );
  @override
  late final GeneratedColumn<String> dataKind = GeneratedColumn<String>(
    'data_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverValueMeta = const VerificationMeta(
    'serverValue',
  );
  @override
  late final GeneratedColumn<String> serverValue = GeneratedColumn<String>(
    'server_value',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    kind,
    characterId,
    characterName,
    dataKind,
    serverValue,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncAlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('character_name')) {
      context.handle(
        _characterNameMeta,
        characterName.isAcceptableOrUnknown(
          data['character_name']!,
          _characterNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterNameMeta);
    }
    if (data.containsKey('data_kind')) {
      context.handle(
        _dataKindMeta,
        dataKind.isAcceptableOrUnknown(data['data_kind']!, _dataKindMeta),
      );
    } else if (isInserting) {
      context.missing(_dataKindMeta);
    }
    if (data.containsKey('server_value')) {
      context.handle(
        _serverValueMeta,
        serverValue.isAcceptableOrUnknown(
          data['server_value']!,
          _serverValueMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncAlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncAlertRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      characterName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_name'],
      )!,
      dataKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_kind'],
      )!,
      serverValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_value'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncAlertsTable createAlias(String alias) {
    return $SyncAlertsTable(attachedDatabase, alias);
  }
}

class SyncAlertRow extends DataClass implements Insertable<SyncAlertRow> {
  final int id;
  final String ownerId;

  /// `'abandon'` ou `'conflict'` — voir `SyncAlertKind`.
  final String kind;
  final String characterId;
  final String characterName;
  final String dataKind;
  final String? serverValue;
  final DateTime createdAt;
  const SyncAlertRow({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.characterId,
    required this.characterName,
    required this.dataKind,
    this.serverValue,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['kind'] = Variable<String>(kind);
    map['character_id'] = Variable<String>(characterId);
    map['character_name'] = Variable<String>(characterName);
    map['data_kind'] = Variable<String>(dataKind);
    if (!nullToAbsent || serverValue != null) {
      map['server_value'] = Variable<String>(serverValue);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncAlertsCompanion toCompanion(bool nullToAbsent) {
    return SyncAlertsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      kind: Value(kind),
      characterId: Value(characterId),
      characterName: Value(characterName),
      dataKind: Value(dataKind),
      serverValue: serverValue == null && nullToAbsent
          ? const Value.absent()
          : Value(serverValue),
      createdAt: Value(createdAt),
    );
  }

  factory SyncAlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncAlertRow(
      id: serializer.fromJson<int>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      kind: serializer.fromJson<String>(json['kind']),
      characterId: serializer.fromJson<String>(json['characterId']),
      characterName: serializer.fromJson<String>(json['characterName']),
      dataKind: serializer.fromJson<String>(json['dataKind']),
      serverValue: serializer.fromJson<String?>(json['serverValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'kind': serializer.toJson<String>(kind),
      'characterId': serializer.toJson<String>(characterId),
      'characterName': serializer.toJson<String>(characterName),
      'dataKind': serializer.toJson<String>(dataKind),
      'serverValue': serializer.toJson<String?>(serverValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncAlertRow copyWith({
    int? id,
    String? ownerId,
    String? kind,
    String? characterId,
    String? characterName,
    String? dataKind,
    Value<String?> serverValue = const Value.absent(),
    DateTime? createdAt,
  }) => SyncAlertRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    kind: kind ?? this.kind,
    characterId: characterId ?? this.characterId,
    characterName: characterName ?? this.characterName,
    dataKind: dataKind ?? this.dataKind,
    serverValue: serverValue.present ? serverValue.value : this.serverValue,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncAlertRow copyWithCompanion(SyncAlertsCompanion data) {
    return SyncAlertRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      characterName: data.characterName.present
          ? data.characterName.value
          : this.characterName,
      dataKind: data.dataKind.present ? data.dataKind.value : this.dataKind,
      serverValue: data.serverValue.present
          ? data.serverValue.value
          : this.serverValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncAlertRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('characterId: $characterId, ')
          ..write('characterName: $characterName, ')
          ..write('dataKind: $dataKind, ')
          ..write('serverValue: $serverValue, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    kind,
    characterId,
    characterName,
    dataKind,
    serverValue,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncAlertRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.kind == this.kind &&
          other.characterId == this.characterId &&
          other.characterName == this.characterName &&
          other.dataKind == this.dataKind &&
          other.serverValue == this.serverValue &&
          other.createdAt == this.createdAt);
}

class SyncAlertsCompanion extends UpdateCompanion<SyncAlertRow> {
  final Value<int> id;
  final Value<String> ownerId;
  final Value<String> kind;
  final Value<String> characterId;
  final Value<String> characterName;
  final Value<String> dataKind;
  final Value<String?> serverValue;
  final Value<DateTime> createdAt;
  const SyncAlertsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.characterId = const Value.absent(),
    this.characterName = const Value.absent(),
    this.dataKind = const Value.absent(),
    this.serverValue = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncAlertsCompanion.insert({
    this.id = const Value.absent(),
    required String ownerId,
    required String kind,
    required String characterId,
    required String characterName,
    required String dataKind,
    this.serverValue = const Value.absent(),
    required DateTime createdAt,
  }) : ownerId = Value(ownerId),
       kind = Value(kind),
       characterId = Value(characterId),
       characterName = Value(characterName),
       dataKind = Value(dataKind),
       createdAt = Value(createdAt);
  static Insertable<SyncAlertRow> custom({
    Expression<int>? id,
    Expression<String>? ownerId,
    Expression<String>? kind,
    Expression<String>? characterId,
    Expression<String>? characterName,
    Expression<String>? dataKind,
    Expression<String>? serverValue,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (kind != null) 'kind': kind,
      if (characterId != null) 'character_id': characterId,
      if (characterName != null) 'character_name': characterName,
      if (dataKind != null) 'data_kind': dataKind,
      if (serverValue != null) 'server_value': serverValue,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncAlertsCompanion copyWith({
    Value<int>? id,
    Value<String>? ownerId,
    Value<String>? kind,
    Value<String>? characterId,
    Value<String>? characterName,
    Value<String>? dataKind,
    Value<String?>? serverValue,
    Value<DateTime>? createdAt,
  }) {
    return SyncAlertsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      dataKind: dataKind ?? this.dataKind,
      serverValue: serverValue ?? this.serverValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (characterName.present) {
      map['character_name'] = Variable<String>(characterName.value);
    }
    if (dataKind.present) {
      map['data_kind'] = Variable<String>(dataKind.value);
    }
    if (serverValue.present) {
      map['server_value'] = Variable<String>(serverValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncAlertsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('characterId: $characterId, ')
          ..write('characterName: $characterName, ')
          ..write('dataKind: $dataKind, ')
          ..write('serverValue: $serverValue, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>(
        'last_successful_sync_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [ownerId, lastSuccessfulSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
        _lastSuccessfulSyncAtMeta,
        lastSuccessfulSyncAt.isAcceptableOrUnknown(
          data['last_successful_sync_at']!,
          _lastSuccessfulSyncAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSuccessfulSyncAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  SyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncState(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_sync_at'],
      )!,
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncState extends DataClass implements Insertable<SyncState> {
  final String ownerId;
  final DateTime lastSuccessfulSyncAt;
  const SyncState({required this.ownerId, required this.lastSuccessfulSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      ownerId: Value(ownerId),
      lastSuccessfulSyncAt: Value(lastSuccessfulSyncAt),
    );
  }

  factory SyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncState(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime>(
        json['lastSuccessfulSyncAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime>(lastSuccessfulSyncAt),
    };
  }

  SyncState copyWith({String? ownerId, DateTime? lastSuccessfulSyncAt}) =>
      SyncState(
        ownerId: ownerId ?? this.ownerId,
        lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      );
  SyncState copyWithCompanion(SyncStatesCompanion data) {
    return SyncState(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncState(')
          ..write('ownerId: $ownerId, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ownerId, lastSuccessfulSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncState &&
          other.ownerId == this.ownerId &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt);
}

class SyncStatesCompanion extends UpdateCompanion<SyncState> {
  final Value<String> ownerId;
  final Value<DateTime> lastSuccessfulSyncAt;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.ownerId = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String ownerId,
    required DateTime lastSuccessfulSyncAt,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       lastSuccessfulSyncAt = Value(lastSuccessfulSyncAt);
  static Insertable<SyncState> custom({
    Expression<String>? ownerId,
    Expression<DateTime>? lastSuccessfulSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith({
    Value<String>? ownerId,
    Value<DateTime>? lastSuccessfulSyncAt,
    Value<int>? rowid,
  }) {
    return SyncStatesCompanion(
      ownerId: ownerId ?? this.ownerId,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] = Variable<DateTime>(
        lastSuccessfulSyncAt.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedReferenceEntriesTable cachedReferenceEntries =
      $CachedReferenceEntriesTable(this);
  late final $PendingCharacterWritesTable pendingCharacterWrites =
      $PendingCharacterWritesTable(this);
  late final $SyncAlertsTable syncAlerts = $SyncAlertsTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedReferenceEntries,
    pendingCharacterWrites,
    syncAlerts,
    syncStates,
  ];
}

typedef $$CachedReferenceEntriesTableCreateCompanionBuilder =
    CachedReferenceEntriesCompanion Function({
      required String key,
      required String payload,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedReferenceEntriesTableUpdateCompanionBuilder =
    CachedReferenceEntriesCompanion Function({
      Value<String> key,
      Value<String> payload,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedReferenceEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedReferenceEntriesTable> {
  $$CachedReferenceEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedReferenceEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedReferenceEntriesTable> {
  $$CachedReferenceEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedReferenceEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedReferenceEntriesTable> {
  $$CachedReferenceEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedReferenceEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedReferenceEntriesTable,
          CachedReferenceEntry,
          $$CachedReferenceEntriesTableFilterComposer,
          $$CachedReferenceEntriesTableOrderingComposer,
          $$CachedReferenceEntriesTableAnnotationComposer,
          $$CachedReferenceEntriesTableCreateCompanionBuilder,
          $$CachedReferenceEntriesTableUpdateCompanionBuilder,
          (
            CachedReferenceEntry,
            BaseReferences<
              _$AppDatabase,
              $CachedReferenceEntriesTable,
              CachedReferenceEntry
            >,
          ),
          CachedReferenceEntry,
          PrefetchHooks Function()
        > {
  $$CachedReferenceEntriesTableTableManager(
    _$AppDatabase db,
    $CachedReferenceEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedReferenceEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedReferenceEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedReferenceEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedReferenceEntriesCompanion(
                key: key,
                payload: payload,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String payload,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedReferenceEntriesCompanion.insert(
                key: key,
                payload: payload,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedReferenceEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedReferenceEntriesTable,
      CachedReferenceEntry,
      $$CachedReferenceEntriesTableFilterComposer,
      $$CachedReferenceEntriesTableOrderingComposer,
      $$CachedReferenceEntriesTableAnnotationComposer,
      $$CachedReferenceEntriesTableCreateCompanionBuilder,
      $$CachedReferenceEntriesTableUpdateCompanionBuilder,
      (
        CachedReferenceEntry,
        BaseReferences<
          _$AppDatabase,
          $CachedReferenceEntriesTable,
          CachedReferenceEntry
        >,
      ),
      CachedReferenceEntry,
      PrefetchHooks Function()
    >;
typedef $$PendingCharacterWritesTableCreateCompanionBuilder =
    PendingCharacterWritesCompanion Function({
      required String characterId,
      required String ownerId,
      required String kind,
      Value<String> targetId,
      required String payload,
      required DateTime queuedAt,
      Value<int> failureCount,
      Value<bool> abandoned,
      Value<String?> lastFailureMessage,
      Value<int> rowid,
    });
typedef $$PendingCharacterWritesTableUpdateCompanionBuilder =
    PendingCharacterWritesCompanion Function({
      Value<String> characterId,
      Value<String> ownerId,
      Value<String> kind,
      Value<String> targetId,
      Value<String> payload,
      Value<DateTime> queuedAt,
      Value<int> failureCount,
      Value<bool> abandoned,
      Value<String?> lastFailureMessage,
      Value<int> rowid,
    });

class $$PendingCharacterWritesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingCharacterWritesTable> {
  $$PendingCharacterWritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get abandoned => $composableBuilder(
    column: $table.abandoned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFailureMessage => $composableBuilder(
    column: $table.lastFailureMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingCharacterWritesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingCharacterWritesTable> {
  $$PendingCharacterWritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get abandoned => $composableBuilder(
    column: $table.abandoned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFailureMessage => $composableBuilder(
    column: $table.lastFailureMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingCharacterWritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingCharacterWritesTable> {
  $$PendingCharacterWritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get abandoned =>
      $composableBuilder(column: $table.abandoned, builder: (column) => column);

  GeneratedColumn<String> get lastFailureMessage => $composableBuilder(
    column: $table.lastFailureMessage,
    builder: (column) => column,
  );
}

class $$PendingCharacterWritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingCharacterWritesTable,
          PendingCharacterWrite,
          $$PendingCharacterWritesTableFilterComposer,
          $$PendingCharacterWritesTableOrderingComposer,
          $$PendingCharacterWritesTableAnnotationComposer,
          $$PendingCharacterWritesTableCreateCompanionBuilder,
          $$PendingCharacterWritesTableUpdateCompanionBuilder,
          (
            PendingCharacterWrite,
            BaseReferences<
              _$AppDatabase,
              $PendingCharacterWritesTable,
              PendingCharacterWrite
            >,
          ),
          PendingCharacterWrite,
          PrefetchHooks Function()
        > {
  $$PendingCharacterWritesTableTableManager(
    _$AppDatabase db,
    $PendingCharacterWritesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingCharacterWritesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingCharacterWritesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingCharacterWritesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> characterId = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> failureCount = const Value.absent(),
                Value<bool> abandoned = const Value.absent(),
                Value<String?> lastFailureMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingCharacterWritesCompanion(
                characterId: characterId,
                ownerId: ownerId,
                kind: kind,
                targetId: targetId,
                payload: payload,
                queuedAt: queuedAt,
                failureCount: failureCount,
                abandoned: abandoned,
                lastFailureMessage: lastFailureMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String characterId,
                required String ownerId,
                required String kind,
                Value<String> targetId = const Value.absent(),
                required String payload,
                required DateTime queuedAt,
                Value<int> failureCount = const Value.absent(),
                Value<bool> abandoned = const Value.absent(),
                Value<String?> lastFailureMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingCharacterWritesCompanion.insert(
                characterId: characterId,
                ownerId: ownerId,
                kind: kind,
                targetId: targetId,
                payload: payload,
                queuedAt: queuedAt,
                failureCount: failureCount,
                abandoned: abandoned,
                lastFailureMessage: lastFailureMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingCharacterWritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingCharacterWritesTable,
      PendingCharacterWrite,
      $$PendingCharacterWritesTableFilterComposer,
      $$PendingCharacterWritesTableOrderingComposer,
      $$PendingCharacterWritesTableAnnotationComposer,
      $$PendingCharacterWritesTableCreateCompanionBuilder,
      $$PendingCharacterWritesTableUpdateCompanionBuilder,
      (
        PendingCharacterWrite,
        BaseReferences<
          _$AppDatabase,
          $PendingCharacterWritesTable,
          PendingCharacterWrite
        >,
      ),
      PendingCharacterWrite,
      PrefetchHooks Function()
    >;
typedef $$SyncAlertsTableCreateCompanionBuilder = SyncAlertsCompanion Function({
  Value<int> id,
  required String ownerId,
  required String kind,
  required String characterId,
  required String characterName,
  required String dataKind,
  Value<String?> serverValue,
  required DateTime createdAt,
});
typedef $$SyncAlertsTableUpdateCompanionBuilder = SyncAlertsCompanion Function({
  Value<int> id,
  Value<String> ownerId,
  Value<String> kind,
  Value<String> characterId,
  Value<String> characterName,
  Value<String> dataKind,
  Value<String?> serverValue,
  Value<DateTime> createdAt,
});

class $$SyncAlertsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncAlertsTable> {
  $$SyncAlertsTableFilterComposer({
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

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterName => $composableBuilder(
    column: $table.characterName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataKind => $composableBuilder(
    column: $table.dataKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverValue => $composableBuilder(
    column: $table.serverValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncAlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncAlertsTable> {
  $$SyncAlertsTableOrderingComposer({
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

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterName => $composableBuilder(
    column: $table.characterName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataKind => $composableBuilder(
    column: $table.dataKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverValue => $composableBuilder(
    column: $table.serverValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncAlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncAlertsTable> {
  $$SyncAlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get characterName => $composableBuilder(
    column: $table.characterName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataKind =>
      $composableBuilder(column: $table.dataKind, builder: (column) => column);

  GeneratedColumn<String> get serverValue => $composableBuilder(
    column: $table.serverValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncAlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncAlertsTable,
          SyncAlertRow,
          $$SyncAlertsTableFilterComposer,
          $$SyncAlertsTableOrderingComposer,
          $$SyncAlertsTableAnnotationComposer,
          $$SyncAlertsTableCreateCompanionBuilder,
          $$SyncAlertsTableUpdateCompanionBuilder,
          (
            SyncAlertRow,
            BaseReferences<_$AppDatabase, $SyncAlertsTable, SyncAlertRow>,
          ),
          SyncAlertRow,
          PrefetchHooks Function()
        > {
  $$SyncAlertsTableTableManager(_$AppDatabase db, $SyncAlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncAlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncAlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncAlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> characterName = const Value.absent(),
                Value<String> dataKind = const Value.absent(),
                Value<String?> serverValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncAlertsCompanion(
                id: id,
                ownerId: ownerId,
                kind: kind,
                characterId: characterId,
                characterName: characterName,
                dataKind: dataKind,
                serverValue: serverValue,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ownerId,
                required String kind,
                required String characterId,
                required String characterName,
                required String dataKind,
                Value<String?> serverValue = const Value.absent(),
                required DateTime createdAt,
              }) => SyncAlertsCompanion.insert(
                id: id,
                ownerId: ownerId,
                kind: kind,
                characterId: characterId,
                characterName: characterName,
                dataKind: dataKind,
                serverValue: serverValue,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncAlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncAlertsTable,
      SyncAlertRow,
      $$SyncAlertsTableFilterComposer,
      $$SyncAlertsTableOrderingComposer,
      $$SyncAlertsTableAnnotationComposer,
      $$SyncAlertsTableCreateCompanionBuilder,
      $$SyncAlertsTableUpdateCompanionBuilder,
      (
        SyncAlertRow,
        BaseReferences<_$AppDatabase, $SyncAlertsTable, SyncAlertRow>,
      ),
      SyncAlertRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStatesTableCreateCompanionBuilder = SyncStatesCompanion Function({
  required String ownerId,
  required DateTime lastSuccessfulSyncAt,
  Value<int> rowid,
});
typedef $$SyncStatesTableUpdateCompanionBuilder = SyncStatesCompanion Function({
  Value<String> ownerId,
  Value<DateTime> lastSuccessfulSyncAt,
  Value<int> rowid,
});

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => column,
  );
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatesTable,
          SyncState,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (
            SyncState,
            BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>,
          ),
          SyncState,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<DateTime> lastSuccessfulSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion(
                ownerId: ownerId,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required DateTime lastSuccessfulSyncAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion.insert(
                ownerId: ownerId,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatesTable,
      SyncState,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (SyncState, BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>),
      SyncState,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedReferenceEntriesTableTableManager get cachedReferenceEntries =>
      $$CachedReferenceEntriesTableTableManager(
        _db,
        _db.cachedReferenceEntries,
      );
  $$PendingCharacterWritesTableTableManager get pendingCharacterWrites =>
      $$PendingCharacterWritesTableTableManager(
        _db,
        _db.pendingCharacterWrites,
      );
  $$SyncAlertsTableTableManager get syncAlerts =>
      $$SyncAlertsTableTableManager(_db, _db.syncAlerts);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
}
