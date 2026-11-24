import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_stack_observer.dart';
import '../../domain/combat_notification.dart';
import '../../domain/grimoire_combat_reducer.dart';
import '../../domain/grimoire_combat_session.dart';
import '../../domain/grimoire_combat_view.dart';
import 'combat_providers.dart';

/// Signal global de combat (`docs/combat-grimoire-ui.md` §6).
enum CombatCalloutKind {
  /// Variante **annonce** « Combat ! » (début du combat).
  combatStart,

  /// Variante **annonce** « Initiative demandée » (le MJ (re)demande
  /// l'initiative hors annonce du combat).
  initiativeRequested,

  /// Variante **tour** « À toi de jouer » : ne disparaît jamais seule.
  yourTurn,
}

/// Origine d'une demande de signal : message reçu sur le canal du groupe, ou
/// notification push reçue app ouverte.
enum CombatCalloutSource { live, push }

/// Signal affiché : [id] croissant (un nouveau signal, même identique, a un
/// nouvel [id]), groupe et variante.
typedef CombatCallout = ({int id, String groupId, CombatCalloutKind kind});

/// Fenêtre de dédoublonnage par groupe et par type entre une notification push
/// et le canal du groupe (spec §5, dernière ligne du tableau).
const Duration kCombatCalloutDedupeWindow = Duration(seconds: 60);

/// Durée d'affichage de la variante annonce (sauf `accessibleNavigation`).
const Duration kCombatCalloutAnnounceDuration = Duration(seconds: 10);

extension CombatCalloutTraits on CombatCallout {
  /// Variante tour (« À toi de jouer ») : jamais retirée par une minuterie.
  bool get isTurn => kind == CombatCalloutKind.yourTurn;
}

/// Signal global de combat **courant** (un seul à la fois), en mémoire
/// seulement : `null` sans signal.
///
/// Alimenté par le suivi de tous les groupes au premier plan
/// (`grimoireGroupsFollowerProvider`, [onSession]) et par les notifications
/// push reçues app ouverte ([showFromPush]). Retiré par l'utilisateur
/// ([dismiss]), à la fin du tour, à la fin ou à l'expiration du combat, à
/// l'exclusion, et dès que l'écran Combat du groupe concerné est affiché
/// ([RouteStackObserver]).
///
/// Règles de priorité : la variante tour l'emporte sur une annonce (une
/// annonce n'efface jamais un « À toi de jouer » affiché) ; une demande
/// d'initiative juste après « Combat ! » du même groupe garde « Combat ! »
/// (sa ligne 2 passe alors à « Envoie ton initiative »).
final combatCalloutControllerProvider =
    NotifierProvider<CombatCalloutController, CombatCallout?>(
      CombatCalloutController.new,
    );

class CombatCalloutController extends Notifier<CombatCallout?> {
  int _nextId = 0;
  late RouteStackObserver _routes;

  /// Dernier signal créé par groupe et par type : instant et origine.
  final Map<
    (String, CombatCalloutKind),
    ({DateTime at, CombatCalloutSource source})
  >
  _shown = {};

  @override
  CombatCallout? build() {
    _routes = ref.watch(routeStackObserverProvider);
    _routes.addListener(_onRoutesChanged);
    ref.onDispose(() => _routes.removeListener(_onRoutesChanged));
    _shown.clear();
    return null;
  }

  DateTime _now() => ref.read(combatClockProvider)();

  /// L'écran Combat de [groupId] est la page affichée (même sous une feuille
  /// modale) : l'écran signale lui-même, aucun callout.
  bool isCombatScreenOf(String groupId) =>
      _routes.visiblePageName == kGroupCombatRouteName &&
      _routes.visiblePageParameter('id') == groupId;

  void _onRoutesChanged() {
    final current = state;
    if (current != null && isCombatScreenOf(current.groupId)) state = null;
  }

  /// Retire le signal [id] (fermeture, ouverture du combat, minuterie).
  void dismiss(int id) {
    if (state?.id == id) state = null;
  }

  /// Changement de compte : plus aucun signal ni dédoublonnage du compte
  /// précédent.
  void reset() {
    _shown.clear();
    state = null;
  }

  /// Le groupe [groupId] n'est plus suivi (quitté, exclu) : son signal
  /// disparaît.
  void groupGone(String groupId) {
    if (state?.groupId == groupId) state = null;
  }

  /// Notification push reçue app ouverte (concurrence entre la présence et
  /// l'envoi) : le signal correspondant, sauf s'il vient d'être montré.
  void showFromPush(CombatNotificationTarget target) {
    _request(target.groupId, switch (target.type) {
      CombatNotificationType.combatStart => CombatCalloutKind.combatStart,
      CombatNotificationType.yourTurn => CombatCalloutKind.yourTurn,
    }, CombatCalloutSource.push);
  }

