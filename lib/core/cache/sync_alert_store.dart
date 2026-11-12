import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// Nature d'une [SyncAlert].
enum SyncAlertKind {
  /// Écriture hors-ligne abandonnée (refus non rejouable répété, D34) : la
  /// fiche affiche la valeur du serveur.
  abandon('abandon'),

  /// Modification concurrente (F19) : l'écriture en file a quand même été
  /// envoyée, par-dessus la valeur serveur.
  conflict('conflict');

  const SyncAlertKind(this.storageKey);

  final String storageKey;

  static SyncAlertKind? fromStorageKey(String value) {
    for (final kind in values) {
      if (kind.storageKey == value) return kind;
    }
    return null;
  }
}

/// Une ligne de [SyncAlerts] décodée.
class SyncAlert {
  const SyncAlert({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.characterId,
    required this.characterName,
    required this.dataKind,
    required this.serverValue,
    required this.createdAt,
  });

  final int id;
  final String ownerId;
  final SyncAlertKind kind;
  final String characterId;
  final String characterName;

  /// `PendingCharacterWriteKind.storageKey` de l'écriture concernée.
  final String dataKind;

  /// Valeur serveur connue (forme selon [dataKind], voir
  /// `SyncAlertFactory`), `null` si inconnue (texte de repli).
  final Map<String, dynamic>? serverValue;
  final DateTime createdAt;
}

