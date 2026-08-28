/// Traduit `class_features.choice_type` (ex. `style_combat`, `ennemi_jure`,
/// `invocation`, `sort_domaine`, `sous_classe`...) en libellé français
/// affichable sur l'écran de blocage de la montée de niveau
/// (`presentation/level_up_screen.dart`, voir `domain/level_up_block_reason.dart`).
///
/// `02-modele-donnees.md` ne documente qu'une liste d'exemples pour
/// `choice_type` ("... — permet de savoir qu'un choix du joueur est
/// attendu à ce niveau"), pas une énumération exhaustive : [labelFor] couvre
/// donc les valeurs connues explicitement, et retombe sur une humanisation
/// générique de la clé brute (`snake_case` -> "Snake case") pour toute
/// valeur non répertoriée plutôt que d'afficher la clé technique telle
/// quelle au joueur.
abstract final class ClassFeatureChoiceLabelFormatter {
  // `sous_classe`/`style_combat`/`ennemi_jure` sont mortes dans ce contexte
  // depuis l'increment 2 de la montée de niveau : `LevelUpBlockRules.evaluate`
  // ne bloque plus jamais pour ces 3 valeurs (`resolvedChoiceTypes`), elles
  // mènent à l'étape "Choix à faire" à la place (voir
  // `domain/level_up_choice_kind.dart`). Gardées ici quand même (plutôt que
  // supprimées) : label toujours correct si jamais réutilisé ailleurs, et
  // évite de retomber sur l'humanisation générique ("Sous Classe") en cas de
  // régression future sur `resolvedChoiceTypes`.
  static const Map<String, String> _labels = {
    'sous_classe': 'Sous-classe à choisir',
    'style_combat': 'Style de combat',
    'ennemi_jure': 'Ennemi juré',
    'invocation': 'Invocation occulte',
    'sort_domaine': 'Sort de domaine',
  };

  static String labelFor(String choiceType) {
    final known = _labels[choiceType];
    if (known != null) return known;

    final words = choiceType
        .split('_')
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'Choix à faire';
    final humanized = words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    return humanized;
  }
}
