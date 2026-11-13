import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/destructive_menu_tile.dart';
import '../../../../core/widgets/menu_tile.dart';
import '../../../../core/widgets/sheet_header_bar.dart';

/// Entrée d'un menu d'actions du combat (menu d'en-tête ou de ligne).
class CombatMenuEntry {
  const CombatMenuEntry({
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// `true` : `DestructiveMenuTile` (texte brick).
  final bool destructive;
}

/// Menu d'actions en feuille basse (une entrée destructive = tuile brick).
/// L'action est lancée **après** la fermeture de la feuille.
Future<void> showCombatActionMenu(
  BuildContext context, {
  required String title,
  required List<CombatMenuEntry> entries,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.parchmentBg,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeaderBar(title: title),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in entries) ...[
                    if (entry.destructive)
                      DestructiveMenuTile(
                        label: entry.label,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          entry.onTap();
                        },
                      )
                    else
                      MenuTile(
                        icon: entry.icon ?? Icons.chevron_right,
                        label: entry.label,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          entry.onTap();
                        },
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
