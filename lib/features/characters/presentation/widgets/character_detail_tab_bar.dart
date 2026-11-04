import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Les 5 onglets de la fiche personnage — voir
/// `docs/cahier-des-charges/05-ux-navigation.md`. Les 5 ont désormais un
/// contenu réel ([character]/[skills]/[spells]/[inventory]/[story]).
///
/// [label]/[headerTitle] sont des méthodes (pas des champs `const`, chantier
/// "traduction de l'app" Phase B, lot "Characters — fiche
/// (identité/statistiques)") — un enum `const` ne peut pas porter de texte
/// résolu via `AppLocalizations.of(context)`, qui a besoin d'un
/// `BuildContext` au moment de l'appel : voir le "pattern liste localisée en
/// fonction `(l10n) => [...]`" déjà utilisé ailleurs dans ce dépôt pour le
/// même problème sur des listes de catalogue.
enum CharacterDetailTab {
  character(Icons.person),
  skills(Icons.star_outline),
  spells(Icons.auto_fix_high_outlined),
  inventory(Icons.backpack_outlined),
  story(Icons.description_outlined);

  const CharacterDetailTab(this.icon);

  final IconData icon;

  /// Libellé affiché dans le pied de fiche (`CharacterDetailTabBar`), déjà en
  /// majuscules.
  String label(AppLocalizations l10n) => switch (this) {
    CharacterDetailTab.character => l10n.characterDetailTabCharacterLabel,
    CharacterDetailTab.skills => l10n.characterDetailTabSkillsLabel,
    CharacterDetailTab.spells => l10n.characterDetailTabSpellsLabel,
    CharacterDetailTab.inventory => l10n.characterDetailTabInventoryLabel,
    CharacterDetailTab.story => l10n.characterDetailTabStoryLabel,
  };

  /// Titre affiché dans `WoodBackHeader` en tête de la fiche personnage
  /// quand cet onglet est actif — voir `09-maquettes-captures.md`.
  String headerTitle(AppLocalizations l10n) => switch (this) {
    CharacterDetailTab.character => l10n.characterDetailTabCharacterTitle,
    CharacterDetailTab.skills => l10n.characterDetailTabSkillsTitle,
    CharacterDetailTab.spells => l10n.characterDetailTabSpellsTitle,
    CharacterDetailTab.inventory => l10n.characterDetailTabInventoryTitle,
    CharacterDetailTab.story => l10n.characterDetailTabStoryTitle,
  };
}

/// Barre de navigation à 5 onglets, en pied de la fiche personnage —
/// composant partagé entre les 5 onglets de cet écran (spec visuelle
/// validée par l'agent `direction-artistique`).
///
/// Libellés à 11px minimum (contrainte d'accessibilité stricte du design
/// système, section 7) : la maquette réelle les affiche visuellement plus
/// petits, écart assumé et documenté plutôt qu'appliqué silencieusement.
class CharacterDetailTabBar extends StatelessWidget {
  const CharacterDetailTabBar({
    required this.current,
    required this.onSelect,
    super.key,
  });

  final CharacterDetailTab current;
  final ValueChanged<CharacterDetailTab> onSelect;

  static const double _height = 62;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              for (final tab in CharacterDetailTab.values)
                Expanded(
                  child: _TabButton(
                    tab: tab,
                    selected: tab == current,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final CharacterDetailTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconColor = selected ? AppColors.woodDark : AppColors.textOnWoodMuted;
    final labelColor = selected
        ? AppColors.textOnWood
        : AppColors.textOnWoodMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (selected)
                  Container(
                    width: 34,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.goldEnd,
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                    ),
                  ),
                Icon(tab.icon, size: 20, color: iconColor),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tab.label(l10n),
              style: AppTypography.display(fontSize: 11, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
