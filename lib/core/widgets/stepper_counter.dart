import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Compteur +/-" du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4, "Compteur
/// +/-") : boutons carrés 28×28px (`parchment.card-alt`, bordure 1.5px
/// `wood.light`) de part et d'autre d'une valeur numérique centrale en
/// `font.body` 800.
///
/// "Utilisé pour l'allocation de caractéristiques et les ajustements
/// rapides de quantité" — composant partagé (`core/widgets/`) dès sa
/// première utilisation (étape 4/9 "Caractéristiques") plutôt que propre à
/// cet écran, pour être réutilisé tel quel dans l'inventaire.
class StepperCounter extends StatelessWidget {
  const StepperCounter({
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  /// Valeur affichée au centre.
  final int value;

  /// `null` désactive le bouton "+".
  final VoidCallback? onIncrement;

  /// `null` désactive le bouton "-".
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          onPressed: onDecrement,
          semanticLabel: 'Diminuer',
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          onPressed: onIncrement,
          semanticLabel: 'Augmenter',
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  /// Taille minimale de la zone de tap imposée par le design système
  /// (section 7, Accessibilité : "Zones de tap ≥ 44×44px sur tous les
  /// éléments interactifs"). Le rendu visuel du bouton reste un carré
  /// 28×28px conforme au design système ; seule la zone de hit-test de
  /// l'[InkWell] est agrandie, via un padding invisible tout autour du
  /// carré visuel.
  static const double _tapTargetSize = 44;
  static const double _visualSize = 28;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onPressed,
          child: SizedBox(
            width: _tapTargetSize,
            height: _tapTargetSize,
            child: Center(
              child: Container(
                width: _visualSize,
                height: _visualSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.parchmentCardAlt,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.woodLight, width: 1.5),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppColors.textSecondary,
                  semanticLabel: semanticLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
