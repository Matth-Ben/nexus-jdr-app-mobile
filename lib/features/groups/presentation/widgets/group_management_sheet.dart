import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/menu_tile.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/group_detail.dart';
import 'group_dissolve_sheet.dart';
import 'group_rename_sheet.dart';

/// Callback "Régénérer le code" — la confirmation
/// (`showGroupConfirmationDialog`) et l'appel réseau
/// (`GroupRepository.regenerateInviteCode`) restent orchestrés par
/// l'appelant (`group_screen.dart`), qui a déjà besoin de `WidgetRef` pour
/// invalider `groupDetailProvider` — cette sheet ne fait que relayer le tap.
typedef RegenerateInviteCodeCallback = void Function();

/// Sheet "GESTION DU GROUPE" (owner uniquement) — `trailing`
/// `Icons.settings_outlined` du `WoodBackHeader` de l'écran "Groupe", voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2 :
/// "Renommer le groupe" (sous-sheet [showGroupRenameSheet]), "Régénérer le
/// code" ([onRegenerateCode]), puis un séparateur et un
/// `DestructiveButton("Dissoudre le groupe")` isolé (sous-sheet
/// [showGroupDissolveSheet]).
Future<void> showGroupManagementSheet(
  BuildContext context, {
  required GroupDetail detail,
  required RegenerateInviteCodeCallback onRegenerateCode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _GroupManagementSheetContent(
      detail: detail,
      onRegenerateCode: onRegenerateCode,
    ),
  );
}

class _GroupManagementSheetContent extends StatelessWidget {
  const _GroupManagementSheetContent({
    required this.detail,
    required this.onRegenerateCode,
  });

  final GroupDetail detail;
  final RegenerateInviteCodeCallback onRegenerateCode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeaderBar(title: 'GESTION DU GROUPE'),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  MenuTile(
                    icon: Icons.edit_outlined,
                    label: 'Renommer le groupe',
                    onTap: () {
                      Navigator.of(context).pop();
                      showGroupRenameSheet(
                        context,
                        groupId: detail.id,
                        currentName: detail.name,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MenuTile(
                    icon: Icons.autorenew,
                    label: 'Régénérer le code',
                    onTap: () {
                      Navigator.of(context).pop();
                      onRegenerateCode();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.woodLight, thickness: 1),
                  const SizedBox(height: AppSpacing.lg),
                  DestructiveButton(
                    label: 'Dissoudre le groupe',
                    onPressed: () {
                      Navigator.of(context).pop();
                      showGroupDissolveSheet(
                        context,
                        groupId: detail.id,
                        groupName: detail.name,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
