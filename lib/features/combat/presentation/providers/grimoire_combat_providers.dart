import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/grimoire_combat_gateway.dart';
import '../../data/grimoire_message_decoder.dart';
import '../../domain/grimoire_combat_reducer.dart';
import '../../domain/grimoire_combat_session.dart';
import '../../domain/grimoire_combat_view.dart';
import '../../domain/grimoire_failure.dart';
import '../../domain/grimoire_message.dart';
import 'combat_providers.dart';

/// Passerelle du combat mené depuis Grimoire (surchargeable en test).
final grimoireCombatGatewayProvider = Provider<GrimoireCombatGateway>(
  (ref) => SupabaseGrimoireCombatGateway(
    ref.watch(supabaseClientProvider),
    ref.watch(connectivityCheckerProvider),
  ),
);

/// Écart minimal entre deux `state_request` (Grimoire n'en traite qu'un par
/// joueur toutes les 2 s ; plusieurs demandes rapprochées sont regroupées).
const Duration kGrimoireStateRequestGap = Duration(seconds: 2);

/// Délais de réabonnement après une erreur de canal ou de lecture des sujets.
const List<Duration> kGrimoireRetryDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 30),
];

/// Combat mené depuis Grimoire du groupe [groupId], tel que suivi par Nexus.
///
/// **Mémoire seulement** (`keepAlive`, jamais persisté, rien dans `drift`),
/// purgé au changement de compte. Les transitions sont celles, pures, de
/// `grimoire_combat_reducer.dart` ; ce fournisseur n'ajoute que l'horloge
/// injectée ([combatClockProvider]), les minuteries d'expiration et les
/// envois vers le meneur (`state_request`, initiative).
///
/// Les minuteries ne tournent que tant qu'un écran observe le groupe
/// ([grimoireCombatWatcherProvider] l'attache) : sans écoute, rien ne vit.
final grimoireCombatProvider =
    NotifierProvider.family<
      GrimoireCombatNotifier,
      GrimoireCombatSession,
      String
    >(GrimoireCombatNotifier.new);

class GrimoireCombatNotifier extends Notifier<GrimoireCombatSession> {
  GrimoireCombatNotifier(this.groupId);

  final String groupId;

  int _attached = 0;
  Timer? _tickTimer;
  Timer? _stateRequestTimer;
  Timer? _afterSendTimer;
  DateTime? _lastStateRequestAt;
  GrimoireIdentity? _identity;

  /// Le prochain `state` est la réponse à un (ré)abonnement : appliqué sans
  /// annonce.
  bool _resyncing = false;

  /// Génération : un envoi lancé avant une purge (changement de compte)
  /// n'écrit jamais dans l'état du compte suivant.
  int _epoch = 0;

