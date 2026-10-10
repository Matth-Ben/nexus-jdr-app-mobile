import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/character_repository.dart';
import '../../data/pending_character_write_syncer.dart';
import '../../data/racial_innate_spell_repository.dart';
import '../../data/warlock_pact_spell_repository.dart';
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

/// Lectures de référence de la faveur de pacte de l'Occultiste (sorts mineurs
/// du Livre des ombres, Appel de familier) — voir
/// `WarlockPactSpellRepository`.
@Riverpod(keepAlive: true)
WarlockPactSpellRepository warlockPactSpellRepository(Ref ref) {
  return SupabaseWarlockPactSpellRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(referenceDataCacheProvider),
  );
}

/// Lecture de référence des sorts innés raciaux (`racial_innate_spells`,
/// lignes sans choix de lignée) — voir `RacialInnateSpellRepository`.
@Riverpod(keepAlive: true)
RacialInnateSpellRepository racialInnateSpellRepository(Ref ref) {
  return SupabaseRacialInnateSpellRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(referenceDataCacheProvider),
  );
}

/// Vide, best-effort, la file d'attente hors-ligne (PV/XP/sorts/aptitudes/
/// repos, D11) — voir `PendingCharacterWriteSyncer`. Seul consommateur :
/// `character_write_sync_coordinator.dart` (déclenche [sync] au démarrage et
/// à chaque retour de connectivité).
///
/// Construit sa propre instance de `SupabaseCharacterRepository` (plutôt que
/// `ref.watch(characterRepositoryProvider)`, typé `CharacterRepository`
/// abstrait) : `PendingCharacterWriteSyncer` a besoin du type CONCRET pour
/// `applyRestOnline` (voir sa doc de classe), jamais exposé par
/// l'abstraction. Instance distincte de celle de [characterRepository],
/// sans conséquence — voir la doc de classe de `SupabaseCharacterRepository
/// ._pendingWriteSyncer`.
@Riverpod(keepAlive: true)
PendingCharacterWriteSyncer pendingCharacterWriteSyncer(Ref ref) {
  return PendingCharacterWriteSyncer(
    ref.watch(supabaseClientProvider),
    ref.watch(pendingCharacterWriteQueueProvider),
    ref.watch(referenceDataCacheProvider),
    SupabaseCharacterRepository(
      ref.watch(supabaseClientProvider),
      ref.watch(referenceDataCacheProvider),
      ref.watch(pendingCharacterWriteQueueProvider),
      ref.watch(connectivityCheckerProvider),
    ),
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
