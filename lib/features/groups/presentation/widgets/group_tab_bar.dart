import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Les 2 onglets de l'écran "Groupe" — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.
enum GroupTab {
  members(icon: Icons.groups_outlined, label: 'MEMBRES', headerTitle: 'GROUPE'),
  treasure(
    icon: Icons.inventory_2_outlined,
    label: 'BUTIN',
    headerTitle: 'GROUPE',
  );

  const GroupTab({
    required this.icon,
    required this.label,
    required this.headerTitle,
  });

  final IconData icon;
  final String label;

  /// Titre affiché dans le `WoodBackHeader` de l'écran "Groupe" — toujours
  /// "GROUPE" (contrairement à `CharacterDetailTab.headerTitle`, le bandeau
  /// de tête ne varie pas selon l'onglet actif ici, voir la spec visuelle de
  /// la tâche).
  final String headerTitle;
}

/// Barre de navigation à 2 onglets, en pied de l'écran "Groupe" —
/// visuellement identique à `CharacterDetailTabBar`
/// (`features/characters/presentation/widgets/character_detail_tab_bar.dart`),
/// dupliquée ici plutôt que généralisée (deux enums de forme différente,
/// même convention de duplication que `GroupMemberRowMapper`).
class GroupTabBar extends StatelessWidget {
  const GroupTabBar({required this.current, required this.onSelect, super.key});

  final GroupTab current;
  final ValueChanged<GroupTab> onSelect;

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
              for (final tab in GroupTab.values)
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

  final GroupTab tab;
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
