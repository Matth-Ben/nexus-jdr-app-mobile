import 'character_spell_entry.dart';

/// Filtre pur des sorts par nom — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section 3,
/// "Filtre / recherche dans la liste des sorts", et la maquette "Fiche —
/// Sorts" (`09-maquettes-captures.md`, champ "Rechercher un sort").
///
/// Même convention que `character_list_filter.dart::CharacterListFilter`
/// (sous-chaîne insensible à la casse, sans normalisation des accents).
abstract final class SpellNameFilter {
  static List<CharacterSpellEntry> apply({
    required List<CharacterSpellEntry> spells,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return spells;
    return spells
        .where((spell) => spell.name.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);
  }
}
