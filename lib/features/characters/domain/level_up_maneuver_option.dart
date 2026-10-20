/// Une manœuvre disponible au choix à l'étape "Manœuvres" de la montée de
/// niveau (Guerrier, Maître de guerre, `presentation/level_up_screen.dart`)
/// — nom/description déjà résolus via `translations` (`entity_type =
/// 'class_option'`), voir `data/level_up_maneuver_row_mapper.dart`.
///
/// Ne liste que les manœuvres dont `class_options.min_level` est déjà
/// atteint ET NON déjà connues du personnage (`character_class_options`,
/// voir `data/character_repository.dart::fetchAvailableManeuvers`) — RAW :
/// les 23 manœuvres du catalogue ont toutes `min_level = 3` (confirmé par
/// `regles-dnd`), donc ce filtre n'exclut jamais rien par le niveau en
/// pratique, seule l'exclusion "déjà connue" est réellement discriminante.
///
/// Duplicata volontaire de [LevelUpElementalDisciplineOption] (même
/// structure, même rationale de duplication) — voir sa documentation de
/// classe : chaque étape dédiée de la montée de niveau garde son propre
/// modèle d'option, jamais partagé entre deux mécaniques de classes
/// différentes.
///
/// Volontairement une classe simple (pas `freezed`), même précédent.
class LevelUpManeuverOption {
  const LevelUpManeuverOption({
    required this.id,
    required this.name,
    required this.description,
  });

  /// `class_options.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpElementalDisciplineOption.id`).
  final Object id;

  final String name;

  /// Description complète de la manœuvre, affichée en `subtitle` de la
  /// `CheckableOptionTile` de l'étape "Manœuvres" — même traitement que
  /// [LevelUpElementalDisciplineOption.description].
  final String description;
}
