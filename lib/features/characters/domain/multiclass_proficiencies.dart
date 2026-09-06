/// Maîtrises accordées par le multiclassage RAW 5e (moins qu'un départ
/// normal dans la classe, voir le *Manuel des joueurs*) — affichées UNE FOIS
/// au moment du multiclassage, dans l'étape "Aptitudes" de la montée de
/// niveau (`presentation/level_up_screen.dart`, bloc "Maîtrises de
/// multiclassage", spec direction-artistique section 3).
///
/// **Limite assumée, documentée explicitement (pas un chantier couvert
/// ici)** : ces maîtrises ne sont affichées qu'à ce moment précis (`GainRow`
/// de l'étape "Aptitudes"), jamais persistées ni reflétées ailleurs.
/// Aujourd'hui, aucune fonctionnalité de la fiche personnage n'affiche les
/// maîtrises d'armure/d'armes de façon permanente par classe possédée (à
/// vérifier avant de s'y fier de nouveau si le code évolue) — donc pas de
/// régression à ce jour. Mais si un tel affichage permanent est construit
/// plus tard (ex. à partir de `classes.armor_proficiencies`/
/// `weapon_proficiencies`), il devra distinguer les maîtrises d'un départ
/// normal dans la classe de celles, plus restreintes, du multiclassage —
/// cette limite devra être levée à ce moment-là.
///
/// Données fournies par le chef de projet, autoritaires : encodées telles
/// quelles ci-dessous, non re-vérifiées ici — même convention de clé (nom de
/// classe en français) que `domain/multiclass_prerequisites.dart`.
abstract final class MulticlassProficiencies {
  static const Map<String, List<String>> _proficienciesByClassName = {
    'Barbare': [
      'Maîtrise des boucliers',
      'Maîtrise des armes courantes et de guerre',
    ],
    'Barde': [
      'Maîtrise des armures légères',
      "Maîtrise d'une compétence au choix",
      "Maîtrise d'un instrument de musique au choix",
    ],
    'Clerc': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
    ],
    'Druide': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
    ],
    'Guerrier': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
      'Maîtrise des armes courantes et de guerre',
    ],
    'Moine': ['Maîtrise des armes courantes', 'Maîtrise des épées courtes'],
    'Paladin': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
      'Maîtrise des armes courantes et de guerre',
    ],
    'Rôdeur': [
      'Maîtrise des armures légères et intermédiaires',
      'Maîtrise des boucliers',
      'Maîtrise des armes courantes et de guerre',
      "Maîtrise d'une compétence au choix (liste du Rôdeur)",
    ],
    'Roublard': [
      'Maîtrise des armures légères',
      "Maîtrise d'une compétence au choix (liste du Roublard)",
      "Maîtrise des outils de voleur",
    ],
    // Aucune maîtrise de multiclassage (Ensorceleur/Magicien).
    'Ensorceleur': [],
    'Occultiste': [
      'Maîtrise des armures légères',
      'Maîtrise des armes courantes',
    ],
    'Magicien': [],
  };

  /// Libellés français à afficher tels quels (`GainRow.subtitle`), une entrée
  /// par ligne de maîtrise accordée par le multiclassage dans [className].
  /// Liste vide si [className] est absente de la table (classe sans aucune
  /// maîtrise de multiclassage, ou classe imprévue — traité identiquement,
  /// jamais d'exception).
  static List<String> multiclassProficienciesFor(String className) =>
      _proficienciesByClassName[className] ?? const [];
}
