import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../domain/grimoire_combat_session.dart';
import '../../domain/grimoire_combat_view.dart';
import '../widgets/combat_banner_mode.dart';
import 'grimoire_combat_providers.dart';
import 'grimoire_groups_providers.dart';

/// Contenu des bandeaux Groupe et fiche d'un combat mené depuis Grimoire.
/// Un record : égalité structurelle, un message sans rapport ne reconstruit
/// rien.
typedef GrimoireBannerInfo = ({
  CombatBannerMode mode,
  int round,
  String? turnName,
  DateTime? offlineSince,
  DateTime? gmOfflineSince,
  CombatBannerInitiativeHint initiativeHint,
});

/// Bandeau du combat Grimoire du groupe [groupId] : `null` sans combat
/// **vivant** (aucun, terminé, ou expiré après 10 min sans message : le
/// bandeau est alors retiré) ou si le joueur ne fait plus partie du
/// groupe. Priorité d'affichage du §7 : téléphone hors
/// ligne ou canal coupé (« Hors ligne · état de… »), puis MJ hors ligne.
final grimoireBannerProvider = Provider.family<GrimoireBannerInfo?, String>((
  ref,
  groupId,
) {
  final session = ref.watch(grimoireCombatProvider(groupId));
  final view = session.view;
  // Joueur exclu (`group_not_found`) : bandeau retiré tout de suite, sans
  // texte (décision 50).
  if (session.isExcluded || !view.isAlive) return null;
  final online = ref.watch(connectivityStatusProvider).value != false;
  final liveness = session.displayLiveness(phoneOnline: online);
  final lastState = view.lastSentAt ?? view.lastReceivedAt;
  final preparing = view.status == GrimoireCombatStatus.preparing;
  final initiative = view.initiative;
  return (
    mode: view.yourTurn
        ? CombatBannerMode.yourTurn
        : preparing
        ? CombatBannerMode.preparing
        : CombatBannerMode.standard,
    round: view.round,
    turnName: view.currentParticipant?.name,
    offlineSince: liveness == GrimoireDisplayLiveness.offline
        ? lastState
        : null,
    gmOfflineSince: liveness == GrimoireDisplayLiveness.gmOffline
        ? lastState
        : null,
    initiativeHint: !preparing || view.removedFromCombat
        ? CombatBannerInitiativeHint.none
        : initiative.canSend
        ? CombatBannerInitiativeHint.send
        : initiative.status == GrimoireInitiativeStatus.sent ||
              initiative.status == GrimoireInitiativeStatus.sending
        ? CombatBannerInitiativeHint.sent
        : CombatBannerInitiativeHint.none,
  );
});

/// Transmet au suivi du combat Grimoire de [groupId] l'identité du joueur
/// (compte et personnage courant), connue des écrans qui l'affichent. Appelé
/// à chaque construction : l'écriture a lieu après l'image, et seulement si
/// l'identité change (jamais pendant une construction).
///
/// Signale aussi le groupe au suivi de tous les groupes (s'il tourne) : un
/// groupe tout juste créé ou rejoint, ou un personnage changé, y entre sans
/// attendre le prochain retour au premier plan.
void syncGrimoireIdentity(
  BuildContext context,
  WidgetRef ref,
  String groupId,
  GrimoireIdentity? identity,
) {
  if (identity == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ref.read(grimoireCombatProvider(groupId).notifier).setIdentity(identity);
    if (ref.exists(myGroupMembershipsProvider)) {
      ref
          .read(myGroupMembershipsProvider.notifier)
          .noteGroupSeen(groupId, characterId: identity.characterId);
    }
  });
}
