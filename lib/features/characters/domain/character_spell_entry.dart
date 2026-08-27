/// Un sort connu/préparé du personnage (onglet "Compétences", section
/// "SORTS" — `presentation/widgets/character_spells_section.dart`) — voir
/// `data/character_detail_row_mapper.dart` pour la résolution depuis
/// `character_spells`/`spells`/`translations`.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `CharacterDetailClassRow`.
class CharacterSpellEntry {
  const CharacterSpellEntry({
    required this.id,
    required this.name,
    required this.level,
    required this.school,
    required this.status,
  });

  final int id;
  final String name;

  /// 0 = sort mineur, 1 à 9 = niveau d'emplacement requis.
  final int level;

  /// `spells.school`, chaîne vide si non renseignée côté base.
  final String school;

  /// `character_spells.status` : 'connu'/'préparé'/'inné'. Pas encore
  /// affiché à cette itération (voir la documentation de classe de
  /// `character_spells_section.dart`), gardé disponible pour la suite.
  final String status;
}
