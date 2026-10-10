import '../../../core/rules/class_spellcasting_rule.dart';
import '../../../core/rules/spell_status.dart';

/// Quotas de sorts à la création, encodés en constantes Dart applicatives,
/// exactement comme `SkillAbilityMapping` (mapping compétence ->
/// caractéristique) : aucune colonne de `classes`/`spell_classes` ne porte
/// le nombre de sorts/cantrips accessibles à la création — donc ces quotas
/// doivent être encodés côté app plutôt que lus en base.
///
/// Clé de mapping : le **nom de classe en français** (`ClassOption.name`,
/// déjà résolu via `translations`), même convention que
/// `SkillAbilityMapping.abilityAbbreviationBySkill`. La classification
/// « lanceur ou pas »/« connaît ou prépare » est, elle, déléguée au registre
/// unique `core/rules/class_spellcasting_rule.dart::ClassSpellcastingRegistry`
/// (dette D04, `docs/dette-technique.md`, ex-`_preparedCasterClassNames` de
/// ce fichier) : seuls les quotas numériques, propres à l'étape de création,
/// restent ici.
///
/// [isSpellcastingClass] sert aussi de seule source de vérité pour la
/// visibilité de l'étape 6/9 entière, y compris depuis l'étape 5/9
/// (`presentation/skills_and_tools_step_screen.dart`, qui doit sauter
/// directement à l'étape 7/9 pour une classe non lanceuse) — pas de requête
/// réseau dédiée (`spell_classes` non vide) : les deux sources
/// (contenu peuplé en base et le registre) doivent rester synchronisées
/// manuellement, seule alternative pour trancher ce point à l'étape 5/9 sans
/// y faire porter un appel réseau supplémentaire.
///
/// Quotas ci-dessous choisis au plus proche du *Manuel des Joueurs* (5e) pour
/// un personnage de niveau 1, avec des simplifications assumées documentées
/// caractéristique par caractéristique ci-dessous plutôt que silencieusement
/// — à valider par le chef de projet :
/// 1. Clerc/Druide sont des lanceurs "préparés" en 5e (nombre de sorts
///    préparés = modificateur de Sagesse + niveau, minimum 1, pas un nombre
///    fixe) : [_levelOneSpellQuotaByClassName] retombe ici sur un nombre fixe
///    (4) plutôt que de recalculer le modificateur final de Sagesse (bonus
///    racial inclus, étape 4/9) à cette étape — éviterait de recharger
///    `RaceCatalog` ici uniquement pour ce calcul (déjà fait une fois à
///    l'étape 4/9). 4 correspond au modificateur de Sagesse le plus courant
///    (+3, tableau standard/achat par points) + niveau 1.
/// 2. Paladin/Rôdeur n'ont RAW aucun sort accessible au niveau 1 (leur
///    lancer de sorts démarre au niveau 2) : leur donner un quota nul viderait
///    entièrement cette étape pour ces deux classes (aucun onglet visible,
///    voir la règle de masquage sur `SpellLevelTabSelector`), alors que la
///    consigne d'origine les liste explicitement parmi les classes
///    lanceuses concernées par cette étape. Quota de 2 retenu par
///    cohérence avec leur valeur RAW au niveau 2 (leur premier niveau
///    disposant de sorts), pas une valeur inventée sans ancrage aux règles.
/// 3. Artificier (D41, `docs/dette-technique.md`, décision produit du
///    10/10/2026 : demi-lanceur qui prépare, voir
///    [ClassSpellcastingRegistry]) — **contrairement à Paladin/Rôdeur (point
///    2), ce n'est PAS une valeur de secours par analogie avec un niveau
///    supérieur** : RAW, l'Artificier a bien 2 cantrips dès le niveau 1
///    (`domain/spells_known_progression.dart::cantripsKnownByLevel`,
///    confirmé par `qa-testeur` en relisant D41 — c'est justement ce qui le
///    distingue de Paladin/Rôdeur, qui eux n'ont RAW aucun sort avant le
///    niveau 2). Le chiffre retenu (2) est donc la vraie valeur RAW de
///    niveau 1, pas une simplification. Pour les sorts de niveau 1 : RAW il
///    prépare (modificateur d'Intelligence + moitié du niveau d'Artificier
///    arrondie à l'inférieur, minimum 1), soit 0 + modificateur au niveau 1
///    — valeur retenue (3) par cohérence avec le modificateur le plus
///    courant (+3), même méthode que Clerc/Druide ci-dessus, mais sans le
///    "+ niveau" (l'Artificier n'a droit à aucun bonus de niveau à ce
///    stade, contrairement à Clerc/Druide).
abstract final class SpellcastingRules {
  /// Cantrips connus au niveau 1 (`Manuel des Joueurs`, valeur exacte,
  /// indépendante du modificateur de caractéristique — contrairement aux
  /// sorts de niveau 1 des lanceurs "préparés", les cantrips connus sont un
  /// nombre fixe pour toutes les classes en 5e). Absente de cette map =
  /// aucun cantrip (Paladin/Rôdeur, qui n'ont RAW jamais accès aux cantrips,
  /// à aucun niveau) -> [cantripQuotaFor] retombe sur 0, onglet "Mineurs"
  /// masqué pour ces deux classes (voir `SpellLevelTabSelector`).
  static const Map<String, int> _cantripQuotaByClassName = {
    'Barde': 2,
    'Clerc': 3,
    'Druide': 2,
    'Occultiste': 2,
    'Magicien': 3,
    'Ensorceleur': 4,
    // D41 : voir le point 3 du commentaire de classe.
    'Artificier': 2,
  };

