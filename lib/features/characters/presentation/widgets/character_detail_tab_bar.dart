import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Les 4 onglets de la fiche personnage — voir
/// `docs/cahier-des-charges/05-ux-navigation.md`. Les 4 ont désormais un
/// contenu réel ([character]/[skills]/[inventory]/[story]).
enum CharacterDetailTab {
  character(icon: Icons.person, label: 'PERSO', headerTitle: 'FICHE'),
  skills(icon: Icons.star_outline, label: 'COMP.', headerTitle: 'COMPÉTENCES'),
  inventory(
    icon: Icons.backpack_outlined,
    label: 'SAC',
    headerTitle: 'INVENTAIRE',
  ),
  story(
    icon: Icons.description_outlined,
    label: 'HIST.',
    headerTitle: 'HISTOIRE',
  );

  const CharacterDetailTab({
    required this.icon,
    required this.label,
    required this.headerTitle,
  });

  final IconData icon;
  final String label;

  /// Titre affiché dans `WoodBackHeader` en tête de la fiche personnage
  /// quand cet onglet est actif — voir `09-maquettes-captures.md`.
  final String headerTitle;
}

/// Barre de navigation à 4 onglets, en pied de la fiche personnage —
/// composant partagé entre les 4 onglets de cet écran (spec visuelle
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
              tab.label,
              style: AppTypography.display(fontSize: 11, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
