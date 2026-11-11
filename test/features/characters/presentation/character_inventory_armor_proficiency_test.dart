// Avertissement informatif « armure ou bouclier non maîtrisé » (P10/F16) :
// pastille sur la carte, en-tête de la feuille d'actions et du panneau
// « Infos », bannière avant « Équiper », accessibilité (police x2,0 sur
// 360 dp). Aucun effet sur la CA, aucune écriture.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/not_proficient_badge.dart';
import 'package:personnages/features/characters/domain/armor_class_calculator.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:personnages/l10n/app_localizations_en.dart';

const _frArmorBanner =
    'Armure non maîtrisée : désavantage aux tests, sauvegardes et attaques '
    'de Force/Dextérité ; sorts impossibles.';
const _frShieldBanner =
    'Bouclier non maîtrisé : désavantage aux tests, sauvegardes et attaques '
    'de Force/Dextérité ; sorts impossibles.';

CharacterInventoryItem _armor(
  String name, {
  String id = 'a',
  String acDexBonus = 'aucun',
  bool equipped = false,
  String? category = 'armure',
  String? slot,
}) => CharacterInventoryItem(
  id: id,
  itemId: 10,
  name: name,
  category: category,
  quantity: 1,
  equipped: equipped,
  armorProperties: CharacterInventoryArmorProperties(
    slot: slot,
    acBase: 16,
    acDexBonus: acDexBonus,
    stealthDisadvantage: true,
  ),
);

const _dagger = CharacterInventoryItem(
  id: 'd',
  itemId: 1,
  name: 'Dague',
  category: 'arme',
  quantity: 1,
  equipped: false,
);

const _plusOneArmor = CharacterInventoryItem(
  id: 'p',
  itemId: 11,
  name: 'Armure +1',
  category: 'objet_magique',
  quantity: 1,
  equipped: false,
  acBonus: 1,
  acBonusKind: 'avec_armure',
);

