// P7 PR 2 : affichage d'un objet personnalisé enrichi — carte d'inventaire
// (sous-titre, pastille de bonus magique, icône d'harmonisation), panneau
// « Infos » (type, poids, bonus, harmonisation, légende) et feuille d'actions
// (harmonisation d'un objet personnalisé). Un objet non enrichi et un objet du
// catalogue gardent leur rendu historique.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';
import 'package:personnages/core/widgets/magic_bonus_badge.dart';
import 'package:personnages/core/widgets/not_proficient_badge.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_item_card.dart';
import 'package:personnages/features/characters/presentation/widgets/item_action_sheet.dart';
import 'package:personnages/features/characters/presentation/widgets/item_info_panel.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _blade = CharacterInventoryItem(
  id: 'inv-blade',
  name: 'Lame solaire',
  quantity: 1,
  equipped: false,
  unitWeight: 1.5,
  totalWeight: 1.5,
  description: 'Brille dans la nuit.',
  requiresAttunement: true,
  customKind: 'arme',
  magicBonus: 2,
  customRequiresAttunement: true,
  customWeaponCategory: 'guerre',
  customWeaponRange: 'melee',
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d8',
    damageType: 'radiant',
    properties: ['finesse'],
  ),
);

CharacterInventoryItem _copy(
  CharacterInventoryItem i, {
  bool? isAttuned,
  int? magicBonus,
  bool? requiresAttunement,
  int quantity = 1,
}) => CharacterInventoryItem(
  id: i.id,
  itemId: i.itemId,
  name: i.name,
  category: i.category,
  quantity: quantity,
  equipped: i.equipped,
  unitWeight: i.unitWeight,
  totalWeight: i.totalWeight,
  description: i.description,
  requiresAttunement: requiresAttunement ?? i.requiresAttunement,
  isAttuned: isAttuned ?? i.isAttuned,
  weaponProperties: i.weaponProperties,
  customKind: i.customKind,
  magicBonus: magicBonus ?? i.magicBonus,
  customRequiresAttunement: i.customRequiresAttunement,
  customWeaponCategory: i.customWeaponCategory,
  customWeaponRange: i.customWeaponRange,
);

/// Objet personnalisé « Objet magique ou autre » enrichi.
const _ring = CharacterInventoryItem(
  id: 'inv-ring',
  name: 'Anneau étrange',
  quantity: 1,
  equipped: false,
  customKind: 'autre',
  unitWeight: 0.1,
  totalWeight: 0.1,
);

/// Ancien objet personnalisé, jamais enrichi.
const _legacy = CharacterInventoryItem(
  id: 'inv-legacy',
  name: 'Petit sac de sable',
  quantity: 2,
  equipped: false,
);

/// Ancienne arme personnalisée (dé de dégâts, aucun type enregistré).
const _legacyWeapon = CharacterInventoryItem(
  id: 'inv-legacy-weapon',
  name: 'Gourdin maison',
  quantity: 1,
  equipped: false,
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d6',
    damageType: 'contondant',
    properties: [],
  ),
);

const _catalogMagic = CharacterInventoryItem(
  id: 'inv-cat',
  itemId: 4,
  name: 'Amulette de vitalité',
  category: 'objet_magique',
  quantity: 1,
  equipped: false,
  requiresAttunement: true,
);

const _catalogSword = CharacterInventoryItem(
  id: 'inv-sword',
  itemId: 1,
  name: 'Épée longue',
  category: 'arme',
  quantity: 1,
  equipped: false,
  unitWeight: 1.5,
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d8',
    damageType: 'tranchant',
    properties: [],
  ),
);

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

Widget _app(
  Widget home, {
  Locale locale = const Locale('fr'),
  double scale = 1,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(body: home),
  );
}

