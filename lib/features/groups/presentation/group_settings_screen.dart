import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/group_detail.dart';
import '../domain/group_failure.dart';
import 'group_failure_presenter.dart';
import 'providers/group_providers.dart';
import 'widgets/group_confirmation_dialog.dart';
import 'widgets/group_dissolve_sheet.dart';
import 'widgets/group_invite_code_chip.dart';

/// Écran dédié "Paramètres du groupe", route `/groups/:id/settings` —
/// recettage direction-artistique du 13/09/2026 (`docs/cahier-des-charges/
/// 09-maquettes-captures.md`, section "Groupe — Paramètres") : remplace
/// `showGroupManagementSheet` (bottom sheet compacte, retirée par cette
/// tâche), la maquette attend un écran plein dédié plutôt qu'une sheet.
///
/// `WoodBackHeader` + corps parchemin scrollable (même gabarit que
/// `ProfileEditScreen`/`GroupCreateScreen`) : "Nom du groupe" (le
/// `TextFormField` est migré tel quel depuis `widgets/group_rename_sheet.dart`,
/// retiré par cette tâche — seul le libellé au-dessus change de style pour
/// suivre la maquette, voir [_SectionLabel]), "CODE D'INVITATION" (chip +
/// "Régénérer", même logique de confirmation/appel réseau que l'ancienne
/// `showGroupManagementSheet`, voir [_GroupSettingsScreenState
/// ._confirmRegenerateInviteCode]), puis "ZONE DANGEREUSE"
/// (`DestructiveButton` "Dissoudre le groupe", flux de confirmation existant
/// [showGroupDissolveSheet] réutilisé tel quel, jamais réécrit).
///
/// Pas de "Quitter le groupe" ici : cet écran n'est accessible qu'au
/// fondateur (icône réglages du header de `group_screen.dart`, réservée à
/// `detail.isOwner` — les autres membres y voient une icône déconnexion qui
/// déclenche directement `_GroupScreenState._confirmLeaveGroup`, jamais
/// cet écran). Décision du chef de projet : un fondateur ne "quitte" pas
/// son groupe, il le dissout (voir la "ZONE DANGEREUSE" ci-dessus) —
/// `GroupRepository.leaveGroup` ne gère de toute façon pas le transfert de
/// `groups.owner_id` qu'un départ du fondateur supposerait.
///
/// Le nom se sauvegarde via le `PrimaryButton` "Enregistrer" fixé en pied
/// d'écran (`_submitRename`, logique reprise de `group_rename_sheet.dart`) —
/// les autres actions (régénérer/quitter/dissoudre) restent immédiates au
/// tap, comme sur l'ancienne sheet.
class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _nameInitialized = false;
  String _initialName = '';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_isSaving) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _canSave {
    final trimmed = _nameController.text.trim();
    return _nameInitialized &&
        !_isSaving &&
        trimmed.isNotEmpty &&
        trimmed != _initialName;
  }

  /// Migré depuis `group_rename_sheet.dart::_GroupRenameSheetContentState
  /// ._submit` : même appel réseau (écriture directe `UPDATE groups`) et même
  /// distinction [GroupFailure]/erreur générique, adapté pour rester sur
  /// place (écran dédié, pas de `Navigator.pop`) et remettre à jour
  /// [_initialName] pour redésactiver "Enregistrer" jusqu'à la prochaine
  /// modification — même patron que `ProfileEditScreen._submit`.
  Future<void> _submitRename() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(groupRepositoryProvider)
          .renameGroup(groupId: widget.groupId, name: name);
      ref.invalidate(groupDetailProvider(widget.groupId));
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _initialName = name;
      });
      _showSnackBar(l10n.groupSettingsScreenRenamedSnackbar);
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = resolveGroupFailureMessage(l10n, failure);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.groupSettingsScreenGenericRenameErrorMessage;
      });
    }
  }

  /// Même confirmation/appel réseau/invalidation que l'ancienne
  /// `showGroupManagementSheet` (`group_screen.dart::_GroupScreenState
  /// ._confirmRegenerateInviteCode`, retirée avec le bandeau d'identité de
  /// `group_screen.dart` par une tâche parallèle à celle-ci — voir sa doc de
  /// classe).
  Future<void> _confirmRegenerateInviteCode() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: l10n.groupSettingsScreenRegenerateConfirmTitle,
      message: l10n.groupSettingsScreenRegenerateConfirmMessage,
      confirmLabel: l10n.groupSettingsScreenRegenerateConfirmButtonLabel,
      destructive: false,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(groupRepositoryProvider)
          .regenerateInviteCode(widget.groupId);
      ref.invalidate(groupDetailProvider(widget.groupId));
      if (!mounted) return;
      _showSnackBar(l10n.groupSettingsScreenRegeneratedSnackbar);
    } on GroupFailure catch (failure) {
      _showSnackBar(resolveGroupFailureMessage(l10n, failure));
    } catch (_) {
      _showSnackBar(l10n.groupSettingsScreenRegenerateGenericErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    // Initialise le contrôleur de nom une seule fois, dès que
    // `groupDetailProvider` résout une première valeur — pas de
    // `ref.listen(..., fireImmediately: true)` ici : contrairement au `Ref`
    // générique utilisé par `groupMembersRealtimeWatcherProvider`
    // (`providers/group_providers.dart`), le `WidgetRef.listen` d'un
    // `ConsumerState` ne supporte pas `fireImmediately` (un rebuild ne permet
    // pas de savoir quel appel `listen` doit être "réémis"). Une simple
    // lecture de `detailAsync.value` après `ref.watch` suffit : ce `build`
    // est de toute façon ré-exécuté dès que le provider passe de
    // chargement à donnée.
    final detail = detailAsync.value;
    if (detail != null && !_nameInitialized) {
      _nameController.text = detail.name;
      _initialName = detail.name;
      _nameInitialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(title: l10n.groupSettingsScreenTitle, onBack: _goBack),
          Expanded(
            child: detailAsync.when(
              data: _buildBody,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is GroupFailure
                    ? resolveGroupFailureMessage(l10n, error)
                    : l10n.groupSettingsScreenLoadErrorMessage,
                onRetry: () =>
                    ref.invalidate(groupDetailProvider(widget.groupId)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GroupDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  AlertBanner(message: _errorMessage!),
                  const SizedBox(height: AppSpacing.md),
                ],
                _SectionLabel(l10n.groupSettingsScreenNameLabel),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  minLines: 1,
                  maxLines: 1,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.groupSettingsScreenNameHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.groupSettingsScreenInviteCodeSectionLabel,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: GroupInviteCodeChip(code: detail.inviteCode),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SecondaryButton(
                      label: l10n.groupSettingsScreenRegenerateButtonLabel,
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: _confirmRegenerateInviteCode,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.groupSettingsScreenRegenerateHint,
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.woodLight, thickness: 1),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.groupSettingsScreenDangerZoneLabel,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentBrick,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DestructiveButton(
                  label: l10n.groupSettingsScreenDissolveButtonLabel,
                  icon: Icons.delete_outline,
                  onPressed: () => showGroupDissolveSheet(
                    context,
                    groupId: widget.groupId,
                    groupName: detail.name,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.groupSettingsScreenDissolveHint,
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.gaugeTrack),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: PrimaryButton(
            label: l10n.groupSettingsScreenSaveButtonLabel,
            isLoading: _isSaving,
            onPressed: _canSave ? _submitRename : null,
          ),
        ),
      ],
    );
  }
}

/// Libellé "Nom du groupe" — casse normale, plus grand/plus sombre que la
/// convention "MAJUSCULES + `textSecondary`" du reste du module (voir
/// `group_rename_sheet.dart::"NOM DU GROUPE"`) : la maquette "Groupe —
/// Paramètres" (`docs/cahier-des-charges/09-maquettes-captures.md`) montre
/// explicitement cette casse — recettage direction-artistique du 13/09/2026,
/// même écart assumé que `GroupJoinScreen._SectionLabel` (écran "Groupe —
/// Rejoindre" du même recettage).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.body(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: l10n.groupSettingsScreenRetryButtonLabel,
              surface: SecondaryButtonSurface.parchment,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
