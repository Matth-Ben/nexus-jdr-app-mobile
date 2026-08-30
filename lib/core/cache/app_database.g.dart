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
  @override
  List<GeneratedColumn> get $columns => [
    characterId,
    ownerId,
    kind,
    payload,
    queuedAt,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {characterId, kind};
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
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
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
  final String payload;
  final DateTime queuedAt;
  const PendingCharacterWrite({
    required this.characterId,
    required this.ownerId,
    required this.kind,
    required this.payload,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_id'] = Variable<String>(characterId);
    map['owner_id'] = Variable<String>(ownerId);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  PendingCharacterWritesCompanion toCompanion(bool nullToAbsent) {
    return PendingCharacterWritesCompanion(
      characterId: Value(characterId),
      ownerId: Value(ownerId),
      kind: Value(kind),
      payload: Value(payload),
      queuedAt: Value(queuedAt),
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
      payload: serializer.fromJson<String>(json['payload']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterId': serializer.toJson<String>(characterId),
      'ownerId': serializer.toJson<String>(ownerId),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  PendingCharacterWrite copyWith({
    String? characterId,
    String? ownerId,
    String? kind,
    String? payload,
    DateTime? queuedAt,
  }) => PendingCharacterWrite(
    characterId: characterId ?? this.characterId,
    ownerId: ownerId ?? this.ownerId,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    queuedAt: queuedAt ?? this.queuedAt,
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
      payload: data.payload.present ? data.payload.value : this.payload,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingCharacterWrite(')
          ..write('characterId: $characterId, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(characterId, ownerId, kind, payload, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingCharacterWrite &&
          other.characterId == this.characterId &&
          other.ownerId == this.ownerId &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.queuedAt == this.queuedAt);
}

class PendingCharacterWritesCompanion
    extends UpdateCompanion<PendingCharacterWrite> {
  final Value<String> characterId;
  final Value<String> ownerId;
  final Value<String> kind;
  final Value<String> payload;
  final Value<DateTime> queuedAt;
  final Value<int> rowid;
  const PendingCharacterWritesCompanion({
    this.characterId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingCharacterWritesCompanion.insert({
    required String characterId,
    required String ownerId,
    required String kind,
    required String payload,
    required DateTime queuedAt,
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
    Expression<String>? payload,
    Expression<DateTime>? queuedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (ownerId != null) 'owner_id': ownerId,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingCharacterWritesCompanion copyWith({
    Value<String>? characterId,
    Value<String>? ownerId,
    Value<String>? kind,
    Value<String>? payload,
    Value<DateTime>? queuedAt,
    Value<int>? rowid,
  }) {
    return PendingCharacterWritesCompanion(
      characterId: characterId ?? this.characterId,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
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
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
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
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt, ')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedReferenceEntries,
    pendingCharacterWrites,
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
      required String payload,
      required DateTime queuedAt,
      Value<int> rowid,
    });
typedef $$PendingCharacterWritesTableUpdateCompanionBuilder =
    PendingCharacterWritesCompanion Function({
      Value<String> characterId,
      Value<String> ownerId,
      Value<String> kind,
      Value<String> payload,
      Value<DateTime> queuedAt,
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
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

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
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
                Value<String> payload = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingCharacterWritesCompanion(
                characterId: characterId,
                ownerId: ownerId,
                kind: kind,
                payload: payload,
                queuedAt: queuedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String characterId,
                required String ownerId,
                required String kind,
                required String payload,
                required DateTime queuedAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingCharacterWritesCompanion.insert(
                characterId: characterId,
                ownerId: ownerId,
                kind: kind,
                payload: payload,
                queuedAt: queuedAt,
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
}
