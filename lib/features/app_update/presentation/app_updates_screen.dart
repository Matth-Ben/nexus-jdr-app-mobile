import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../profile/presentation/providers/package_info_provider.dart';
import '../data/in_app_update_gateway.dart';
import '../domain/app_version_status.dart';
import '../domain/changelog_parser.dart';
import 'app_store_launcher.dart';
import 'providers/app_updates_providers.dart';
import 'providers/app_version_providers.dart';

/// Écran « Nouveautés et mises à jour », route `/profile/updates` (demande
/// utilisateur, 2026-09-27) : version installée, bouton « Rechercher une
/// mise à jour » et notes de version de chaque version publiée
/// (`CHANGELOG.md` embarqué, voir [ChangelogParser]).
///
/// Recherche de mise à jour :
/// 1. mise à jour intégrée Google Play en mode immédiat
///    ([InAppUpdateGateway]) : si une version plus récente existe, Google
///    Play la télécharge, l'installe et redémarre l'app ;
/// 2. si elle est impossible (iOS, app non installée depuis le Play Store),
///    repli sur la table `app_versions` (`appVersionCheckProvider`) et
///    ouverture de la fiche store.
class AppUpdatesScreen extends ConsumerStatefulWidget {
  const AppUpdatesScreen({super.key});

  @override
  ConsumerState<AppUpdatesScreen> createState() => _AppUpdatesScreenState();
}

class _AppUpdatesScreenState extends ConsumerState<AppUpdatesScreen> {
  bool _isChecking = false;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkForUpdate() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final outcome = await ref
          .read(inAppUpdateGatewayProvider)
          .tryImmediateUpdate();
      if (!mounted) return;
      switch (outcome) {
        case InAppUpdateOutcome.updated:
          _showSnackBar('Mise à jour installée.');
        case InAppUpdateOutcome.upToDate:
          _showSnackBar('Tu as déjà la dernière version.');
        case InAppUpdateOutcome.declined:
          _showSnackBar('Mise à jour annulée.');
        case InAppUpdateOutcome.failed:
          _showSnackBar('La mise à jour a échoué. Réessaie plus tard.');
        case InAppUpdateOutcome.unavailable:
          await _checkWithVersionTable();
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  /// Repli hors Google Play : compare avec la table `app_versions`.
  Future<void> _checkWithVersionTable() async {
    ref.invalidate(appVersionCheckProvider);
    final result = await ref.read(appVersionCheckProvider.future);
    if (!mounted) return;
    if (result.status == AppVersionStatus.upToDate) {
      _showSnackBar('Tu as déjà la dernière version.');
      return;
    }
    // Recherche terminée : le bouton ne doit plus tourner derrière la boîte
    // de dialogue.
    setState(() => _isChecking = false);
    final openStore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: Text(
          'La version ${result.latestVersion} est disponible (tu as la '
          '${result.installedVersion}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Plus tard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
    if (openStore == true && mounted) {
      await openAppStorePage(context, storeUrl: result.storeUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final installedVersion = ref.watch(packageInfoProvider).value?.version;
    final releasesAsync = ref.watch(changelogReleasesProvider);

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(title: 'NOUVEAUTÉS', onBack: _goBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _UpdateCard(
                  installedVersion: installedVersion,
                  isChecking: _isChecking,
                  onCheck: _checkForUpdate,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'DERNIÈRES MISES À JOUR',
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...releasesAsync.when(
                  data: (releases) => releases.isEmpty
                      ? [const _EmptyMessage()]
                      : [
                          for (final release in releases) ...[
                            _ReleaseCard(
                              release: release,
                              isInstalled: release.version == installedVersion,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                  loading: () => [
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.woodMedium,
                      ),
                    ),
                  ],
                  error: (_, _) => [const _EmptyMessage()],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.installedVersion,
    required this.isChecking,
    required this.onCheck,
  });

  final String? installedVersion;
  final bool isChecking;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            installedVersion == null
                ? 'Version installée'
                : 'Version installée : $installedVersion',
            style: AppTypography.body(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Recherche une mise à jour pour installer tout de suite la '
            'dernière version disponible.',
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Rechercher une mise à jour',
            isLoading: isChecking,
            onPressed: onCheck,
          ),
        ],
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.release, required this.isInstalled});

  final ChangelogRelease release;
  final bool isInstalled;

  static String? _formatDate(String? isoDate) {
    if (isoDate == null) return null;
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(release.date);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isInstalled ? AppColors.goldEnd : AppColors.woodLight,
          width: isInstalled ? AppBorders.cardEmphasis : AppBorders.card,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Version ${release.version}',
                  style: AppTypography.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isInstalled)
                Text(
                  'INSTALLÉE',
                  style: AppTypography.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldEnd,
                  ),
                ),
            ],
          ),
          if (date != null)
            Text(
              date,
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          for (final note in release.notes) ...[
            Text(note, style: AppTypography.body(fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Aucune note de version disponible.',
      style: AppTypography.body(fontSize: 13, color: AppColors.textMuted),
    );
  }
}
