/// Un sort inné accordé par la race/sous-race d'un personnage
/// (`racial_innate_spells`, lignes sans choix de lignée — `lineage_id IS
/// NULL`, voir `data/racial_innate_spell_repository.dart`), à partir du
/// niveau TOTAL de personnage [characterLevel].
///
/// Les lignes `lineage_id` non nul (Drakéide, variantes 2024 d'Elfe/Gnome/
/// Tieffelin — choix de lignée fait par le joueur) sont hors périmètre :
/// elles ne sont jamais résolues en [RacialInnateSpellGrant], voir la
/// documentation de [RacialInnateSpellRepository].
class RacialInnateSpellGrant {
  const RacialInnateSpellGrant({
    required this.spellId,
    required this.spellName,
    required this.characterLevel,
  });

  final int spellId;
  final String spellName;

  /// Niveau TOTAL de personnage (somme des niveaux de toutes les classes, PAS
  /// le niveau d'une seule classe) à partir duquel ce sort est accordé.
  final int characterLevel;
}
