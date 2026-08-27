import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/class_feature_choice_label_formatter.dart';

void main() {
  group('ClassFeatureChoiceLabelFormatter.labelFor', () {
    test('valeurs connues -> libellé français dédié', () {
      expect(
        ClassFeatureChoiceLabelFormatter.labelFor('sous_classe'),
        'Sous-classe à choisir',
      );
      expect(
        ClassFeatureChoiceLabelFormatter.labelFor('style_combat'),
        'Style de combat',
      );
      expect(
        ClassFeatureChoiceLabelFormatter.labelFor('ennemi_jure'),
        'Ennemi juré',
      );
      expect(
        ClassFeatureChoiceLabelFormatter.labelFor('invocation'),
        'Invocation occulte',
      );
      expect(
        ClassFeatureChoiceLabelFormatter.labelFor('sort_domaine'),
        'Sort de domaine',
      );
    });

    test('valeur inconnue -> humanisation générique de la clé brute', () {
      expect(
        ClassFeatureChoiceLabelFormatter.labelFor('nouveau_pouvoir'),
        'Nouveau Pouvoir',
      );
      expect(ClassFeatureChoiceLabelFormatter.labelFor('mot'), 'Mot');
    });

    test('clé vide -> repli générique', () {
      expect(ClassFeatureChoiceLabelFormatter.labelFor(''), 'Choix à faire');
    });
  });
}