Future<void> _pumpCard(
  WidgetTester tester,
  CharacterInventoryItem item, {
  Locale locale = const Locale('fr'),
  double scale = 1,
  Size size = const Size(390, 800),
  bool notProficient = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      SingleChildScrollView(
        child: CharacterInventoryItemCard(
          item: item,
          notProficient: notProficient,
        ),
      ),
      locale: locale,
      scale: scale,
    ),
  );
  await tester.pumpAndSettle();
}

var _toggleAttunedCalls = <CharacterInventoryItem>[];

Future<void> _pumpInfo(
  WidgetTester tester,
  CharacterInventoryItem item, {
  int attunedCount = 0,
  bool readOnly = false,
  Locale locale = const Locale('fr'),
}) async {
  _toggleAttunedCalls = [];
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showItemInfoPanel(
            context,
            item: item,
            onUseItem: (_) {},
            onToggleEquipped: (_) {},
            onToggleAttuned: _toggleAttunedCalls.add,
            attunedCount: attunedCount,
            readOnly: readOnly,
          ),
          child: const Text('Ouvrir'),
        ),
      ),
      locale: locale,
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

Future<void> _pumpActions(
  WidgetTester tester,
  CharacterInventoryItem item, {
  int attunedCount = 0,
}) async {
  _toggleAttunedCalls = [];
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showItemActionSheet(
            context,
            item: item,
            onUseItem: (_) {},
            onToggleEquipped: (_) {},
            onToggleAttuned: _toggleAttunedCalls.add,
            onRemoveItem: (_) {},
            attunedCount: attunedCount,
            equippedWeapons: const [],
            onEquipWeaponToSlot: (_, _) {},
          ),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('carte d\'inventaire', () {
    testWidgets('arme personnalisée enrichie : sous-titre « Arme · radiant · '
        'x1 », dé, pastille +2, icône d\'harmonisation requise', (
      tester,
    ) async {
      await _pumpCard(tester, _blade);

      expect(find.text('Arme · radiant · x1'), findsOneWidget);
      expect(find.byType(DiceTypeBadge), findsOneWidget);
      expect(find.byType(MagicBonusBadge), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.bySemanticsLabel('Bonus magique +2'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
      expect(
        find.bySemanticsLabel('harmonisation requise, objet non harmonisé'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.link), findsNothing);
    });

    testWidgets('harmonisée : icône « lié » dorée, plus d\'icône d\'attente', (
      tester,
    ) async {
      await _pumpCard(tester, _copy(_blade, isAttuned: true));

      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsNothing);
    });

    testWidgets('sans bonus magique : pas de pastille', (tester) async {
      await _pumpCard(tester, _copy(_blade, magicBonus: 0));

      expect(find.byType(MagicBonusBadge), findsNothing);
    });

    testWidgets('objet « autre » enrichi : sous-titre inchangé « Objet '
        'personnalisé · x1 », ni pastille ni icône', (tester) async {
      await _pumpCard(tester, _ring);

      expect(find.text('Objet personnalisé · x1'), findsOneWidget);
      expect(find.byType(MagicBonusBadge), findsNothing);
      expect(find.byIcon(Icons.link_off), findsNothing);
    });

    testWidgets('ancien objet personnalisé et ancienne arme : rendu '
        'strictement inchangé', (tester) async {
      await _pumpCard(tester, _legacy);
      expect(find.text('Objet personnalisé · x2'), findsOneWidget);
      expect(find.byType(MagicBonusBadge), findsNothing);
      expect(find.byIcon(Icons.link_off), findsNothing);

      await _pumpCard(tester, _legacyWeapon);
      expect(find.text('Objet personnalisé · x1'), findsOneWidget);
      expect(find.byType(DiceTypeBadge), findsOneWidget);
      expect(find.byType(MagicBonusBadge), findsNothing);
    });

    testWidgets('objet du catalogue : sous-titre inchangé ; harmonisation '
        'requise non réalisée : icône aussi (tous les objets)', (tester) async {
      await _pumpCard(tester, _catalogSword);
      expect(find.text('Arme · x1'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsNothing);

      await _pumpCard(tester, _catalogMagic);
      expect(find.text('Objet magique · x1'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('anglais : « Weapon · slashing · x1 »', (tester) async {
      await _pumpCard(
        tester,
        CharacterInventoryItem(
          id: 'w',
          name: 'Blade',
          quantity: 1,
          equipped: false,
          customKind: 'arme',
          weaponProperties: const CharacterInventoryWeaponProperties(
            damageDice: '1d8',
            damageType: 'tranchant',
            properties: [],
          ),
        ),
        locale: const Locale('en'),
      );

      expect(find.text('Weapon · slashing · x1'), findsOneWidget);
    });

    testWidgets('arme enrichie sans type de dégâts : « Arme · x1 »', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        const CharacterInventoryItem(
          id: 'w',
          name: 'Lame',
          quantity: 1,
          equipped: false,
          customKind: 'arme',
        ),
      );

      expect(find.text('Arme · x1'), findsOneWidget);
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('x$scale sur 320 dp : toutes les pastilles, sans '
          'débordement', (tester) async {
        await _pumpCard(
          tester,
          _blade,
          scale: scale,
          size: const Size(320, 900),
          notProficient: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(MagicBonusBadge), findsOneWidget);
        expect(find.byType(NotProficientBadge), findsOneWidget);
        expect(find.byType(DiceTypeBadge), findsOneWidget);
      });
    }
  });

  group('MagicBonusBadge', () {
    testWidgets('rien sous +1 ; +3 affiché avec sa sémantique', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [MagicBonusBadge(bonus: 0), MagicBonusBadge(bonus: 3)],
          ),
        ),
      );

      expect(find.text('+0'), findsNothing);
      expect(find.text('+3'), findsOneWidget);
      expect(find.bySemanticsLabel('Bonus magique +3'), findsOneWidget);
    });

    testWidgets('texte à 11 px minimum, en gras', (tester) async {
      await tester.pumpWidget(_app(const MagicBonusBadge(bonus: 1)));

      final style = tester.widget<Text>(find.text('+1')).style!;
      expect(style.fontSize, greaterThanOrEqualTo(11));
      expect(style.fontWeight, FontWeight.w800);
    });
  });

  group('panneau « Infos »', () {
    testWidgets('arme enrichie : Type, Poids, Bonus magique, Dégâts, '
        'Catégorie, Portée, Harmonisation, légende de bonus suspendu', (
      tester,
    ) async {
      await _pumpInfo(tester, _blade);

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Arme'), findsOneWidget);
      expect(find.text('Poids unitaire'), findsOneWidget);
      expect(find.text('1,5 kg'), findsOneWidget);
      expect(find.text('Bonus magique'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('1d8 radiant'), findsOneWidget);
      expect(find.text('Catégorie d\'arme'), findsOneWidget);
      expect(find.text('De guerre'), findsOneWidget);
      expect(find.text('Corps à corps'), findsOneWidget);
      expect(find.text('Harmonisation'), findsOneWidget);
      expect(find.text('Requise · non harmonisé'), findsOneWidget);
      expect(
        find.text(
          'Bonus magique inactif tant que l\'objet n\'est pas harmonisé.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('harmonisé : pas de légende, valeur « Requise · harmonisé »', (
      tester,
    ) async {
      await _pumpInfo(tester, _copy(_blade, isAttuned: true));

      expect(find.text('Requise · harmonisé'), findsOneWidget);
      expect(find.textContaining('Bonus magique inactif'), findsNothing);
    });

    testWidgets('sans harmonisation requise : bonus actif, pas de légende', (
      tester,
    ) async {
      await _pumpInfo(tester, _copy(_blade, requiresAttunement: false));

      expect(find.text('Bonus magique'), findsOneWidget);
      expect(find.textContaining('Bonus magique inactif'), findsNothing);
      expect(find.text('Harmonisation'), findsNothing);
    });

    testWidgets('objet « autre » : ligne Type, pas de bonus', (tester) async {
      await _pumpInfo(tester, _ring);

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Objet magique ou autre'), findsOneWidget);
      expect(find.text('Bonus magique'), findsNothing);
      expect(find.text('0,1 kg'), findsOneWidget);
    });

    testWidgets('ancien objet personnalisé : aucune ligne nouvelle', (
      tester,
    ) async {
      await _pumpInfo(tester, _legacyWeapon);

      expect(find.text('Type'), findsNothing);
      expect(find.text('Bonus magique'), findsNothing);
      expect(find.text('Harmonisation'), findsNothing);
      expect(find.text('Catégorie d\'arme'), findsNothing);
      expect(find.text('1d6 contondant'), findsOneWidget);
      expect(find.text('Harmoniser cet objet'), findsNothing);
    });

    testWidgets('lien d\'harmonisation d\'un objet personnalisé : appelle '
        'onToggleAttuned', (tester) async {
      await _pumpInfo(tester, _blade, attunedCount: 1);

      await tester.tap(find.text('Harmoniser cet objet'));
      await tester.pumpAndSettle();

      expect(_toggleAttunedCalls.single.id, 'inv-blade');
    });

    testWidgets('plafond de 3 objets harmonisés : lien grisé et légende', (
      tester,
    ) async {
      await _pumpInfo(tester, _blade, attunedCount: 3);

      expect(
        find.text('Limite de 3 objets harmonisés atteinte.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Harmoniser cet objet'));
      await tester.pumpAndSettle();
      expect(_toggleAttunedCalls, isEmpty);
    });

    testWidgets('lecture seule : pas de lien d\'harmonisation', (tester) async {
      await _pumpInfo(tester, _blade, readOnly: true);

      expect(find.text('Harmoniser cet objet'), findsNothing);
      expect(find.text('Bonus magique'), findsOneWidget);
    });

    testWidgets('anglais : libellés traduits', (tester) async {
      await _pumpInfo(tester, _blade, locale: const Locale('en'));

      expect(find.text('Magic bonus'), findsOneWidget);
      expect(find.text('Weapon category'), findsOneWidget);
      expect(find.text('Martial'), findsOneWidget);
      expect(find.text('Melee'), findsOneWidget);
      expect(find.text('Required · not attuned'), findsOneWidget);
      expect(
        find.text('Magic bonus inactive until the item is attuned.'),
        findsOneWidget,
      );
    });

    testWidgets('objet du catalogue : aucune ligne Type', (tester) async {
      await _pumpInfo(tester, _catalogSword);

      expect(find.text('Type'), findsNothing);
      expect(find.text('Bonus magique'), findsNothing);
      expect(find.text('1d8 tranchant'), findsOneWidget);
    });
  });

  group('feuille d\'actions', () {
    testWidgets('objet personnalisé exigeant l\'harmonisation : « Harmoniser '
        'cet objet » proposé, sous-titre « Arme · x1 »', (tester) async {
      await _pumpActions(tester, _blade);

      expect(find.text('Harmoniser cet objet'), findsOneWidget);
      expect(find.text('Arme · x1'), findsOneWidget);
      expect(find.text('Équiper'), findsNothing);

      await tester.tap(find.text('Harmoniser cet objet'));
      await tester.pumpAndSettle();
      expect(_toggleAttunedCalls.single.id, 'inv-blade');
    });

    testWidgets('objet personnalisé sans harmonisation : seulement Infos et '
        'Retirer', (tester) async {
      await _pumpActions(tester, _legacy);

      expect(find.text('Harmoniser cet objet'), findsNothing);
      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Retirer'), findsOneWidget);
      expect(find.text('Objet personnalisé · x2'), findsOneWidget);
    });

    testWidgets('harmonisation au plafond : action désactivée', (tester) async {
      await _pumpActions(tester, _blade, attunedCount: 3);

      await tester.tap(find.text('Harmoniser cet objet'));
      await tester.pumpAndSettle();

      expect(_toggleAttunedCalls, isEmpty);
    });
  });
}
