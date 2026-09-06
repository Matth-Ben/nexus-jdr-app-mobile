// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [PushNotificationGateway] partagé par toute l'app — voir sa doc de classe.
/// `keepAlive` : même rationale que `connectivityCheckerProvider`
/// (`core/network/connectivity_providers.dart`), jamais recréé par écran.

@ProviderFor(pushNotificationGateway)
final pushNotificationGatewayProvider = PushNotificationGatewayProvider._();

/// [PushNotificationGateway] partagé par toute l'app — voir sa doc de classe.
/// `keepAlive` : même rationale que `connectivityCheckerProvider`
/// (`core/network/connectivity_providers.dart`), jamais recréé par écran.

final class PushNotificationGatewayProvider
    extends
        $FunctionalProvider<
          PushNotificationGateway,
          PushNotificationGateway,
          PushNotificationGateway
        >
    with $Provider<PushNotificationGateway> {
  /// [PushNotificationGateway] partagé par toute l'app — voir sa doc de classe.
  /// `keepAlive` : même rationale que `connectivityCheckerProvider`
  /// (`core/network/connectivity_providers.dart`), jamais recréé par écran.
  PushNotificationGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushNotificationGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotificationGatewayHash();

  @$internal
  @override
  $ProviderElement<PushNotificationGateway> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushNotificationGateway create(Ref ref) {
    return pushNotificationGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushNotificationGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushNotificationGateway>(value),
    );
  }
}

String _$pushNotificationGatewayHash() =>
    r'1e4b475da784010953b4629843bb3cf638b81ab4';

@ProviderFor(pushTokenRepository)
final pushTokenRepositoryProvider = PushTokenRepositoryProvider._();

final class PushTokenRepositoryProvider
    extends
        $FunctionalProvider<
          PushTokenRepository,
          PushTokenRepository,
          PushTokenRepository
        >
    with $Provider<PushTokenRepository> {
  PushTokenRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushTokenRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushTokenRepositoryHash();

  @$internal
  @override
  $ProviderElement<PushTokenRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushTokenRepository create(Ref ref) {
    return pushTokenRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushTokenRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushTokenRepository>(value),
    );
  }
}

String _$pushTokenRepositoryHash() =>
    r'aeaf0f0c38f74dd63eb3f3308069b35e26fd2c91';

/// Clé globale de `ScaffoldMessenger`, câblée sur
/// `MaterialApp.router(scaffoldMessengerKey: ...)` dans `main.dart` —
/// permet à [PushTokenRegistrar] (`push_token_registrar.dart`) d'afficher un
/// `SnackBar` pour un message FCM reçu au premier plan sans jamais disposer
/// d'un `BuildContext` d'écran (ce coordinateur vit tant que l'app tourne,
/// indépendamment de tout écran affiché — voir sa doc de classe).
///
/// Pattern standard documenté par Flutter lui-même pour ce cas précis
/// (afficher un `SnackBar` depuis en dehors de l'arbre de widgets), à ne pas
/// confondre avec un `GlobalKey<NavigatorState>` pour la navigation : le tap
/// sur une notification (`onMessageOpenedApp`/`getInitialMessage`) route via
/// `appRouterProvider` (`GoRouter.push`, une méthode d'instance qui n'a pas
/// besoin de `BuildContext`), jamais via une clé de navigateur dédiée.

@ProviderFor(scaffoldMessengerKey)
final scaffoldMessengerKeyProvider = ScaffoldMessengerKeyProvider._();

/// Clé globale de `ScaffoldMessenger`, câblée sur
/// `MaterialApp.router(scaffoldMessengerKey: ...)` dans `main.dart` —
/// permet à [PushTokenRegistrar] (`push_token_registrar.dart`) d'afficher un
/// `SnackBar` pour un message FCM reçu au premier plan sans jamais disposer
/// d'un `BuildContext` d'écran (ce coordinateur vit tant que l'app tourne,
/// indépendamment de tout écran affiché — voir sa doc de classe).
///
/// Pattern standard documenté par Flutter lui-même pour ce cas précis
/// (afficher un `SnackBar` depuis en dehors de l'arbre de widgets), à ne pas
/// confondre avec un `GlobalKey<NavigatorState>` pour la navigation : le tap
/// sur une notification (`onMessageOpenedApp`/`getInitialMessage`) route via
/// `appRouterProvider` (`GoRouter.push`, une méthode d'instance qui n'a pas
/// besoin de `BuildContext`), jamais via une clé de navigateur dédiée.

final class ScaffoldMessengerKeyProvider
    extends
        $FunctionalProvider<
          GlobalKey<ScaffoldMessengerState>,
          GlobalKey<ScaffoldMessengerState>,
          GlobalKey<ScaffoldMessengerState>
        >
    with $Provider<GlobalKey<ScaffoldMessengerState>> {
  /// Clé globale de `ScaffoldMessenger`, câblée sur
  /// `MaterialApp.router(scaffoldMessengerKey: ...)` dans `main.dart` —
  /// permet à [PushTokenRegistrar] (`push_token_registrar.dart`) d'afficher un
  /// `SnackBar` pour un message FCM reçu au premier plan sans jamais disposer
  /// d'un `BuildContext` d'écran (ce coordinateur vit tant que l'app tourne,
  /// indépendamment de tout écran affiché — voir sa doc de classe).
  ///
  /// Pattern standard documenté par Flutter lui-même pour ce cas précis
  /// (afficher un `SnackBar` depuis en dehors de l'arbre de widgets), à ne pas
  /// confondre avec un `GlobalKey<NavigatorState>` pour la navigation : le tap
  /// sur une notification (`onMessageOpenedApp`/`getInitialMessage`) route via
  /// `appRouterProvider` (`GoRouter.push`, une méthode d'instance qui n'a pas
  /// besoin de `BuildContext`), jamais via une clé de navigateur dédiée.
  ScaffoldMessengerKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scaffoldMessengerKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scaffoldMessengerKeyHash();

  @$internal
  @override
  $ProviderElement<GlobalKey<ScaffoldMessengerState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalKey<ScaffoldMessengerState> create(Ref ref) {
    return scaffoldMessengerKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalKey<ScaffoldMessengerState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalKey<ScaffoldMessengerState>>(
        value,
      ),
    );
  }
}

String _$scaffoldMessengerKeyHash() =>
    r'6fdcaf2dd3359a74fa6f6d7fbd0c67c54a8e600d';
