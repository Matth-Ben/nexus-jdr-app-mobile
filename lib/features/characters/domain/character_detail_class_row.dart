/// Ligne `character_classes` résolue pour la fiche personnage (onglet
/// "Personnage", `presentation/character_detail_screen.dart`) : contrairement
/// à [CharacterClassRow] (`character_class_row.dart`, utilisé par la liste
/// des personnages), porte le nom de classe déjà traduit et les maîtrises de
/// jets de sauvegarde de la classe (`classes.saving_throw_proficiencies`,
/// embarquées via la relation `character_classes.class_id -> classes.id`,
/// une vraie FK — pas la table polymorphe `translations`).
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [CharacterClassRow], aucune égalité structurelle fine n'est nécessaire
/// ici (donnée en lecture seule affichée telle quelle).
class CharacterDetailClassRow {
  const CharacterDetailClassRow({
    required this.classId,
    required this.className,
    required this.level,
    required this.isPrimary,
    required this.savingThrowProficiencies,
    required this.hitDie,
    this.hitDiceSpent = 0,
  });

  /// Identifiant de la classe (`classes.id`, entier côté Supabase, gardé en
  /// [Object] pour ne pas figer un type précis dans la couche domaine — même
  /// convention que [CharacterClassRow.classId]).
  final Object classId;

  /// Nom de classe déjà traduit (`translations`, locale FR), ou un libellé
  /// générique ("Classe #12") si la traduction n'a pas pu être résolue.
  final String className;

  final int level;

  /// `classes.hit_die` (6/8/10/12), embarqué via la même relation de clé
  /// étrangère que [savingThrowProficiencies] — ajouté pour l'étape "Points
  /// de vie" de la montée de niveau (`domain/level_up_hit_points_calculator.dart`),
  /// qui a besoin du dé de vie de la classe pour proposer un lancer/une
  /// valeur moyenne. Comme [savingThrowProficiencies], seule pertinente pour
  /// la classe [isPrimary] à cette itération (pas de montée de niveau
  /// multiclassée gérée, voir `data/character_repository.dart::applyLevelUp`).
  ///
  /// Volontairement `null` (plutôt qu'un repli silencieux sur une valeur par
  /// défaut) si `hit_die` est absent en base : contrairement aux autres
  /// champs de cette classe (purement affichés), celui-ci alimente une
  /// écriture irréversible (`CharacterRepository.applyLevelUp`,
  /// `characters.max_hp`/`character_level_hp`) — un défaut silencieux
  /// produirait un gain de PV faux et indétectable. Le flux de montée de
  /// niveau (`presentation/providers/level_up_provider.dart`) doit lever une
  /// [CharacterFailure] explicite plutôt que de démarrer avec cette valeur
  /// absente. Revue de code du 2026-08-28 : cohérence volontaire avec
  /// `character_creation/data/class_row_mapper.dart`, qui plante plutôt que
  /// deviner pour cette même colonne.
  final int? hitDie;

  /// `character_classes.hit_dice_spent` : nombre de dés de vie déjà dépensés
  /// pour cette classe (repos court, voir `domain/rest_type.dart`/
  /// `presentation/widgets/rest_sheet.dart`). Dés de vie disponibles =
  /// [level] - [hitDiceSpent] (le total de dés de vie d'une classe est
  /// toujours égal à son niveau, RAW 5e). Valeur par défaut `0` (plutôt
  /// qu'un champ requis comme [hitDie]) : contrairement à [hitDie], cette
  /// valeur par défaut ne peut jamais produire un calcul faux et indétectable
  /// (au pire, une fiche déjà ancienne sans cette colonne resynchronisée
  /// affiche "tous les dés disponibles", un état sûr) — ne nécessite donc
  /// pas de faire planter tous les sites de construction directe déjà
  /// existants (tests) comme la migration au null-safety de [hitDie] l'a
  /// exigé en son temps.
  final int hitDiceSpent;

  /// Vrai pour la classe de départ (`character_classes.is_primary`).
  final bool isPrimary;

  /// Clés de caractéristiques ('str'/'dex'/'con'/'int'/'wis'/'cha') pour
  /// lesquelles cette classe accorde une maîtrise de jet de sauvegarde
  /// (`classes.saving_throw_proficiencies`). Seule pertinente pour la classe
  /// [isPrimary] : en 5e RAW, le multiclassage n'ajoute jamais de nouvelle
  /// maîtrise de jet de sauvegarde — voir
  /// `domain/saving_throw_calculator.dart` et la spec de la tâche qui a
  /// tranché ce point.
  final List<String> savingThrowProficiencies;
}