/// Alertes de synchro persistées ([SyncAlerts]) : ajout, lecture observable
/// (la plus ancienne d'abord), fermeture (= suppression), purge par compte.
/// Toujours filtré par `ownerId` : sur un appareil partagé, un compte ne voit
/// jamais les alertes d'un autre.
class SyncAlertStore {
  SyncAlertStore(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<void> add({
    required String ownerId,
    required SyncAlertKind kind,
    required String characterId,
    required String characterName,
    required String dataKind,
    Map<String, dynamic>? serverValue,
  }) async {
    await _db
        .into(_db.syncAlerts)
        .insert(
          SyncAlertsCompanion.insert(
            ownerId: ownerId,
            kind: kind.storageKey,
            characterId: characterId,
            characterName: characterName,
            dataKind: dataKind,
            serverValue: Value(
              serverValue == null ? null : jsonEncode(serverValue),
            ),
            createdAt: _now(),
          ),
        );
  }

  /// Alerte de conflit **non fermée** (une alerte fermée est supprimée) la plus
  /// récente de [ownerId] pour ([characterId], [dataKind]), `null` si aucune.
  /// Sert au dédoublonnage de T8 : un nouveau conflit met cette alerte à jour
  /// au lieu d'en ajouter une.
  Future<SyncAlert?> findOpenConflict({
    required String ownerId,
    required String characterId,
    required String dataKind,
  }) async {
    final query = _db.select(_db.syncAlerts)
      ..where(
        (row) =>
            row.ownerId.equals(ownerId) &
            row.kind.equals(SyncAlertKind.conflict.storageKey) &
            row.characterId.equals(characterId) &
            row.dataKind.equals(dataKind),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.id)])
      ..limit(1);
    final alerts = _decode(await query.get());
    return alerts.isEmpty ? null : alerts.single;
  }

  /// Remplace le nom et la valeur de l'alerte [id] de [ownerId] (jamais celle
  /// d'un autre compte). L'`id` et la date sont conservés : l'alerte reste à
  /// sa place et n'est pas ré-annoncée.
  Future<void> updateValue({
    required String ownerId,
    required int id,
    required String characterName,
    required Map<String, dynamic>? serverValue,
  }) async {
    await (_db.update(
      _db.syncAlerts,
    )..where((row) => row.ownerId.equals(ownerId) & row.id.equals(id))).write(
      SyncAlertsCompanion(
        characterName: Value(characterName),
        serverValue: Value(
          serverValue == null ? null : jsonEncode(serverValue),
        ),
      ),
    );
  }

  /// Alertes de [ownerId], de la plus ancienne à la plus récente (l'`id`
  /// auto-incrémenté départage deux alertes de même seconde).
  Stream<List<SyncAlert>> watchForOwner(String ownerId) {
    final query = _db.select(_db.syncAlerts)
      ..where((row) => row.ownerId.equals(ownerId))
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    return query.watch().map(_decode);
  }

  Future<List<SyncAlert>> allForOwner(String ownerId) async {
    final query = _db.select(_db.syncAlerts)
      ..where((row) => row.ownerId.equals(ownerId))
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    return _decode(await query.get());
  }

  /// Ferme (supprime) l'alerte [id] de [ownerId] — jamais celle d'un autre
  /// compte, même si l'identifiant correspond.
  Future<void> dismiss({required String ownerId, required int id}) async {
    await (_db.delete(
      _db.syncAlerts,
    )..where((row) => row.ownerId.equals(ownerId) & row.id.equals(id))).go();
  }

  /// Ferme (supprime) toutes les alertes de [ownerId] et rend celles qui ont
  /// été supprimées (pour [restore] en cas d'annulation). Ne touche jamais aux
  /// écritures en attente.
  Future<List<SyncAlert>> dismissAll({required String ownerId}) async {
    // Transaction : une alerte ajoutée entre la lecture et la suppression ne
    // doit pas disparaître sans pouvoir être restaurée.
    return _db.transaction(() async {
      final removed = await allForOwner(ownerId);
      await removeAllForOwner(ownerId);
      return removed;
    });
  }

  /// Ré-insère [alert] avec son `id` et son `createdAt` d'origine (annulation
  /// d'un « Écarter »). La table est `AUTOINCREMENT` : l'`id` d'une ligne
  /// supprimée n'est jamais réattribué à une autre, la ré-insertion ne peut
  /// donc pas entrer en collision. Sans effet si l'`id` existe déjà.
  ///
  /// Règle de dédoublonnage de `SyncAlertRecorder` : un seul conflit ouvert par
  /// (compte, personnage, `dataKind`). Si un nouveau conflit a été enregistré
  /// depuis l'écartement, l'alerte restaurée serait périmée : on ne la
  /// ré-insère pas. Les abandons ne se dédoublonnent pas, ils sont toujours
  /// restaurés.
  Future<void> restore(SyncAlert alert) async {
    if (alert.kind == SyncAlertKind.conflict) {
      final open = await findOpenConflict(
        ownerId: alert.ownerId,
        characterId: alert.characterId,
        dataKind: alert.dataKind,
      );
      if (open != null && open.id != alert.id) return;
    }
    await _db
        .into(_db.syncAlerts)
        .insert(
          SyncAlertsCompanion.insert(
            id: Value(alert.id),
            ownerId: alert.ownerId,
            kind: alert.kind.storageKey,
            characterId: alert.characterId,
            characterName: alert.characterName,
            dataKind: alert.dataKind,
            serverValue: Value(
              alert.serverValue == null ? null : jsonEncode(alert.serverValue),
            ),
            createdAt: alert.createdAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// [restore] de toutes les [alerts] en une transaction : tout ou rien (une
  /// erreur n'en laisse pas la moitié restaurée).
  Future<void> restoreAll(List<SyncAlert> alerts) async {
    await _db.transaction(() async {
      for (final alert in alerts) {
        await restore(alert);
      }
    });
  }

  Future<void> removeAllForOwner(String ownerId) async {
    await (_db.delete(
      _db.syncAlerts,
    )..where((row) => row.ownerId.equals(ownerId))).go();
  }

  List<SyncAlert> _decode(List<SyncAlertRow> rows) {
    final alerts = <SyncAlert>[];
    for (final row in rows) {
      final kind = SyncAlertKind.fromStorageKey(row.kind);
      if (kind == null) continue;
      Map<String, dynamic>? serverValue;
      final raw = row.serverValue;
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) serverValue = Map<String, dynamic>.from(decoded);
        } catch (_) {
          serverValue = null;
        }
      }
      alerts.add(
        SyncAlert(
          id: row.id,
          ownerId: row.ownerId,
          kind: kind,
          characterId: row.characterId,
          characterName: row.characterName,
          dataKind: row.dataKind,
          serverValue: serverValue,
          createdAt: row.createdAt,
        ),
      );
    }
    return alerts;
  }
}
