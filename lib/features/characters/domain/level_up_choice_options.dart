/// Listes codées en dur des options "Style de combat"/"Ennemi juré" de
/// l'étape "Choix à faire" de la montée de niveau (increment 2) — contenu
/// fourni explicitement par le chef de projet, pas de table de référence en
/// base pour ces deux choix (contrairement à `subclasses`).
abstract final class LevelUpChoiceOptions {
  /// Les 6 options standard du *Manuel des Joueurs* 5e. Aucune restriction de
  /// sous-liste par classe n'est appliquée ici : les 6 options sont
  /// proposées à toute classe qui atteint ce choix — simplification assumée
  /// et documentée, même rationale que les classes "à sorts connus" codées
  /// en dur de `character_creation/domain/spellcasting_rules.dart`.
  static const List<String> fightingStyles = [
    'Archerie',
    'Défense',
    'Duel',
    'Combat à deux armes',
    'Combat à deux mains',
    'Protection',
  ];

  /// Types de créatures du *Manuel des Joueurs* 5e, SANS le sous-choix "deux
  /// races humanoïdes" du Rôdeur — même simplification assumée que
  /// [fightingStyles].
  static const List<String> favoredEnemies = [
    'Aberrations',
    'Bêtes',
    'Célestes',
    'Constructions',
    'Dragons',
    'Élémentaires',
    'Fées',
    'Fiélons',
    'Géants',
    'Monstruosités',
    'Plantes',
    'Morts-vivants',
  ];
}
