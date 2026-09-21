import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/warlock_pact.dart';
import 'package:personnages/features/characters/domain/warlock_pact_rewards.dart';

void main() {
  group('WarlockPactRewards.cantripQuotaFor', () {
    test('3 sorts mineurs pour le grimoire, 0 sinon', () {
      expect(WarlockPactRewards.cantripQuotaFor(WarlockPact.tome), 3);
      expect(WarlockPactRewards.cantripQuotaFor(WarlockPact.chain), 0);
      expect(WarlockPactRewards.cantripQuotaFor(WarlockPact.blade), 0);
      expect(WarlockPactRewards.cantripQuotaFor(null), 0);
    });
  });

  group('WarlockPactRewards.availableCantrips', () {
    test('exclut les sorts mineurs deja connus', () {
      final result = WarlockPactRewards.availableCantrips<int>(
        [1, 2, 3, 4],
        idOf: (id) => id,
        knownSpellIds: {2, 4, 99},
      );
      expect(result, [1, 3]);
    });
  });

  group('WarlockPactRewards.spellIdsToAdd', () {
    test('grimoire : les sorts mineurs choisis, tronques a 3', () {
      expect(
        WarlockPactRewards.spellIdsToAdd(
          pact: WarlockPact.tome,
          chosenCantripIds: [1, 2, 3, 4],
          familiarSpellId: 50,
          knownSpellIds: {},
        ),
        [1, 2, 3],
      );
    });

    test('chaine : Appel de familier, jamais les sorts mineurs', () {
      expect(
        WarlockPactRewards.spellIdsToAdd(
          pact: WarlockPact.chain,
          chosenCantripIds: [1, 2, 3],
          familiarSpellId: 50,
          knownSpellIds: {},
        ),
        [50],
      );
    });

    test('chaine : sort introuvable (id null), rien n\'est ajoute', () {
      expect(
        WarlockPactRewards.spellIdsToAdd(
          pact: WarlockPact.chain,
          chosenCantripIds: const [],
          familiarSpellId: null,
          knownSpellIds: {},
        ),
        isEmpty,
      );
    });

    test('lame ou aucun pacte : rien', () {
      for (final pact in [WarlockPact.blade, null]) {
        expect(
          WarlockPactRewards.spellIdsToAdd(
            pact: pact,
            chosenCantripIds: [1, 2, 3],
            familiarSpellId: 50,
            knownSpellIds: {},
          ),
          isEmpty,
        );
      }
    });

    test(
      'pas de doublon : deja connu ou deja prevu dans la montee de niveau',
      () {
        expect(
          WarlockPactRewards.spellIdsToAdd(
            pact: WarlockPact.chain,
            chosenCantripIds: const [],
            familiarSpellId: 50,
            knownSpellIds: {50},
          ),
          isEmpty,
        );
        expect(
          WarlockPactRewards.spellIdsToAdd(
            pact: WarlockPact.tome,
            chosenCantripIds: [1, 2, 2, 3],
            familiarSpellId: null,
            knownSpellIds: {1},
            alreadyPlannedSpellIds: {3},
          ),
          [2],
        );
      },
    );
  });

  group('WarlockPactRewards.willAddFamiliar', () {
    test('chaine + sort resolu et inconnu uniquement', () {
      expect(
        WarlockPactRewards.willAddFamiliar(
          pact: WarlockPact.chain,
          familiarSpellId: 50,
          knownSpellIds: {},
        ),
        isTrue,
      );
      expect(
        WarlockPactRewards.willAddFamiliar(
          pact: WarlockPact.chain,
          familiarSpellId: 50,
          knownSpellIds: {50},
        ),
        isFalse,
      );
      expect(
        WarlockPactRewards.willAddFamiliar(
          pact: WarlockPact.chain,
          familiarSpellId: null,
          knownSpellIds: {},
        ),
        isFalse,
      );
      expect(
        WarlockPactRewards.willAddFamiliar(
          pact: WarlockPact.tome,
          familiarSpellId: 50,
          knownSpellIds: {},
        ),
        isFalse,
      );
    });
  });
}
