import 'package:freezed_annotation/freezed_annotation.dart';

import 'character_class_feature.dart';
import 'character_detail_class_row.dart';
import 'character_inventory_item.dart';
import 'character_skill_row.dart';
import 'character_spell_entry.dart';
import 'character_spell_slot.dart';
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

    /// Les 18 compétences résolues (nom, caractéristique, maîtrise) —
    /// onglet "Compétences", carte "LES 18 COMPÉTENCES". Liste vide tant
    /// qu'aucune compétence de référence n'a pu être résolue (ne devrait
    /// arriver que pour un stack de contenu vide).
    @Default(<CharacterSkillRow>[]) List<CharacterSkillRow> skills,

    /// Aptitudes de classe déjà atteintes par le niveau actuel du
    /// personnage — onglet "Compétences", carte "APTITUDES DE CLASSE". Voir
    /// la documentation de classe de [CharacterClassFeature] pour la portée
    /// (aptitudes de sous-classe jamais incluses à cette itération).
    @Default(<CharacterClassFeature>[])
    List<CharacterClassFeature> classFeatures,

    /// Noms des outils dont le personnage est compétent (texte libre inclus)
    /// — onglet "Compétences", carte "MAÎTRISES D'OUTILS".
    @Default(<String>[]) List<String> toolProficiencyNames,

    /// Noms des langues connues — onglet "Compétences", carte "LANGUES
    /// CONNUES".
    @Default(<String>[]) List<String> knownLanguageNames,

    /// Sorts connus/préparés du personnage — onglet "Compétences", section
    /// "SORTS". Liste vide pour un personnage qui ne lance pas de sorts (pas
    /// de distinction stockée entre "classe non lanceuse" et "lanceuse sans
    /// sort encore choisi" : les deux cas affichent simplement une section
    /// absente, voir `presentation/widgets/character_skills_tab_body.dart`).
    @Default(<CharacterSpellEntry>[]) List<CharacterSpellEntry> spells,

    /// Emplacements de sorts par niveau (1 à 9) — onglet "Compétences",
    /// section "SORTS".
    @Default(<CharacterSpellSlot>[]) List<CharacterSpellSlot> spellSlots,

    /// Monnaie du personnage (`characters.currency_gp/pp/ep/sp/cp`) — onglet
    /// "Inventaire", rangée de stat boxes (voir
    /// `domain/inventory_stat_boxes_resolver.dart`). `@Default(0)` comme les
    /// autres champs ajoutés après la première version de ce modèle
    /// (`skills`/`classFeatures`/...) : évite de devoir toucher tous les
    /// sites de construction directe de [CharacterDetail] déjà existants
    /// dans les tests (voir la même remarque sur ces champs ci-dessus).
    @Default(0) int currencyGp,
    @Default(0) int currencyPp,
    @Default(0) int currencyEp,
    @Default(0) int currencySp,
    @Default(0) int currencyCp,

    /// Inventaire résolu du personnage — onglet "Inventaire", liste de
    /// cartes. Comme [skills]/[classFeatures]/..., a besoin d'une requête
    /// PostgREST séparée (résolution des noms d'objets du catalogue via
    /// `translations`), voir `SupabaseCharacterRepository._fetchInventory`.
    @Default(<CharacterInventoryItem>[]) List<CharacterInventoryItem> inventory,
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
