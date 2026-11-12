import 'dart:async';

import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/reference_data_cache.dart';
import '../../../core/network/connectivity_checker.dart';
import '../domain/character_summary.dart';
import 'character_detail_cache.dart';

/// Précharge en arrière-plan la fiche des personnages « en jeu » dans le cache
/// de `SupabaseCharacterRepository.fetchCharacterDetail`, pour qu'une fiche
/// jamais ouverte sur l'appareil reste consultable hors ligne (V5-5, décision
/// « cache »).
///
/// Ne fait que **rejouer l'ouverture d'une fiche** ([fetchDetail] est
/// `fetchCharacterDetail`) : mêmes requêtes, donc même RLS, aucune nouvelle
/// table, et c'est le dépôt lui-même qui écrit le cache (scopé par `ownerId`).
/// Aucune file hors ligne n'est touchée, aucun état n'est exposé à l'UI.
///
/// Garde-fous :
/// - jamais hors ligne (vérifié avant chaque fiche) ;
/// - au plus [concurrency] fiches à la fois ;
/// - une fiche en cache plus récente que [freshness] n'est pas retéléchargée
///   (le retour sur la liste ne relance donc pas tout) ;
/// - une fiche ayant des écritures en attente est ignorée : rafraîchir le
///   cache effacerait la base de comparaison de la détection de modification
///   concurrente (F19/D178), qui lit les PV du cache ;
/// - annulable ([isCancelled]) et lié au compte : si le compte courant n'est
///   plus celui du départ, plus aucune fiche n'est demandée ;
/// - une fiche en échec n'empêche pas les suivantes, et aucune erreur n'est
///   remontée ni journalisée.
class CharacterDetailPrefetcher {
  CharacterDetailPrefetcher({
    required this.cache,
    required this.pendingWrites,
    required this.connectivity,
    required this.currentOwnerId,
    required this.fetchDetail,
    this.concurrency = 2,
    this.maxCharacters = 10,
    this.freshness = const Duration(minutes: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ReferenceDataCache cache;
  final PendingCharacterWriteQueue pendingWrites;
  final ConnectivityChecker connectivity;
  final String? Function() currentOwnerId;
  final Future<void> Function(String characterId) fetchDetail;
  final DateTime Function() _now;

  /// Nombre maximal de fiches téléchargées simultanément.
  final int concurrency;

  /// Nombre maximal de fiches préchargées par passage (coût borné).
  final int maxCharacters;

  /// Âge en deçà duquel une fiche en cache est considérée à jour.
  final Duration freshness;

  /// Personnages à précharger parmi [characters] : en jeu seulement (ni
  /// morts, ni archivés), dans l'ordre reçu.
  ///
  /// Au plus [maxCharacters] fiches : d'abord la dernière ouverte
  /// ([lastOpened] : `{characterId: epochMs}`, plus récent en premier), puis
  /// l'ordre de la liste (tri stable) — borne le coût à
  /// `maxCharacters × (10 à 23 requêtes)`.
  List<String> eligibleIds(
    List<CharacterSummary> characters, {
    Map<String, int> lastOpened = const {},
  }) {
    final ids = [
      for (final character in characters)
        if (!character.isDead && !character.isArchived) character.id,
    ];
    final indexed = ids.asMap().entries.toList()
      ..sort((a, b) {
        final byOpened = (lastOpened[b.value] ?? -1).compareTo(
          lastOpened[a.value] ?? -1,
        );
        return byOpened != 0 ? byOpened : a.key.compareTo(b.key);
      });
    return [for (final entry in indexed.take(maxCharacters)) entry.value];
  }

  /// Fiches en cours de téléchargement, partagées entre un préchargement
  /// annulé puis relancé (l'instance est unique) : jamais deux vols
  /// simultanés pour la même fiche.
  final Set<String> _inFlight = {};

  /// Précharge les fiches éligibles de [characters]. Ne lève jamais.
  Future<void> prefetch(
    List<CharacterSummary> characters, {
    required bool Function() isCancelled,
    Map<String, int> lastOpened = const {},
  }) async {
    try {
      final ownerId = currentOwnerId();
      if (ownerId == null) return;
      final queue = eligibleIds(characters, lastOpened: lastOpened);
      var next = 0;

      Future<void> worker() async {
        while (next < queue.length) {
          final characterId = queue[next++];
          if (_inFlight.contains(characterId)) continue;
          final decision = await _decide(ownerId, characterId, isCancelled);
          if (decision == _Decision.stop) return;
          if (decision == _Decision.skip) continue;
          // Réservé de façon synchrone avec la vérification ci-dessus : aucun
          // `await` entre les deux.
          if (!_inFlight.add(characterId)) continue;
          try {
            await fetchDetail(characterId);
          } catch (_) {
            // Une fiche en échec ne bloque pas les suivantes ; silencieux.
          } finally {
            _inFlight.remove(characterId);
          }
        }
      }

      await Future.wait([
        for (var i = 0; i < concurrency && i < queue.length; i++) worker(),
      ]);
    } catch (_) {
      // Best-effort : le préchargement ne doit jamais remonter d'erreur.
    }
  }

  /// [_Decision.stop] : arrêt de tout le préchargement (annulé, autre compte,
  /// hors ligne, lecture locale en erreur) ; [_Decision.skip] : seulement cette
  /// fiche (déjà fraîche, ou écritures en attente).
  Future<_Decision> _decide(
    String ownerId,
    String characterId,
    bool Function() isCancelled,
  ) async {
    try {
      if (isCancelled() || currentOwnerId() != ownerId) {
        return _Decision.stop;
      }
      if (!await connectivity.hasConnection()) return _Decision.stop;
      final cachedAt = await cache.cachedAt(
        CharacterDetailCache.keyFor(ownerId: ownerId, characterId: characterId),
      );
      if (cachedAt != null && _now().difference(cachedAt) < freshness) {
        return _Decision.skip;
      }
      final pending = await pendingWrites.forCharacter(
        ownerId: ownerId,
        characterId: characterId,
      );
      if (pending.isNotEmpty) return _Decision.skip;
      // Ré-vérifié après les lectures asynchrones ci-dessus.
      if (isCancelled() || currentOwnerId() != ownerId) {
        return _Decision.stop;
      }
      return _Decision.fetch;
    } catch (_) {
      return _Decision.stop;
    }
  }
}

enum _Decision { fetch, skip, stop }
