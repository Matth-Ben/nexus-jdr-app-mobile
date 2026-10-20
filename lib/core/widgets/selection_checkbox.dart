import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Case à cocher 18×18px du design système (`docs/cahier-des-charges/`
/// `10-design-system.md` section 4, "Case à cocher / élément de liste
/// sélectionnable") : bordure 1.5px `wood.light` non cochée ; cochée : fond
/// `gold-end`, bordure `wood.dark`, coche blanche.
///
/// Extrait de [CheckableOptionTile] (`_Checkbox`, son unique usage jusque-là)
/// pour un second usage par `CharacterCard` (mode sélection multiple de
/// `character_list_screen.dart`) — composant partagé plutôt que dupliqué,
/// purement visuel : porter l'état [checked] et l'interaction (zone de tap,
/// `onTap`) reste à la charge de l'appelant.
class SelectionCheckbox extends StatelessWidget {
  const SelectionCheckbox({required this.checked, super.key});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? AppColors.goldEnd : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: checked ? AppColors.woodDark : AppColors.woodLight,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}
