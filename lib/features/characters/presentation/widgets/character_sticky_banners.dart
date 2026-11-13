import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sync/sync_banner_engine.dart';
import '../../../../core/sync/sync_status_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/sync_status_banner.dart';
import '../../../combat/presentation/providers/character_combat_provider.dart';
import '../../../combat/presentation/widgets/combat_sheet_banner.dart';

/// Part de la hauteur de l'écran que le bloc sticky (synchro + combat) ne
/// dépasse jamais ; au-delà, il défile en interne (même principe que
/// `_SyncBand` de la liste d'accueil).
const double kCharacterStickyBannersMaxHeightFraction = 0.4;

/// Bloc sticky de la fiche, hors zone défilante, sous l'en-tête bois :
/// [SyncStatusBanner] (un seul état à la fois : alerte, puis hors ligne, puis
/// en cours/en attente/synchronisé) **puis** le bandeau « Combat en cours »
/// quand le personnage a un combat actif (il ne disparaît jamais derrière un
/// bandeau de synchro). Marges : 10 sous l'en-tête, 10 entre bandeaux, 10 sous
/// le dernier. Le bandeau de combat passe en forme compacte (D211) quand la
/// synchro est en alerte ou hors ligne.
///
/// `ConsumerWidget` isolé : seuls ces bandeaux observent la synchro et le
/// combat, un évènement de combat ne reconstruit donc jamais la fiche.
class CharacterStickyBanners extends ConsumerStatefulWidget {
  const CharacterStickyBanners({required this.characterId, super.key});

  final String characterId;

  @override
  ConsumerState<CharacterStickyBanners> createState() =>
      _CharacterStickyBannersState();
}

class _CharacterStickyBannersState
    extends ConsumerState<CharacterStickyBanners> {
  @override
  void initState() {
    super.initState();
    // Une seule relecture à l'ouverture, et seulement si le cache est ancien.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(characterGroupIdsProvider(widget.characterId).notifier)
            .ensureFresh(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final combat = ref.watch(characterCombatBannerProvider(widget.characterId));
    final kind = ref.watch(
      syncBannerProvider(characterId: widget.characterId)
          .select((state) => state.kind),
    );
    final compact =
        kind == SyncBannerKind.alert || kind == SyncBannerKind.offline;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SyncStatusBanner(
          characterId: widget.characterId,
          visiblePadding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            // Le bandeau de combat apporte sa propre marge haute (10 entre
            // bandeaux) : pas de double marge.
            combat == null ? AppSpacing.sm : 0,
          ),
        ),
        if (combat != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: CombatSheetBanner(
              groupId: combat.groupId,
              compact: compact,
              onOpen: (groupId) =>
                  unawaited(context.push('/groups/$groupId/combat')),
            ),
          ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height *
            kCharacterStickyBannersMaxHeightFraction,
      ),
      child: SingleChildScrollView(
        key: const Key('characterStickyBannersScroll'),
        child: content,
      ),
    );
  }
}
