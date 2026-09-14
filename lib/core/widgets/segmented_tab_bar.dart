import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Une option de [SegmentedTabBar].
class SegmentedTabBarOption<T> {
  const SegmentedTabBarOption({required this.value, required this.label});

  /// Valeur portée par cet onglet, retournée par
  /// [SegmentedTabBar.onChanged] lorsqu'il est sélectionné.
  final T value;

  /// Libellé affiché (converti en majuscules à l'affichage, `font.display` —
  /// voir la documentation de classe de [SegmentedTabBar]).
  final String label;
}

/// "Onglets segmentés" (recettage direction-artistique du 13/09) : une ligne
/// horizontale de libellés en majuscules `font.display`, l'onglet actif
/// distingué par un simple soulignement [AppColors.goldEnd] plutôt qu'un fond
/// ou une pastille — remplace [GroupTabBar]
/// (`features/groups/presentation/widgets/group_tab_bar.dart`, barre à
/// icônes en pied d'écran) pour l'écran "Groupe" (`presentation/
/// group_screen.dart`), désormais posé juste sous le `WoodBackHeader` plutôt
/// qu'en `bottomNavigationBar`.
///
/// Distinct de [SegmentedToggle] (`core/widgets/segmented_toggle.dart`, piste
/// bordée pleine largeur, segment actif en dégradé or, pensé pour un choix
/// ponctuel type "méthode de caractéristiques") : ce composant-ci n'a ni
/// piste ni fond, pensé pour une navigation entre onglets de contenu
/// (Membres/Butin), pas un choix binaire ponctuel — donc pas de réutilisation
/// de [SegmentedToggle] avec un style alternatif, même rationale que
/// [SpellLevelTabSelector] vs [SegmentedToggle].
class SegmentedTabBar<T> extends StatelessWidget {
  const SegmentedTabBar({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Onglets affichés, dans l'ordre. Aucune limite n'est imposée ici par ce
  /// composant générique, même si l'usage visé (Membres/Butin) n'en a que 2.
  final List<SegmentedTabBarOption<T>> options;

  /// Valeur de l'onglet actuellement sélectionné. Doit correspondre à
  /// exactement un `option.value` de [options].
  final T value;

  /// Appelé avec la valeur de l'onglet tapé.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.parchmentBg,
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _SegmentedTab(
                label: option.label,
                selected: option.value == value,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentedTab extends StatelessWidget {
  const _SegmentedTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Zone de tap minimale imposée par le design système (section 7,
  /// Accessibilité : "Zones de tap ≥ 44×44px sur tous les éléments
  /// interactifs") — même principe que `_Segment` de [SegmentedToggle].
  static const double _tapTargetHeight = 44;

  static const double _underlineThickness = 3;
  static const double _underlineWidth = 34;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _tapTargetHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.display(
                  fontSize: 11,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Trait de soulignement toujours présent dans l'arbre (couleur
              // transparente quand inactif) plutôt que conditionnellement
              // inséré : évite un micro-décalage vertical du libellé entre
              // onglet actif/inactif.
              Container(
                height: _underlineThickness,
                width: _underlineWidth,
                decoration: BoxDecoration(
                  color: selected ? AppColors.goldEnd : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
