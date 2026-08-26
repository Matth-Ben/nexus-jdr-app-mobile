// Tests de widget de l'étape 7/9 de l'assistant de création ("Équipement de
// départ").
//
// Même principe que `spells_step_screen_test.dart`/
// `skills_and_tools_step_screen_test.dart` : dépôt factice injecté via
// `overrideWithValue`, aucun appel réseau réel.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/equipment_choice_tab.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/item_option.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/equipment_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  BackgroundCatalog? backgroundCatalogToReturn;
  Object? backgroundCatalogErrorToThrow;
  Completer<BackgroundCatalog>? backgroundCatalogCompleter;
  ItemCatalog? itemCatalogToReturn;
  Object? itemCatalogErrorToThrow;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async =>
      const RaceCatalog(races: [], subraces: []);

  @override
  Future<ClassCatalog> fetchClassCatalog() async =>
      const ClassCatalog(classes: []);

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async {
    if (backgroundCatalogCompleter != null) {
      return backgroundCatalogCompleter!.future;
    }
    if (backgroundCatalogErrorToThrow != null) {
      throw backgroundCatalogErrorToThrow!;
    }
    return backgroundCatalogToReturn ??
        const BackgroundCatalog(backgrounds: []);
  }

  @override
  Future<ToolCatalog> fetchToolCatalog() async => const ToolCatalog(tools: []);

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async =>
      const LanguageCatalog(languages: []);

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async =>
      const SpellCatalog(spells: []);

  @override
  Future<ItemCatalog> fetchItemCatalog() async {
    if (itemCatalogErrorToThrow != null) {
      throw itemCatalogErrorToThrow!;
    }
    return itemCatalogToReturn ?? const ItemCatalog(items: []);
  }

  @override
  Future<SkillCatalog> fetchSkillCatalog() async =>
      const SkillCatalog(skills: []);

  @override
  Future<String> createCharacter({
    required CharacterCreationDraft draft,
    required String characterName,
    required RaceCatalog raceCatalog,
    required ClassOption classOption,
    required BackgroundOption backgroundOption,
    required SkillCatalog skillCatalog,
    required ToolCatalog toolCatalog,
    required LanguageCatalog languageCatalog,
    required SpellCatalog spellCatalog,
    required ItemCatalog itemCatalog,
  }) async => throw UnimplementedError();
}

// Historique avec un objet résolu ("Dague", présent dans `_itemCatalog`) ET
// un objet non résolu ("Symbole sacré", absent) — voir la consigne
// d'origine : "beaucoup ne matcheront pas".
const _acolyte = BackgroundOption(
  id: 1,
  name: 'Acolyte',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
  equipment: ['Symbole sacré', 'Dague', 'Bourse (15 po)'],
);

// Historique sans aucun équipement en dehors de la ligne "Bourse" (une fois
// celle-ci retirée) -> état vide de l'onglet "Historique".
const _ermite = BackgroundOption(
  id: 2,
  name: 'Ermite',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
  equipment: ['Bourse (10 po)'],
);

const _dague = ItemOption(
  id: 2,
  name: 'Dague',
  category: 'arme',
  costAmount: 2,
);
const _armureDeCuir = ItemOption(
  id: 5,
  name: 'Armure de cuir',
  category: 'armure',
  costAmount: 10,
);
const _sacADos = ItemOption(
  id: 8,
  name: 'Sac à dos',
  category: 'equipement_general',
  costAmount: 2,
);

