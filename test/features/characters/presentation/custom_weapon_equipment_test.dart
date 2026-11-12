// P7 PR 2b : arme personnalisée équipable, attaque et dégâts calculés —
// onglet Inventaire (équiper par set, panneau « Infos »), carte « ARMES
// ÉQUIPÉES », légendes, anglais et échelles de police x2,0/x3,0 sur 320 dp.
//
// Personnage : Guerrier niveau 5 (maîtrise +3), Force 16 (+3), Dex 18 (+4),
// maîtrises « courantes » et « martiales ».

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_equipped_weapons_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';

CharacterInventoryItem _weapon({
  String id = 'w',
  String name = 'Lame solaire',
  String? category = 'guerre',
  String? range = 'melee',
  int magic = 2,
  bool requiresAttunement = false,
  bool attuned = false,
  bool equipped = false,
  List<String> properties = const [],
  String? kind = 'arme',
}) => CharacterInventoryItem(
  id: id,
  name: name,
  quantity: 1,
  equipped: equipped,
  weaponSlot: equipped ? WeaponSlot.principal : null,
  customKind: kind,
  magicBonus: magic,
  requiresAttunement: requiresAttunement,
  customRequiresAttunement: requiresAttunement,
  isAttuned: attuned,
  customWeaponCategory: category,
  customWeaponRange: range,
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d8',
    damageType: 'radiant',
    properties: properties,
  ),
);

CharacterDetail _detail(List<CharacterInventoryItem> inventory) =>
    CharacterDetail(
      id: '1',
      name: 'Test',
      classes: const [
        CharacterDetailClassRow(
          classId: 1,
          className: 'Guerrier',
          level: 5,
          isPrimary: true,
          savingThrowProficiencies: [],
          hitDie: 10,
        ),
      ],
      xp: 0,
      currentHp: 10,
      maxHp: 10,
      temporaryHp: 0,
      abilityScores: const {'str': 16, 'dex': 18},
      weaponProficiencyNames: const ['courantes', 'martiales'],
      inventory: inventory,
    );

Widget _app(
  Widget body, {
  Locale locale = const Locale('fr'),
  double scale = 1,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: body),
);

