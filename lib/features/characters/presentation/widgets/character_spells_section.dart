import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dice_type_badge.dart';
import '../../domain/character_spell_entry.dart';
import '../../domain/character_spell_slot.dart';
import '../../domain/innate_spell_usage.dart';
import '../../domain/spell_damage_dice_extractor.dart';
import '../../domain/spell_grant_source.dart';
import '../../domain/spell_status_formatter.dart';
import '../../domain/spells_by_level_grouper.dart';
import 'spell_action_sheet.dart';
import 'spell_info_panel.dart';

/// Section "SORTS" de l'onglet "Sorts" : les sorts connus/préparés du
/// personnage, groupés par niveau (0 = "Sorts mineurs"), avec les
/// emplacements disponibles du niveau affichés en pastilles à côté du titre
/// de chaque niveau ≥ 1.
///
/// Chaque sort (`_SpellRow`) est cliquable, ouvrant directement le panneau
/// "Infos" ([showSpellInfoPanel], qui porte déjà son propre bouton
/// "Lancer" en pied) — la sheet intermédiaire "Infos"/"Lancer" qui précédait
/// ce panneau a été retirée : elle n'ajoutait qu'un aller-retour, "Lancer"
/// étant de toute façon accessible depuis le panneau "Infos" (retour
/// utilisateur). [onCastSpell] délègue toute la logique
/// d'écriture (optimiste + réseau) à l'appelant
/// (`character_detail_screen.dart::_castSpell`), même principe que
/// `onTapAdjustHp`/`onTapRest` de `_CharacterTabBody`.
///
/// Au sein d'un niveau, les sorts restant à préparer sont affichés grisés,
/// après les sorts préparés (ordre porté par [groups], voir
/// `SpellsByLevelGrouper.group`) — demande utilisateur du 06/10/2026.
///
/// N'affiche rien tant que [groups] est vide — appelant responsable de ne
/// pas monter cette section dans ce cas (voir
/// `character_spells_tab_body.dart`).
class CharacterSpellsSection extends StatelessWidget {
  const CharacterSpellsSection({
    required this.groups,
    required this.spellSlots,
    required this.onCastSpell,
    required this.onTogglePrepared,
    this.pactSlot,
    this.actionsDisabled = false,
    super.key,
  });

  final List<SpellLevelGroup> groups;

  /// Emplacements de sorts par niveau — indexé par niveau dans [build] pour
  /// afficher les pastilles du bon niveau à côté de chaque titre de groupe,
  /// et transmis tel quel à [showSpellInfoPanel] (calcul d'éligibilité).
  final List<CharacterSpellSlot> spellSlots;

  /// Magie de pacte de l'Occultiste (`CharacterDetail.pactSpellSlot`), `null`
  /// si non applicable — affiche le bloc dédié "Magie de pacte" juste
  /// au-dessus de la boucle des groupes de sorts par niveau (voir
  /// [_PactSlotBanner]), et transmis à [showSpellInfoPanel] comme source
  /// d'emplacements supplémentaire pour le calcul d'éligibilité.
  final CharacterSpellSlot? pactSlot;

  final CastSpellCallback onCastSpell;

  /// Bascule "Préparer ce sort"/"Ne plus préparer" du panneau "Infos" — voir
  /// `CharacterRepository.setSpellPrepared`. Jamais appelée pour un sort dont
  /// [SpellStatusFormatter.canTogglePrepared] est faux (le panneau masque
  /// alors cette action).
  final ToggleSpellFlagCallback onTogglePrepared;

