import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/condition_type.dart';
import 'condition_texts.dart';

/// Au-delà de ce facteur d'échelle de police, la zone n'applique plus de
/// plafond de pastilles (« +N ») : la `Wrap` passe simplement à la ligne.
const double kConditionsCapMaxTextScale = 1.3;

/// Zone d'état (P6) : pastilles des conditions actives, en une seule `Wrap`.
///
/// - Éditable ([onEdit] non nul) : sans condition, un seul bouton discret
///   « + État » (aucune pastille vide, aucun titre) ; avec au moins une
///   condition, les pastilles puis un bouton d'édition distinct. Un tap sur
///   une pastille, sur « +N » ou sur le bouton appelle [onEdit].
/// - Lecture seule ([onEdit] nul) : pastilles sans zone de tap, rien du tout
///   si aucune condition (la hauteur de la carte hôte ne change pas). Seule
///   exception : « +N » est un bouton si [onTapMore] est fourni (V3-5).
///
/// [maxFullChips] plafonne les pastilles complètes (puis « +N ») tant que la
/// police reste normale ; `null` = toutes les pastilles. [compact] = variante
/// de la carte membre du MJ (hauteur 24, texte 11).
class ConditionsZone extends StatelessWidget {
  const ConditionsZone({
    required this.conditions,
    this.onEdit,
    this.onTapMore,
    this.maxFullChips,
    this.compact = false,
    super.key,
  });

  final List<ConditionType> conditions;
  final VoidCallback? onEdit;

  /// Tap sur la seule pastille « +N » (V3-5) : prioritaire sur [onEdit] pour
  /// cette pastille ; les pastilles individuelles ne sont jamais concernées.
  final VoidCallback? onTapMore;
  final int? maxFullChips;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = sortConditionsForDisplay(conditions, l10n);
    final editable = onEdit != null;

    if (sorted.isEmpty) {
      return editable
          ? _AddConditionButton(onPressed: onEdit!)
          : const SizedBox.shrink();
    }

    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final cap = maxFullChips;
    final capped =
        cap != null &&
        textScale <= kConditionsCapMaxTextScale &&
        sorted.length > cap;
    final visible = capped ? sorted.take(cap) : sorted;
    final hidden = capped ? sorted.skip(cap).toList() : const <ConditionType>[];

    return Semantics(
      container: true,
      label: l10n.conditionsZoneSemanticsLabel(
        sorted.map((c) => c.label(l10n)).join(', '),
      ),
      // Le bouton d'édition vit hors de la `Wrap` (V3-4) : dedans, il tombait
      // seul sur une 2e ligne quand les pastilles remplissaient la 1re
      // (3 pastilles à 411 dp). En `Row`, il reste en fin de 1re ligne et les
      // pastilles passent à la ligne dans la largeur restante.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final condition in visible)
                  ConditionChip(
                    condition: condition,
                    compact: compact,
                    onTap: onEdit,
                  ),
                if (hidden.isNotEmpty)
                  _MoreChip(
                    hidden: hidden,
                    compact: compact,
                    onTap: onTapMore ?? onEdit,
                    // Le hint annonce la feuille de liste, pas l'éditeur.
                    withListHint: onTapMore != null,
                  ),
              ],
            ),
          ),
          if (editable) _EditConditionsButton(onPressed: onEdit!),
        ],
      ),
    );
  }
}

/// Pastille d'une condition : `PixelIcon` 16 dp `accent.brick` + libellé
/// (jamais d'icône seule), fond `parchment.card-alt`, bordure 1 px
/// `accent.brick`. Hauteur visuelle 28 (24 en [compact]), zone de tap 44 si
/// [onTap] est fourni.
class ConditionChip extends StatelessWidget {
  const ConditionChip({
    required this.condition,
    this.compact = false,
    this.onTap,
    super.key,
  });

  final ConditionType condition;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ChipShell(
      semanticsLabel: l10n.conditionChipSemanticsLabel(
        condition.label(l10n),
        condition.rule(l10n),
      ),
      compact: compact,
      onTap: onTap,
      leading: PixelIcon(
        matrix: condition.pixelMatrix,
        size: 16,
        color: AppColors.accentBrick,
      ),
      label: condition.label(l10n),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({
    required this.hidden,
    required this.compact,
    required this.onTap,
    required this.withListHint,
  });

  final List<ConditionType> hidden;
  final bool compact;
  final VoidCallback? onTap;
  final bool withListHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ChipShell(
      semanticsLabel: l10n.conditionsMoreChipSemanticsLabel(
        hidden.length,
        hidden.map((c) => c.label(l10n)).join(', '),
      ),
      compact: compact,
      onTap: onTap,
      label: l10n.conditionsMoreChipLabel(hidden.length),
      hint: withListHint ? l10n.conditionsMoreChipHint : null,
      minTapWidth: 44,
    );
  }
}

class _ChipShell extends StatelessWidget {
  const _ChipShell({
    required this.semanticsLabel,
    required this.compact,
    required this.onTap,
    required this.label,
    this.leading,
    this.hint,
    this.minTapWidth = 0,
  });

  final String semanticsLabel;
  final bool compact;
  final VoidCallback? onTap;
  final String label;
  final Widget? leading;
  final String? hint;

  /// Largeur minimale de la zone de tap (44 pour « +N », court sinon).
  final double minTapWidth;

  @override
  Widget build(BuildContext context) {
    final visual = Container(
      constraints: BoxConstraints(minHeight: compact ? 24 : 28),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.accentBrick),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    final tap = onTap;
    return Semantics(
      container: true,
      button: tap != null,
      label: semanticsLabel,
      hint: hint,
      excludeSemantics: true,
      onTap: tap,
      child: tap == null
          ? visual
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: tap,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 44,
                    minWidth: minTapWidth,
                  ),
                  child: Center(widthFactor: 1, child: visual),
                ),
              ),
            ),
    );
  }
}

/// Bouton discret « + État » (aucune condition active).
class _AddConditionButton extends StatelessWidget {
  const _AddConditionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: l10n.conditionsAddSemanticsLabel,
        excludeSemantics: true,
        onTap: onPressed,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            l10n.conditionsAddButtonLabel,
            style: AppTypography.body(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton d'édition distinct des pastilles (au moins une condition active),
/// cible 44×44.
class _EditConditionsButton extends StatelessWidget {
  const _EditConditionsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      button: true,
      label: l10n.conditionsEditSemanticsLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          tooltip: l10n.conditionsEditSemanticsLabel,
          icon: const Icon(
            Icons.edit_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
