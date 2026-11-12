// P7 PR 2 : formulaire d'objet personnalisé en deux temps (Arme, Objet magique
// ou autre) — étape 1, étape 2 par type, « Changer », validations, section
// avancée, harmonisation (plafond de 3), échelles de police sur 320 dp avec
// les vraies polices.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/stepper_counter.dart';
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
  int? attunedCount,
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
                _result = await showCustomItemFormSheet(
                  context,
                  attunedCount: attunedCount,
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

Future<void> _pickKind(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _enterName(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('customItemNameField')), name);
  await tester.pump();
}

Future<void> _openAdvanced(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('advancedSectionHeader')));
  await tester.tap(find.byKey(const Key('advancedSectionHeader')));
  await tester.pumpAndSettle();
}

Future<void> _pickDamageType(WidgetTester tester, String label) async {
  await tester.ensureVisible(
    find.byKey(const Key('customItemDamageTypeField')),
  );
  await tester.tap(find.byKey(const Key('customItemDamageTypeField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder get _addButton => find.widgetWithText(PrimaryButton, 'AJOUTER');

bool _addEnabled(WidgetTester tester) =>
    tester.widget<PrimaryButton>(_addButton).onPressed != null;

Finder get _increment => find.byWidgetPredicate(
  (widget) => widget is Icon && widget.semanticLabel == 'Augmenter',
);

void main() {
  setUpAll(() async {
    await _load('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _load('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('étape 1 : type d\'objet', () {
    testWidgets('deux types seulement (Arme, Objet magique ou autre), ni '
        'Armure ni Bouclier, pied réduit à « Annuler »', (tester) async {
      await _open(tester);

      expect(find.text('TYPE D\'OBJET'), findsOneWidget);
      expect(find.byKey(const Key('customItemKindWeapon')), findsOneWidget);
      expect(find.byKey(const Key('customItemKindOther')), findsOneWidget);
      expect(find.text('Arme'), findsOneWidget);
      expect(find.text('Objet magique ou autre'), findsOneWidget);
      expect(find.text('Armure'), findsNothing);
      expect(find.text('Bouclier'), findsNothing);
      expect(find.text('ANNULER'), findsOneWidget);
      expect(_addButton, findsNothing);
      // Aucun champ de formulaire avant le choix du type.
      expect(find.byKey(const Key('customItemNameField')), findsNothing);
    });

    testWidgets('les tuiles de type font au moins 64 dp de haut', (
      tester,
    ) async {
      await _open(tester);

      for (final key in ['customItemKindWeapon', 'customItemKindOther']) {
        expect(
          tester.getSize(find.byKey(Key(key))).height,
          greaterThanOrEqualTo(64),
        );
      }
    });

    testWidgets('« Annuler » ferme sans résultat', (tester) async {
      await _open(tester);

      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(_result, isNull);
      expect(find.text('TYPE D\'OBJET'), findsNothing);
    });
  });

  group('étape 2 : Arme', () {
    testWidgets('champs visibles, défaut 1d6, type de dégâts sans défaut, '
        'section avancée repliée', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindWeapon');

      expect(find.text('Type : Arme'), findsOneWidget);
      expect(find.byKey(const Key('customItemNameField')), findsOneWidget);
      expect(find.byKey(const Key('customItemDiceSidesField')), findsOneWidget);
      expect(
        find.byKey(const Key('customItemDamageTypeField')),
        findsOneWidget,
      );
      expect(find.text('Sélectionner'), findsOneWidget);
      expect(find.text('CATÉGORIE D\'ARME'), findsOneWidget);
      expect(find.text('PORTÉE'), findsOneWidget);
      final dice = tester.widgetList<StepperCounter>(
        find.byType(StepperCounter),
      );
      expect(dice.first.value, 1);
      // Avancé replié : ni bonus magique, ni propriétés, ni poids.
      expect(find.text('Options avancées'), findsOneWidget);
      expect(find.byKey(const Key('customItemWeightField')), findsNothing);
      expect(find.byKey(const Key('customItemPropertiesField')), findsNothing);
      expect(find.text('BONUS MAGIQUE'), findsNothing);
    });

    testWidgets('« Ajouter » désactivé tant que nom ET type de dégâts '
        'manquent, ligne « Il manque » mise à jour', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindWeapon');

      expect(_addEnabled(tester), isFalse);
      expect(find.text('Il manque : nom, type de dégâts'), findsOneWidget);

      await _enterName(tester, 'Lame solaire');
      expect(_addEnabled(tester), isFalse);
      expect(find.text('Il manque : type de dégâts'), findsOneWidget);

      await _pickDamageType(tester, 'Radiant');
      expect(_addEnabled(tester), isTrue);
      expect(find.textContaining('Il manque'), findsNothing);
    });

    testWidgets('la ligne « Il manque » est une région vivante', (
      tester,
    ) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindWeapon');

      expect(
        find.ancestor(
          of: find.text('Il manque : nom, type de dégâts'),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('les 13 types de dégâts sont proposés', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindWeapon');
      await tester.tap(find.byKey(const Key('customItemDamageTypeField')));
      await tester.pumpAndSettle();

      expect(CustomDamageTypes.all, hasLength(13));
      for (final label in [
        'Tranchant',
        'Perforant',
        'Contondant',
        'Acide',
        'Feu',
        'Foudre',
        'Froid',
        'Force',
        'Nécrotique',
        'Poison',
        'Psychique',
        'Radiant',
        'Tonnerre',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
    });

    testWidgets('dés : de 1 à 10, faces d4 à d12 (pas de d20)', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindWeapon');

      for (var i = 0; i < 12; i++) {
        final button = _increment.first;
        await tester.tap(button, warnIfMissed: false);
        await tester.pump();
      }
      expect(
        tester
            .widgetList<StepperCounter>(find.byType(StepperCounter))
            .first
            .value,
        10,
      );

      await tester.tap(find.byKey(const Key('customItemDiceSidesField')));
      await tester.pumpAndSettle();
      for (final sides in ['4', '8', '10', '12']) {
        expect(find.text(sides), findsWidgets, reason: 'd$sides');
      }
      expect(find.text('20'), findsNothing);
    });

    testWidgets('résultat complet : dé, type, catégorie, portée, bonus '
        'magique, propriétés, poids (virgule), harmonisation, description', (
      tester,
    ) async {
      await _open(tester, attunedCount: 1);
      await _pickKind(tester, 'customItemKindWeapon');
      await _enterName(tester, '  Lame solaire ');
      await tester.tap(_increment.first);
      await tester.pump();
      await tester.tap(find.byKey(const Key('customItemDiceSidesField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8').last);
      await tester.pumpAndSettle();
      await _pickDamageType(tester, 'Radiant');
      await tester.tap(find.text('DE GUERRE'));
      await tester.pump();
      await tester.tap(find.text('DISTANCE'));
      await tester.pump();

      await _openAdvanced(tester);
      await tester.tap(find.text('+2'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('customItemPropertiesField')),
        'légère, finesse, ,',
      );
      await tester.enterText(
        find.byKey(const Key('customItemWeightField')),
        '1,5',
      );
      await tester.tap(
        find.byKey(const Key('customItemRequiresAttunementSwitch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customItemAttuneNowSwitch')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customItemDescriptionField')),
        'Brille.',
      );
      await tester.ensureVisible(_increment.last);
      await tester.tap(_increment.last);
      await tester.pump();

      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();

      final result = _result!;
      expect(result.name, 'Lame solaire');
      expect(result.quantity, 2);
      expect(result.damageDice, '2d8');
      expect(result.damageType, 'radiant');
      expect(result.properties, ['légère', 'finesse']);
      expect(result.description, 'Brille.');
      final e = result.enrichment;
      expect(e.kind, CustomItemKinds.weapon);
      expect(e.magicBonus, 2);
      expect(e.weight, 1.5);
      expect(e.requiresAttunement, isTrue);
      expect(e.attuneNow, isTrue);
      expect(e.weaponCategory, CustomWeaponCategories.martial);
      expect(e.weaponRange, CustomWeaponRanges.ranged);
      expect(e.isValid, isTrue);
    });

    testWidgets('catégorie et portée non choisies : null (maîtrise non '
        'évaluée), légendes affichées, poids au point accepté', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindWeapon');
      await _enterName(tester, 'Gourdin');
      await _pickDamageType(tester, 'Contondant');

      expect(
        find.text(
          'Non renseignée : la maîtrise de l\'arme ne sera pas évaluée.',
        ),
        findsOneWidget,
      );
      await _openAdvanced(tester);
      await tester.enterText(
        find.byKey(const Key('customItemWeightField')),
        '2.25',
      );
      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();

      final e = _result!.enrichment;
      expect(e.weaponCategory, isNull);
      expect(e.weaponRange, isNull);
      expect(e.magicBonus, 0);
      expect(e.weight, 2.25);
      expect(e.requiresAttunement, isFalse);
      expect(e.attuneNow, isFalse);
    });
  });

  group('étape 2 : Objet magique ou autre', () {
    testWidgets('nom + description visibles, ni dés ni bonus magique ; '
        'résultat sans champ d\'arme', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindOther');

      expect(find.text('Type : Objet magique ou autre'), findsOneWidget);
      expect(
        find.byKey(const Key('customItemDescriptionField')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('customItemDiceSidesField')), findsNothing);
      expect(find.byKey(const Key('customItemDamageTypeField')), findsNothing);
      await _openAdvanced(tester);
      expect(find.text('BONUS MAGIQUE'), findsNothing);
      expect(find.byKey(const Key('customItemWeightField')), findsOneWidget);
      expect(
        find.byKey(const Key('customItemRequiresAttunementSwitch')),
        findsOneWidget,
      );

      await _enterName(tester, 'Anneau étrange');
      expect(find.textContaining('Il manque'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('customItemDescriptionField')),
        'Froid au doigt.',
      );
      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();

      final result = _result!;
      expect(result.name, 'Anneau étrange');
      expect(result.description, 'Froid au doigt.');
      expect(result.damageDice, isNull);
      expect(result.damageType, isNull);
      expect(result.properties, isEmpty);
      expect(result.enrichment.kind, CustomItemKinds.other);
      expect(result.enrichment.magicBonus, 0);
      expect(result.enrichment.weight, isNull);
    });
  });

  group('« Changer »', () {
    testWidgets('conserve nom, quantité, poids, harmonisation et '
        'description en changeant de type', (tester) async {
      await _open(tester, attunedCount: 0);
      await _pickKind(tester, 'customItemKindWeapon');
      await _enterName(tester, 'Anneau de Zarn');
      await _openAdvanced(tester);
      await tester.enterText(
        find.byKey(const Key('customItemWeightField')),
        '0,5',
      );
      await tester.tap(
        find.byKey(const Key('customItemRequiresAttunementSwitch')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customItemDescriptionField')),
        'Forgé au nord.',
      );
      await tester.ensureVisible(_increment.last);
      await tester.tap(_increment.last);
      await tester.pump();

      await tester.ensureVisible(
        find.byKey(const Key('customItemChangeKindButton')),
      );
      await tester.tap(find.byKey(const Key('customItemChangeKindButton')));
      await tester.pumpAndSettle();
      // Retour à l'étape 1.
      expect(find.byKey(const Key('customItemKindOther')), findsOneWidget);
      await _pickKind(tester, 'customItemKindOther');

      expect(find.text('Type : Objet magique ou autre'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('customItemNameField')))
            .controller!
            .text,
        'Anneau de Zarn',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('customItemDescriptionField')),
            )
            .controller!
            .text,
        'Forgé au nord.',
      );
      // Valeur non vide : la section avancée s'ouvre d'elle-même.
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('customItemWeightField')),
            )
            .controller!
            .text,
        '0,5',
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
      expect(
        tester
            .widgetList<StepperCounter>(find.byType(StepperCounter))
            .last
            .value,
        2,
      );

      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();
      expect(_result!.name, 'Anneau de Zarn');
      expect(_result!.quantity, 2);
      expect(_result!.enrichment.kind, CustomItemKinds.other);
      expect(_result!.enrichment.weight, 0.5);
      expect(_result!.enrichment.requiresAttunement, isTrue);
    });

    testWidgets('le bouton « Changer » fait au moins 44 dp', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindWeapon');

      final size = tester.getSize(
        find.byKey(const Key('customItemChangeKindButton')),
      );
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    });
  });

  group('validations', () {
    testWidgets('poids hors bornes : erreur inline, section avancée dépliée, '
        '« Ajouter » désactivé ; valeur valide : erreur retirée', (
      tester,
    ) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindOther');
      await _enterName(tester, 'Sac');
      await _openAdvanced(tester);

      for (final bad in ['10000', '9999,991', '1.2.3', ',']) {
        await tester.enterText(
          find.byKey(const Key('customItemWeightField')),
          bad,
        );
        await tester.pump();
        expect(
          find.text('Entrez un poids entre 0 et 9 999,99 kg.'),
          findsOneWidget,
          reason: bad,
        );
        expect(_addEnabled(tester), isFalse, reason: bad);
      }
      for (final good in ['0', '9999,99', '9999.99', '']) {
        await tester.enterText(
          find.byKey(const Key('customItemWeightField')),
          good,
        );
        await tester.pump();
        expect(
          find.text('Entrez un poids entre 0 et 9 999,99 kg.'),
          findsNothing,
          reason: good,
        );
        expect(_addEnabled(tester), isTrue, reason: good);
      }
    });

    testWidgets('poids décimal : clavier numérique avec virgule/point, '
        'caractères parasites filtrés', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindOther');
      await _openAdvanced(tester);

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('customItemWeightField')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.keyboardType.decimal, isTrue);
      await tester.enterText(
        find.byKey(const Key('customItemWeightField')),
        'a1,5kg',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('customItemWeightField')),
            )
            .controller!
            .text,
        '1,5',
      );
    });

    testWidgets('nom de plus de 200 caractères : erreur inline, refusé', (
      tester,
    ) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindOther');

      await _enterName(tester, 'x' * 201);

      expect(find.text('200 caractères au plus.'), findsOneWidget);
      expect(_addEnabled(tester), isFalse);
      await _enterName(tester, 'x' * 200);
      expect(find.text('200 caractères au plus.'), findsNothing);
      expect(_addEnabled(tester), isTrue);
    });

    testWidgets('un poids invalide déplie la section avancée même repliée '
        '(valeur saisie, puis retour d\'étape)', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindOther');
      await _openAdvanced(tester);
      await tester.enterText(
        find.byKey(const Key('customItemWeightField')),
        '99999',
      );
      await tester.pump();

      await tester.ensureVisible(
        find.byKey(const Key('customItemChangeKindButton')),
      );
      await tester.tap(find.byKey(const Key('customItemChangeKindButton')));
      await tester.pumpAndSettle();
      await _pickKind(tester, 'customItemKindWeapon');

      expect(find.byKey(const Key('customItemWeightField')), findsOneWidget);
      expect(
        find.text('Entrez un poids entre 0 et 9 999,99 kg.'),
        findsOneWidget,
      );
    });
  });

  group('harmonisation', () {
    testWidgets('« Harmoniser maintenant » absent tant que l\'harmonisation '
        'n\'est pas requise, ou si le nombre d\'objets harmonisés est '
        'inconnu', (tester) async {
      await _open(tester, attunedCount: 0);
      await _pickKind(tester, 'customItemKindOther');
      await _openAdvanced(tester);

      expect(find.byKey(const Key('customItemAttuneNowSwitch')), findsNothing);
      await tester.tap(
        find.byKey(const Key('customItemRequiresAttunementSwitch')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('customItemAttuneNowSwitch')),
        findsOneWidget,
      );
    });

    testWidgets('nombre inconnu : pas de second interrupteur', (tester) async {
      await _open(tester);
      await _pickKind(tester, 'customItemKindOther');
      await _openAdvanced(tester);
      await tester.tap(
        find.byKey(const Key('customItemRequiresAttunementSwitch')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('customItemAttuneNowSwitch')), findsNothing);
    });

    for (final count in [0, 1, 2]) {
      testWidgets('$count objet(s) harmonisé(s) : « Harmoniser maintenant » '
          'actif, résultat harmonisé', (tester) async {
        await _open(tester, attunedCount: count);
        await _pickKind(tester, 'customItemKindOther');
        await _enterName(tester, 'Cape');
        await _openAdvanced(tester);
        await tester.tap(
          find.byKey(const Key('customItemRequiresAttunementSwitch')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('customItemAttuneNowSwitch')));
        await tester.pumpAndSettle();

        expect(find.textContaining('Vous avez déjà'), findsNothing);
        await tester.ensureVisible(_addButton);
        await tester.tap(_addButton);
        await tester.pumpAndSettle();
        expect(_result!.enrichment.requiresAttunement, isTrue);
        expect(_result!.enrichment.attuneNow, isTrue);
      });
    }

    for (final count in [3, 4]) {
      testWidgets('$count objets harmonisés : « Harmoniser maintenant » '
          'désactivé, légende, création jamais bloquée (non harmonisé)', (
        tester,
      ) async {
        await _open(tester, attunedCount: count);
        await _pickKind(tester, 'customItemKindOther');
        await _enterName(tester, 'Cape');
        await _openAdvanced(tester);
        await tester.tap(
          find.byKey(const Key('customItemRequiresAttunementSwitch')),
        );
        await tester.pumpAndSettle();

        final attuneNow = tester.widget<SwitchListTile>(
          find.descendant(
            of: find.byKey(const Key('customItemAttuneNowSwitch')),
            matching: find.byType(SwitchListTile),
          ),
        );
        expect(attuneNow.onChanged, isNull);
        expect(attuneNow.value, isFalse);
        expect(
          find.textContaining('Vous avez déjà $count objets harmonisés'),
          findsOneWidget,
        );
        expect(_addEnabled(tester), isTrue);

        await tester.ensureVisible(_addButton);
        await tester.tap(_addButton);
        await tester.pumpAndSettle();
        expect(_result!.enrichment.requiresAttunement, isTrue);
        expect(_result!.enrichment.attuneNow, isFalse);
      });
    }

    testWidgets('décocher « Nécessite une harmonisation » efface '
        '« Harmoniser maintenant »', (tester) async {
      await _open(tester, attunedCount: 0);
      await _pickKind(tester, 'customItemKindOther');
      await _enterName(tester, 'Cape');
      await _openAdvanced(tester);
      final requires = find.byKey(
        const Key('customItemRequiresAttunementSwitch'),
      );
      await tester.tap(requires);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customItemAttuneNowSwitch')));
      await tester.pumpAndSettle();
      await tester.tap(requires);
      await tester.pumpAndSettle();
      await tester.tap(requires);
      await tester.pumpAndSettle();

      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();
      expect(_result!.enrichment.requiresAttunement, isTrue);
      expect(_result!.enrichment.attuneNow, isFalse);
    });

    testWidgets('les interrupteurs font au moins 56 dp de haut', (
      tester,
    ) async {
      await _open(tester, attunedCount: 0);
      await _pickKind(tester, 'customItemKindOther');
      await _openAdvanced(tester);
      await tester.tap(
        find.byKey(const Key('customItemRequiresAttunementSwitch')),
      );
      await tester.pumpAndSettle();

      for (final key in [
        'customItemRequiresAttunementSwitch',
        'customItemAttuneNowSwitch',
      ]) {
        expect(
          tester.getSize(find.byKey(Key(key))).height,
          greaterThanOrEqualTo(56),
          reason: key,
        );
      }
    });
  });

  group('police agrandie sur 320 dp (vraies polices)', () {
    for (final locale in [const Locale('fr'), const Locale('en')]) {
      for (final scale in [2.0, 3.0]) {
        testWidgets('${locale.languageCode} x$scale : étape 1 et formulaire '
            'Arme complet sans débordement, pied en colonne', (tester) async {
          await _open(
            tester,
            attunedCount: 3,
            scale: scale,
            locale: locale,
            size: const Size(320, 640),
          );
          expect(tester.takeException(), isNull);

          await tester.tap(find.byKey(const Key('customItemKindWeapon')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.enterText(
            find.byKey(const Key('customItemNameField')),
            'Épée longue des ténèbres éternelles',
          );
          await tester.pump();
          await tester.ensureVisible(
            find.byKey(const Key('advancedSectionHeader')),
          );
          await tester.tap(find.byKey(const Key('advancedSectionHeader')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Sélecteurs en liste verticale (tuiles) plutôt qu'en bascule.
          await tester.ensureVisible(
            find.byKey(const Key('customItemMagicBonusTile_3')),
          );
          expect(
            find.byKey(const Key('customItemMagicBonusToggle')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('customItemMagicBonusTile_3')),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const Key('customItemRequiresAttunementSwitch')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Pied en colonne : « Ajouter » au-dessus de « Annuler ».
          final add = locale.languageCode == 'fr' ? 'AJOUTER' : 'ADD';
          final cancel = locale.languageCode == 'fr' ? 'ANNULER' : 'CANCEL';
          final addBox = tester.getRect(
            find.widgetWithText(PrimaryButton, add),
          );
          final cancelBox = tester.getRect(find.text(cancel));
          expect(addBox.top, lessThan(cancelBox.top));
          expect(addBox.left, lessThanOrEqualTo(cancelBox.left));
          expect(addBox.right, lessThanOrEqualTo(320));

          // Aucun texte sous 11 px.
          for (final text in tester.widgetList<Text>(find.byType(Text))) {
            final size = text.style?.fontSize;
            if (size != null) expect(size, greaterThanOrEqualTo(11));
          }
        });
      }
    }

    testWidgets('x1 : pied en ligne (Annuler et Ajouter côte à côte)', (
      tester,
    ) async {
      await _open(tester, size: const Size(320, 640));
      await tester.tap(find.byKey(const Key('customItemKindOther')));
      await tester.pumpAndSettle();

      final add = tester.getRect(_addButton);
      final cancel = tester.getRect(find.text('ANNULER'));
      expect((add.center.dy - cancel.center.dy).abs(), lessThan(8));
    });
  });
}
