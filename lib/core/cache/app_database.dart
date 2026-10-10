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

/// File d'attente de synchronisation hors-ligne pour `updateHp`/`addXp`
/// (`features/characters/data/character_repository.dart`) — voir
/// `docs/cahier-des-charges/01-architecture-technique.md`, section "Mode
/// hors-ligne". Table dédiée, séparée de [CachedReferenceEntries] : besoin
/// différent (écriture + file d'attente à vider, pas un cache clé/valeur en
/// lecture seule).
///
/// [characterId]/[kind] forment la clé primaire composite : une nouvelle
/// écriture en attente pour un même personnage/type **remplace** la
/// précédente (upsert, voir `PendingCharacterWriteQueue.enqueue`) plutôt que
/// de s'ajouter à une liste — `updateHp`/`addXp` écrivent déjà des valeurs
/// absolues, jamais des deltas, donc seule la toute dernière valeur en
/// attente a besoin d'être synchronisée un jour.
///
/// [ownerId] permet de ne jamais tenter de synchroniser une écriture en
/// attente qui n'appartient pas au joueur actuellement connecté (isolation
/// par utilisateur, même principe que la clé de cache scopée par `ownerId`
/// de [CachedReferenceEntries] côté lecture de la fiche — voir la doc de
/// classe de `SupabaseCharacterRepository`) : sur un appareil partagé, un
/// changement de compte ne doit jamais laisser une entrée en attente d'un
/// autre compte bloquée en boucle d'échec RLS silencieux.
///
/// [kind] vaut `'hp'` ou `'xp'`, [payload] est le JSON du payload à écrire
/// (`{"currentHp": ..., "temporaryHp": ...}` ou `{"newXp": ...}`) — voir
/// `PendingCharacterWriteKind`/`PendingCharacterWrite`
/// (`core/cache/pending_character_write_queue.dart`).
///
/// [failureCount]/[abandoned]/[lastFailureMessage] (schéma v3, D34 du
/// registre de dette technique) : une entrée refusée par le serveur de façon
/// non rejouable (contrainte, RLS) incrémente [failureCount] au lieu d'être
/// retentée indéfiniment ; au-delà du seuil
/// (`PendingCharacterWriteQueue.abandonAfterConsecutiveFailures`), [abandoned]
/// passe à `true` et [lastFailureMessage] porte le message à afficher au
/// joueur (voir `PendingCharacterWriteSyncer.sync`). Une entrée abandonnée
/// n'est plus relue par `forCharacter`/`allForOwner` (donc plus ni retentée,
/// ni superposée à la fiche) mais reste en base jusqu'à sa consommation par
/// `PendingCharacterWriteQueue.consumeAbandonedMessages` (affichage puis
/// suppression) — jamais perdue avant d'avoir été montrée.
class PendingCharacterWrites extends Table {
  TextColumn get characterId => text()();
  TextColumn get ownerId => text()();
  TextColumn get kind => text()();
  // Discriminant ajouté au schéma v4 (D11 du registre de dette technique) :
  // distingue plusieurs entrées `kind` en attente pour le même personnage
  // (ex. deux sorts différents lancés hors ligne) — voir
  // `PendingCharacterWrite.targetId` pour sa forme exacte selon le `kind`.
  // Chaîne vide (jamais nulle, colonne de clé primaire) pour `hp`/`xp`/
  // `rest`, qui n'en ont pas besoin — comportement inchangé pour ces trois
  // types par rapport au schéma v3.
  TextColumn get targetId => text().withDefault(const Constant(''))();
  TextColumn get payload => text()();
  // Sert de numéro de version de l'entrée, pas de date fiable : stocké à la
  // seconde, il avance d'au moins une seconde à chaque remplacement (voir
  // `PendingCharacterWriteQueue.enqueue`/`removeIfUnchanged`) et peut donc
  // se trouver dans le futur. Ne jamais l'utiliser pour trier ou faire
  // expirer des entrées. (Commentaire `//` et non `///` : `drift_dev` recopie
  // les commentaires de documentation des colonnes dans le code généré.)
  DateTimeColumn get queuedAt => dateTime()();
  // Refus non rejouables consécutifs (D34) — remis à zéro par `enqueue`
  // (nouvelle valeur saisie par le joueur = nouvelle tentative), jamais par
  // un échec réseau transitoire (voir `PendingCharacterWriteSyncer`).
  IntColumn get failureCount => integer().withDefault(const Constant(0))();
  BoolColumn get abandoned => boolean().withDefault(const Constant(false))();
  TextColumn get lastFailureMessage => text().nullable()();

  // Clé primaire élargie à `targetId` au schéma v4 (D11) : `(characterId,
  // kind)` seul ne suffisait plus à distinguer deux sorts/aptitudes
  // différents en attente pour le même personnage — voir
  // `AppDatabase.migration` pour la migration qui recrée cette table avec
  // cette nouvelle clé (SQLite ne permet pas de modifier une contrainte
  // PRIMARY KEY par un simple `ALTER TABLE`).
  @override
  Set<Column> get primaryKey => {characterId, kind, targetId};
}

