// Tests de widget de la fiche personnage (onglet "Personnage").
//
// Le dépôt de test (`_FakeCharacterRepository`) est injecté via
// `overrideWithValue` sur `characterRepositoryProvider` — même principe que
// `character_list_screen_test.dart`. `characterDetailProvider` (famille
// Riverpod générée) n'a pas besoin d'override dédié : il délègue directement
// à ce dépôt.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/core/widgets/portrait_frame.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_ability_score_grid.dart';

class _FakeCharacterRepository implements CharacterRepository {
  CharacterDetail? detailToReturn;
  Object? detailErrorToThrow;
  Completer<CharacterDetail>? detailCompleter;
  int fetchDetailCallCount = 0;

  int? lastUpdatedCurrentHp;
  int? lastUpdatedTemporaryHp;
  int updateHpCallCount = 0;

  String? lastRemovedPortraitUrl;
  int removePortraitCallCount = 0;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    fetchDetailCallCount++;
    if (detailCompleter != null) return detailCompleter!.future;
    if (detailErrorToThrow != null) throw detailErrorToThrow!;
    return detailToReturn ?? _baseDetail;
  }

  @override
  Future<void> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) async {
    updateHpCallCount++;
    lastUpdatedCurrentHp = currentHp;
    lastUpdatedTemporaryHp = temporaryHp;
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) async => 'https://example.com/portrait.png';

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) async {
    removePortraitCallCount++;
    lastRemovedPortraitUrl = portraitUrl;
  }
}

const _baseDetail = CharacterDetail(
  id: '1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  subraceName: null,
  backgroundName: null,
  alignmentName: null,
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: 'Magicienne',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: ['int', 'wis'],
    ),
  ],
  xp: 7000,
  currentHp: 18,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: {
    'str': 8,
    'dex': 14,
    'con': 12,
    'int': 18,
    'wis': 13,
    'cha': 10,
  },
);

