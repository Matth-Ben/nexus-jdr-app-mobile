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
/// ne doit jamais remonter jusqu'à l'appelant de [start]/[registerTokenNow]) :
/// - **Enregistrement du jeton FCM** (`user_push_tokens`), via
///   [registerTokenNow] (voir sa doc pour le détail), déclenché depuis trois
///   points distincts :
///     - à chaque connexion effective (même détection
///       `AuthChangeEvent.signedIn`/`initialSession` qu'
///       `CharacterCreationCatalogPreloader`, voir sa doc de classe pour le
///       rationale complet du choix d'[AuthStateStream] plutôt que
///       `Ref.listen(authStateChangesProvider, ...)`) ;
///     - à l'appel explicite de [registerTokenNow] par
///       `ProfileNotificationsScreen._togglePushEnabled` juste après que
///       `PushNotificationGateway.requestPermission()` a confirmé la
///       permission — **bug corrigé** : sans cet appel, activer
///       l'interrupteur en cours de session n'enregistrait jamais le jeton
///       avant qu'une connexion effective (donc un redémarrage complet de
///       l'app) ne se reproduise, alors que la préférence
///       `notification_preferences.push_enabled` était déjà écrite en base —
///       l'utilisateur croyait alors avoir activé les notifications sans
///       qu'aucune ligne `user_push_tokens` n'existe tant qu'il n'avait pas
///       fermé et rouvert l'app ;
///     - à chaque rotation du jeton
///       ([PushNotificationGateway.onTokenRefresh]), sans revérifier la
///       permission (un jeton dont la permission a été retirée entre-temps
///       reste inoffensif côté backend, voir la doc de classe de
///       [PushTokenRepository]).
/// - **Réception au premier plan** ([PushNotificationGateway.onMessage]) :
///   affiche un `SnackBar` simple (titre/corps), via
///   [scaffoldMessengerKeyProvider] (aucune UI dédiée pour cette itération,
///   cohérent avec le reste de ce dépôt pour des messages informatifs).
/// - **Tap sur une notification** ([PushNotificationGateway
///   .onMessageOpenedApp]/[PushNotificationGateway.getInitialMessage],
///   routé par [_routeFromMessage]) : deux formats de payload `data`
///   possibles selon le déclencheur —
///     - `{type: 'new_version', ...}` ("nouvelle version disponible") :
///       route vers l'accueil (`/`), où vit déjà `UpdateSuggestedBanner`
///       (`features/app_update/presentation/widgets/update_suggested_banner
///       .dart`) — c'est justement le changement de
///       `app_versions.latest_version` qui a déclenché l'envoi de cette
///       notification, donc la bannière a de quoi s'afficher dès l'arrivée
///       sur cet écran.
///     - `{characterId: string}` (sans `type`) : route vers
///       `/characters/:id` — hypothèse de format adoptée ici pour les 2
///       déclencheurs restants ("accès retiré"/"rappel de repos"), qui
///       concernent tous deux un personnage précis ; à faire matcher côté
///       backend (edge functions FCM du dépôt web, chantier séparé en cours
///       en parallèle) si le format réellement envoyé diverge.

@ProviderFor(pushTokenRegistrar)
final pushTokenRegistrarProvider = PushTokenRegistrarProvider._();

/// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
/// `main.dart`) : câblage mobile des notifications push
/// (`docs/cahier-des-charges/15-profil-parametres.md` section 3), Android
/// uniquement pour cette itération (voir [PushNotificationGateway]).
///
/// Trois responsabilités indépendantes, toutes best-effort (aucune exception
/// ne doit jamais remonter jusqu'à l'appelant de [start]/[registerTokenNow]) :
/// - **Enregistrement du jeton FCM** (`user_push_tokens`), via
///   [registerTokenNow] (voir sa doc pour le détail), déclenché depuis trois
///   points distincts :
///     - à chaque connexion effective (même détection
///       `AuthChangeEvent.signedIn`/`initialSession` qu'
///       `CharacterCreationCatalogPreloader`, voir sa doc de classe pour le
///       rationale complet du choix d'[AuthStateStream] plutôt que
///       `Ref.listen(authStateChangesProvider, ...)`) ;
///     - à l'appel explicite de [registerTokenNow] par
///       `ProfileNotificationsScreen._togglePushEnabled` juste après que
///       `PushNotificationGateway.requestPermission()` a confirmé la
///       permission — **bug corrigé** : sans cet appel, activer
///       l'interrupteur en cours de session n'enregistrait jamais le jeton
///       avant qu'une connexion effective (donc un redémarrage complet de
///       l'app) ne se reproduise, alors que la préférence
///       `notification_preferences.push_enabled` était déjà écrite en base —
///       l'utilisateur croyait alors avoir activé les notifications sans
///       qu'aucune ligne `user_push_tokens` n'existe tant qu'il n'avait pas
///       fermé et rouvert l'app ;
///     - à chaque rotation du jeton
///       ([PushNotificationGateway.onTokenRefresh]), sans revérifier la
///       permission (un jeton dont la permission a été retirée entre-temps
///       reste inoffensif côté backend, voir la doc de classe de
///       [PushTokenRepository]).
/// - **Réception au premier plan** ([PushNotificationGateway.onMessage]) :
///   affiche un `SnackBar` simple (titre/corps), via
///   [scaffoldMessengerKeyProvider] (aucune UI dédiée pour cette itération,
///   cohérent avec le reste de ce dépôt pour des messages informatifs).
/// - **Tap sur une notification** ([PushNotificationGateway
///   .onMessageOpenedApp]/[PushNotificationGateway.getInitialMessage],
///   routé par [_routeFromMessage]) : deux formats de payload `data`
///   possibles selon le déclencheur —
///     - `{type: 'new_version', ...}` ("nouvelle version disponible") :
///       route vers l'accueil (`/`), où vit déjà `UpdateSuggestedBanner`
///       (`features/app_update/presentation/widgets/update_suggested_banner
///       .dart`) — c'est justement le changement de
///       `app_versions.latest_version` qui a déclenché l'envoi de cette
///       notification, donc la bannière a de quoi s'afficher dès l'arrivée
///       sur cet écran.
///     - `{characterId: string}` (sans `type`) : route vers
///       `/characters/:id` — hypothèse de format adoptée ici pour les 2
///       déclencheurs restants ("accès retiré"/"rappel de repos"), qui
///       concernent tous deux un personnage précis ; à faire matcher côté
///       backend (edge functions FCM du dépôt web, chantier séparé en cours
///       en parallèle) si le format réellement envoyé diverge.

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
  /// ne doit jamais remonter jusqu'à l'appelant de [start]/[registerTokenNow]) :
  /// - **Enregistrement du jeton FCM** (`user_push_tokens`), via
  ///   [registerTokenNow] (voir sa doc pour le détail), déclenché depuis trois
  ///   points distincts :
  ///     - à chaque connexion effective (même détection
  ///       `AuthChangeEvent.signedIn`/`initialSession` qu'
  ///       `CharacterCreationCatalogPreloader`, voir sa doc de classe pour le
  ///       rationale complet du choix d'[AuthStateStream] plutôt que
  ///       `Ref.listen(authStateChangesProvider, ...)`) ;
  ///     - à l'appel explicite de [registerTokenNow] par
  ///       `ProfileNotificationsScreen._togglePushEnabled` juste après que
  ///       `PushNotificationGateway.requestPermission()` a confirmé la
  ///       permission — **bug corrigé** : sans cet appel, activer
  ///       l'interrupteur en cours de session n'enregistrait jamais le jeton
  ///       avant qu'une connexion effective (donc un redémarrage complet de
  ///       l'app) ne se reproduise, alors que la préférence
  ///       `notification_preferences.push_enabled` était déjà écrite en base —
  ///       l'utilisateur croyait alors avoir activé les notifications sans
  ///       qu'aucune ligne `user_push_tokens` n'existe tant qu'il n'avait pas
  ///       fermé et rouvert l'app ;
  ///     - à chaque rotation du jeton
  ///       ([PushNotificationGateway.onTokenRefresh]), sans revérifier la
  ///       permission (un jeton dont la permission a été retirée entre-temps
  ///       reste inoffensif côté backend, voir la doc de classe de
  ///       [PushTokenRepository]).
  /// - **Réception au premier plan** ([PushNotificationGateway.onMessage]) :
  ///   affiche un `SnackBar` simple (titre/corps), via
  ///   [scaffoldMessengerKeyProvider] (aucune UI dédiée pour cette itération,
  ///   cohérent avec le reste de ce dépôt pour des messages informatifs).
  /// - **Tap sur une notification** ([PushNotificationGateway
  ///   .onMessageOpenedApp]/[PushNotificationGateway.getInitialMessage],
  ///   routé par [_routeFromMessage]) : deux formats de payload `data`
  ///   possibles selon le déclencheur —
  ///     - `{type: 'new_version', ...}` ("nouvelle version disponible") :
  ///       route vers l'accueil (`/`), où vit déjà `UpdateSuggestedBanner`
  ///       (`features/app_update/presentation/widgets/update_suggested_banner
  ///       .dart`) — c'est justement le changement de
  ///       `app_versions.latest_version` qui a déclenché l'envoi de cette
  ///       notification, donc la bannière a de quoi s'afficher dès l'arrivée
  ///       sur cet écran.
  ///     - `{characterId: string}` (sans `type`) : route vers
  ///       `/characters/:id` — hypothèse de format adoptée ici pour les 2
  ///       déclencheurs restants ("accès retiré"/"rappel de repos"), qui
  ///       concernent tous deux un personnage précis ; à faire matcher côté
  ///       backend (edge functions FCM du dépôt web, chantier séparé en cours
  ///       en parallèle) si le format réellement envoyé diverge.
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