  /// `true` pendant qu'un repos long est en cours d'application (voir
  /// `character_detail_screen.dart::_isApplyingRest`) : désactive le tap sur
  /// chaque sort, un repos long réinitialisant les emplacements de sorts —
  /// même verrou déjà appliqué au bandeau PV (`CharacterVitalsCard
  /// .hpActionsDisabled`), ferme ici le même type de course qu'un lancer de
  /// sort démarré pendant que le repos écrit encore en base (voir la
  /// documentation de `_castSpell`). N'affecte pas [onTogglePrepared] :
  /// basculer la préparation d'un sort n'entre jamais en course avec un
  /// repos, contrairement au lancer d'un sort.
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    final slotsByLevel = {for (final slot in spellSlots) slot.level: slot};
    final hasPact = pactSlot != null && pactSlot!.total > 0;
    // La carte "SORTS" ne porte plus que le bloc "Magie de pacte" (le
    // compteur de sorts préparés vit désormais dans
    // `spell_preparation_card.dart`, au-dessus de cette section) : sans
    // magie de pacte elle ne contiendrait que son titre tout seul, elle est
    // alors masquée — demande utilisateur du 23/09/2026.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPact)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.parchmentCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.woodLight,
                width: AppBorders.card,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SORTS',
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                // Bloc de section (pas un groupe de sorts) affiché une seule
                // fois, uniquement pour un Occultiste (ou un Occultiste
                // multiclassé) — même garde défensive que [hasPact].
                if (hasPact) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _PactSlotBanner(slot: pactSlot!),
                ],
              ],
            ),
          ),
        // Un bloc distinct par niveau (« Sorts mineurs », « Niveau 1»...)
        // plutôt que des sous-sections empilées dans la carte "SORTS"
        // ci-dessus — demande utilisateur du 23/09/2026. Pas d'espacement
        // avant le tout premier bloc quand la carte "SORTS" est masquée
        // ([hasPact] faux) : l'appelant (`character_spells_tab_body
        // .dart`) porte déjà son propre espacement au-dessus de
        // [CharacterSpellsSection].
        for (var i = 0; i < groups.length; i++) ...[
          if (hasPact || i > 0) const SizedBox(height: AppSpacing.md),
          _SpellLevelGroupSection(
            group: groups[i],
            slot: slotsByLevel[groups[i].level],
            spellSlots: spellSlots,
            pactSlot: pactSlot,
            onCastSpell: onCastSpell,
            onTogglePrepared: onTogglePrepared,
            actionsDisabled: actionsDisabled,
          ),
        ],
      ],
    );
  }
}

/// Bloc de section "Magie de pacte" (increment magie de pacte de
/// l'Occultiste) : icône + libellé "Magie de pacte — Niveau {L}" + pips de
/// pacte, spec visuelle direction-artistique. Jamais coloré en
/// [AppColors.accentTeal] pour le texte du libellé (contraste ~4,9:1 sur
/// [AppColors.parchmentCard], marge trop faible pour du texte porteur
/// d'info) — [AppColors.accentTeal] réservé à l'icône et au remplissage des
/// pips (seuil non-textuel 3:1, largement respecté).
class _PactSlotBanner extends StatelessWidget {
  const _PactSlotBanner({required this.slot});

  final CharacterSpellSlot slot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.local_fire_department,
          size: 14,
          color: AppColors.accentTeal,
        ),
        const SizedBox(width: AppSpacing.xs / 2),
        Text(
          'Magie de pacte — Niveau ${slot.level}',
          style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpacing.xs),
        SpellSlotDots(slot: slot, filledColor: AppColors.accentTeal),
      ],
    );
  }
}

class _SpellLevelGroupSection extends StatelessWidget {
  const _SpellLevelGroupSection({
    required this.group,
    required this.slot,
    required this.spellSlots,
    this.pactSlot,
    required this.onCastSpell,
    required this.onTogglePrepared,
    required this.actionsDisabled,
  });

