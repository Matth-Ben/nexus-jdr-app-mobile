import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/menu_tile.dart';
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
/// direction-artistique de la tâche "Confidentialité et données". Les tuiles
/// utilisent le composant partagé `core/widgets/menu_tile.dart` (`MenuTile`,
/// anciennement `_PrivacyMenuTile` propre à ce fichier, extrait à
/// l'incrément C du chantier "Profil/Paramètres" une fois `ProfileHelpScreen`
/// devenu le 3e usage identique — voir la doc de classe de `MenuTile`).
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
                  MenuTile(
                    icon: Icons.download_outlined,
                    label: 'Export de mes données',
                    onTap: () => showExportDataSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
                    icon: Icons.description_outlined,
                    label: 'Politique de confidentialité',
                    onTap: () => _showComingSoon(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
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
