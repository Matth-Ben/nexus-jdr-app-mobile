// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_token_registrar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
/// `main.dart`) : câblage mobile des notifications push
/// (`docs/cahier-des-charges/15-profil-parametres.md` section 3), Android
/// uniquement pour cette itération (voir [PushNotificationGateway]).
///
/// Trois responsabilités indépendantes, toutes best-effort (aucune exception
/// ne doit jamais remonter jusqu'à l'appelant de [start]) :
/// - **Enregistrement du jeton FCM** (`user_push_tokens`) : à chaque
///   connexion effective (même détection `AuthChangeEvent.signedIn`/
///   `initialSession` qu'`CharacterCreationCatalogPreloader`, voir sa doc de
///   classe pour le rationale complet du choix d'[AuthStateStream] plutôt que
///   `Ref.listen(authStateChangesProvider, ...)`), *si et seulement si* la
///   permission OS est déjà accordée (jamais de demande ici — la demande
///   n'a lieu qu'au clic explicite sur l'interrupteur global de
///   `features/profile/presentation/profile_notifications_screen.dart`,
///   décision chef de projet). Puis à chaque rotation du jeton
///   ([PushNotificationGateway.onTokenRefresh]), sans revérifier la
///   permission (un jeton dont la permission a été retirée entre-temps reste
///   inoffensif côté backend, voir la doc de classe de
///   [PushTokenRepository]).
/// - **Réception au premier plan** ([PushNotificationGateway.onMessage]) :
///   affiche un `SnackBar` simple (titre/corps), via
///   [scaffoldMessengerKeyProvider] (aucune UI dédiée pour cette itération,
///   cohérent avec le reste de ce dépôt pour des messages informatifs).
/// - **Tap sur une notification** ([PushNotificationGateway
///   .onMessageOpenedApp]/[PushNotificationGateway.getInitialMessage]) :
///   route vers `/characters/:id` si le payload `data` contient un
///   `characterId` — hypothèse de format `{characterId: string}` adoptée ici
///   pour les 2 déclencheurs actuels ("accès retiré"/"rappel de repos"), qui
///   concernent tous deux un personnage précis ; à faire matcher côté
///   backend (edge functions FCM du dépôt web, chantier séparé en cours en
///   parallèle) si le format réellement envoyé diverge.

@ProviderFor(pushTokenRegistrar)
final pushTokenRegistrarProvider = PushTokenRegistrarProvider._();

/// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
/// `main.dart`) : câblage mobile des notifications push
/// (`docs/cahier-des-charges/15-profil-parametres.md` section 3), Android
/// uniquement pour cette itération (voir [PushNotificationGateway]).
///
/// Trois responsabilités indépendantes, toutes best-effort (aucune exception
/// ne doit jamais remonter jusqu'à l'appelant de [start]) :
/// - **Enregistrement du jeton FCM** (`user_push_tokens`) : à chaque
///   connexion effective (même détection `AuthChangeEvent.signedIn`/
///   `initialSession` qu'`CharacterCreationCatalogPreloader`, voir sa doc de
///   classe pour le rationale complet du choix d'[AuthStateStream] plutôt que
///   `Ref.listen(authStateChangesProvider, ...)`), *si et seulement si* la
///   permission OS est déjà accordée (jamais de demande ici — la demande
///   n'a lieu qu'au clic explicite sur l'interrupteur global de
///   `features/profile/presentation/profile_notifications_screen.dart`,
///   décision chef de projet). Puis à chaque rotation du jeton
///   ([PushNotificationGateway.onTokenRefresh]), sans revérifier la
///   permission (un jeton dont la permission a été retirée entre-temps reste
///   inoffensif côté backend, voir la doc de classe de
///   [PushTokenRepository]).
/// - **Réception au premier plan** ([PushNotificationGateway.onMessage]) :
///   affiche un `SnackBar` simple (titre/corps), via
///   [scaffoldMessengerKeyProvider] (aucune UI dédiée pour cette itération,
///   cohérent avec le reste de ce dépôt pour des messages informatifs).
/// - **Tap sur une notification** ([PushNotificationGateway
///   .onMessageOpenedApp]/[PushNotificationGateway.getInitialMessage]) :
///   route vers `/characters/:id` si le payload `data` contient un
///   `characterId` — hypothèse de format `{characterId: string}` adoptée ici
///   pour les 2 déclencheurs actuels ("accès retiré"/"rappel de repos"), qui
///   concernent tous deux un personnage précis ; à faire matcher côté
///   backend (edge functions FCM du dépôt web, chantier séparé en cours en
///   parallèle) si le format réellement envoyé diverge.

final class PushTokenRegistrarProvider
    extends
        $FunctionalProvider<
          PushTokenRegistrar,
          PushTokenRegistrar,
          PushTokenRegistrar
        >
    with $Provider<PushTokenRegistrar> {
  /// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
  /// `main.dart`) : câblage mobile des notifications push
  /// (`docs/cahier-des-charges/15-profil-parametres.md` section 3), Android
  /// uniquement pour cette itération (voir [PushNotificationGateway]).
  ///
  /// Trois responsabilités indépendantes, toutes best-effort (aucune exception
  /// ne doit jamais remonter jusqu'à l'appelant de [start]) :
  /// - **Enregistrement du jeton FCM** (`user_push_tokens`) : à chaque
  ///   connexion effective (même détection `AuthChangeEvent.signedIn`/
  ///   `initialSession` qu'`CharacterCreationCatalogPreloader`, voir sa doc de
  ///   classe pour le rationale complet du choix d'[AuthStateStream] plutôt que
  ///   `Ref.listen(authStateChangesProvider, ...)`), *si et seulement si* la
  ///   permission OS est déjà accordée (jamais de demande ici — la demande
  ///   n'a lieu qu'au clic explicite sur l'interrupteur global de
  ///   `features/profile/presentation/profile_notifications_screen.dart`,
  ///   décision chef de projet). Puis à chaque rotation du jeton
  ///   ([PushNotificationGateway.onTokenRefresh]), sans revérifier la
  ///   permission (un jeton dont la permission a été retirée entre-temps reste
  ///   inoffensif côté backend, voir la doc de classe de
  ///   [PushTokenRepository]).
  /// - **Réception au premier plan** ([PushNotificationGateway.onMessage]) :
  ///   affiche un `SnackBar` simple (titre/corps), via
  ///   [scaffoldMessengerKeyProvider] (aucune UI dédiée pour cette itération,
  ///   cohérent avec le reste de ce dépôt pour des messages informatifs).
  /// - **Tap sur une notification** ([PushNotificationGateway
  ///   .onMessageOpenedApp]/[PushNotificationGateway.getInitialMessage]) :
  ///   route vers `/characters/:id` si le payload `data` contient un
  ///   `characterId` — hypothèse de format `{characterId: string}` adoptée ici
  ///   pour les 2 déclencheurs actuels ("accès retiré"/"rappel de repos"), qui
  ///   concernent tous deux un personnage précis ; à faire matcher côté
  ///   backend (edge functions FCM du dépôt web, chantier séparé en cours en
  ///   parallèle) si le format réellement envoyé diverge.
  PushTokenRegistrarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushTokenRegistrarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushTokenRegistrarHash();

  @$internal
  @override
  $ProviderElement<PushTokenRegistrar> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushTokenRegistrar create(Ref ref) {
    return pushTokenRegistrar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushTokenRegistrar value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushTokenRegistrar>(value),
    );
  }
}

String _$pushTokenRegistrarHash() =>
    r'8064c5f046aec4a3bdde9a8b3d6cfd36160246d0';
