// T8 : texte des alertes de conflit (FR et EN), troncature, repli tolérant.
// Fonction pure `syncAlertMessage` : testée directement sur les classes de
// localisation (pas de widget).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/sync/sync_alert_payload.dart';
import 'package:personnages/core/widgets/sync_status_banner.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

SyncAlert _alert(
  String dataKind,
  Map<String, dynamic>? value, {
  String name = 'Aria',
  SyncAlertKind kind = SyncAlertKind.conflict,
}) => SyncAlert(
  id: 1,
  ownerId: 'o',
  kind: kind,
  characterId: 'c',
  characterName: name,
  dataKind: dataKind,
  serverValue: value,
  createdAt: DateTime.utc(2026, 11, 11),
);

Map<String, dynamic> _hp({
  int server = 12,
  int queued = 5,
  int serverTemp = 0,
  int queuedTemp = 0,
  int? max = 30,
}) => {
  'currentHp': server,
  'temporaryHp': serverTemp,
  'maxHp': max,
  'queued': {'currentHp': queued, 'temporaryHp': queuedTemp},
};

Map<String, dynamic> _items(List<List<Object?>> rows) => {
  'items': [
    for (var i = 0; i < rows.length; i++)
      {
        'id': 'l$i',
        'name': rows[i][0],
        'server': rows[i][1],
        'queued': rows[i][2],
      },
  ],
};

