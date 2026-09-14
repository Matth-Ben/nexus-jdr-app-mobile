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
  const InfoBanner({required this.message, required this.icon, super.key})
    : _isSuccess = false;

  /// Variant "succès" (recettage direction-artistique du 13/09/2026, écran
  /// "Partage — Gérer le lien", bandeau "Partage actif") : fond vert menthe
  /// pâle (`Color(0xFFE7F0E9)`), bordure `AppColors.accentTeal`, puce ronde
  /// pleine (`Icons.circle`, ~8px, `accentTeal`) devant le texte au lieu de
  /// l'icône du variant par défaut — nouveau token visuel absent de
  /// `10-design-system.md`, distinct du variant "info neutre" ci-dessus
  /// (fond `parchment.card`/bordure `gold-end`), jamais utilisé pour la même
  /// situation (succès vs information neutre).
  const InfoBanner.success({required this.message, super.key})
    : icon = null,
      _isSuccess = true;

  final String message;

  /// Icône affichée à gauche du message, toujours en `AppColors.accentTeal`
  /// — voir la documentation de classe. `null` pour le variant [success],
  /// qui affiche une puce ronde à la place.
  final IconData? icon;

  final bool _isSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _isSuccess ? const Color(0xFFE7F0E9) : AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _isSuccess ? AppColors.accentTeal : AppColors.goldEnd,
          width: AppBorders.card,
        ),
      ),
      child: Row(
        children: [
          _isSuccess
              ? const Icon(Icons.circle, color: AppColors.accentTeal, size: 8)
              : Icon(icon, color: AppColors.accentTeal, size: 20),
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
