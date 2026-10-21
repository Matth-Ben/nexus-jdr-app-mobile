/// Une option du second choix de niveau 1 d'une sous-classe (ex. un type de
/// dragon pour l'Ancêtre draconique du Lignage draconique, Ensorceleur) —
/// correctif D99 (`docs/dette-technique.md`), voir
/// `domain/subclass_feature_choice.dart`/
/// `presentation/widgets/subclass_feature_choice_block.dart`.
///
/// `class_options.id`/nom/description déjà résolus via `translations`
/// (`entity_type = 'class_option'`) — même forme que [SubclassChoiceOption],
/// modèle distinct (table/contexte différents : `class_options`, pas
/// `subclasses`) pour ne jamais coupler les deux choix entre eux.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `LevelUpRuneOption`/`LevelUpArcaneShotOption` (duplicata assumé, pas de
/// modèle partagé entre mécaniques).
class SubclassFeatureOption {
  const SubclassFeatureOption({
    required this.id,
    required this.name,
    this.description,
  });

  /// `class_options.id`.
  final int id;

  final String name;

  /// `null` si aucune description n'est renseignée en base (la tuile
  /// n'affiche alors pas de sous-titre).
  final String? description;
}
