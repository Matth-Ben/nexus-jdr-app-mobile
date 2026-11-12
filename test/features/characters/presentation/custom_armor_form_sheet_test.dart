// P7 PR 3 : formulaire d'objet personnalisé, types Armure et Bouclier — champs,
// défauts par catégorie, légende, validations et bornes, résultat (CA de base,
// catégorie jamais écrite pour un bouclier), échelles de police sur 320 dp avec
// les vraies polices, FR et EN.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/presentation/widgets/custom_item_form_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

CustomItemFormResult? _result;

Future<void> _load(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

Future<void> _open(
  WidgetTester tester, {
  double scale = 1,
  Locale locale = const Locale('fr'),
  Size size = const Size(390, 1400),
}) async {
  _result = null;
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                _result = await showCustomItemFormSheet(context);
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

Future<void> _pickKind(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _enterName(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('customItemNameField')), name);
  await tester.pump();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

Future<void> _openAdvanced(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('advancedSectionHeader')));
  await tester.tap(find.byKey(const Key('advancedSectionHeader')));
  await tester.pumpAndSettle();
}

Finder get _addButton => find.widgetWithText(PrimaryButton, 'AJOUTER');

bool _addEnabled(WidgetTester tester) =>
    tester.widget<PrimaryButton>(_addButton).onPressed != null;

String _acText(WidgetTester tester) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('customItemArmorClassField')),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

