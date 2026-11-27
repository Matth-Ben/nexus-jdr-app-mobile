// Format des données d'ouverture des notifications de combat (`notify-group`,
// contrat DeepCore §5 ; combat natif V2, décision 59).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat_notification.dart';

const _group = '8f14e45f-ceea-4e1b-9d34-3c1a2b3c4d5e';

void main() {
  test('combat_start et your_turn : type et groupe', () {
    expect(
      parseCombatNotificationData({
        'v': '1',
        'type': 'combat_start',
        'group_id': _group,
      }),
      (type: CombatNotificationType.combatStart, groupId: _group),
    );
    expect(
      parseCombatNotificationData({
        'v': '1',
        'type': 'your_turn',
        'group_id': _group,
      }),
      (type: CombatNotificationType.yourTurn, groupId: _group),
    );
  });

  test('type inconnu (reveal, autre) : ignoré, mais reconnu comme format '
      'versionné', () {
    for (final type in ['reveal', 'turn_reminder', '']) {
      final data = {'v': '1', 'type': type, 'group_id': _group};
      expect(parseCombatNotificationData(data), isNull);
      expect(isVersionedNotificationData(data), isTrue);
    }
  });

  test('autre version, sans version, ancien format : jamais un combat', () {
    expect(
      parseCombatNotificationData({
        'v': '2',
        'type': 'your_turn',
        'group_id': _group,
      }),
      isNull,
    );
    expect(
      parseCombatNotificationData({'type': 'your_turn', 'group_id': _group}),
      isNull,
    );
    expect(parseCombatNotificationData({'characterId': 'c-1'}), isNull);
    expect(isVersionedNotificationData({'type': 'new_version'}), isFalse);
  });

  test('group_id absent ou qui n\'est pas un uuid : ignoré (jamais placé '
      'dans une route)', () {
    for (final groupId in [null, '', '../profile', 'group-1', 42]) {
      expect(
        parseCombatNotificationData({
          'v': '1',
          'type': 'combat_start',
          'group_id': ?groupId,
        }),
        isNull,
        reason: '$groupId',
      );
    }
  });
}
