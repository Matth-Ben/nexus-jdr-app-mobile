import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/character_vital_status.dart';

void main() {
  group('CharacterVitalStatusResolver.resolve', () {
    test('PV > 0 et pas mort -> alive', () {
      expect(
        CharacterVitalStatusResolver.resolve(currentHp: 5, isDead: false),
        CharacterVitalStatus.alive,
      );
    });

    test('PV == 0 et pas mort -> unconscious', () {
      expect(
        CharacterVitalStatusResolver.resolve(currentHp: 0, isDead: false),
        CharacterVitalStatus.unconscious,
      );
    });

    test('isDead vrai, PV > 0 -> dead (prioritaire sur PV)', () {
      expect(
        CharacterVitalStatusResolver.resolve(currentHp: 12, isDead: true),
        CharacterVitalStatus.dead,
      );
    });

    test('isDead vrai et PV == 0 -> dead (jamais unconscious)', () {
      expect(
        CharacterVitalStatusResolver.resolve(currentHp: 0, isDead: true),
        CharacterVitalStatus.dead,
      );
    });

    test('PV négatifs (jamais attendu en pratique) traités comme <= 0', () {
      expect(
        CharacterVitalStatusResolver.resolve(currentHp: -3, isDead: false),
        CharacterVitalStatus.unconscious,
      );
    });
  });
}