void _view(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<List<String>> _pumpTab(
  WidgetTester tester,
  CharacterInventoryItem item, {
  Locale locale = const Locale('fr'),
}) async {
  _view(tester, const Size(390, 2400));
  final writes = <String>[];
  await tester.pumpWidget(
    _app(
      CharacterInventoryTabBody(
        detail: _detail([item]),
        onUseItem: (i) => writes.add('use'),
        onToggleItemEquipped: (i) => writes.add('toggle ${i.id}'),
        onToggleItemAttuned: (i) => writes.add('attune'),
        onRemoveItem: (i) => writes.add('remove'),
        onAdjustCurrency: (c, a) => writes.add('currency'),
        onAddInventoryItem: (i, q) => writes.add('add'),
        onAddCustomInventoryItem: (
          name,
          quantity, {
          description,
          damageDice,
          damageType,
          properties = const [],
          enrichment,
        }) => writes.add('addCustom'),
        onEquipWeaponToSlot: (i, s) => writes.add('equip ${i.id} ${s.name}'),
      ),
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
  return writes;
}

Future<void> _openInfo(
  WidgetTester tester,
  String name, {
  String infoLabel = 'Infos',
}) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text(infoLabel));
  await tester.pumpAndSettle();
}

Future<void> _pumpCard(
  WidgetTester tester,
  List<CharacterInventoryItem> weapons, {
  double scale = 1,
  Size size = const Size(390, 1600),
  Locale locale = const Locale('fr'),
}) async {
  _view(tester, size);
  await tester.pumpWidget(
    _app(
      SingleChildScrollView(
        child: CharacterEquippedWeaponsCard(
          weapons: weapons,
          abilityScores: const {'str': 16, 'dex': 18},
          proficiencyBonus: 3,
          weaponProficiencyNames: const ['courantes', 'martiales'],
        ),
      ),
      scale: scale,
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('équiper une arme personnalisée', () {
    testWidgets('« Équiper » propose les sets puis écrit le set choisi', (
      tester,
    ) async {
      final writes = await _pumpTab(tester, _weapon());
      await tester.tap(find.text('Lame solaire'));
      await tester.pumpAndSettle();

      expect(find.text('Équiper'), findsOneWidget);
      await tester.tap(find.text('Équiper'));
      await tester.pumpAndSettle();
      expect(find.text('Set secondaire'), findsOneWidget);

      await tester.tap(find.text('Set principal'));
      await tester.pumpAndSettle();
      expect(writes, ['equip w principal']);
    });

    testWidgets('équipée : « Changer de set » et « Déséquiper »', (
      tester,
    ) async {
      await _pumpTab(tester, _weapon(equipped: true));
      await tester.tap(find.text('Lame solaire'));
      await tester.pumpAndSettle();

      expect(find.text('Changer de set'), findsOneWidget);
      expect(find.text('Déséquiper'), findsOneWidget);
    });

    testWidgets('panneau « Infos » : aucun bouton bascule en pied (sets)', (
      tester,
    ) async {
      await _pumpTab(tester, _weapon());
      await _openInfo(tester, 'Lame solaire');

      expect(find.text('Équiper'), findsNothing);
    });

    testWidgets('objet « autre » : toujours pas équipable', (tester) async {
      await _pumpTab(
        tester,
        CharacterInventoryItem(
          id: 'o',
          name: 'Anneau étrange',
          quantity: 1,
          equipped: false,
          customKind: 'autre',
        ),
      );
      await tester.tap(find.text('Anneau étrange'));
      await tester.pumpAndSettle();

      expect(find.text('Équiper'), findsNothing);
    });
  });

  group('panneau « Infos » : attaque et dégâts', () {
    testWidgets('bonus +2 actif : Attaque +8 (dont +2 magique), 1d8+5', (
      tester,
    ) async {
      await _pumpTab(tester, _weapon());
      await _openInfo(tester, 'Lame solaire');

      // Force +3, maîtrise +3, bonus magique +2.
      expect(find.text('+8 (dont +2 magique)'), findsOneWidget);
      expect(find.text('1d8+5 radiant'), findsOneWidget);
      expect(find.text('Bonus magique'), findsOneWidget);
      expect(find.textContaining('Bonus magique inactif'), findsNothing);
    });

    testWidgets('bonus suspendu (non harmonisé) : sans bonus + légende', (
      tester,
    ) async {
      await _pumpTab(tester, _weapon(requiresAttunement: true));
      await _openInfo(tester, 'Lame solaire');

      expect(find.text('+6'), findsOneWidget);
      expect(find.text('1d8+3 radiant'), findsOneWidget);
      expect(find.textContaining('dont'), findsNothing);
      expect(
        find.text(
          "Bonus magique inactif tant que l'objet n'est pas harmonisé.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('harmonisé : bonus actif, pas de légende', (tester) async {
      await _pumpTab(tester, _weapon(requiresAttunement: true, attuned: true));
      await _openInfo(tester, 'Lame solaire');

      expect(find.text('+8 (dont +2 magique)'), findsOneWidget);
      expect(find.textContaining('Bonus magique inactif'), findsNothing);
    });

    testWidgets('portée à distance : Dextérité (+4)', (tester) async {
      await _pumpTab(tester, _weapon(range: 'distance', magic: 0));
      await _openInfo(tester, 'Lame solaire');

      expect(find.text('+7'), findsOneWidget);
      expect(find.text('1d8+4 radiant'), findsOneWidget);
    });

    testWidgets('catégorie et portée absentes : deux légendes, Force, '
        'aucune maîtrise', (tester) async {
      await _pumpTab(tester, _weapon(category: null, range: null, magic: 0));
      await _openInfo(tester, 'Lame solaire');

      expect(find.text('+3'), findsOneWidget);
      expect(find.text('1d8+3 radiant'), findsOneWidget);
      expect(find.textContaining('Maîtrise non évaluée'), findsOneWidget);
      expect(find.textContaining('Portée non précisée'), findsOneWidget);
    });

    testWidgets('ancien objet à dés sans type : arme calculée, non évaluée', (
      tester,
    ) async {
      await _pumpTab(
        tester,
        _weapon(kind: null, category: null, range: null, magic: 0),
      );
      await _openInfo(tester, 'Lame solaire');

      expect(find.text('+3'), findsOneWidget);
      expect(find.textContaining('Maîtrise non évaluée'), findsOneWidget);
    });

    testWidgets('anglais : « incl. +2 magic » et légendes traduites', (
      tester,
    ) async {
      await _pumpTab(
        tester,
        _weapon(category: null, range: null),
        locale: const Locale('en'),
      );
      await _openInfo(tester, 'Lame solaire', infoLabel: 'Info');

      expect(find.text('+5 (incl. +2 magic)'), findsOneWidget);
      expect(find.text('1d8+5 radiant'), findsOneWidget);
      expect(find.textContaining('Proficiency not evaluated'), findsOneWidget);
      expect(find.textContaining('Range not specified'), findsOneWidget);
    });
  });

  group('carte « ARMES ÉQUIPÉES »', () {
    testWidgets('attaque et dégâts avec le bonus magique', (tester) async {
      await _pumpCard(tester, [_weapon(equipped: true)]);

      expect(find.text('+8'), findsOneWidget);
      expect(find.text('1d8+5 radiant'), findsOneWidget);
      expect(find.text('Maîtrise non évaluée'), findsNothing);
    });

    testWidgets('bonus suspendu : attaque +6, dégâts 1d8+3', (tester) async {
      await _pumpCard(tester, [
        _weapon(equipped: true, requiresAttunement: true),
      ]);

      expect(find.text('+6'), findsOneWidget);
      expect(find.text('1d8+3 radiant'), findsOneWidget);
    });

    testWidgets('catégorie absente : mention « Maîtrise non évaluée »', (
      tester,
    ) async {
      await _pumpCard(tester, [
        _weapon(equipped: true, category: null, magic: 0),
      ]);

      expect(find.text('+3'), findsOneWidget);
      expect(find.text('Maîtrise non évaluée'), findsOneWidget);
    });

    testWidgets('anglais : mention traduite', (tester) async {
      await _pumpCard(tester, [
        _weapon(equipped: true, category: null),
      ], locale: const Locale('en'));

      expect(find.text('Proficiency not evaluated'), findsOneWidget);
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('x$scale sur 320 dp : sans débordement', (tester) async {
        await _pumpCard(
          tester,
          [
            _weapon(
              equipped: true,
              category: null,
              name: 'Lame solaire du soir',
            ),
          ],
          scale: scale,
          size: const Size(320, 2400),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Maîtrise non évaluée'), findsOneWidget);
      });

      testWidgets('x$scale sur 320 dp : panneau « Infos » sans '
          'débordement', (tester) async {
        _view(tester, const Size(320, 1800));
        await tester.pumpWidget(
          _app(
            CharacterInventoryTabBody(
              detail: _detail([
                _weapon(category: null, range: null, requiresAttunement: true),
              ]),
              onUseItem: (_) {},
              onToggleItemEquipped: (_) {},
              onToggleItemAttuned: (_) {},
              onRemoveItem: (_) {},
              onAdjustCurrency: (c, a) {},
              onAddInventoryItem: (i, q) {},
              onAddCustomInventoryItem: (
                name,
                quantity, {
                description,
                damageDice,
                damageType,
                properties = const [],
                enrichment,
              }) {},
              onEquipWeaponToSlot: (i, s) {},
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lame solaire'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Infos'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Maîtrise non évaluée'), findsOneWidget);
      });
    }
  });
}