  final SpellLevelGroup group;
  final CharacterSpellSlot? slot;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final CastSpellCallback onCastSpell;
  final ToggleSpellFlagCallback onTogglePrepared;
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    // Les pastilles d'emplacement n'ont de sens qu'à partir du niveau 1 (les
    // sorts mineurs, niveau 0, ne consomment jamais d'emplacement) et
    // seulement si des emplacements existent réellement pour ce niveau
    // (`character_spell_slots` peut ne porter aucune ligne pour un niveau
    // donné, ex. personnage pas encore assez haut niveau).
    final showPips = group.level > 0 && slot != null && slot!.total > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.label,
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showPips) ...[
                const SizedBox(width: AppSpacing.xs),
                SpellSlotDots(slot: slot!),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          for (final spell in group.spells)
            _SpellRow(
              spell: spell,
              spellSlots: spellSlots,
              pactSlot: pactSlot,
              onCastSpell: onCastSpell,
              onTogglePrepared: onTogglePrepared,
              enabled: !actionsDisabled,
            ),
        ],
      ),
    );
  }
}

/// Emplacements de sorts d'un niveau, en pastilles pleines/vides — mêmes
/// couleurs que le point de maîtrise déjà utilisé ailleurs dans cet onglet
/// (`character_skills_card.dart::_SkillDot`,
/// `character_saving_throws_card.dart::_ProficiencyDot`) : un vrai cercle
/// graphique plutôt qu'un glyphe Unicode "●"/"○" coloré en texte
/// (`domain/spell_slot_pips_formatter.dart::SpellSlotPipsFormatter.format`,
/// gardé pour ses tests unitaires et une éventuelle réutilisation ultérieure,
/// mais plus utilisé ici) — le contraste texte `AppColors.goldEnd` sur
/// `AppColors.parchmentCard` (~2,4:1) était très sous le minimum AA 4.5:1,
/// signalé en revue direction-artistique. [Semantics.label] porte une phrase
/// lisible ("X restants sur Y") plutôt que le rendu en pastilles, plus
/// adaptée à un lecteur d'écran qu'une suite de glyphes pleins/vides.
class SpellSlotDots extends StatelessWidget {
  const SpellSlotDots({
    required this.slot,
    this.filledColor = AppColors.goldEnd,
    super.key,
  });

  final CharacterSpellSlot slot;

  /// Couleur de remplissage des pastilles pleines — `AppColors.goldEnd` par
  /// défaut (emplacements classiques), `AppColors.accentTeal` pour la magie
  /// de pacte de l'Occultiste (voir `_PactSlotBanner`).
  final Color filledColor;

  @override
  Widget build(BuildContext context) {
    final total = slot.total < 0 ? 0 : slot.total;
    final remaining = slot.remaining;
    final label = slot.isPact
        ? 'Emplacements de pacte : $remaining restants sur $total '
              '(niveau ${slot.level})'
        : 'Emplacements de sorts : $remaining restants sur $total';

    return Semantics(
      label: label,
      // `container: true` : ce noeud de sémantique ne doit jamais fusionner
      // dans celui du `Text` voisin (le libellé de niveau, ex. "Niveau 1")
      // — sans quoi le libellé ci-dessus disparaîtrait, absorbé dans le
      // texte du parent.
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _SpellSlotDot(filled: i < remaining, filledColor: filledColor),
          ],
        ],
      ),
    );
  }
}

class _SpellSlotDot extends StatelessWidget {
  const _SpellSlotDot({required this.filled, required this.filledColor});

  final bool filled;
  final Color filledColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? filledColor : Colors.transparent,
        border: filled
            ? null
            : Border.all(color: AppColors.woodLight, width: 1.5),
      ),
    );
  }
}

/// Taille du texte des pastilles de ligne de sort ([_GrantBadge],
/// [_InnateBadge]) — une seule constante pour qu'elles restent alignées.
const double _rowBadgeFontSize = 10;

/// Taille du texte du marqueur « Épuisé » d'un sort inné ([_InnateUsage]).
const double _innateSpentFontSize = 11;

