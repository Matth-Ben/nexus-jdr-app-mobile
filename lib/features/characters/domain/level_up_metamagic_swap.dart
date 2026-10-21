/// Échange d'UNE option de Métamagie déjà connue contre une autre, proposé
/// à CHAQUE niveau d'Ensorceleur (pas seulement 3/10/17) — voir
/// `data/character_repository.dart::applyLevelUp` (paramètre
/// `metamagicSwap`) et `domain/metamagic_known_progression.dart` pour le
/// rationale RAW — même précédent que l'échange d'infusion de l'Artificier
/// (`domain/level_up_infusion_swap.dart`, D93 du registre de dette
/// technique, `docs/dette-technique.md`).
///
/// Par NOM déjà résolu par l'appelant (même convention texte libre que
/// [LevelUpInfusionSwap]), jamais un identifiant : `character_class_options`
/// n'a pas de colonne dédiée à un FK vers `class_options`.
///
/// Volontairement une classe simple (pas `freezed`), même précédent.
class LevelUpMetamagicSwap {
  const LevelUpMetamagicSwap({
    required this.removedName,
    required this.addedName,
  });

  /// Nom de l'option déjà connue retirée — doit correspondre à une option
  /// EFFECTIVEMENT connue du personnage au moment de l'écriture (voir
  /// `CharacterRepository.applyLevelUp`, qui lève une `CharacterFailure`
  /// sinon).
  final String removedName;

  /// Nom de la nouvelle option apprise en remplacement — ne doit jamais être
  /// une option déjà connue (vérifié côté écran avant cet appel, jamais
  /// revérifié ici : même niveau de confiance que le reste des listes
  /// "nouvellement choisies" de `applyLevelUp`).
  final String addedName;
}
