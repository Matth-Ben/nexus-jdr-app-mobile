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
    this.leading,
    this.subtitle,
    this.trailing,
    this.showIndicator = true,
    super.key,
  });

  final String title;

  /// Icône/illustration à gauche de la ligne, ex. un [AccentIconBadge] —
  /// même rôle que `SelectableOptionTile.leading`, ajouté ici pour son
  /// premier usage à l'étape 6/9 "Sorts" (`presentation/spells_step_screen.dart`)
  /// plutôt que de dupliquer toute la carcasse (case à cocher, dimming,
  /// bordures) dans un nouveau composant. `null` par défaut : les usages
  /// existants (étape 5/9) n'en fournissent pas et n'affichent donc rien de
  /// plus qu'avant.
  final Widget? leading;

  /// Ligne de méta optionnelle affichée sous [title] — même rôle que
  /// `SelectableOptionTile.subtitle`, même rationale d'ajout que [leading].
  /// `null` par défaut.
  final String? subtitle;

  /// Libellé affiché à droite de la ligne, en gris (ex. l'abréviation de
  /// caractéristique d'une compétence, "Int"/"Sag"...). `null` pour ne rien
  /// afficher (outils, langues).
  final String? trailingLabel;

  /// Widget optionnel affiché à la place de la case à cocher intégrée (ex.
  /// un `StepperCounter` pour l'onglet "Acheter" de l'étape 7/9 "Équipement
  /// de départ") — ajouté pour son premier usage sur cette étape, même
  /// rationale d'ajout que [leading]. Prioritaire sur [showIndicator] (le
  /// remplace plutôt que de coexister avec lui) ; `null` par défaut, les
  /// usages existants n'en fournissent pas et gardent donc la case à cocher
  /// intégrée.
  final Widget? trailing;

  /// `false` masque la case à cocher intégrée sans la remplacer par rien —
  /// ajouté pour l'onglet "Historique" de l'étape 7/9 "Équipement de
  /// départ" (objets automatiquement accordés, non interactifs : "pas de
  /// case à cocher ni de bouton radio" d'après la consigne d'origine, à la
  /// différence de l'octroi automatique de l'étape 5/9 qui affiche, lui, une
  /// case cochée verrouillée). Sans effet si [trailing] est fourni (déjà
  /// prioritaire). `true` par défaut : comportement inchangé pour les usages
  /// existants (étapes 5/9 et 6/9).
  final bool showIndicator;

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

    // `trailing` prime sur `showIndicator` (voir leur documentation) ; sans
    // l'un ni l'autre (ex. onglet "Historique" de l'étape 7/9), aucun
    // indicateur n'est rendu du tout, ni à gauche ni à droite.
    final indicator =
        trailing ?? (showIndicator ? _Checkbox(checked: checked) : null);

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
                // L'indicateur (case à cocher intégrée, [trailing] fourni,
                // ou rien) reste à gauche (comportement historique, étape
                // 5/9) tant qu'aucun [leading] n'est fourni ; avec un
                // [leading] (étape 6/9 "Sorts", étape 7/9 "Équipement"), il
                // passe à droite pour laisser la place à l'icône — voir la
                // documentation de [leading].
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ] else if (indicator != null) ...[
                  indicator,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
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
                if (leading != null && indicator != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  indicator,
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
