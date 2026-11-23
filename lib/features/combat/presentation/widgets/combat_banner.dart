import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../core/widgets/pixel_icons/combat_pixel_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/combat_view_state.dart';
import '../../domain/grimoire_combat_reducer.dart';
import '../../domain/grimoire_combat_view.dart';
import '../combat_announcer.dart';
import '../combat_l10n.dart';
import '../combat_motion.dart';
import '../providers/combat_providers.dart';
import '../providers/combat_read_only_provider.dart';
import '../providers/grimoire_banner_provider.dart';
import '../providers/grimoire_combat_providers.dart';
import 'combat_banner_mode.dart';
import 'initiative_row.dart' show kCombatTurnFill;

export 'combat_banner_mode.dart';

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
    this.gmOfflineSince,
    this.masterAbsent = false,
    this.mode = CombatBannerMode.standard,
    this.initiativeHint = CombatBannerInitiativeHint.none,
    this.variant = CombatBannerVariant.group,
    this.compact = false,
    super.key,
  });

  final CombatBannerMode mode;

  /// Mode [CombatBannerMode.preparing] seulement : rappel d'initiative.
  final CombatBannerInitiativeHint initiativeHint;

  /// Non nul : le MJ semble hors ligne ; heure du dernier état reçu.
  /// [offlineSince] (téléphone hors ligne) l'emporte toujours.
  final DateTime? gmOfflineSince;

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
    final title = switch (mode) {
      CombatBannerMode.standard => l10n.combatBannerTitle(round),
      CombatBannerMode.preparing => l10n.combatBannerPreparing,
      CombatBannerMode.yourTurn => l10n.combatBannerYourTurn(round),
    };
    final since = offlineSince;
    final gmSince = gmOfflineSince;
    final secondLine = since != null
        ? l10n.combatBannerOffline(combatClockLabel(l10n, since))
        : gmSince != null
        ? l10n.combatBannerGmOffline(combatClockLabel(l10n, gmSince))
        : masterAbsent
        ? l10n.combatBannerAwaitingMaster
        : mode == CombatBannerMode.preparing
        ? switch (initiativeHint) {
            CombatBannerInitiativeHint.send => l10n.combatBannerSendInitiative,
            CombatBannerInitiativeHint.sent => l10n.combatBannerInitiativeSent,
            CombatBannerInitiativeHint.none => l10n.combatBannerOpen,
          }
        : mode == CombatBannerMode.yourTurn
        ? l10n.combatBannerOpen
        : turnName != null
        ? l10n.combatBannerTurn(turnName!)
        : l10n.combatBannerNoTurn;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTypography.maxTextScaleFactor,
      child: _halo(
        MergeSemantics(
          child: Semantics(
            button: true,
            child: Material(
              color: _fill,
              shape: _shape,
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
                      horizontal:
                          MediaQuery.textScalerOf(context).scale(1) >= 1.6
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
                                style:
                                    AppTypography.body(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ).copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
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
      ),
    );
  }

  bool get _emphasis => mode == CombatBannerMode.yourTurn;

  Color get _fill => _emphasis ? kCombatTurnFill : AppColors.parchmentCard;

  /// Cadre `goldEnd` 2 ; mode « À toi de jouer » : bordure emphasis 3
  /// `woodMedium` (le halo est ajouté par [_halo]).
  ShapeBorder get _shape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    side: _emphasis
        ? const BorderSide(
            color: AppColors.woodMedium,
            width: AppBorders.cardEmphasis,
          )
        : const BorderSide(color: AppColors.goldEnd, width: AppBorders.card),
  );

  /// Halo 1 `woodDark` du mode « À toi de jouer » (comme la ligne en cours).
  Widget _halo(Widget child) {
    if (!_emphasis) return child;
    return Container(
      margin: const EdgeInsets.all(AppBorders.cardEmphasisHalo),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: AppColors.woodDark,
            spreadRadius: AppBorders.cardEmphasisHalo,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Variante **fiche** de [CombatBannerView] : une seule ligne (« Combat en
/// cours · round N », hors ligne « … · état de HH:MM » — jamais un second
/// « Hors ligne », celui du bandeau de synchro suffit), même cadre, chevron.
/// Modes : « Combat en préparation » / « Combat ! Envoie ton initiative »,
/// « À toi de jouer · round N », « Combat · MJ hors ligne (état de HH:MM) ».
extension on CombatBannerView {
  ({String text, String semantics}) _sheetTexts(AppLocalizations l10n) {
    final since = offlineSince;
    if (since != null) {
      final time = combatClockLabel(l10n, since);
      return (
        text: l10n.combatSheetBannerOffline(round, time),
        semantics: l10n.combatSheetBannerSemanticsOffline(round, time),
      );
    }
    final gmSince = gmOfflineSince;
    if (gmSince != null) {
      final time = combatClockLabel(l10n, gmSince);
      return (
        text: l10n.combatSheetBannerGmOffline(time),
        semantics: l10n.combatSheetBannerGmOfflineSemantics(time),
      );
    }
    switch (mode) {
      case CombatBannerMode.yourTurn:
        return (
          text: l10n.combatBannerYourTurn(round),
          semantics: l10n.combatSheetBannerYourTurnSemantics(round),
        );
      case CombatBannerMode.preparing:
        if (initiativeHint == CombatBannerInitiativeHint.send) {
          return (
            text: l10n.combatSheetBannerInitiativeRequested,
            semantics: l10n.combatSheetBannerInitiativeRequestedSemantics,
          );
        }
        return (
          text: l10n.combatBannerPreparing,
          semantics: l10n.combatSheetBannerPreparingSemantics,
        );
      case CombatBannerMode.standard:
        return (
          text: l10n.combatBannerTitle(round),
          semantics: l10n.combatSheetBannerSemantics(round),
        );
    }
  }

  Widget _sheet(BuildContext context, AppLocalizations l10n) {
    final (:text, :semantics) = _sheetTexts(l10n);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTypography.maxTextScaleFactor,
      child: _halo(
        Semantics(
          button: true,
          label: semantics,
          excludeSemantics: true,
          onTap: onTap,
          child: Material(
            color: _fill,
            shape: _shape,
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
      ),
    );
  }
}

/// Bandeau Groupe : sous le `SegmentedTabBar`, hors zone défilante, visible
/// sur les 3 onglets, marges `lg`/`sm`. Apparition `AnimatedSize` 200 ms
/// (immédiate en reduce motion). Absent sans combat actif.
///
/// Un combat mené depuis Grimoire **vivant** passe avant le combat natif
/// (décision 61) ; il est retiré après 10 min sans message du MJ.
class CombatGroupBanner extends ConsumerWidget {
  const CombatGroupBanner({
    required this.groupId,
    required this.masterAbsent,
    required this.onTap,
    this.identity,
    super.key,
  });

  final String groupId;
  final bool masterAbsent;
  final VoidCallback onTap;

  /// Compte et personnage courant du joueur (détail du groupe), transmis au
  /// suivi du combat Grimoire (demande d'initiative, « Toi »).
  final GrimoireIdentity? identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Un seul abonnement Realtime tant que l'écran Groupe est monté.
    ref.watch(combatRealtimeWatcherProvider(groupId));
    ref.watch(grimoireCombatWatcherProvider(groupId));
    syncGrimoireIdentity(context, ref, groupId, identity);
    // Fin d'un combat Grimoire vue depuis l'écran Groupe : une seule annonce
    // polie (l'écran Combat annonce lui-même la fin quand il est devant).
    ref.listen<int>(
      grimoireCombatProvider(groupId).select((session) => session.eventSerial),
      (previous, next) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        final events = ref.read(grimoireCombatProvider(groupId)).events;
        if (events.any(
          (event) => event.kind == GrimoireCombatEventKind.ended,
        )) {
          defaultCombatAnnouncer(
            context,
            AppLocalizations.of(context)!.combatAnnounceEnded,
          );
        }
      },
    );
    final grimoire = ref.watch(grimoireBannerProvider(groupId));
    if (grimoire != null) {
      return _animated(
        context,
        _shown(
          CombatBannerView(
            mode: grimoire.mode,
            round: grimoire.round,
            turnName: grimoire.turnName,
            offlineSince: grimoire.offlineSince,
            gmOfflineSince: grimoire.gmOfflineSince,
            initiativeHint: grimoire.initiativeHint,
            onTap: onTap,
          ),
        ),
      );
    }
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
        : _shown(
            CombatBannerView(
              round: info.round,
              turnName: info.turnName,
              offlineSince: readOnly ? info.lastKnownAt : null,
              masterAbsent: masterAbsent,
              onTap: onTap,
            ),
          );
    return _animated(context, content);
  }

  Widget _shown(Widget banner) => Padding(
    key: const ValueKey('combatBannerShown'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: banner,
  );

  Widget _animated(BuildContext context, Widget content) {
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
