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

  /// `null` si [key] n'a jamais été mise en cache. Retourne l'entrée quel
  /// que soit son âge (contrairement à [getFresh]) — utilisé par la
  /// stratégie "réseau d'abord, cache en secours" de
  /// `SupabaseCharacterCreationRepository`, qui doit pouvoir retomber sur un
  /// cache périmé plutôt que sur rien du tout si le réseau échoue.
  Future<Object?> get(String key) async {
    final row = await _selectRow(key);
    if (row == null) {
      return null;
    }
    return jsonDecode(row.payload);
  }

  /// `null` si [key] n'a jamais été mise en cache **ou** si l'entrée
  /// existante a plus de [maxAge] (calculé par rapport à `DateTime.now()`) —
  /// utilisé par la stratégie "cache d'abord si frais" des catalogues de
  /// référence de `SupabaseCharacterCreationRepository` : une entrée fraîche
  /// évite tout appel réseau, une entrée absente ou périmée laisse
  /// l'appelant retomber sur son comportement réseau-d'abord habituel (voir
  /// [get] pour le repli sur un cache périmé en cas d'échec réseau).
  Future<Object?> getFresh(String key, {required Duration maxAge}) async {
    final row = await _selectRow(key);
    if (row == null) {
      return null;
    }
    final age = DateTime.now().difference(row.cachedAt);
    if (age > maxAge) {
      return null;
    }
    return jsonDecode(row.payload);
  }

  Future<CachedReferenceEntry?> _selectRow(String key) {
    return (_db.select(
      _db.cachedReferenceEntries,
    )..where((row) => row.key.equals(key))).getSingleOrNull();
  }
}
