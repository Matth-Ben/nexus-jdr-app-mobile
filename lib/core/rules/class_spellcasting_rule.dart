import 'character_class.dart';

/// Type de lanceur de sorts RAW 5e, voir [ClassSpellcastingRule.casterType].
enum CasterType {
  /// Ne lance aucun sort (Barbare, Guerrier, Moine, Roublard — hors
  /// sous-classes lanceuses du Guerrier/Roublard, non modélisées dans ce
  /// dépôt, voir le README).
  none,

  /// Lanceur complet — emplacements de niveau de sort 1 à 9 (Barde, Clerc,
  /// Druide, Magicien, Ensorceleur).
  full,

  /// Demi-lanceur — emplacements de niveau de sort 1 à 5 seulement, à un
  /// niveau de personnage décalé (Paladin, Rôdeur, et depuis le 10/10/2026
  /// l'Artificier par décision produit, voir
  /// [ClassSpellcastingRule.artificer]).
  half,

  /// Magie de pacte de l'Occultiste — mécanisme à part (charges rechargées
  /// au repos court), voir `characters/domain/spell_slot_progression.dart::
  /// pactMagicFor`.
  pact,
}

/// Mode d'acquisition des sorts RAW 5e, voir
/// [ClassSpellcastingRule.preparationMode].
enum SpellPreparationMode {
  /// Ne s'applique pas ([CasterType.none]).
  none,

  /// Un nombre fixe de sorts appris définitivement
  /// (`character_spells.status = 'connu'`) — Barde, Ensorceleur, Occultiste,
  /// Rôdeur.
  known,

  /// Un sous-ensemble choisi chaque jour parmi les sorts accessibles
  /// (`character_spells.status = 'préparé'`) — Clerc, Druide, Magicien,
  /// Paladin, Artificier.
  prepared,
}

/// Règle de lancer de sorts d'UNE classe — remplace les 3+3 listes dupliquées
/// de `lib/features/characters/domain/spellcasting_class_names.dart`,
/// `lib/features/characters/domain/spell_slot_progression.dart`,
/// `lib/features/characters/domain/prepared_spells_limit.dart`,
/// `lib/features/characters/domain/prepared_caster_spell_list.dart` et
/// `lib/features/character_creation/domain/spellcasting_rules.dart` (dette
/// D04, `docs/dette-technique.md`) : une seule table, consultée par
/// [ClassSpellcastingRegistry.ruleFor], au lieu de six listes à maintenir en
/// synchronisation manuelle.
class ClassSpellcastingRule {
  const ClassSpellcastingRule._({
    required this.casterType,
    required this.preparationMode,
    this.spellcastingAbilityKey,
    this.hasFullSpellListAccess = false,
  });

  /// Repli pour toute classe absente de [ClassSpellcastingRegistry] — ne
  /// lance aucun sort.
  static const ClassSpellcastingRule none = ClassSpellcastingRule._(
    casterType: CasterType.none,
    preparationMode: SpellPreparationMode.none,
  );

  const ClassSpellcastingRule.full({
    required String abilityKey,
    required SpellPreparationMode preparationMode,
    bool hasFullSpellListAccess = false,
  }) : this._(
         casterType: CasterType.full,
         preparationMode: preparationMode,
         spellcastingAbilityKey: abilityKey,
         hasFullSpellListAccess: hasFullSpellListAccess,
       );

  const ClassSpellcastingRule.half({
    required String abilityKey,
    required SpellPreparationMode preparationMode,
    bool hasFullSpellListAccess = false,
  }) : this._(
         casterType: CasterType.half,
         preparationMode: preparationMode,
         spellcastingAbilityKey: abilityKey,
         hasFullSpellListAccess: hasFullSpellListAccess,
       );

  const ClassSpellcastingRule.pact({required String abilityKey})
    : this._(
        casterType: CasterType.pact,
        preparationMode: SpellPreparationMode.known,
        spellcastingAbilityKey: abilityKey,
      );

  /// Lanceur complet, demi-lanceur, magie de pacte, ou aucun.
  final CasterType casterType;

  /// Connaît ses sorts, les prépare, ou ne s'applique pas.
  final SpellPreparationMode preparationMode;

  /// Clé de caractéristique d'incantation ('wis'/'int'/'cha'), `null` ssi
  /// [casterType] est [CasterType.none].
  final String? spellcastingAbilityKey;

  /// `true` pour un lanceur « à préparation » qui choisit chaque jour parmi
  /// **toute** la liste de sorts de sa classe (Clerc, Druide, Paladin,
  /// Artificier) — par opposition au Magicien, qui prépare depuis un
  /// grimoire alimenté à la montée de niveau (sous-ensemble connu, pas accès
  /// à la liste entière). Sans effet pour un lanceur « à sorts connus » ou
  /// non lanceur (toujours `false`). Voir
  /// `characters/domain/prepared_caster_spell_list.dart`.
  final bool hasFullSpellListAccess;

  bool get isCaster => casterType != CasterType.none;

  bool get preparesSpells => preparationMode == SpellPreparationMode.prepared;

  bool get knowsSpellsWithoutPreparing =>
      preparationMode == SpellPreparationMode.known;
}

