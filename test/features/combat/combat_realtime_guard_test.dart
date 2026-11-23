// Gardes du canal temps réel du combat : Nexus n'émet jamais sur un canal
// (il passe par `api_v1.send_to_group_leader`, émetteur garanti) et ne lit
// jamais la présence (réservée au meneur, décision 49). Le canal `:gm` est
// privé, avec la présence du joueur sous son `user_id`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/data/grimoire_combat_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_connectivity_checker.dart';

/// Appels interdits dans `lib/features/combat/` : émission directe sur un
/// canal (broadcast client ou REST) et lecture de la présence.
const _forbidden = [
  '.send(',
  'httpSend',
  'sendBroadcastMessage',
  'presenceState',
  'onPresence',
];

void main() {
  test('aucune émission directe ni lecture de présence dans le combat', () {
    final files = [
      for (final entity in Directory(
        'lib/features/combat',
      ).listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.endsWith('.g.dart') &&
            !entity.path.endsWith('.freezed.dart'))
          entity,
    ];
    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final forbidden in _forbidden) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: '${file.path} contient $forbidden',
        );
      }
    }
  });

  test(
    'openGmChannel : canal privé, présence activée sous le user_id',
    () async {
      // Client hors réseau : seule la configuration du canal est lue.
      final client = SupabaseClient('http://127.0.0.1:9', 'cle-publique-test');
      final connectivity = FakeConnectivityChecker();
      addTearDown(() async {
        await client.removeAllChannels();
        await client.dispose();
        await connectivity.close();
      });
      final gateway = SupabaseGrimoireCombatGateway(client, connectivity);

      final link = gateway.openGmChannel(
        topic: 'grimoire:v1:group:g-1:e3:gm',
        presenceKey: 'user-42',
        onBroadcast: (_) {},
        onSignal: (_) {},
      );

      final channel = client.getChannels().single;
      // `topic` et `params` (charge d'entrée réellement envoyée au serveur)
      // sont internes à `realtime_client` : seule façon de vérifier le canal
      // produit par `openGmChannel`.
      // ignore: invalid_use_of_internal_member
      expect(channel.topic, 'realtime:grimoire:v1:group:g-1:e3:gm');
      // ignore: invalid_use_of_internal_member
      final config = channel.params['config'] as Map<String, dynamic>;
      expect(config['private'], isTrue);
      final presence = config['presence'] as Map<String, dynamic>;
      expect(presence['key'], 'user-42');
      expect(presence['enabled'], isTrue);

      await link.close();
      expect(client.getChannels(), isEmpty);
    },
  );
}
