import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/class_feature_usage_formatter.dart';

void main() {
  group('ClassFeatureUsageFormatter.format', () {
    test('null pour une aptitude passive (usesMax nul)', () {
      const feature = CharacterClassFeature(
        id: 1,
        name: 'Défense sans armure',
        level: 1,
      );

      expect(ClassFeatureUsageFormatter.format(feature), isNull);
    });

    test('"X / Y · repos long" pour un repos long', () {
      const feature = CharacterClassFeature(
        id: 2,
        name: 'Sens divin',
        level: 1,
        usesMax: 3,
        usesRemaining: 2,
        restType: 'repos_long',
      );

      expect(ClassFeatureUsageFormatter.format(feature), '2 / 3 · repos long');
    });

    test('"X / Y · repos court" pour un repos court', () {
      const feature = CharacterClassFeature(
        id: 3,
        name: 'Conduit divin',
        level: 2,
        usesMax: 1,
        usesRemaining: 1,
        restType: 'repos_court',
      );

      expect(ClassFeatureUsageFormatter.format(feature), '1 / 1 · repos court');
    });

    test('usesRemaining absent (aucune ligne character_feature_uses) retombe '
        'sur usesMax (rien encore consommé)', () {
      const feature = CharacterClassFeature(
        id: 4,
        name: 'Fougue guerrière',
        level: 2,
        usesMax: 1,
        restType: 'repos_court',
      );

      expect(ClassFeatureUsageFormatter.format(feature), '1 / 1 · repos court');
    });

    test('restType null retombe sur "repos court" plutôt que de crasher', () {
      const feature = CharacterClassFeature(
        id: 5,
        name: 'Aptitude sans restType renseigné',
        level: 1,
        usesMax: 2,
        usesRemaining: 1,
      );

      expect(ClassFeatureUsageFormatter.format(feature), '1 / 2 · repos court');
    });

    test('une valeur restType inattendue (ni repos_long ni repos_court, donnée '
        'serveur incohérente) retombe aussi sur "repos court" plutôt que '
        'd\'afficher la valeur brute non traduite', () {
      const feature = CharacterClassFeature(
        id: 6,
        name: 'Aptitude avec restType inconnu',
        level: 1,
        usesMax: 2,
        usesRemaining: 2,
        restType: 'valeur_inattendue',
      );

      expect(ClassFeatureUsageFormatter.format(feature), '2 / 2 · repos court');
    });
  });
}
