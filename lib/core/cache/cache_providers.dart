import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';
import 'pending_character_write_queue.dart';
import 'reference_data_cache.dart';

part 'cache_providers.g.dart';

/// Connexion SQLite (drift) partagée par toute l'app — doit vivre toute la
/// durée de l'app, jamais recréée par écran, même rationale que
/// `supabaseClientProvider` (`core/network/supabase_client_provider.dart`).
/// Ferme la connexion à la destruction du provider (ne devrait normalement
/// jamais arriver hors test, `keepAlive`).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// Cache des données de référence (races, classes, historiques, sorts,
/// objets, compétences, outils, langues) consommé par
/// `SupabaseCharacterCreationRepository` — voir
/// `features/character_creation/presentation/providers/character_creation_providers.dart`.
@Riverpod(keepAlive: true)
ReferenceDataCache referenceDataCache(Ref ref) {
  return ReferenceDataCache(ref.watch(appDatabaseProvider));
}

/// File de synchro hors-ligne PV/XP (`PendingCharacterWrites`), consommée par
/// `SupabaseCharacterRepository`/`PendingCharacterWriteSyncer` — voir
/// `features/characters/presentation/providers/character_providers.dart`.
@Riverpod(keepAlive: true)
PendingCharacterWriteQueue pendingCharacterWriteQueue(Ref ref) {
  return PendingCharacterWriteQueue(ref.watch(appDatabaseProvider));
}
