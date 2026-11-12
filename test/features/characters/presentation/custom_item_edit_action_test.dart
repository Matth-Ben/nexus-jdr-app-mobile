// P7 PR 4 : actions « Modifier » / « Enrichir » d'un objet personnalisé dans la
// sheet d'actions et l'onglet Inventaire — présence (objets personnalisés
// seulement, jamais le catalogue, jamais en lecture seule), cible tactile,
// ouverture du formulaire pré-rempli, relais du résultat, non-régression de la
// création. Libellés FR/EN, échelles de police sur 320 dp.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/sheet_action_row.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/custom_item_edit_rules.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/custom_item_form_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _typed = CharacterInventoryItem(
  id: 'typed',
  name: 'Bouclier runique',
  quantity: 1,
  equipped: false,
  customKind: CustomItemKinds.shield,
  customAcBase: 3,
);

const _legacy = CharacterInventoryItem(
  id: 'legacy',
  name: 'Vieux sac',
  quantity: 1,
  equipped: false,
);

const _catalog = CharacterInventoryItem(
  id: 'cat',
  itemId: 7,
  name: 'Épée longue',
  category: 'equipement_general',
  quantity: 1,
  equipped: false,
);

CharacterDetail _detail(List<CharacterInventoryItem> inventory) =>
    CharacterDetail(
      id: '1',
      name: 'Test',
      classes: const [
        CharacterDetailClassRow(
          classId: 1,
          className: 'Magicien',
          level: 3,
          isPrimary: true,
          savingThrowProficiencies: [],
          hitDie: 6,
        ),
      ],
      xp: 0,
      currentHp: 10,
      maxHp: 10,
      temporaryHp: 0,
      abilityScores: const {},
      inventory: inventory,
    );

final List<(CharacterInventoryItem, CustomItemFormResult)> _updates = [];
final List<String> _creations = [];

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

