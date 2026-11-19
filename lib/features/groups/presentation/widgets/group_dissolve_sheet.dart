import 'dart:async';

import '../../../combat/presentation/providers/character_combat_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../combat/presentation/providers/combat_providers.dart';
import '../../domain/group_failure.dart';
import '../group_failure_l10n.dart';
import '../providers/group_providers.dart';

/// Ouvre la sheet "Dissoudre le groupe" (`DestructiveButton` de la section
/// "ZONE DANGEREUSE" de `group_settings_screen.dart`, anciennement isolé
/// dans `group_management_sheet.dart`, retiré par le recettage
/// direction-artistique du 13/09/2026) — calque EXACT de l'ancienne
/// `features/profile/presentation/widgets/delete_account_sheet.dart` (un
/// seul widget à 2 étapes internes : avertissement, puis confirmation),
/// avec une confirmation par retape du NOM DU GROUPE (comparaison
/// insensible casse/espaces) plutôt qu'un mot de passe — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2. Ce
/// fichier de référence a depuis été remplacé par l'écran dédié
/// `features/profile/presentation/profile_delete_account_screen.dart`
/// (recettage direction-artistique du 13/09/2026) ; cette sheet-ci reste
/// volontairement une sheet à 2 étapes (pas d'écran dédié), le patron
/// décrit ici n'a donc plus de jumeau exact ailleurs dans le dépôt.
///
/// Gère elle-même toute la séquence "confirmer -> dissoudre -> naviguer" :
/// contrairement à `showGroupRenameSheet`, il n'y a rien à faire après coup
/// côté appelant (succès -> `context.go('/')` + `SnackBar('Groupe
/// dissous.')`, directement depuis cette sheet).
///
/// **Combat actif (D224)** : l'appelant (`GroupSettingsScreen`) relit l'état
/// du combat avant d'ouvrir cette sheet (garde cliente), mais le serveur est
/// l'autorité : DeepCore refuse la dissolution pendant un combat actif
/// (`combat_active`, migration `20261119090000`). Ce refus, même avec un état
/// local périmé, est traduit ici en message clair et relance la lecture du
/// combat.
///
/// **Avertissement (D228)** : liste toutes les suppressions en cascade de
/// DeepCore (membres, butin commun, carnets de notes des joueurs, journal,
/// combats) et rappelle que les personnages restent intacts.
Future<void> showGroupDissolveSheet(
  BuildContext context, {
  required String groupId,
  required String groupName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) =>
        _GroupDissolveSheetContent(groupId: groupId, groupName: groupName),
  );
}

enum _DissolveStep { warning, confirm }

/// Message d'un échec de dissolution : refus `combat_active` dédié, échec non
/// reconnu générique (jamais le message brut du serveur), sinon le texte du
/// code (réseau, session, conflit transitoire...).
String _dissolveFailureMessage(GroupFailure failure, AppLocalizations l10n) {
  return switch (failure.code) {
    GroupErrorCode.combatActive => l10n.groupDissolveBlockedByCombat,
    GroupErrorCode.generic => l10n.groupDissolveGenericError,
    _ => failure.localizedWith(l10n),
  };
}

class _GroupDissolveSheetContent extends ConsumerStatefulWidget {
  const _GroupDissolveSheetContent({
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  ConsumerState<_GroupDissolveSheetContent> createState() =>
      _GroupDissolveSheetContentState();
}

class _GroupDissolveSheetContentState
    extends ConsumerState<_GroupDissolveSheetContent> {
  _DissolveStep _step = _DissolveStep.warning;
  final TextEditingController _nameController = TextEditingController();
  bool _isDissolving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goToConfirmStep() {
    if (_isDissolving) return;
    setState(() => _step = _DissolveStep.confirm);
  }

  /// Comparaison insensible casse/espaces (`trim` + `toLowerCase` des deux
  /// côtés) — spec de la tâche.
  bool get _nameMatches =>
      _nameController.text.trim().toLowerCase() ==
      widget.groupName.trim().toLowerCase();

  Future<void> _confirmDissolve() async {
    if (_isDissolving || !_nameMatches) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isDissolving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(groupRepositoryProvider).dissolveGroup(widget.groupId);
      ref.invalidate(characterGroupIdsProvider);
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == GroupErrorCode.combatActive) {
        // État local périmé : le serveur a vu un combat actif. On relit le
        // combat pour que l'écran Groupe affiche son bandeau.
        unawaited(ref.read(combatProvider(widget.groupId).notifier).refresh());
      }
      setState(() {
        _isDissolving = false;
        _errorMessage = _dissolveFailureMessage(failure, l10n);
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDissolving = false;
        _errorMessage = l10n.groupDissolveGenericError;
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    context.go('/');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.groupDissolveSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isDissolving,
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            color: AppColors.parchmentBg,
            child: Column(
              children: [
                SheetHeaderBar(
                  title: l10n.groupDissolveSheetTitle,
                  closeEnabled: !_isDissolving,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: switch (_step) {
                      _DissolveStep.warning => AlertBanner(
                        message: l10n.groupDissolveWarning,
                      ),
                      _DissolveStep.confirm => _ConfirmStepBody(
                        nameController: _nameController,
                        enabled: !_isDissolving,
                        errorMessage: _errorMessage,
                        onChanged: () => setState(() {}),
                      ),
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: switch (_step) {
                    _DissolveStep.warning => Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: l10n.groupDissolveCancel,
                            surface: SecondaryButtonSurface.parchment,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DestructiveButton(
                            label: l10n.groupDissolveContinue,
                            onPressed: _goToConfirmStep,
                          ),
                        ),
                      ],
                    ),
                    _DissolveStep.confirm => Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: l10n.groupDissolveCancel,
                            surface: SecondaryButtonSurface.parchment,
                            onPressed: _isDissolving
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DestructiveButton(
                            label: _isDissolving
                                ? l10n.groupDissolveInProgress
                                : l10n.groupDissolveConfirm,
                            onPressed: (!_isDissolving && _nameMatches)
                                ? _confirmDissolve
                                : null,
                          ),
                        ),
                      ],
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmStepBody extends StatelessWidget {
  const _ConfirmStepBody({
    required this.nameController,
    required this.enabled,
    required this.errorMessage,
    required this.onChanged,
  });

  final TextEditingController nameController;
  final bool enabled;
  final String? errorMessage;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          AlertBanner(message: errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          l10n.groupDissolveRetypeLabel,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: nameController,
          enabled: enabled,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(hintText: l10n.groupDissolveRetypeHint),
        ),
      ],
    );
  }
}
