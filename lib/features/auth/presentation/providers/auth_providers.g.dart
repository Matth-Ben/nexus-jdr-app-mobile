// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'157dd73bdf6ec0879936e7c10d1b03f5bf9bed55';

/// [AuthStateStream] partagé par toute l'app — voir sa doc de classe pour le
/// rationale ("piège `Ref.listen`") qui le distingue d'[authStateChanges]
/// ci-dessous. `keepAlive` : même rationale que [authRepositoryProvider].

@ProviderFor(authStateStream)
final authStateStreamProvider = AuthStateStreamProvider._();

/// [AuthStateStream] partagé par toute l'app — voir sa doc de classe pour le
/// rationale ("piège `Ref.listen`") qui le distingue d'[authStateChanges]
/// ci-dessous. `keepAlive` : même rationale que [authRepositoryProvider].

final class AuthStateStreamProvider
    extends
        $FunctionalProvider<AuthStateStream, AuthStateStream, AuthStateStream>
    with $Provider<AuthStateStream> {
  /// [AuthStateStream] partagé par toute l'app — voir sa doc de classe pour le
  /// rationale ("piège `Ref.listen`") qui le distingue d'[authStateChanges]
  /// ci-dessous. `keepAlive` : même rationale que [authRepositoryProvider].
  AuthStateStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateStreamHash();

  @$internal
  @override
  $ProviderElement<AuthStateStream> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthStateStream create(Ref ref) {
    return authStateStream(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthStateStream value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthStateStream>(value),
    );
  }
}

String _$authStateStreamHash() => r'530d0a3282b0af1210c4088c0e857dd6c78432da';

/// État d'authentification exposé de façon centralisée via Riverpod plutôt
/// que de l'état local dispersé dans chaque écran — n'importe quelle
/// fonctionnalité peut `ref.watch` ce provider pour réagir à une
/// connexion/déconnexion (ex. écran de profil).
///
/// Le routeur (`core/router/app_router.dart`) écoute quant à lui directement
/// le flux `onAuthStateChange` pour piloter `GoRouter.refreshListenable`,
/// afin de rester découplé de Riverpod dans la configuration du routeur.

@ProviderFor(authStateChanges)
final authStateChangesProvider = AuthStateChangesProvider._();

/// État d'authentification exposé de façon centralisée via Riverpod plutôt
/// que de l'état local dispersé dans chaque écran — n'importe quelle
/// fonctionnalité peut `ref.watch` ce provider pour réagir à une
/// connexion/déconnexion (ex. écran de profil).
///
/// Le routeur (`core/router/app_router.dart`) écoute quant à lui directement
/// le flux `onAuthStateChange` pour piloter `GoRouter.refreshListenable`,
/// afin de rester découplé de Riverpod dans la configuration du routeur.

final class AuthStateChangesProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  /// État d'authentification exposé de façon centralisée via Riverpod plutôt
  /// que de l'état local dispersé dans chaque écran — n'importe quelle
  /// fonctionnalité peut `ref.watch` ce provider pour réagir à une
  /// connexion/déconnexion (ex. écran de profil).
  ///
  /// Le routeur (`core/router/app_router.dart`) écoute quant à lui directement
  /// le flux `onAuthStateChange` pour piloter `GoRouter.refreshListenable`,
  /// afin de rester découplé de Riverpod dans la configuration du routeur.
  AuthStateChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'835d2fbd587c51600562fad9086c24998aeb8039';

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

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

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

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
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
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'18cf8d7a817a4acbffe7f9b1c912490aee4f8e93';