/// Échelle de texte à partir de laquelle la ligne d'un sort inné à charge
/// passe sur deux lignes (nom + dé, puis pastille + marqueur) : en dessous,
/// tout tient en face du nom. Propre aux sorts innés, pas généralisé aux
/// autres sorts (spec direction-artistique).
const double _innateTwoLineTextScale = 1.3;

/// Plafond d'échelle de texte de la pastille « INNÉ » et de son marqueur
/// d'usage — même valeur que la ligne de raison du panneau « Infos »
/// (`spell_info_panel.dart::_blockReasonMaxTextScale`).
const double _innateUsageMaxTextScale = 2;

class _SpellRow extends StatelessWidget {
  const _SpellRow({
    required this.spell,
    required this.spellSlots,
    this.pactSlot,
    required this.onCastSpell,
    required this.onTogglePrepared,
    required this.enabled,
  });

  final CharacterSpellEntry spell;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final CastSpellCallback onCastSpell;
  final ToggleSpellFlagCallback onTogglePrepared;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dice = SpellDamageDiceExtractor.extract(spell.description);
    final preparationLabel = SpellStatusFormatter.preparationLabel(spell);
    final unprepared = SpellStatusFormatter.isUnprepared(spell);
    // Sort inné de niveau >= 1 : pastille « INNÉ » + marqueur d'usage. Un
    // sort mineur inné (à volonté) n'en porte pas.
    // Jamais cumulé avec la pastille d'octroi ni le libellé de préparation
    // (un sort accordé est présenté 'préparé', un sort inné ne se prépare
    // pas) : la mise en page sur deux lignes n'a donc qu'eux à placer.
    final innateLimited = InnateSpellUsage.isLimited(spell);
    final twoLines =
        innateLimited &&
        MediaQuery.textScalerOf(context).scale(1) >= _innateTwoLineTextScale;

