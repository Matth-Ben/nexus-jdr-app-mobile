import 'dart:convert';

import 'app_database.dart';

/// Petite abstraction de lecture/écriture au-dessus du DAO drift généré
/// (`AppDatabase`/`CachedReferenceEntries`) : encode/décode le payload JSON,
/// pour que les repositories appelants (ex.
/// `SupabaseCharacterCreationRepository`) n'aient jamais à connaître le
/// détail de la table drift sous-jacente — voir la doc de classe de
/// [CachedReferenceEntries] pour le rationale d'une seule table générique.
///
/// Testable indépendamment de tout repository, avec une base drift en
/// mémoire (`NativeDatabase.memory()`) plutôt qu'un vrai fichier disque —
/// voir `test/core/cache/reference_data_cache_test.dart`.
class ReferenceDataCache {
  const ReferenceDataCache(this._db);

  final AppDatabase _db;

  /// Upsert : une [key] déjà présente est remplacée. Pas d'historique, pas
  /// d'expiration (décision de la tâche qui a introduit ce cache : le
  /// volume de données de référence — dizaines de lignes par catalogue — ne
  /// justifie pas de gestion de taille).
  Future<void> put(String key, Object rawPayload) async {
    await _db
        .into(_db.cachedReferenceEntries)
        .insertOnConflictUpdate(
          CachedReferenceEntriesCompanion.insert(
            key: key,
            payload: jsonEncode(rawPayload),
            cachedAt: DateTime.now(),
          ),
        );
  }

  /// `null` si [key] n'a jamais été mise en cache.
  Future<Object?> get(String key) async {
    final row = await (_db.select(
      _db.cachedReferenceEntries,
    )..where((row) => row.key.equals(key))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return jsonDecode(row.payload);
  }
}
