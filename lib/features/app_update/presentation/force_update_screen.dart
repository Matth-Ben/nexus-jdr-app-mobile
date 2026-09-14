import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import 'app_store_launcher.dart';

/// Écran "Erreur — Mise à jour obligatoire" — recettage direction-artistique
/// du 13/09/2026 (`docs/cahier-des-charges/09-maquettes-captures.md`, section
/// "Erreur — Mise à jour obligatoire").
///
/// **Écran bloquant** : aucun bouton retour, aucune `AppBar`, jamais poussé
/// comme route du routeur applicatif (`core/router/app_router.dart`) — voir
/// `main.dart::_AppBootstrapState.build`, qui l'affiche à la place de
/// `NexusJdrApp` (dans son propre `MaterialApp` minimal, même principe que
/// `SplashScreen`) dès que `appVersionCheckProvider`
/// (`presentation/providers/app_version_providers.dart`) résout
/// `AppVersionStatus.updateRequired`, et ne bascule jamais sur autre chose
/// tant que ce statut reste vrai (pas de possibilité de le contourner sans
/// mettre à jour l'app).
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    required this.installedVersion,
    required this.minimumVersion,
    this.storeUrl,
    super.key,
  });

  /// Version actuellement installée (`PackageInfo.version`).
  final String installedVersion;

  /// `app_versions.min_supported_version` de la plateforme courante.
  final String minimumVersion;

  /// `app_versions.store_url` — voir `app_store_launcher.dart` pour le
  /// comportement de repli quand `null`/vide.
  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    return SceneScaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _UpdateBadge(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'MISE À JOUR',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(
                    fontSize: 15,
                    color: AppColors.textOnWood,
                  ),
                ),
                Text(
                  'REQUISE',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(
                    fontSize: 15,
                    color: AppColors.textOnWood,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "Cette version de Nexus JDR n'est plus prise en charge. "
                  "Mets à jour l'application pour continuer à gérer tes "
                  'personnages en toute sécurité.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.textOnWoodMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: '↓ Mettre à jour',
                    onPressed: () =>
                        openAppStorePage(context, storeUrl: storeUrl),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Version installée : $installedVersion · minimum requis : '
                  '$minimumVersion',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 11,
                    color: AppColors.textOnWoodMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge doré rond avec icône téléchargement — voir la maquette citée dans
/// la doc de classe de [ForceUpdateScreen]. Recréé localement plutôt qu'une
/// réutilisation d'`AppBrandBadge` (`core/widgets/app_brand_badge.dart`,
/// suggéré comme point de départ possible par la tâche) : ce dernier est
/// spécifiquement l'emblème de la marque (bouclier), une icône différente de
/// la flèche de téléchargement de cette maquette — un simple `Container`
/// dédié reste plus direct qu'un paramètre d'icône ajouté à un composant de
/// marque.
class _UpdateBadge extends StatelessWidget {
  const _UpdateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryButtonGradient,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.woodDark, width: AppBorders.cardEmphasis),
        ),
      ),
      child: const Icon(
        Icons.file_download_outlined,
        size: 40,
        color: AppColors.woodDark,
      ),
    );
  }
}
