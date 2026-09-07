/// Noms de classe (français, `character_classes` déjà traduit) qui lancent
/// des sorts en 5e RAW — utilisé pour distinguer, dans l'onglet "Sorts" de la
/// fiche personnage (`presentation/widgets/character_spells_tab_body.dart`),
/// "aucun sort choisi pour l'instant" (classe lanceuse) de "cette classe ne
/// lance pas de sorts" (classe non lanceuse, voir maquette
/// `docs/cahier-des-charges/09-maquettes-captures.md`, section "État vide —
/// Sorts").
///
/// Duplique volontairement la liste de
/// `character_creation/domain/spellcasting_rules.dart::SpellcastingRules`
/// (union de `_cantripQuotaByClassName`/`_levelOneSpellQuotaByClassName`)
/// plutôt que de l'importer directement : même principe de duplication
/// assumée que `RaceRowMapper`/`ClassRowMapper` dans ce dépôt, pour ne pas
/// coupler `features/characters/` à `features/character_creation/`
/// (architecture par fonctionnalité, voir `CLAUDE.md`).
///
/// Ne modélise pas les sous-classes qui accordent des sorts à une classe de
/// base non lanceuse (ex. Chevalier occulte pour le Guerrier, Roublard
/// arcanique) — aucune des deux n'est implémentée dans ce dépôt à ce jour
/// (`sous-classe` n'est même pas relue par `CharacterRepository
/// .fetchCharacterDetail`, voir le README) : un Guerrier affiche donc
/// toujours "cette classe ne lance pas de sorts" ici, ce qui reste correct
/// tant que ces sous-classes ne sont pas construites.
const Set<String> spellcastingClassNames = {
  'Barde',
  'Clerc',
  'Druide',
  'Paladin',
  'Rôdeur',
  'Occultiste',
  'Magicien',
  'Ensorceleur',
};