const _itemCatalog = ItemCatalog(items: [_dague, _armureDeCuir, _sacADos]);

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository();
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // `initialLocation` reste l'étape "Sorts" (stub) : `EquipmentStepScreen`
  // est atteinte via un `push`, comme dans la vraie navigation.
  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/new/step-6',
      routes: [
        GoRoute(
          path: '/characters/new/step-6',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Sorts'))),
        ),
        GoRoute(
          path: '/characters/new/step-7',
          builder: (context, state) => const EquipmentStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-8',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Étape Apparence, histoire et portrait')),
          ),
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

  void selectBackground(int backgroundId) {
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .setBackground(backgroundId: backgroundId);
  }

  Future<void> pumpEquipmentStep(WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/step-7');
    await tester.pumpAndSettle();
  }

  Finder tileFor(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byType(CheckableOptionTile),
  );

  Future<void> tapStepper(
    WidgetTester tester,
    String itemName, {
    required bool increment,
  }) async {
    final icon = increment ? Icons.add : Icons.remove;
    final button = find.descendant(
      of: tileFor(itemName),
      matching: find.byIcon(icon),
    );
    // Le catalogue d'achat peut dépasser la hauteur visible de la
    // `ListView` : s'assurer que la carte est scrollée dans le viewport
    // avant de taper son compteur, plutôt que de dépendre de la position
    // par défaut du test (résolution d'un flaky hit-test miss).
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeRepository.backgroundCatalogCompleter = Completer<BackgroundCatalog>();
    selectBackground(1);

    await tester.pumpWidget(buildTestWidget());
    router.push('/characters/new/step-7');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" si le catalogue '
    'd\'historiques échoue à charger',
    (WidgetTester tester) async {
      fakeRepository.backgroundCatalogErrorToThrow =
          const CharacterCreationFailure(
            'Impossible de charger les historiques disponibles. Réessayez.',
          );
      selectBackground(1);

      await pumpEquipmentStep(tester);

      expect(
        find.text(
          'Impossible de charger les historiques disponibles. '
          'Réessayez.',
        ),
        findsOneWidget,
      );

      fakeRepository.backgroundCatalogErrorToThrow = null;
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_acolyte],
      );
      fakeRepository.itemCatalogToReturn = _itemCatalog;

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text("ÉQUIPEMENT DE L'HISTORIQUE"), findsOneWidget);
    },
  );

  testWidgets(
    'historique introuvable dans le catalogue (id du brouillon absent) -> '
    'état d\'erreur explicite plutôt qu\'un crash',
    (WidgetTester tester) async {
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_acolyte],
      );
      fakeRepository.itemCatalogToReturn = _itemCatalog;
      selectBackground(999);

      await pumpEquipmentStep(tester);

      expect(find.textContaining('Historique introuvable'), findsOneWidget);
    },
  );

  group('historique avec équipement (Acolyte)', () {
    setUp(() {
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_acolyte, _ermite],
      );
      fakeRepository.itemCatalogToReturn = _itemCatalog;
      selectBackground(1);
    });

    testWidgets(
      'onglet "Historique" actif par défaut : titre de section, objet '
      'résolu ET objet non résolu (texte libre) affichés à l\'identique, '
      'bandeau "OR DE DÉPART"',
      (WidgetTester tester) async {
        await pumpEquipmentStep(tester);

        expect(find.text('HISTORIQUE'), findsOneWidget);
        expect(find.text('ACHETER (15 PO)'), findsOneWidget);

        expect(find.text("ÉQUIPEMENT DE L'HISTORIQUE"), findsOneWidget);

        // Objet résolu.
        expect(find.text('Dague'), findsOneWidget);
        expect(find.text('Arme'), findsOneWidget);

        // Objet non résolu : rendu identique (même carte), libellé de
        // catégorie générique neutre "Équipement" — jamais un texte qui
        // révélerait au joueur que cet objet n'a pas matché la base (ex.
        // "Non répertorié", régression corrigée après revue qa-testeur/
        // direction-artistique).
        expect(find.text('Symbole sacré'), findsOneWidget);
        expect(find.text('Équipement'), findsOneWidget);

        // Ni case à cocher, ni interaction sur ces cartes.
        final dagueTile = tester.widget<CheckableOptionTile>(tileFor('Dague'));
        expect(dagueTile.checked, isFalse);
        expect(dagueTile.showIndicator, isFalse);
        expect(dagueTile.onTap, isNull);

        // Bandeau "OR DE DÉPART".
        expect(find.text('OR DE DÉPART'), findsOneWidget);
        expect(find.text('15 po'), findsOneWidget);
      },
    );

    testWidgets(
      '"Suivant" est toujours actif sur l\'onglet "Historique" et fait '
      'passer à l\'étape suivante avec ce choix retenu',
      (WidgetTester tester) async {
        await pumpEquipmentStep(tester);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(
          find.text('Étape Apparence, histoire et portrait'),
          findsOneWidget,
        );
        expect(readDraft().equipmentChoiceTab, EquipmentChoiceTab.background);
        expect(readDraft().purchasedEquipment, isEmpty);
      },
    );

    testWidgets('taper "Acheter (15 PO)" bascule vers le catalogue groupé par '
        'catégorie (ordre fixe), avec un compteur +/- par objet', (
      WidgetTester tester,
    ) async {
      await pumpEquipmentStep(tester);

      await tester.tap(find.text('ACHETER (15 PO)'));
      await tester.pumpAndSettle();

      expect(find.text("ÉQUIPEMENT DE L'HISTORIQUE"), findsNothing);

      expect(find.text('ARME'), findsOneWidget);
      expect(find.text('ARMURE'), findsOneWidget);
      expect(find.text('ÉQUIPEMENT'), findsOneWidget);

      expect(find.text('Dague'), findsOneWidget);
      expect(find.text('Arme · 2 po'), findsOneWidget);
      expect(find.text('Armure de cuir'), findsOneWidget);
      expect(find.text('Armure · 10 po'), findsOneWidget);
      expect(find.text('Sac à dos'), findsOneWidget);
      expect(find.text('Équipement · 2 po'), findsOneWidget);

      expect(find.text('OR RESTANT'), findsOneWidget);
      expect(find.text('15 po'), findsOneWidget);
    });

    testWidgets(
      'augmenter la quantité d\'un objet au-delà du budget affiche le '
      'bandeau d\'alerte et bloque "Suivant" ; revenir sous le budget '
      'restaure le bandeau "OR RESTANT" et débloque "Suivant"',
      (WidgetTester tester) async {
        await pumpEquipmentStep(tester);
        await tester.tap(find.text('ACHETER (15 PO)'));
        await tester.pumpAndSettle();

        await tapStepper(tester, 'Armure de cuir', increment: true);
        await tapStepper(tester, 'Armure de cuir', increment: true);

        expect(find.text('Budget dépassé de 5 po'), findsOneWidget);
        expect(find.text('OR RESTANT'), findsNothing);

        final primaryButton = tester.widget<PrimaryButton>(
          find.byType(PrimaryButton),
        );
        expect(primaryButton.onPressed, isNull);

        await tapStepper(tester, 'Armure de cuir', increment: false);

        expect(find.text('OR RESTANT'), findsOneWidget);
        expect(find.text('5 po'), findsOneWidget);
        final enabledButton = tester.widget<PrimaryButton>(
          find.byType(PrimaryButton),
        );
        expect(enabledButton.onPressed, isNotNull);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(
          find.text('Étape Apparence, histoire et portrait'),
          findsOneWidget,
        );
        expect(readDraft().equipmentChoiceTab, EquipmentChoiceTab.purchase);
        expect(readDraft().purchasedEquipment, {'Armure de cuir': 1});
      },
    );

    testWidgets('le panier de l\'onglet "Acheter" reste préservé au changement '
        'd\'onglet (bascule sur "Historique" puis retour, sans validation)', (
      WidgetTester tester,
    ) async {
      await pumpEquipmentStep(tester);
      await tester.tap(find.text('ACHETER (15 PO)'));
      await tester.pumpAndSettle();

      await tapStepper(tester, 'Dague', increment: true);
      await tapStepper(tester, 'Dague', increment: true);

      await tester.tap(find.text('HISTORIQUE'));
      await tester.pumpAndSettle();
      expect(find.text("ÉQUIPEMENT DE L'HISTORIQUE"), findsOneWidget);

      await tester.tap(find.text('ACHETER (15 PO)'));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets(
      'revenir sur l\'étape avec un brouillon déjà rempli (onglet "Acheter" '
      'retenu) réhydrate l\'onglet actif ET le panier (retour en arrière '
      'depuis une étape suivante)',
      (WidgetTester tester) async {
        container
            .read(characterCreationDraftControllerProvider.notifier)
            .setEquipment(
              activeTab: EquipmentChoiceTab.purchase,
              purchasedEquipment: const {'Dague': 3},
            );

        await pumpEquipmentStep(tester);

        expect(find.text("ÉQUIPEMENT DE L'HISTORIQUE"), findsNothing);
        expect(find.text('Dague'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      },
    );

    testWidgets('"Retour" revient à l\'étape précédente', (
      WidgetTester tester,
    ) async {
      await pumpEquipmentStep(tester);

      await tester.tap(find.text('RETOUR'));
      await tester.pumpAndSettle();

      expect(find.text('Étape Sorts'), findsOneWidget);
    });
  });

  testWidgets(
    'historique sans équipement en dehors de la ligne "Bourse" -> état vide '
    'discret sur l\'onglet "Historique"',
    (WidgetTester tester) async {
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_acolyte, _ermite],
      );
      fakeRepository.itemCatalogToReturn = _itemCatalog;
      selectBackground(2);

      await pumpEquipmentStep(tester);

      expect(find.text("ÉQUIPEMENT DE L'HISTORIQUE"), findsNothing);
      expect(
        find.text('Aucun équipement pour cet historique.'),
        findsOneWidget,
      );
      expect(find.text('OR DE DÉPART'), findsOneWidget);
      expect(find.text('10 po'), findsOneWidget);
    },
  );

  testWidgets("affiche un état d'erreur avec un bouton 'Réessayer' si le "
      "catalogue d'objets (fetchItemCatalog) échoue à charger, même si "
      "le catalogue d'historiques a réussi", (WidgetTester tester) async {
    fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
      backgrounds: [_acolyte],
    );
    fakeRepository.itemCatalogErrorToThrow = const CharacterCreationFailure(
      "Impossible de charger le catalogue d'équipement. Réessayez.",
    );
    selectBackground(1);

    await pumpEquipmentStep(tester);

    expect(
      find.text(
        "Impossible de charger le catalogue d'équipement. "
        'Réessayez.',
      ),
      findsOneWidget,
    );

    fakeRepository.itemCatalogErrorToThrow = null;
    fakeRepository.itemCatalogToReturn = _itemCatalog;

    await tester.tap(find.text('RÉESSAYER'));
    await tester.pumpAndSettle();

    expect(find.text("ÉQUIPEMENT DE L'HISTORIQUE"), findsOneWidget);
  });

  testWidgets("catalogue d'objets vide -> état vide discret sur l'onglet "
      "'Acheter', distinct de l'état d'erreur", (WidgetTester tester) async {
    fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
      backgrounds: [_acolyte],
    );
    fakeRepository.itemCatalogToReturn = const ItemCatalog(items: []);
    selectBackground(1);

    await pumpEquipmentStep(tester);
    await tester.tap(find.text('ACHETER (15 PO)'));
    await tester.pumpAndSettle();

    expect(find.text("Aucun objet disponible à l'achat."), findsOneWidget);
    // Objet d'historique non résolu vers un item : reste affiché tel
    // quel sur l'onglet Historique malgré un catalogue vide (voir
    // `BackgroundEquipmentResolver.resolve`, catalogue vide -> tout est
    // non résolu, jamais une raison de vider l'onglet Historique).
    await tester.tap(find.text('HISTORIQUE'));
    await tester.pumpAndSettle();
    expect(find.text('Symbole sacré'), findsOneWidget);
    expect(find.text('Dague'), findsOneWidget);
  });
}
