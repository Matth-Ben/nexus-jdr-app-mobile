import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_spell_entry.dart';
import '../../domain/character_spell_slot.dart';
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
/// Section "FAVORIS" (voir [favorites]) affichée en tête, avant même le
/// bloc "Magie de pacte" — voir `docs/cahier-des-charges/`
/// 11-fonctionnalites-a-ajouter.md, section "Onglet Sorts" : "Favoris /
/// épinglage des sorts fréquemment utilisés (accès rapide en combat)".
/// Absente du tout quand [favorites] est vide (aucun favori épinglé), même
/// principe que le bloc "Magie de pacte".
///
/// N'affiche rien tant que [groups] est vide — appelant responsable de ne
/// pas monter cette section dans ce cas (voir
/// `character_spells_tab_body.dart`).
class CharacterSpellsSection extends StatelessWidget {
  const CharacterSpellsSection({
    required this.groups,
    required this.spellSlots,
    required this.onCastSpell,
    required this.onToggleFavorite,
    required this.onTogglePrepared,
    this.favorites = const [],
    this.pactSlot,
    this.actionsDisabled = false,
    super.key,
  });

  final List<SpellLevelGroup> groups;

  /// Sorts épinglés (`CharacterSpellEntry.isFavorite`), toutes classes/tous
  /// niveaux confondus — voir la documentation de classe, section
  /// "FAVORIS". Déjà filtré par l'appelant (recherche active incluse, voir
  /// `character_spells_tab_body.dart`).
  final List<CharacterSpellEntry> favorites;

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

  /// Étoile de [_SpellRow] — voir `CharacterRepository.setSpellFavorite`.
  final ToggleSpellFlagCallback onToggleFavorite;

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
  /// documentation de `_castSpell`). N'affecte pas [onToggleFavorite]/
  /// [onTogglePrepared] : épingler un sort ou basculer sa préparation
  /// n'entre jamais en course avec un repos, contrairement au lancer d'un
  /// sort.
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    final slotsByLevel = {for (final slot in spellSlots) slot.level: slot};

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
          Text(
            'SORTS',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (favorites.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _FavoritesSection(
              favorites: favorites,
              spellSlots: spellSlots,
              pactSlot: pactSlot,
              onCastSpell: onCastSpell,
              onToggleFavorite: onToggleFavorite,
              onTogglePrepared: onTogglePrepared,
              enabled: !actionsDisabled,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(height: 1, color: AppColors.gaugeTrack),
          ],
          // Bloc de section (pas un groupe de sorts) affiché une seule fois,
          // uniquement pour un Occultiste (ou un Occultiste multiclassé) —
          // même garde défensive que `showPips` ci-dessous (`total > 0`).
          if (pactSlot != null && pactSlot!.total > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _PactSlotBanner(slot: pactSlot!),
            const SizedBox(height: AppSpacing.sm),
            Container(height: 1, color: AppColors.gaugeTrack),
            const SizedBox(height: AppSpacing.sm),
          ],
          for (final group in groups)
            _SpellLevelGroupSection(
              group: group,
              slot: slotsByLevel[group.level],
              spellSlots: spellSlots,
              pactSlot: pactSlot,
              onCastSpell: onCastSpell,
              onToggleFavorite: onToggleFavorite,
              onTogglePrepared: onTogglePrepared,
              actionsDisabled: actionsDisabled,
            ),
        ],
      ),
    );
  }
}

/// Section "FAVORIS" — carte à bordure/emphase dorée (même token que
/// l'emplacement "PO" de `character_inventory_stat_boxes_row.dart`), une
/// [_SpellRow] par sort épinglé avec `showLevelInSubtitle: true` (les
/// favoris mélangent des sorts de plusieurs niveaux, contrairement aux
/// groupes par niveau ci-dessous où le niveau est déjà porté par le titre de
/// section).
class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({
    required this.favorites,
    required this.spellSlots,
    this.pactSlot,
    required this.onCastSpell,
    required this.onToggleFavorite,
    required this.onTogglePrepared,
    required this.enabled,
  });

  final List<CharacterSpellEntry> favorites;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final CastSpellCallback onCastSpell;
  final ToggleSpellFlagCallback onToggleFavorite;
  final ToggleSpellFlagCallback onTogglePrepared;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.goldEnd, width: AppBorders.cardEmphasis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: AppColors.goldEnd),
              const SizedBox(width: AppSpacing.xs / 2),
              Text(
                'FAVORIS',
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          for (final spell in favorites)
            _SpellRow(
              spell: spell,
              spellSlots: spellSlots,
              pactSlot: pactSlot,
              onCastSpell: onCastSpell,
              onToggleFavorite: onToggleFavorite,
              onTogglePrepared: onTogglePrepared,
              enabled: enabled,
              showLevelInSubtitle: true,
            ),
        ],
      ),
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
    required this.onToggleFavorite,
    required this.onTogglePrepared,
    required this.actionsDisabled,
  });

  final SpellLevelGroup group;
  final CharacterSpellSlot? slot;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final CastSpellCallback onCastSpell;
  final ToggleSpellFlagCallback onToggleFavorite;
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

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
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
              onToggleFavorite: onToggleFavorite,
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

class _SpellRow extends StatelessWidget {
  const _SpellRow({
    required this.spell,
    required this.spellSlots,
    this.pactSlot,
    required this.onCastSpell,
    required this.onToggleFavorite,
    required this.onTogglePrepared,
    required this.enabled,
    this.showLevelInSubtitle = false,
  });

  final CharacterSpellEntry spell;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final CastSpellCallback onCastSpell;
  final ToggleSpellFlagCallback onToggleFavorite;
  final ToggleSpellFlagCallback onTogglePrepared;
  final bool enabled;

  /// `true` dans la section "FAVORIS" (mélange plusieurs niveaux, le niveau
  /// doit donc être précisé) — `false` dans un groupe par niveau, où le
  /// niveau est déjà porté par le titre de section ("Niveau 1"...).
  final bool showLevelInSubtitle;

  @override
  Widget build(BuildContext context) {
    final school = spell.school.trim();
    final statusText = SpellStatusFormatter.subtitle(spell);
    final subtitle = showLevelInSubtitle
        ? ['niv. ${spell.level}', ?statusText].join(' · ')
        : statusText;

    // Deux `Text` distincts (nom, puis école entre parenthèses) plutôt qu'un
    // seul `Text.rich`/`TextSpan` : plus simple à cibler par
    // `find.text(...)` dans les tests de widget, et cohérent avec le
    // découpage nom/valeur des autres cartes de cet onglet (ex.
    // `character_skills_card.dart::_SkillRow`).
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        spell.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(fontSize: 13),
                      ),
                    ),
                    if (school.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs / 2),
                      Flexible(
                        child: Text(
                          '($school)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _FavoriteStar(
                      isFavorite: spell.isFavorite,
                      onTap: enabled ? () => onToggleFavorite(spell) : null,
                    ),
                    const SizedBox(width: AppSpacing.xs / 2),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Étoile de favori, zone de tap indépendante de celle de la ligne (voir
/// [_SpellRow.onTap]) — `Icons.star`/`AppColors.goldEnd` épinglé,
/// `Icons.star_border`/`AppColors.textMuted` sinon.
class _FavoriteStar extends StatelessWidget {
  const _FavoriteStar({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs / 2),
          child: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            size: 18,
            color: isFavorite ? AppColors.goldEnd : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
