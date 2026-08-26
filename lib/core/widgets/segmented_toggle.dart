import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Une option de [SegmentedToggle].
class SegmentedToggleOption<T> {
  const SegmentedToggleOption({required this.value, required this.label});

  /// Valeur portée par ce segment, retournée par
  /// [SegmentedToggle.onChanged] lorsqu'il est sélectionné.
  final T value;

  /// Libellé affiché (converti en majuscules à l'affichage).
  final String label;
}

/// Bascule segmentée du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4, "Bascule
/// segmentée (segmented control)") : piste `parchment.card-alt` avec
/// bordure 2px `wood.light`, `radius.md` ; segment actif en dégradé
/// `gold-start` → `gold-end`, texte `font.display`.
///
/// "Utilisée pour les choix binaires/ternaires globaux à un écran (méthode
/// de caractéristiques, paquetage vs achat d'équipement)" — composant
/// partagé (`core/widgets/`) dès sa première utilisation (étape 4/9
/// "Caractéristiques") plutôt que propre à cet écran, pour être réutilisé
/// tel quel à l'étape 7/9 "Équipement de départ".
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Segments affichés, dans l'ordre. 2 ou 3 selon l'usage ("binaires/
  /// ternaires" d'après le design système), mais aucune limite n'est
  /// imposée ici par ce composant générique.
  final List<SegmentedToggleOption<T>> options;

  /// Valeur du segment actuellement sélectionné. Doit correspondre à
  /// exactement un `option.value` de [options].
  final T value;

  /// Appelé avec la valeur du segment tapé.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs / 2),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment(
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

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Hauteur minimale de la zone de tap imposée par le design système
  /// (section 7, Accessibilité : "Zones de tap ≥ 44×44px sur tous les
  /// éléments interactifs"). Le rendu visuel du segment reste compact
  /// (`_visualHeight`) ; c'est la zone de hit-test de l'[InkWell], via un
  /// [ConstrainedBox], qui atteint 44px.
  static const double _tapTargetHeight = 44;
  static const double _visualHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _tapTargetHeight),
          child: Center(
            child: Container(
              height: _visualHeight,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryButtonGradient : null,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                label.toUpperCase(),
                style: AppTypography.display(
                  fontSize: 11,
                  color: selected
                      ? AppColors.woodDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
