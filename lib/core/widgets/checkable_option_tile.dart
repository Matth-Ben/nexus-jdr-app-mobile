import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Ligne de liste sélectionnable à choix multiple, composant "Case à cocher
/// / élément de liste sélectionnable" de
/// `docs/cahier-des-charges/10-design-system.md` section 4 : case 18×18px
/// (`radius.sm`), bordure 1.5px `wood.light` non cochée ; cochée : fond
/// `gold-end`, bordure `wood.dark`, coche blanche. La ligne entière prend un
/// fond `parchment.card` (non cochée) ou une bordure `gold-end` mise en
/// avant (cochée).
///
/// Distinct de [SelectableOptionTile] (choix exclusif, bouton radio) :
/// premier usage à l'étape 5/9 "Compétences et outils" de l'assistant de
/// création (compétences/outils/langues, listes à choix multiple avec
/// quota) — composant partagé (`core/widgets/`) dès sa première utilisation
/// pour être réutilisé tel quel par l'inventaire/les sorts plus tard.
///
/// [enabled] ajoute un état que [SelectableOptionTile] n'a pas, à deux
/// usages :
/// - une option non cochée d'une section dont le quota est déjà atteint
///   (`enabled: false, checked: false`) : rendue estompée (`Opacity`, même
///   principe que `StepperCounter._StepperButton` pour un bouton désactivé)
///   et non cliquable.
/// - un octroi automatique non interactif (ex. outils d'historique,
///   `enabled: false, checked: true`) : **pas** estompé — [checked] prime
///   toujours sur [enabled] pour le rendu (bordure dorée mise en avant,
///   case cochée pleine couleur), seule l'absence d'interaction change. Ne
///   pas confondre avec un état "verrouillé" qui grisait aussi les lignes
///   cochées : la maquette `06_étape_5_compétences_et_outils.png` montre la
///   ligne "Kit d'herboriste" (octroi automatique) avec le même rendu plein
///   qu'une compétence cochée normalement.
class CheckableOptionTile extends StatelessWidget {
  const CheckableOptionTile({
    required this.title,
    required this.checked,
    this.trailingLabel,
    this.enabled = true,
    this.onTap,
    super.key,
  });

  final String title;

  /// Libellé affiché à droite de la ligne, en gris (ex. l'abréviation de
  /// caractéristique d'une compétence, "Int"/"Sag"...). `null` pour ne rien
  /// afficher (outils, langues).
  final String? trailingLabel;

  final bool checked;

  /// `false` désactive l'interaction (`onTap` ignoré même s'il est fourni) —
  /// voir la documentation de la classe pour les deux usages et leur rendu
  /// respectif.
  final bool enabled;

  final VoidCallback? onTap;

  /// Zone de tap minimale imposée par le design système (section 7,
  /// Accessibilité : "Zones de tap ≥ 44×44px sur tous les éléments
  /// interactifs ... la zone de tap dépasse le carré visuel de 18px") — la
  /// ligne entière est cliquable (même principe que [SelectableOptionTile]),
  /// donc il suffit de garantir sa hauteur minimale plutôt que d'agrandir
  /// spécifiquement la case à cocher.
  static const double _minTapHeight = 44;

  bool get _isInteractive => enabled && onTap != null;

  @override
  Widget build(BuildContext context) {
    // Estompé seulement pour une option non cochée et désactivée (quota
    // atteint) — jamais pour un octroi automatique déjà coché, voir la
    // documentation de la classe.
    final isDimmed = !checked && !enabled;

    return Opacity(
      opacity: isDimmed ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isInteractive ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: _minTapHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.parchmentCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: checked ? AppColors.goldEnd : AppColors.woodLight,
                width: checked ? AppBorders.cardEmphasis : AppBorders.card,
              ),
            ),
            child: Row(
              children: [
                _Checkbox(checked: checked),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailingLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    trailingLabel!,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Case à cocher 18×18px du design système : bordure 1.5px `wood.light` à
/// l'état non coché ; à l'état coché, fond `gold-end` + bordure `wood.dark`
/// + coche blanche.
class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? AppColors.goldEnd : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: checked ? AppColors.woodDark : AppColors.woodLight,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}
