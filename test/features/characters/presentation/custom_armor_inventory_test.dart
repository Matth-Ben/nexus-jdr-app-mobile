// P7 PR 3 : armure et bouclier personnalisés dans l'onglet Inventaire — carte
// (sous-titre, pastille de bonus magique, « Non maîtrisé »), équipement,
// panneau « Infos », filtre « Armures », libellés FR/EN et échelles de police.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/magic_bonus_badge.dart';
import 'package:personnages/core/widgets/not_proficient_badge.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/custom_armor_properties.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/domain/inventory_category_filter.dart';
import 'package:personnages/features/characters/presentation/custom_item_labels.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_item_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/item_action_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

const _frArmorBanner =
    'Armure non maîtrisée : désavantage aux tests, sauvegardes et attaques '
    'de Force/Dextérité ; sorts impossibles.';
const _frShieldBanner =
    'Bouclier non maîtrisé : désavantage aux tests, sauvegardes et attaques '
    'de Force/Dextérité ; sorts impossibles.';

CharacterInventoryItem _armor({
  String id = 'a',
  String name = 'Cotte maison',
  String? category = CustomArmorCategories.heavy,
  int? acBase = 16,
  int magic = 0,
  bool equipped = false,
  bool requiresAttunement = false,
  bool isAttuned = false,
  int quantity = 1,
}) => CharacterInventoryItem(
  id: id,
  name: name,
  quantity: quantity,
  equipped: equipped,
  requiresAttunement: requiresAttunement,
  isAttuned: isAttuned,
  customKind: CustomItemKinds.armor,
  magicBonus: magic,
  customAcBase: acBase,
  customArmorCategory: category,
  customRequiresAttunement: requiresAttunement,
  unitWeight: 20,
  totalWeight: 20.0 * quantity,
  armorProperties: customArmorPropertiesOf(
    kind: CustomItemKinds.armor,
    acBase: acBase,
    armorCategory: category,
  ),
);

CharacterInventoryItem _shield({
  String id = 's',
  String name = 'Pavois maison',
  int bonus = 2,
  int magic = 0,
  bool equipped = false,
}) => CharacterInventoryItem(
  id: id,
  name: name,
  quantity: 1,
  equipped: equipped,
  customKind: CustomItemKinds.shield,
  magicBonus: magic,
  customAcBase: bonus,
  armorProperties: customArmorPropertiesOf(
    kind: CustomItemKinds.shield,
    acBase: bonus,
    armorCategory: null,
  ),
);

const _ring = CharacterInventoryItem(
  id: 'r',
  name: 'Anneau étrange',
  quantity: 1,
  equipped: false,
  customKind: CustomItemKinds.other,
);

const _legacy = CharacterInventoryItem(
  id: 'l',
  name: 'Vieux sac',
  quantity: 1,
  equipped: false,
);

CharacterDetail _detail(
  List<CharacterInventoryItem> inventory, {
  String className = 'Magicien',
  List<String> armorTokens = const [],
}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: className,
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: const [],
      hitDie: 6,
      subclassName: className == 'Magicien' ? 'Abjuration' : null,
    ),
  ],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: const {},
  armorProficiencyNames: armorTokens,
  inventory: inventory,
);

