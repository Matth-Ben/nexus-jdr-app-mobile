// Feuilles « Initiative » (version MJ) et « Ajouter un monstre » : validation,
// compteurs, aperçu de la numérotation, « Ajouter et continuer ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/stepper_counter.dart';
import 'package:personnages/features/combat/presentation/widgets/add_monster_sheet.dart';
import 'package:personnages/features/combat/presentation/widgets/initiative_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

import 'combat_test_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget sheet, {
  double scale = 1,
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(body: sheet),
    ),
  );
  await tester.pumpAndSettle();
}

class _Submit {
  final List<({String name, int? initiative, int count})> calls = [];
  String? error;

  Future<String?> call({
    required String name,
    required int? initiative,
    required int count,
  }) async {
    calls.add((name: name, initiative: initiative, count: count));
    return error;
  }
}

Finder get _nameField => find.byKey(const Key('combatMonsterName'));
Finder get _initField => find.byKey(const Key('combatInitiativeField'));

bool _enabled(WidgetTester tester, Type type) {
  if (type == PrimaryButton) {
    return tester
            .widgetList<PrimaryButton>(find.byType(PrimaryButton))
            .first
            .onPressed !=
        null;
  }
  // Dernier bouton secondaire : « Ajouter et continuer » (le premier est le
  // lanceur de d20, toujours actif).
  return tester
          .widgetList<SecondaryButton>(find.byType(SecondaryButton))
          .last
          .onPressed !=
      null;
}

