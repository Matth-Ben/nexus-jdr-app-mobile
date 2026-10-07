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
    this.storedStatus,
    this.requiresPreparation = true,
    this.innateUsesSpent = 0,
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

  /// `false` pour un sort sans AUCUNE ligne `character_spells` (dérivé pur) :
  /// sort accordé par une sous-classe, ou sort de la liste de classe d'un
  /// lanceur à préparation jamais préparé (sa ligne est créée quand il est
  /// préparé). Pas de favori possible, et exclu des exports. `true` pour
  /// tout sort doté d'une ligne réelle.
  final bool isPersisted;

  /// Statut réellement stocké dans `character_spells.status`, quand il diffère
  /// de [status] (sort accordé : [status] vaut toujours 'préparé' alors que la
  /// ligne en base peut valoir 'connu'). `null` = identique à [status]. Sert
  /// aux exports, fidèles aux données stockées.
  final String? storedStatus;

  /// `false` si ce sort vient d'une classe à sorts connus (Barde,
  /// Ensorceleur, Occultiste, Rôdeur) : il se lance sans être préparé et n'a
  /// aucune notion de préparation, quel que soit [status] (y compris
  /// 'préparé', hérité d'une version où il fallait le « préparer » pour le
  /// lancer). Dérivé à la lecture des classes du personnage et de
  /// `character_spells.source_class_id`, jamais stocké — voir
  /// `PreparedSpellsLimit.spellRequiresPreparation`.
  ///
  /// `true` par défaut : c'est la règle historique (un sort 'connu' de
  /// niveau >= 1 attend d'être préparé). Sans effet sur un sort mineur, inné
  /// ou accordé par une sous-classe, dont les règles passent avant — voir
  /// `domain/spell_status_formatter.dart`.
  final bool requiresPreparation;

  /// `character_spells.innate_uses_spent` : usages DÉPENSÉS depuis le dernier
  /// repos long, pour un sort inné de niveau >= 1 (lancé sans emplacement —
  /// voir `domain/innate_spell_usage.dart` pour la fréquence et les
  /// dérivés). 0 par défaut, et toujours 0 pour un sort sans ligne 'inné'.
  /// Sans signification pour tout autre sort (sort mineur inné compris : à
  /// volonté).
  final int innateUsesSpent;

  /// Copie avec un autre compteur d'usages innés dépensés — surcouche
  /// optimiste de `character_detail_screen.dart::_effectiveDetail`.
  CharacterSpellEntry copyWithInnateUsesSpent(int innateUsesSpent) =>
      CharacterSpellEntry(
        id: id,
        name: name,
        level: level,
        school: school,
        status: status,
        castingTime: castingTime,
        range: range,
        components: components,
        duration: duration,
        concentration: concentration,
        description: description,
        isFavorite: isFavorite,
        grantSource: grantSource,
        isPersisted: isPersisted,
        storedStatus: storedStatus,
        requiresPreparation: requiresPreparation,
        innateUsesSpent: innateUsesSpent,
      );

  /// `true` si le sort est accordé par une sous-classe ([grantSource] non
  /// nul) : toujours préparé, exclu du décompte des sorts préparés, non
  /// retirable.
  bool get isAlwaysPrepared => grantSource != null;
}
