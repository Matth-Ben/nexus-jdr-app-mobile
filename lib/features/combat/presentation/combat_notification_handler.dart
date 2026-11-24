import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
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
  /// le signal global correspondant (dédoublonné par groupe et par type
  /// pendant 60 s avec les messages du canal du groupe).
  void received(CombatNotificationTarget target) {
    _ref.read(combatCalloutControllerProvider.notifier).showFromPush(target);
    // Groupe inconnu de la liste (rejoint ailleurs) : son nom arrive avec la
    // relecture.
    if (_ref.exists(myGroupMembershipsProvider)) {
      _ref
          .read(myGroupMembershipsProvider.notifier)
          .ensureKnown(target.groupId);
    }
  }

  /// Notification **touchée** (`onMessageOpenedApp`, `getInitialMessage`) :
  /// écran Groupe (`go`) puis écran Combat (`push`), pour que le retour mène
  /// au groupe. Compte qui n'est plus membre : rien ne s'ouvre, « Ce groupe
  /// n'est plus accessible. ». Appartenance inconnue (hors ligne) : le combat
  /// s'ouvre, l'écran gère lui-même un groupe devenu inaccessible.
  Future<void> open(CombatNotificationTarget target) async {
    final groupId = target.groupId;
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
    final router = _ref.read(appRouterProvider)..go('/groups/$groupId');
    // La pile « Groupe » doit être en place avant d'y empiler le combat.
    await WidgetsBinding.instance.endOfFrame;
    unawaited(router.push('/groups/$groupId/combat'));
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