Future<List<String>> _pumpTab(
  WidgetTester tester,
  CharacterDetail detail, {
  double scale = 1,
  Size size = const Size(390, 2400),
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final writes = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: CharacterInventoryTabBody(
          detail: detail,
          showArmorProficiencyWarning: true,
          onUseItem: (i) => writes.add('use ${i.id}'),
          onToggleItemEquipped: (i) => writes.add('equip ${i.id}'),
          onToggleItemAttuned: (i) => writes.add('attune ${i.id}'),
          onRemoveItem: (i) => writes.add('remove ${i.id}'),
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
          onEquipWeaponToSlot: (i, s) => writes.add('equipWeapon'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return writes;
}

Future<void> _pumpCard(
  WidgetTester tester,
  CharacterInventoryItem item, {
  Locale locale = const Locale('fr'),
  double scale = 1,
  Size size = const Size(390, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CharacterInventoryItemCard(item: item),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

Future<void> _openInfo(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Infos'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('carte', () {
    testWidgets('« Armure intermédiaire · CA 15 · x1 »', (tester) async {
      await _pumpCard(
        tester,
        _armor(category: CustomArmorCategories.medium, acBase: 15),
      );
      expect(find.text('Armure intermédiaire · CA 15 · x1'), findsOneWidget);
    });

    testWidgets('légère et lourde, quantité', (tester) async {
      await _pumpCard(
        tester,
        _armor(category: CustomArmorCategories.light, acBase: 11, quantity: 2),
      );
      expect(find.text('Armure légère · CA 11 · x2'), findsOneWidget);
      await _pumpCard(tester, _armor());
      expect(find.text('Armure lourde · CA 16 · x1'), findsOneWidget);
    });

    testWidgets('« Bouclier · +2 CA · x1 »', (tester) async {
      await _pumpCard(tester, _shield());
      expect(find.text('Bouclier · +2 CA · x1'), findsOneWidget);
    });

    testWidgets('anglais : « Medium armor · AC 15 · x1 », « Shield · +2 AC »', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        _armor(category: CustomArmorCategories.medium, acBase: 15),
        locale: const Locale('en'),
      );
      expect(find.text('Medium armor · AC 15 · x1'), findsOneWidget);
      await _pumpCard(tester, _shield(), locale: const Locale('en'));
      expect(find.text('Shield · +2 AC · x1'), findsOneWidget);
    });

    testWidgets('pastille de bonus magique et icône d\'harmonisation en '
        'attente', (tester) async {
      await _pumpCard(tester, _armor(magic: 2, requiresAttunement: true));
      expect(find.byType(MagicBonusBadge), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('sans bonus magique : pas de pastille', (tester) async {
      await _pumpCard(tester, _armor());
      expect(find.byType(MagicBonusBadge), findsNothing);
    });

    testWidgets('armure sans CA ni catégorie : sous-titre générique « '
        'Armure · x1 », jamais de CA inventée', (tester) async {
      await _pumpCard(tester, _armor(category: null, acBase: null));
      expect(find.text('Armure · x1'), findsOneWidget);
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('x$scale sur 320 dp : carte sans débordement', (
        tester,
      ) async {
        await _pumpCard(
          tester,
          _armor(
            name: 'Armure de plaques des anciens rois nains',
            magic: 3,
            requiresAttunement: true,
            category: CustomArmorCategories.medium,
            acBase: 15,
          ),
          scale: scale,
          size: const Size(320, 800),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('maîtrise (P10) : pastille et bannière', () {
    testWidgets('Magicien : armure lourde personnalisée non maîtrisée, '
        'pastille et bannière armure avant d\'équiper', (tester) async {
      await _pumpTab(tester, _detail([_armor()]));
      expect(find.byType(NotProficientBadge), findsOneWidget);

      await tester.tap(find.text('Cotte maison'));
      await tester.pumpAndSettle();
      expect(find.text(_frArmorBanner), findsOneWidget);
      expect(find.text('Équiper'), findsOneWidget);
    });

    testWidgets('bouclier personnalisé non maîtrisé : bannière bouclier', (
      tester,
    ) async {
      await _pumpTab(tester, _detail([_shield()]));
      expect(find.byType(NotProficientBadge), findsOneWidget);
      await tester.tap(find.text('Pavois maison'));
      await tester.pumpAndSettle();
      expect(find.text(_frShieldBanner), findsOneWidget);
    });

    testWidgets('Guerrier maîtrisant tout : aucune pastille', (tester) async {
      await _pumpTab(
        tester,
        _detail(
          [_armor(), _shield(id: 's2')],
          className: 'Guerrier',
          armorTokens: const ['légère', 'intermédiaire', 'lourde', 'boucliers'],
        ),
      );
      expect(find.byType(NotProficientBadge), findsNothing);
    });

    testWidgets('armure sans catégorie : aucune pastille (verdict '
        'indécidable)', (tester) async {
      await _pumpTab(tester, _detail([_armor(category: null)]));
      expect(find.byType(NotProficientBadge), findsNothing);
    });

    testWidgets('objet « autre » et ancien objet : jamais de pastille', (
      tester,
    ) async {
      await _pumpTab(tester, _detail([_ring, _legacy]));
      expect(find.byType(NotProficientBadge), findsNothing);
    });
  });

  group('équipement', () {
    testWidgets('« Équiper » proposé pour une armure personnalisée, écrit '
        'l\'équipement', (tester) async {
      final writes = await _pumpTab(
        tester,
        _detail([_armor()], className: 'Guerrier', armorTokens: ['lourde']),
      );
      await tester.tap(find.text('Cotte maison'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Équiper'));
      await tester.pumpAndSettle();
      expect(writes, ['equip a']);
    });

    testWidgets('équipé : « Déséquiper »', (tester) async {
      await _pumpTab(tester, _detail([_shield(equipped: true)]));
      await tester.tap(find.text('Pavois maison'));
      await tester.pumpAndSettle();
      expect(find.text('Déséquiper'), findsOneWidget);
      expect(find.text('Équiper'), findsNothing);
    });

    testWidgets('une seconde armure reste équipable (comme le catalogue : '
        'seule la première compte pour la CA)', (tester) async {
      final writes = await _pumpTab(
        tester,
        _detail([
          _armor(id: 'a1', equipped: true),
          _armor(id: 'a2', name: 'Seconde cotte'),
        ]),
      );
      await tester.tap(find.text('Seconde cotte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Équiper'));
      await tester.pumpAndSettle();
      expect(writes, ['equip a2']);
    });

    testWidgets('objet « autre » et ancien objet : pas équipables', (
      tester,
    ) async {
      await _pumpTab(tester, _detail([_ring]));
      await tester.tap(find.text('Anneau étrange'));
      await tester.pumpAndSettle();
      expect(find.text('Équiper'), findsNothing);
    });

    test('isEquippableItem : armure et bouclier personnalisés oui, '
        '« autre » et ancien non', () {
      expect(isEquippableItem(_armor()), isTrue);
      expect(isEquippableItem(_armor(category: null)), isTrue);
      expect(isEquippableItem(_shield()), isTrue);
      expect(isEquippableItem(_ring), isFalse);
      expect(isEquippableItem(_legacy), isFalse);
    });
  });

  group('panneau « Infos »', () {
    testWidgets('armure : type, catégorie, poids, CA de base, bonus de Dex, '
        'bonus magique, harmonisation, légende ; ni Force ni Discrétion', (
      tester,
    ) async {
      await _pumpTab(
        tester,
        _detail([
          _armor(
            category: CustomArmorCategories.medium,
            acBase: 15,
            magic: 1,
            requiresAttunement: true,
          ),
        ]),
      );
      await _openInfo(tester, 'Cotte maison');

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Armure'), findsOneWidget);
      expect(find.text('Catégorie d\'armure'), findsOneWidget);
      expect(find.text('Intermédiaire'), findsOneWidget);
      expect(find.text('CA de base'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Bonus Dex'), findsOneWidget);
      expect(find.text('plafonné à +2'), findsOneWidget);
      expect(find.text('Bonus magique'), findsOneWidget);
      expect(find.text('+1'), findsWidgets);
      expect(find.text('Harmonisation'), findsOneWidget);
      expect(find.text('Requise · non harmonisé'), findsOneWidget);
      expect(
        find.text(
          'Bonus magique inactif tant que l\'objet n\'est pas harmonisé.',
        ),
        findsOneWidget,
      );
      expect(find.text('Force requise'), findsNothing);
      expect(find.text('Désavantage Discrétion'), findsNothing);
    });

    testWidgets('bouclier : Bonus de CA +3, pas de Bonus de Dextérité', (
      tester,
    ) async {
      await _pumpTab(tester, _detail([_shield(bonus: 3)]));
      await _openInfo(tester, 'Pavois maison');

      expect(find.text('Bouclier'), findsWidgets);
      expect(find.text('Bonus de CA'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget);
      expect(find.text('CA de base'), findsNothing);
      expect(find.text('Bonus Dex'), findsNothing);
    });

    testWidgets('harmonisé : pas de légende', (tester) async {
      await _pumpTab(
        tester,
        _detail([_armor(magic: 1, requiresAttunement: true, isAttuned: true)]),
      );
      await _openInfo(tester, 'Cotte maison');
      expect(
        find.text(
          'Bonus magique inactif tant que l\'objet n\'est pas harmonisé.',
        ),
        findsNothing,
      );
    });
  });

  group('filtre « Armures »', () {
    test('armure et bouclier personnalisés : sous « Armures », jamais '
        'sous « Divers »', () {
      for (final item in [_armor(), _shield(), _armor(category: null)]) {
        expect(InventoryCategoryFilter.armor.matches(item), isTrue);
        expect(InventoryCategoryFilter.misc.matches(item), isFalse);
        expect(InventoryCategoryFilter.weapons.matches(item), isFalse);
      }
    });

    test('objet « autre » et ancien objet : « Divers » seulement', () {
      for (final item in [_ring, _legacy]) {
        expect(InventoryCategoryFilter.armor.matches(item), isFalse);
        expect(InventoryCategoryFilter.misc.matches(item), isTrue);
      }
    });
  });

  group('libellés', () {
    test('customKindLabel : armure et bouclier, FR et EN', () {
      final fr = AppLocalizationsFr();
      final en = AppLocalizationsEn();
      expect(customKindLabel(fr, CustomItemKinds.armor), 'Armure');
      expect(customKindLabel(fr, CustomItemKinds.shield), 'Bouclier');
      expect(customKindLabel(en, CustomItemKinds.armor), 'Armor');
      expect(customKindLabel(en, CustomItemKinds.shield), 'Shield');
      expect(customKindLabel(fr, 'inconnu'), 'inconnu');
    });

    test('catégories d\'armure et ligne de Dextérité', () {
      final fr = AppLocalizationsFr();
      final en = AppLocalizationsEn();
      expect(customArmorCategoryLabel(fr, 'legere'), 'Légère');
      expect(customArmorCategoryLabel(fr, 'intermediaire'), 'Intermédiaire');
      expect(customArmorCategoryLabel(fr, 'lourde'), 'Lourde');
      expect(customArmorCategoryLabel(en, 'intermediaire'), 'Medium');
      expect(customArmorDexBonusLabel(fr, 'legere'), 'illimité');
      expect(customArmorDexBonusLabel(fr, 'intermediaire'), 'plafonné à +2');
      expect(customArmorDexBonusLabel(fr, 'lourde'), 'aucun');
      expect(customArmorDexBonusLabel(en, 'lourde'), 'none');
    });
  });
}
