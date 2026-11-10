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
