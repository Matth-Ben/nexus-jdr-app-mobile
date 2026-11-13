import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_snapshot.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

import '../../../support/combat_fixtures.dart';

List<String> ids(Iterable<dynamic> list) => [
  for (final p in list) p.id as String,
];

void main() {
  group('sortedForDisplay', () {
    test('initiative décroissante', () {
      final sorted = [
        fakeParticipant('a', initiative: 5, sortOrder: 1),
        fakeParticipant('b', initiative: 18, sortOrder: 2),
        fakeParticipant('c', initiative: 12, sortOrder: 3),
      ].sortedForDisplay;
      expect(ids(sorted), ['b', 'c', 'a']);
    });

    test(
      'initiative NULL en dernier, y compris devant un sort_order faible',
      () {
        final sorted = [
          fakeParticipant('nul', sortOrder: 1),
          fakeParticipant('neg', initiative: -3, sortOrder: 2),
          fakeParticipant('zero', initiative: 0, sortOrder: 3),
        ].sortedForDisplay;
        expect(ids(sorted), ['zero', 'neg', 'nul']);
      },
    );

    test('plusieurs NULL : ordonnés par sort_order croissant', () {
      final sorted = [
        fakeParticipant('b', sortOrder: 5),
        fakeParticipant('a', sortOrder: 2),
      ].sortedForDisplay;
      expect(ids(sorted), ['a', 'b']);
    });

    test('égalité : sort_order croissant fourni par le serveur '
        '(PJ avant PNJ, sinon ordre d\'arrivée)', () {
      final sorted = [
        fakeParticipant(
          'gob',
          initiative: 10,
          sortOrder: 4,
          kind: ParticipantKind.npc,
        ),
        fakeParticipant('pj', initiative: 10, sortOrder: 1),
        fakeParticipant(
          'gob2',
          initiative: 10,
          sortOrder: 5,
          kind: ParticipantKind.npc,
        ),
      ].sortedForDisplay;
      expect(ids(sorted), ['pj', 'gob', 'gob2']);
    });

    test('le client ne réordonne pas PJ/PNJ : seul sort_order compte', () {
      final sorted = [
        fakeParticipant('pj', initiative: 10, sortOrder: 9),
        fakeParticipant(
          'npc',
          initiative: 10,
          sortOrder: 2,
          kind: ParticipantKind.npc,
        ),
      ].sortedForDisplay;
      expect(ids(sorted), ['npc', 'pj']);
    });

    test('stable : clés identiques conservent l\'ordre fourni', () {
      final sorted = [
        fakeParticipant('x', initiative: 7, sortOrder: 3),
        fakeParticipant('y', initiative: 7, sortOrder: 3),
        fakeParticipant('z', initiative: 7, sortOrder: 3),
      ].sortedForDisplay;
      expect(ids(sorted), ['x', 'y', 'z']);
    });

    test('ne modifie pas la liste source', () {
      final source = [
        fakeParticipant('a', initiative: 1),
        fakeParticipant('b', initiative: 9),
      ];
      source.sortedForDisplay;
      expect(ids(source), ['a', 'b']);
    });
  });

  group('helpers de CombatSnapshot', () {
    final participants = [
      fakeParticipant('a', initiative: 10, sortOrder: 1),
      fakeParticipant('b', sortOrder: 2),
      fakeParticipant(
        'w',
        initiative: 4,
        sortOrder: 3,
        status: ParticipantStatus.waiting,
      ),
      fakeParticipant(
        'r',
        initiative: 20,
        sortOrder: 4,
        status: ParticipantStatus.removed,
      ),
    ];
    final snapshot = fakeSnapshot(participants: participants);

    test('actifs / en attente / retirés / affichés', () {
      expect(ids(snapshot.activeParticipants), ['a', 'b']);
      expect(ids(snapshot.waitingParticipants), ['w']);
      expect(ids(snapshot.removedParticipants), ['r']);
      expect(ids(snapshot.displayParticipants), ['a', 'w', 'b']);
    });

    test('compteur d\'initiatives sur les non retirés', () {
      expect(snapshot.initiativeProgress, (entered: 2, total: 3));
    });

    test('compteur vide', () {
      expect(fakeSnapshot().initiativeProgress, (entered: 0, total: 0));
    });

    test('tour en cours : NULL -> aucun', () {
      expect(snapshot.currentParticipant, isNull);
    });

    test('tour en cours : participant valide', () {
      final s = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'a'),
        participants: participants,
      );
      expect(s.currentParticipant?.id, 'a');
    });

    test('tour en cours : participant retiré ignoré', () {
      final s = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'r'),
        participants: participants,
      );
      expect(s.currentParticipant, isNull);
    });

    test('tour en cours : id inconnu ignoré', () {
      final s = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'zzz'),
        participants: participants,
      );
      expect(s.currentParticipant, isNull);
    });
  });

  group('membersWithoutRow', () {
    GroupMember member(String user, String? characterId, {bool gm = false}) =>
        GroupMember(
          userId: user,
          characterId: characterId,
          role: GroupRole.membre,
          name: user,
          isGameMaster: gm,
        );

    test('détecte les membres avec personnage sans ligne, ignore le MJ', () {
      final s = fakeSnapshot(
        participants: [
          fakeParticipant('p1', characterId: 'c1'),
          fakeParticipant(
            'p2',
            characterId: 'c2',
            status: ParticipantStatus.removed,
          ),
        ],
      );
      final missing = s.membersWithoutRow([
        member('u1', 'c1'),
        member('u2', 'c2'),
        member('u3', 'c3'),
        member('mj', null, gm: true),
        member('orphelin', null),
      ]);
      expect(missing.map((m) => m.userId), ['u3']);
    });
  });
}
