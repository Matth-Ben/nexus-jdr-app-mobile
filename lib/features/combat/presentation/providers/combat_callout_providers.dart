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

/// Signal affiché : [id] croissant (un nouveau signal, même identique, a un
/// nouvel [id]), groupe et variante.
typedef CombatCallout = ({int id, String groupId, CombatCalloutKind kind});

/// Tour du joueur tel que le canal du groupe le décrit : combat, round et
/// participant. Deux tours du même joueur sont distincts dès que l'un des
/// trois change.
typedef GrimoireTurnKey = ({String combatId, int round, String participantId});

/// Délai pendant lequel le premier tour du joueur reçu sur le canal est la
/// même nouvelle qu'une notification push « À toi de jouer » reçue juste avant
/// (concurrence entre la présence et l'envoi).
const Duration kCombatCalloutPushMatchWindow = Duration(seconds: 60);

/// Durée d'affichage de la variante annonce (sauf `accessibleNavigation`).
const Duration kCombatCalloutAnnounceDuration = Duration(seconds: 10);

extension CombatCalloutTraits on CombatCallout {
  /// Variante tour (« À toi de jouer ») : jamais retirée par une minuterie.
  bool get isTurn => kind == CombatCalloutKind.yourTurn;
}

/// Tour en cours du joueur [me] dans [view] (ordre dévoilé, surbrillance sur
/// son `pc`), `null` sinon.
GrimoireTurnKey? grimoireTurnKeyOf(
  GrimoireCombatView view,
  GrimoireIdentity me,
) {
  final combatId = view.combatId;
  final current = view.currentParticipant;
  if (combatId == null ||
      view.status != GrimoireCombatStatus.active ||
      current == null ||
      !GrimoireCombatView.isMine(current, me)) {
    return null;
  }
  return (combatId: combatId, round: view.round, participantId: current.id);
}

/// Signal global de combat **courant** (un seul à la fois), en mémoire
/// seulement : `null` sans signal.
///
/// Alimenté par le suivi de tous les groupes au premier plan
/// (`grimoireGroupsFollowerProvider`, [onSession]) et par les notifications
/// push reçues app ouverte ([showFromPush]). Retiré par l'utilisateur
/// ([dismiss]), à la fin du tour, à la fin ou à l'expiration du combat, à
/// l'exclusion, et dès que l'écran Combat du groupe concerné est affiché
/// ([RouteStackObserver]). **Jamais pour le meneur** du groupe (`is_leader`) :
/// comme `notify-group`, qui n'envoie rien à l'appelant.
///
/// Règles de priorité : la variante tour l'emporte sur une annonce (une
/// annonce n'efface jamais un « À toi de jouer » affiché) ; une demande
/// d'initiative juste après « Combat ! » du même groupe garde « Combat ! »
/// (sa ligne 2 passe alors à « Envoie ton initiative »).
///
/// Dédoublonnage (arbitrage du 24/11/2026) : aucune fenêtre de temps, des
/// identités. Un tour est identifié par le combat, le round et le
/// participant ([GrimoireTurnKey]) ; une annonce de combat par le combat.
/// Une notification push est ignorée seulement si un signal du même groupe et
/// du même type est affiché, si le tour qu'elle annonce est déjà celui du
/// canal, ou si le combat qu'elle annonce a déjà été annoncé par le canal ;
/// sinon elle s'affiche. Le premier tour du joueur reçu ensuite sur le canal
/// (dans les 60 s) est la même nouvelle : pas de second signal.
final combatCalloutControllerProvider =
    NotifierProvider<CombatCalloutController, CombatCallout?>(
      CombatCalloutController.new,
    );

class CombatCalloutController extends Notifier<CombatCallout?> {
  int _nextId = 0;
  late RouteStackObserver _routes;

  /// Dernier tour signalé (ou rapproché d'une notification push) par groupe.
  final Map<String, GrimoireTurnKey> _turnKeys = {};

  /// Dernier combat annoncé par le canal, par groupe.
  final Map<String, String> _startKeys = {};

  /// Notification « À toi de jouer » affichée et pas encore rapprochée d'un
  /// tour du canal, par groupe.
  final Map<String, DateTime> _pushTurns = {};

