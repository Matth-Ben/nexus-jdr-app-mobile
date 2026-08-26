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
  });

  /// Identifiant de la classe (`classes.id`, entier côté Supabase, gardé en
  /// [Object] pour ne pas figer un type précis dans la couche domaine — même
  /// convention que [CharacterClassRow.classId]).
  final Object classId;

  /// Nom de classe déjà traduit (`translations`, locale FR), ou un libellé
  /// générique ("Classe #12") si la traduction n'a pas pu être résolue.
  final String className;

  final int level;

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
