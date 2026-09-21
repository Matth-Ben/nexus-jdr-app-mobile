/// Faveur de pacte de l'Occultiste (niveau 3, `class_features.choice_type =
/// 'pacte'`) — les 3 options du *Manuel des Joueurs* 5e.
///
/// [key] est la valeur stockée dans `character_class_options.chosen_value` ET
/// la valeur de `invocations.prerequisites->>'pact'` : les deux doivent rester
/// identiques (contrat avec le backend, dépôt web).
enum WarlockPact {
  chain(
    key: 'chaine',
    label: 'Pacte de la chaîne',
    description:
        'Vous apprenez le sort Appel de familier et pouvez invoquer '
        'un familier amélioré : lutin, pseudodragon, quasit ou sprite.',
  ),
  blade(
    key: 'lame',
    label: 'Pacte de la lame',
    description:
        'Vous pouvez invoquer une arme de pacte dans votre main, ou lier '
        'une arme magique que vous maîtrisez à votre pacte.',
  ),
  tome(
    key: 'grimoire',
    label: 'Pacte du grimoire',
    description:
        'Votre patron vous confie un Livre des ombres : vous apprenez '
        "trois sorts mineurs de n'importe quelle classe.",
  );

  const WarlockPact({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;

  /// Pacte correspondant à [key] (`chaine`/`lame`/`grimoire`), `null` si
  /// [key] est `null` ou inconnu.
  static WarlockPact? fromKey(String? key) {
    if (key == null) return null;
    for (final pact in values) {
      if (pact.key == key) return pact;
    }
    return null;
  }

  /// Libellé lisible de [key] si c'est un pacte connu, [key] tel quel sinon
  /// (les autres `chosen_value` — styles de combat, ennemis jurés — sont déjà
  /// des libellés).
  static String displayLabelFor(String key) => fromKey(key)?.label ?? key;
}