  /// Dernier état connu du canal de chaque groupe suivi, avec l'identité du
  /// joueur.
  final Map<String, ({GrimoireCombatView view, GrimoireIdentity me})> _known =
      {};

  @override
  CombatCallout? build() {
    _routes = ref.watch(routeStackObserverProvider);
    _routes.addListener(_onRoutesChanged);
    ref.onDispose(() => _routes.removeListener(_onRoutesChanged));
    _clearMemory();
    return null;
  }

  void _clearMemory() {
    _turnKeys.clear();
    _startKeys.clear();
    _pushTurns.clear();
    _known.clear();
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

  /// Changement de compte : plus aucun signal ni mémoire du compte
  /// précédent.
  void reset() {
    _clearMemory();
    state = null;
  }

  /// Le groupe [groupId] n'est plus suivi (quitté, exclu) : son signal
  /// disparaît.
  void groupGone(String groupId) {
    if (state?.groupId == groupId) state = null;
  }

  /// Notification push reçue app ouverte (concurrence entre la présence et
  /// l'envoi) : le signal correspondant, sauf s'il est déjà affiché ou si le
  /// canal du groupe a déjà donné cette nouvelle (même tour, même combat).
  void showFromPush(CombatNotificationTarget target) {
    final groupId = target.groupId;
    final known = _known[groupId];
    switch (target.type) {
      case CombatNotificationType.combatStart:
        final view = known?.view;
        if (view != null &&
            view.isRunning &&
            view.combatId != null &&
            view.combatId == _startKeys[groupId]) {
          return;
        }
        _request(groupId, CombatCalloutKind.combatStart);
      case CombatNotificationType.yourTurn:
        if (known != null && grimoireTurnKeyOf(known.view, known.me) != null) {
          return;
        }
        final current = state;
        if (current != null &&
            current.groupId == groupId &&
            current.kind == CombatCalloutKind.yourTurn) {
          return;
        }
        _pushTurns[groupId] = _now();
        _request(groupId, CombatCalloutKind.yourTurn);
    }
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
    _known[groupId] = (view: view, me: me);
    // Le meneur suit le combat comme les joueurs, sans signal global.
    if (next.isLeader) {
      groupGone(groupId);
      return;
    }
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
    _matchPushTurn(groupId, view, me);
    if (previous == null || next.eventSerial == previous.eventSerial) return;
    for (final event in next.events) {
      switch (event.kind) {
        case GrimoireCombatEventKind.combatStarted:
          final combatId = view.combatId;
          if (combatId != null && _startKeys[groupId] == combatId) break;
          if (combatId != null) _startKeys[groupId] = combatId;
          _request(groupId, CombatCalloutKind.combatStart);
        case GrimoireCombatEventKind.initiativeRequested:
          _request(groupId, CombatCalloutKind.initiativeRequested);
        case GrimoireCombatEventKind.yourTurn:
          final key = grimoireTurnKeyOf(view, me);
          if (key != null && _turnKeys[groupId] == key) break;
          if (key != null) _turnKeys[groupId] = key;
          _request(groupId, CombatCalloutKind.yourTurn);
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

  /// Une notification « À toi de jouer » attend le tour du canal qui la
  /// confirme : le premier état (ou `turn`) dont la surbrillance est connue
  /// règle la question. Sur le joueur : c'est ce tour-là (aucun second
  /// signal) ; sur un autre : le tour annoncé est passé.
  void _matchPushTurn(
    String groupId,
    GrimoireCombatView view,
    GrimoireIdentity me,
  ) {
    final pushedAt = _pushTurns[groupId];
    if (pushedAt == null) return;
    if (_now().difference(pushedAt) >= kCombatCalloutPushMatchWindow) {
      _pushTurns.remove(groupId);
      return;
    }
    if (view.status != GrimoireCombatStatus.active ||
        view.currentParticipantId == null) {
      return;
    }
    _pushTurns.remove(groupId);
    final key = grimoireTurnKeyOf(view, me);
    if (key != null) _turnKeys[groupId] = key;
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

  void _request(String groupId, CombatCalloutKind kind) {
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
    state = (id: ++_nextId, groupId: groupId, kind: kind);
  }
}
