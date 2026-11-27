import 'package:freezed_annotation/freezed_annotation.dart';

import 'grimoire_combat_reducer.dart';
import 'grimoire_combat_view.dart';

part 'grimoire_combat_session.freezed.dart';

/// État du lien temps réel avec le sujet `:gm` d'un groupe.
enum GrimoireLinkStatus {
  /// Personne n'écoute ce groupe (aucun écran ne l'observe, ou app en
  /// arrière-plan : canal quitté, présence retirée).
  idle,

  /// Lecture des sujets et abonnement en cours.
  connecting,

  /// Canal `SUBSCRIBED`.
  subscribed,

  /// Canal en erreur, fermé ou trop long à s'ouvrir : réabonnement prévu.
  down,

  /// `group_not_found` : plus membre du groupe, plus aucun essai.
  lost,

  /// API absente de ce projet (`PGRST106`, `PGRST202`) : plus aucun essai,
  /// comme si aucun combat n'était en cours (aucun écran d'erreur).
  unavailable,
}

/// Fraîcheur affichée, par priorité (spec `docs/combat-grimoire-ui.md` §7).
enum GrimoireDisplayLiveness {
  /// Affichage normal.
  normal,

  /// Téléphone hors ligne ou canal pas `SUBSCRIBED` : « Hors ligne · dernier
  /// état connu ». Jamais « MJ hors ligne » dans ce cas.
  offline,

  /// 90 s sans message : « MJ hors ligne ».
  gmOffline,

  /// 10 min sans message : bandeaux retirés, « Pas de nouvelles du MJ ».
  expired,
}

/// Combat mené depuis Grimoire pour un groupe, tel que Nexus le suit :
/// [view] (modèle de vue pur), lien temps réel, rôle de meneur et derniers
/// évènements reçus. **Mémoire seulement**, purgée au changement de compte.
@freezed
abstract class GrimoireCombatSession with _$GrimoireCombatSession {
  const GrimoireCombatSession._();

  const factory GrimoireCombatSession({
    @Default(GrimoireCombatView()) GrimoireCombatView view,
    @Default(GrimoireLinkStatus.idle) GrimoireLinkStatus link,

    /// Entrée dans l'état [link] courant (horloge de Nexus).
    DateTime? linkSince,

    /// `is_leader` de `api_v1.group_live_channels` : le compte mène ce combat
    /// depuis Grimoire (bandeau d'information, aucun contrôle).
    @Default(false) bool isLeader,

    /// Incrémenté à chaque lot d'évènements reçus ([events]).
    @Default(0) int eventSerial,
    @Default(<GrimoireCombatEvent>[]) List<GrimoireCombatEvent> events,
  }) = _GrimoireCombatSession;

  /// Fin de l'attente après un (ré)abonnement : aucune conclusion sur le
  /// silence du MJ avant (réponse au `state_request`).
  DateTime? get graceUntil {
    final since = linkSince;
    if (since == null) return null;
    if (link != GrimoireLinkStatus.connecting &&
        link != GrimoireLinkStatus.subscribed) {
      return null;
    }
    return since.add(kGrimoireResyncGrace);
  }

  /// Le silence du MJ peut-il être jugé ? Jamais au repos (app en
  /// arrière-plan, personne n'écoute), après une exclusion ni sans API : au
  /// retour, l'attente de 5 s s'applique d'abord, puis l'expiration si rien
  /// n'arrive.
  bool get evaluatesSilence =>
      link != GrimoireLinkStatus.idle &&
      link != GrimoireLinkStatus.lost &&
      link != GrimoireLinkStatus.unavailable;

  /// `group_not_found` : le joueur ne fait plus partie du groupe (exclu ou
  /// parti, décision 50). Canal fermé, vue effacée.
  bool get isExcluded => link == GrimoireLinkStatus.lost;

  /// Le canal est-il inutilisable (pas `SUBSCRIBED`, hors ouverture en cours) ?
  bool get linkDown =>
      link == GrimoireLinkStatus.down ||
      link == GrimoireLinkStatus.lost ||
      link == GrimoireLinkStatus.unavailable ||
      link == GrimoireLinkStatus.idle;

  /// Fraîcheur affichée, par priorité : expiré, puis téléphone hors ligne ou
  /// canal coupé, puis MJ hors ligne, puis normal.
  GrimoireDisplayLiveness displayLiveness({required bool phoneOnline}) {
    if (view.liveness == GrimoireLiveness.expired) {
      return GrimoireDisplayLiveness.expired;
    }
    if (!phoneOnline || linkDown) return GrimoireDisplayLiveness.offline;
    if (view.liveness == GrimoireLiveness.gmOffline) {
      return GrimoireDisplayLiveness.gmOffline;
    }
    return GrimoireDisplayLiveness.normal;
  }
}
