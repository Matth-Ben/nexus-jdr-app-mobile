import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/destructive_menu_tile.dart';
import '../../../core/widgets/menu_tile.dart';
import '../../../core/widgets/settings_list_card.dart';
import '../../../core/widgets/wood_back_header.dart';
import 'widgets/device_permissions_sheet.dart';
import 'widgets/export_data_sheet.dart';

/// Sous-écran "Confidentialité", route `/profile/privacy` — poussé depuis la
/// tuile "Confidentialité et données" de `profile_screen.dart` (qui
/// affichait auparavant `_showComingSoon`, voir la doc de classe de
/// `ProfileScreen`). Le bandeau bois de cet écran est volontairement plus
/// court ("CONFIDENTIALITÉ") que le libellé de la tuile qui y mène — recettage
/// direction-artistique du 13/09/2026.
///
/// Gabarit B identique à `ProfileEditScreen` (`WoodBackHeader` + corps
/// parchemin scrollable) : une section "MES DONNÉES" (3 tuiles regroupées
/// dans un `SettingsListCard` — "Exporter mes données", "Politique de
/// confidentialité", "Autorisations de l'appareil" — les 2 dernières avec
/// une icône de fin `Icons.north_east` puisqu'elles sortent de l'app/ouvrent
/// une sheet système, voir `MenuTile.trailingIcon`) puis une section "ZONE
/// DANGEREUSE" (`DestructiveMenuTile` isolée, "Supprimer mon compte", qui
/// pousse l'écran dédié `/profile/privacy/delete-account`
/// (`ProfileDeleteAccountScreen`) plutôt que d'ouvrir une sheet — recettage
/// direction-artistique du 13/09/2026, la maquette attend un écran plein).
///
/// Lecture 100% synchrone à l'ouverture (aucune donnée à charger, chaque
/// tuile ouvre sa propre sheet ou route) : ni état de chargement ni appel
/// réseau ici, même remarque que `ProfileScreen`/`ProfileEditScreen`.
class ProfilePrivacyScreen extends StatelessWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'CONFIDENTIALITÉ',
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MES DONNÉES',
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsListCard(
                    children: [
                      MenuTile(
                        standalone: false,
                        icon: Icons.download_outlined,
                        label: 'Exporter mes données',
                        onTap: () => showExportDataSheet(context),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.description_outlined,
                        label: 'Politique de confidentialité',
                        trailingIcon: Icons.north_east,
                        onTap: () => _showComingSoon(context),
                      ),
                      MenuTile(
                        standalone: false,
                        icon: Icons.admin_panel_settings_outlined,
                        label: "Autorisations de l'appareil",
                        trailingIcon: Icons.north_east,
                        onTap: () => showDevicePermissionsSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "L'export contient tes personnages, leur inventaire, "
                    'leurs sorts et leur historique (JSON, envoyé par '
                    'e-mail).',
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.gaugeTrack,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'ZONE DANGEREUSE',
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentBrick,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DestructiveMenuTile(
                    label: 'Supprimer mon compte',
                    onTap: () =>
                        context.push('/profile/privacy/delete-account'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Même garde que `ProfileScreen._goBack`/`ProfileEditScreen._goBack` :
  /// cet écran est normalement toujours atteint via
  /// `context.push('/profile/privacy')` (donc `canPop()` vrai), mais reste
  /// défensif si jamais poussé un jour comme route initiale (deep link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Tap sur "Politique de confidentialité", pas encore implémentée (spec
  /// direction-artistique de la tâche) — même texte exact que
  /// `ProfileScreen._showComingSoon`, réutilisé mot pour mot plutôt qu'une
  /// nouvelle constante.
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
  }
}