  /// Nouvel état du combat Grimoire du groupe [groupId] (identité du joueur
  /// [me]) : signaux à montrer pour les évènements **reçus**, signaux à
  /// retirer (fin du tour, fin ou expiration du combat, exclusion).
  void onSession(
    String groupId,
    GrimoireCombatSession? previous,
    GrimoireCombatSession next, {
    required GrimoireIdentity me,
  }) {
    final before = previous?.view;
    final view = next.view;
    final excluded = next.isExcluded && previous?.isExcluded != true;
    final gone = before != null && before.isAlive && !view.isAlive;
    if (excluded || gone) groupGone(groupId);
    final current = state;
    if (current != null &&
        current.groupId == groupId &&
        current.isTurn &&
        _turnOver(before, view, me)) {
      state = null;
    }
    if (previous == null || next.eventSerial == previous.eventSerial) return;
    for (final event in next.events) {
      switch (event.kind) {
        case GrimoireCombatEventKind.combatStarted:
          _request(
            groupId,
            CombatCalloutKind.combatStart,
            CombatCalloutSource.live,
          );
        case GrimoireCombatEventKind.initiativeRequested:
          _request(
            groupId,
            CombatCalloutKind.initiativeRequested,
            CombatCalloutSource.live,
          );
        case GrimoireCombatEventKind.yourTurn:
          _request(
            groupId,
            CombatCalloutKind.yourTurn,
            CombatCalloutSource.live,
          );
        case GrimoireCombatEventKind.ended:
        case GrimoireCombatEventKind.expired:
          groupGone(groupId);
        case GrimoireCombatEventKind.initiativeSent:
        case GrimoireCombatEventKind.initiativeReceived:
        case GrimoireCombatEventKind.initiativeCorrected:
        case GrimoireCombatEventKind.orderRevealed:
        case GrimoireCombatEventKind.turn:
        case GrimoireCombatEventKind.gmOffline:
        case GrimoireCombatEventKind.gmBack:
          break;
      }
    }
  }

  /// Le tour n'est plus celui du joueur : « À toi de jouer » a pris fin, ou
  /// la surbrillance est passée à un autre participant (connu) ou à aucun.
  /// Un signal venu d'une notification push avant tout état reste affiché
  /// tant qu'aucun état ne dit que le tour est passé.
  bool _turnOver(
    GrimoireCombatView? before,
    GrimoireCombatView view,
    GrimoireIdentity me,
  ) {
    if (before != null && before.yourTurn && !view.yourTurn) return true;
    if (view.yourTurn || view.status != GrimoireCombatStatus.active) {
      return false;
    }
    final currentId = view.currentParticipantId;
    if (before != null &&
        before.status == GrimoireCombatStatus.active &&
        before.currentParticipantId == currentId) {
      return false;
    }
    if (currentId == null) return true;
    final current = view.currentParticipant;
    return current != null && !GrimoireCombatView.isMine(current, me);
  }

  void _request(
    String groupId,
    CombatCalloutKind kind,
    CombatCalloutSource source,
  ) {
    // Écran Combat du groupe affiché : il signale lui-même.
    if (isCombatScreenOf(groupId)) return;
    final current = state;
    if (current != null) {
      // Déjà affiché : rien de neuf (ni haptique ni annonce répétées).
      if (current.groupId == groupId && current.kind == kind) return;
      // « Combat ! » du même groupe reste : sa ligne 2 propose l'initiative.
      if (kind == CombatCalloutKind.initiativeRequested &&
          current.groupId == groupId &&
          current.kind == CombatCalloutKind.combatStart) {
        return;
      }
      // Une annonce n'efface jamais « À toi de jouer ».
      if (current.isTurn && kind != CombatCalloutKind.yourTurn) return;
    }
    final now = _now();
    _shown.removeWhere(
      (_, shown) => now.difference(shown.at) >= kCombatCalloutDedupeWindow,
    );
    final last = _shown[(groupId, kind)];
    // Dédoublonnage (60 s) dès qu'une notification push est en jeu : la même
    // nouvelle arrive par les deux voies. Deux messages du canal sont deux
    // évènements distincts (ex. deux tours rapprochés).
    if (last != null &&
        !(last.source == CombatCalloutSource.live &&
            source == CombatCalloutSource.live)) {
      return;
    }
    _shown[(groupId, kind)] = (at: now, source: source);
    state = (id: ++_nextId, groupId: groupId, kind: kind);
  }
}
