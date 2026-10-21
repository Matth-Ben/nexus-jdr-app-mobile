/// Une option de Métamagie disponible au choix à l'étape "Métamagie" de la
/// montée de niveau (Ensorceleur, aptitude de CLASSE —
/// `presentation/level_up_screen.dart`) — nom/description déjà résolus via
/// `translations` (`entity_type = 'class_option'`) et
/// `class_options.prerequisites->>'cost'` (coût en points de sorcellerie,
/// purement informatif — l'app ne décompte pas les points de sorcellerie),
/// voir `data/level_up_metamagic_row_mapper.dart`.
///
/// Ne liste que les options NON déjà connues du personnage
/// (`character_class_options`, voir
/// `data/character_repository.dart::fetchAvailableMetamagicOptions`) — RAW :
/// les 10 options du catalogue (`option_type = 'metamagie'`, `class_id` de
/// l'Ensorceleur, `subclass_id` NULL) ont toutes `min_level = 3`.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `LevelUpInfusionOption`.
class LevelUpMetamagicOption {
  const LevelUpMetamagicOption({
    required this.id,
    required this.name,
    required this.description,
    this.costText,
  });

  /// `class_options.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpInfusionOption.id`).
  final Object id;

  final String name;

  /// `class_options.prerequisites->>'cost'` (coût en points de sorcellerie,
  /// texte libre — ex. "1 point de sorcellerie"), `null` si absent.
  final String? costText;

  /// Description complète de l'option, affichée en `subtitle` de la
  /// `CheckableOptionTile` de l'étape "Métamagie" — même traitement que
  /// [LevelUpInfusionOption.description].
  final String description;
}
