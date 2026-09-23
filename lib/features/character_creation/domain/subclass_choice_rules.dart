/// Règles pures du choix de sous-classe à la création (étape 2/9).
abstract final class SubclassChoiceRules {
  /// Libellé de repli pour une classe sans libellé propre.
  static const String fallbackTitle = 'Sous-classe';

  static const Map<String, String> _titleByClassName = {
    'Clerc': 'Domaine divin',
    'Occultiste': 'Patron protecteur',
    'Ensorceleur': 'Origine magique',
  };

  /// Libellé propre à la classe (« Domaine divin », « Patron protecteur »,
  /// « Origine magique »), [fallbackTitle] sinon. Seul l'AFFICHAGE dépend du
  /// nom : quelles classes choisissent une sous-classe vient des données.
  static String titleFor(String className) =>
      _titleByClassName[className] ?? fallbackTitle;

  /// Texte annoncé aux lecteurs d'écran quand le bloc apparaît.
  static String announcementFor(String className) {
    final title = titleFor(className);
    // « sous-classe » est féminin, les libellés propres sont masculins.
    return title == fallbackTitle
        ? 'Choisis ta sous-classe.'
        : 'Choisis ton ${title.toLowerCase()}.';
  }
}
