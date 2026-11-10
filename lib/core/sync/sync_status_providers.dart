import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cache/cache_providers.dart';
import '../cache/sync_alert_store.dart';
import '../network/connectivity_providers.dart';
import '../network/supabase_client_provider.dart';
import 'sync_activity_provider.dart';
import 'sync_banner_engine.dart';

part 'sync_status_providers.g.dart';

/// Identifiant du compte connecté, ou `null` (pas de session, ou Supabase non
/// initialisé comme dans la plupart des tests de widgets) — jamais
/// d'exception. Surchargeable dans les tests.
@riverpod
String? syncOwnerId(Ref ref) {
  try {
    return ref.read(supabaseClientProvider).auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}

/// Alertes de synchro persistées du compte connecté, la plus ancienne
/// d'abord. Vide si personne n'est connecté.
@riverpod
Stream<List<SyncAlert>> syncAlerts(Ref ref) {
  final ownerId = ref.watch(syncOwnerIdProvider);
  if (ownerId == null) return Stream.value(const <SyncAlert>[]);
  return ref.watch(syncAlertStoreProvider).watchForOwner(ownerId);
}

/// Nombre d'écritures hors-ligne en attente : celles de [characterId] (fiche)
/// ou le total du compte si `null` (liste).
@riverpod
Stream<int> pendingWriteCount(Ref ref, {String? characterId}) {
  final ownerId = ref.watch(syncOwnerIdProvider);
  if (ownerId == null) return Stream.value(0);
  return ref
      .watch(pendingCharacterWriteQueueProvider)
      .watchPendingCount(ownerId, characterId: characterId);
}

/// Date de dernière synchro réussie du compte connecté (`null` : jamais).
@riverpod
Stream<DateTime?> lastSyncAt(Ref ref) {
  final ownerId = ref.watch(syncOwnerIdProvider);
  if (ownerId == null) return Stream.value(null);
  return ref.watch(syncStateStoreProvider).watchLastSuccess(ownerId);
}

/// État du bandeau de synchro (`SyncStatusBanner`) pour une portée : la fiche
/// d'un personnage ([characterId] renseigné : compteur de CE personnage,
/// « Hors ligne » affiché même à 0 en attente) ou la liste (`null` : total du
/// compte, hors-ligne seulement si N > 0). Voir [SyncBannerEngine] pour la
/// précédence et les temporisations.
@riverpod
class SyncBanner extends _$SyncBanner {
  @override
  SyncBannerState build({String? characterId}) {
    final engine = SyncBannerEngine(showOfflineWhenEmpty: characterId != null);
    ref.onDispose(engine.dispose);

    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (_, next) {
      // Erreur/chargement : traités comme « en ligne », jamais un faux
      // hors-ligne.
      engine.setOnline(next.value ?? true);
    }, fireImmediately: true);
    ref.listen<AsyncValue<int>>(
      pendingWriteCountProvider(characterId: characterId),
      (_, next) => engine.setPendingCount(next.value ?? 0),
      fireImmediately: true,
    );
    ref.listen<bool>(
      syncActivityProvider,
      (_, next) => engine.setSyncing(next),
      fireImmediately: true,
    );
    ref.listen<AsyncValue<List<SyncAlert>>>(
      syncAlertsProvider,
      (_, next) => engine.setAlerts(next.value ?? const []),
      fireImmediately: true,
    );

    engine.onChanged = (next) => state = next;
    return engine.state;
  }
}
