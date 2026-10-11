import '../../../core/rules/character_class.dart';
import '../../../core/rules/class_spellcasting_rule.dart';
import '../../character_creation/domain/ability_score_rules.dart';
import 'character_detail_class_row.dart';

/// Limite de sorts préparés (5e RAW) des classes qui PRÉPARENT leurs sorts :
/// Clerc/Druide (Sagesse + niveau), Magicien (Intelligence + niveau),
/// Paladin et Artificier (moitié du niveau arrondie à l'inférieur). Minimum 1
/// dans tous les cas.
///
/// Les classes à sorts connus (Barde, Ensorceleur, Occultiste, Rôdeur) et les
/// classes non lanceuses (les sous-classes lanceuses du Guerrier/Roublard ne
/// sont pas modélisées) n'ont pas de limite de préparation : [limitFor]
/// renvoie `null`.
///
/// Classification déléguée au registre unique
/// `core/rules/class_spellcasting_rule.dart::ClassSpellcastingRegistry`
/// (dette D04, `docs/dette-technique.md`) — y compris l'Artificier, demi-
/// lanceur qui prépare depuis D41.
abstract final class PreparedSpellsLimit {
  /// Clé de caractéristique d'incantation ('wis'/'int'/'cha') des classes qui
  /// préparent leurs sorts, `null` pour toute autre classe.
  static String? abilityKeyFor(String className) {
    final rule = ClassSpellcastingRegistry.ruleForFrenchName(className);
    return rule.preparesSpells ? rule.spellcastingAbilityKey : null;
  }

  /// Vrai si [className] prépare ses sorts.
  static bool preparesSpells(String className) =>
      ClassSpellcastingRegistry.ruleForFrenchName(className).preparesSpells;

  /// Vrai si [className] est une classe à sorts connus : elle lance ses
  /// sorts sans les préparer (Barde, Ensorceleur, Occultiste, Rôdeur). Un nom
  /// inconnu (repli « Classe #id ») ne doit jamais rendre un sort lançable
  /// sans préparation — [ClassSpellcastingRegistry.ruleForFrenchName] est
  /// déjà sûr par défaut sur ce point (repli [ClassSpellcastingRule.none],
  /// qui ne connaît jamais sans préparer).
  static bool knowsSpellsWithoutPreparing(String className) =>
      ClassSpellcastingRegistry.ruleForFrenchName(className)
          .knowsSpellsWithoutPreparing;

  /// Vrai si [className] est une classe CONNUE qui ne lance aucun sort
  /// (Barbare, Guerrier, Moine, Roublard) : reconnue par [CharacterClass]
  /// (les 13 classes RAW) et non lanceuse selon
  /// [ClassSpellcastingRegistry]. Un nom non reconnu n'est PAS « non
  /// lanceur » : on ne sait rien de lui.
  static bool _castsNoSpells(String className) {
    final characterClass = CharacterClass.fromFrenchName(className);
    if (characterClass == null) return false;
    return !ClassSpellcastingRegistry.ruleFor(characterClass).isCaster;
  }

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
  ///
  /// `base` dépend du type de lanceur ([CasterType], voir
  /// [ClassSpellcastingRegistry]) : niveau de classe entier pour un lanceur
  /// complet qui prépare (Clerc, Druide, Magicien), moitié du niveau de
  /// classe arrondie à l'inférieur pour un demi-lanceur qui prépare (Paladin,
  /// Artificier depuis D41).
  static int? limitFor({
    required String className,
    required int classLevel,
    required int abilityModifier,
  }) {
    final rule = ClassSpellcastingRegistry.ruleForFrenchName(className);
    if (!rule.preparesSpells) return null;
    final base = switch (rule.casterType) {
      CasterType.full => classLevel,
      CasterType.half => classLevel ~/ 2,
      CasterType.none || CasterType.pact => null,
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
