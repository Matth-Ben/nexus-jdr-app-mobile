import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_participant.dart';
import 'package:personnages/features/combat/domain/combat_permissions.dart';
import 'package:personnages/features/combat/domain/combat_player_input.dart';
import 'package:personnages/features/combat/domain/combat_reorder.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

import '../../../support/combat_fixtures.dart';

const _owner = 'owner-1';
const _me = 'player-1';
const _other = 'player-2';

GroupMember _member(
  String userId, {
  String? characterId,
  bool gm = false,
  GroupRole role = GroupRole.membre,
}) => GroupMember(
  userId: userId,
  characterId: characterId,
  role: role,
  name: userId,
  isGameMaster: gm,
);

GroupDetail _group({
  String currentUserId = _me,
  bool masterAbsent = false,
  String? myCharacter = 'c-me',
  bool meGameMaster = false,
}) => GroupDetail(
  id: 'group-1',
  name: 'Les Braves',
  ownerId: _owner,
  inviteCode: 'ABC',
  currentUserId: currentUserId,
  members: [
    if (!masterAbsent) _member(_owner, gm: true, role: GroupRole.owner),
    _member(_me, characterId: myCharacter, gm: meGameMaster),
    _member(_other, characterId: 'c-other'),
  ],
);

CombatParticipant _row(
  String id, {
  required String userId,
  required String characterId,
  ParticipantStatus status = ParticipantStatus.active,
  int? initiative,
}) => fakeParticipant(
  id,
  characterId: characterId,
  status: status,
  initiative: initiative,
).copyWith(userId: userId);

