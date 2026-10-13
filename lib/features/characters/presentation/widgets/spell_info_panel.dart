import 'package:flutter/material.dart';

import '../../../../core/rules/spell_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/character_spell_entry.dart';
import '../../domain/character_spell_slot.dart';
import '../../domain/innate_spell_usage.dart';
import '../../domain/spell_cast_block_reason.dart';
import '../../domain/spell_components_formatter.dart';
import '../../domain/spell_status_formatter.dart';
import '../../domain/spell_subtitle_formatter.dart';
import 'spell_action_sheet.dart';

/// Plafond d'échelle de texte de la ligne de raison sous "Lancer" : le pied
/// est fixe, donc tout ce qu'elle gagne en hauteur est pris à la zone
/// défilante. À 2.0 elle reste lisible (12 px -> 24 px effectifs) ; le bouton,
/// lui, continue de suivre l'échelle système.
///
/// Ce plafond ne suffit que parce que les messages de [SpellCastBlockReason]
/// sont courts : aucune limite de lignes ne borne la hauteur du pied. Le
/// garde-fou est la matrice de mise en page de
/// `test/features/characters/presentation/spell_info_panel_test.dart`, qui
/// échoue si l'un de ces messages s'allonge au point de déborder ou d'écraser
/// la zone défilante.
const double _blockReasonMaxTextScale = 2;

/// Ouvre le panneau "Infos" d'un sort — gabarit B ([SheetHeaderBar], contenu
/// scrollable, pied fixe) : détail technique complet (temps d'incantation,
/// portée, composantes, durée, concentration) puis description, avec un
/// bouton "Lancer" en pied qui délègue à [castSpellFlow]. Point d'entrée
/// direct depuis une ligne de sort de l'onglet "Sorts"
/// (`character_spells_section.dart::_SpellRow`) : plus de sheet
/// intermédiaire "Infos"/"Lancer" à traverser au préalable (retirée, "Lancer"
/// étant de toute façon déjà accessible ici).
///
/// [onTogglePrepared] : voir `domain/spell_status_formatter.dart`. Le tap
/// ferme directement la sheet (comme un simple lien "Marquer comme
/// mort"/"Archiver ce personnage" ailleurs sur la fiche) plutôt que de garder
/// la sheet ouverte à jour avec l'état réseau en cours — le prochain tap sur
/// la ligne de sort rouvrira ce panneau avec l'état déjà à jour, une fois le
/// tableau de sorts rafraîchi par l'appelant (voir
/// `character_detail_screen.dart::_toggleSpellPrepared`).
///
/// Sort à double route (D43 du registre de dette technique,
/// `docs/dette-technique.md` : à la fois inné — trait racial — et
/// connu/préparé — classe) : le pied porte alors DEUX actions "Lancer"
/// indépendantes (voir [_SpellInfoPanelContent]) — le bouton principal pour
/// la route ordinaire (délègue à [castSpellFlow] comme pour tout sort),
/// et un second bouton "Lancer (sort inné)" qui appelle directement
/// [onCastSpell] avec `slot: null`, SANS passer par [castSpellFlow] (qui ne
/// sait raisonner que sur la route ordinaire de ce sort une fois les deux
/// lignes fusionnées en une entrée, voir sa doc) — exactement le même patron
/// que [onTogglePrepared] ci-dessous : ferme directement la sheet, l'appelant
/// gère écriture optimiste + réseau.
Future<void> showSpellInfoPanel(
  BuildContext context, {
  required CharacterSpellEntry spell,
  required List<CharacterSpellSlot> spellSlots,
  CharacterSpellSlot? pactSlot,
  required CastSpellCallback onCastSpell,
  required ToggleSpellFlagCallback onTogglePrepared,
}) async {
  final shouldCast = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _SpellInfoPanelContent(
      spell: spell,
      spellSlots: spellSlots,
      pactSlot: pactSlot,
      onTogglePrepared: () {
        onTogglePrepared(spell);
        Navigator.of(sheetContext).pop(false);
      },
      onCastInnate: () {
        onCastSpell(spell, null);
        Navigator.of(sheetContext).pop(false);
      },
    ),
  );
  if (shouldCast != true || !context.mounted) return;

  await castSpellFlow(
    context,
    spell: spell,
    spellSlots: spellSlots,
    pactSlot: pactSlot,
    onCastSpell: onCastSpell,
  );
}