const _customArmor = CharacterInventoryItem(
  id: 'c',
  itemId: null,
  name: 'Armure maison',
  category: null,
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
      // Un Magicien de niveau 3 a toujours une école : sans elle, le verdict
      // serait indécidable (voir `ArmorProficiencyRules`).
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

Future<List<String>> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  bool warn = true,
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
          showArmorProficiencyWarning: warn,
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
          }) => writes.add('addCustom'),
          onEquipWeaponToSlot: (i, s) => writes.add('equipWeapon'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return writes;
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

  group('pastille sur la carte', () {
    testWidgets('visible sur une armure non équipée ET équipée', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail([
          _armor('Cotte de mailles', id: 'a1'),
          _armor('Brigandine', id: 'a2', equipped: true),
        ]),
      );
      expect(find.byType(NotProficientBadge), findsNWidgets(2));
      expect(find.text('Non maîtrisé'), findsNWidgets(2));
      // L'équipé garde son badge « ÉQUIPÉ ».
      expect(find.text('ÉQUIPÉ'), findsOneWidget);
    });

    testWidgets('bouclier non maîtrisé : pastille aussi', (tester) async {
      await _pump(
        tester,
        _detail([
          _armor('Bouclier', category: 'bouclier', acDexBonus: 'illimite'),
        ]),
      );
      expect(find.byType(NotProficientBadge), findsOneWidget);
    });

    testWidgets('jamais pour un objet non armure ni un verdict indécidable', (
      tester,
    ) async {
      await _pump(tester, _detail([_dagger, _plusOneArmor, _customArmor]));
      expect(find.byType(NotProficientBadge), findsNothing);
    });

    testWidgets('aucune pastille si le personnage maîtrise la catégorie', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(
          [_armor('Cotte de mailles')],
          className: 'Guerrier',
          armorTokens: const ['légère', 'intermédiaire', 'lourde', 'boucliers'],
        ),
      );
      expect(find.byType(NotProficientBadge), findsNothing);
    });

    testWidgets('Druide : chemise de mailles et bouclier métalliques, aucune '
        'pastille', (tester) async {
      await _pump(
        tester,
        _detail(
          [
            _armor('Chemise de mailles', acDexBonus: 'max_2'),
            _armor(
              'Bouclier',
              id: 'b',
              category: 'bouclier',
              acDexBonus: 'illimite',
            ),
          ],
          className: 'Druide',
          armorTokens: const [
            'légère',
            'intermédiaire (non métallique)',
            'boucliers (non métalliques)',
          ],
        ),
      );
      expect(find.byType(NotProficientBadge), findsNothing);
    });

    testWidgets('vue partagée/MJ (showArmorProficiencyWarning false) : rien', (
      tester,
    ) async {
      await _pump(tester, _detail([_armor('Cotte de mailles')]), warn: false);
      expect(find.byType(NotProficientBadge), findsNothing);
    });
  });

  group('feuille d\'actions et panneau Infos', () {
    testWidgets('feuille : pastille en en-tête et bannière armure au-dessus '
        'de « Équiper », aucune écriture', (tester) async {
      final writes = await _pump(tester, _detail([_armor('Cotte de mailles')]));
      await tester.tap(find.text('Cotte de mailles'));
      await tester.pumpAndSettle();

      // Carte + en-tête de feuille.
      expect(find.byType(NotProficientBadge), findsNWidgets(2));
      expect(find.text(_frArmorBanner), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text(_frArmorBanner)).dy,
        lessThan(tester.getTopLeft(find.text('Équiper')).dy),
      );
      expect(writes, isEmpty);
    });

    testWidgets('feuille : bouclier -> texte « Bouclier non maîtrisé »', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail([
          _armor(
            'Bouclier +1',
            category: 'objet_magique',
            slot: 'bouclier',
            acDexBonus: 'illimite',
          ),
        ]),
      );
      await tester.tap(find.text('Bouclier +1'));
      await tester.pumpAndSettle();
      expect(find.text(_frShieldBanner), findsOneWidget);
      expect(find.text(_frArmorBanner), findsNothing);
    });

    testWidgets('panneau Infos : pastille et bannière', (tester) async {
      final writes = await _pump(tester, _detail([_armor('Cotte de mailles')]));
      await tester.tap(find.text('Cotte de mailles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text(_frArmorBanner), findsOneWidget);
      // Carte (sous la feuille) + panneau.
      expect(find.byType(NotProficientBadge), findsNWidgets(2));
      expect(writes, isEmpty);
    });

    testWidgets('objet maîtrisé : ni bannière ni pastille dans la feuille', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(
          [_armor('Cotte de mailles')],
          className: 'Guerrier',
          armorTokens: const ['lourde'],
        ),
      );
      await tester.tap(find.text('Cotte de mailles'));
      await tester.pumpAndSettle();
      expect(find.text(_frArmorBanner), findsNothing);
      expect(find.byType(NotProficientBadge), findsNothing);
    });
  });

  group('textes FR/EN', () {
    testWidgets('anglais : pastille et bannières', (tester) async {
      await _pump(
        tester,
        _detail([_armor('Chain mail')]),
        locale: const Locale('en'),
      );
      expect(find.text('Not proficient'), findsOneWidget);
      await tester.tap(find.text('Chain mail'));
      await tester.pumpAndSettle();
      final en = AppLocalizationsEn();
      expect(find.text(en.inventoryNotProficientArmorBanner), findsOneWidget);
      expect(
        en.inventoryNotProficientArmorBanner,
        "Not proficient with this armor: disadvantage on Strength/Dexterity "
        "checks, saves and attacks; can't cast spells.",
      );
      expect(
        en.inventoryNotProficientShieldBanner,
        "Not proficient with this shield: disadvantage on Strength/Dexterity "
        "checks, saves and attacks; can't cast spells.",
      );
      expect(
        en.characterDetailItemEquippedMessage('Chain mail'),
        'Equipped: Chain mail.',
      );
      expect(
        en.characterDetailItemUnequippedMessage('Chain mail'),
        'Unequipped: Chain mail.',
      );
    });
  });

  group('police x2,0 sur 360 dp', () {
    testWidgets('nom long + pastille + ÉQUIPÉ : aucun débordement, aucune '
        'ellipse', (tester) async {
      const longName = 'Armure de plates articulée des profondeurs ancestrales';
      await _pump(
        tester,
        _detail([_armor(longName, equipped: true)]),
        scale: 2,
        size: const Size(360, 2400),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(longName), findsOneWidget);
      expect(find.text('Non maîtrisé'), findsOneWidget);
      expect(find.text('ÉQUIPÉ'), findsOneWidget);
      // Pas de pastille tronquée : le texte tient (le Wrap la descend).
      expect(
        tester.getSize(find.byType(NotProficientBadge)).width,
        lessThanOrEqualTo(360),
      );
      for (final label in [longName, 'Non maîtrisé', 'ÉQUIPÉ']) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.overflow, isNot(TextOverflow.ellipsis), reason: label);
        expect(text.maxLines, isNull, reason: label);
      }
    });

    testWidgets('bannière sur plusieurs lignes dans la feuille et le '
        'panneau, sans débordement', (tester) async {
      await _pump(
        tester,
        _detail([_armor('Cotte de mailles')]),
        scale: 2,
        size: const Size(360, 2400),
      );
      await tester.tap(find.text('Cotte de mailles'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(_frArmorBanner), findsOneWidget);
      final bannerHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.text(_frArmorBanner),
                  matching: find.byType(Container),
                )
                .first,
          )
          .height;
      expect(bannerHeight, greaterThan(60));

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(_frArmorBanner), findsOneWidget);
    });
  });

  group('aucun effet sur la CA', () {
    test('un Magicien en cotte de mailles garde la CA de l\'armure', () {
      final chainMail = _armor('Cotte de mailles', equipped: true);
      final ac = ArmorClassCalculator.compute(
        abilityScores: const {'dex': 14},
        inventory: [chainMail],
        classNames: const {'Magicien'},
      );
      // acBase 16, ac_dex_bonus « aucun » : la Dex ne s'ajoute pas.
      expect(ac, 16);
    });
  });
}