  @override
  GrimoireCombatSession build() {
    _epoch++;
    _cancelTimers();
    _identity = null;
    _resyncing = false;
    _lastStateRequestAt = null;
    ref.onDispose(_cancelTimers);
    ref
      ..listen<String?>(currentUserProvider.select((user) => user?.id), (
        previous,
        next,
      ) {
        if (previous != next) ref.invalidateSelf();
      })
      // Téléphone de nouveau en ligne ou coupé : les conclusions sur le
      // silence du MJ sont réévaluées (jamais « MJ hors ligne » hors ligne).
      ..listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
        if (previous?.value != next.value) _tick();
      });
    return const GrimoireCombatSession();
  }

  DateTime _now() => ref.read(combatClockProvider)();

  GrimoireCombatGateway get _gateway => ref.read(grimoireCombatGatewayProvider);

  bool get _phoneOnline => ref.read(connectivityStatusProvider).value != false;

  /// Identité du joueur : fournie par les écrans qui connaissent le détail du
  /// groupe (ou le personnage de la fiche) ; à défaut, le compte connecté.
  GrimoireIdentity? get _me {
    final identity = _identity;
    if (identity != null) return identity;
    final userId = ref.read(currentUserProvider)?.id;
    return userId == null ? null : (userId: userId, characterId: null);
  }

  /// Compte et personnage courant du joueur dans ce groupe. Une demande
  /// d'initiative déjà reçue est réévaluée sans annonce.
  void setIdentity(GrimoireIdentity identity) {
    if (_identity == identity) return;
    _identity = identity;
    final view = reconcileGrimoireInitiative(state.view, identity);
    if (view != state.view) state = state.copyWith(view: view);
  }

  // --------------------------------------------------------- attache

  /// Un écran observe le groupe : le lien s'ouvre (attente de 5 s avant toute
  /// conclusion sur le silence du MJ) et les minuteries reprennent.
  void attach() {
    _attached++;
    if (_attached == 1) setLink(GrimoireLinkStatus.connecting);
  }

  /// Plus aucun écran n'observe le groupe : toutes les minuteries s'arrêtent
  /// (aucun changement d'état : personne ne l'affiche).
  void detach() {
    if (_attached == 0) return;
    _attached--;
    if (_attached == 0) _cancelTimers();
  }

  void _cancelTimers() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _stateRequestTimer?.cancel();
    _stateRequestTimer = null;
    _afterSendTimer?.cancel();
    _afterSendTimer = null;
  }

  // ------------------------------------------------------------- lien

  /// Lien en cours d'ouverture, `SUBSCRIBED`, coupé ou au repos. Une
  /// exclusion passe par [markExcluded].
  void setLink(GrimoireLinkStatus link, {bool? isLeader}) {
    if (link == GrimoireLinkStatus.subscribed) _resyncing = true;
    state = state.copyWith(
      link: link,
      linkSince: _now(),
      isLeader: isLeader ?? state.isLeader,
    );
    _tick();
  }

  /// `group_not_found` (lecture des sujets, `state_request`, initiative) :
  /// le joueur ne fait plus partie du groupe (décision 50). La vue Grimoire
  /// est effacée et le lien passe à « perdu » : le canal est fermé
  /// ([grimoireCombatWatcherProvider] y veille) et plus rien n'est tenté.
  void markExcluded() {
    if (state.isExcluded && state.view == const GrimoireCombatView()) return;
    _cancelTimers();
    _resyncing = false;
    state = GrimoireCombatSession(
      link: GrimoireLinkStatus.lost,
      linkSince: _now(),
      eventSerial: state.eventSerial,
    );
  }

  // --------------------------------------------------------- messages

  /// Broadcast reçu sur `:gm` (déjà débarrassé de l'enveloppe Phoenix).
  void receive(Map<String, dynamic> payload) {
    final message = decodeGrimoireMessage(payload);
    final me = _me;
    if (message == null || me == null || state.isExcluded) return;
    final now = _now();
    final graceUntil = state.graceUntil;
    final step = applyGrimoireMessage(
      state.view,
      message,
      me: me,
      receivedAt: now,
      resyncing: _resyncing && (graceUntil == null || now.isBefore(graceUntil)),
    );
    if (message is GrimoireState) _resyncing = false;
    _applyStep(step);
    if (step.requestState) requestState();
  }

  void _applyStep(GrimoireStep step) {
    final events = step.events;
    if (step.view == state.view && events.isEmpty) return;
    state = state.copyWith(
      view: step.view,
      events: events.isEmpty ? state.events : events,
      eventSerial: events.isEmpty ? state.eventSerial : state.eventSerial + 1,
    );
    _reschedule();
  }

  // -------------------------------------------------------- minuterie

  void _tick() {
    final now = _now();
    var session = state;
    // Ouverture trop longue : le canal est considéré coupé.
    if (session.link == GrimoireLinkStatus.connecting &&
        session.linkSince != null &&
        !now.isBefore(session.linkSince!.add(kGrimoireResyncGrace))) {
      session = session.copyWith(link: GrimoireLinkStatus.down, linkSince: now);
      state = session;
    }
    // Au repos (arrière-plan) : aucune conclusion sur le silence du MJ ; au
    // retour, l'attente de 5 s passe d'abord.
    if (session.evaluatesSilence) {
      _applyStep(
        tickGrimoireCombat(
          session.view,
          now: now,
          canJudgeGm:
              session.link == GrimoireLinkStatus.subscribed && _phoneOnline,
          graceUntil: session.graceUntil,
        ),
      );
    }
    _reschedule();
  }

  void _reschedule() {
    _tickTimer?.cancel();
    _tickTimer = null;
    final session = state;
    if (_attached == 0 || !session.evaluatesSilence) return;
    final now = _now();
    final deadlines = [
      ?nextGrimoireDeadline(
        session.view,
        now: now,
        graceUntil: session.graceUntil,
      ),
      if (session.link == GrimoireLinkStatus.connecting &&
          session.linkSince != null)
        session.linkSince!.add(kGrimoireResyncGrace),
    ].where((instant) => instant.isAfter(now)).toList()..sort();
    if (deadlines.isEmpty) return;
    _tickTimer = Timer(deadlines.first.difference(now), () {
      _tickTimer = null;
      if (ref.mounted) _tick();
    });
  }

  // ---------------------------------------------------- vers le meneur

  /// Demande l'état complet (`state_request`) : après `SUBSCRIBED`, sur un
  /// trou de `seq`, 2 s après un envoi d'initiative. Regroupé (au plus un
  /// toutes les 2 s), jamais hors ligne ni sans canal. Sans `combat_id` :
  /// Grimoire répond avec son combat en cours, quel qu'il soit.
  void requestState() {
    if (_attached == 0 ||
        state.link != GrimoireLinkStatus.subscribed ||
        !_phoneOnline) {
      return;
    }
    final now = _now();
    final last = _lastStateRequestAt;
    if (last == null || now.difference(last) >= kGrimoireStateRequestGap) {
      _sendStateRequest();
      return;
    }
    _stateRequestTimer ??= Timer(
      kGrimoireStateRequestGap - now.difference(last),
      () {
        _stateRequestTimer = null;
        if (ref.mounted) _sendStateRequest();
      },
    );
  }

  void _sendStateRequest() {
    _lastStateRequestAt = _now();
    final epoch = _epoch;
    unawaited(
      _gateway
          .sendToLeader(
            groupId: groupId,
            type: 'state_request',
            payload: const <String, Object?>{},
          )
          .catchError((Object error) {
            if (!ref.mounted || epoch != _epoch) return;
            if (error is GrimoireFailure &&
                error.kind == GrimoireFailureKind.groupNotFound) {
              markExcluded();
            }
          }),
    );
  }

  /// Envoie l'initiative [value] du joueur au meneur
  /// (`send_to_group_leader`, type `initiative`). L'échec est rangé dans
  /// l'état (jamais levé) ; un envoi réussi redemande l'état 2 s plus tard
  /// (accusé de réception rapide, arbitrage Q3).
  Future<void> sendInitiative(int value) async {
    final view = state.view;
    final combatId = view.combatId;
    if (combatId == null ||
        !view.isRunning ||
        view.initiative.status == GrimoireInitiativeStatus.sending) {
      return;
    }
    final epoch = _epoch;
    state = state.copyWith(view: markInitiativeSending(view));
    try {
      await _gateway.sendToLeader(
        groupId: groupId,
        type: 'initiative',
        payload: {'combat_id': combatId, 'initiative': value},
      );
      if (!ref.mounted || epoch != _epoch) return;
      _applyStep(
        markInitiativeSent(
          state.view,
          combatId: combatId,
          value: value,
          at: _now(),
        ),
      );
      _afterSendTimer?.cancel();
      _afterSendTimer = _attached == 0
          ? null
          : Timer(kGrimoireStateRequestAfterSend, () {
              _afterSendTimer = null;
              if (ref.mounted) requestState();
            });
    } on Object catch (error) {
      if (!ref.mounted || epoch != _epoch) return;
      final failure = error is GrimoireFailure
          ? error
          : GrimoireFailure(GrimoireFailureKind.other, rawMessage: '$error');
      state = state.copyWith(
        view: markInitiativeFailed(
          state.view,
          combatId: combatId,
          failure: failure,
        ),
      );
      if (failure.kind == GrimoireFailureKind.groupNotFound) {
        markExcluded();
      }
    }
  }
}

