import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/feat_tag.dart';

void main() {
  group('FeatTag.fromColumns', () {
    test('epic_boon : Épopée, quelle que soit la source', () {
      expect(FeatTag.fromColumns(category: 'epic_boon'), FeatTag.epic);
      expect(
        FeatTag.fromColumns(category: 'epic_boon', source: 'PHB24'),
        FeatTag.epic,
      );
      expect(
        FeatTag.fromColumns(category: 'epic_boon', source: 'FToD'),
        FeatTag.epic,
      );
    });

    test('legacy + supplément de campagne : Campagne', () {
      for (final source in ['FToD', 'BGG', 'PSAiM', 'DSotDQ']) {
        expect(
          FeatTag.fromColumns(category: 'legacy', source: source),
          FeatTag.campaign,
          reason: source,
        );
      }
    });

    test('legacy + PHB14/XGtE/TCoE/NULL : aucune étiquette', () {
      for (final source in ['PHB14', 'XGtE', 'TCoE', null]) {
        expect(
          FeatTag.fromColumns(category: 'legacy', source: source),
          isNull,
          reason: '$source',
        );
      }
    });

    test('source de campagne hors legacy : aucune étiquette', () {
      for (final category in ['origin', 'general', 'fighting_style']) {
        expect(
          FeatTag.fromColumns(category: category, source: 'FToD'),
          isNull,
          reason: category,
        );
      }
    });

    test('origin/general/fighting_style, NULL, absent, inconnu : aucune', () {
      for (final category in ['origin', 'general', 'fighting_style']) {
        expect(FeatTag.fromColumns(category: category), isNull);
      }
      expect(FeatTag.fromColumns(), isNull);
      expect(FeatTag.fromColumns(category: null, source: null), isNull);
      expect(FeatTag.fromColumns(category: 'inconnu', source: 'FToD'), isNull);
      expect(FeatTag.fromColumns(category: 'legacy', source: 'XYZ'), isNull);
      expect(FeatTag.fromColumns(category: 42, source: 7), isNull);
    });
  });
}
