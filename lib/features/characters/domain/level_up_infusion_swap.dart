/// Échange d'UNE infusion déjà connue contre une autre, proposé à l'étape
/// "Infusions" de la montée de niveau (Artificier) — voir
/// `data/character_repository.dart::applyLevelUp` (paramètre
/// `infusionSwap`) et `domain/infusions_known_progression.dart` pour le
/// rationale de cette divergence de modèle (D93 du registre de dette
/// technique, `docs/dette-technique.md`) : seule mécanique de ce chantier à
/// autoriser un échange, décision explicite de Matthias, proposée à CHAQUE
/// niveau d'Artificier (pas seulement ceux qui augmentent le nombre
/// d'infusions connues).
///
/// Par NOM déjà résolu par l'appelant (même convention texte libre que
/// [maneuverNames]/[elementalDisciplineNames] côté `applyLevelUp`), jamais
/// un identifiant : `character_class_options` n'a pas de colonne dédiée à un
/// FK vers `class_options`.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `LevelUpChoiceSelection`.
class LevelUpInfusionSwap {
  const LevelUpInfusionSwap({
    required this.removedName,
    required this.addedName,
  });

  /// Nom de l'infusion déjà connue retirée — doit correspondre à une
  /// infusion EFFECTIVEMENT connue du personnage au moment de l'écriture
  /// (voir `CharacterRepository.applyLevelUp`, qui lève une
  /// `CharacterFailure` sinon).
  final String removedName;

  /// Nom de la nouvelle infusion apprise en remplacement — ne doit jamais
  /// être une infusion déjà connue (même règle de non-doublon que
  /// [maneuverNames]/[elementalDisciplineNames], vérifiée côté écran avant
  /// cet appel, jamais revérifiée ici : même niveau de confiance que le
  /// reste des listes "nouvellement choisies" de `applyLevelUp`).
  final String addedName;
}
