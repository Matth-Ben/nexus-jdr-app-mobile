import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Bandeau d'info inline" du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4) : nouveau
/// composant, introduit pour le bandeau "Compte lié à l'app Histoires" de
/// l'écran "Profil" (`features/profile/presentation/profile_screen.dart`) —
/// aucun token existant ne convenait, le "Bandeau d'alerte inline" (même
/// document) étant explicitement réservé aux erreurs/actions correctives
/// (fond `#FDECE0`, bordure `accent.brick`), jamais à de l'information
/// neutre.
///
/// Fond `parchment.card`, bordure 2px `gold-end`, icône [icon] en
/// `accent.teal` (le token "info secondaire" de la palette, voir
/// `AppColors`/section 1 du design système). Non interactif par nature (pas
/// d'`InkWell`, pas de chevron) : instancié directement dans
/// `core/widgets/` plutôt qu'un gabarit privé à un seul écran, cet usage
/// ("compte lié") pouvant resservir ailleurs (chef de projet, tâche
/// "écran Profil").
class InfoBanner extends StatelessWidget {
  const InfoBanner({required this.message, required this.icon, super.key});

  final String message;

  /// Icône affichée à gauche du message, toujours en `AppColors.accentTeal`
  /// — voir la documentation de classe.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.goldEnd, width: AppBorders.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentTeal, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
