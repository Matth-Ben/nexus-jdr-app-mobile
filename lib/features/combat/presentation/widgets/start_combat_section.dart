import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/compact_action_button.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../core/widgets/pixel_icons/combat_pixel_icons.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../groups/domain/group_detail.dart';
import '../../domain/combat_failure.dart';
import '../../domain/combat_permissions.dart';
import '../../domain/combat_view_state.dart';
import '../combat_l10n.dart';
import '../providers/combat_providers.dart';
import '../providers/combat_read_only_provider.dart';

/// Entrée « Lancer un combat » de l'onglet Membres (`docs/combat-groupe-ui.md`
/// §4), sous l'indicateur de mise à jour en direct :
/// - MJ dans l'app ([canStartCombat]) sans combat actif : bouton primaire
///   pleine largeur (spinner pendant l'appel, désactivé hors ligne avec
///   « Indisponible hors ligne ») ;
/// - propriétaire sans rôle MJ : bandeau « Pas de combat sans MJ dans l'app. »
///   et lien vers les paramètres ;
/// - joueur ou combat déjà actif (le bandeau du groupe prend le relais) :
///   rien — jamais de bouton grisé.
class StartCombatSection extends ConsumerStatefulWidget {
  const StartCombatSection({
    required this.detail,
    required this.onOpenCombat,
    required this.onOpenSettings,
    super.key,
  });

  final GroupDetail detail;
  final VoidCallback onOpenCombat;
  final VoidCallback onOpenSettings;

  @override
  ConsumerState<StartCombatSection> createState() => _StartCombatSectionState();
}

class _StartCombatSectionState extends ConsumerState<StartCombatSection> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _starting = true);
    var opened = false;
    String? error;
    try {
      await ref.read(combatProvider(widget.detail.id).notifier).startCombat();
      opened = true;
    } on CombatFailure catch (failure) {
      // `combat_already_active` : le fournisseur a déjà relancé un refetch.
      error = failure.kind == CombatFailureKind.combatAlreadyActive
          ? l10n.combatStartAlreadyActive
          : failure.localized(l10n);
    } on Object {
      error = l10n.combatFailureGeneric;
    }
    if (!mounted) return;
    setState(() => _starting = false);
    if (opened) {
      widget.onOpenCombat();
    } else if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    if (!detail.isOwner) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    if (!canStartCombat(detail)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoBanner(
              icon: Icons.info_outline,
              message: l10n.combatNoMasterExplain,
            ),
            const SizedBox(height: AppSpacing.xs),
            CompactActionButton(
              icon: Icons.admin_panel_settings_outlined,
              label: l10n.combatNoMasterSettings,
              onTap: widget.onOpenSettings,
            ),
          ],
        ),
      );
    }

    final phase = ref.watch(
      combatProvider(detail.id).select((state) => state.phase),
    );
    if (phase == CombatPhase.loading || phase == CombatPhase.active) {
      return const SizedBox.shrink();
    }
    final readOnly = ref.watch(combatReadOnlyProvider(detail.id));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: PixelIcon(
                  matrix: kCombatSwordsMatrix,
                  size: 32,
                  color: readOnly
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: PrimaryButton(
                  label: l10n.combatStart,
                  isLoading: _starting,
                  onPressed: readOnly ? null : _start,
                ),
              ),
            ],
          ),
          if (readOnly)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.combatStartUnavailableOffline,
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