void main() {
  setUpAll(loadCombatFonts);

  group('feuille Initiative (MJ)', () {
    Widget sheet({int? initial}) =>
        InitiativeSheet(participantName: 'Brun', initial: initial);

    testWidgets('titre nominatif, champ vide : Enregistrer désactivé, sans '
        'erreur', (tester) async {
      await _pump(tester, sheet());
      expect(find.text('Initiative de Brun'), findsOneWidget);
      expect(_enabled(tester, PrimaryButton), isFalse);
      expect(find.text('Entre -20 et 60'), findsNothing);
    });

    testWidgets('pas de lanceur de d20 dans la version MJ', (tester) async {
      await _pump(tester, sheet());
      expect(find.textContaining('d20'), findsNothing);
      expect(find.textContaining('D20'), findsNothing);
    });

    testWidgets('valeur valide : Enregistrer renvoie la valeur', (
      tester,
    ) async {
      int? result;
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showInitiativeSheet(
              context,
              participantName: 'Brun',
            ),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.enterText(_initField, '-7');
      await tester.pump();
      expect(_enabled(tester, PrimaryButton), isTrue);
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(result, -7);
    });

    testWidgets('hors bornes : erreur + Enregistrer désactivé', (tester) async {
      await _pump(tester, sheet());
      for (final bad in ['61', '-21', '--', '1-']) {
        await tester.enterText(_initField, bad);
        await tester.pump();
        expect(find.text('Entre -20 et 60'), findsOneWidget, reason: bad);
        expect(_enabled(tester, PrimaryButton), isFalse, reason: bad);
      }
      await tester.enterText(_initField, '60');
      await tester.pump();
      expect(find.text('Entre -20 et 60'), findsNothing);
      expect(_enabled(tester, PrimaryButton), isTrue);
    });

    testWidgets('seuls les chiffres et le signe sont acceptés', (tester) async {
      await _pump(tester, sheet());
      await tester.enterText(_initField, 'a1b2');
      await tester.pump();
      expect(tester.widget<TextField>(_initField).controller!.text, '12');
    });

    testWidgets('compteur − / + : vide donne 10, bornes respectées', (
      tester,
    ) async {
      await _pump(tester, sheet());
      await tester.tap(find.bySemanticsLabel('Augmenter l\'initiative'));
      await tester.pump();
      expect(tester.widget<TextField>(_initField).controller!.text, '10');
      await tester.tap(find.bySemanticsLabel('Augmenter l\'initiative'));
      await tester.pump();
      expect(tester.widget<TextField>(_initField).controller!.text, '11');
      await tester.tap(find.bySemanticsLabel('Diminuer l\'initiative'));
      await tester.pump();
      expect(tester.widget<TextField>(_initField).controller!.text, '10');
      await tester.enterText(_initField, '60');
      await tester.tap(find.bySemanticsLabel('Augmenter l\'initiative'));
      await tester.pump();
      expect(tester.widget<TextField>(_initField).controller!.text, '60');
    });

    testWidgets('compteurs : zone de tap 44×44, champ 44 de haut', (
      tester,
    ) async {
      await _pump(tester, sheet(initial: 5));
      for (final button in tester.widgetList<StepperButton>(
        find.byType(StepperButton),
      )) {
        final size = tester.getSize(find.byWidget(button));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      expect(tester.getSize(_initField).height, greaterThanOrEqualTo(44));
    });

    testWidgets('anglais et ×3,0 sans débordement', (tester) async {
      await _pump(tester, sheet(), scale: 3, locale: const Locale('en'));
      expect(tester.takeException(), isNull);
      expect(find.text('Brun\'s initiative'), findsOneWidget);
    });
  });

  group('feuille Ajouter un monstre', () {
    late _Submit submit;
    final announcements = <String>[];
    var existing = <String>[];

    setUp(() {
      submit = _Submit();
      announcements.clear();
      existing = [];
    });

    Widget sheet() => AddMonsterSheet(
      onSubmit: submit.call,
      existingNames: () => existing,
      announcer: (_, text) => announcements.add(text),
    );

    Future<void> setName(WidgetTester tester, String name) async {
      await tester.enterText(_nameField, name);
      await tester.pump();
    }

    Future<void> plus(
      WidgetTester tester, [
      int times = 1,
      String label = 'Augmenter la quantité',
    ]) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pump();
      }
    }

    testWidgets('« Ajouter » désactivé tant que le nom est vide', (
      tester,
    ) async {
      await _pump(tester, sheet());
      expect(_enabled(tester, PrimaryButton), isFalse);
      expect(_enabled(tester, SecondaryButton), isFalse);
      await setName(tester, '   ');
      expect(_enabled(tester, PrimaryButton), isFalse);
      await setName(tester, 'Gobelin');
      expect(_enabled(tester, PrimaryButton), isTrue);
      expect(_enabled(tester, SecondaryButton), isTrue);
    });

    testWidgets('initiative facultative : absente = null', (tester) async {
      await _pump(tester, sheet());
      await setName(tester, 'Gobelin');
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();
      expect(submit.calls.single, (
        name: 'Gobelin',
        initiative: null,
        count: 1,
      ));
    });

    testWidgets('initiative invalide : erreur et ajout bloqué', (tester) async {
      await _pump(tester, sheet());
      await setName(tester, 'Gobelin');
      await tester.enterText(_initField, '99');
      await tester.pump();
      expect(find.text('Entre -20 et 60'), findsOneWidget);
      expect(_enabled(tester, PrimaryButton), isFalse);
    });

    testWidgets('quantité bornée à 1..20, initiative commune transmise', (
      tester,
    ) async {
      await _pump(tester, sheet());
      await setName(tester, 'Gobelin');
      await tester.enterText(_initField, '14');
      await plus(tester, 25);
      expect(find.text('20'), findsOneWidget);
      final counter = tester.widget<StepperCounter>(
        find.byType(StepperCounter),
      );
      expect(counter.onIncrement, isNull);
      expect(counter.onDecrement, isNotNull);
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();
      expect(submit.calls.single, (name: 'Gobelin', initiative: 14, count: 20));
    });

    testWidgets('quantité minimale : − désactivé à 1', (tester) async {
      await _pump(tester, sheet());
      final counter = tester.widget<StepperCounter>(
        find.byType(StepperCounter),
      );
      expect(counter.value, 1);
      expect(counter.onDecrement, isNull);
    });

    testWidgets('aperçu : N=1 sans suffixe, N≤4 liste, N>4 résumé', (
      tester,
    ) async {
      await _pump(tester, sheet());
      expect(find.byKey(const Key('combatMonsterPreview')), findsNothing);
      await setName(tester, 'Gobelin');
      expect(find.text('Sera ajouté : Gobelin'), findsOneWidget);
      await plus(tester, 2);
      expect(
        find.text('Sera ajouté : Gobelin 1, Gobelin 2, Gobelin 3'),
        findsOneWidget,
      );
      await plus(tester, 5);
      expect(
        find.text('Sera ajouté : Gobelin 1 … Gobelin 8 (8 monstres)'),
        findsOneWidget,
      );
    });

    testWidgets('aperçu : continue après le plus grand suffixe existant', (
      tester,
    ) async {
      existing = ['Gobelin 1', 'Gobelin 2'];
      await _pump(tester, sheet());
      await setName(tester, 'Gobelin');
      await plus(tester);
      expect(find.text('Sera ajouté : Gobelin 3, Gobelin 4'), findsOneWidget);
    });

    testWidgets('aperçu : région vivante polie', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, sheet());
      await setName(tester, 'Orc');
      final node = tester.getSemantics(
        find.byKey(const Key('combatMonsterPreview')),
      );
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('« Ajouter et continuer » : garde la feuille, quantité à 1, '
        'focus sur Nom, annonce', (tester) async {
      await _pump(tester, sheet());
      await setName(tester, 'Orc');
      await plus(tester, 2);
      await tester.tap(find.text('AJOUTER ET CONTINUER'));
      await tester.pumpAndSettle();
      expect(submit.calls.single.count, 3);
      expect(_nameField, findsOneWidget);
      expect(
        tester.widget<StepperCounter>(find.byType(StepperCounter)).value,
        1,
      );
      expect(announcements, ['3 ajoutés']);
      expect(tester.widget<TextField>(_nameField).focusNode!.hasFocus, isTrue);
    });

    testWidgets('annonce au singulier : « 1 ajouté »', (tester) async {
      await _pump(tester, sheet());
      await setName(tester, 'Orc');
      await tester.tap(find.text('AJOUTER ET CONTINUER'));
      await tester.pumpAndSettle();
      expect(announcements, ['1 ajouté']);
    });

    testWidgets('échec : message dans la feuille, feuille conservée', (
      tester,
    ) async {
      submit.error = '60 monstres au maximum par combat.';
      await _pump(tester, sheet());
      await setName(tester, 'Orc');
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();
      expect(find.text('60 monstres au maximum par combat.'), findsOneWidget);
      expect(_nameField, findsOneWidget);
    });

    testWidgets('nom plafonné à 80 caractères', (tester) async {
      await _pump(tester, sheet());
      await tester.enterText(_nameField, 'x' * 120);
      await tester.pump();
      expect(tester.widget<TextField>(_nameField).controller!.text.length, 80);
    });

    testWidgets('×3,0 sur 320 dp sans débordement, anglais', (tester) async {
      await _pump(tester, sheet(), scale: 3, locale: const Locale('en'));
      await setName(tester, 'Goblin');
      await plus(tester, 7, 'Increase quantity');
      expect(tester.takeException(), isNull);
      expect(find.text('Add a monster'), findsOneWidget);
      expect(
        find.text('Will be added: Goblin 1 … Goblin 8 (8 monsters)'),
        findsOneWidget,
      );
    });
  });

  group('libellés sémantiques des champs', () {
    testWidgets('nom et initiative du monstre', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AddMonsterSheet(
          onSubmit: _Submit().call,
          existingNames: () => const [],
        ),
      );
      expect(tester.getSemantics(_nameField).label, contains('Nom'));
      expect(tester.getSemantics(_initField).label, contains('Initiative'));
      expect(
        tester.getSemantics(_nameField).flagsCollection.isTextField,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('initiative (feuille MJ), en anglais', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const InitiativeSheet(participantName: 'Brun'),
        locale: const Locale('en'),
      );
      expect(tester.getSemantics(_initField).label, contains('Initiative'));
      handle.dispose();
    });
  });
}