void main() {
  final fr = AppLocalizationsFr();
  final en = AppLocalizationsEn();

  String f(SyncAlert a) => syncAlertMessage(fr, a);
  String e(SyncAlert a) => syncAlertMessage(en, a);

  group('PV (R1, R2)', () {
    test('serveur/max et appliquée/max, FR et EN', () {
      expect(
        f(_alert('hp', _hp())),
        'Aria : les PV ont été modifiés sur un autre appareil (serveur : '
        '12/30). Ta modification hors ligne (5/30) les a remplacés.',
      );
      expect(
        e(_alert('hp', _hp())),
        'Aria: HP were changed on another device (server: 12/30). Your '
        'offline change (5/30) replaced them.',
      );
    });

    test('max inconnu : variante sans « /max »', () {
      expect(
        f(_alert('hp', _hp(max: null))),
        'Aria : les PV ont été modifiés sur un autre appareil (serveur : 12). '
        'Ta modification hors ligne (5) les a remplacés.',
      );
    });

    test('PV temporaires > 0 : « + t temp. » sur chaque valeur concernée', () {
      final both = f(_alert('hp', _hp(serverTemp: 3, queuedTemp: 2)));
      expect(both, contains('(serveur : 12/30 + 3 temp.)'));
      expect(both, contains('(5/30 + 2 temp.)'));
      final one = e(_alert('hp', _hp(serverTemp: 3)));
      expect(one, contains('(server: 12/30 + 3 temp.)'));
      expect(one, contains('Your offline change (5/30)'));
    });

    test('seuls les PV temporaires diffèrent : texte « PV temporaires »', () {
      final value = _hp(server: 8, queued: 8, serverTemp: 5);
      expect(
        f(_alert('hp', value)),
        'Aria : les PV temporaires ont été modifiés sur un autre appareil '
        '(serveur : 5). Ta modification hors ligne (0) les a remplacés.',
      );
      expect(
        e(_alert('hp', value)),
        'Aria: temporary HP were changed on another device (server: 5). Your '
        'offline change (0) replaced them.',
      );
    });
  });

  group('monnaies (R3)', () {
    test('seulement les pièces en conflit, ordre pc, pa, pe, po, pp', () {
      final value = {
        'currency_pp': 1,
        'currency_gp': 120,
        'currency_sp': 4,
        'queued': {'currency_gp': 85, 'currency_sp': 10, 'currency_pp': 0},
      };
      expect(
        f(_alert('currency', value)),
        'Aria : tes pièces ont été modifiées sur un autre appareil (serveur : '
        '4 PA, 120 PO, 1 PP). Ta modification hors ligne (10 PA, 85 PO, 0 PP) '
        'les a remplacées.',
      );
      expect(
        e(_alert('currency', value)),
        'Aria: your coins were changed on another device (server: 4 SP, 120 '
        'GP, 1 PP). Your offline change (10 SP, 85 GP, 0 PP) replaced them.',
      );
    });

    test('une seule monnaie', () {
      final value = {
        'currency_gp': 120,
        'queued': {'currency_gp': 85},
      };
      final text = f(_alert('currency', value));
      expect(text, contains('(serveur : 120 PO)'));
      expect(text, contains('(85 PO)'));
    });

    test('un total appliqué sans total serveur est ignoré (mêmes '
        'longueurs)', () {
      final value = {
        'currency_gp': 120,
        'queued': {'currency_gp': 85, 'currency_cp': 3},
      };
      final text = f(_alert('currency', value));
      expect(text, contains('(serveur : 120 PO)'));
      expect(text, contains('(85 PO)'));
    });
  });

  group('objets (R4)', () {
    test('un objet : texte détaillé', () {
      final value = _items([
        ['Potion de soin', 5, 4],
      ]);
      expect(
        f(_alert('inventory_item', value)),
        'Aria : la quantité de « Potion de soin » a été modifiée sur un autre '
        "appareil (serveur : 5). Ta modification hors ligne (4) l'a "
        'remplacée.',
      );
      expect(
        e(_alert('inventory_item', value)),
        'Aria: the quantity of “Potion de soin” was changed on another device '
        '(server: 5). Your offline change (4) replaced it.',
      );
    });

    test('deux objets : deux noms, pas de suffixe', () {
      final value = _items([
        ['Corde', 1, 0],
        ['Torche', 3, 2],
      ]);
      expect(
        f(_alert('inventory_item', value)),
        'Aria : les quantités de « Corde » et « Torche » ont été modifiées sur '
        'un autre appareil. Tes modifications hors ligne les ont remplacées.',
      );
    });

    test('quatre objets : deux noms et « (+2 autres) » ; trois : « (+1 '
        'autre) »', () {
      final four = _items([
        ['A', 1, 0],
        ['B', 1, 0],
        ['C', 1, 0],
        ['D', 1, 0],
      ]);
      expect(
        f(_alert('inventory_item', four)),
        'Aria : les quantités de « A » et « B » ont été modifiées sur un '
        'autre appareil (+2 autres). Tes modifications hors ligne les ont '
        'remplacées.',
      );
      expect(
        e(_alert('inventory_item', four)),
        'Aria: the quantities of “A” and “B” were changed on another device '
        '(+2 more). Your offline changes replaced them.',
      );
      final three = _items([
        ['A', 1, 0],
        ['B', 1, 0],
        ['C', 1, 0],
      ]);
      expect(f(_alert('inventory_item', three)), contains('(+1 autre)'));
    });

    test('nom d\'objet coupé à 24, ou 20 si le texte dépasse ~150 '
        'caractères', () {
      final long = 'X' * 40;
      final value = _items([
        [long, 5, 4],
      ]);
      expect(f(_alert('inventory_item', value)), contains('« ${'X' * 24}… »'));
      final text = f(_alert('inventory_item', value, name: 'N' * 24));
      expect(text.length, greaterThan(150));
      expect(text, contains('« ${'X' * 20}… »'));
      expect(text, isNot(contains('X' * 21)));
    });

    test('nom d\'objet inconnu : repli', () {
      final value = _items([
        [null, 5, 4],
      ]);
      expect(
        f(_alert('inventory_item', value)),
        'Aria a été modifié sur un autre appareil. Ta modification hors ligne '
        'a été appliquée par-dessus.',
      );
    });
  });

  group('XP', () {
    test('texte FR et EN', () {
      final value = {'xp': 900, 'queued': 1200};
      expect(
        f(_alert('xp', value)),
        "Aria : l'XP a été modifiée sur un autre appareil (serveur : 900 XP). "
        "Ta modification hors ligne (1200 XP) l'a remplacée.",
      );
      expect(
        e(_alert('xp', value)),
        'Aria: XP was changed on another device (server: 900 XP). Your '
        'offline change (1200 XP) replaced it.',
      );
    });
  });

  group('nom du personnage (R5)', () {
    test('32 caractères : coupé à 24 + « … » dans le texte', () {
      final text = f(_alert('hp', _hp(), name: 'B' * 32));
      expect(text, startsWith('${'B' * 24}… :'));
      expect(text, isNot(contains('B' * 25)));
    });

    test('24 caractères : intact', () {
      expect(
        f(_alert('hp', _hp(), name: 'B' * 24)),
        startsWith('${'B' * 24} :'),
      );
    });

    test('émojis et accents jamais coupés au milieu', () {
      const family = '👨‍👩‍👧';
      final name = '${'é' * 23}$family$family';
      expect(
        f(_alert('hp', _hp(), name: name)),
        startsWith('${'é' * 23}$family… :'),
      );
      final combining = 'é' * 30;
      expect(truncateForAlert(combining, 24), '${'é' * 24}…');
    });

    test('nom vide : « ce personnage »', () {
      expect(f(_alert('hp', _hp(), name: '')), startsWith('ce personnage :'));
    });
  });

  group('repli (R6)', () {
    final cases = <String, (String, Map<String, dynamic>?)>{
      'hp sans queued (ancienne ligne)': ('hp', {'currentHp': 7, 'maxHp': 12}),
      'hp vide': ('hp', {}),
      'hp null': ('hp', null),
      'monnaies sans queued': ('currency', {'currency_gp': 50}),
      'objets non liste': ('inventory_item', {'items': 'x'}),
      'objets vide': ('inventory_item', {'items': []}),
      'xp sans queued': ('xp', {'xp': 3}),
    };
    for (final entry in cases.entries) {
      test(entry.key, () {
        final a = _alert(entry.value.$1, entry.value.$2);
        expect(
          f(a),
          'Aria a été modifié sur un autre appareil. Ta modification hors '
          'ligne a été appliquée par-dessus.',
        );
        expect(
          e(a),
          'Aria was changed on another device. Your offline change was '
          'applied on top.',
        );
      });
    }

    test('kind sans texte dédié et valeurs de mauvais type : repli sans '
        'exception', () {
      expect(f(_alert('spell_slot', {'level': 1})), contains('autre appareil'));
      expect(
        f(_alert('hp', {'currentHp': 'x', 'queued': 4})),
        contains('autre appareil'),
      );
    });
  });

  test('mergeConflictValue : ancienne valeur serveur, dernière appliquée', () {
    final merged = mergeConflictValue(
      'xp',
      {'xp': 1, 'queued': 2},
      {'xp': 9, 'queued': 3},
    );
    expect(merged, {'xp': 1, 'queued': 3});
  });

  test('les clés de conflit existent en FR et en EN', () {
    for (final l10n in <AppLocalizations>[fr, en]) {
      expect(l10n.syncAlertConflictHp('a', 'b', 'c'), isNotEmpty);
      expect(l10n.syncAlertConflictTempHp('a', 1, 2), isNotEmpty);
      expect(l10n.syncAlertConflictCurrency('a', 'b', 'c'), isNotEmpty);
      expect(l10n.syncAlertConflictItem('a', 'b', 1, 2), isNotEmpty);
      expect(l10n.syncAlertConflictItems('a', 'b', 'c', 0), isNotEmpty);
      expect(l10n.syncAlertConflictXp('a', 1, 2), isNotEmpty);
    }
  });
}
