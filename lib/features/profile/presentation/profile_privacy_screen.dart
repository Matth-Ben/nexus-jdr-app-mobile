import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_preferences_provider.dart';
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
/// confidentialité", "Autorisations de l'appareil" — la dernière avec une
/// icône de fin `Icons.north_east` puisqu'elle ouvre une sheet système, voir
/// `MenuTile.trailingIcon` ; "Politique de confidentialité" garde le chevron
/// par défaut depuis qu'elle pousse un écran interne
/// (`ProfilePrivacyPolicyScreen`, `/profile/privacy/policy`) plutôt que
/// d'afficher `_showComingSoon` — même convention que "Confidentialité et
/// données"/"Aide et support" sur `ProfileScreen`, `north_east` étant
/// réservé aux actions qui sortent de l'app ou ouvrent une sheet système)
/// puis une section "ZONE DANGEREUSE" (`DestructiveMenuTile` isolée,
/// "Supprimer mon compte", qui pousse l'écran dédié
/// `/profile/privacy/delete-account` (`ProfileDeleteAccountScreen`) plutôt
/// que d'ouvrir une sheet — recettage direction-artistique du 13/09/2026, la
/// maquette attend un écran plein).
///
/// Lecture 100% synchrone à l'ouverture (aucune donnée à charger, chaque
/// tuile ouvre sa propre sheet ou route) : ni état de chargement ni appel
/// réseau ici, même remarque que `ProfileScreen`/`ProfileEditScreen` — à
/// l'exception de la bascule "Partager mes données d'usage" ci-dessous, qui
/// lit `AnalyticsPreferencesController`
/// (`core/analytics/analytics_preferences_provider.dart`, `SharedPreferences`
/// local, jamais de table Supabase).
///
/// **"Partager mes données d'usage"** (`core/analytics/`, décision chef de
/// projet RGPD du 23/09/2026) : rangée bascule standalone, activée par
/// défaut, désactivable à tout moment — aucun bandeau de consentement
/// bloquant pour cette itération. `AnalyticsPreferencesController.state` se
/// met à jour de façon synchrone dès l'appel de `setEnabled` (voir sa doc),
/// donc [onChanged] appelle directement le contrôleur sans état optimiste
/// local supplémentaire, contrairement à `ProfileNotificationsScreen`
/// (dont le provider sous-jacent, un dépôt Supabase, n'offre pas cette
/// garantie).
class ProfilePrivacyScreen extends ConsumerWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsEnabled = ref.watch(analyticsPreferencesControllerProvider);

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
                        onTap: () => context.push('/profile/privacy/policy'),
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
                  _ToggleRow(
                    title: 'Partager mes données d\'usage',
                    subtitle:
                        "Statistiques d'utilisation anonymes, pour "
                        "améliorer l'app. Désactivable à tout moment.",
                    value: analyticsEnabled,
                    onChanged: (value) => ref
                        .read(analyticsPreferencesControllerProvider.notifier)
                        .setEnabled(value),
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
}

/// Rangée "carte + interrupteur" standalone, dupliquée depuis
/// `profile_notifications_screen.dart::_ToggleRow`/`_AppSwitch` (widgets
/// privés à ce fichier, non exportés) — même convention de duplication
/// assumée que `character_creation/data/race_row_mapper.dart` : un seul
/// écran (`ProfileNotificationsScreen`) portait ce gabarit jusqu'ici, pas de
/// composant partagé introduit pour deux usages plutôt qu'un import
/// cross-écran qui coupler inutilement ces deux fichiers entre eux.
///
/// Version simplifiée par rapport à l'original : ni [icon] ni `standalone`
/// (toujours `true`, seul usage de ce fichier) — retirés plutôt que copiés
/// sans jamais être utilisés.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _AppSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// `Switch` Material thématisé aux tokens "Interrupteur (switch)" de
/// `docs/cahier-des-charges/10-design-system.md` section 4 — dupliqué depuis
/// `profile_notifications_screen.dart::_AppSwitch` (voir sa doc de classe
/// pour le rationale des couleurs), sans son état désactivé (`onChanged`
/// toujours non-`null` sur cet écran, jamais grisé).
class _AppSwitch extends StatelessWidget {
  const _AppSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: const WidgetStatePropertyAll(AppColors.parchmentCard),
      trackColor: WidgetStatePropertyAll(
        value ? AppColors.woodMedium : AppColors.woodLight,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.woodDark),
      trackOutlineWidth: const WidgetStatePropertyAll(1),
    );
  }
}
