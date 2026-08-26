/// Règles de lancer de sorts encodées en constantes Dart applicatives,
/// exactement comme `SkillAbilityMapping` (mapping compétence -> caractéristique)
/// : aucune colonne de `classes`/`spell_classes` ne porte le nombre de
/// sorts/cantrips accessibles à la création (ni la distinction "sorts
/// connus" vs "sorts préparés"), voir le commentaire de tâche d'origine —
/// donc ces quotas doivent être encodés côté app plutôt que lus en base.
///
/// Clé de mapping : le **nom de classe en français** (`ClassOption.name`,
/// déjà résolu via `translations`) — même convention que
/// `SkillAbilityMapping.abilityAbbreviationBySkill` (clé = nom de compétence
/// en français), pas `classes.id` : ces id ne sont pas des constantes stables
/// documentées ailleurs dans ce dépôt (contrairement aux noms, cf.
/// `supabase/migrations/20260825090700_seed_classes_subclasses_features.sql`
/// du dépôt web), et garder la même convention de clé que
/// `SkillAbilityMapping` limite le nombre de façons différentes de référencer
/// une classe dans ce module.
///
/// [isSpellcastingClass] sert aussi de seule source de vérité pour la
/// visibilité de l'étape 6/9 entière, y compris depuis l'étape 5/9
/// (`presentation/skills_and_tools_step_screen.dart`, qui doit sauter
/// directement à l'étape 7/9 pour une classe non lanceuse) — pas de requête
/// réseau dédiée (`spell_classes` non vide) : les deux sources
/// (contenu peuplé en base et ce mapping) doivent rester synchronisées
/// manuellement, seule alternative pour trancher ce point à l'étape 5/9 sans
/// y faire porter un appel réseau supplémentaire.
///
/// Quotas ci-dessous choisis au plus proche du *Manuel des Joueurs* (5e) pour
/// un personnage de niveau 1, avec deux simplifications assumées documentées
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
///    consigne d'origine les liste explicitement parmi les 8 classes
///    lanceuses concernées par cette étape. Quota de 2 retenu par
///    cohérence avec leur valeur RAW au niveau 2 (leur premier niveau
///    disposant de sorts), pas une valeur inventée sans ancrage aux règles.
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
  };

  /// Sorts de niveau 1 accessibles à la création — voir le commentaire de
  /// classe pour le rationale des valeurs Clerc/Druide/Paladin/Rôdeur.
  /// Magicien (6) est la seule valeur non liée à un modificateur de
  /// caractéristique parmi les lanceurs "préparés" : au niveau 1, un
  /// Magicien a RAW un grimoire contenant exactement 6 sorts de niveau 1 de
  /// son choix, indépendamment de son Intelligence — valeur fixe exacte,
  /// pas une simplification.
  static const Map<String, int> _levelOneSpellQuotaByClassName = {
    'Barde': 4,
    'Clerc': 4,
    'Druide': 4,
    'Paladin': 2,
    'Rôdeur': 2,
    'Occultiste': 2,
    'Magicien': 6,
    'Ensorceleur': 2,
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

  /// `true` ssi [className] est l'une des 8 classes lanceuses de sorts
  /// (contenu peuplé, voir le commentaire de classe) — voir la documentation
  /// de classe pour le rationale de cette source de vérité par nom plutôt
  /// que par requête réseau.
  static bool isSpellcastingClass(String className) =>
      _cantripQuotaByClassName.containsKey(className) ||
      _levelOneSpellQuotaByClassName.containsKey(className);
}
