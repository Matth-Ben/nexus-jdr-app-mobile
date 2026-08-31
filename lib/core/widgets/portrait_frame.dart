import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'dashed_border_painter.dart';

/// "Cadre de portrait" du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4) : bordure 3px
/// `wood.light` + halo 1px `wood.dark`, coins à `radius.md`, autour d'une
/// image libre — utilisé par la carte personnage de la liste d'accueil, et
/// destiné à être réutilisé en tête de fiche personnage.
///
/// Sans [portraitUrl], affiche un motif pointillé neutre `color.text.muted`
/// (voir maquette `01_liste_personnages.png`, personnage "Sylvi
/// Aubefeuille") plutôt que le dégradé thématique par classe également
/// mentionné au design système : ce second fallback n'a pas encore de
/// mapping classe → dégradé défini nulle part dans le cahier des charges, à
/// spécifier par la direction artistique avant implémentation.
///
/// [fallbackIcon] (`Icons.person_outline` par défaut, comportement inchangé
/// pour tous les appelants existants) permet de réutiliser ce même cadre pour
/// une couverture d'histoire (`Icons.auto_stories`, voir le flux "Rejoindre
/// une histoire" et la carte "Aventures" de la fiche personnage) plutôt
/// qu'une silhouette humaine, sans toucher à aucun autre token visuel.
class PortraitFrame extends StatelessWidget {
  const PortraitFrame({
    required this.portraitUrl,
    this.size = 64,
    this.fallbackIcon = Icons.person_outline,
    super.key,
  });

  final String? portraitUrl;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.woodLight,
          width: AppBorders.cardEmphasis,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.woodDark,
            blurRadius: 0,
            spreadRadius: AppBorders.cardEmphasisHalo,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: portraitUrl == null
          ? _EmptyPortraitPlaceholder(icon: fallbackIcon)
          : Image.network(
              portraitUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _EmptyPortraitPlaceholder(icon: fallbackIcon),
            ),
    );
  }
}

/// Motif pointillé neutre affiché quand le personnage/l'histoire n'a pas de
/// portrait/couverture.
class _EmptyPortraitPlaceholder extends StatelessWidget {
  const _EmptyPortraitPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(color: AppColors.textMuted),
      child: Center(child: Icon(icon, color: AppColors.textMuted)),
    );
  }
}
