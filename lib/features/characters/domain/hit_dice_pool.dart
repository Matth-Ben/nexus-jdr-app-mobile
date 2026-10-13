import 'character_detail_class_row.dart';

/// Un « pool » de dés de vie, càd le suivi (type de dé, total, dépensés)
/// d'UNE ligne `character_classes` — voir `data/character_repository.dart`
/// (`applyRest`/`applyRestOnline`) et `presentation/widgets/rest_sheet.dart`.
///
/// Décision chef de projet du 10/10/2026 (dette D-dés de vie
/// multiclassés) : le suivi reste **par ligne de classe**, jamais fusionné
/// par taille de dé à travers plusieurs classes qui partageraient le même
/// type (ex. Clerc d8 / Roublard d8) — RAW 5e autoriserait cette fusion
/// ("Note seulement le nombre de dés si deux classes ont le même dé"), mais
/// le schéma de ce dépôt suit déjà `character_classes.hit_dice_spent` par
/// ligne, et une fusion aurait exigé une nouvelle colonne/table sans
/// bénéfice pratique pour la quasi-totalité des combinaisons de classes
/// (dés de tailles différentes). Écart RAW assumé et documenté plutôt que
/// silencieux, limité aux rares combinaisons de classes au même dé.
class HitDicePool {
  const HitDicePool({
    required this.classId,
    required this.className,
    required this.hitDie,
    required this.total,
    required this.spent,
  });

  /// `character_classes.class_id` — identifie ce pool de façon stable d'un
  /// repos à l'autre (même convention que [CharacterDetailClassRow.classId]).
  final Object classId;

  /// Nom de classe déjà traduit, pour l'affichage ("Dés de vie — Magicien").
  final String className;

  /// Taille du dé de vie de cette classe (6/8/10/12).
  final int hitDie;

  /// Nombre total de dés de vie de CETTE classe = son niveau (RAW 5e : un
  /// dé de vie par niveau de classe).
  final int total;

  /// `character_classes.hit_dice_spent` pour cette classe.
  final int spent;

  /// Dés de vie encore disponibles pour cette classe — jamais négatif, ni
  /// supérieur à [total] (même garde-fou défensif que l'ancien
  /// `_remainingHitDice` de `rest_sheet.dart`, généralisé à un pool par
  /// classe).
  int get available => (total - spent).clamp(0, total);
}

/// Construit la liste des [HitDicePool] d'un personnage à partir de ses
/// [CharacterDetailClassRow] — une entrée par classe dont le dé de vie a pu
/// être résolu. Une classe dont `hitDie` est `null` (gap de données
/// défensif, voir la documentation de
/// [CharacterDetailClassRow.hitDie]) est omise plutôt que de deviner un
/// dé : son niveau compte quand même dans `CharacterDetail.totalLevel` (le
/// nombre de dés RÉCUPÉRÉS au repos long reste RAW-correct), seul le suivi
/// de SES PROPRES dés dépensés/disponibles reste indisponible, comme avant
/// cette fonctionnalité pour toute classe.
abstract final class HitDicePools {
  static List<HitDicePool> fromClasses(List<CharacterDetailClassRow> classes) {
    return [
      for (final row in classes)
        if (row.hitDie != null)
          HitDicePool(
            classId: row.classId,
            className: row.className,
            hitDie: row.hitDie!,
            total: row.level,
            spent: row.hitDiceSpent,
          ),
    ];
  }
}
