import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/compact_action_button.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../core/widgets/pixel_icons/combat_pixel_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../combat_motion.dart';
import 'initiative_row.dart' show kCombatTurnFill;

/// Mode de [CombatHeader] (`docs/combat-grimoire-ui.md` §2 et §5).
enum CombatHeaderMode {
  /// « Round N » puis « Tour de X » ou « Aucun tour actif · initiatives N/M ».
  standard,

  /// Annonce sans contenu : « Combat ! », « En préparation », aide ; rien
  /// d'autre (ni round, ni progression des initiatives).
  preparing,

  /// « À toi de jouer » : fond `turn-fill`, bordure emphasis + halo, même
  /// hauteur qu'en mode [standard] (la liste ne bouge pas).
  yourTurn,
}

/// En-tête fixe de l'écran Combat (`docs/combat-groupe-ui.md` §1) : « Round N »
/// (jamais en police pixel), « Tour de X » ou « Aucun tour actif · initiatives
/// 2/4 », kebab MJ, bouton « Voir le tour en cours » quand le tour est hors
/// écran. Textes plafonnés ×2,0, hauteur plafonnée à 40 % du viewport.
///
/// Paramétré par l'appelant ([mode], [sourceLabel], callbacks nuls), jamais
/// par la source du combat : la ligne de source discrète (ex. « Mené depuis
/// Grimoire », décision 63) n'apparaît que si [sourceLabel] est fourni.
class CombatHeader extends StatefulWidget {
  const CombatHeader({
    required this.round,
    required this.initiativeEntered,
    required this.initiativeTotal,
    this.turnName,
    this.mode = CombatHeaderMode.standard,
    this.sourceLabel,
    this.sourceIcon = Icons.desktop_windows_outlined,
    this.showKebab = false,
    this.kebabEnabled = true,
    this.onKebab,
    this.reorderMode = false,
    this.onReorderDone,
    this.showJumpToTurn = false,
    this.onJumpToTurn,
    super.key,
  });

  final int round;
  final String? turnName;
  final int initiativeEntered;
  final int initiativeTotal;
  final CombatHeaderMode mode;

  /// Dernière ligne discrète (12/600 `textSecondary`), `null` : absente.
  final String? sourceLabel;
  final IconData sourceIcon;

  /// Kebab MJ (« Réordonner les égalités », « Terminer le combat »).
  final bool showKebab;
  final bool kebabEnabled;
  final VoidCallback? onKebab;

  /// Mode « Réordonner » : le kebab devient « Terminé ».
  final bool reorderMode;
  final VoidCallback? onReorderDone;

  /// Tour en cours hors écran : bouton « Voir le tour en cours ».
  final bool showJumpToTurn;
  final VoidCallback? onJumpToTurn;

  @override
  State<CombatHeader> createState() => _CombatHeaderState();
}

class _CombatHeaderState extends State<CombatHeader>
    with SingleTickerProviderStateMixin {
  /// Un seul « coup » d'échelle 1,00 → 1,02 → 1,00 (200 ms, `easeOut`) à
  /// l'entrée en mode « À toi de jouer » ; aucune animation en boucle.
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.02), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 1), weight: 1),
  ]).animate(CurvedAnimation(parent: _bump, curve: Curves.easeOut));

  @override
  void didUpdateWidget(CombatHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode == CombatHeaderMode.yourTurn &&
        oldWidget.mode != CombatHeaderMode.yourTurn &&
        !combatReduceMotion(context)) {
      _bump.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final viewportHeight = MediaQuery.sizeOf(context).height;
    final yourTurn = widget.mode == CombatHeaderMode.yourTurn;
    final decoration = BoxDecoration(
      color: yourTurn ? kCombatTurnFill : AppColors.parchmentCard,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: yourTurn ? AppColors.woodMedium : AppColors.woodLight,
        width: yourTurn ? AppBorders.cardEmphasis : AppBorders.card,
      ),
      boxShadow: yourTurn
          ? const [
              BoxShadow(
                color: AppColors.woodDark,
                spreadRadius: AppBorders.cardEmphasisHalo,
              ),
            ]
          : null,
    );
    final content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _lines(l10n)),
                if (widget.reorderMode)
                  CompactActionButton(
                    icon: Icons.check,
                    label: l10n.combatReorderDone,
                    onTap: widget.onReorderDone,
                  )
                else if (widget.showKebab)
                  _kebab(l10n),
              ],
            ),
            if (widget.showJumpToTurn) ...[
              const SizedBox(height: AppSpacing.xs),
              CompactActionButton(
                icon: Icons.my_location_outlined,
                label: l10n.combatJumpToTurn,
                onTap: widget.onJumpToTurn,
              ),
            ],
            if (widget.sourceLabel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _source(widget.sourceLabel!),
            ],
          ],
        ),
      ),
    );
    final box = combatReduceMotion(context)
        ? DecoratedBox(
            key: const Key('combatHeader'),
            decoration: decoration,
            child: content,
          )
        // Fondu de la décoration sans retrait du contenu (un `Container`
        // décalerait le contenu de l'épaisseur de bordure : la hauteur doit
        // rester la même en mode « À toi de jouer »).
        : TweenAnimationBuilder<Decoration>(
            tween: DecorationTween(end: decoration),
            duration: const Duration(milliseconds: 200),
            child: content,
            builder: (context, value, child) => DecoratedBox(
              key: const Key('combatHeader'),
              decoration: value,
              child: child,
            ),
          );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTypography.maxTextScaleFactor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: viewportHeight * 0.4),
        child: ScaleTransition(scale: _scale, child: box),
      ),
    );
  }

  Widget _lines(AppLocalizations l10n) {
    if (widget.mode == CombatHeaderMode.preparing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.combatShout,
              style: AppTypography.body(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            l10n.combatPreparingStatus,
            style: AppTypography.body(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            l10n.combatPreparingHint,
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
    final turnName = widget.turnName;
    final standard = Text(
      turnName != null
          ? l10n.combatTurnOf(turnName)
          : '${l10n.combatNoActiveTurn} · '
                '${l10n.combatInitiativeProgress(widget.initiativeEntered, widget.initiativeTotal)}',
      style: AppTypography.body(fontSize: 15, fontWeight: FontWeight.w700),
    );
    final Widget second = widget.mode == CombatHeaderMode.yourTurn
        // Même hauteur qu'en mode normal (la liste ne bouge pas) : la ligne
        // « Tour de X » reste mesurée, invisible et muette.
        ? Stack(
            children: [
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: standard,
              ),
              Row(
                children: [
                  const PixelIcon(
                    matrix: kCombatSwordsMatrix,
                    size: 16,
                    color: AppColors.accentTeal,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.combatYourTurn,
                      style: AppTypography.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : standard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.combatRound(widget.round),
            style: AppTypography.body(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        second,
      ],
    );
  }

  Widget _source(String label) {
    return Row(
      key: const Key('combatHeaderSource'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(widget.sourceIcon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.body(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kebab(AppLocalizations l10n) {
    return Tooltip(
      message: widget.kebabEnabled
          ? l10n.combatKebabLabel
          : l10n.combatStartUnavailableOffline,
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          key: const Key('combatHeaderMenu'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: Icon(
            Icons.more_vert,
            color: widget.kebabEnabled
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          onPressed: widget.kebabEnabled ? widget.onKebab : null,
        ),
      ),
    );
  }
}
