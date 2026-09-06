/// Une invocation occultiste disponible au choix à l'étape "Invocations" de
/// la montée de niveau (`presentation/level_up_screen.dart`, spec visuelle
/// direction-artistique section 3) — nom/description/prérequis déjà résolus
/// via `translations` (`entity_type = 'invocation'`) et
/// `invocations.prerequisites->>'text'`, voir
/// `data/level_up_invocation_row_mapper.dart`.
///
/// Ne liste que les invocations NON déjà connues du personnage
/// (`character_invocations`) — voir
/// `data/character_repository.dart::fetchAvailableInvocations`.
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [LevelUpFeatOption], donnée en lecture seule construite une fois par le
/// repository.
class LevelUpInvocationOption {
  const LevelUpInvocationOption({
    required this.id,
    required this.name,
    required this.description,
    this.prerequisiteText,
  });

  /// `invocations.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpFeatOption.id`).
  final Object id;

  final String name;

  /// `invocations.prerequisites->>'text'`, `null` si aucun prérequis
  /// textuel renseigné en base — affiché en `subtitle` de la
  /// `CheckableOptionTile` de l'étape "Invocations".
  final String? prerequisiteText;

  /// Description complète de l'invocation — pas encore consultable ailleurs
  /// dans l'app (aucun onglet "Invocations" de la fiche à ce chantier),
  /// affichée directement en `subtitle` étendu ou dans un futur panneau
  /// "Infos" si le besoin apparaît (hors périmètre de la spec visuelle
  /// actuelle, qui ne demande pas de panneau "Infos" pour les invocations —
  /// contrairement aux dons, voir [LevelUpFeatOption.description]). Gardée
  /// ici pour ne pas avoir à re-résoudre cette traduction plus tard.
  final String description;
}
