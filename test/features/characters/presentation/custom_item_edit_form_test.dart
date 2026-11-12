// P7 PR 4 : formulaire d'objet personnalisé en mode édition / enrichissement —
// pré-remplissage fidèle (4 types), « Changer » de type (champs sans objet
// remis à NULL dans le résultat), type d'un objet équipé verrouillé, titres et
// bouton « Enregistrer », pas de quantité, validations de la création, échelles
// de police sur 320 dp avec les vraies polices, FR et EN.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/custom_item_edit_rules.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/presentation/widgets/custom_item_form_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _armor = CharacterInventoryItem(
  id: 'a',
  name: 'Plate runique',
  quantity: 2,
  equipped: false,
  customKind: CustomItemKinds.armor,
  customAcBase: 16,
  customArmorCategory: CustomArmorCategories.heavy,
  magicBonus: 2,
  unitWeight: 20,
  customRequiresAttunement: true,
  requiresAttunement: true,
  description: 'Gravée de runes.',
);

const _weapon = CharacterInventoryItem(
  id: 'w',
  name: 'Lame ardente',
  quantity: 1,
  equipped: false,
  customKind: CustomItemKinds.weapon,
  customWeaponCategory: CustomWeaponCategories.martial,
  customWeaponRange: CustomWeaponRanges.ranged,
  magicBonus: 1,
  unitWeight: 1.5,
  description: 'Brûle.',
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '2d8',
    damageType: 'feu',
    properties: ['finesse', 'légère'],
  ),
);

const _shield = CharacterInventoryItem(
  id: 's',
  name: 'Égide',
  quantity: 1,
  equipped: false,
  customKind: CustomItemKinds.shield,
  customAcBase: 3,
  magicBonus: 1,
);

const _other = CharacterInventoryItem(
  id: 'o',
  name: 'Amulette',
  quantity: 1,
  equipped: false,
  customKind: CustomItemKinds.other,
  unitWeight: 0.25,
  customRequiresAttunement: true,
  requiresAttunement: true,
  description: 'Une amulette.',
);

const _legacyWeapon = CharacterInventoryItem(
  id: 'l',
  name: 'Vieille épée',
  quantity: 1,
  equipped: false,
  description: 'Rouillée.',
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d20',
    damageType: 'tranchant',
    properties: [],
  ),
);

const _legacySimple = CharacterInventoryItem(
  id: 'ls',
  name: 'Caillou',
  quantity: 1,
  equipped: false,
);

CustomItemFormResult? _result;