    final nameAndDice = Row(
      children: [
        Flexible(
          child: Text(
            spell.name,
            maxLines: twoLines ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(fontSize: 13),
          ),
        ),
        if (dice != null) ...[
          const SizedBox(width: AppSpacing.xs),
          DiceTypeBadge(
            sides: dice.sides,
            label: '${dice.count}d${dice.sides}',
          ),
        ],
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () => showSpellInfoPanel(
                context,
                spell: spell,
                spellSlots: spellSlots,
                pactSlot: pactSlot,
                onCastSpell: onCastSpell,
                onTogglePrepared: onTogglePrepared,
              )
            : null,
        // Sort restant à préparer : ligne entière atténuée (non lançable
        // en l'état, mais toujours tappable pour ouvrir "Infos" et le
        // préparer) — demande utilisateur du 06/10/2026.
        child: Opacity(
          opacity: unprepared ? 0.5 : 1,
          child: ConstrainedBox(
            // Une seule ligne de contenu par sort : même plancher réduit que
            // celui déjà retenu pour les sorts mineurs (demande utilisateur du
            // 23/09/2026), le plancher tactile standard de 44 laissant un
            // grand vide sous le nom.
            constraints: const BoxConstraints(minHeight: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              // Grandes polices (échelle >= 1.3), sort inné à charge
              // uniquement : pastille et marqueur passent sous le nom,
              // alignés à gauche, pour ne pas écraser le nom sur petit écran.
              child: twoLines
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        nameAndDice,
                        const SizedBox(height: AppSpacing.xs),
                        _InnateUsage(spell: spell),
                      ],
                    )
                  : Row(
                      children: [
                        // Nom + dé de dégâts collés l'un à l'autre à gauche,
                        // la pastille "DOMAINE"/"SERMENT"/"INNÉ" repoussée en
                        // face, à droite — demande utilisateur du 06/10/2026.
                        Expanded(child: nameAndDice),
                        if (spell.grantSource != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _GrantBadge(source: spell.grantSource!),
                        ],
                        if (innateLimited) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _InnateUsage(spell: spell),
                        ],
                        if (preparationLabel != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _PreparationStatus(
                            label: preparationLabel,
                            prepared: !unprepared,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// État de préparation d'un sort, en face de son nom ("PRÉPARÉ"/"NON
/// PRÉPARÉ", voir `SpellStatusFormatter.preparationLabel`) : marque-page
/// plein [AppColors.accentTeal] pour un sort préparé, vide sinon — même
/// icône que le compteur "SORTS PRÉPARÉS" (`spell_preparation_card.dart`).
class _PreparationStatus extends StatelessWidget {
  const _PreparationStatus({required this.label, required this.prepared});

  final String label;
  final bool prepared;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          prepared ? Icons.bookmark : Icons.bookmark_border,
          size: 12,
          color: prepared ? AppColors.accentTeal : AppColors.textMuted,
        ),
        const SizedBox(width: 3),
        Text(
          label.toUpperCase(),
          style: AppTypography.display(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Pastille "DOMAINE"/"SERMENT" d'un sort accordé par une sous-classe (voir
/// `CharacterSpellEntry.grantSource`) — mêmes tokens que les autres chips du
/// design système (fond `parchment.card-alt`, liseré `wood.light`,
/// `radius.sm`, `font.display`), cadenas pour signifier "non retirable".
class _GrantBadge extends StatelessWidget {
  const _GrantBadge({required this.source});

  final SpellGrantSource source;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Toujours préparé, accordé par : ${source.label}',
      excludeSemantics: true,
      child: _RowBadge(
        label: source.label.toUpperCase(),
        icon: Icons.lock_outline,
      ),
    );
  }
}

/// Pastille de ligne de sort partagée par [_GrantBadge] et [_InnateUsage] :
/// fond `parchment.card-alt`, liseré `wood.light` 1 px, `radius.sm`, texte
/// `font.display` [_rowBadgeFontSize]. [icon] facultative, devant le
/// libellé. Purement visuelle : la sémantique est portée par l'appelant.
class _RowBadge extends StatelessWidget {
  const _RowBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTypography.display(
        fontSize: _rowBadgeFontSize,
        color: AppColors.textSecondary,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: 1),
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 10, color: AppColors.woodMedium),
                const SizedBox(width: 3),
                text,
              ],
            ),
    );
  }
}

/// Pastille « INNÉ » + marqueur d'usage d'un sort inné de niveau >= 1
/// (`InnateSpellUsage.isLimited`) : lancé sans emplacement, une fois par
/// repos long. Marqueur : pastille pleine [AppColors.goldEnd] (identique à
/// [_SpellSlotDot]) tant que l'usage est disponible, le mot « Épuisé » en
/// [AppColors.accentBrick] sinon — la ligne elle-même n'est jamais atténuée.
///
/// Un seul nœud sémantique pour les deux (sans `container: true`, comme
/// [_GrantBadge]) ; texte plafonné à [_innateUsageMaxTextScale].
class _InnateUsage extends StatelessWidget {
  const _InnateUsage({required this.spell});

  final CharacterSpellEntry spell;

  @override
  Widget build(BuildContext context) {
    final remaining = InnateSpellUsage.usesRemaining(spell);
    const max = InnateSpellUsage.usesPerLongRest;
    final available = remaining > 0;

    return Semantics(
      label: available
          ? 'Sort inné, sans emplacement, $remaining '
                '${remaining > 1 ? 'utilisations restantes' : 'utilisation restante'} '
                'sur $max, repos long'
          : 'Sort inné, épuisé, disponible après un repos long',
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _innateUsageMaxTextScale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _RowBadge(label: 'INNÉ'),
            const SizedBox(width: AppSpacing.xs),
            if (available)
              const _SpellSlotDot(filled: true, filledColor: AppColors.goldEnd)
            else
              Text(
                'Épuisé',
                style: AppTypography.body(
                  fontSize: _innateSpentFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBrick,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
