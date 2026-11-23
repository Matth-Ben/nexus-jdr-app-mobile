// Décodage des messages du MJ reçus sur `:gm` (contrat DeepCore §4.1, §4.2) :
// enveloppe, types, tolérance aux clés inconnues, contenu invalide.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/data/grimoire_error_mapper.dart';
import 'package:personnages/features/combat/data/grimoire_message_decoder.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/grimoire_failure.dart';
import 'package:personnages/features/combat/domain/grimoire_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/grimoire_fixtures.dart';

void main() {
  group('enveloppe', () {
    test('v différent de 1 : ignoré (null, non compté)', () {
      final message = {...gTurn(2, 'p-aria'), 'v': 2};
      expect(decodeGrimoireMessage(message), isNull);
    });

    test('combat_id ou seq absents, seq < 1 : ignoré', () {
      expect(
        decodeGrimoireMessage({...gTurn(2, 'p'), 'combat_id': null}),
        isNull,
      );
      expect(decodeGrimoireMessage({...gTurn(2, 'p')}..remove('seq')), isNull);
      expect(decodeGrimoireMessage({...gTurn(2, 'p'), 'seq': 0}), isNull);
    });

    test('channel_rotated : signal de la base, jamais un message du MJ', () {
      expect(isGrimoireChannelRotated(gRotated()), isTrue);
      expect(decodeGrimoireMessage(gRotated()), isNull);
      expect(isGrimoireChannelRotated(gTurn(2, 'p')), isFalse);
    });

    test('enveloppe Phoenix de realtime_client retirée', () {
      final inner = gTurn(3, 'p-aria');
      expect(
        unwrapGrimoireBroadcast({
          'type': 'broadcast',
          'event': 'turn',
          'payload': inner,
        }),
        inner,
      );
      expect(unwrapGrimoireBroadcast(inner), inner);
    });

    test('sent_at lu pour l\'affichage, seq entier même écrit 3.0', () {
      final message = decoded({...gTurn(3, 'p-aria'), 'seq': 3.0});
      expect(message.seq, 3);
      expect(message.sentAt, DateTime.parse(kSentAt));
    });

    test('type inconnu : enveloppe gardée (compte), contenu ignoré', () {
      final message = decoded(grimoireMessage('reveal_v2', seq: 4));
      expect(
        message,
        isA<GrimoireUnknownMessage>()
            .having((m) => m.type, 'type', 'reveal_v2')
            .having((m) => m.malformed, 'malformed', isFalse),
      );
    });

    test('clés inconnues ignorées (ajout compatible)', () {
      final message = decoded({...gTurn(5, 'p-aria'), 'hp': 3, 'extra': true});
      expect(message, isA<GrimoireTurn>());
    });
  });

  group('types', () {
    test('combat_start de préparation : liste vide, round 1', () {
      final message = decoded(gCombatStart(1)) as GrimoireCombatStart;
      expect(message.round, 1);
      expect(message.participants, isEmpty);
    });

    test('initiative_request : liste ou null (tous)', () {
      final list = decoded(
        gInitiativeRequest(2, ['c-player']),
      ) as GrimoireInitiativeRequest;
      expect(list.characterIds, ['c-player']);
      final all =
          decoded(gInitiativeRequest(3, null)) as GrimoireInitiativeRequest;
      expect(all.characterIds, isNull);
    });

    test('order : ordre du MJ conservé, participants publics complets', () {
      final message = decoded(
        gOrder(4, grimoireRoster(), current: 'p-gob', round: 2),
      ) as GrimoireOrder;
      expect(message.participants.map((p) => p.id), [
        'p-aria',
        'p-gob',
        'p-brun',
      ]);
      expect(message.participants[1].kind, ParticipantKind.npc);
      expect(message.participants[2].initiative, isNull);
      expect(message.currentParticipantId, 'p-gob');
      expect(message.round, 2);
    });

    test('statut waiting accepté, statut inconnu lu comme actif', () {
      final message = decoded(
        gOrder(4, [
          grimoireParticipant('a', status: 'waiting'),
          grimoireParticipant('b', status: 'paused'),
        ]),
      ) as GrimoireOrder;
      expect(message.participants[0].status, ParticipantStatus.waiting);
      expect(message.participants[1].status, ParticipantStatus.active);
    });

    test('nom non fiable : gardé tel quel, borné à 80 caractères', () {
      final message = decoded(
        gOrder(4, [grimoireParticipant('a', name: '<b>${'x' * 90}')]),
      ) as GrimoireOrder;
      expect(message.participants.single.name.length, 80);
      expect(message.participants.single.name, startsWith('<b>'));
    });

    test('turn, participant_removed, combat_end, state none', () {
      expect(decoded(gTurn(5, 'p-aria', round: 3)), isA<GrimoireTurn>());
      expect(
        decoded(gRemoved(6, 'p-gob')),
        isA<GrimoireParticipantRemoved>().having(
          (m) => m.participantId,
          'participantId',
          'p-gob',
        ),
      );
      expect(
        decoded(gEnd(7, rounds: 1, count: 0)),
        isA<GrimoireCombatEnd>().having(
          (m) => m.participantCount,
          'participantCount',
          0,
        ),
      );
      expect(
        decoded(gState(8, status: 'none')),
        isA<GrimoireState>().having((m) => m.active, 'active', isFalse),
      );
    });

    test('state actif : liste, tour, initiatives demandées', () {
      final message = decoded(
        gState(
          9,
          participants: grimoireRoster(),
          current: 'p-aria',
          requested: ['c-brun'],
          round: 3,
        ),
      ) as GrimoireState;
      expect(message.active, isTrue);
      expect(message.initiativeRequestedFor, ['c-brun']);
      expect(message.currentParticipantId, 'p-aria');
    });
  });

  group('contenu invalide : compté, état complet redemandé', () {
    for (final entry in {
      'participant sans nom': gOrder(4, [
        {...grimoireParticipant('a'), 'name': ''},
      ]),
      'kind inconnu': gOrder(4, [grimoireParticipant('a', kind: 'boss')]),
      'initiative hors bornes': gOrder(4, [
        grimoireParticipant('a', initiative: 61),
      ]),
      'round absent': grimoireMessage(
        'order',
        seq: 4,
        extra: {'participants': <Object>[]},
      ),
      'combat_end sans compte': grimoireMessage(
        'combat_end',
        seq: 4,
        extra: {'rounds': 2},
      ),
      'state avec statut inconnu': gState(4, status: 'paused'),
    }.entries) {
      test(entry.key, () {
        expect(
          decoded(entry.value),
          isA<GrimoireUnknownMessage>().having(
            (m) => m.malformed,
            'malformed',
            isTrue,
          ),
        );
      });
    }
  });

  group('erreurs api_v1 (contrat §6)', () {
    test('rate_limited : secondes lues dans details', () {
      final failure = mapGrimoirePostgrestError(
        const PostgrestException(
          message: 'rate_limited',
          code: 'P0001',
          details: '37',
        ),
      );
      expect(failure.kind, GrimoireFailureKind.rateLimited);
      expect(failure.retryAfterSeconds, 37);
    });

    test('API absente : PGRST106 et PGRST202 définitifs', () {
      for (final code in ['PGRST106', 'PGRST202']) {
        final failure = mapGrimoirePostgrestError(
          PostgrestException(message: 'Could not find', code: code),
        );
        expect(failure.kind, GrimoireFailureKind.unavailable, reason: code);
        expect(failure.rawMessage, code);
      }
    });

    test('codes stables : no_character, group_not_found, inconnu', () {
      expect(
        mapGrimoirePostgrestError(
          const PostgrestException(message: 'no_character', code: 'P0001'),
        ).kind,
        GrimoireFailureKind.noCharacter,
      );
      expect(
        mapGrimoirePostgrestError(
          const PostgrestException(message: 'group_not_found', code: 'P0002'),
        ).kind,
        GrimoireFailureKind.groupNotFound,
      );
      expect(
        mapGrimoirePostgrestError(
          const PostgrestException(message: 'message_not_sent', code: 'P0001'),
        ).kind,
        GrimoireFailureKind.other,
      );
      expect(
        mapGrimoireUnknownError(StateError('x')).kind,
        GrimoireFailureKind.other,
      );
    });
  });
}
