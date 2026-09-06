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
import '../providers/group_providers.dart';

/// Ouvre la sheet "Dissoudre le groupe" (`DestructiveButton` isolé de
/// `group_management_sheet.dart`) — calque EXACT de
/// `features/profile/presentation/widgets/delete_account_sheet.dart` (un
/// seul widget à 2 étapes internes : avertissement, puis confirmation),
/// avec une confirmation par retape du NOM DU GROUPE (comparaison
/// insensible casse/espaces) plutôt qu'un mot de passe — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.
///
/// Gère elle-même toute la séquence "confirmer -> dissoudre -> naviguer" :
/// contrairement à `showGroupRenameSheet`, il n'y a rien à faire après coup
/// côté appelant (succès -> `context.go('/')` + `SnackBar('Groupe
/// dissous.')`, directement depuis cette sheet).
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

const String _warningMessage =
    'Cette action est irréversible. Elle supprimera définitivement le '
    'groupe, son butin commun et l\'accès de tous ses membres — leurs '
    'personnages gardent toutes leurs données.\n\n'
    'Cette action ne peut pas être annulée.';

const String _genericErrorMessage =
    'Impossible de dissoudre le groupe. Réessayez.';

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
    setState(() {
      _isDissolving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(groupRepositoryProvider).dissolveGroup(widget.groupId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDissolving = false;
        _errorMessage = _genericErrorMessage;
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    context.go('/');
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Groupe dissous.')));
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'DISSOUDRE LE GROUPE',
                  closeEnabled: !_isDissolving,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: switch (_step) {
                      _DissolveStep.warning => const AlertBanner(
                        message: _warningMessage,
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
                            label: 'Annuler',
                            surface: SecondaryButtonSurface.parchment,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DestructiveButton(
                            label: 'Continuer',
                            onPressed: _goToConfirmStep,
                          ),
                        ),
                      ],
                    ),
                    _DissolveStep.confirm => Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Annuler',
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
                                ? 'Dissolution en cours…'
                                : 'Dissoudre définitivement',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          AlertBanner(message: errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          'RETAPE LE NOM DU GROUPE POUR CONFIRMER',
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
          decoration: const InputDecoration(hintText: 'Nom du groupe'),
        ),
      ],
    );
  }
}