void main() {
  group('playerInitiativeStatus', () {
    test('joueur avec sa ligne : allowed + la ligne', () {
      final mine = _row('me', userId: _me, characterId: 'c-me');
      final status = playerInitiativeStatus(
        fakeSnapshot(participants: [mine]),
        _group(),
      );
      expect(status.access, PlayerInitiativeAccess.allowed);
      expect(status.row?.id, 'me');
    });

    test('ligne absente (arrivé après le lancement) : allowed sans ligne', () {
      final status = playerInitiativeStatus(
        fakeSnapshot(
          participants: [_row('o', userId: _other, characterId: 'c-other')],
        ),
        _group(),
      );
      expect(status.access, PlayerInitiativeAccess.allowed);
      expect(status.row, isNull);
      expect(shouldOfferFirstInitiative(status), isTrue);
    });

    test('ligne retirée : removed, jamais de saisie ni d offre', () {
      final removed = _row(
        'me',
        userId: _me,
        characterId: 'c-me',
        status: ParticipantStatus.removed,
      );
      final status = playerInitiativeStatus(
        fakeSnapshot(participants: [removed]),
        _group(),
      );
      expect(status.access, PlayerInitiativeAccess.removed);
      expect(wasRemovedFromCombat(status), isTrue);
      expect(isOwnEditableRow(status, removed), isFalse);
      expect(shouldOfferFirstInitiative(status), isFalse);
    });

    test('personnage changé A→B→A : seule la ligne du personnage courant '
        'compte', () {
      final oldCharacter = _row(
        'b',
        userId: _me,
        characterId: 'c-old',
        status: ParticipantStatus.removed,
      );
      final status = playerInitiativeStatus(
        fakeSnapshot(participants: [oldCharacter]),
        _group(),
      );
      // Le personnage courant (c-me) n'a pas de ligne : saisie permise.
      expect(status.access, PlayerInitiativeAccess.allowed);
      expect(status.row, isNull);
      // Et sa ligne retirée, elle, bloque.
      final current = _row(
        'a',
        userId: _me,
        characterId: 'c-me',
        status: ParticipantStatus.removed,
      );
      expect(
        playerInitiativeStatus(
          fakeSnapshot(participants: [oldCharacter, current]),
          _group(),
        ).access,
        PlayerInitiativeAccess.removed,
      );
    });

    test('MJ absent : masterAbsent (lecture seule), ligne conservée', () {
      final mine = _row('me', userId: _me, characterId: 'c-me');
      final status = playerInitiativeStatus(
        fakeSnapshot(participants: [mine]),
        _group(masterAbsent: true),
      );
      expect(status.access, PlayerInitiativeAccess.masterAbsent);
      expect(status.row?.id, 'me');
      expect(isOwnEditableRow(status, mine), isTrue);
      expect(shouldOfferFirstInitiative(status), isFalse);
    });

    test('MJ absent sans ligne : l offre existe (désactivée par l UI)', () {
      final status = playerInitiativeStatus(
        fakeSnapshot(),
        _group(masterAbsent: true),
      );
      expect(status.access, PlayerInitiativeAccess.masterAbsent);
      expect(shouldOfferFirstInitiative(status), isTrue);
    });

    test('propriétaire (MJ) : jamais joueur', () {
      final status = playerInitiativeStatus(
        fakeSnapshot(),
        _group(currentUserId: _owner),
      );
      expect(status.access, PlayerInitiativeAccess.notAPlayer);
      expect(shouldOfferFirstInitiative(status), isFalse);
    });

    test('membre MJ non propriétaire : jamais joueur', () {
      expect(
        playerInitiativeStatus(
          fakeSnapshot(),
          _group(meGameMaster: true, myCharacter: null),
        ).access,
        PlayerInitiativeAccess.notAPlayer,
      );
    });

    test('non-membre : jamais joueur', () {
      expect(
        playerInitiativeStatus(
          fakeSnapshot(),
          _group(currentUserId: 'inconnu'),
        ).access,
        PlayerInitiativeAccess.notAPlayer,
      );
    });

    test('membre sans personnage : noCharacter, aucune offre', () {
      final status = playerInitiativeStatus(
        fakeSnapshot(),
        _group(myCharacter: null),
      );
      expect(status.access, PlayerInitiativeAccess.noCharacter);
      expect(shouldOfferFirstInitiative(status), isFalse);
    });
  });

  group('isOwnEditableRow', () {
    test('jamais la ligne d un autre joueur ni d un PNJ', () {
      final mine = _row('me', userId: _me, characterId: 'c-me');
      final other = _row('o', userId: _other, characterId: 'c-other');
      final npc = fakeParticipant('n', kind: ParticipantKind.npc);
      final status = playerInitiativeStatus(
        fakeSnapshot(participants: [mine, other, npc]),
        _group(),
      );
      expect(isOwnEditableRow(status, mine), isTrue);
      expect(isOwnEditableRow(status, other), isFalse);
      expect(isOwnEditableRow(status, npc), isFalse);
    });

    test('propriétaire : aucune ligne n est « la sienne » côté joueur', () {
      final status = playerInitiativeStatus(
        fakeSnapshot(
          participants: [_row('me', userId: _me, characterId: 'c-me')],
        ),
        _group(currentUserId: _owner),
      );
      expect(
        isOwnEditableRow(status, _row('me', userId: _me, characterId: 'c-me')),
        isFalse,
      );
    });
  });

  group('prédicats déplacés depuis l écran', () {
    final snapshot = fakeSnapshot(
      participants: [
        fakeParticipant('a', initiative: 5),
        fakeParticipant(
          'r',
          initiative: 3,
          sortOrder: 2,
          status: ParticipantStatus.removed,
        ),
        fakeParticipant('b', sortOrder: 3),
      ],
    );

    test('removedVisibleTo : seulement pour le propriétaire', () {
      expect(snapshot.removedVisibleTo(isOwner: true).map((p) => p.id), ['r']);
      expect(snapshot.removedVisibleTo(isOwner: false), isEmpty);
    });

    test('summaryParticipantCount : tous sauf les retirés', () {
      expect(snapshot.summaryParticipantCount, 2);
    });

    test('swapSortOrderWith : prend la place du voisin', () {
      expect(swapSortOrderWith(fakeParticipant('n', sortOrder: 7)), 7);
    });

    group('canPilotCombat', () {
      GroupDetail detail({
        required bool owner,
        required bool ownerIsGm,
        bool ownerPresent = true,
      }) => GroupDetail(
        id: 'g',
        name: 'G',
        ownerId: _owner,
        inviteCode: 'X',
        currentUserId: owner ? _owner : _me,
        members: [
          if (ownerPresent)
            _member(
              _owner,
              gm: ownerIsGm,
              characterId: ownerIsGm ? null : 'c',
              role: GroupRole.owner,
            ),
          _member(_me, characterId: 'c-me'),
        ],
      );

      test('MJ propriétaire : oui, sauf lecture seule', () {
        final group = detail(owner: true, ownerIsGm: true);
        expect(canPilotCombat(group), isTrue);
        expect(canPilotCombat(group, readOnly: true), isFalse);
      });

      test('cohérent avec canStartCombat pour un propriétaire', () {
        for (final isGm in [true, false]) {
          final group = detail(owner: true, ownerIsGm: isGm);
          expect(canPilotCombat(group), canStartCombat(group));
        }
      });

      test('propriétaire qui joue (sans ligne MJ) : non', () {
        expect(canPilotCombat(detail(owner: true, ownerIsGm: false)), isFalse);
      });

      test('MJ absent : non', () {
        expect(
          canPilotCombat(
            detail(owner: true, ownerIsGm: true, ownerPresent: false),
          ),
          isFalse,
        );
      });

      test('joueur : non', () {
        expect(canPilotCombat(detail(owner: false, ownerIsGm: true)), isFalse);
      });
    });
  });
}