void main() {
  setUpAll(() async {
    await _load('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _load('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('Armure', () {
    testWidgets('champs visibles : nom, catégorie (légère par défaut), CA 11, '
        'légende, ligne Dextérité en lecture seule', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');

      expect(find.text('Type : Armure'), findsOneWidget);
      expect(find.byKey(const Key('customItemNameField')), findsOneWidget);
      expect(find.text('CATÉGORIE D\'ARMURE'), findsOneWidget);
      expect(find.text('LÉGÈRE'), findsOneWidget);
      expect(find.text('INTERMÉDIAIRE'), findsOneWidget);
      expect(find.text('LOURDE'), findsOneWidget);
      expect(find.text('CA DE BASE'), findsOneWidget);
      expect(_acText(tester), '11');
      expect(
        find.textContaining('Légère 11-12, intermédiaire 12-15, lourde 14-18'),
        findsOneWidget,
      );
      expect(find.text('Bonus de Dextérité : illimité'), findsOneWidget);
      // Ni dés, ni type de dégâts, ni propriétés d'arme.
      expect(find.byKey(const Key('customItemDiceSidesField')), findsNothing);
      expect(find.byKey(const Key('customItemDamageTypeField')), findsNothing);
      expect(find.byKey(const Key('customItemPropertiesField')), findsNothing);
      // Section avancée repliée.
      expect(find.byKey(const Key('customItemMagicBonusToggle')), findsNothing);
    });

    testWidgets('la CA proposée suit la catégorie (11/14/16) et la ligne '
        'Dextérité aussi', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');

      await tester.tap(find.text('INTERMÉDIAIRE'));
      await tester.pumpAndSettle();
      expect(_acText(tester), '14');
      expect(find.text('Bonus de Dextérité : plafonné à +2'), findsOneWidget);

      await tester.tap(find.text('LOURDE'));
      await tester.pumpAndSettle();
      expect(_acText(tester), '16');
      expect(find.text('Bonus de Dextérité : aucun'), findsOneWidget);

      await tester.tap(find.text('LÉGÈRE'));
      await tester.pumpAndSettle();
      expect(_acText(tester), '11');
    });

    testWidgets('une CA saisie à la main n\'est plus remplacée par un '
        'changement de catégorie (la légende n\'est qu\'une aide)', (
      tester,
    ) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');

      await _enter(tester, 'customItemArmorClassField', '20');
      await tester.tap(find.text('LOURDE'));
      await tester.pumpAndSettle();
      expect(_acText(tester), '20');

      await _enterName(tester, 'Plate runique');
      expect(_addEnabled(tester), isTrue);
    });

    testWidgets('« Ajouter » désactivé sans nom ; la ligne « Il manque » '
        'est une région vivante', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');

      expect(_addEnabled(tester), isFalse);
      expect(find.text('Il manque : nom'), findsOneWidget);
      final line = find.ancestor(
        of: find.text('Il manque : nom'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      );
      expect(line, findsWidgets);
    });

    testWidgets('bornes de la CA : vide, 0 et 31 refusés (erreur inline), '
        '1 et 30 acceptés', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');
      await _enterName(tester, 'Cotte');

      await _enter(tester, 'customItemArmorClassField', '');
      expect(_addEnabled(tester), isFalse);
      expect(find.text('Il manque : CA de base'), findsOneWidget);

      for (final bad in ['0', '31', '99']) {
        await _enter(tester, 'customItemArmorClassField', bad);
        expect(_addEnabled(tester), isFalse, reason: bad);
        expect(find.text('Entrez une CA entre 1 et 30.'), findsOneWidget);
      }
      for (final good in ['1', '30', '15']) {
        await _enter(tester, 'customItemArmorClassField', good);
        expect(_addEnabled(tester), isTrue, reason: good);
        expect(find.text('Entrez une CA entre 1 et 30.'), findsNothing);
      }
    });

    testWidgets('clavier numérique, chiffres seulement', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('customItemArmorClassField')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.keyboardType, TextInputType.number);
      await _enter(tester, 'customItemArmorClassField', '1a4,5');
      expect(_acText(tester), '145');
    });

    testWidgets('résultat : kind armure, CA, catégorie, bonus magique, poids, '
        'harmonisation, description ; valide', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');
      await _enterName(tester, '  Cotte de mithril ');
      await tester.tap(find.text('INTERMÉDIAIRE'));
      await tester.pumpAndSettle();
      await _enter(tester, 'customItemArmorClassField', '15');

      await _openAdvanced(tester);
      await tester.ensureVisible(find.text('+2'));
      await tester.tap(find.text('+2'));
      await tester.pump();
      await _enter(tester, 'customItemWeightField', '9,5');
      await tester.ensureVisible(
        find.byKey(const Key('customItemRequiresAttunementSwitch')),
      );
      await tester.tap(
        find.byKey(const Key('customItemRequiresAttunementSwitch')),
      );
      await tester.pumpAndSettle();
      await _enter(
        tester,
        'customItemDescriptionField',
        'Légère comme l\'air.',
      );

      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();

      final result = _result!;
      expect(result.name, 'Cotte de mithril');
      expect(result.description, 'Légère comme l\'air.');
      expect(result.damageDice, isNull);
      expect(result.damageType, isNull);
      final e = result.enrichment;
      expect(e.kind, CustomItemKinds.armor);
      expect(e.acBase, 15);
      expect(e.armorCategory, CustomArmorCategories.medium);
      expect(e.magicBonus, 2);
      expect(e.weight, 9.5);
      expect(e.requiresAttunement, isTrue);
      expect(e.weaponCategory, isNull);
      expect(e.weaponRange, isNull);
      expect(e.isValid, isTrue);
    });

    testWidgets('défauts : catégorie légère, CA 11, sans bonus magique', (
      tester,
    ) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');
      await _enterName(tester, 'Cuir');
      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();

      final e = _result!.enrichment;
      expect(e.acBase, 11);
      expect(e.armorCategory, CustomArmorCategories.light);
      expect(e.magicBonus, 0);
      expect(e.weight, isNull);
      expect(e.isValid, isTrue);
      expect(e.toInsertColumns(), {
        'custom_kind': 'armure',
        'custom_ac_base': 11,
        'custom_armor_category': 'legere',
      });
    });

    testWidgets('« Changer » conserve nom et CA saisie', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');
      await _enterName(tester, 'Maison');
      await _enter(tester, 'customItemArmorClassField', '19');

      await tester.tap(find.byKey(const Key('customItemChangeKindButton')));
      await tester.pumpAndSettle();
      await _pickKind(tester, 'customItemKindArmor');

      expect(find.text('Maison'), findsOneWidget);
      expect(_acText(tester), '19');
    });
  });

  group('Bouclier', () {
    testWidgets('champs visibles : bonus de CA +2 par défaut, légende, ni '
        'catégorie ni Dextérité', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindShield');

      expect(find.text('Type : Bouclier'), findsOneWidget);
      expect(find.text('BONUS DE CA'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('customItemShieldBonusField')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, '2');
      expect(field.keyboardType, TextInputType.number);
      expect(
        find.text('Un bouclier standard donne +2 à la CA.'),
        findsOneWidget,
      );
      expect(find.text('CATÉGORIE D\'ARMURE'), findsNothing);
      expect(find.byKey(const Key('customItemArmorDexLine')), findsNothing);
    });

    testWidgets('bornes du bonus : 0, 6 refusés ; 1 et 5 acceptés', (
      tester,
    ) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindShield');
      await _enterName(tester, 'Pavois');

      expect(_addEnabled(tester), isTrue);
      for (final bad in ['', '0', '6', '12']) {
        await _enter(tester, 'customItemShieldBonusField', bad);
        expect(_addEnabled(tester), isFalse, reason: '"$bad"');
      }
      expect(find.text('Entrez un bonus entre 1 et 5.'), findsOneWidget);
      for (final good in ['1', '5', '3']) {
        await _enter(tester, 'customItemShieldBonusField', good);
        expect(_addEnabled(tester), isTrue, reason: good);
      }
    });

    testWidgets('résultat : kind bouclier, CA = bonus, JAMAIS de catégorie '
        'd\'armure, bonus magique', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindShield');
      await _enterName(tester, 'Égide');
      await _enter(tester, 'customItemShieldBonusField', '3');
      await _openAdvanced(tester);
      await tester.ensureVisible(find.text('+1'));
      await tester.tap(find.text('+1'));
      await tester.pump();

      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();

      final e = _result!.enrichment;
      expect(e.kind, CustomItemKinds.shield);
      expect(e.acBase, 3);
      expect(e.armorCategory, isNull);
      expect(e.magicBonus, 1);
      expect(e.isValid, isTrue);
      expect(e.toInsertColumns().containsKey('custom_armor_category'), isFalse);
      expect(
        e.toPayload().containsKey(CustomItemPayloadKeys.armorCategory),
        isFalse,
      );
    });

    testWidgets('passer d\'une armure à un bouclier n\'envoie pas la '
        'catégorie d\'armure choisie', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindArmor');
      await tester.tap(find.text('LOURDE'));
      await tester.pumpAndSettle();
      await _enterName(tester, 'Hybride');
      await tester.tap(find.byKey(const Key('customItemChangeKindButton')));
      await tester.pumpAndSettle();
      await _pickKind(tester, 'customItemKindShield');

      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();

      final e = _result!.enrichment;
      expect(e.kind, CustomItemKinds.shield);
      expect(e.acBase, 2);
      expect(e.armorCategory, isNull);
    });
  });

  group('police agrandie sur 320 dp (vraies polices)', () {
    for (final locale in [const Locale('fr'), const Locale('en')]) {
      for (final scale in [2.0, 3.0]) {
        for (final kind in ['Armor', 'Shield']) {
          testWidgets('${locale.languageCode} x$scale : $kind sans '
              'débordement, sélecteurs en liste verticale, cibles >= 44', (
            tester,
          ) async {
            await _open(
              tester,
              scale: scale,
              locale: locale,
              size: const Size(320, 640),
            );
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(find.byKey(Key('customItemKind$kind')));
            await tester.tap(find.byKey(Key('customItemKind$kind')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.enterText(
              find.byKey(const Key('customItemNameField')),
              'Armure de plaques des anciens rois',
            );
            await tester.pump();

            if (kind == 'Armor') {
              await tester.ensureVisible(
                find.byKey(const Key('customItemArmorCategoryTile_lourde')),
              );
              expect(
                find.byKey(const Key('customItemArmorCategoryToggle')),
                findsNothing,
              );
              await tester.tap(
                find.byKey(const Key('customItemArmorCategoryTile_lourde')),
              );
              await tester.pumpAndSettle();
              expect(_acText(tester), '16');
              expect(
                tester
                    .getSize(
                      find.byKey(
                        const Key('customItemArmorCategoryTile_lourde'),
                      ),
                    )
                    .height,
                greaterThanOrEqualTo(44),
              );
            }
            final field = kind == 'Armor'
                ? 'customItemArmorClassField'
                : 'customItemShieldBonusField';
            await tester.ensureVisible(find.byKey(Key(field)));
            expect(
              tester.getSize(find.byKey(Key(field))).height,
              greaterThanOrEqualTo(44),
            );

            await tester.ensureVisible(
              find.byKey(const Key('advancedSectionHeader')),
            );
            await tester.tap(find.byKey(const Key('advancedSectionHeader')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(
              find.byKey(const Key('customItemMagicBonusTile_2')),
            );
            expect(
              find.byKey(const Key('customItemMagicBonusToggle')),
              findsNothing,
            );
            await tester.tap(
              find.byKey(const Key('customItemMagicBonusTile_2')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            // Pied en colonne.
            final add = locale.languageCode == 'fr' ? 'AJOUTER' : 'ADD';
            final cancel = locale.languageCode == 'fr' ? 'ANNULER' : 'CANCEL';
            final addBox = tester.getRect(
              find.widgetWithText(PrimaryButton, add),
            );
            expect(addBox.top, lessThan(tester.getRect(find.text(cancel)).top));
            expect(addBox.right, lessThanOrEqualTo(320));

            for (final text in tester.widgetList<Text>(find.byType(Text))) {
              final size = text.style?.fontSize;
              if (size != null) expect(size, greaterThanOrEqualTo(11));
            }
          });
        }
      }
    }

    testWidgets('EN x1 : libellés anglais, défauts et légende', (tester) async {
      await _open(tester, locale: const Locale('en'));
      await tester.tap(find.byKey(const Key('customItemKindArmor')));
      await tester.pumpAndSettle();

      expect(find.text('Type: Armor'), findsOneWidget);
      expect(find.text('ARMOR CATEGORY'), findsOneWidget);
      expect(find.text('BASE AC'), findsOneWidget);
      expect(find.text('Dexterity bonus: unlimited'), findsOneWidget);
      expect(
        find.textContaining('Light 11-12, medium 12-15, heavy 14-18'),
        findsOneWidget,
      );
      await tester.tap(find.text('MEDIUM'));
      await tester.pumpAndSettle();
      expect(_acText(tester), '14');
      expect(find.text('Dexterity bonus: capped at +2'), findsOneWidget);
    });
  });
}
