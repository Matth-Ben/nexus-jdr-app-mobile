import 'subclass_feature_option.dart';

/// Second choix de niveau 1 propre à une sous-classe (générique : toute
/// ligne `class_features` où `subclass_id` = la sous-classe choisie,
/// `level = 1`, `choice_type` non nul ET différent de `'sous_classe'` — ce
/// dernier étant déjà le choix de SOUS-CLASSE elle-même, couvert par
/// `SubclassChoiceBlock`, pas ce second choix). Correctif D99
/// (`docs/dette-technique.md`).
///
/// Aujourd'hui, seul le Lignage draconique de l'Ensorceleur correspond
/// (`class_features.id = 368`, `choice_type = 'ancetre_draconique'`, 10
/// types de dragon) — voir `presentation/widgets
/// /subclass_feature_choice_block.dart` pour l'écran, construit générique
/// malgré ce seul cas actuel.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// [SubclassFeatureOption].
class SubclassFeatureChoice {
  const SubclassFeatureChoice({
    required this.classFeatureId,
    required this.featureName,
    required this.options,
  });

  /// `class_features.id` de la ligne à choix (ex. 368, "Ancêtre draconique")
  /// — écrit dans `character_class_options.class_feature_id` au moment de
  /// `createCharacter` (voir `data/character_creation_repository.dart`),
  /// même colonne que pour les choix nommés de CLASSE (Style de
  /// combat/Ennemi juré).
  final int classFeatureId;

  /// Nom de l'aptitude, déjà résolu via `translations`
  /// (`entity_type = 'class_feature'`), ex. "Ancêtre draconique" — titre du
  /// bloc.
  final String featureName;

  /// Options proposées (`class_options` où `option_type` = le `choice_type`
  /// de cette ligne), triées alphabétiquement. Éventuellement vide : cas
  /// défensif documenté (D95, `docs/dette-technique.md`) où la ligne
  /// `class_features` existe déjà mais le script SQL peuplant les
  /// `class_options` correspondantes n'a pas encore été exécuté — voir
  /// `SubclassFeatureChoiceBlock` pour le traitement non bloquant de ce cas.
  final List<SubclassFeatureOption> options;
}
