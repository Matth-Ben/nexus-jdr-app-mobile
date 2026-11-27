import 'package:flutter/material.dart';

import '../../features/characters/domain/currency_kind.dart';
import '../theme/app_spacing.dart';

/// Sélecteur de devise à choix exclusif parmi les 5 [CurrencyKind] — extrait
/// du motif `_chips` de `currency_conversion_sheet.dart` (spec du prix d'un
/// objet modifiable, §0/§2) pour un 3ᵉ usage (prix d'un objet, personnalisé
/// ou surcharge d'un objet du catalogue) sans le dupliquer une 3ᵉ fois.
///
/// Contrairement aux chips de `currency_conversion_sheet.dart`, aucun solde
/// n'est affiché (`· {solde}`, pas pertinent pour un prix) : le libellé est
/// toujours la seule abréviation ([CurrencyKind.unitLabel]).
///
/// Même habillage : `ChoiceChip` à zone de tap >= 44 px
/// (`MaterialTapTargetSize.padded`), un seul choix sélectionné à la fois.
class CurrencyPickerChips extends StatelessWidget {
  const CurrencyPickerChips({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Devise sélectionnée.
  final CurrencyKind value;

  final ValueChanged<CurrencyKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final currency in CurrencyKind.values)
          ChoiceChip(
            // Cible tactile >= 44 px (le chip Material fait 32 px par défaut).
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm + 2,
            ),
            label: Text(currency.unitLabel),
            selected: currency == value,
            onSelected: (_) => onChanged(currency),
          ),
      ],
    );
  }
}
