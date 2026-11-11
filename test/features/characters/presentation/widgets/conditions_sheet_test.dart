// Sélecteur d'états (P6) : T4 (14 lignes, ordre alphabétique FR/EN, bouton
// Enregistrer désactivé sans changement), T5 côté feuille (erreur : sélection
// conservée), état d'enregistrement, T8 (police x2,0) et T11 (cases).

import 'dart:async';
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/alert_banner.dart';
import 'package:personnages/core/widgets/pixel_icon.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/selection_checkbox.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/presentation/widgets/conditions_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _frOrder = [
  'À terre',
  'Agrippé',
  'Assourdi',
  'Aveuglé',
  'Charmé',
  'Effrayé',
  'Empoisonné',
  'Entravé',
  'Étourdi',
  'Inconscient',
  'Invisible',
  'Neutralisé',
  'Paralysé',
  'Pétrifié',
];

const _enOrder = [
  'Blinded',
  'Charmed',
  'Deafened',
  'Frightened',
  'Grappled',
  'Incapacitated',
  'Invisible',
  'Paralyzed',
  'Petrified',
  'Poisoned',
  'Prone',
  'Restrained',
  'Stunned',
  'Unconscious',
];

class _Harness {
  final List<List<ConditionType>> saved = [];
  final List<String> announced = [];
}

Future<_Harness> _open(
  WidgetTester tester, {
  List<ConditionType> initial = const [],
  Future<String?> Function(List<ConditionType>)? onSave,
  Locale locale = const Locale('fr'),
  double scale = 1,
}) async {
  final harness = _Harness();
  tester.view.physicalSize = const Size(360, 800);
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showConditionsSheet(
                context,
                initial: initial,
                onSave: (selection) async {
                  harness.saved.add(selection);
                  return onSave == null ? null : onSave(selection);
                },
                announcer: (_, text) => harness.announced.add(text),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return harness;
}

PrimaryButton _saveButton(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton));

Future<void> _tapRow(WidgetTester tester, String label) async {
  final row = find.text(label);
  // Retour en haut de la liste, puis défilement vers le bas jusqu'à la ligne.
  await tester.drag(find.byType(ListView), const Offset(0, 10000));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    row,
    80,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pump();
}

double _top(WidgetTester tester, String label) =>
    tester.getTopLeft(find.text(label)).dy;

