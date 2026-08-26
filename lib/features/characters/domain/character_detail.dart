import 'package:freezed_annotation/freezed_annotation.dart';

import 'character_detail_class_row.dart';
import 'xp_table.dart';

part 'character_detail.freezed.dart';

/// Modèle complet d'un personnage tel qu'affiché par la fiche personnage
/// (`presentation/character_detail_screen.dart`, onglet "Personnage").
///
/// Plus riche que [CharacterSummary] (`character_summary.dart`, réservé à la
/// carte de la liste d'accueil) : porte notamment les scores de
/// caractéristiques, les PV/PV temporaires, et les maîtrises de jets de
/// sauvegarde de la classe principale.
@freezed
abstract class CharacterDetail with _$CharacterDetail {
  const CharacterDetail._();

  const factory CharacterDetail({
    required String id,
    required String name,

    /// URL publique du portrait (`characters.portrait_url`), `null` si le
    /// joueur n'en a pas encore défini un.
    String? portraitUrl,

    /// Nom de race traduit, `null` si non résolu (race personnalisée ou
    /// `race_id` nul).
    String? raceName,

    /// Nom de sous-race traduit, `null` si le personnage n'a pas de
    /// sous-race.
    String? subraceName,

    /// Texte libre de race personnalisée (`characters.race_custom_text`),
    /// `null` si le personnage a une race du catalogue.
    String? raceCustomText,

    /// Nom d'historique traduit, `null` si `background_id` est nul.
    String? backgroundName,

    /// Nom d'alignement traduit, `null` si `alignment_id` est nul.
    String? alignmentName,

    /// Toutes les lignes `character_classes` du personnage (multiclassage
    /// inclus), dans l'ordre renvoyé par PostgREST.
    required List<CharacterDetailClassRow> classes,

    required int xp,
    required int currentHp,
    required int maxHp,
    required int temporaryHp,

    /// Scores finaux par caractéristique (`character_ability_scores`), clé
    /// 'str'/'dex'/'con'/'int'/'wis'/'cha' — déjà le score final en base,
    /// aucun bonus racial à recalculer ici (voir
    /// `character_creation/domain/final_ability_scores_resolver.dart` pour
    /// l'endroit où ce calcul a déjà eu lieu, à la création).
    required Map<String, int> abilityScores,
  }) = _CharacterDetail;

  /// Niveau total, somme de `character_classes.level` sur toutes les lignes
  /// (multiclassage) — même règle que [CharacterClassesSummary.totalLevel]
  /// (`character_class_row.dart`), dupliquée ici pour opérer directement sur
  /// [CharacterDetailClassRow] plutôt que sur [CharacterClassRow].
  int get totalLevel => classes.fold(0, (sum, row) => sum + row.level);

  /// Classe "principale" : celle marquée `is_primary`, ou la première de la
  /// liste à défaut (donnée incohérente, ne devrait normalement pas
  /// arriver). `null` si le personnage n'a aucune classe enregistrée.
  CharacterDetailClassRow? get primaryClass {
    if (classes.isEmpty) return null;
    for (final row in classes) {
      if (row.isPrimary) return row;
    }
    return classes.first;
  }

  /// Maîtrises de jets de sauvegarde de la classe principale uniquement —
  /// voir [CharacterDetailClassRow.savingThrowProficiencies].
  Set<String> get primarySavingThrowProficiencies =>
      primaryClass?.savingThrowProficiencies.toSet() ?? const {};

  /// XP cumulée requise pour le niveau suivant, `null` au niveau maximum —
  /// même formule que [CharacterSummary.nextLevelXpThreshold], sur
  /// [totalLevel] plutôt que sur un niveau déjà agrégé côté dépôt.
  int? get nextLevelXpThreshold =>
      XpTable.cumulativeXpForNextLevel(totalLevel > 0 ? totalLevel : 1);

  /// Ratio de remplissage de la jauge XP, entre 0 et 1 — même formule que
  /// [CharacterSummary.xpProgress].
  double get xpProgress {
    final level = totalLevel > 0 ? totalLevel : 1;
    final nextThreshold = nextLevelXpThreshold;
    if (nextThreshold == null) {
      return 1;
    }
    final currentThreshold = XpTable.cumulativeXpForLevel(level);
    final span = nextThreshold - currentThreshold;
    if (span <= 0) {
      return 1;
    }
    return ((xp - currentThreshold) / span).clamp(0, 1).toDouble();
  }

  /// Ratio de remplissage de la jauge PV, entre 0 et 1. Les PV temporaires
  /// sont volontairement exclus de ce ratio (spec de la fiche personnage) :
  /// seul `current_hp / max_hp` compte pour la couleur/le remplissage de la
  /// jauge.
  double get hpRatio {
    if (maxHp <= 0) return 0;
    return (currentHp / maxHp).clamp(0, 1).toDouble();
  }
}
