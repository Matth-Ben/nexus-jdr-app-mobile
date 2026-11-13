import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../core/widgets/pixel_icons/combat_pixel_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/combat_view_state.dart';
import '../combat_l10n.dart';
import '../combat_motion.dart';
import '../providers/combat_providers.dart';
import '../providers/combat_read_only_provider.dart';

/// Variante du bandeau de combat : sous les onglets du groupe ou dans le bloc
/// sticky de la fiche d'un personnage.
enum CombatBannerVariant { group, sheet }

/// Bandeau « Combat en cours · round N » — variante **Groupe**, tappable
/// (`docs/combat-groupe-ui.md` §2). Variante tappable d'`InfoBanner` : fond
/// `parchment.card`, bordure 2 `goldEnd`, icône `accent.teal` ; jamais un
/// `AlertBanner` (le combat n'est pas une erreur). Pas de pulsation.
///
/// Vue pure (aucun fournisseur) : [CombatGroupBanner] la nourrit depuis
/// l'état du combat.
class CombatBannerView extends StatelessWidget {
  const CombatBannerView({
    required this.round,
    required this.onTap,
    this.turnName,
    this.offlineSince,
    this.masterAbsent = false,
    this.variant = CombatBannerVariant.group,
    this.compact = false,
    super.key,
  });

  /// [CombatBannerVariant.group] (2 lignes, 64 dp mini) ou
  /// [CombatBannerVariant.sheet] (1 ligne, 48 dp mini, bloc sticky de la fiche).
  final CombatBannerVariant variant;

  /// Variante fiche seulement : forme compacte (44 dp mini, marges réduites)
  /// tant qu'une alerte de synchro ou le mode hors ligne occupe déjà le bloc
  /// sticky (D211).
  final bool compact;

  final int round;

  /// Participant dont c'est le tour (`null` : aucun tour actif).
  final String? turnName;

  /// Non nul hors ligne : horodatage du dernier état connu.
  final DateTime? offlineSince;

  /// MJ absent : la ligne 2 devient « En attente du MJ ».
  final bool masterAbsent;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (variant == CombatBannerVariant.sheet) return _sheet(context, l10n);
    final title = l10n.combatBannerTitle(round);
    final since = offlineSince;
    final secondLine = since != null
        ? l10n.combatBannerOffline(combatClockLabel(l10n, since))
        : masterAbsent
        ? l10n.combatBannerAwaitingMaster
        : turnName != null
        ? l10n.combatBannerTurn(turnName!)
        : l10n.combatBannerNoTurn;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTypography.maxTextScaleFactor,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: Material(
            color: AppColors.parchmentCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(
                color: AppColors.goldEnd,
                width: AppBorders.card,
              ),
            ),
            child: InkWell(
              key: const Key('combatBanner'),
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  // Grand texte (≥ ×1,6) : marge verticale réduite pour rester
                  // sous 150 dp à ×2,0/×3,0 (spec §6).
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.textScalerOf(context).scale(1) >= 1.6
                        ? AppSpacing.sm
                        : AppSpacing.md,
                    vertical: MediaQuery.textScalerOf(context).scale(1) >= 1.6
                        ? AppSpacing.xs
                        : AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: PixelIcon(
                              matrix: kCombatSwordsMatrix,
                              size: 16,
                              color: AppColors.accentTeal,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              secondLine,
                              style: AppTypography.body(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ).copyWith(decoration: TextDecoration.underline),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Variante **fiche** de [CombatBannerView] : une seule ligne (« Combat en
/// cours · round N », hors ligne « … · état de HH:MM » — jamais un second
/// « Hors ligne », celui du bandeau de synchro suffit), même cadre, chevron.
extension on CombatBannerView {
  Widget _sheet(BuildContext context, AppLocalizations l10n) {
    final since = offlineSince;
    final time = since == null ? null : combatClockLabel(l10n, since);
    final text = time == null
        ? l10n.combatBannerTitle(round)
        : l10n.combatSheetBannerOffline(round, time);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final semantics = time == null
        ? l10n.combatSheetBannerSemantics(round)
        : l10n.combatSheetBannerSemanticsOffline(round, time);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTypography.maxTextScaleFactor,
      child: Semantics(
        button: true,
        label: semantics,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: AppColors.parchmentCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(
              color: AppColors.goldEnd,
              width: AppBorders.card,
            ),
          ),
          child: InkWell(
            key: const Key('combatSheetBanner'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: compact ? 44 : 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: largeText
                      ? AppSpacing.xs
                      : compact
                      ? AppSpacing.sm
                      : AppSpacing.md,
                  vertical: compact ? (largeText ? 2 : 0) : AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    // Grand texte (≥ ×1,6) : l'icône, purement décorative (le
                    // libellé dit « Combat »), laisse sa place au texte pour
                    // rester sous 112 dp à ×2,0/×3,0 sur 320 dp (spec §6).
                    if (!largeText) ...[
                      const PixelIcon(
                        matrix: kCombatSwordsMatrix,
                        size: 16,
                        color: AppColors.accentTeal,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        text,
                        style: AppTypography.body(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w800,
                        ).copyWith(height: largeText ? 1.05 : null),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: largeText ? 16 : 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau Groupe : sous le `SegmentedTabBar`, hors zone défilante, visible
/// sur les 3 onglets, marges `lg`/`sm`. Apparition `AnimatedSize` 200 ms
/// (immédiate en reduce motion). Absent sans combat actif.
class CombatGroupBanner extends ConsumerWidget {
  const CombatGroupBanner({
    required this.groupId,
    required this.masterAbsent,
    required this.onTap,
    super.key,
  });

  final String groupId;
  final bool masterAbsent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Un seul abonnement Realtime tant que l'écran Groupe est monté.
    ref.watch(combatRealtimeWatcherProvider(groupId));
    final info = ref.watch(
      combatProvider(groupId).select((state) {
        final snapshot = state.snapshot;
        if (state.phase != CombatPhase.active || snapshot == null) {
          return null;
        }
        return (
          round: snapshot.combat.round,
          turnName: snapshot.currentParticipant?.name,
          lastKnownAt: state.lastKnownAt,
        );
      }),
    );
    final readOnly = ref.watch(combatReadOnlyProvider(groupId));

    final Widget content = info == null
        ? const SizedBox(key: ValueKey('combatBannerNone'), width: 0)
        : Padding(
            key: const ValueKey('combatBannerShown'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: CombatBannerView(
              round: info.round,
              turnName: info.turnName,
              offlineSince: readOnly ? info.lastKnownAt : null,
              masterAbsent: masterAbsent,
              onTap: onTap,
            ),
          );
    // Reduce motion : retour direct du widget (jamais `Duration.zero` sur
    // `AnimatedSize`, qui plante).
    if (combatReduceMotion(context)) return content;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: SizedBox(width: double.infinity, child: content),
    );
  }
}
