import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/combat_notification.dart';
import 'providers/combat_callout_providers.dart';
import 'providers/grimoire_groups_providers.dart';

/// Notifications push du combat (`combat_start`, `your_turn`), appelé par
/// `PushTokenRegistrar` (`core/notifications/push_token_registrar.dart`) —
/// `docs/combat-grimoire-ui.md` §5 et §8. Même format et même routage pour le
/// combat natif V2 (décision 59).
final combatNotificationHandlerProvider = Provider<CombatNotificationHandler>(
  CombatNotificationHandler.new,
);

class CombatNotificationHandler {
  CombatNotificationHandler(this._ref);

  final Ref _ref;

  /// Notification reçue **app ouverte** : jamais la `SnackBar` générique,
  /// le signal global correspondant (dédoublonné avec les messages du canal
  /// du groupe, voir `CombatCalloutController.showFromPush`) ; rien sans
  /// session.
  void received(CombatNotificationTarget target) {
    // Sans session (notification de l'ancien compte après une déconnexion) :
    // rien, jamais « Combat ! » sur l'écran de connexion.
    if (_ref.read(currentUserProvider) == null) return;
    _ref.read(combatCalloutControllerProvider.notifier).showFromPush(target);
    // Groupe inconnu de la liste (rejoint ailleurs) ou pas encore lié à
    // Grimoire : son nom arrive avec la relecture, et son canal est suivi.
    if (_ref.exists(myGroupMembershipsProvider)) {
      _ref
          .read(myGroupMembershipsProvider.notifier)
          .ensureFollowed(target.groupId);
    }
  }

  /// Notification **touchée** (`onMessageOpenedApp`, `getInitialMessage`) :
  /// écran Groupe (`go`) puis écran Combat (`push`), pour que le retour mène
  /// au groupe. Compte qui n'est plus membre : rien ne s'ouvre, « Ce groupe
  /// n'est plus accessible. ». Appartenance inconnue (hors ligne) : le combat
  /// s'ouvre, l'écran gère lui-même un groupe devenu inaccessible. Sans
  /// compte connecté : rien. Si la redirection du routeur (connexion,
  /// présentation de l'app) détourne l'écran Groupe, le combat n'est pas
  /// empilé par-dessus.
  Future<void> open(CombatNotificationTarget target) async {
    final groupId = target.groupId;
    if (_ref.read(currentUserProvider) == null) return;
    bool? member;
    try {
      member = await _ref
          .read(myGroupMembershipsProvider.notifier)
          .isMember(groupId);
    } on Object {
      member = null;
    }
    if (member == false) {
      _showNotAccessible();
      return;
    }
    final groupPath = '/groups/$groupId';
    final router = _ref.read(appRouterProvider)..go(groupPath);
    // La pile « Groupe » doit être en place avant d'y empiler le combat.
    await WidgetsBinding.instance.endOfFrame;
    if (router.state.uri.path != groupPath) return;
    unawaited(router.push('$groupPath/combat'));
  }

  void _showNotAccessible() {
    final key = _ref.read(scaffoldMessengerKeyProvider);
    final context = key.currentContext;
    final messenger = key.currentState;
    if (context == null || messenger == null) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.combatGroupNotAccessible)),
    );
  }
}
