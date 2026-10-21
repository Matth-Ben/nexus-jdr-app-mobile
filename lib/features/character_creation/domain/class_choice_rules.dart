/// Choix nommé de classe fait dès le NIVEAU 1 (pas lors d'une montée de
/// niveau ultérieure), couvert par `presentation/class_choice_step_screen.dart`
/// — correctif D99 (`docs/dette-technique.md`) : un personnage créé
/// directement dans une classe de départ avec ce choix de niveau 1 ne se le
/// voyait jamais proposer à la création, seul le multiclassage tardif via
/// l'écran de montée de niveau le proposait (`LevelUpChoiceKind`).
///
/// Périmètre exact, vérifié en base (ne pas étendre sans revérifier) :
/// - Guerrier (`classes.id = 5`) : [fightingStyle] (`class_features.id = 15`).
/// - Rôdeur (`classes.id = 8`) : [favoredEnemy] (`class_features.id = 28`).
///
/// Le Roublard (`classes.id = 9`, `expertise`) a son propre point
/// d'insertion (après l'étape 5/9 "Compétences et outils", pas juste après
/// la classe) — voir `domain/expertise_step_selection.dart`, [kindFor] ne le
/// couvre donc PAS : [ClassChoiceKind.expertise] est utilisé par
/// `ClassChoiceStepScreen` mais sa pertinence est déterminée directement par
/// `SkillsAndToolsStepScreen`, pas par [kindFor]/[isConcerned] (qui
/// répondraient à tort "non concerné" pour le Roublard, cette classe n'ayant
/// pas de second choix propre déclenché juste après `ClassStepScreen`).
enum ClassChoiceKind { fightingStyle, favoredEnemy, expertise }

abstract final class ClassChoiceRules {
  /// `classes.id` -> [ClassChoiceKind], uniquement pour les classes dont le
  /// choix tombe juste après `ClassStepScreen` (Guerrier/Rôdeur). Le
  /// Roublard (`expertise`) n'y figure pas volontairement, voir la doc de
  /// classe.
  static const Map<int, ClassChoiceKind> _kindByClassId = {
    5: ClassChoiceKind.fightingStyle,
    8: ClassChoiceKind.favoredEnemy,
  };

  static ClassChoiceKind? kindFor(int classId) => _kindByClassId[classId];

  /// `true` si [classId] a un choix nommé à proposer juste après le choix de
  /// classe (`ClassStepScreen._submit`) — Guerrier/Rôdeur uniquement, voir la
  /// doc de classe pour le cas particulier du Roublard.
  static bool isConcerned(int classId) => kindFor(classId) != null;

  /// `class_features.choice_type` correspondant, pour résoudre la ligne
  /// `class_features` de niveau 1 au moment de `createCharacter` (voir
  /// `data/character_creation_repository.dart`).
  static String choiceTypeFor(ClassChoiceKind kind) => switch (kind) {
    ClassChoiceKind.fightingStyle => 'style_combat',
    ClassChoiceKind.favoredEnemy => 'ennemi_jure',
    ClassChoiceKind.expertise => 'expertise',
  };

  /// Titre de l'écran/de l'aide, ex. "Style de combat".
  static String titleFor(ClassChoiceKind kind) => switch (kind) {
    ClassChoiceKind.fightingStyle => 'Style de combat',
    ClassChoiceKind.favoredEnemy => 'Ennemi juré',
    ClassChoiceKind.expertise => 'Expertise',
  };

  /// Texte annoncé aux lecteurs d'écran quand les options apparaissent.
  static String announcementFor(ClassChoiceKind kind) => switch (kind) {
    ClassChoiceKind.fightingStyle => 'Choisis un style de combat.',
    ClassChoiceKind.favoredEnemy => 'Choisis un ennemi juré.',
    ClassChoiceKind.expertise => 'Choisis 2 compétences maîtrisées.',
  };
}
