/// Ligne `character_classes` minimale (multiclassage, `02-modele-donnees.md`)
/// nécessaire aux calculs de `CharacterClassesSummary` — extraite en petit
/// modèle immuable pour que ces calculs restent testables indépendamment du
/// format brut renvoyé par Supabase (`data/character_repository.dart`).
class CharacterClassRow {
  const CharacterClassRow({
    required this.classId,
    required this.level,
    required this.isPrimary,
  });

  /// Identifiant de la classe (`classes.id`, entier côté Supabase, gardé en
  /// [Object] ici pour ne pas figer un type précis dans la couche domaine).
  final Object classId;

  /// Niveau du personnage dans cette classe.
  final int level;

  /// Vrai pour la classe de départ (`character_classes.is_primary`).
  final bool isPrimary;
}

/// Calculs purs liés au multiclassage, extraits de
/// `data/character_repository.dart` pour rester testables sans dépendance à
/// Supabase.
abstract final class CharacterClassesSummary {
  /// Niveau total d'un personnage : somme du niveau de chacune de ses
  /// classes (un personnage Guerrier 3 / Magicien 2 est niveau 5).
  static int totalLevel(List<CharacterClassRow> classes) {
    return classes.fold(0, (sum, classRow) => sum + classRow.level);
  }

  /// Identifiant de la classe "principale" à afficher en résumé : celle
  /// marquée `is_primary`, ou la première de la liste si aucune ne l'est
  /// (donnée incohérente, ne devrait normalement pas arriver). Retourne
  /// `null` si [classes] est vide (personnage sans classe enregistrée).
  static Object? primaryClassId(List<CharacterClassRow> classes) {
    if (classes.isEmpty) {
      return null;
    }
    for (final classRow in classes) {
      if (classRow.isPrimary) {
        return classRow.classId;
      }
    }
    return classes.first.classId;
  }
}