Future<void> _load(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

Future<void> _open(
  WidgetTester tester,
  CharacterInventoryItem item, {
  double scale = 1,
  Locale locale = const Locale('fr'),
  Size size = const Size(390, 1400),
  bool equipped = false,
}) async {
  _result = null;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final base = customItemInitialValuesOf(item);
  final initial = equipped
      ? CustomItemInitialValues(
          mode: base.mode,
          name: base.name,
          kind: base.kind,
          equipped: true,
          description: base.description,
          diceCount: base.diceCount,
          diceSides: base.diceSides,
          damageType: base.damageType,
          properties: base.properties,
          weaponCategory: base.weaponCategory,
          weaponRange: base.weaponRange,
          magicBonus: base.magicBonus,
          acBase: base.acBase,
          armorCategory: base.armorCategory,
          weight: base.weight,
          requiresAttunement: base.requiresAttunement,
        )
      : base;
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                _result = await showCustomItemFormSheet(
                  context,
                  initial: initial,
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Finder get _saveButton => find.widgetWithText(PrimaryButton, 'ENREGISTRER');

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<PrimaryButton>(_saveButton).onPressed != null;

Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(_saveButton);
  await tester.tap(_saveButton);
  await tester.pumpAndSettle();
}

Future<void> _pickKind(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _openAdvanced(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('advancedSectionHeader')));
  await tester.tap(find.byKey(const Key('advancedSectionHeader')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await _load('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _load('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('édition : pré-remplissage fidèle, étape 2 directement', () {
    testWidgets('armure : titre, bouton Enregistrer, nom, catégorie, CA, '
        'bonus, poids, harmonisation ; pas de quantité', (tester) async {
      await _open(tester, _armor);

      expect(find.text('MODIFIER L\'OBJET'), findsOneWidget);
      expect(find.text('Type : Armure'), findsOneWidget);
      expect(_text(tester, 'customItemNameField'), 'Plate runique');
      expect(_text(tester, 'customItemArmorClassField'), '16');
      expect(find.text('Bonus de Dextérité : aucun'), findsOneWidget);
      // Valeurs avancées présentes : section dépliée d'office.
      expect(_text(tester, 'customItemWeightField'), '20');
      expect(_text(tester, 'customItemDescriptionField'), 'Gravée de runes.');
      expect(
        find.byKey(const Key('customItemMagicBonusToggle')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.descendant(
                of: find.byKey(const Key('customItemRequiresAttunementSwitch')),
                matching: find.byType(SwitchListTile),
              ),
            )
            .value,
        isTrue,
      );
      expect(find.text('QUANTITÉ'), findsNothing);
      expect(find.text('AJOUTER'), findsNothing);
      expect(_saveEnabled(tester), isTrue);
      // Jamais d'« Harmoniser maintenant » à l'édition.
      expect(find.byKey(const Key('customItemAttuneNowSwitch')), findsNothing);

      await _save(tester);

      final r = _result!;
      expect(r.name, 'Plate runique');
      expect(r.enrichment.kind, 'armure');
      expect(r.enrichment.acBase, 16);
      expect(r.enrichment.armorCategory, 'lourde');
      expect(r.enrichment.magicBonus, 2);
      expect(r.enrichment.weight, 20);
      expect(r.enrichment.requiresAttunement, isTrue);
      expect(r.enrichment.attuneNow, isFalse);
      expect(r.description, 'Gravée de runes.');
      expect(r.damageDice, isNull);
    });

    testWidgets('arme : dés 2d8, type feu, catégorie, portée, propriétés, '
        'bonus, poids', (tester) async {
      await _open(tester, _weapon);

      expect(find.text('Type : Arme'), findsOneWidget);
      expect(_text(tester, 'customItemNameField'), 'Lame ardente');
      expect(find.text('2'), findsWidgets);
      expect(find.text('Feu'), findsOneWidget);
      expect(_text(tester, 'customItemPropertiesField'), 'finesse, légère');
      expect(_text(tester, 'customItemWeightField'), '1.5');

      await _save(tester);

      final r = _result!;
      expect(r.damageDice, '2d8');
      expect(r.damageType, 'feu');
      expect(r.properties, ['finesse', 'légère']);
      expect(r.enrichment.weaponCategory, 'guerre');
      expect(r.enrichment.weaponRange, 'distance');
      expect(r.enrichment.magicBonus, 1);
      expect(r.enrichment.weight, 1.5);
      expect(r.enrichment.acBase, isNull);
      expect(r.enrichment.armorCategory, isNull);
    });

    testWidgets('bouclier : bonus de CA et bonus magique', (tester) async {
      await _open(tester, _shield);

      expect(find.text('Type : Bouclier'), findsOneWidget);
      expect(_text(tester, 'customItemShieldBonusField'), '3');

      await _save(tester);

      final r = _result!;
      expect(r.enrichment.kind, 'bouclier');
      expect(r.enrichment.acBase, 3);
      expect(r.enrichment.armorCategory, isNull);
      expect(r.enrichment.magicBonus, 1);
    });

    testWidgets('objet magique ou autre : description, poids 0.25, '
        'harmonisation', (tester) async {
      await _open(tester, _other);

      expect(find.text('Type : Objet magique ou autre'), findsOneWidget);
      expect(_text(tester, 'customItemDescriptionField'), 'Une amulette.');

      await _save(tester);

      final r = _result!;
      expect(r.enrichment.kind, 'autre');
      expect(r.enrichment.weight, 0.25);
      expect(r.enrichment.requiresAttunement, isTrue);
      expect(r.enrichment.magicBonus, 0);
      expect(r.description, 'Une amulette.');
    });

    testWidgets('un 1d20 déjà stocké reste affiché et enregistré tel quel', (
      tester,
    ) async {
      await _open(tester, _legacyWeapon.copyWithKind('arme'));

      await _save(tester);

      expect(_result!.damageDice, '1d20');
    });
  });

  group('« Changer » de type : champs devenus sans objet remis à NULL', () {
    testWidgets('armure -> arme : nom et description conservés, plus de CA '
        'ni de catégorie d\'armure', (tester) async {
      await _open(tester, _armor);
      await tester.tap(find.byKey(const Key('customItemChangeKindButton')));
      await tester.pumpAndSettle();
      // Étape 1 : le type actuel est marqué.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await _pickKind(tester, 'customItemKindWeapon');
      expect(_text(tester, 'customItemNameField'), 'Plate runique');
      await tester.tap(find.byKey(const Key('customItemDamageTypeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tranchant').last);
      await tester.pumpAndSettle();
      await _save(tester);

      final r = _result!;
      expect(r.name, 'Plate runique');
      expect(r.description, 'Gravée de runes.');
      expect(r.enrichment.kind, 'arme');
      expect(r.enrichment.acBase, isNull);
      expect(r.enrichment.armorCategory, isNull);
      expect(r.damageType, 'tranchant');
      expect(r.damageDice, '1d6');
    });

    testWidgets('arme -> armure : plus de dés, de dégâts, de propriétés ni de '
        'catégorie/portée d\'arme', (tester) async {
      await _open(tester, _weapon);
      await tester.tap(find.byKey(const Key('customItemChangeKindButton')));
      await tester.pumpAndSettle();

      await _pickKind(tester, 'customItemKindArmor');
      await _save(tester);

      final r = _result!;
      expect(r.enrichment.kind, 'armure');
      expect(r.damageDice, isNull);
      expect(r.damageType, isNull);
      expect(r.properties, isEmpty);
      expect(r.enrichment.weaponCategory, isNull);
      expect(r.enrichment.weaponRange, isNull);
      expect(r.enrichment.acBase, 11);
      expect(r.enrichment.armorCategory, 'legere');
      expect(r.enrichment.isValid, isTrue);
    });

    testWidgets('armure -> autre : bonus magique remis à 0, plus de CA', (
      tester,
    ) async {
      await _open(tester, _armor);
      await tester.tap(find.byKey(const Key('customItemChangeKindButton')));
      await tester.pumpAndSettle();

      await _pickKind(tester, 'customItemKindOther');
      await _save(tester);

      final r = _result!;
      expect(r.enrichment.kind, 'autre');
      expect(r.enrichment.magicBonus, 0);
      expect(r.enrichment.acBase, isNull);
      expect(r.enrichment.armorCategory, isNull);
      expect(r.enrichment.isValid, isTrue);
    });
  });

  group('enrichissement d\'un ancien objet sans type', () {
    testWidgets('étape 1 d\'abord, type déduit (arme à dé) présélectionné, '
        'puis formulaire pré-rempli', (tester) async {
      await _open(tester, _legacyWeapon);

      expect(find.text('ENRICHIR L\'OBJET'), findsOneWidget);
      expect(find.byKey(const Key('customItemKindWeapon')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('customItemKindWeapon')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );

      await _pickKind(tester, 'customItemKindWeapon');

      expect(_text(tester, 'customItemNameField'), 'Vieille épée');
      expect(find.text('Tranchant'), findsOneWidget);
      expect(_text(tester, 'customItemDescriptionField'), 'Rouillée.');
      expect(_saveEnabled(tester), isTrue);
      await _save(tester);
      expect(_result!.damageDice, '1d20');
      expect(_result!.enrichment.kind, 'arme');
    });

    testWidgets('sans dé de dégâts : aucun type présélectionné', (
      tester,
    ) async {
      await _open(tester, _legacySimple);

      expect(find.text('ENRICHIR L\'OBJET'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await _pickKind(tester, 'customItemKindOther');
      expect(_text(tester, 'customItemNameField'), 'Caillou');
    });
  });

  group('type d\'un objet équipé', () {
    testWidgets('édition : « Changer » désactivé et message honnête', (
      tester,
    ) async {
      await _open(tester, _armor, equipped: true);

      final button = tester.widget<TextButton>(
        find.byKey(const Key('customItemChangeKindButton')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.text('Déséquipez l\'objet avant de changer son type'),
        findsOneWidget,
      );
      // Les autres champs restent modifiables : enregistrement possible.
      await _save(tester);
      expect(_result!.enrichment.kind, 'armure');
    });

    testWidgets('enrichissement : seules la tuile du type actuel est '
        'active', (tester) async {
      await _open(tester, _legacyWeapon, equipped: true);

      expect(
        find.byKey(const Key('customItemKindBlockedCaption')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('customItemKindArmor')));
      await tester.pumpAndSettle();
      // Toujours à l'étape 1 : la tuile « Armure » ne répond pas.
      expect(find.byKey(const Key('customItemKindWeapon')), findsOneWidget);
      expect(find.byKey(const Key('customItemNameField')), findsNothing);

      await _pickKind(tester, 'customItemKindWeapon');
      expect(find.byKey(const Key('customItemNameField')), findsOneWidget);
    });
  });

  group('validations identiques à la création', () {
    testWidgets('nom vidé : Enregistrer désactivé + « Il manque : nom »', (
      tester,
    ) async {
      await _open(tester, _other);

      await tester.enterText(find.byKey(const Key('customItemNameField')), '');
      await tester.pump();

      expect(_saveEnabled(tester), isFalse);
      expect(find.textContaining('Il manque : nom'), findsOneWidget);
    });

    testWidgets('armure : CA 0 refusée, 31 refusée', (tester) async {
      await _open(tester, _armor);

      await tester.enterText(
        find.byKey(const Key('customItemArmorClassField')),
        '31',
      );
      await tester.pump();
      expect(_saveEnabled(tester), isFalse);

      await tester.enterText(
        find.byKey(const Key('customItemArmorClassField')),
        '14',
      );
      await tester.pump();
      expect(_saveEnabled(tester), isTrue);
    });

    testWidgets('poids invalide : Enregistrer désactivé', (tester) async {
      await _open(tester, _armor);

      await tester.ensureVisible(
        find.byKey(const Key('customItemWeightField')),
      );
      await tester.enterText(
        find.byKey(const Key('customItemWeightField')),
        '99999',
      );
      await tester.pump();

      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('Annuler ne renvoie rien', (tester) async {
      await _open(tester, _armor);

      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(_result, isNull);
    });

    testWidgets('Avancé replié quand aucune valeur avancée (bouclier sans '
        'poids)', (tester) async {
      await _open(
        tester,
        const CharacterInventoryItem(
          id: 's2',
          name: 'Rondache',
          quantity: 1,
          equipped: false,
          customKind: CustomItemKinds.shield,
          customAcBase: 2,
        ),
      );

      expect(find.byKey(const Key('customItemMagicBonusToggle')), findsNothing);
      await _openAdvanced(tester);
      expect(
        find.byKey(const Key('customItemMagicBonusToggle')),
        findsOneWidget,
      );
    });
  });

  group('échelles de police sur 320 dp, vraies polices', () {
    for (final scale in [2.0, 3.0]) {
      testWidgets('armure équipée x$scale : aucune exception, enregistrer '
          'atteignable', (tester) async {
        await _open(
          tester,
          _armor,
          scale: scale,
          size: const Size(320, 700),
          equipped: true,
        );

        expect(tester.takeException(), isNull);
        await _save(tester);
        expect(tester.takeException(), isNull);
        expect(_result, isNotNull);
      });

      testWidgets('enrichissement (étape 1) x$scale : aucune exception', (
        tester,
      ) async {
        await _open(
          tester,
          _legacyWeapon,
          scale: scale,
          size: const Size(320, 700),
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('customItemKindWeapon')), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const Key('customItemKindOther')),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('anglais', () {
    testWidgets('titre, bouton et message en anglais', (tester) async {
      await _open(tester, _armor, locale: const Locale('en'), equipped: true);

      expect(find.text('EDIT ITEM'), findsOneWidget);
      expect(find.widgetWithText(PrimaryButton, 'SAVE'), findsOneWidget);
      expect(
        find.text('Unequip the item before changing its type'),
        findsOneWidget,
      );
    });

    testWidgets('enrichissement : titre anglais', (tester) async {
      await _open(tester, _legacySimple, locale: const Locale('en'));

      expect(find.text('ENRICH ITEM'), findsOneWidget);
    });
  });
}

extension on CharacterInventoryItem {
  /// Ancien objet à dé : même objet vu comme déjà typé arme (pour tester le
  /// 1d20 en mode édition).
  CharacterInventoryItem copyWithKind(String kind) => CharacterInventoryItem(
    id: id,
    name: name,
    quantity: quantity,
    equipped: equipped,
    description: description,
    weaponProperties: weaponProperties,
    customKind: kind,
  );
}
