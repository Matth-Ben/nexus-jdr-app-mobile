/// Résultat de [SpellComponentsFormatter.format] — séparé en deux morceaux
/// (plutôt qu'une simple chaîne) pour que l'affichage
/// (`presentation/widgets/spell_info_panel.dart`) puisse rendre
/// [materialDescriptionSuffix] dans une couleur atténuée (`textMuted`,
/// spec visuelle) distincte de [label] (`textPrimary`).
class SpellComponentsFormatted {
  const SpellComponentsFormatted({
    required this.label,
    this.materialDescriptionSuffix,
  });

  /// "V", "V, S", "Aucune"... — toujours non vide.
  final String label;

  /// " — {material_desc}", `null` si le composant matériel est absent ou
  /// sans description renseignée. Inclut déjà le séparateur " — " en tête.
  final String? materialDescriptionSuffix;
}

/// Met en forme `spells.components` (jsonb `{verbal, somatic, material,
/// material_desc}`, voir [CharacterSpellEntry.components]) pour la ligne
/// "Composantes" du panneau "Infos" d'un sort
/// (`presentation/widgets/spell_info_panel.dart`).
abstract final class SpellComponentsFormatter {
  /// "V, S, M" (composantes présentes séparées par ", ") avec, si le
  /// composant matériel est présent et que `material_desc` est renseigné, un
  /// suffixe " — {material_desc}" distinct (voir [SpellComponentsFormatted])
  /// ; "Aucune" (sans suffixe) si aucune composante n'est renseignée.
  static SpellComponentsFormatted format(Map<String, dynamic> components) {
    final letters = <String>[
      if (components['verbal'] == true) 'V',
      if (components['somatic'] == true) 'S',
      if (components['material'] == true) 'M',
    ];
    if (letters.isEmpty) {
      return const SpellComponentsFormatted(label: 'Aucune');
    }

    final label = letters.join(', ');
    if (components['material'] != true) {
      return SpellComponentsFormatted(label: label);
    }

    final materialDesc = components['material_desc'];
    if (materialDesc is! String || materialDesc.trim().isEmpty) {
      return SpellComponentsFormatted(label: label);
    }

    return SpellComponentsFormatted(
      label: label,
      materialDescriptionSuffix: ' — ${materialDesc.trim()}',
    );
  }
}