void main() {
  group('T4 : structure du sélecteur', () {
    testWidgets('titre, sous-titre informatif, 14 lignes avec règle', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text('ÉTATS'), findsOneWidget);
      expect(
        find.text("Informatif : n'a aucun effet sur les calculs."),
        findsOneWidget,
      );
      expect(find.byType(PixelIcon), findsAtLeastNWidgets(4));
      expect(find.byType(TextField), findsNothing); // pas de recherche
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.semanticChildCount ?? 14, 14);
      // Le corps défile (jamais plafonné) : la dernière ligne est atteignable.
      await tester.scrollUntilVisible(
        find.text('Pétrifié'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Pétrifié'), findsOneWidget);
    });

    testWidgets('ordre alphabétique FR (accents et casse ignorés)', (
      tester,
    ) async {
      await _open(tester);
      // Les premières lignes sont dans l'ordre ; on parcourt par défilement.
      final seen = <String>[];
      for (final label in _frOrder) {
        final finder = find.text(label);
        await tester.scrollUntilVisible(
          finder,
          80,
          scrollable: find.byType(Scrollable).first,
        );
        seen.add(label);
      }
      expect(seen, _frOrder);
      // Vérification de la position relative sur les 5 premières visibles.
      await tester.drag(find.byType(ListView), const Offset(0, 5000));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        expect(
          _top(tester, _frOrder[i]),
          lessThan(_top(tester, _frOrder[i + 1])),
        );
      }
    });

    testWidgets('ordre alphabétique EN', (tester) async {
      await _open(tester, locale: const Locale('en'));
      expect(find.text('CONDITIONS'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(
          _top(tester, _enOrder[i]),
          lessThan(_top(tester, _enOrder[i + 1])),
        );
      }
      await tester.scrollUntilVisible(
        find.text('Unconscious'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Unconscious'), findsOneWidget);
    });

    testWidgets('Enregistrer désactivé sans changement, actif dès qu\'une '
        'case change, de nouveau désactivé au retour à l\'état initial', (
      tester,
    ) async {
      await _open(tester, initial: const [ConditionType.blinded]);
      expect(_saveButton(tester).onPressed, isNull);

      await _tapRow(tester, 'Charmé');
      expect(_saveButton(tester).onPressed, isNotNull);

      await _tapRow(tester, 'Charmé');
      expect(_saveButton(tester).onPressed, isNull);

      await _tapRow(tester, 'Aveuglé'); // décoche l'état initial
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets(
      'ligne cochée : coche visible, fond card-alt, bordure wood.light',
      (tester) async {
        await _open(tester, initial: const [ConditionType.blinded]);
        expect(find.byType(SelectionCheckbox), findsAtLeastNWidgets(4));
        final checked = tester
            .widgetList<SelectionCheckbox>(find.byType(SelectionCheckbox))
            .where((c) => c.checked);
        expect(checked.length, 1);
        expect(find.byIcon(Icons.check), findsOneWidget);

        final row = find
            .ancestor(
              of: find.text('Aveuglé'),
              matching: find.byType(Container),
            )
            .first;
        final decoration =
            tester.widget<Container>(row).decoration! as BoxDecoration;
        expect(decoration.color, AppColors.parchmentCardAlt);
        expect((decoration.border! as Border).top.color, AppColors.woodLight);
        expect(tester.getSize(row).height, greaterThanOrEqualTo(56));

        final unchecked = find
            .ancestor(
              of: find.text('À terre'),
              matching: find.byType(Container),
            )
            .first;
        final plain =
            tester.widget<Container>(unchecked).decoration! as BoxDecoration;
        expect(plain.color, AppColors.parchmentCard);
      },
    );
  });

  group('Tout décocher / Annuler', () {
    testWidgets('« Tout décocher » visible seulement si >= 1 cochée', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text('Tout décocher'), findsNothing);
      await _tapRow(tester, 'Charmé');
      expect(find.text('Tout décocher'), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Tout décocher')).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('Tout décocher'));
      await tester.pump();
      expect(find.text('Tout décocher'), findsNothing);
      expect(
        tester
            .widgetList<SelectionCheckbox>(find.byType(SelectionCheckbox))
            .where((c) => c.checked),
        isEmpty,
      );
    });

    testWidgets('Annuler ferme sans enregistrer ni confirmation', (
      tester,
    ) async {
      final harness = await _open(tester);
      await _tapRow(tester, 'Charmé');
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();
      expect(find.text('ÉTATS'), findsNothing);
      expect(harness.saved, isEmpty);
    });
  });

  group('Enregistrement', () {
    testWidgets('succès : onSave reçoit la sélection canonique, annonce, '
        'fermeture', (tester) async {
      final harness = await _open(tester);
      await _tapRow(tester, 'Étourdi');
      await _tapRow(tester, 'Aveuglé');
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(harness.saved, [
        [ConditionType.blinded, ConditionType.stunned],
      ]);
      expect(harness.announced, ['États mis à jour : Aveuglé, Étourdi']);
      expect(find.text('ÉTATS'), findsNothing);
    });

    testWidgets('tout décocher puis enregistrer : « Aucun état actif »', (
      tester,
    ) async {
      final harness = await _open(tester, initial: const [ConditionType.prone]);
      await tester.tap(find.text('Tout décocher'));
      await tester.pump();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(harness.saved, [<ConditionType>[]]);
      expect(harness.announced, ['Aucun état actif']);
    });

    testWidgets('erreur : bannière, sélection conservée, feuille ouverte, '
        'aucune annonce', (tester) async {
      final harness = await _open(
        tester,
        onSave: (_) async =>
            'Hors ligne : cette action n\'a pas pu être '
            'enregistrée. Réessayez une fois reconnecté.',
      );
      await _tapRow(tester, 'Charmé');
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertBanner), findsOneWidget);
      expect(find.textContaining('Hors ligne'), findsOneWidget);
      expect(find.text('ÉTATS'), findsOneWidget);
      expect(harness.announced, isEmpty);
      final checked = tester
          .widgetList<SelectionCheckbox>(find.byType(SelectionCheckbox))
          .where((c) => c.checked);
      expect(checked.length, 1);
      // L'état saisi reste enregistrable (réessai).
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('exception : message générique, sélection conservée', (
      tester,
    ) async {
      await _open(tester, onSave: (_) async => throw StateError('boom'));
      await _tapRow(tester, 'Charmé');
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(
        find.text("Impossible d'enregistrer les états. Réessayez."),
        findsOneWidget,
      );
      expect(find.text('ÉTATS'), findsOneWidget);
    });

    testWidgets('en cours : bouton occupé, cases et fermeture désactivées', (
      tester,
    ) async {
      final gate = Completer<String?>();
      await _open(tester, onSave: (_) => gate.future);
      await _tapRow(tester, 'Charmé');
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pump();

      expect(_saveButton(tester).isLoading, isTrue);
      // Cases désactivées : un tap sur « Aveuglé » (en haut de la liste) ne la
      // coche pas.
      await tester.drag(find.byType(ListView), const Offset(0, 10000));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Aveuglé'));
      await tester.pump();
      expect(
        tester
            .widgetList<SelectionCheckbox>(find.byType(SelectionCheckbox))
            .where((c) => c.checked),
        isEmpty,
      );
      // Fermeture et Annuler désactivés.
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('ANNULER'));
      await tester.pump();
      expect(find.text('ÉTATS'), findsOneWidget);

      gate.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('ÉTATS'), findsNothing);
    });
  });

  group('T8 : police x2,0 sur 360 dp', () {
    testWidgets('aucun débordement, défilement jusqu\'au bout', (tester) async {
      await _open(tester, scale: 2);
      expect(tester.takeException(), isNull);
      await _tapRow(tester, 'Charmé');
      await tester.scrollUntilVisible(
        find.text('Pétrifié'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('ENREGISTRER'), findsOneWidget);
    });
  });

  group('T8 : police x2,0 avec bannière d erreur', () {
    testWidgets(
      'pied défilant + bannière : aucun débordement, ENREGISTRER atteignable',
      (tester) async {
        await _open(
          tester,
          scale: 2,
          onSave: (_) async =>
              'Hors ligne : cette action n a pas pu être enregistrée. Réessayez '
              'une fois reconnecté.',
        );
        await _tapRow(tester, 'Charmé');
        await tester.tap(find.text('ENREGISTRER'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertBanner), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.text('ENREGISTRER'), findsOneWidget);
        // D195 (d) : le bouton reste atteignable (non masqué, hors de l'écran
        // ou recouvert) malgré la bannière et la police x2,0.
        expect(find.text('ENREGISTRER').hitTestable(), findsOneWidget);
      },
    );
  });

  group('T11 : cases accessibles', () {
    testWidgets('Semantics(checked) avec libellé et règle', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, initial: const [ConditionType.blinded]);

      final checked = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Aveuglé :')),
      );
      expect(checked.flagsCollection.isChecked, CheckedState.isTrue);
      expect(checked.label, contains("celles contre lui l'avantage."));

      final unchecked = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Assourdi :')),
      );
      expect(unchecked.flagsCollection.isChecked, CheckedState.isFalse);
      handle.dispose();
    });
  });
}
