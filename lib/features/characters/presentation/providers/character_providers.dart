import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/character_detail_cache.dart';
import '../../data/character_detail_prefetcher.dart';
import '../../data/character_repository.dart';
import '../../data/pending_character_write_syncer.dart';
import '../../data/racial_innate_spell_repository.dart';
import '../../data/sync_alert_recorder.dart';
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
    syncState: ref.watch(syncStateStoreProvider),
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
Future<List<CharacterSummary>> characters(Ref ref) async {
  // Annule le préchargement ci-dessous dès que la liste n'est plus écoutée
  // (écran démonté) ou relancée (invalidation).
  var disposed = false;
  ref.onDispose(() => disposed = true);
  final list = await ref.watch(characterRepositoryProvider).fetchCharacters();
  // Préchargement des fiches pour le hors-ligne (V5-5) : en arrière-plan,
  // jamais attendu, jamais visible (la liste est déjà prête ci-dessous).
  unawaited(_prefetchDetails(ref, list, () => disposed));
  return list;
}

Future<void> _prefetchDetails(
  Ref ref,
  List<CharacterSummary> list,
  bool Function() isCancelled,
) async {
  try {
    // Laisse la liste s'afficher avant toute lecture locale ou réseau.
    await Future<void>.delayed(Duration.zero);
    if (isCancelled()) return;
    await ref
        .read(characterDetailPrefetcherProvider)
        .prefetch(list, isCancelled: isCancelled);
  } catch (_) {
    // Best-effort : jamais d'erreur visible ni journalisée.
  }
}

/// Préchargement en arrière-plan des fiches « en jeu » pour le hors-ligne —
/// voir `CharacterDetailPrefetcher`. Déclenché par [characters].
@Riverpod(keepAlive: true)
CharacterDetailPrefetcher characterDetailPrefetcher(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  final repository = ref.watch(characterRepositoryProvider);
  return CharacterDetailPrefetcher(
    cache: ref.watch(referenceDataCacheProvider),
    pendingWrites: ref.watch(pendingCharacterWriteQueueProvider),
    connectivity: ref.watch(connectivityCheckerProvider),
    currentOwnerId: () => client.auth.currentUser?.id,
    fetchDetail: repository.fetchCharacterDetail,
  );
}

/// Catalogue complet des objets `items`, exposé aux sheets "Depuis le
/// catalogue" de l'onglet "Inventaire" (`presentation/widgets
/// /add_item_flow.dart`) — voir `CharacterRepository.fetchInventoryCatalog`.
///
/// `autoDispose` par défaut : ce catalogue n'a pas besoin de survivre à la
/// fermeture de la sheet qui l'affiche, même rationale que [characters].
///
/// F20 : rechargé automatiquement au retour du réseau
/// (`ConnectivityChecker.onConnectivityRestored`) quand le dernier chargement a
/// échoué ou n'a pu se faire que depuis un cache périmé hors ligne — la sheet
/// d'ajout ne reste pas bloquée sur une erreur de catalogue. Chargé seulement
/// quand la sheet l'écoute (jamais au démarrage).
@Riverpod(retry: _noRetry)
Future<List<InventoryCatalogItem>> inventoryCatalog(Ref ref) async {
  final checker = ref.watch(connectivityCheckerProvider);
  var needsReload = false;
  // Surveillance du réseau best-effort : une erreur du canal de plateforme ne
  // doit jamais empêcher d'afficher le catalogue (ni remonter comme erreur
  // non gérée).
  final subscription = checker.onConnectivityRestored.listen((_) {
    if (needsReload) ref.invalidateSelf();
  }, onError: (_) {});
  ref.onDispose(subscription.cancel);
  try {
    final items = await ref
        .watch(characterRepositoryProvider)
        .fetchInventoryCatalog();
    // Servi hors ligne (cache périmé) : à recharger dès que le réseau revient.
    // Déterminé sans bloquer l'affichage du catalogue (best-effort).
    unawaited(
      checker
          .hasConnection()
          .then((connected) => needsReload = !connected)
          .catchError((_) => false),
    );
    return items;
  } catch (_) {
    needsReload = true;
    rethrow;
  }
}

Duration? _noRetry(int retryCount, Object error) => null;

/// Enregistre les abandons/conflits de synchro comme alertes persistées —
/// voir `SyncAlertRecorder`. Seul consommateur : le coordinateur de synchro.
@Riverpod(keepAlive: true)
SyncAlertRecorder syncAlertRecorder(Ref ref) {
  return SyncAlertRecorder(
    ref.watch(appDatabaseProvider),
    ref.watch(pendingCharacterWriteQueueProvider),
    ref.watch(syncAlertStoreProvider),
    CharacterDetailCache(ref.watch(referenceDataCacheProvider)),
  );
}
