import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/inventory_category_filter.dart';

/// Ouvre la sheet "Filtrer par catégorie" de l'onglet "Inventaire" —
/// remplace la bascule segmentée à 5 segments ("Tout"/"Armes"/"Armures"/
/// "Consomm."/"Divers", `core/widgets/segmented_toggle.dart`) qui cassait le
/// texte de ses libellés sur petit écran (5 segments de largeur égale,
/// aucune limite de longueur de libellé côté composant partagé). Choix
/// exclusif : chaque tap ferme directement la sheet avec la valeur
/// sélectionnée (pas de bouton "Appliquer" séparé, contrairement à
/// `character_class_filter_sheet.dart` qui est à choix multiple), même
/// principe qu'un menu de sélection.
///
/// Retourne le nouveau filtre choisi, ou `null` si la sheet est fermée sans
/// choix (croix, tap en dehors) — l'appelant ne doit alors rien changer à
/// son filtre actuel.
Future<InventoryCategoryFilter?> showInventoryCategoryFilterSheet(
  BuildContext context, {
  required InventoryCategoryFilter current,
}) {
  return showModalBottomSheet<InventoryCategoryFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _InventoryCategoryFilterSheetContent(current: current),
  );
}

class _InventoryCategoryFilterSheetContent extends StatelessWidget {
  const _InventoryCategoryFilterSheetContent({required this.current});

  final InventoryCategoryFilter current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeaderBar(title: 'FILTRER PAR CATÉGORIE'),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  for (final option in InventoryCategoryFilter.values) ...[
                    SelectableOptionTile(
                      title: option.label,
                      selected: option == current,
                      onTap: () => Navigator.of(context).pop(option),
                    ),
                    if (option != InventoryCategoryFilter.values.last)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
