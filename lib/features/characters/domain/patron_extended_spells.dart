import '../../character_creation/domain/spell_catalog.dart';
import '../../character_creation/domain/spell_option.dart';

/// Un sort de la liste ÉTENDUE d'un patron d'Occultiste
/// (`subclass_spells.grant_kind = 'extends_list'`) : [classLevel] est le
/// niveau d'Occultiste à partir duquel les sorts de ce niveau de sort sont
/// accessibles (1/3/5/7/9 pour les niveaux de sort 1/2/3/4/5).
///
/// RAW 5e : ces sorts ne sont jamais connus/préparés d'office, ils s'ajoutent
/// seulement aux candidats que l'Occultiste peut choisir d'apprendre.
class PatronExtendedSpell {
  const PatronExtendedSpell({required this.spell, required this.classLevel});

  final SpellOption spell;
  final int classLevel;
}

/// Résultat de [PatronExtendedSpells.merge].
typedef PatronMergeResult = ({
  SpellCatalog catalog,

  /// `spells.id` présents UNIQUEMENT grâce au patron (absents de la liste de
  /// classe) — pour l'indication "Patron" du sélecteur.
  Set<int> patronOnlySpellIds,
});

/// Fusion des sorts étendus du patron avec le catalogue de la classe
/// Occultiste, pour l'étape "Sorts" de la montée de niveau.
abstract final class PatronExtendedSpells {
  /// Seule classe concernée par les listes étendues de patron.
  static const String warlockClassName = 'Occultiste';

  /// Ajoute à [base] les sorts de [extended] dont `classLevel <=`
  /// [warlockLevel] (niveau d'Occultiste CIBLE) et dont le niveau de sort
  /// n'excède pas [maxSpellLevel] (emplacements de pacte). Aucun doublon
  /// (un sort déjà dans [base] n'est pas re-ajouté ni marqué "patron"), liste
  /// triée par nom comme le catalogue d'origine.
  static PatronMergeResult merge({
    required SpellCatalog base,
    required List<PatronExtendedSpell> extended,
    required int warlockLevel,
    required int maxSpellLevel,
  }) {
    final knownIds = {for (final spell in base.spells) spell.id};
    final added = <SpellOption>[];
    for (final entry in extended) {
      final spell = entry.spell;
      if (entry.classLevel > warlockLevel) continue;
      if (spell.level > maxSpellLevel) continue;
      if (!knownIds.add(spell.id)) continue;
      added.add(spell);
    }
    if (added.isEmpty) {
      return (catalog: base, patronOnlySpellIds: const <int>{});
    }
    final merged = [...base.spells, ...added]
      ..sort((a, b) => a.name.compareTo(b.name));
    return (
      catalog: SpellCatalog(spells: merged),
      patronOnlySpellIds: {for (final spell in added) spell.id},
    );
  }
}
