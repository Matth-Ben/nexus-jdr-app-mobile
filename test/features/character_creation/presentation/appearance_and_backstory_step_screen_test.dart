// Tests de widget de l'étape 8/9 de l'assistant de création ("Apparence,
// histoire et portrait").
//
// Contrairement aux étapes catalogue précédentes, cet écran ne dépend
// d'aucun `CharacterCreationRepository` (pas de donnée de référence à
// charger) : pas de dépôt factice ici, juste le vrai
// `CharacterCreationDraftController` porté par le `ProviderContainer` par
// défaut.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/step_progress_bar.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/presentation/appearance_and_backstory_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';

// Ordre canonique des 9 champs, voir le commentaire de classe de
// `AppearanceAndBackstoryStepScreen` — les tests s'appuient sur cet ordre
// pour retrouver le bon `TextFormField` par index.
const _labels = [
  'APPARENCE PHYSIQUE',
  'TRAITS DE PERSONNALITÉ',
  'IDÉAUX',
  'LIENS',
  'DÉFAUTS',
  'HISTOIRE PERSONNELLE',
  'ALLIÉS',
  'PARTICULARITÉS',
  'TRÉSOR',
];

void main() {
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  // `initialLocation` reste l'étape "Équipement" (stub) :
  // `AppearanceAndBackstoryStepScreen` est atteinte via un `push`, comme
  // dans la vraie navigation (`equipment_step_screen.dart` pousse
  // `/characters/new/step-8`).
  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/new/step-7',
      routes: [
        GoRoute(
          path: '/characters/new/step-7',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Équipement'))),
        ),
        GoRoute(
          path: '/characters/new/step-8',
          builder: (context, state) => const AppearanceAndBackstoryStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-9',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape suivante'))),
        ),
      ],
    );
    return router;
  }

  Widget buildTestWidget() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: buildTestRouter()),
    );
  }

  CharacterCreationDraft readDraft() =>
      container.read(characterCreationDraftControllerProvider);

  Future<void> pumpStep(WidgetTester tester) async {
    // Le corps de l'écran est un `ListView` avec 9 champs texte : la taille
    // de surface de test par défaut (800x600) n'en affiche que 2-3 à la
    // fois, donc les widgets restants ne sont ni construits ni trouvables
    // (`ListView(children: ...)` reste lazy via `SliverList`, ne matérialise
    // que les enfants proches du viewport). Agrandir la surface plutôt que
    // scroller à chaque test garde ces tests simples et robustes à l'ordre
    // des champs.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/step-8');
    await tester.pumpAndSettle();
  }

  Finder fieldAt(int index) => find.byType(TextFormField).at(index);

  // `TextFormField` ne réexpose pas `focusNode`/`textInputAction` en champs
  // publics (ils ne servent qu'à construire le `TextField` interne) : on
  // descend jusqu'à ce `TextField` pour les lire dans les tests ci-dessous.
  Finder textFieldAt(int index) =>
      find.descendant(of: fieldAt(index), matching: find.byType(TextField));

  testWidgets('affiche la tuile Portrait et les 9 champs texte dans l\'ordre '
      'canonique', (WidgetTester tester) async {
    await pumpStep(tester);

    expect(find.text('Portrait'), findsOneWidget);
    expect(find.text('Optionnel — ajoutable plus tard'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);

    for (final label in _labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(TextFormField), findsNWidgets(9));
  });

  testWidgets(
    'le titre d\'étape et la barre de progression sont sur le bandeau bois, '
    'pas sur le fond parchemin (non-régression du bug relevé par '
    'direction-artistique : le bois doit s\'étendre jusque sous '
    'StepProgressBar, comme les étapes 6/9 et 7/9)',
    (WidgetTester tester) async {
      await pumpStep(tester);

      // Le titre et le "Étape 8 / 9" doivent utiliser les couleurs "sur
      // bois" (`textOnWood`/`textOnWoodMuted`), pas les couleurs "sur
      // parchemin" (`textPrimary`/`textMuted`) utilisées par erreur avant
      // correction.
      final title = tester.widget<Text>(find.text('8. Histoire'));
      expect(title.style?.color, AppColors.textOnWood);

      final stepLabel = tester.widget<Text>(find.text('Étape 8 / 9'));
      expect(stepLabel.style?.color, AppColors.textOnWoodMuted);

      // `StepProgressBar` doit être un descendant du même `ColoredBox` bois
      // que le bouton retour/"CRÉATION", pas posé séparément sur le
      // parchemin en dessous.
      final woodBanner = find
          .ancestor(
            of: find.text('CRÉATION'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is ColoredBox && widget.color == AppColors.woodMedium,
            ),
          )
          .first;
      expect(
        find.descendant(of: woodBanner, matching: find.byType(StepProgressBar)),
        findsOneWidget,
      );
    },
  );

  testWidgets('"Suivant" est actif dès l\'affichage, sans aucune saisie', (
    WidgetTester tester,
  ) async {
    await pumpStep(tester);

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    'revenir sur l\'étape avec un brouillon déjà rempli préremplit les 9 '
    'champs (retour en arrière depuis l\'étape 9)',
    (WidgetTester tester) async {
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setAppearanceAndBackstory(
            appearanceText: 'Grand et mince',
            traitsText: 'Curieux',
            idealsText: 'La justice',
            bondsText: 'Sa famille',
            flawsText: 'Trop confiant',
            backstoryText: 'Né dans un village isolé',
            alliesText: 'La guilde des marchands',
            featuresText: 'Une cicatrice au visage',
            treasureText: 'Une amulette ancienne',
          );

      await pumpStep(tester);

      const expectedValues = [
        'Grand et mince',
        'Curieux',
        'La justice',
        'Sa famille',
        'Trop confiant',
        'Né dans un village isolé',
        'La guilde des marchands',
        'Une cicatrice au visage',
        'Une amulette ancienne',
      ];
      for (var i = 0; i < expectedValues.length; i++) {
        final field = tester.widget<TextFormField>(fieldAt(i));
        expect(field.controller!.text, expectedValues[i]);
      }
    },
  );

  testWidgets(
    'saisir du texte puis valider propage les 9 valeurs vers le brouillon '
    'via copyWith, sans effacer les choix des étapes précédentes',
    (WidgetTester tester) async {
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setClass(classId: 42);

      await pumpStep(tester);

      await tester.enterText(fieldAt(0), 'Grand et mince');
      await tester.enterText(fieldAt(8), 'Une amulette ancienne');
      await tester.pump();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      final draft = readDraft();
      expect(draft.classId, 42);
      expect(draft.appearanceText, 'Grand et mince');
      expect(draft.treasureText, 'Une amulette ancienne');
      expect(draft.traitsText, isNull);
      expect(find.text('Étape suivante'), findsOneWidget);
    },
  );

  testWidgets(
    'un champ rempli puis entièrement effacé (espaces uniquement) redevient '
    'null dans le brouillon après validation',
    (WidgetTester tester) async {
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setAppearanceAndBackstory(
            appearanceText: 'Grand et mince',
            traitsText: null,
            idealsText: null,
            bondsText: null,
            flawsText: null,
            backstoryText: null,
            alliesText: null,
            featuresText: null,
            treasureText: null,
          );

      await pumpStep(tester);

      await tester.enterText(fieldAt(0), '   ');
      await tester.pump();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft().appearanceText, isNull);
    },
  );

  testWidgets(
    'action clavier "suivant" sur un champ déplace le focus vers le champ '
    'suivant',
    (WidgetTester tester) async {
      await pumpStep(tester);

      await tester.tap(fieldAt(0));
      await tester.pumpAndSettle();

      final firstFocusNode = tester
          .widget<TextField>(textFieldAt(0))
          .focusNode!;
      final secondFocusNode = tester
          .widget<TextField>(textFieldAt(1))
          .focusNode!;
      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
    },
  );

  testWidgets('le 9e champ ("Trésor") utilise l\'action clavier "terminé", pas '
      '"suivant"', (WidgetTester tester) async {
    await pumpStep(tester);

    final lastField = tester.widget<TextField>(textFieldAt(8));
    expect(lastField.textInputAction, TextInputAction.done);

    // Sur les 8 premiers champs, l'action est "suivant".
    for (var i = 0; i < 8; i++) {
      final field = tester.widget<TextField>(textFieldAt(i));
      expect(field.textInputAction, TextInputAction.next);
    }
  });

  testWidgets(
    'valider l\'action "terminé" sur le dernier champ ne fait pas planter '
    'l\'écran',
    (WidgetTester tester) async {
      await pumpStep(tester);

      await tester.tap(fieldAt(8));
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'la tuile "Portrait" n\'est pas fonctionnelle : le tap ne plante pas et '
    'n\'écrit rien dans le brouillon',
    (WidgetTester tester) async {
      await pumpStep(tester);

      await tester.tap(find.text('Portrait'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(readDraft(), const CharacterCreationDraft());
      expect(find.text('Bientôt disponible'), findsOneWidget);
    },
  );

  testWidgets('le bouton "Retour" revient à l\'étape précédente', (
    WidgetTester tester,
  ) async {
    await pumpStep(tester);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Étape Équipement'), findsOneWidget);
  });

  testWidgets('le bouton "Retour" utilise la variante "parchemin" du bouton '
      'secondaire', (WidgetTester tester) async {
    await pumpStep(tester);

    final backButton = tester
        .widgetList<SecondaryButton>(find.byType(SecondaryButton))
        .firstWhere((button) => button.label == 'Retour');

    expect(backButton.surface, SecondaryButtonSurface.parchment);
  });
}
