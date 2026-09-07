import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Emblème rond de la marque "Nexus JDR" (bouclier à coche sur médaillon
/// doré) — repris de l'icône d'application (voir `docs/assets/`) pour
/// l'affichage en app, sur l'écran de lancement et l'écran de connexion
/// (`docs/cahier-des-charges/09-maquettes-captures.md`, sections "Lancement
/// — Splash" et "Écran de connexion").
///
/// Rendu en vecteur (`Icon` + `BoxDecoration`) plutôt qu'en image embarquée,
/// pour rester cohérent avec le reste de l'app (aucune image raster
/// embarquée à ce jour, seulement des `Icon` Material pilotées par
/// [AppColors]) et rester net à toute résolution/taille d'affichage.
class AppBrandBadge extends StatelessWidget {
  const AppBrandBadge({this.size = 88, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.035),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.woodLight,
      ),
      child: Container(
        padding: EdgeInsets.all(size * 0.05),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.woodDark,
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryButtonGradient,
          ),
          child: Center(
            child: Icon(
              Icons.gpp_good,
              size: size * 0.5,
              color: AppColors.woodDark,
            ),
          ),
        ),
      ),
    );
  }
}
