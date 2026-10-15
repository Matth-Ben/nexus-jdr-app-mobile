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
            unawaited(registerTokenNow());
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
      _routeFromMessage,
      onError: (_) {},
    );
    unawaited(_routeFromInitialMessage());
  }

  /// Lit la permission OS puis, si accordée, récupère et enregistre le
  /// jeton FCM courant — best-effort, voir la doc de classe.
  ///
  /// Revérifie la permission via [PushNotificationGateway
  /// .getNotificationSettings] même quand l'appelant (`ProfileNotificationsScreen
  /// ._togglePushEnabled`) vient déjà de l'obtenir via
  /// [PushNotificationGateway.requestPermission] : une lecture passive
  /// supplémentaire juste après ne coûte qu'un aller-retour négligeable
  /// (aucune boîte de dialogue OS, contrairement à `requestPermission`), et
  /// reste la seule garde qui protège aussi l'appel périodique fait depuis
  /// [start] (reprise de session/connexion) — plutôt que deux chemins
  /// différents (l'un qui vérifie, l'autre qui ferait confiance à un état
  /// déjà lu ailleurs), un seul chemin unique, donc un seul comportement à
  /// maintenir si [PushNotificationGateway] change un jour de sémantique.
  Future<void> registerTokenNow() async {
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
      debugPrint('PushTokenRegistrar.registerTokenNow: $error');
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
      if (message != null) _routeFromMessage(message);
    } catch (_) {
      // Best-effort, silencieux — voir la doc de classe.
    }
  }

  /// Routage sur tap de notification — voir la doc de classe pour les 2
  /// formats de payload `data` gérés.
  void _routeFromMessage(RemoteMessage message) {
    if (message.data['type'] == 'new_version') {
      // `go` (jamais `push`) : revient à l'accueil plutôt que d'empiler une
      // route par-dessus la pile existante — même choix que
      // `ProfileNotificationsScreen._goBack` pour "retour à l'accueil".
      // `GoRouter.go` est synchrone (`void`), contrairement à `.push`
      // (`Future<T?>`) — jamais de `unawaited` ici.
      _ref.read(appRouterProvider).go('/');
      return;
    }
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
