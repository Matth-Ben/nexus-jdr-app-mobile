import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/group_failure.dart';
import '../providers/group_providers.dart';

/// Ouvre la sheet "Renommer le groupe" (`MenuTile` "Renommer le groupe" de
/// `group_management_sheet.dart`) — calque exact de
/// `features/profile/presentation/widgets/edit_display_name_sheet.dart`
/// (voir sa documentation de classe pour le rationale complet du pattern
/// "attend le résultat réseau sur place"), champ "NOM DU GROUPE" plutôt que
/// "NOM D'AFFICHAGE". Écrit directement `UPDATE groups` (RLS "Owner can
/// update their groups" déjà en place côté serveur, pas d'edge function),
/// puis invalide `groupDetailProvider(groupId)` avant de se refermer — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.
Future<void> showGroupRenameSheet(
  BuildContext context, {
  required String groupId,
  required String currentName,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) =>
        _GroupRenameSheetContent(groupId: groupId, currentName: currentName),
  );
  if (saved != true || !context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Groupe renommé.')));
}

const String _genericErrorMessage =
    "Impossible d'enregistrer les modifications. Réessayez.";

class _GroupRenameSheetContent extends ConsumerStatefulWidget {
  const _GroupRenameSheetContent({
    required this.groupId,
    required this.currentName,
  });

  final String groupId;
  final String currentName;

  @override
  ConsumerState<_GroupRenameSheetContent> createState() =>
      _GroupRenameSheetContentState();
}

class _GroupRenameSheetContentState
    extends ConsumerState<_GroupRenameSheetContent> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentName,
  );
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isSaving) return;

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
      Navigator.of(context).pop(true);
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.parchmentBg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHeaderBar(
                  title: 'RENOMMER LE GROUPE',
                  closeEnabled: !_isSaving,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        AlertBanner(message: _errorMessage!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        'NOM DU GROUPE',
                        style: AppTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _controller,
                        enabled: !_isSaving,
                        minLines: 1,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Ex. Les Lames de l\'Aube',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Annuler',
                          surface: SecondaryButtonSurface.parchment,
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Enregistrer',
                          isLoading: _isSaving,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
