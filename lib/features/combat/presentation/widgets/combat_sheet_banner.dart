import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/combat_providers.dart';
import '../providers/combat_read_only_provider.dart';
import 'combat_banner.dart';

/// Bandeau « Combat en cours · round N » de la **fiche** d'un personnage
/// (variante [CombatBannerVariant.sheet] de [CombatBannerView]) pour le groupe
/// [groupId] : une ligne, tappable vers l'écran Combat. Hors ligne ou état
/// périmé : « … · état de HH:MM » (jamais un second « Hors ligne »).
///
/// Ne s'abonne qu'aux champs utiles (`select`) : un évènement de combat sans
/// rapport ne le reconstruit pas. [compact] : forme compacte (D211) quand le
/// bandeau de synchro affiche déjà une alerte ou « Hors ligne ».
class CombatSheetBanner extends ConsumerWidget {
  const CombatSheetBanner({
    required this.groupId,
    required this.onOpen,
    this.compact = false,
    super.key,
  });

  final String groupId;
  final bool compact;
  final void Function(String groupId) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
