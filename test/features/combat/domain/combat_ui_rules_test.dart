// Règles pures utilisées par l'écran Combat : égalités/réordonnancement,
// saisie d'initiative, numérotation des monstres, garde du propriétaire.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_permissions.dart';
import 'package:personnages/features/combat/domain/combat_reorder.dart';
import 'package:personnages/features/combat/domain/initiative_input.dart';
import 'package:personnages/features/combat/domain/monster_numbering.dart';

import '../../../support/combat_fixtures.dart';

void main() {
  group('égalités et réordonnancement', () {
    test('pas d\'égalité : mode Réordonner indisponible', () {
      final snapshot = fakeSnapshot(
        participants: [
          fakeParticipant('a', initiative: 10),
          fakeParticipant('b', initiative: 8, sortOrder: 2),
          fakeParticipant('c', sortOrder: 3),
          fakeParticipant('d', sortOrder: 4),
        ],
      );
      // Deux participants sans initiative ne sont pas une égalité.
      expect(hasInitiativeTies(snapshot), isFalse);
    });

    test('une égalité sur une initiative saisie est détectée', () {
      final snapshot = fakeSnapshot(
        participants: [
          fakeParticipant('a', initiative: 10),
          fakeParticipant('b', initiative: 10, sortOrder: 2),
        ],
      );
      expect(hasInitiativeTies(snapshot), isTrue);
    });

    test('un participant retiré ne crée pas d\'égalité', () {
      final snapshot = fakeSnapshot(
        participants: [
          fakeParticipant('a', initiative: 10),
          fakeParticipant(
            'b',
            initiative: 10,
            sortOrder: 2,
            status: ParticipantStatus.removed,
          ),
        ],
      );
      expect(hasInitiativeTies(snapshot), isFalse);
    });

    test('voisin : seulement à égalité, jamais aux limites du bloc', () {
      final displayed = fakeSnapshot(
        participants: [
          fakeParticipant('a', initiative: 12),
          fakeParticipant('b', initiative: 10, sortOrder: 2),
          fakeParticipant('c', initiative: 10, sortOrder: 3),
          fakeParticipant('d', initiative: 10, sortOrder: 4),
          fakeParticipant('e', initiative: 4, sortOrder: 5),
        ],
      ).displayParticipants;
      expect(displayed.map((p) => p.id), ['a', 'b', 'c', 'd', 'e']);
      expect(reorderNeighbor(displayed, 0, up: false), isNull);
      expect(reorderNeighbor(displayed, 1, up: true), isNull);
      expect(reorderNeighbor(displayed, 1, up: false)?.id, 'c');
      expect(reorderNeighbor(displayed, 2, up: true)?.id, 'b');
      expect(reorderNeighbor(displayed, 2, up: false)?.id, 'd');
      expect(reorderNeighbor(displayed, 3, up: false), isNull);
      expect(reorderNeighbor(displayed, 4, up: true), isNull);
      expect(reorderNeighbor(displayed, 0, up: true), isNull);
      expect(reorderNeighbor(displayed, 9, up: true), isNull);
    });
  });

  group('saisie d\'initiative', () {
    InitiativeInputStatus status(String raw) =>
        parseInitiativeInput(raw).status;

    test('vide, valide, invalide', () {
      expect(status(''), InitiativeInputStatus.empty);
      expect(status('  '), InitiativeInputStatus.empty);
      expect(parseInitiativeInput('14').value, 14);
      expect(parseInitiativeInput('-20').value, -20);
      expect(parseInitiativeInput('−5').value, -5);
      expect(parseInitiativeInput('60').value, 60);
      expect(parseInitiativeInput('+3').value, 3);
      expect(status('61'), InitiativeInputStatus.invalid);
      expect(status('-21'), InitiativeInputStatus.invalid);
      expect(status('abc'), InitiativeInputStatus.invalid);
      expect(status('1.5'), InitiativeInputStatus.invalid);
      expect(status('-'), InitiativeInputStatus.invalid);
    });

    test('compteur : vide donne 10, sinon ±1 borné', () {
      expect(stepInitiative(parseInitiativeInput(''), 1), 10);
      expect(stepInitiative(parseInitiativeInput('x'), -1), 10);
      expect(stepInitiative(parseInitiativeInput('7'), 1), 8);
      expect(stepInitiative(parseInitiativeInput('60'), 1), 60);
      expect(stepInitiative(parseInitiativeInput('-20'), -1), -20);
    });
  });

  group('numérotation des monstres', () {
    test('N = 1 : nom sans suffixe', () {
      expect(monsterNames('  Gobelin ', 1), ['Gobelin']);
    });

    test('N > 1 : Gobelin 1..N', () {
      expect(monsterNames('Gobelin', 3), [
        'Gobelin 1',
        'Gobelin 2',
        'Gobelin 3',
      ]);
    });

    test('collision : continue après le plus grand suffixe existant', () {
      expect(
        monsterNames(
          'Gobelin',
          2,
          existingNames: ['Gobelin 1', 'Gobelin 4', 'Orc 9', 'Gobelin'],
        ),
        ['Gobelin 5', 'Gobelin 6'],
      );
    });

    test('un nom avec caractères spéciaux est échappé', () {
      expect(monsterNames('Orc (chef)', 2, existingNames: ['Orc (chef) 3']), [
        'Orc (chef) 4',
        'Orc (chef) 5',
      ]);
    });
  });

  test('garde : seul le propriétaire est bloqué pendant un combat actif', () {
    expect(
      isLeaveBlockedByCombat(isOwner: true, hasActiveCombat: true),
      isTrue,
    );
    expect(
      isLeaveBlockedByCombat(isOwner: true, hasActiveCombat: false),
      isFalse,
    );
    expect(
      isLeaveBlockedByCombat(isOwner: false, hasActiveCombat: true),
      isFalse,
    );
  });
}
