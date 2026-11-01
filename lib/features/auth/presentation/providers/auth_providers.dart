import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/notifications/notification_providers.dart';
import '../../../../core/sync/pending_write_sync_hook_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_state_stream.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(
    ref.watch(supabaseClientProvider),
    pendingWriteQueue: ref.watch(pendingCharacterWriteQueueProvider),
    referenceDataCache: ref.watch(referenceDataCacheProvider),
    // Indirection neutre (`core/sync/pending_write_sync_hook_provider.dart`,
    // D31 du registre de dette technique) : jamais un import direct de
    // `features/characters/presentation/providers/character_providers.dart`
    // depuis `features/auth/` — le vrai câblage
    // (`PendingCharacterWriteSyncer.sync`) est posé en `override` dans
    // `lib/main.dart`, seul point de composition du dépôt qui connaît déjà
    // toutes les `features`.
    syncPendingWrites: () => ref.read(pendingWriteSyncHookProvider)(),
    // Registre d'audit RGPD B2 : libération best-effort du jeton push à la
    // déconnexion (voir la doc de classe de `SupabaseAuthRepository`) —
    // `core/notifications/` ne dépend d'aucune `feature`, donc cet import
    // direct ne pose pas le même risque de cycle que `pendingWriteSyncHook`
    // ci-dessus.
    pushTokenRepository: ref.watch(pushTokenRepositoryProvider),
    pushNotificationGateway: ref.watch(pushNotificationGatewayProvider),
  );
}

/// [AuthStateStream] partagé par toute l'app — voir sa doc de classe pour le
/// rationale ("piège `Ref.listen`") qui le distingue d'[authStateChanges]
/// ci-dessous. `keepAlive` : même rationale que [authRepositoryProvider].
@Riverpod(keepAlive: true)
AuthStateStream authStateStream(Ref ref) {
  return SupabaseAuthStateStream(ref.watch(supabaseClientProvider));
}

/// État d'authentification exposé de façon centralisée via Riverpod plutôt
/// que de l'état local dispersé dans chaque écran — n'importe quelle
/// fonctionnalité peut `ref.watch` ce provider pour réagir à une
/// connexion/déconnexion (ex. écran de profil).
///
/// Le routeur (`core/router/app_router.dart`) écoute quant à lui directement
/// le flux `onAuthStateChange` pour piloter `GoRouter.refreshListenable`,
/// afin de rester découplé de Riverpod dans la configuration du routeur.
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}

/// Utilisateur Supabase actuellement connecté — seul point d'accès à
/// `Supabase.instance.client.auth.currentUser` dans ce dépôt (jamais un accès
/// direct/statique depuis un widget), pour que les tests de widgets (écran de
/// profil, `features/profile/presentation/profile_screen.dart`) puissent
/// overrider ce provider avec un `User` construit à la main, sans jamais
/// fabriquer de vrai `SupabaseClient` — même rationale que [AuthRepository].
///
/// `ref.watch(authStateChanges)` (plutôt qu'une simple lecture non réactive)
/// pour que ce provider se recalcule à chaque événement d'auth, en
/// particulier `AuthChangeEvent.userUpdated` émis par
/// `SupabaseAuthRepository.updateDisplayName` : l'écran de profil reflète
/// ainsi un nom d'affichage tout juste modifié sans qu'aucun code appelant
/// n'ait besoin d'invalider ce provider explicitement (contrairement au reste
/// du dépôt, ex. `characterDetailProvider`).
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
}

/// Détermine si le bouton "Continuer avec Apple" doit être proposé sur
/// l'écran de connexion (`login_screen.dart`) — `true` sur iOS/macOS
/// uniquement : Android n'est pas concerné par l'obligation Apple App Store
/// Review Guideline 4.8 (qui ne s'applique qu'aux apps iOS), et le flux natif
/// `sign_in_with_apple` n'y est de toute façon pas disponible sans
/// configuration Services ID web supplémentaire (hors périmètre de cette
/// tâche).
///
/// Passe par un provider (plutôt qu'un appel direct à `Platform.isIOS` dans
/// `login_screen.dart`, comme le fait déjà `AppStoreUrls.current()`) pour une
/// seule raison : permettre à `login_screen_test.dart` de l'overrider à
/// `true` et exercer le bouton/`AuthRepository.signInWithApple` en test —
/// `Platform.isIOS`/`isMacOS` valent toujours `false` sous `flutter test`
/// (exécuté sur hôte desktop, Windows en local et `ubuntu-latest` en CI,
/// voir `.github/workflows/ci.yml`), donc un appel direct rendrait ce bouton
/// impossible à tester autrement que manuellement. Écart volontaire par
/// rapport à la piste "`Platform.isIOS || Platform.isMacOS` en dur" de la
/// spec d'origine — signalé au chef de projet plutôt qu'appliqué
/// silencieusement.
@Riverpod(keepAlive: true)
bool appleSignInSupported(Ref ref) => Platform.isIOS || Platform.isMacOS;
