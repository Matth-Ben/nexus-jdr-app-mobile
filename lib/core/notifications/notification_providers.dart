import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/supabase_client_provider.dart';
import 'push_notification_gateway.dart';
import 'push_token_repository.dart';

part 'notification_providers.g.dart';

/// [PushNotificationGateway] partagé par toute l'app — voir sa doc de classe.
/// `keepAlive` : même rationale que `connectivityCheckerProvider`
/// (`core/network/connectivity_providers.dart`), jamais recréé par écran.
@Riverpod(keepAlive: true)
PushNotificationGateway pushNotificationGateway(Ref ref) =>
    const FirebasePushNotificationGateway();

@Riverpod(keepAlive: true)
PushTokenRepository pushTokenRepository(Ref ref) {
  return SupabasePushTokenRepository(ref.watch(supabaseClientProvider));
}

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
@Riverpod(keepAlive: true)
GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey(Ref ref) =>
    GlobalKey<ScaffoldMessengerState>();
