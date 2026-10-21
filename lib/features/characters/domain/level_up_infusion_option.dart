/// Une infusion disponible au choix à l'étape "Infusions" de la montée de
/// niveau (Artificier, aptitude de CLASSE — pas de sous-classe,
/// `presentation/level_up_screen.dart`) — nom/description/prérequis déjà
/// résolus via `translations` (`entity_type = 'class_option'`) et
/// `class_options.prerequisites->>'text'`, voir
/// `data/level_up_infusion_row_mapper.dart`.
///
/// Ne liste que les infusions dont `class_options.min_level` est déjà
/// atteint ET NON déjà connues du personnage (`character_class_options`,
/// voir `data/character_repository.dart::fetchAvailableInfusions`) — RAW :
/// les 16 infusions du catalogue (`option_type = 'infusion'`, `class_id` de
/// l'Artificier, `subclass_id` nul) ont `min_level` ∈ {2, 6, 10, 14}
/// (confirmé par `regles-dnd`).
///
/// [prerequisiteText] : contrairement à [LevelUpManeuverOption]/
/// [LevelUpArcaneShotOption]/[LevelUpRuneOption] (jamais de prérequis
/// textuel pertinent), chaque infusion porte un prérequis de type de
/// support d'objet (armure/arme/bouclier/anneau/bâton/outils...) — même
/// structure jsonb `{"text": "..."}` que [LevelUpFeatOption.prerequisiteText]
/// /[LevelUpInvocationOption.prerequisiteText], affiché tel quel en
/// `subtitle` : purement informatif, l'app ne modélise pas encore les objets
/// magiques possédés individuellement pour calculer une éligibilité
/// structurée (voir `domain/infusions_known_progression.dart`, jamais de
/// filtrage automatique sur ce champ — contrairement à
/// `InvocationPrerequisites`, qui filtre réellement sur le niveau/pacte/sort
/// mineur connu).
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// [LevelUpFeatOption].
class LevelUpInfusionOption {
  const LevelUpInfusionOption({
    required this.id,
    required this.name,
    required this.description,
    this.prerequisiteText,
  });

  /// `class_options.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpManeuverOption.id`).
  final Object id;

  final String name;

  /// `class_options.prerequisites->>'text'` (type de support d'objet requis
  /// — armure, arme, bouclier, anneau...), `null` si aucun prérequis
  /// textuel renseigné en base.
  final String? prerequisiteText;

  /// Description complète de l'infusion, affichée en `subtitle` de la
  /// `CheckableOptionTile` de l'étape "Infusions" — même traitement que
  /// [LevelUpManeuverOption.description].
  final String description;
}
