import 'package:firebase_messaging/firebase_messaging.dart';

/// Abstraction de `package:firebase_messaging`, au-dessus de
/// `FirebaseMessaging.instance`/les flux statiques `FirebaseMessaging
/// .onMessage`/`.onMessageOpenedApp` — jamais utilisés directement ailleurs
/// dans ce dépôt, pour que les tests puissent injecter un double sans jamais
/// toucher au canal de plateforme réel (indisponible dans `flutter test`, ni
/// mocké nativement dans ce dépôt — voir `ConnectivityChecker`,
/// `core/network/connectivity_checker.dart`, même rationale exact).
///
/// Consommé par [PushTokenRegistrar]
/// (`push_token_registrar.dart` — enregistrement/rotation du token FCM,
/// réception au premier plan, tap sur notification) et par
/// `features/profile/presentation/profile_notifications_screen.dart`
/// (demande de permission explicite au clic sur l'interrupteur global "Activer
/// les notifications push", décision chef de projet — voir sa documentation
/// de classe).
///
/// Android uniquement pour cette itération (iOS reste bloqué sur le compte
/// Apple Developer — pas de `GoogleService-Info.plist` ni de
/// `DefaultFirebaseOptions.ios` encore générés, voir `firebase_options.dart`).
abstract class PushNotificationGateway {
  /// Déclenche la boîte de dialogue OS de demande de permission de
  /// notifications. **Ne jamais appeler en dehors d'un clic explicite de
  /// l'utilisateur** (décision chef de projet, voir la doc de classe de
  /// `ProfileNotificationsScreen`) — [getNotificationSettings] est la lecture
  /// passive équivalente, à utiliser partout ailleurs (ex. démarrage de
  /// l'app).
  Future<NotificationSettings> requestPermission();

  /// Lit l'état actuel de la permission de notifications, sans jamais
  /// déclencher de boîte de dialogue OS.
  Future<NotificationSettings> getNotificationSettings();

  /// Jeton FCM actuel de l'appareil, ou `null` si indisponible (ex. Google
  /// Play Services absent/obsolète).
  Future<String?> getToken();

  /// Émet un nouveau jeton à chaque rotation FCM (ex. réinstallation de
  /// l'app, restauration sur un nouvel appareil).
  Stream<String> get onTokenRefresh;

  /// Message reçu pendant que l'app est au premier plan.
  Stream<RemoteMessage> get onMessage;

  /// Tap sur une notification pendant que l'app est en arrière-plan (pas
  /// terminée) — voir [getInitialMessage] pour le cas "app terminée".
  Stream<RemoteMessage> get onMessageOpenedApp;

  /// Message ayant provoqué le lancement de l'app depuis un état terminé (tap
  /// sur une notification), ou `null` si l'app n'a pas été lancée ainsi.
  Future<RemoteMessage?> getInitialMessage();
}

/// `true` si [settings] autorise l'envoi de notifications — englobe
/// [AuthorizationStatus.provisional] (notifications silencieuses, iOS
/// uniquement, jamais rencontré sur Android mais traité de la même façon par
/// cohérence avec le reste de la plateforme Apple/Android commune de ce
/// package) en plus d'[AuthorizationStatus.authorized]. Toute autre valeur
/// (`denied`/`notDetermined`/`deniedPermanently`) est traitée comme "non
/// autorisé".
bool isPushPermissionGranted(NotificationSettings settings) =>
    settings.authorizationStatus == AuthorizationStatus.authorized ||
    settings.authorizationStatus == AuthorizationStatus.provisional;

/// Implémentation réelle, au-dessus de `FirebaseMessaging.instance`/des flux
/// statiques du package.
class FirebasePushNotificationGateway implements PushNotificationGateway {
  const FirebasePushNotificationGateway();

  @override
  Future<NotificationSettings> requestPermission() =>
      FirebaseMessaging.instance.requestPermission();

  @override
  Future<NotificationSettings> getNotificationSettings() =>
      FirebaseMessaging.instance.getNotificationSettings();

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();
}
