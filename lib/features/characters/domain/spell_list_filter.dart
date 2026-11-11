import 'character_spell_entry.dart';
import 'spell_school.dart';

/// Filtre de concentration : trois états exclusifs.
enum SpellConcentrationFilter { all, concentration, noConcentration }

/// Filtres de l'onglet « Sorts » (P4) : niveau, école, concentration.
///
/// Règle de combinaison : ET entre critères, OU entre les valeurs d'un même
/// critère (niveaux 1 OU 3, ET école Évocation OU Abjuration, ET concentration).
/// Un critère vide ([levels], [schools]) ou [SpellConcentrationFilter.all]
/// ne filtre rien. S'applique en plus (ET) de la recherche par nom et du filtre
/// de préparation (`SpellPreparationFilter`), qui restent séparés.
///
/// Un sort sans école reconnue ([SpellSchool.fromStored] nul) ne passe aucun
/// filtre d'école actif. Immuable : toute modification renvoie une copie.
class SpellListFilter {
  const SpellListFilter({
    this.levels = const {},
    this.schools = const {},
    this.concentration = SpellConcentrationFilter.all,
  });

  static const SpellListFilter none = SpellListFilter();

  final Set<int> levels;
  final Set<SpellSchool> schools;
  final SpellConcentrationFilter concentration;

  /// Nombre de critères sélectionnés (une puce par niveau, par école, et une
  /// pour la concentration si elle n'est pas sur « Tous »).
  int get activeCount =>
      levels.length +
      schools.length +
      (concentration == SpellConcentrationFilter.all ? 0 : 1);

  bool get isActive => activeCount > 0;

  SpellListFilter copyWith({
    Set<int>? levels,
    Set<SpellSchool>? schools,
    SpellConcentrationFilter? concentration,
  }) => SpellListFilter(
    levels: levels ?? this.levels,
    schools: schools ?? this.schools,
    concentration: concentration ?? this.concentration,
  );

  bool matches(CharacterSpellEntry spell) {
    if (levels.isNotEmpty && !levels.contains(spell.level)) return false;
    if (schools.isNotEmpty) {
      final school = SpellSchool.fromStored(spell.school);
      if (school == null || !schools.contains(school)) return false;
    }
    return switch (concentration) {
      SpellConcentrationFilter.all => true,
      SpellConcentrationFilter.concentration => spell.concentration,
      SpellConcentrationFilter.noConcentration => !spell.concentration,
    };
  }

  List<CharacterSpellEntry> apply(List<CharacterSpellEntry> spells) {
    if (!isActive) return spells;
    return [
      for (final spell in spells)
        if (matches(spell)) spell,
    ];
  }

  /// Niveaux présents parmi [spells], triés (0 = sorts mineurs).
  static List<int> presentLevels(List<CharacterSpellEntry> spells) =>
      {for (final spell in spells) spell.level}.toList()..sort();

  /// Écoles reconnues présentes parmi [spells], dans l'ordre de l'enum.
  static List<SpellSchool> presentSchools(List<CharacterSpellEntry> spells) {
    final present = {
      for (final spell in spells) SpellSchool.fromStored(spell.school),
    };
    return [
      for (final school in SpellSchool.values)
        if (present.contains(school)) school,
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is SpellListFilter &&
      other.concentration == concentration &&
      other.levels.length == levels.length &&
      other.levels.containsAll(levels) &&
      other.schools.length == schools.length &&
      other.schools.containsAll(schools);

  @override
  int get hashCode => Object.hash(
    concentration,
    Object.hashAllUnordered(levels),
    Object.hashAllUnordered(schools),
  );
}