/// Base SQLite locale de l'app (drift), pour l'instant dédiée au cache des
/// données de référence en lecture seule ([CachedReferenceEntries]) et à la
/// file de synchro hors-ligne PV/XP ([PendingCharacterWrites]) — première
/// persistance locale de ce dépôt (voir
/// `docs/cahier-des-charges/01-architecture-technique.md`, section "Mode
/// hors-ligne"). Un seul `AppDatabase` doit vivre pour toute la durée de
/// l'app, exposé par `appDatabaseProvider` (`keepAlive`,
/// `core/cache/cache_providers.dart`), jamais recréé par écran.
@DriftDatabase(tables: [CachedReferenceEntries, PendingCharacterWrites])
class AppDatabase extends _$AppDatabase {
  /// [executor] injectable pour les tests (ex. `NativeDatabase.memory()`,
  /// jamais un vrai fichier disque dans `flutter test`) — sinon, ouvre le
  /// fichier SQLite réel du répertoire documents de l'app (voir
  /// [_openConnection]).
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  // [PendingCharacterWrites] (schéma v2) a été ajoutée après la première
  // version livrée de ce cache (v1, [CachedReferenceEntries] seule) : une
  // stratégie de migration explicite évite qu'un appareil ayant déjà ouvert
  // la base en v1 ne se retrouve avec la nouvelle table manquante (un simple
  // bump de [schemaVersion] sans `onUpgrade` laisserait le schéma existant
  // tel quel, `drift` ne recréant le schéma complet qu'au tout premier
  // `onCreate`). [failureCount]/[abandoned]/[lastFailureMessage] (schéma v3,
  // D34) suivent le même principe : trois colonnes ajoutées à une table
  // existante plutôt qu'une nouvelle table, migration de v2 par `addColumn`.
  //
  // [targetId] (schéma v4, D11) est différent : il élargit la clé primaire
  // de `(characterId, kind)` à `(characterId, kind, targetId)`, pas une
  // simple colonne ajoutée à une contrainte inchangée. SQLite ne permet pas
  // de modifier une contrainte `PRIMARY KEY` par `ALTER TABLE` — la migration
  // v3 -> v4 recrée donc la table entière sous un nom temporaire, la
  // reconstruit avec le nouveau schéma (`m.createTable`, qui lit la
  // définition Dart courante — donc déjà la nouvelle clé primaire), recopie
  // les lignes existantes (`targetId` vide : `hp`/`xp` n'en ont jamais eu
  // besoin, voir [PendingCharacterWrites.targetId]) puis supprime la table
  // temporaire. Généré via `dart run build_runner build
  // --delete-conflicting-outputs` après ce changement, comme pour toute
  // modification de ce fichier.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(pendingCharacterWrites);
      }
      if (from < 3) {
        await m.addColumn(
          pendingCharacterWrites,
          pendingCharacterWrites.failureCount,
        );
        await m.addColumn(
          pendingCharacterWrites,
          pendingCharacterWrites.abandoned,
        );
        await m.addColumn(
          pendingCharacterWrites,
          pendingCharacterWrites.lastFailureMessage,
        );
      }
      if (from < 4) {
        // Transaction explicite (revue de code) : `onUpgrade` n'est jamais
        // enveloppée dans une transaction par `drift` lui-même — à la charge
        // du code de migration. Pour `NativeDatabase` (sqlite3),
        // `PRAGMA user_version` est fixé à la version cible AVANT que cette
        // fonction `onUpgrade` ne s'exécute, pas après son succès : si l'app
        // est tuée entre deux des quatre opérations ci-dessous (ex. juste
        // après le `RENAME`, avant que `createTable` ne recrée la table),
        // le fichier reste dans un état intermédiaire alors que
        // `user_version` est déjà à 4 — au redémarrage, `from == to == 4`,
        // cette migration ne serait donc plus jamais rejouée, perdant la
        // table pour toujours sur cet appareil (y compris les entrées
        // `hp`/`xp` qui fonctionnaient déjà avant ce changement). Une seule
        // transaction autour des quatre opérations garantit qu'elles
        // réussissent ou échouent ensemble (rollback complet sur tout échec,
        // y compris un arrêt brutal du processus).
        await m.database.transaction(() async {
          await m.database.customStatement(
            'ALTER TABLE pending_character_writes '
            'RENAME TO pending_character_writes_v3',
          );
          await m.createTable(pendingCharacterWrites);
          await m.database.customStatement(
            'INSERT INTO pending_character_writes '
            '(character_id, owner_id, kind, target_id, payload, queued_at, '
            'failure_count, abandoned, last_failure_message) '
            "SELECT character_id, owner_id, kind, '', payload, queued_at, "
            'failure_count, abandoned, last_failure_message '
            'FROM pending_character_writes_v3',
          );
          await m.database.customStatement(
            'DROP TABLE pending_character_writes_v3',
          );
        });
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(documentsDir.path, 'nexus_jdr_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
