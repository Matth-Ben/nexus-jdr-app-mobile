import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Une option de [SpellLevelTabSelector].
class SpellLevelTabOption<T> {
  const SpellLevelTabOption({required this.value, required this.label});

  /// Valeur portée par cette pilule, retournée par
  /// [SpellLevelTabSelector.onChanged] lorsqu'elle est sélectionnée.
  final T value;

  /// Libellé affiché ("Mineurs", "Niveau 1"...).
  final String label;
}

/// Sélecteur d'onglets en pilules de l'étape 6/9 "Sorts" de l'assistant de
/// création (maquette réelle vérifiée au pixel près, section "Étape 6 —
/// Sorts" de `docs/cahier-des-charges/09-maquettes-captures.md`), posé sur le
/// bandeau bois de l'en-tête d'étape, sous la barre de progression.
///
/// Distinct de [SegmentedToggle] (piste bordée pleine largeur à segments
/// égaux, fond `parchment.card-alt`, pensé pour un écran "parchemin") :
/// celui-ci a des pilules de taille ajustée à leur contenu (pas de piste ni
/// de largeur égale imposée), posées directement sur le bandeau bois plutôt
/// que sur leur propre conteneur bordé — deux composants visuellement et
/// structurellement différents malgré leur rôle proche (bascule entre
/// options), donc pas de réutilisation de [SegmentedToggle] avec des options
/// de style : voir `docs/cahier-des-charges/09-maquettes-captures.md` pour le
/// détail vérifié au pixel près qui a motivé la création de ce composant
/// dédié plutôt qu'une variante de [SegmentedToggle].
///
/// Ne gère PAS elle-même le masquage conditionnel d'une pilule à quota nul
/// (ex. onglet "Mineurs" absent pour un Paladin) ni le cas à une seule
/// pilule restante : c'est à l'appelant
/// (`presentation/spells_step_screen.dart`) de ne fournir que les [options]
/// à afficher, et de ne pas instancier ce composant du tout s'il n'en reste
/// qu'une seule (décision documentée sur `SpellsStepScreen`, pas de rendu
/// "sélecteur à un seul choix" ici).
class SpellLevelTabSelector<T> extends StatelessWidget {
  const SpellLevelTabSelector({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Pilules affichées, dans l'ordre. Toujours au moins 2 dans la pratique
  /// (voir la documentation de classe pour le cas à une seule option),
  /// aucune limite n'est imposée ici par ce composant générique.
  final List<SpellLevelTabOption<T>> options;

  /// Valeur de la pilule actuellement sélectionnée. Doit correspondre à
  /// exactement un `option.value` de [options].
  final T value;

  /// Appelé avec la valeur de la pilule tapée.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          _Pill(
            label: options[i].label,
            selected: options[i].value == value,
            onTap: () => onChanged(options[i].value),
          ),
        ],
      ],
    );
  }
}

/// Une pilule de [SpellLevelTabSelector] : active en dégradé or
/// ([AppColors.primaryButtonGradient], même dégradé que [PrimaryButton]/le
/// segment actif de [SegmentedToggle]) avec un texte sombre gras ; inactive
/// en fond brun foncé uni ([AppColors.woodDark]) avec un texte clair atténué
/// ([AppColors.textOnWoodMuted]).
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Zone de tap minimale imposée par le design système (section 7,
  /// Accessibilité : "Zones de tap ≥ 44×44px sur tous les éléments
  /// interactifs") — même principe que `_Segment` de [SegmentedToggle] : le
  /// rendu visuel de la pilule reste compact ([_visualHeight]), c'est la zone
  /// de hit-test de l'[InkWell], via un [ConstrainedBox], qui atteint 44px.
  static const double _tapTargetHeight = 44;
  static const double _visualHeight = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _tapTargetHeight),
          child: Center(
            child: Container(
              height: _visualHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryButtonGradient : null,
                color: selected ? null : AppColors.woodDark,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                // Casse phrase, police `body` (Work Sans) — pas `display`
                // (Press Start 2P, pixel) : correction demandée par
                // `direction-artistique` après comparaison directe avec la
                // maquette réelle ("Mineurs"/"Niveau 1" en glyphes lisses),
                // cohérente avec la règle du design système réservant la
                // police pixel aux libellés que le joueur n'a pas besoin de
                // lire vite (titres, boutons), jamais à un contenu variable
                // à lire couramment comme un libellé d'onglet.
                label,
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.woodDark
                      : AppColors.textOnWoodMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
