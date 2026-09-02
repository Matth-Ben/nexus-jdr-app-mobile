import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/character_repository.dart';
import '../../data/pending_character_write_syncer.dart';
import '../../domain/character_summary.dart';
import '../../domain/inventory_catalog_item.dart';

part 'character_providers.g.dart';

@Riverpod(keepAlive: true)
CharacterRepository characterRepository(Ref ref) {
  return SupabaseCharacterRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(referenceDataCacheProvider),
    ref.watch(pendingCharacterWriteQueueProvider),
    ref.watch(connectivityCheckerProvider),
  );
}

/// Vide, best-effort, la file d'attente PV/XP hors-ligne — voir
/// `PendingCharacterWriteSyncer`. Seul consommateur :
/// `character_write_sync_coordinator.dart` (déclenche [sync] au démarrage et
/// à chaque retour de connectivité).
@Riverpod(keepAlive: true)
PendingCharacterWriteSyncer pendingCharacterWriteSyncer(Ref ref) {
  return PendingCharacterWriteSyncer(
    ref.watch(supabaseClientProvider),
    ref.watch(pendingCharacterWriteQueueProvider),
  );
}

/// Liste des personnages du joueur connecté, exposée à
/// `CharacterListScreen`.
///
/// Volontairement `autoDispose` (comportement par défaut du générateur) :
/// contrairement à l'état d'authentification, cette liste n'a pas besoin de
/// survivre à la fermeture de l'écran qui l'affiche. `ref.invalidate(
/// charactersProvider)` (bouton "Réessayer" de l'état d'erreur) relance un
/// nouvel appel.
///
/// `retry: null` désactive les tentatives automatiques en arrière-plan de
/// Riverpod 3 (comportement par défaut : relances illimitées avec backoff
/// exponentiel sur toute erreur) : l'écran expose déjà un bouton "Réessayer"
/// explicite pour l'état d'erreur, une relance automatique et silencieuse
/// masquerait une erreur persistante (ex. session expirée) derrière des
/// appels réseau répétés sans que le joueur en soit informé.
@Riverpod(retry: _noRetry)
Future<List<CharacterSummary>> characters(Ref ref) {
  return ref.watch(characterRepositoryProvider).fetchCharacters();
}

/// Catalogue complet des objets `items`, exposé aux sheets "Depuis le
/// catalogue" de l'onglet "Inventaire" (`presentation/widgets
/// /add_item_flow.dart`) — voir `CharacterRepository.fetchInventoryCatalog`.
///
/// `autoDispose` par défaut : ce catalogue n'a pas besoin de survivre à la
/// fermeture de la sheet qui l'affiche, même rationale que [characters].
@Riverpod(retry: _noRetry)
Future<List<InventoryCatalogItem>> inventoryCatalog(Ref ref) {
  return ref.watch(characterRepositoryProvider).fetchInventoryCatalog();
}

Duration? _noRetry(int retryCount, Object error) => null;
