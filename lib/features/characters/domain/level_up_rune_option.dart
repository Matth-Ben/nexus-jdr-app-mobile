/// Une rune disponible au choix à l'étape "Runes" de la montée de niveau
/// (Guerrier, Chevalier runique, `presentation/level_up_screen.dart`) —
/// nom/description déjà résolus via `translations` (`entity_type =
/// 'class_option'`), voir `data/level_up_rune_row_mapper.dart`.
///
/// Ne liste que les runes dont `class_options.min_level` est déjà atteint ET
/// NON déjà connues du personnage (`character_class_options`, voir
/// `data/character_repository.dart::fetchAvailableRunes`) — RAW : 4 des 6
/// runes du catalogue ont `min_level = 3`, les 2 autres `min_level = 7`
/// (prérequis propre à ces 2 runes, pas un palier de gain — voir
/// `domain/runes_known_progression.dart`), confirmé par `regles-dnd`.
///
/// Duplicata volontaire de [LevelUpManeuverOption]/[LevelUpArcaneShotOption]
/// (même structure, même rationale de duplication) — voir leur documentation
/// de classe : chaque étape dédiée de la montée de niveau garde son propre
/// modèle d'option, jamais partagé entre deux mécaniques de classes
/// différentes.
///
/// Volontairement une classe simple (pas `freezed`), même précédent.
class LevelUpRuneOption {
  const LevelUpRuneOption({
    required this.id,
    required this.name,
    required this.description,
  });

  /// `class_options.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpManeuverOption.id`).
  final Object id;

  final String name;

  /// Description complète de la rune, affichée en `subtitle` de la
  /// `CheckableOptionTile` de l'étape "Runes" — même traitement que
  /// [LevelUpManeuverOption.description].
  final String description;
}
