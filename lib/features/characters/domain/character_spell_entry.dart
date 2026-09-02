/// Un sort connu/préparé du personnage (onglet "Sorts", section "SORTS" —
/// `presentation/widgets/character_spells_section.dart`) — voir
/// `data/character_detail_row_mapper.dart`/`data/character_spell_row_mapper.dart`
/// pour la résolution depuis `character_spells`/`spells`/`translations`.
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
    this.castingTime = '',
    this.range = '',
    this.components = const {},
    this.duration = '',
    this.concentration = false,
    this.description = '',
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

  /// `spells.casting_time`, chaîne vide si non renseigné — panneau "Infos"
  /// (`presentation/widgets/spell_info_panel.dart`).
  final String castingTime;

  /// `spells.range`, même convention que [castingTime].
  final String range;

  /// `spells.components` (jsonb `{verbal, somatic, material,
  /// material_desc}`) tel quel — voir
  /// `domain/spell_components_formatter.dart` pour sa mise en forme à
  /// l'affichage. Map vide si non renseigné côté base.
  final Map<String, dynamic> components;

  /// `spells.duration`, même convention que [castingTime].
  final String duration;

  /// `spells.concentration`.
  final bool concentration;

  /// `spells.description`, chaîne vide si non renseignée.
  final String description;
}
