import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/combat_providers.dart';
import '../providers/combat_read_only_provider.dart';
import '../providers/grimoire_banner_provider.dart';
import 'combat_banner.dart';

/// Bandeau « Combat en cours · round N » de la **fiche** d'un personnage
/// (variante [CombatBannerVariant.sheet] de [CombatBannerView]) pour le groupe
/// [groupId] : une ligne, tappable vers l'écran Combat. Hors ligne ou état
/// périmé : « … · état de HH:MM » (jamais un second « Hors ligne »).
///
/// Un combat mené depuis Grimoire vivant passe avant le combat natif
/// (décision 61) : préparation, « À toi de jouer », « MJ hors ligne ».
///
/// Ne s'abonne qu'aux champs utiles (`select`) : un évènement de combat sans
/// rapport ne le reconstruit pas. [compact] : forme compacte (D211) quand le
/// bandeau de synchro affiche déjà une alerte ou « Hors ligne ».
class CombatSheetBanner extends ConsumerWidget {
  const CombatSheetBanner({
    required this.groupId,
    required this.onOpen,
    this.compact = false,
    this.characterId,
    super.key,
  });

  final String groupId;
  final bool compact;
  final void Function(String groupId) onOpen;

  /// Personnage de la fiche (personnage courant du joueur dans [groupId]),
  /// transmis avec le compte connecté au suivi du combat Grimoire.
  final String? characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = characterId;
    if (character != null) {
      final userId = ref.watch(currentUserProvider.select((user) => user?.id));
      syncGrimoireIdentity(
        context,
        ref,
        groupId,
        userId == null ? null : (userId: userId, characterId: character),
      );
    }
    final grimoire = ref.watch(grimoireBannerProvider(groupId));
    if (grimoire != null) {
      return CombatBannerView(
        variant: CombatBannerVariant.sheet,
        compact: compact,
        mode: grimoire.mode,
        round: grimoire.round,
        offlineSince: grimoire.offlineSince,
        gmOfflineSince: grimoire.gmOfflineSince,
        initiativeHint: grimoire.initiativeHint,
        onTap: () => onOpen(groupId),
      );
    }
    final info = ref.watch(combatBannerProvider(groupId));
    if (info == null) return const SizedBox.shrink();
    final readOnly = ref.watch(combatReadOnlyProvider(groupId));
    // L'horodatage ne bouge que hors ligne : en ligne il n'est pas observé.
    final since = readOnly
        ? ref.watch(
            combatProvider(groupId).select((state) => state.lastKnownAt),
          )
        : null;
    return CombatBannerView(
      variant: CombatBannerVariant.sheet,
      compact: compact,
      round: info.round,
      offlineSince: readOnly ? (since ?? DateTime.now()) : null,
      onTap: () => onOpen(groupId),
    );
  }
}
