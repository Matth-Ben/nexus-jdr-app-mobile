import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Bouton destructif" du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4) : fond
/// `#FDECE0` (= [AppColors.alertBannerBackground]), bordure 2px
/// `accent.brick`, texte `font.body` 700 en `accent.brick` — "Réservé aux
/// actions irréversibles (déconnexion, suppression de personnage)".
///
/// Premier composant partagé dédié à ce token, introduit à l'occasion de
/// la confirmation "Retirer le portrait" de la fiche personnage
/// (`presentation/widgets/portrait_upload_sheet.dart`) — depuis, aussi
/// utilisé pour l'action "Se déconnecter" de l'écran Profil
/// (`features/profile/presentation/profile_screen.dart`), et réutilisable
/// tel quel pour la suppression de personnage à venir.
///
/// Contrairement à [PrimaryButton]/[SecondaryButton], le texte du variant
/// par défaut ([filled] `false`) n'est **pas** en `font.display`/majuscules :
/// le design système précise explicitement `font.body` 700 pour ce
/// composant.
///
/// [filled] introduit le variant "Bouton destructif — fond plein" (recettage
/// direction-artistique du 13/09/2026, écran "Profil — Suppression du
/// compte" : `docs/cahier-des-charges/09-maquettes-captures.md`, action
/// "SUPPRIMER DÉFINITIVEMENT") : fond `accent.brick` plein (au lieu du fond
/// `alertBannerBackground`/bordure du variant par défaut), texte
/// `color.text.on-wood` — la maquette montre ce libellé en majuscules
/// `font.display`, comme [PrimaryButton]/[SecondaryButton], contrairement au
/// variant par défaut ci-dessus ; `false` par défaut, comportement inchangé
/// pour tous les usages existants (aucun n'a besoin de ce fond plein).
///
/// [icon] ajoute une icône avant le libellé (recettage direction-artistique
/// du 13/09/2026, écran "Partage — Gérer le lien", action "Désactiver le
/// partage" avec `Icons.block`) : taille 18, `AppColors.accentBrick`, `null`
/// par défaut (aucun usage existant n'en a besoin).
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.icon,
    super.key,
  });

  final String label;

  /// `null` désactive le bouton.
  final VoidCallback? onPressed;

  /// `true` : variant "fond plein" (voir la documentation de classe).
  final bool filled;

  /// Icône optionnelle affichée avant le libellé — voir la documentation de
  /// classe.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled
              ? AppColors.accentBrick
              : AppColors.alertBannerBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.accentBrick,
                  width: AppBorders.card,
                ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: isEnabled ? onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: AppColors.accentBrick),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      // `Flexible` : sans lui, `Text` reçoit une largeur non
                      // bornée de la part de `Row` (perd la contrainte de
                      // largeur propagée par `Padding` quand il en était
                      // l'unique enfant direct) et ne s'enroule/ne rétrécit
                      // plus — régression réelle trouvée sur "Dissoudre le
                      // groupe" (libellé long, `RenderFlex overflowed`).
                      Flexible(
                        child: Text(
                          filled ? label.toUpperCase() : label,
                          textAlign: TextAlign.center,
                          style: filled
                              ? AppTypography.display(
                                  fontSize: 11,
                                  color: AppColors.textOnWood,
                                )
                              : AppTypography.body(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentBrick,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