Future<void> _pump(
  WidgetTester tester,
  List<CharacterInventoryItem> inventory, {
  bool withEdit = true,
  Locale locale = const Locale('fr'),
  double scale = 1,
  Size size = const Size(390, 2000),
}) async {
  _updates.clear();
  _creations.clear();
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
        body: CharacterInventoryTabBody(
          detail: _detail(inventory),
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
          }) => _creations.add(name),
          onEquipWeaponToSlot: (i, s) {},
          onUpdateCustomInventoryItem: withEdit
              ? (item, result) => _updates.add((item, result))
              : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openActions(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('présence de l\'action', () {
    testWidgets('objet personnalisé typé : « Modifier » (icône edit, cible '
        '>= 44)', (tester) async {
      await _pump(tester, [_typed]);

      await _openActions(tester, 'Bouclier runique');

      expect(find.text('Modifier'), findsOneWidget);
      expect(find.text('Enrichir'), findsNothing);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      final row = find.ancestor(
        of: find.text('Modifier'),
        matching: find.byType(SheetActionRow),
      );
      expect(tester.getSize(row).height, greaterThanOrEqualTo(44));
    });

    testWidgets('ancien objet personnalisé sans type : « Enrichir »', (
      tester,
    ) async {
      await _pump(tester, [_legacy]);

      await _openActions(tester, 'Vieux sac');

      expect(find.text('Enrichir'), findsOneWidget);
      expect(find.text('Modifier'), findsNothing);
    });

    testWidgets('objet du catalogue : JAMAIS d\'action de modification', (
      tester,
    ) async {
      await _pump(tester, [_catalog]);

      await _openActions(tester, 'Épée longue');

      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Enrichir'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('sans callback (vue en lecture seule) : aucune action', (
      tester,
    ) async {
      await _pump(tester, [_typed, _legacy], withEdit: false);

      await _openActions(tester, 'Bouclier runique');

      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Modifier'), findsNothing);
    });

    testWidgets('anglais : Edit / Enrich', (tester) async {
      await _pump(tester, [_typed, _legacy], locale: const Locale('en'));

      await _openActions(tester, 'Bouclier runique');
      expect(find.text('Edit'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await _openActions(tester, 'Vieux sac');
      expect(find.text('Enrich'), findsOneWidget);
    });
  });

  group('ouverture et relais', () {
    testWidgets('Modifier : formulaire pré-rempli (étape 2), Enregistrer '
        'relaie l\'objet et la saisie, la création n\'est pas appelée', (
      tester,
    ) async {
      await _pump(tester, [_typed]);

      await _openActions(tester, 'Bouclier runique');
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      expect(find.text('MODIFIER L\'OBJET'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('customItemNameField')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'Bouclier runique',
      );
      await tester.enterText(
        find.byKey(const Key('customItemNameField')),
        'Égide',
      );
      await tester.pump();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(_updates, hasLength(1));
      expect(_updates.single.$1.id, 'typed');
      expect(_updates.single.$2.name, 'Égide');
      expect(_updates.single.$2.enrichment.kind, 'bouclier');
      expect(_updates.single.$2.enrichment.acBase, 3);
      expect(_creations, isEmpty);
    });

    testWidgets('Enrichir : formulaire à l\'étape 1', (tester) async {
      await _pump(tester, [_legacy]);

      await _openActions(tester, 'Vieux sac');
      await tester.tap(find.text('Enrichir'));
      await tester.pumpAndSettle();

      expect(find.text('ENRICHIR L\'OBJET'), findsOneWidget);
      expect(find.byKey(const Key('customItemKindWeapon')), findsOneWidget);
      expect(_updates, isEmpty);
    });

    testWidgets('Annuler : aucune écriture', (tester) async {
      await _pump(tester, [_typed]);

      await _openActions(tester, 'Bouclier runique');
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(_updates, isEmpty);
    });
  });

  group('règles', () {
    test('mode d\'édition : catalogue null, typé edit, sans type enrich', () {
      expect(customItemEditModeOf(_catalog), isNull);
      expect(customItemEditModeOf(_typed), CustomItemEditMode.edit);
      expect(customItemEditModeOf(_legacy), CustomItemEditMode.enrich);
    });

    test('type d\'un objet équipé : changement interdit, même type permis', () {
      const equippedShield = CharacterInventoryItem(
        id: 'e',
        name: 'Égide',
        quantity: 1,
        equipped: true,
        customKind: CustomItemKinds.shield,
        customAcBase: 2,
      );

      expect(isCustomKindChangeBlocked(equippedShield, 'armure'), isTrue);
      expect(isCustomKindChangeBlocked(equippedShield, 'arme'), isTrue);
      expect(isCustomKindChangeBlocked(equippedShield, 'bouclier'), isFalse);
      expect(isCustomKindChangeBlocked(_typed, 'armure'), isFalse);
    });

    test(
      'valeurs de départ : dé illisible -> 1d6, description vide -> null',
      () {
        const odd = CharacterInventoryItem(
          id: 'o',
          name: 'Bizarre',
          quantity: 1,
          equipped: false,
          customKind: CustomItemKinds.weapon,
          description: '',
          weaponProperties: CharacterInventoryWeaponProperties(
            damageDice: 'beaucoup',
            damageType: 'feu',
            properties: [],
          ),
        );

        final initial = customItemInitialValuesOf(odd);

        expect(initial.diceCount, 1);
        expect(initial.diceSides, 6);
        expect(initial.description, isNull);
      },
    );
  });

  group('échelles de police', () {
    for (final scale in [2.0, 3.0]) {
      testWidgets('feuille d\'actions x$scale sur 320 dp : pas de '
          'débordement, Modifier atteignable', (tester) async {
        await _pump(tester, [_typed], scale: scale, size: const Size(320, 800));

        await _openActions(tester, 'Bouclier runique');

        expect(tester.takeException(), isNull);
        expect(find.text('Modifier'), findsOneWidget);
      });
    }
  });
}