/// Abonnement au sujet `:gm` du groupe [groupId] — fournisseur à effet de
/// bord pur, à `ref.watch` depuis l'écran Groupe, l'écran Combat et le
/// bandeau de la fiche : il ne vit que tant qu'ils l'observent
/// (`autoDispose`). Un seul canal par groupe.
///
/// - Sujets lus par `api_v1.group_live_channels` (jamais construits ici) ;
///   `group_not_found` : plus aucun essai.
/// - Canal **privé** ; après `SUBSCRIBED` : présence (`track`) puis
///   `state_request`.
/// - Présence **seulement au premier plan** (arbitrage Q2) : en arrière-plan
///   le canal est quitté (la présence disparaît avec lui), au retour il est
///   rouvert (réabonnement, `state_request`).
/// - Réabonnement sur `channel_rotated`, `CHANNEL_ERROR`, fermeture ou délai
///   dépassé (ancien canal retiré d'abord, sujets relus), et au retour du
///   réseau.
final grimoireCombatWatcherProvider = Provider.autoDispose.family<void, String>(
  (ref, groupId) {
    final gateway = ref.watch(grimoireCombatGatewayProvider);
    final connectivity = ref.watch(connectivityCheckerProvider);
    final userId = ref.watch(currentUserProvider.select((user) => user?.id));
    if (userId == null) return;
    final notifier = ref.read(grimoireCombatProvider(groupId).notifier);
    final controller = _GrimoireLinkController(
      groupId: groupId,
      userId: userId,
      gateway: gateway,
      notifier: notifier,
      isMounted: () => ref.mounted,
    );
    // Garde le suivi actif (et son écoute du réseau) tant qu'un écran observe
    // le groupe ; une exclusion signalée par un envoi ferme le canal.
    ref.listen<bool>(
      grimoireCombatProvider(groupId).select((session) => session.isExcluded),
      (previous, excluded) {
        if (excluded) controller.excluded();
      },
    );
    final binding = WidgetsBinding.instance;
    final observer = _GrimoireLifecycleObserver(
      onForeground: controller.foreground,
      onBackground: controller.background,
    );
    binding.addObserver(observer);
    // Jamais d'écriture dans un autre fournisseur pendant cette construction ;
    // l'état de l'app est lu au moment d'agir (il a pu changer entre-temps).
    Future.microtask(() {
      if (!ref.mounted) return;
      notifier.attach();
      final lifecycle = binding.lifecycleState;
      if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
        controller.foreground();
      } else {
        controller.background();
      }
    });
    final restored = connectivity.onConnectivityRestored.listen(
      (_) => controller.networkRestored(),
    );
    ref.onDispose(() {
      binding.removeObserver(observer);
      unawaited(restored.cancel());
      controller.dispose();
      notifier.detach();
    });
  },
);

