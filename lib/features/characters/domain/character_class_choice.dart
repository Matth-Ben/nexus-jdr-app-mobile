import 'warlock_pact.dart';

/// Un choix de classe résolu par niveau ("Style de combat"/"Ennemi juré",
/// `character_class_options` — voir `docs/cahier-des-charges/
/// 11-fonctionnalites-a-ajouter.md`) — onglet "Compétences", carte "CHOIX DE
/// CLASSE" (`presentation/widgets/character_class_choices_card.dart`).
///
/// Écrit depuis longtemps par la montée de niveau
/// (`data/character_repository.dart::_applyChoice`,
/// `LevelUpChoiceKind.fightingStyle`/`LevelUpChoiceKind.favoredEnemy`) mais
/// jamais relu par `fetchCharacterDetail` jusqu'à cet ajout — gap trouvé en
/// construisant l'export XML (voir le README, section "Reste à faire").
///
/// [chosenValue] est le libellé choisi tel quel (`chosen_value`, texte libre
/// — ces 2 choix n'ont pas de table de référence en base, listes codées en
/// dur côté écran de montée de niveau, voir
/// `domain/level_up_choice_options.dart`), pas un identifiant à résoudre.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// [CharacterDetailClassRow]/[CharacterClassFeature] : donnée en lecture
/// seule affichée telle quelle.
class CharacterClassChoice {
  const CharacterClassChoice({
    required this.featureName,
    required this.chosenValue,
  });

  /// Nom de l'aptitude de classe à l'origine du choix ("Style de combat",
  /// "Ennemi juré") — déjà traduit, résolu depuis `class_features`/
  /// `translations` au même titre que les aptitudes de la carte "APTITUDES
  /// DE CLASSE".
  final String featureName;

  final String chosenValue;

  /// Valeur lisible : traduit les clés de la Faveur de pacte de l'Occultiste
  /// (`chaine`/`lame`/`grimoire` -> "Pacte de la chaîne"...), renvoie
  /// [chosenValue] tel quel pour les autres choix (déjà des libellés).
  String get displayValue => WarlockPact.displayLabelFor(chosenValue);

  /// Pacte de l'Occultiste si ce choix en est un, `null` sinon.
  WarlockPact? get pact => WarlockPact.fromKey(chosenValue);
}