class _SpellInfoPanelContent extends StatelessWidget {
  const _SpellInfoPanelContent({
    required this.spell,
    required this.spellSlots,
    this.pactSlot,
    required this.onTogglePrepared,
    required this.onCastInnate,
  });

  final CharacterSpellEntry spell;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final VoidCallback onTogglePrepared;

  /// Lancer de la route innée séparée d'un sort à double route (D43) — voir
  /// la doc de [showSpellInfoPanel]. Jamais appelée tant que [innateDualRoute]
  /// est faux (le bouton qui l'utilise n'est alors pas construit).
  final VoidCallback onCastInnate;

  @override
  Widget build(BuildContext context) {
    // `null` : sort lançable par sa route ORDINAIRE. Sinon la raison est
    // affichée sous le bouton "Lancer" désactivé (priorité "non préparé",
    // voir le domaine). Pour un sort SEULEMENT inné (pas de route ordinaire
    // du tout), [SpellCastBlockReason.of] retombe entièrement sur la route
    // innée — voir sa doc.
    final blockReason = SpellCastBlockReason.of(
      spell: spell,
      spellSlots: [...spellSlots, ?pactSlot],
    );
    final canCast = blockReason == null;
    final components = SpellComponentsFormatter.format(spell.components);

    // Sort inné de niveau >= 1 : lancé sans emplacement, une fois par repos
    // long (sort mineur inné : à volonté, rien de plus à afficher). Vrai
    // aussi bien pour un sort SEULEMENT inné que pour un sort à double route
    // (D43) : voir `domain/innate_spell_usage.dart::InnateSpellUsage
    // .isLimited`.
    final innateLimited = InnateSpellUsage.isLimited(spell);
    final innateSpent =
        innateLimited && !InnateSpellUsage.hasUseAvailable(spell);

    // Sort à double route (D43) : en plus de sa route ordinaire déjà traitée
    // par [blockReason] ci-dessus, ce sort garde une route innée gratuite
    // SÉPARÉE, affichée comme un second bouton "Lancer (sort inné)" en pied
    // (voir plus bas) — jamais pour un sort SEULEMENT inné (`status ==
    // SpellStatus.innate`), dont l'UNIQUE bouton "Lancer" ci-dessus est déjà
    // celui de cette route (voir [SpellCastBlockReason.of]).
    final innateDualRoute = innateLimited && spell.status != SpellStatus.innate;
    final innateBlockReason = innateDualRoute
        ? SpellCastBlockReason.ofInnateRoute(spell)
        : null;

    final infoRows = <Widget>[
      if (innateLimited)
        _SpellInfoRow(
          label: 'Utilisations',
          value: InnateSpellUsage.usageLabel(spell),
          valueColor: innateSpent ? AppColors.accentBrick : null,
          valueWeight: innateSpent ? FontWeight.w700 : null,
        ),
      _SpellInfoRow(label: "Temps d'incantation", value: spell.castingTime),
      _SpellInfoRow(label: 'Portée', value: spell.range),
      _SpellComponentsInfoRow(formatted: components),
      _SpellInfoRow(label: 'Durée', value: spell.duration),
      _SpellInfoRow(
        label: 'Concentration',
        value: spell.concentration ? 'Oui' : 'Non',
        valueColor: spell.concentration
            ? AppColors.accentTeal
            : AppColors.textMuted,
        valueWeight: spell.concentration ? FontWeight.w700 : null,
      ),
    ];

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(title: spell.name.toUpperCase()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SpellSubtitleFormatter.format(spell),
                        style: AppTypography.body(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (spell.grantSource != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Toujours préparé — sort de '
                          '${spell.grantSource!.label.toLowerCase()} '
                          '(ne compte pas dans la limite de sorts préparés)',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (innateLimited) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sort inné — se lance sans emplacement, '
                          '${InnateSpellUsage.usesPerLongRest} fois par '
                          'repos long',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (SpellStatusFormatter.canTogglePrepared(spell)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _TogglePreparedLink(
                          prepared: spell.status == SpellStatus.prepared,
                          onTap: onTogglePrepared,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      for (var i = 0; i < infoRows.length; i++) ...[
                        infoRows[i],
                        if (i < infoRows.length - 1) const SheetActionDivider(),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'DESCRIPTION',
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        spell.description,
                        style: AppTypography.body(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      label: 'Lancer',
                      onPressed: canCast
                          ? () => Navigator.of(context).pop(true)
                          : null,
                    ),
                    if (blockReason != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      MediaQuery.withClampedTextScaling(
                        maxScaleFactor: _blockReasonMaxTextScale,
                        child: Text(
                          blockReason.message,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    // Second bouton, route innée indépendante d'un sort à
                    // double route (D43) — voir [innateDualRoute]. Jamais
                    // affiché pour un sort SEULEMENT inné : son unique
                    // bouton "Lancer" ci-dessus est déjà celui-ci.
                    if (innateDualRoute) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SecondaryButton(
                        label: 'Lancer (sort inné)',
                        surface: SecondaryButtonSurface.parchment,
                        onPressed: innateBlockReason == null
                            ? onCastInnate
                            : null,
                      ),
                      if (innateBlockReason != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        MediaQuery.withClampedTextScaling(
                          maxScaleFactor: _blockReasonMaxTextScale,
                          child: Text(
                            innateBlockReason.message,
                            textAlign: TextAlign.center,
                            style: AppTypography.body(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lien "Préparer ce sort"/"Ne plus préparer" — calque de
/// `character_vitals_card.dart::_DeathToggleLink`/`_RestLink` (`body` 700/13,
/// zone de tap 44px min-height), icône dépendante de l'état (comme
/// `_ArchiveToggleLink`) : `Icons.bookmark_add_outlined` pour préparer,
/// `Icons.bookmark_remove_outlined` pour retirer de la préparation.
class _TogglePreparedLink extends StatelessWidget {
  const _TogglePreparedLink({required this.prepared, required this.onTap});

  final bool prepared;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Icon(
              prepared
                  ? Icons.bookmark_remove_outlined
                  : Icons.bookmark_add_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            // `Flexible` : le libellé passe à la ligne plutôt que de faire
            // déborder la `Row` sur petit écran avec un texte agrandi
            // (réglage d'accessibilité) — sans effet tant qu'il tient sur
            // une ligne.
            Flexible(
              child: Text(
                prepared ? 'Ne plus préparer' : 'Préparer ce sort',
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne "libellé/valeur" du bloc technique (façon "Liste de réglages" du
/// design système, voir la spec visuelle) — libellé `body 600 12px
/// textSecondary` largeur ~110px, valeur `body 400 13px textPrimary` par
/// défaut (surchageable, ex. la ligne "Concentration").
class _SpellInfoRow extends StatelessWidget {
  const _SpellInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: valueWeight ?? FontWeight.w400,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Variante de [_SpellInfoRow] pour la ligne "Composantes" : le suffixe
/// description du composant matériel (voir
/// [SpellComponentsFormatted.materialDescriptionSuffix]) a besoin d'une
/// couleur distincte (`textMuted`) au sein de la même valeur, impossible
/// avec un simple `Text` — voir la spec visuelle.
class _SpellComponentsInfoRow extends StatelessWidget {
  const _SpellComponentsInfoRow({required this.formatted});

  final SpellComponentsFormatted formatted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'Composantes',
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: formatted.label,
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                children: [
                  if (formatted.materialDescriptionSuffix != null)
                    TextSpan(
                      text: formatted.materialDescriptionSuffix,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
