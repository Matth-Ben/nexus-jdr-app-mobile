import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import 'widgets/delete_account_sheet.dart';
import 'widgets/device_permissions_sheet.dart';
import 'widgets/export_data_sheet.dart';

/// Sous-écran "Confidentialité et données", route `/profile/privacy` —
/// poussé depuis la tuile éponyme de `profile_screen.dart` (qui affichait
/// auparavant `_showComingSoon`, voir la doc de classe de `ProfileScreen`).
///
/// Gabarit B identique à `ProfileEditScreen` (`WoodBackHeader` + corps
/// parchemin scrollable) : 3 tuiles de menu ("Export de mes données",
/// "Politique de confidentialité", "Gestion des autorisations appareil") +
/// un bouton destructif isolé ("Supprimer mon compte") — spec
/// direction-artistique de la tâche "Confidentialité et données".
///
/// **"Supprimer mon compte" n'est volontairement pas une 4e tuile** : un
/// `DestructiveButton` séparé, placé en dernier après un espacement
/// `AppSpacing.lg` (écart assumé par rapport à l'ordre listé dans le
/// document fonctionnel, cohérent avec le placement de "Se déconnecter" en
/// fin de `profile_screen.dart`, voir la spec de la tâche).
///
/// Lecture 100% synchrone à l'ouverture (aucune donnée à charger, chaque
/// tuile ouvre sa propre sheet) : ni état de chargement ni appel réseau ici,
/// même remarque que `ProfileScreen`/`ProfileEditScreen`.
class ProfilePrivacyScreen extends StatelessWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'CONFIDENTIALITÉ ET DONNÉES',
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _PrivacyMenuTile(
                    icon: Icons.download_outlined,
                    label: 'Export de mes données',
                    onTap: () => showExportDataSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PrivacyMenuTile(
                    icon: Icons.description_outlined,
                    label: 'Politique de confidentialité',
                    onTap: () => _showComingSoon(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PrivacyMenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Gestion des autorisations appareil',
                    onTap: () => showDevicePermissionsSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DestructiveButton(
                    label: 'Supprimer mon compte',
                    onPressed: () => showDeleteAccountSheet(context),
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

/// Une des 3 tuiles de menu de cet écran — copie volontaire de `_MenuTile`
/// (`profile_screen.dart`), pas une extraction en composant partagé : 2e
/// usage seulement (ce fichier + `profile_screen.dart`), sous le seuil
/// d'extraction habituel de ce dépôt (3e usage — voir `SheetHeaderBar`/
/// `ProfileEditScreen._ProfileEditRow` pour ce même rationale déjà
/// documenté), tranché ainsi par la spec direction-artistique de la tâche.
class _PrivacyMenuTile extends StatelessWidget {
  const _PrivacyMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
