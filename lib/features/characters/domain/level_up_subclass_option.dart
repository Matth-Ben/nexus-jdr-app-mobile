/// Une sous-classe disponible au choix à un niveau donné (étape "Choix à
/// faire", variante `LevelUpChoiceKind.subclass`) — nom/description déjà
/// résolus via `translations` (`entity_type = 'subclass'`), voir
/// `data/level_up_choice_row_mapper.dart`.
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [CharacterClassFeature]/[LevelUpLevelData], donnée en lecture seule
/// construite une fois par le repository.
class LevelUpSubclassOption {
  const LevelUpSubclassOption({
    required this.id,
    required this.name,
    this.description,
  });

  /// `subclasses.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `CharacterDetailClassRow.classId`).
  final Object id;

  final String name;

  /// `subclasses.description` traduite, `null` si non renseignée en base
  /// (`SelectableOptionTile.subtitle` n'est alors pas affiché pour cette
  /// option, voir la spec visuelle direction-artistique de l'étape "Choix à
  /// faire").
  final String? description;
}
