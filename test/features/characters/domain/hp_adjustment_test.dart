import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/hp_adjustment.dart';

void main() {
  group('HpAdjustmentCalculator.applyDamage', () {
    test('sans PV temporaires, retranche directement de current_hp', () {
      const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 0);
      final result = HpAdjustmentCalculator.applyDamage(state, 5);
      expect(result, const HpState(currentHp: 15, maxHp: 30, temporaryHp: 0));
    });

    test(
      'les PV temporaires sont absorbés en premier, sans affecter current_hp',
      () {
        const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 5);
        final result = HpAdjustmentCalculator.applyDamage(state, 3);
        expect(result, const HpState(currentHp: 20, maxHp: 30, temporaryHp: 2));
      },
    );

    test(
      'le reliquat de dégâts non absorbé par les PV temporaires est retranché '
      'de current_hp',
      () {
        const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 5);
        final result = HpAdjustmentCalculator.applyDamage(state, 8);
        expect(result, const HpState(currentHp: 17, maxHp: 30, temporaryHp: 0));
      },
    );

    test('current_hp ne descend jamais sous 0', () {
      const state = HpState(currentHp: 5, maxHp: 30, temporaryHp: 0);
      final result = HpAdjustmentCalculator.applyDamage(state, 999);
      expect(result, const HpState(currentHp: 0, maxHp: 30, temporaryHp: 0));
    });

    test('dégâts supérieurs au cumul PV temporaires + PV actuels : les PV '
        'temporaires sont vidés ET current_hp retombe à 0, jamais négatif '
        '(cas limite explicitement demandé en revue QA, en plus des deux cas '
        'testés séparément ci-dessus qui n\'exercent jamais les deux "à bout" '
        'en même temps)', () {
      const state = HpState(currentHp: 10, maxHp: 30, temporaryHp: 5);
      final result = HpAdjustmentCalculator.applyDamage(state, 999);
      expect(result, const HpState(currentHp: 0, maxHp: 30, temporaryHp: 0));
    });

    test('un montant nul ou négatif ne change rien', () {
      const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 2);
      expect(HpAdjustmentCalculator.applyDamage(state, 0), state);
      expect(HpAdjustmentCalculator.applyDamage(state, -4), state);
    });
  });

  group('HpAdjustmentCalculator.applyHeal', () {
    test('additionne à current_hp sans dépasser max_hp', () {
      const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 0);
      final result = HpAdjustmentCalculator.applyHeal(state, 5);
      expect(result, const HpState(currentHp: 25, maxHp: 30, temporaryHp: 0));
    });

    test('plafonne à max_hp', () {
      const state = HpState(currentHp: 28, maxHp: 30, temporaryHp: 0);
      final result = HpAdjustmentCalculator.applyHeal(state, 50);
      expect(result, const HpState(currentHp: 30, maxHp: 30, temporaryHp: 0));
    });

    test('n\'affecte jamais temporary_hp', () {
      const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 4);
      final result = HpAdjustmentCalculator.applyHeal(state, 5);
      expect(result.temporaryHp, 4);
    });

    test('un montant nul ou négatif ne change rien', () {
      const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 0);
      expect(HpAdjustmentCalculator.applyHeal(state, 0), state);
      expect(HpAdjustmentCalculator.applyHeal(state, -1), state);
    });
  });

  group('HpAdjustmentCalculator.applyTemporaryHp', () {
    test('remplace temporary_hp si le nouveau montant est supérieur', () {
      const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 3);
      final result = HpAdjustmentCalculator.applyTemporaryHp(state, 8);
      expect(result, const HpState(currentHp: 20, maxHp: 30, temporaryHp: 8));
    });

    test('des PV temporaires à 0 sont bien remplacés par un nouveau montant '
        '(cas limite explicitement demandé en revue QA : 0 est un cas '
        'particulier de "nouveau montant supérieur" jamais exercé seul par les '
        'autres tests de ce groupe)', () {
      const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 0);
      final result = HpAdjustmentCalculator.applyTemporaryHp(state, 5);
      expect(result, const HpState(currentHp: 20, maxHp: 30, temporaryHp: 5));
    });

    test('ne change rien si le nouveau montant est inférieur ou égal (pas de '
        'cumul, RAW 5e)', () {
      const state = HpState(currentHp: 20, maxHp: 30, temporaryHp: 8);
      expect(HpAdjustmentCalculator.applyTemporaryHp(state, 5), state);
      expect(HpAdjustmentCalculator.applyTemporaryHp(state, 8), state);
    });
  });
}
