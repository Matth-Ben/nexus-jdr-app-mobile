import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/compact_action_button.dart';
import '../../../../core/widgets/dashed_border_painter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/combat_enums.dart';
import '../../domain/combat_participant.dart';
import '../combat_l10n.dart';
import '../combat_motion.dart';
import 'combat_action_menu.dart';

/// Fond « tour en cours » : `goldStart` à 25 % sur `parchment.card`
/// (≈ `#F6E4B6`), par `Color.alphaBlend` — pas un nouvel hex
/// (`docs/combat-groupe-ui.md` §0).
final Color kCombatTurnFill = Color.alphaBlend(
  AppColors.goldStart.withValues(alpha: 0.25),
  AppColors.parchmentCard,
);

/// Échelle de texte à partir de laquelle la ligne passe en mode empilé.
const double kInitiativeRowStackedScale = 1.6;

/// Ligne de l'ordre d'initiative (`docs/combat-groupe-ui.md` §1). Une ligne
/// ne trie rien : l'ordre et le rang viennent de l'appelant
/// (`sortedForDisplay`).
///
/// États : normal, tour en cours, en attente, retiré, sans initiative. Mode
/// normal (échelle < ×1,6) : rang | nom + badges | initiative | menu ; mode
/// empilé (≥ ×1,6) : rang + nom pleine largeur, puis initiative, badges et menu.
class InitiativeRow extends StatelessWidget {
  const InitiativeRow({
    required this.participant,
    required this.rank,
    this.isCurrent = false,
    this.isYou = false,
    this.onEditInitiative,
    this.editLabel,
    this.onRemove,
    this.onFill,
    this.actionsEnabled = true,
    this.disabledHint,
    this.reorderMode = false,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  final CombatParticipant participant;

  /// Rang d'affichage (1-based) ; `null` pour une ligne sans initiative.
  final int? rank;

  final bool isCurrent;
  final bool isYou;

  /// « Éditer l'initiative » (MJ). `null` : pas d'entrée de menu.
  final VoidCallback? onEditInitiative;

  /// Libellé de l'entrée d'édition (défaut : « Éditer l'initiative »).
  final String? editLabel;

  /// « Retirer du combat » (MJ), la confirmation est à la charge de l'appelant.
  final VoidCallback? onRemove;

  /// Bouton « Renseigner » d'une ligne sans initiative.
  final VoidCallback? onFill;

  /// `false` : lecture seule (hors ligne...) — menu et « Renseigner »
  /// désactivés avec indice.
  final bool actionsEnabled;

  /// Indice des actions désactivées (défaut : « Indisponible hors ligne »).
  final String? disabledHint;

  /// Mode « Réordonner les égalités » : 2e ligne ▲/▼.
  final bool reorderMode;

  /// Voisin de même initiative disponible ? (`null` : flèche désactivée).
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  bool get _removed => participant.status == ParticipantStatus.removed;
  bool get _waiting => participant.status == ParticipantStatus.waiting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >= kInitiativeRowStackedScale;
    final hasMenu = !_removed && (onEditInitiative != null || onRemove != null);

    final content = Padding(
      // Mode empilé : marge verticale réduite pour rester dans la fourchette
      // de hauteur de la spec (100 à 150 dp à ×2,0).
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: stacked ? AppSpacing.xs : AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked)
            ..._stackedBody(context, l10n, hasMenu)
          else
            _normalBody(context, l10n, hasMenu),
          if (reorderMode && !_removed) _reorderBar(context, l10n),
        ],
      ),
    );

    final decorated = _decorate(context, content);
    return MergeSemantics(
      child: Semantics(
        container: true,
        excludeSemantics: true,
        customSemanticsActions: {
          if (hasMenu && actionsEnabled && onEditInitiative != null)
            CustomSemanticsAction(
              label: editLabel ?? l10n.combatMenuEditInitiative,
            ): onEditInitiative!,
          if (hasMenu && actionsEnabled && onRemove != null)
            CustomSemanticsAction(label: l10n.combatMenuRemove): onRemove!,
          if (reorderMode && onMoveUp != null)
            CustomSemanticsAction(label: l10n.combatMoveUp(participant.name)):
                onMoveUp!,
          if (reorderMode && onMoveDown != null)
            CustomSemanticsAction(label: l10n.combatMoveDown(participant.name)):
                onMoveDown!,
        },
        label: _semanticsLabel(l10n),
        child: decorated,
      ),
    );
  }

  String _semanticsLabel(AppLocalizations l10n) {
    final kind = combatKindLabel(l10n, participant.kind);
    final initiative = participant.initiative;
    final base = initiative == null
        ? l10n.combatRowSemanticsPending(participant.name, kind)
        : l10n.combatRowSemantics(
            rank ?? 0,
            participant.name,
            kind,
            initiative,
          );
    return [
      base,
      if (isYou) l10n.combatYouTag,
      if (_removed)
        l10n.combatStatusRemoved
      else if (_waiting)
        l10n.combatStatusWaiting
      else if (isCurrent)
        l10n.combatCurrentTurnLabel.toLowerCase(),
    ].join(', ');
  }

  Widget _decorate(BuildContext context, Widget child) {
    final Color fill;
    if (isCurrent && !_removed) {
      fill = kCombatTurnFill;
    } else if (_waiting || _removed) {
      fill = AppColors.parchmentCardAlt;
    } else {
      fill = AppColors.parchmentCard;
    }
    final emphasis = isCurrent && !_removed;
    final decoration = BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: emphasis
            ? AppColors.woodMedium
            : _waiting
            ? Colors.transparent
            : AppColors.woodLight,
        width: emphasis ? AppBorders.cardEmphasis : AppBorders.card,
      ),
      boxShadow: emphasis
          ? const [
              BoxShadow(
                color: AppColors.woodDark,
                spreadRadius: AppBorders.cardEmphasisHalo,
              ),
            ]
          : null,
    );
    final constraints = const BoxConstraints(minHeight: 64);
    Widget box = combatReduceMotion(context)
        ? Container(
            constraints: constraints,
            decoration: decoration,
            child: child,
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: constraints,
            decoration: decoration,
            child: child,
          );
    if (_waiting && !emphasis) {
      box = CustomPaint(
        foregroundPainter: const DashedBorderPainter(
          color: AppColors.woodLight,
          strokeWidth: AppBorders.card,
        ),
        child: box,
      );
    }
    return box;
  }

  // ---------------------------------------------------------------- corps

  Widget _normalBody(
    BuildContext context,
    AppLocalizations l10n,
    bool hasMenu,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _rank(),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [_name(), const SizedBox(height: 2), _tags(l10n)],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _initiative(l10n),
        if (hasMenu) _kebab(context, l10n),
      ],
    );
  }

  List<Widget> _stackedBody(
    BuildContext context,
    AppLocalizations l10n,
    bool hasMenu,
  ) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rank(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _name()),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _initiative(l10n, inline: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _tags(l10n)),
          if (hasMenu) _kebab(context, l10n),
        ],
      ),
    ];
  }

  Widget _rank() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 28),
      child: Text(
        rank == null || participant.initiative == null ? '–' : '$rank',
        textAlign: TextAlign.center,
        style: AppTypography.body(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _name() {
    return Text(
      participant.name,
      // Jamais d'ellipse sur un nom : il passe à la ligne.
      style: AppTypography.body(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ).copyWith(decoration: _removed ? TextDecoration.lineThrough : null),
    );
  }

  /// Texte secondaire plafonné ×2,0 : seuls le nom et le rang suivent
  /// l'échelle au-delà (le nom passe alors sur plusieurs lignes).
  static Widget _clamped(Widget child) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: AppTypography.maxTextScaleFactor,
    child: child,
  );

  /// Initiative : valeur 20/800 avec « Init. » 11/600 dessous (mode normal) ou
  /// à côté (mode empilé, pour tenir dans la fourchette de hauteur).
  Widget _initiative(AppLocalizations l10n, {bool inline = false}) {
    final value = participant.initiative;
    final number = Text(
      value == null ? '–' : '$value',
      style: AppTypography.body(fontSize: 20, fontWeight: FontWeight.w800),
    );
    final label = Text(
      l10n.combatInitLabel,
      style: AppTypography.body(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
    return _clamped(
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44),
        child: inline
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [number, const SizedBox(width: 4), label],
              )
            : Column(mainAxisSize: MainAxisSize.min, children: [number, label]),
      ),
    );
  }

  Widget _tags(AppLocalizations l10n) {
    final noInitiative = participant.initiative == null && !_removed;
    return _clamped(
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CombatKindBadge(kind: participant.kind),
          if (isYou) _youTag(l10n),
          if (_removed)
            _statusLabel(l10n.combatStatusRemoved)
          else if (_waiting)
            _statusLabel(l10n.combatStatusWaiting, icon: Icons.pause)
          else if (isCurrent)
            _statusLabel(
              l10n.combatCurrentTurnLabel,
              icon: Icons.chevron_right,
              iconSize: 24,
              weight: FontWeight.w800,
            ),
          if (noInitiative) ...[
            _statusLabel(l10n.combatInitiativeToEnter),
            if (onFill != null)
              Tooltip(
                message: actionsEnabled
                    ? l10n.combatFillInitiative
                    : disabledHint ?? l10n.combatStartUnavailableOffline,
                child: CompactActionButton(
                  icon: Icons.edit_outlined,
                  label: l10n.combatFillInitiative,
                  onTap: actionsEnabled ? onFill : null,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _youTag(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodMedium, width: 1.5),
      ),
      child: Text(
        l10n.combatYouTag,
        style: AppTypography.body(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _statusLabel(
    String text, {
    IconData? icon,
    double iconSize = 16,
    FontWeight weight = FontWeight.w700,
  }) {
    final color = isCurrent ? AppColors.textPrimary : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: iconSize, color: color),
        Flexible(
          child: Text(
            text,
            style: AppTypography.body(
              fontSize: 12,
              fontWeight: weight,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kebab(BuildContext context, AppLocalizations l10n) {
    final enabled = actionsEnabled;
    return Tooltip(
      message: enabled
          ? l10n.combatRowMenuLabel(participant.name)
          : disabledHint ?? l10n.combatStartUnavailableOffline,
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          key: Key('combatRowMenu-${participant.id}'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: Icon(
            Icons.more_vert,
            color: enabled
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          onPressed: enabled ? () => _openMenu(context, l10n) : null,
        ),
      ),
    );
  }

  void _openMenu(BuildContext context, AppLocalizations l10n) {
    showCombatActionMenu(
      context,
      title: participant.name,
      entries: [
        if (onEditInitiative != null)
          CombatMenuEntry(
            icon: Icons.edit_outlined,
            label: editLabel ?? l10n.combatMenuEditInitiative,
            onTap: onEditInitiative!,
          ),
        if (onRemove != null)
          CombatMenuEntry(
            label: l10n.combatMenuRemove,
            destructive: true,
            onTap: onRemove!,
          ),
      ],
    );
  }

  Widget _reorderBar(BuildContext context, AppLocalizations l10n) {
    Widget arrow({
      required IconData icon,
      required VoidCallback? onTap,
      required String label,
      required Key key,
    }) {
      return Tooltip(
        message: onTap == null ? l10n.combatReorderLimit : label,
        child: SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            key: key,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: Icon(icon),
            color: AppColors.textPrimary,
            disabledColor: AppColors.textSecondary.withValues(alpha: 0.5),
            onPressed: onTap,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(
            icon: Icons.keyboard_arrow_up,
            onTap: onMoveUp,
            label: l10n.combatMoveUp(participant.name),
            key: Key('combatMoveUp-${participant.id}'),
          ),
          arrow(
            icon: Icons.keyboard_arrow_down,
            onTap: onMoveDown,
            label: l10n.combatMoveDown(participant.name),
            key: Key('combatMoveDown-${participant.id}'),
          ),
        ],
      ),
    );
  }
}

/// Badge **PJ** (fond `wood.medium`, texte `text.on-wood`, 7,0:1) ou **PNJ**
/// (fond `parchment.card-alt`, bordure 1,5 `wood.light`, `textSecondary`),
/// jamais la couleur seule : libellé + icône.
class CombatKindBadge extends StatelessWidget {
  const CombatKindBadge({required this.kind, super.key});

  final ParticipantKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pc = kind == ParticipantKind.pc;
    final color = pc ? AppColors.textOnWood : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: pc ? AppColors.woodMedium : AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: pc ? null : Border.all(color: AppColors.woodLight, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pc ? Icons.shield_outlined : Icons.dangerous_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              pc ? l10n.combatBadgePc : l10n.combatBadgeNpc,
              style: AppTypography.body(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