/// Ouverture, réabonnement et fermeture du canal `:gm` d'un groupe.
///
/// **Sérialisé** : une seule opération (fermeture, lecture des sujets,
/// ouverture) à la fois, conduite par [_run] ; les évènements (premier plan,
/// arrière-plan, rotation, erreur, retour du réseau, exclusion) ne font que
/// poser l'intention, et la **dernière intention l'emporte**. L'ancien canal
/// est toujours fermé avant qu'un nouveau soit gardé ; en arrière-plan, aucun
/// canal ni présence ne reste actif.
class _GrimoireLinkController {
  _GrimoireLinkController({
    required this.groupId,
    required this.userId,
    required this.gateway,
    required this.notifier,
    required this.isMounted,
  });

  final String groupId;
  final String userId;
  final GrimoireCombatGateway gateway;
  final GrimoireCombatNotifier notifier;
  final bool Function() isMounted;

  /// Canal gardé (ouvert ou en cours d'abonnement).
  GrimoireGmLink? _link;

  /// Intention : canal voulu (premier plan) ou non (arrière-plan, libéré).
  bool _wantOpen = false;

  /// Le canal gardé doit être remplacé (rotation d'époque, erreur).
  bool _needsFresh = false;

  /// `group_not_found` : plus aucun essai, canal fermé.
  bool _lost = false;
  bool _disposed = false;

  Timer? _retry;
  int _attempt = 0;

  /// Opération en cours, et nouvelle évaluation demandée pendant celle-ci.
  Future<void>? _running;
  bool _rerun = false;

  /// Génération du canal gardé : les signaux d'un canal remplacé ou fermé
  /// par nous sont ignorés.
  int _generation = 0;

  bool get _active => !_disposed && isMounted();

  /// Premier plan (y compris `resumed` après le volet de notifications) :
  /// canal voulu ; un canal déjà gardé n'est pas rouvert.
  void foreground() {
    _wantOpen = true;
    _kick();
  }

  /// Arrière-plan : canal quitté (la présence disparaît avec lui).
  void background() {
    _wantOpen = false;
    _cancelRetry();
    if (_active && !_lost) notifier.setLink(GrimoireLinkStatus.idle);
    _kick();
  }

  /// Rotation d'époque (`channel_rotated`) : nouveau sujet à relire.
  void _rotated() {
    _needsFresh = true;
    _cancelRetry();
    _kick();
  }

  void networkRestored() {
    if (_retry == null) return;
    _cancelRetry();
    _kick();
  }

  /// Exclusion signalée par un envoi (`group_not_found`) : canal fermé.
  void excluded() {
    if (_lost) return;
    _lost = true;
    _cancelRetry();
    _kick();
  }

  void dispose() {
    _disposed = true;
    _cancelRetry();
    _kick();
  }

  void _cancelRetry() {
    _retry?.cancel();
    _retry = null;
  }

  void _kick() {
    if (_running != null) {
      _rerun = true;
      return;
    }
    _running = _run().whenComplete(() {
      _running = null;
      if (_rerun) {
        _rerun = false;
        _kick();
      }
    });
  }

