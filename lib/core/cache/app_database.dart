import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Table générique de cache clé/valeur pour les données de référence D&D
/// (races, classes, historiques, sorts, objets, compétences, outils,
/// langues — voir
/// `features/character_creation/data/character_creation_repository.dart`).
///
/// Une seule table plutôt que 8 tables spécifiques à chaque catalogue : ce
/// n'est qu'un cache JSON clé/valeur (les lignes brutes PostgREST déjà
/// destinées à repasser par le même mapper que le chemin réseau), jamais
/// interrogé localement avec des requêtes relationnelles complexes — le
/// volume de code relationnel dupliqué de 8 tables ne se justifierait pas
/// ici (décision de la tâche qui a introduit ce cache).
class CachedReferenceEntries extends Table {
  /// Ex. `'race_catalog'`, ou paramétré par `classId` pour les sorts :
  /// `'spell_catalog:12'` (voir `SupabaseCharacterCreationRepository
  /// .fetchSpellCatalog`).
  TextColumn get key => text()();

  /// `jsonEncode` d'une map structurée `{sousEnsemble: [lignes brutes...]}`
  /// — voir `ReferenceDataCache.put`.
  TextColumn get payload => text()();

  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Base SQLite locale de l'app (drift), pour l'instant dédiée au cache des
/// données de référence en lecture seule (voir [CachedReferenceEntries]) —
/// première persistance locale de ce dépôt (voir
/// `docs/cahier-des-charges/01-architecture-technique.md`, section "Mode
/// hors-ligne"). Un seul `AppDatabase` doit vivre pour toute la durée de
/// l'app, exposé par `appDatabaseProvider` (`keepAlive`,
/// `core/cache/cache_providers.dart`), jamais recréé par écran.
@DriftDatabase(tables: [CachedReferenceEntries])
class AppDatabase extends _$AppDatabase {
  /// [executor] injectable pour les tests (ex. `NativeDatabase.memory()`,
  /// jamais un vrai fichier disque dans `flutter test`) — sinon, ouvre le
  /// fichier SQLite réel du répertoire documents de l'app (voir
  /// [_openConnection]).
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(documentsDir.path, 'nexus_jdr_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
