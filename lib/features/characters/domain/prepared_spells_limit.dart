import '../../../core/rules/character_class.dart';
import '../../../core/rules/class_spellcasting_rule.dart';
import '../../../core/rules/spell_status.dart';
import '../../character_creation/domain/ability_score_rules.dart';
import 'character_detail_class_row.dart';
import 'character_spell_entry.dart';

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

  /// `true` si [spell] compte dans le décompte de sorts préparés d'une
  /// classe (le numérateur de "Préparés X / Y") — sort de niveau >= 1,
  /// effectivement 'préparé', ni accordé par une sous-classe ni exempté de
  /// préparation. Même règle que `CharacterDetail.preparedSpellCount`
  /// (dupliquée ici à l'identique plutôt que l'inverse : ce fichier ne
  /// dépend jamais de `CharacterDetail`, qui dépend déjà de lui).
  static bool _countsTowardPreparedLimit(CharacterSpellEntry spell) =>
      spell.level > 0 &&
      spell.status == SpellStatus.prepared &&
      !spell.isAlwaysPrepared &&
      spell.requiresPreparation;

  /// Décompte et limite PAR CLASSE qui prépare ses sorts — un élément par
  /// classe du personnage qui prépare ([preparesSpells]), liste vide si
  /// aucune classe ne prépare. Remplace l'ancien couple global unique
  /// `(preparedSpellCount, preparedSpellLimit)` de `CharacterDetail`, devenu
  /// RAW-incorrect dès que le personnage a PLUSIEURS classes qui préparent
  /// (ex. Clerc/Paladin) : RAW, chaque classe calcule sa propre limite
  /// séparément — son niveau, sa caractéristique, sa liste — jamais un total
  /// fusionné (PHB, « Multiclassing — Spells Known and Prepared »).
  ///
  /// Deux branches, pour ne jamais régresser le cas mono-classe (l'immense
  /// majorité des personnages) :
  /// - **Une seule classe qui prépare** : le décompte porte sur TOUS les
  ///   sorts qualifiants du personnage ([_countsTowardPreparedLimit]), SANS
  ///   filtrer par [CharacterSpellEntry.sourceClassIds] — comportement
  ///   historique à l'identique (y compris pour une ligne dont l'origine
  ///   n'est pas renseignée, cas déjà possible avant ce chantier pour un
  ///   sort de la liste complète jamais encore préparé) : aucune ambiguïté
  ///   possible avec une seule classe candidate.
  /// - **Plusieurs classes qui préparent** : chaque sort qualifiant est
  ///   ventilé vers la ou les classes dont [CharacterSpellEntry
  ///   .sourceClassIds] contient l'identifiant — un sort SANS origine connue
  ///   (donnée antérieure à ce chantier, voir la doc de ce champ) n'est
  ///   compté dans AUCUNE classe plutôt que deviné : sous-compte assumé,
  ///   jamais un sur-compte qui bloquerait la préparation à tort. Un sort
  ///   dont l'origine désigne PLUSIEURS classes du personnage qui préparent
  ///   (sort présent sur la liste complète de deux d'entre elles, ex.
  ///   Clerc/Druide partageant un sort, jamais encore préparé d'aucune des
  ///   deux) compte dans chacune : accepté comme signal d'affichage (chaque
  ///   compteur reste correct indépendamment), l'écriture bloquante
  ///   (`CharacterRepository.setSpellPrepared`) tranche, elle, une seule
  ///   classe précise à l'écriture (voir sa documentation).
  static List<ClassPreparedSpells> limitsByClass({
    required List<CharacterDetailClassRow> classes,
    required Map<String, int> abilityScores,
    required List<CharacterSpellEntry> spells,
  }) {
    final preparing = [
      for (final row in classes)
        if (preparesSpells(row.className)) row,
    ];
    if (preparing.isEmpty) return const [];

    int limitOf(CharacterDetailClassRow row) {
      final score = abilityScores[abilityKeyFor(row.className)] ?? 10;
      return limitFor(
            className: row.className,
            classLevel: row.level,
            abilityModifier: AbilityScoreRules.abilityModifier(score),
          ) ??
          1;
    }

    if (preparing.length == 1) {
      final row = preparing.single;
      final count = spells.where(_countsTowardPreparedLimit).length;
      return [
        ClassPreparedSpells(
          classId: row.classId,
          className: row.className,
          limit: limitOf(row),
          preparedCount: count,
        ),
      ];
    }

    return [
      for (final row in preparing)
        ClassPreparedSpells(
          classId: row.classId,
          className: row.className,
          limit: limitOf(row),
          preparedCount: spells
              .where(_countsTowardPreparedLimit)
              .where(
                (spell) => spell.sourceClassIds
                    .map((id) => id.toString())
                    .contains(row.classId.toString()),
              )
              .length,
        ),
    ];
  }
}

/// Décompte et limite de sorts préparés d'UNE classe qui prépare ses sorts
/// — un élément de la liste renvoyée par
/// [PreparedSpellsLimit.limitsByClass], voir sa documentation.
class ClassPreparedSpells {
  const ClassPreparedSpells({
    required this.classId,
    required this.className,
    required this.limit,
    required this.preparedCount,
  });

  /// `character_classes.class_id` de cette classe — type `Object`, même
  /// convention que [CharacterDetailClassRow.classId] (comparaisons
  /// toujours via `.toString()`, jamais un cast direct : voir
  /// `PreparedSpellsLimit.spellRequiresPreparation` pour le précédent).
  final Object classId;

  /// Nom de classe déjà traduit (`CharacterDetailClassRow.className`).
  final String className;

  /// Limite RAW de sorts préparés de cette classe (voir
  /// [PreparedSpellsLimit.limitFor]), toujours >= 1.
  final int limit;

  /// Nombre de sorts actuellement préparés attribués à cette classe (voir
  /// [PreparedSpellsLimit.limitsByClass] pour la règle de ventilation).
  final int preparedCount;

  /// `true` si [preparedCount] a atteint ou dépassé [limit] : plus aucun
  /// NOUVEAU sort ne peut être préparé pour cette classe tant qu'un autre
  /// n'a pas été dé-préparé (voir `CharacterRepository.setSpellPrepared`).
  bool get isAtLimit => preparedCount >= limit;
}