  /// Ferme le canal gardé (toujours avant d'en garder un autre).
  Future<void> _closeLink() async {
    _generation++;
    final link = _link;
    _link = null;
    if (link == null) return;
    try {
      await link.close();
    } on Object {
      // Canal déjà fermé : rien à faire.
    }
  }

  /// Conduit le canal vers l'intention courante, réévaluée après chaque
  /// attente.
  Future<void> _run() async {
    while (true) {
      _rerun = false;
      final wanted = _active && _wantOpen && !_lost;
      if (!wanted) {
        if (_link == null) return;
        await _closeLink();
        continue;
      }
      if (_link != null) {
        if (!_needsFresh) return;
        await _closeLink();
        continue;
      }
      // Nouvel essai programmé : on l'attend.
      if (_retry != null) return;
      _needsFresh = false;
      notifier.setLink(GrimoireLinkStatus.connecting);
      final GrimoireLiveTopics topics;
      try {
        // Jamais un sujet construit soi-même : l'époque a pu changer.
        topics = await gateway.fetchLiveChannels(groupId);
      } on GrimoireFailure catch (failure) {
        if (!_active) continue;
        if (failure.kind == GrimoireFailureKind.groupNotFound) {
          _lost = true;
          notifier.markExcluded();
        } else {
          _scheduleRetry();
        }
        continue;
      } on Object {
        if (_active) _scheduleRetry();
        continue;
      }
      // L'intention a pu changer pendant la lecture (arrière-plan...).
      if (!_active || !_wantOpen || _lost || _link != null) continue;
      final generation = ++_generation;
      _link = gateway.openGmChannel(
        topic: topics.gmTopic,
        presenceKey: userId,
        onBroadcast: (raw) {
          if (generation == _generation) _onBroadcast(raw);
        },
        onSignal: (signal) {
          if (generation == _generation) _onSignal(signal, topics.isLeader);
        },
      );
    }
  }

  void _onBroadcast(Map<String, dynamic> raw) {
    if (!_active) return;
    final payload = unwrapGrimoireBroadcast(raw);
    if (payload == null) return;
    if (isGrimoireChannelRotated(payload)) {
      _rotated();
      return;
    }
    notifier.receive(payload);
  }

  void _onSignal(GrimoireChannelSignal signal, bool isLeader) {
    if (!_active) return;
    switch (signal) {
      case GrimoireChannelSignal.subscribed:
        _attempt = 0;
        notifier.setLink(GrimoireLinkStatus.subscribed, isLeader: isLeader);
        final link = _link;
        // Présence seulement au premier plan, sur le canal gardé.
        if (_wantOpen && !_lost && link != null) {
          unawaited(
            link.trackPresence().catchError((Object _) {
              // Présence non annoncée : Grimoire notifiera ce joueur par push,
              // sans autre conséquence.
            }),
          );
        }
        notifier.requestState();
      case GrimoireChannelSignal.error:
      case GrimoireChannelSignal.closed:
      case GrimoireChannelSignal.timedOut:
        // Le client réessaierait en boucle sur le même sujet : retirer le
        // canal et relire les sujets plus tard.
        _needsFresh = true;
        _scheduleRetry();
        _kick();
    }
  }

  void _scheduleRetry() {
    if (!_active || !_wantOpen || _lost) return;
    notifier.setLink(GrimoireLinkStatus.down);
    final delay =
        kGrimoireRetryDelays[_attempt.clamp(
          0,
          kGrimoireRetryDelays.length - 1,
        )];
    _attempt++;
    _retry?.cancel();
    _retry = Timer(delay, () {
      _retry = null;
      _kick();
    });
  }
}

class _GrimoireLifecycleObserver with WidgetsBindingObserver {
  _GrimoireLifecycleObserver({
    required this.onForeground,
    required this.onBackground,
  });

  final void Function() onForeground;
  final void Function() onBackground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onForeground();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        onBackground();
      case AppLifecycleState.inactive:
        break;
    }
  }
}

/// `true` tant qu'un combat Grimoire est **vivant** dans le groupe
/// [groupId] (annoncé, pas terminé, pas expiré) : il est affiché en priorité
/// et « Lancer un combat » (natif) est désactivé (décision 61).
final grimoireCombatAliveProvider = Provider.family<bool, String>(
  (ref, groupId) => ref.watch(
    grimoireCombatProvider(groupId).select((session) => session.view.isAlive),
  ),
);
