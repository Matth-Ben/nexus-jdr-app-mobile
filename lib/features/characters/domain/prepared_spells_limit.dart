import '../../character_creation/domain/ability_score_rules.dart';
import 'character_detail_class_row.dart';
import 'multiclass_prerequisites.dart';
import 'spellcasting_class_names.dart';

/// Limite de sorts préparés (5e RAW) des classes qui PRÉPARENT leurs sorts :
/// Clerc/Druide (Sagesse + niveau), Magicien (Intelligence + niveau) et
/// Paladin (Charisme + moitié du niveau arrondie à l'inférieur). Minimum 1
/// dans tous les cas.
///
/// Les classes à sorts connus (Barde, Ensorceleur, Occultiste, Rôdeur) et les
/// classes non lanceuses (les sous-classes lanceuses du Guerrier/Roublard ne
/// sont pas modélisées) n'ont pas de limite de préparation : [limitFor]
/// renvoie `null`.
abstract final class PreparedSpellsLimit {
  /// Clé de caractéristique d'incantation ('wis'/'int'/'cha') des classes qui
  /// préparent leurs sorts, `null` pour toute autre classe.
  static String? abilityKeyFor(String className) => switch (className) {
    'Clerc' || 'Druide' => 'wis',
    'Magicien' => 'int',
    'Paladin' => 'cha',
    _ => null,
  };

  /// Vrai si [className] prépare ses sorts.
  static bool preparesSpells(String className) =>
      abilityKeyFor(className) != null;

  /// Vrai si [className] est une classe à sorts connus : elle lance ses
  /// sorts sans les préparer (Barde, Ensorceleur, Occultiste, Rôdeur). Liste
  /// explicite, et non « tout ce qui ne prépare pas » : un nom inconnu
  /// (classe non modélisée comme l'Artificier, repli « Classe #id ») ne doit
  /// jamais rendre un sort lançable sans préparation.
  static bool knowsSpellsWithoutPreparing(String className) =>
      switch (className) {
        'Barde' || 'Ensorceleur' || 'Occultiste' || 'Rôdeur' => true,
        _ => false,
      };

  /// Vrai si [className] est une classe CONNUE qui ne lance aucun sort
  /// (Barbare, Guerrier, Moine, Roublard) : connue de
  /// [MulticlassPrerequisites] (les 12 classes RAW) et absente de
  /// [spellcastingClassNames]. Dérivé de ces deux sources plutôt que d'une
  /// liste de plus. Un nom non reconnu n'est PAS « non lanceur » : on ne sait
  /// rien de lui.
  static bool _castsNoSpells(String className) =>
      MulticlassPrerequisites.isKnownClass(className) &&
      !spellcastingClassNames.contains(className);

  /// Vrai si un sort du personnage doit être préparé pour être lancé — la
  /// valeur de `CharacterSpellEntry.requiresPreparation`.
  ///
  /// Sûr par défaut : la réponse n'est « non » que si une classe à sorts
  /// connus ([knowsSpellsWithoutPreparing]) l'établit. Tout le reste (classe
  /// qui prépare, nom non reconnu, aucune classe) donne « à préparer », le
  /// comportement historique.
  ///
  /// [sourceClassIds] : les `character_spells.source_class_id` non nuls des
  /// lignes de ce sort (plusieurs si le sort a des lignes en double : aucune
  /// contrainte d'unicité sur `(character_id, spell_id)`). Seuls ceux qui
  /// désignent une classe lanceuse (ou non reconnue) de [classes] comptent ;
  /// les autres (classe quittée depuis, classe non lanceuse : donnée
  /// incohérente) sont ignorés.
  ///
  /// - Une origine à sorts connus suffit : le sort est connu par cette
  ///   classe, donc lançable tel quel — même si une autre ligne du même sort
  ///   vient d'une classe qui prépare ou n'a pas d'origine. Règle
  ///   indépendante de l'ordre des lignes.
  /// - Sinon, une origine qui prépare ou non reconnue : à préparer.
  /// - Sinon (origine inconnue : `source_class_id` nul, colonne absente d'un
  ///   ancien cache, sort de la liste de classe sans ligne) : sans
  ///   préparation seulement si le personnage a au moins une classe à sorts
  ///   connus et que toutes ses autres classes sont des classes connues non
  ///   lanceuses (Barde + Guerrier). Une classe qui prépare ou non reconnue
  ///   (Barde + Clerc, Barde + Artificier) fait retomber sur « à préparer ».
  static bool spellRequiresPreparation({
    required List<CharacterDetailClassRow> classes,
    Iterable<int> sourceClassIds = const [],
  }) {
    final sourceKeys = {for (final id in sourceClassIds) id.toString()};
    var hasOtherSource = false;
    var hasKnownCaster = false;
    var hasOtherCaster = false;
    for (final row in classes) {
      if (_castsNoSpells(row.className)) continue;
      final knows = knowsSpellsWithoutPreparing(row.className);
      if (knows) {
        hasKnownCaster = true;
      } else {
        hasOtherCaster = true;
      }
      if (sourceKeys.contains(row.classId.toString())) {
        if (knows) return false;
        hasOtherSource = true;
      }
    }
    if (hasOtherSource) return true;
    return !hasKnownCaster || hasOtherCaster;
  }

  /// Limite de sorts préparés d'une classe, `null` si [className] ne prépare
  /// pas ses sorts. [abilityModifier] est le modificateur de la
  /// caractéristique d'incantation de la classe (voir [abilityKeyFor]).
  static int? limitFor({
    required String className,
    required int classLevel,
    required int abilityModifier,
  }) {
    final base = switch (className) {
      'Clerc' || 'Druide' || 'Magicien' => classLevel,
      'Paladin' => classLevel ~/ 2,
      _ => null,
    };
    if (base == null) return null;
    final limit = base + abilityModifier;
    return limit < 1 ? 1 : limit;
  }

  /// Limite à afficher pour un personnage, `null` (rien à afficher) si aucune
  /// classe ne prépare, ou si PLUSIEURS classes préparent : le nombre de sorts
  /// préparés n'est pas ventilé par classe (le décompte porte sur tous les
  /// sorts du personnage), une limite par classe donnerait un chiffre faux.
  static int? limitForCharacter({
    required List<CharacterDetailClassRow> classes,
    required Map<String, int> abilityScores,
  }) {
    final preparing = [
      for (final row in classes)
        if (preparesSpells(row.className)) row,
    ];
    if (preparing.length != 1) return null;
    final row = preparing.single;
    final score = abilityScores[abilityKeyFor(row.className)] ?? 10;
    return limitFor(
      className: row.className,
      classLevel: row.level,
      abilityModifier: AbilityScoreRules.abilityModifier(score),
    );
  }
}
