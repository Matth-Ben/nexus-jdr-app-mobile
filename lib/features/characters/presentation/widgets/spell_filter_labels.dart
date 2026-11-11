import '../../../../l10n/app_localizations.dart';
import '../../domain/spell_list_filter.dart';
import '../../domain/spell_school.dart';

/// Libellés localisés des critères de [SpellListFilter] (feuille de filtres et
/// puces récapitulatives de l'onglet « Sorts »).
extension SpellFilterLabels on AppLocalizations {
  String spellFilterLevelLabel(int level) => level == 0
      ? spellFilterCantripsLabel
      : characterSpellsTabBodySlotsLevelLabel(level);

  String spellFilterSchoolLabel(SpellSchool school) => switch (school) {
    SpellSchool.abjuration => spellFilterSchoolAbjuration,
    SpellSchool.conjuration => spellFilterSchoolConjuration,
    SpellSchool.divination => spellFilterSchoolDivination,
    SpellSchool.enchantment => spellFilterSchoolEnchantment,
    SpellSchool.evocation => spellFilterSchoolEvocation,
    SpellSchool.illusion => spellFilterSchoolIllusion,
    SpellSchool.necromancy => spellFilterSchoolNecromancy,
    SpellSchool.transmutation => spellFilterSchoolTransmutation,
  };

  String spellFilterConcentrationLabel(SpellConcentrationFilter value) =>
      switch (value) {
        SpellConcentrationFilter.all => spellFilterConcentrationAll,
        SpellConcentrationFilter.concentration => spellFilterConcentrationOnly,
        SpellConcentrationFilter.noConcentration =>
          spellFilterConcentrationNone,
      };
}
