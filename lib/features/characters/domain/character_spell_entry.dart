import 'spell_grant_source.dart';

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
    this.isFavorite = false,
    this.grantSource,
    this.isPersisted = true,
  });

  final int id;
  final String name;

  /// 0 = sort mineur, 1 à 9 = niveau d'emplacement requis.
  final int level;

  /// `spells.school`, chaîne vide si non renseignée côté base.
  final String school;

  /// `character_spells.status` : 'connu'/'préparé'/'inné' — voir
  /// `domain/spell_status_formatter.dart` pour sa mise en forme à
  /// l'affichage et les règles dérivées (éligibilité de "Lancer",
  /// bascule "Préparer").
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

  /// `character_spells.is_favorite` — épinglage pour accès rapide en combat,
  /// voir `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
  /// "Onglet Sorts". Bascule via l'étoile de `_SpellRow`
  /// (`presentation/widgets/character_spells_section.dart`) — voir
  /// `CharacterRepository.setSpellFavorite`.
  final bool isFavorite;

  /// Origine du sort s'il est accordé automatiquement par une sous-classe
  /// (`subclass_spells`, voir `domain/subclass_spell_grant_resolver.dart`),
  /// `null` pour un sort ordinaire. Un sort accordé est toujours préparé
  /// ([status] vaut alors 'préparé'), ne compte pas dans la limite de sorts
  /// préparés et ne peut pas être dé-préparé.
  ///
  /// Si le même sort est aussi présent dans `character_spells` (choisi
  /// normalement), il n'apparaît qu'une fois : cette entrée, marquée accordée
  /// ([isPersisted] `true`).
  final SpellGrantSource? grantSource;

  /// `false` uniquement pour un sort accordé qui n'a AUCUNE ligne
  /// `character_spells` (dérivé pur) : rien à écrire dessus, donc ni
  /// favori ni statut modifiable. `true` pour tout sort ordinaire et pour un
  /// sort accordé doublé d'une ligne réelle.
  final bool isPersisted;

  /// `true` si le sort est accordé par une sous-classe ([grantSource] non
  /// nul) : toujours préparé, exclu du décompte des sorts préparés, non
  /// retirable.
  bool get isAlwaysPrepared => grantSource != null;
}
