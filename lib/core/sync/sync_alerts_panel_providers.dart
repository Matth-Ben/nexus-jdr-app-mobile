import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/characters/presentation/providers/character_providers.dart';
import '../cache/cache_providers.dart';
import '../cache/sync_alert_store.dart';
import 'sync_status_providers.dart';

part 'sync_alerts_panel_providers.g.dart';

/// Tri du panneau des alertes : la plus récente d'abord (`createdAt`
/// décroissant), puis `id` décroissant pour départager deux alertes de même
/// instant. Pure.
List<SyncAlert> sortSyncAlertsNewestFirst(List<SyncAlert> alerts) {
  final sorted = [...alerts];
  sorted.sort((a, b) {
    final byDate = b.createdAt.compareTo(a.createdAt);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  });
  return sorted;
}

/// Alertes de synchro du compte connecté **triées** pour le panneau (plus
/// récente d'abord). Distinct de `syncAlertsProvider` (ordre d'insertion),
/// qui sert le moteur du bandeau. Lecture locale seule (drift), jamais de
/// réseau.
@riverpod
Stream<List<SyncAlert>> sortedSyncAlerts(Ref ref) {
  final ownerId = ref.watch(syncOwnerIdProvider);
  if (ownerId == null) return Stream.value(const <SyncAlert>[]);
  return ref
      .watch(syncAlertStoreProvider)
      .watchForOwner(ownerId)
      .map(sortSyncAlertsNewestFirst);
}

/// Identifiants des personnages de la liste **déjà chargée**, ou `null` tant
/// qu'on ne sait pas (liste jamais chargée, en chargement initial ou en
/// erreur) : une alerte n'est « orpheline » que si cet ensemble est connu et
/// ne la contient pas — jamais de faux positif pendant le chargement.
///
/// Ne déclenche jamais le chargement de la liste (le panneau ne fait aucun
/// appel réseau) : si `charactersProvider` n'est pas déjà vivant (écran
/// liste sous la feuille, ouverte depuis la liste, la fiche ou le Profil), la
/// réponse est « inconnu ».
@riverpod
Set<String>? knownCharacterIds(Ref ref) {
  if (!ref.exists(charactersProvider)) return null;
  final characters = ref.watch(charactersProvider).value;
  if (characters == null) return null;
  return {for (final c in characters) c.id};
}