  /// Sorts de niveau 1 accessibles à la création — voir le commentaire de
  /// classe pour le rationale des valeurs Clerc/Druide/Paladin/Rôdeur/
  /// Artificier. Magicien (6) est la seule valeur non liée à un
  /// modificateur de caractéristique parmi les lanceurs "préparés" : au
  /// niveau 1, un Magicien a RAW un grimoire contenant exactement 6 sorts de
  /// niveau 1 de son choix, indépendamment de son Intelligence — valeur
  /// fixe exacte, pas une simplification.
  static const Map<String, int> _levelOneSpellQuotaByClassName = {
    'Barde': 4,
    'Clerc': 4,
    'Druide': 4,
    'Paladin': 2,
    'Rôdeur': 2,
    'Occultiste': 2,
    'Magicien': 6,
    'Ensorceleur': 2,
    // D41 : voir le point 3 du commentaire de classe.
    'Artificier': 3,
  };

  /// Quota de sorts mineurs (onglet "Mineurs") pour [className], 0 si cette
  /// classe n'a droit à aucun cantrip (non lanceuse, ou lanceuse sans
  /// cantrip comme Paladin/Rôdeur) — l'onglet correspondant doit alors être
  /// masqué (voir `SpellLevelTabSelector`).
  static int cantripQuotaFor(String className) =>
      _cantripQuotaByClassName[className] ?? 0;

  /// Quota de sorts de niveau 1 (onglet "Niveau 1") pour [className], 0 si
  /// cette classe n'est pas lanceuse de sorts.
  static int levelOneSpellQuotaFor(String className) =>
      _levelOneSpellQuotaByClassName[className] ?? 0;

  /// `true` ssi [className] est une classe lanceuse de sorts (contenu
  /// peuplé, voir le commentaire de classe) — déléguée au registre unique
  /// [ClassSpellcastingRegistry] (dette D04) plutôt qu'aux clés des deux maps
  /// de quotas ci-dessus : les deux sources restent synchronisées par
  /// construction (ajouter une classe lanceuse au registre sans lui donner
  /// de quota ici afficherait une étape 6/9 vide, repéré par
  /// `spellcasting_rules_test.dart`).
  static bool isSpellcastingClass(String className) =>
      ClassSpellcastingRegistry.ruleForFrenchName(className).isCaster;

  /// `character_spells.status` pour un sort de [className] — `préparé` pour
  /// les lanceurs "à préparation" (Clerc, Druide, Magicien, Paladin,
  /// Artificier), `connu` par défaut (les lanceurs "à sorts connus"
  /// explicitement, ET tout nom de classe imprévu). Cette méthode n'est
  /// normalement appelée que pour une classe lanceuse de sorts (voir
  /// [isSpellcastingClass]), jamais vérifié en amont par un `assert` pour
  /// rester une pure fonction de mapping, sans jamais crasher sur une donnée
  /// inattendue — voir [ClassSpellcastingRegistry.ruleForFrenchName], sûr
  /// par défaut (repli non-lanceur -> [SpellPreparationMode.none] ->
  /// [SpellStatus.known] ci-dessous).
  static SpellStatus statusFor(String className) {
    final rule = ClassSpellcastingRegistry.ruleForFrenchName(className);
    return rule.preparesSpells ? SpellStatus.prepared : SpellStatus.known;
  }
}
