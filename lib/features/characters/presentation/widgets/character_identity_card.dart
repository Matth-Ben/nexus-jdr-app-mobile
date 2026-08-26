import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/portrait_frame.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_identity_formatter.dart';

/// Carte d'identité de l'onglet "Personnage" : portrait, nom, et les deux
/// lignes de sous-titre (race/classe/niveau, historique/alignement) — voir la
/// spec visuelle de la tâche qui a produit ce fichier.
class CharacterIdentityCard extends StatelessWidget {
  const CharacterIdentityCard({
    required this.detail,
    required this.onTapPortrait,
    super.key,
  });

  final CharacterDetail detail;
  final VoidCallback onTapPortrait;

  @override
  Widget build(BuildContext context) {
    final line1 = CharacterIdentityFormatter.subtitleLine1(detail);
    final line2 = CharacterIdentityFormatter.subtitleLine2(detail);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PortraitWithCameraBadge(
            portraitUrl: detail.portraitUrl,
            onTap: onTapPortrait,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: AppTypography.body(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (line1.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    line1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (line2 != null) ...[
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    line2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitWithCameraBadge extends StatelessWidget {
  const _PortraitWithCameraBadge({
    required this.portraitUrl,
    required this.onTap,
  });

  final String? portraitUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        // Un peu plus grand que le cadre 64×64 pour laisser le badge caméra
        // déborder (`Positioned(right: -4, bottom: -4)`) sans être coupé.
        width: 68,
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PortraitFrame(portraitUrl: portraitUrl),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.woodDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldEnd, width: 1.5),
                ),
                child: const Icon(
                  Icons.photo_camera,
                  size: 12,
                  color: AppColors.textOnWood,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
