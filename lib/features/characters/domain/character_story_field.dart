/// Un des 9 champs de texte libre de l'onglet "Histoire" déjà résolu pour
/// l'affichage : libellé de carte tel qu'attendu par la maquette (majuscules,
/// voir `presentation/widgets/character_story_tab_body.dart`) et texte brut
/// non vide (le filtrage des champs vides est fait en amont par
/// `CharacterStoryFieldsResolver`, jamais par ce type de données lui-même).
class CharacterStoryField {
  const CharacterStoryField({required this.label, required this.text});

  final String label;
  final String text;
}
