import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/app_version_status.dart';
import '../app_store_launcher.dart';
import '../providers/app_version_providers.dart';
import '../providers/update_banner_dismissal_provider.dart';

/// Bannière "Mise à jour suggérée" — recettage direction-artistique du
/// 13/09/2026 (`docs/cahier-des-charges/09-maquettes-captures.md`, section
/// "Bannière — Mise à jour suggérée"), insérée par
/// `character_list_screen.dart` entre l'en-tête et la barre de recherche.
///
/// Se réduit elle-même à `SizedBox.shrink()` (aucune place réservée) tant
/// que `appVersionCheckProvider`
/// (`presentation/providers/app_version_providers.dart`) n'a pas résolu un
/// statut `AppVersionStatus.updateSuggested`, ou que sa
/// `latestVersion` correspondante a déjà été refermée
/// (`providers/update_banner_dismissal_provider.dart`) — l'écran appelant
/// n'a donc aucune condition à évaluer lui-même, il insère ce widget
/// inconditionnellement.
class UpdateSuggestedBanner extends ConsumerWidget {
  const UpdateSuggestedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(appVersionCheckProvider).value;
    final dismissedVersion = ref.watch(updateBannerDismissalControllerProvider);

    if (result == null || result.status != AppVersionStatus.updateSuggested) {
      return const SizedBox.shrink();
    }
    if (dismissedVersion == result.latestVersion) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.parchmentCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.goldEnd, width: AppBorders.card),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.file_download_outlined,
              color: AppColors.goldEnd,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Nouvelle version disponible',
                style: AppTypography.body(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            InkWell(
              onTap: () => openAppStorePage(context, storeUrl: result.storeUrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Mettre à jour',
                  style: AppTypography.body(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentBrick,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: 'Fermer',
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => ref
                    .read(updateBannerDismissalControllerProvider.notifier)
                    .dismiss(result.latestVersion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
