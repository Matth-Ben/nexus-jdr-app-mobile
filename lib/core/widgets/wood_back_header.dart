import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bandeau bois plein en tête d'écran, avec un bouton retour et un titre en
/// majuscules (`font.display`) — voir
/// `docs/cahier-des-charges/10-design-system.md` section 6.
///
/// Extrait de `_Header` (`features/character_creation/presentation/race_step_screen.dart`,
/// étape 1/9 "Race") en composant partagé (`core/widgets/`) à l'occasion de
/// la fiche personnage (`features/characters/presentation/character_detail_screen.dart`,
/// bandeau "FICHE"), qui a besoin exactement du même habillage sans barre de
/// progression — pour ne pas dupliquer ce pattern une 3ᵉ fois. [title] est
/// paramétrable ("CRÉATION", "FICHE", "RECADRAGE"...) là où l'original avait
/// "CRÉATION" en dur.
class WoodBackHeader extends StatelessWidget {
  const WoodBackHeader({
    required this.title,
    required this.onBack,
    this.trailing,
    super.key,
  });

  /// Libellé affiché à droite de la flèche retour, déjà en majuscules
  /// (`font.display` ne transforme pas la casse automatiquement — voir
  /// `AppTypography`).
  final String title;

  final VoidCallback onBack;

  /// Widget optionnel affiché à l'extrémité droite du bandeau (ex. un
  /// `IconButton` "Ajouter une récompense" sur l'onglet "Inventaire" de la
  /// fiche personnage, `presentation/character_detail_screen.dart`) — `null`
  /// par défaut, comportement inchangé pour tous les usages existants
  /// (`CRÉATION`/`FICHE`/`RECADRAGE`...). [title] reste enveloppé dans un
  /// `Expanded` que [trailing] soit fourni ou non, pour ne rien changer à sa
  /// position/son ellipsis quand ce dernier est absent.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textOnWood,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textOnWood,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
