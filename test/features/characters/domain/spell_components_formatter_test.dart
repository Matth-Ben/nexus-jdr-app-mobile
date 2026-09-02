import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spell_components_formatter.dart';

void main() {
  group('SpellComponentsFormatter.format', () {
    test('aucune composante renseignée -> "Aucune"', () {
      final result = SpellComponentsFormatter.format(const {});
      expect(result.label, 'Aucune');
      expect(result.materialDescriptionSuffix, isNull);
    });

    test('composantes V et S -> "V, S"', () {
      final result = SpellComponentsFormatter.format(const {
        'verbal': true,
        'somatic': true,
      });
      expect(result.label, 'V, S');
      expect(result.materialDescriptionSuffix, isNull);
    });

    test('composante matérielle sans description -> "M" sans suffixe', () {
      final result = SpellComponentsFormatter.format(const {'material': true});
      expect(result.label, 'M');
      expect(result.materialDescriptionSuffix, isNull);
    });

    test('composante matérielle avec description -> suffixe " — {desc}"', () {
      final result = SpellComponentsFormatter.format(const {
        'verbal': true,
        'material': true,
        'material_desc': 'une pincée de sable',
      });
      expect(result.label, 'V, M');
      expect(result.materialDescriptionSuffix, ' — une pincée de sable');
    });

    test('les trois composantes V, S, M', () {
      final result = SpellComponentsFormatter.format(const {
        'verbal': true,
        'somatic': true,
        'material': true,
      });
      expect(result.label, 'V, S, M');
    });
  });
}
