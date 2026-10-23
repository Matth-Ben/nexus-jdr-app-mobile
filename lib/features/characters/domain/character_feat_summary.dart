/// Un don déjà possédé par le personnage (`character_feats`), résolu pour
/// la fiche personnage — onglet "Aptitudes", carte "DONS"
/// (`presentation/widgets/character_feats_card.dart`), voir
/// [CharacterDetail.feats] (`domain/character_detail.dart`).
///
/// Distinct de `LevelUpFeatOption` (`domain/level_up_feat_option.dart`),
/// réservé aux dons NON déjà possédés proposés à l'étape "Choix à faire" de
/// la montée de niveau (voir sa documentation de classe) : ce type-ci
/// représente l'inverse (un don déjà acquis, simple affichage en lecture
/// seule, sans les champs propres au choix — `increasableAbilities`/
/// `abilityIncreaseMax`). Les deux partagent néanmoins le même panneau
/// "Infos" ([showFeatInfoPanel], `presentation/widgets/feat_info_panel.dart`,
/// généralisé à `name`/`description`/`prerequisiteText` plutôt que typé sur
/// l'un ou l'autre) pour un rendu pixel-identique.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `CharacterClassChoice`/`CharacterJournalEntry` : donnée en lecture seule
/// construite une fois par le repository.
class CharacterFeatSummary {
  const CharacterFeatSummary({
    required this.name,
    required this.description,
    this.prerequisiteText,
  });

  final String name;

  final String description;

  /// `feats.prerequisites->>'text'`, `null` si aucun prérequis textuel
  /// renseigné en base — même champ que `LevelUpFeatOption.prerequisiteText`,
  /// affiché seulement dans le panneau "Infos" (ligne optionnelle).
  final String? prerequisiteText;
}