void main() {
  late _FakeCharacterRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeCharacterRepository();
  });

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: '/characters/1',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Liste'))),
        ),
        GoRoute(
          path: '/characters/:id',
          builder: (context, state) =>
              CharacterDetailScreen(characterId: state.pathParameters['id']!),
        ),
      ],
    );
  }

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: MaterialApp.router(routerConfig: buildTestRouter()),
    );
  }

  // Surface de test agrandie : la carte "Jets de sauvegarde" (en bas de la
  // liste défilante de l'onglet "Personnage") est autrement en dehors du
  // `cacheExtent` par défaut d'un `ListView` sur la taille d'écran de test
  // standard (800×600) — ses widgets ne seraient alors jamais matérialisés
  // dans l'arbre, et introuvables par `find.text(...)`.
  Future<void> pumpDetail(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestWidget());
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    tester,
  ) async {
    fakeRepository.detailCompleter = Completer<CharacterDetail>();

    await pumpDetail(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Pas de barre d'onglets pendant le chargement (spec des états).
    expect(find.text('PERSO'), findsNothing);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" qui relance la '
    'requête',
    (tester) async {
      fakeRepository.detailErrorToThrow = const CharacterFailure(
        'Personnage introuvable.',
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('Personnage introuvable.'), findsOneWidget);
      expect(fakeRepository.fetchDetailCallCount, 1);

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.fetchDetailCallCount, 2);
    },
  );

  testWidgets('affiche le nom, le sous-titre et masque la ligne historique/'
      'alignement quand les deux sont absents', (tester) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Elfe · Magicienne · Niveau 5'), findsOneWidget);
    expect(find.textContaining('Historique :'), findsNothing);
  });

  testWidgets('affiche la ligne historique/alignement quand renseignée', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(
      backgroundName: 'Noble',
      alignmentName: 'Loyal Bon',
    );

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Historique : Noble · Loyal Bon'), findsOneWidget);
  });

  testWidgets(
    'format multiclasse : "{ClasseA} {niveauA} / {ClasseB} {niveauB}"',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Guerrier',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: ['str', 'con'],
          ),
          CharacterDetailClassRow(
            classId: 2,
            className: 'Magicien',
            level: 2,
            isPrimary: false,
            savingThrowProficiencies: ['int', 'wis'],
          ),
        ],
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('Guerrier 3 / Magicien 2'), findsOneWidget);
    },
  );

  testWidgets('affiche les 6 caractéristiques avec score et modificateur', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    // Recherche restreinte à la grille de caractéristiques : les jets de
    // sauvegarde affichent aussi des bonus signés, parfois identiques par
    // coïncidence (ex. dex +2 non maîtrisée dans les deux cartes).
    final grid = find.byType(CharacterAbilityScoreGrid);
    // int: 18 -> +4 ; str: 8 -> −1.
    expect(
      find.descendant(of: grid, matching: find.text('18')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: grid, matching: find.text('+4')),
      findsOneWidget,
    );
    expect(find.descendant(of: grid, matching: find.text('8')), findsOneWidget);
    expect(
      find.descendant(of: grid, matching: find.text('−1')),
      findsOneWidget,
    );
  });

  testWidgets(
    'la carte "Jets de sauvegarde" affiche les 6 caractéristiques, maîtrisées '
    'depuis la classe principale uniquement',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('JETS DE SAUVEGARDE'), findsOneWidget);
      expect(find.text('For'), findsOneWidget);
      expect(find.text('Dex'), findsOneWidget);
      expect(find.text('Con'), findsOneWidget);
      expect(find.text('Int'), findsOneWidget);
      expect(find.text('Sag'), findsOneWidget);
      expect(find.text('Cha'), findsOneWidget);
    },
  );

  testWidgets(
    'affiche la carte "Apparence physique" seulement si au moins un des 7 '
    'champs est renseigné',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('APPARENCE PHYSIQUE'), findsNothing);
    },
  );

  testWidgets(
    'la carte "Apparence physique" affiche les champs renseignés, sous la '
    'carte "Jets de sauvegarde"',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        sexe: 'Femme',
        eyes: 'Argentés',
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('APPARENCE PHYSIQUE'), findsOneWidget);
      expect(find.text('Sexe'), findsOneWidget);
      expect(find.text('Femme'), findsOneWidget);
      expect(find.text('Yeux'), findsOneWidget);
      expect(find.text('Argentés'), findsOneWidget);
      // Champs non renseignés omis.
      expect(find.text('Taille'), findsNothing);

      final savingThrowsPosition = tester.getTopLeft(
        find.text('JETS DE SAUVEGARDE'),
      );
      final appearancePosition = tester.getTopLeft(
        find.text('APPARENCE PHYSIQUE'),
      );
      expect(appearancePosition.dy, greaterThan(savingThrowsPosition.dy));
    },
  );

  testWidgets('affiche les bandeaux PV et XP', (tester) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('POINTS DE VIE'), findsOneWidget);
    expect(find.text('18 / 30'), findsOneWidget);
    expect(find.text('EXPÉRIENCE'), findsOneWidget);
    expect(find.text('7000 / 14000'), findsOneWidget);
  });

  testWidgets('affiche la puce "+N PV temp." seulement si temporary_hp > 0', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(temporaryHp: 4);

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('+4 PV temp.'), findsOneWidget);
  });

  testWidgets('le stepper rapide "+" appelle updateHp avec un soin de 1 PV', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(fakeRepository.updateHpCallCount, 1);
    expect(fakeRepository.lastUpdatedCurrentHp, 19);
    expect(fakeRepository.lastUpdatedTemporaryHp, 0);
  });

  testWidgets('le bouton crayon PV ouvre la feuille d\'ajustement détaillée', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Ajuster les PV'), findsOneWidget);
    expect(find.text('DÉGÂTS'), findsOneWidget);
    expect(find.text('SOINS'), findsOneWidget);
  });

  testWidgets(
    'taper le portrait ouvre le bottom sheet d\'upload, sans "Retirer le '
    'portrait" quand le personnage n\'a pas encore de portrait',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PortraitFrame));
      await tester.pumpAndSettle();

      expect(find.text('Prendre une photo'), findsOneWidget);
      expect(find.text('Choisir dans la galerie'), findsOneWidget);
      expect(find.text('Utiliser une URL'), findsOneWidget);
      expect(find.text('Retirer le portrait'), findsNothing);
    },
  );

  testWidgets('"Retirer le portrait" est proposé quand le personnage a déjà un '
      'portrait, et appelle removePortrait après confirmation', (tester) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(
      portraitUrl: 'https://example.com/halltesse.png',
    );

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PortraitFrame));
    await tester.pumpAndSettle();

    expect(find.text('Retirer le portrait'), findsOneWidget);
    await tester.tap(find.text('Retirer le portrait'));
    await tester.pumpAndSettle();

    expect(find.text('Retirer le portrait ?'), findsOneWidget);
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();

    expect(fakeRepository.removePortraitCallCount, 1);
    expect(
      fakeRepository.lastRemovedPortraitUrl,
      'https://example.com/halltesse.png',
    );
    expect(find.text('Portrait retiré.'), findsOneWidget);
  });

  testWidgets('la navigation entre les 4 onglets fonctionne : "Personnage", '
      '"Compétences", "Inventaire" et "Histoire" ont chacun un vrai contenu, '
      'avec le titre du bandeau qui suit l\'onglet actif', (tester) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(
      appearanceText: 'Cheveux argentés.',
    );

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('FICHE'), findsOneWidget);

    await tester.tap(find.text('COMP.'));
    await tester.pumpAndSettle();
    expect(find.text('LES 18 COMPÉTENCES'), findsOneWidget);
    expect(find.text('Halltesse Ambrelune'), findsNothing);
    expect(find.text('COMPÉTENCES'), findsOneWidget);
    expect(find.text('FICHE'), findsNothing);

    await tester.tap(find.text('SAC'));
    await tester.pumpAndSettle();
    // Rangée de stat boxes toujours affichée, même sans monnaie/inventaire
    // (voir `character_inventory_tab_body_test.dart` pour le détail de ce
    // contenu) : "0" (PO) prouve que l'onglet a bien basculé sur
    // `CharacterInventoryTabBody`, pas sur un autre onglet.
    expect(find.text('PO'), findsOneWidget);
    expect(find.text('Ajouter un objet'), findsOneWidget);
    expect(find.text('INVENTAIRE'), findsOneWidget);

    await tester.tap(find.text('HIST.'));
    await tester.pumpAndSettle();
    // Preuve que l'onglet a bien basculé sur `CharacterStoryTabBody` (voir
    // `character_story_tab_body_test.dart` pour le détail de ce contenu).
    expect(find.text('APPARENCE PHYSIQUE'), findsOneWidget);
    expect(find.text('Cheveux argentés.'), findsOneWidget);
    expect(find.text('HISTOIRE'), findsOneWidget);

    await tester.tap(find.text('PERSO'));
    await tester.pumpAndSettle();
    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('FICHE'), findsOneWidget);
  });
}
