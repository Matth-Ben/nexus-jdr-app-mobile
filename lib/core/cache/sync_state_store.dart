import 'app_database.dart';

/// Dernier échange réussi avec le serveur, par compte ([SyncStates]) : mis à
/// jour après un rejeu réussi de la file ET après une lecture serveur réussie
/// de la liste/fiche. Horloge injectable pour les tests.
class SyncStateStore {
  SyncStateStore(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Enregistre « maintenant » comme dernière synchro réussie de [ownerId].
  /// Best-effort : jamais d'exception (une erreur locale ne doit pas faire
  /// échouer la lecture ou la synchro qui l'appelle).
  Future<void> markSuccess(String ownerId) async {
    try {
      await _db
          .into(_db.syncStates)
          .insertOnConflictUpdate(
            SyncStatesCompanion.insert(
              ownerId: ownerId,
              lastSuccessfulSyncAt: _now(),
            ),
          );
    } catch (_) {
      // Best-effort — voir la documentation de cette méthode.
    }
  }

  Future<DateTime?> lastSuccess(String ownerId) async {
    final row = await (_db.select(
      _db.syncStates,
    )..where((r) => r.ownerId.equals(ownerId))).getSingleOrNull();
    return row?.lastSuccessfulSyncAt;
  }

  Stream<DateTime?> watchLastSuccess(String ownerId) {
    return (_db.select(_db.syncStates)..where((r) => r.ownerId.equals(ownerId)))
        .watchSingleOrNull()
        .map((row) => row?.lastSuccessfulSyncAt);
  }

  Future<void> removeAllForOwner(String ownerId) async {
    await (_db.delete(
      _db.syncStates,
    )..where((r) => r.ownerId.equals(ownerId))).go();
  }
}
