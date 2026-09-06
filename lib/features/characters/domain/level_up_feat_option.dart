/// Un don disponible au choix à l'étape "Choix à faire" de la montée de
/// niveau, sous-mode "don" (niveaux ASI 4/8/12/16/19,
/// `presentation/level_up_screen.dart`, spec visuelle direction-artistique
/// section 1/2) — nom/description/prérequis déjà résolus via `translations`
/// (`entity_type = 'feat'`) et `feats.prerequisites->>'text'`, voir
/// `data/level_up_feat_row_mapper.dart`.
///
/// Ne liste que les dons NON déjà possédés par le personnage
/// (`character_feats`) — voir
/// `data/character_repository.dart::fetchAvailableFeats`.
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [LevelUpSubclassOption], donnée en lecture seule construite une fois par
/// le repository.
class LevelUpFeatOption {
  const LevelUpFeatOption({
    required this.id,
    required this.name,
    required this.description,
    this.prerequisiteText,
  });

  /// `feats.id` (entier côté Supabase, gardé en [Object] — même convention
  /// que `LevelUpSubclassOption.id`).
  final Object id;

  final String name;

  /// `feats.prerequisites->>'text'`, `null` si aucun prérequis textuel
  /// renseigné en base — affiché en `subtitle` de la tuile de sélection
  /// (`SelectableOptionTile.subtitle` tronque déjà à 1 ligne avec ellipsis).
  final String? prerequisiteText;

  /// Description complète du don, affichée uniquement dans le panneau
  /// "Infos" (`presentation/widgets/feat_info_panel.dart`) — jamais dans la
  /// tuile de sélection elle-même (décision produit, voir la spec visuelle
  /// direction-artistique section 2 : "Ne PAS afficher la description
  /// complète du don dans la tuile").
  final String description;
}
