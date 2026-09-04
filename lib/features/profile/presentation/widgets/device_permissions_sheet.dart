import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';

/// Ouvre la sheet "Gestion des autorisations appareil" (tuile éponyme de
/// `presentation/profile_privacy_screen.dart`) — sheet compacte (wrap-content,
/// même gabarit que `export_data_sheet.dart`), texte **statique** : décision
/// chef de projet, cette sheet ne lit jamais l'état réel des permissions
/// caméra/galerie (aucune dépendance `permission_handler`, package plus
/// lourd et inutile ici — voir le commentaire de la dépendance `app_settings`
/// dans `pubspec.yaml`).
///
/// Action 100% locale (`AppSettings.openAppSettings`, ouvre les réglages
/// système de l'app) : aucun état d'erreur/hors-ligne, contrairement à
/// `export_data_sheet.dart`/`delete_account_sheet.dart` — la sheet reste
/// librement fermable (voile/geste retour/`X`), aucun appel réseau à
/// protéger.
Future<void> showDevicePermissionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _DevicePermissionsSheetContent(),
  );
}

class _DevicePermissionsSheetContent extends StatelessWidget {
  const _DevicePermissionsSheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeaderBar(title: 'GESTION DES AUTORISATIONS APPAREIL'),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Nexus JDR utilise l\'appareil photo et la galerie '
                'uniquement pour définir le portrait de ton personnage ou '
                'ton avatar. Pour modifier ces autorisations, ouvre les '
                'réglages de ton téléphone.',
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: PrimaryButton(
                label: 'Ouvrir les réglages',
                onPressed: () => AppSettings.openAppSettings(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
