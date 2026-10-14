import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/weapon_slot.dart';

/// Feuille « CHOISIR UN SET » — liste fixe des deux [WeaponSlot] (jamais de
/// recherche, contrairement à `pact_weapon_picker_sheet.dart`, prévu pour
/// une longue liste). Un tap ferme la feuille et retourne le set choisi ;
/// fermer sans choisir renvoie `null`.
///
/// Aucune écriture ici : l'appelant calcule le déséquipement automatique
/// éventuel puis fait l'écriture (voir
/// `character_detail_screen.dart::_equipWeaponToSlot`,
/// `domain/weapon_slot_rules.dart::WeaponSlotRules.itemsToAutoUnequip`).
Future<WeaponSlot?> showWeaponSlotPickerSheet(
  BuildContext context, {
  required List<CharacterInventoryItem> equippedWeapons,
  required String currentItemId,
}) {
  return showModalBottomSheet<WeaponSlot>(
    context: context,
    backgroundColor: AppColors.parchmentBg,
    builder: (sheetContext) => _WeaponSlotPickerContent(
      equippedWeapons: equippedWeapons,
      currentItemId: currentItemId,
    ),
  );
}

class _WeaponSlotPickerContent extends StatelessWidget {
  const _WeaponSlotPickerContent({
    required this.equippedWeapons,
    required this.currentItemId,
  });

  final List<CharacterInventoryItem> equippedWeapons;
  final String currentItemId;

  String _occupantsLabel(WeaponSlot slot) {
    final names = [
      for (final weapon in equippedWeapons)
        if (weapon.weaponSlot == slot && weapon.id != currentItemId)
          weapon.name,
    ];
    return names.isEmpty ? 'Vide' : names.join(', ');
  }

  IconData _iconFor(WeaponSlot slot) => switch (slot) {
    WeaponSlot.principal => Icons.looks_one_outlined,
    WeaponSlot.secondary => Icons.looks_two_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        // Plafonne la hauteur de la sheet pour le contenu long (texte
        // agrandi, voir `10-design-system.md` section 7) : au-delà, c'est la
        // zone défilante ajoutée ci-dessous qui absorbe le débordement
        // plutôt que l'écran.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeaderBar(title: 'CHOISIR UN SET'),
              Flexible(
                // `SingleChildScrollView` n'a pas de paramètre `shrinkWrap`
                // (contrairement à `ListView`) : il n'en a pas besoin — avec
                // les contraintes lâches que lui donne ce `Flexible`, il
                // épouse déjà la hauteur de son contenu (`constraints
                // .constrain(child.size)`), et ne défile que si le contenu
                // dépasse l'espace laissé par le `ConstrainedBox` ci-dessus.
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final slot in WeaponSlot.values) ...[
                        SheetActionRow(
                          icon: _iconFor(slot),
                          label: slot.label,
                          trailingText: _occupantsLabel(slot),
                          onTap: () => Navigator.of(context).pop(slot),
                        ),
                        if (slot != WeaponSlot.values.last)
                          const SheetActionDivider(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