/// Registre unique des règles de lancer de sorts par classe — voir la
/// documentation de [ClassSpellcastingRule]. Seule source de vérité pour
/// « cette classe lance-t-elle des sorts, de quel type, et les
/// connaît/prépare-t-elle » dans tout ce dépôt.
///
/// **D41** (`docs/dette-technique.md`) : l'Artificier (id 13, ajouté le
/// 30/09/2026, `spell_classes` lui lie déjà 100 sorts) est modélisé comme un
/// demi-lanceur qui prépare — décision produit de Matthias du 10/10/2026.
/// RAW 5e stricte, l'Artificier a sa propre table de progression
/// d'emplacements (2 emplacements de niveau de sort 1 dès le niveau 1,
/// contrairement à Paladin/Rôdeur qui n'en ont aucun avant le niveau 2) :
/// Matthias a explicitement demandé de réutiliser « la progression de
/// Paladin/Rôdeur », une simplification assumée plutôt que la table RAW
/// exacte — voir `characters/domain/spell_slot_progression.dart`, qui range
/// l'Artificier dans [ClassSpellcastingRegistry.halfCasterClasses] sans
/// table dédiée. Côté préparation, l'Artificier prépare bien depuis
/// l'intégrale de sa liste de classe (comme Clerc/Druide/Paladin, pas un
/// sous-ensemble « connu » façon Magicien) : `hasFullSpellListAccess: true`.
abstract final class ClassSpellcastingRegistry {
  static const Map<CharacterClass, ClassSpellcastingRule> _rules = {
    CharacterClass.bard: ClassSpellcastingRule.full(
      abilityKey: 'cha',
      preparationMode: SpellPreparationMode.known,
    ),
    CharacterClass.cleric: ClassSpellcastingRule.full(
      abilityKey: 'wis',
      preparationMode: SpellPreparationMode.prepared,
      hasFullSpellListAccess: true,
    ),
    CharacterClass.druid: ClassSpellcastingRule.full(
      abilityKey: 'wis',
      preparationMode: SpellPreparationMode.prepared,
      hasFullSpellListAccess: true,
    ),
    CharacterClass.wizard: ClassSpellcastingRule.full(
      abilityKey: 'int',
      preparationMode: SpellPreparationMode.prepared,
    ),
    CharacterClass.sorcerer: ClassSpellcastingRule.full(
      abilityKey: 'cha',
      preparationMode: SpellPreparationMode.known,
    ),
    CharacterClass.paladin: ClassSpellcastingRule.half(
      abilityKey: 'cha',
      preparationMode: SpellPreparationMode.prepared,
      hasFullSpellListAccess: true,
    ),
    CharacterClass.ranger: ClassSpellcastingRule.half(
      abilityKey: 'wis',
      preparationMode: SpellPreparationMode.known,
    ),
    // D41 : voir la documentation de classe ci-dessus.
    CharacterClass.artificer: ClassSpellcastingRule.half(
      abilityKey: 'int',
      preparationMode: SpellPreparationMode.prepared,
      hasFullSpellListAccess: true,
    ),
    CharacterClass.warlock: ClassSpellcastingRule.pact(abilityKey: 'cha'),
    // barbarian, fighter, monk, rogue : absents -> ClassSpellcastingRule.none.
  };

  /// Règle de [characterClass] — [ClassSpellcastingRule.none] si absente de
  /// [_rules] (Barbare, Guerrier, Moine, Roublard).
  static ClassSpellcastingRule ruleFor(CharacterClass characterClass) =>
      _rules[characterClass] ?? ClassSpellcastingRule.none;

  /// Équivalent [ruleFor] pour un libellé français déjà traduit
  /// (`CharacterDetailClassRow.className`, `ClassOption.name`...) —
  /// [ClassSpellcastingRule.none] si [frenchName] ne résout vers aucune
  /// [CharacterClass] connue (nom non reconnu, repli « Classe #id », ou
  /// future classe non encore ajoutée à [CharacterClass]). Sûr par défaut :
  /// un nom inconnu n'est jamais traité comme lanceur.
  static ClassSpellcastingRule ruleForFrenchName(String? frenchName) {
    final characterClass = CharacterClass.fromFrenchName(frenchName);
    if (characterClass == null) return ClassSpellcastingRule.none;
    return ruleFor(characterClass);
  }

  /// Classes lanceuses complètes (voir [CasterType.full]).
  static Set<CharacterClass> get fullCasterClasses => {
    for (final entry in _rules.entries)
      if (entry.value.casterType == CasterType.full) entry.key,
  };

  /// Classes demi-lanceuses (voir [CasterType.half]) — inclut l'Artificier
  /// depuis D41.
  static Set<CharacterClass> get halfCasterClasses => {
    for (final entry in _rules.entries)
      if (entry.value.casterType == CasterType.half) entry.key,
  };

  /// Classes à magie de pacte (voir [CasterType.pact]) — seul l'Occultiste à
  /// ce jour.
  static Set<CharacterClass> get pactCasterClasses => {
    for (final entry in _rules.entries)
      if (entry.value.casterType == CasterType.pact) entry.key,
  };
}
