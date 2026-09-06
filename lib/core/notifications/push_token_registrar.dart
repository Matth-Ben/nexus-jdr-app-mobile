import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../router/app_router.dart';
import 'notification_providers.dart';
import 'push_notification_gateway.dart';

part 'push_token_registrar.g.dart';

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
@Riverpod(keepAlive: true)
PushTokenRegistrar pushTokenRegistrar(Ref ref) {
  final registrar = PushTokenRegistrar(ref);
  registrar.start();
  ref.onDispose(registrar.dispose);
  return registrar;
}

class PushTokenRegistrar {
  PushTokenRegistrar(this._ref);

  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  void start() {
    _authSubscription = _ref
        .read(authStateStreamProvider)
        .onAuthStateChange
        .listen((authState) {
          final isNewSignIn = authState.event == AuthChangeEvent.signedIn;
          final isResumedSession =
              authState.event == AuthChangeEvent.initialSession &&
              authState.session != null;
          if (isNewSignIn || isResumedSession) {
            unawaited(_registerTokenIfPermitted());
          }
        });

    final gateway = _ref.read(pushNotificationGatewayProvider);
    _tokenRefreshSubscription = gateway.onTokenRefresh.listen(
      (token) => unawaited(_upsertToken(token)),
      onError: (_) {},
    );
    _foregroundSubscription = gateway.onMessage.listen(
      _showForegroundMessage,
      onError: (_) {},
    );
    _openedAppSubscription = gateway.onMessageOpenedApp.listen(
      _routeToCharacterIfAny,
      onError: (_) {},
    );
    unawaited(_routeFromInitialMessage());
  }

  Future<void> _registerTokenIfPermitted() async {
    try {
      final gateway = _ref.read(pushNotificationGatewayProvider);
      final settings = await gateway.getNotificationSettings();
      if (!isPushPermissionGranted(settings)) return;
      final token = await gateway.getToken();
      if (token == null) return;
      await _upsertToken(token);
    } catch (error) {
      // Best-effort côté utilisateur (voir la doc de classe) — mais tracé en
      // debug pour rester diagnosticable (ex. échec réseau, RPC
      // `claim_push_token` manquante côté backend) plutôt qu'un échec
      // totalement invisible.
      debugPrint('PushTokenRegistrar._registerTokenIfPermitted: $error');
    }
  }

  Future<void> _upsertToken(String token) async {
    try {
      await _ref
          .read(pushTokenRepositoryProvider)
          .upsertToken(token: token, platform: 'android');
    } catch (error) {
      debugPrint('PushTokenRegistrar._upsertToken: $error');
    }
  }

  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final title = notification.title;
    final body = notification.body;
    final text = [
      title,
      body,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' — ');
    if (text.isEmpty) return;

    _ref
        .read(scaffoldMessengerKeyProvider)
        .currentState
        ?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _routeFromInitialMessage() async {
    try {
      final message = await _ref
          .read(pushNotificationGatewayProvider)
          .getInitialMessage();
      if (message != null) _routeToCharacterIfAny(message);
    } catch (_) {
      // Best-effort, silencieux — voir la doc de classe.
    }
  }

  void _routeToCharacterIfAny(RemoteMessage message) {
    final characterId = message.data['characterId'] as String?;
    if (characterId == null || characterId.isEmpty) return;
    unawaited(_ref.read(appRouterProvider).push('/characters/$characterId'));
  }

  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_tokenRefreshSubscription?.cancel());
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedAppSubscription?.cancel());
  }
}
