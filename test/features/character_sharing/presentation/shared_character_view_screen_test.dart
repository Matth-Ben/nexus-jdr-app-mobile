// Tests de widget de l'écran "Vue en lecture seule" d'un personnage partagé
// (`/p/:token`) — dépôt de test injecté via `overrideWithValue` sur
// `characterSharingRepositoryProvider`, même principe que
// `character_share_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/character_sharing/data/character_sharing_repository.dart';
import 'package:personnages/features/character_sharing/presentation/providers/character_sharing_providers.dart';
import 'package:personnages/features/character_sharing/presentation/shared_character_view_screen.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';

class _FakeCharacterSharingRepository implements CharacterSharingRepository {
  CharacterDetail? detailToReturn;
  Object? errorToThrow;
  Completer<CharacterDetail?>? completer;

  @override
  Future<CharacterDetail?> fetchSharedCharacter(String token) async {
    if (completer != null) return completer!.future;
    if (errorToThrow != null) throw errorToThrow!;
    return detailToReturn;
  }

  @override
  Future<String> regenerateShareToken(String characterId) =>
      throw UnimplementedError();

  @override
  Future<void> disableShareToken(String characterId) =>
      throw UnimplementedError();
}

const _baseDetail = CharacterDetail(
  id: 'char-1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
      className: 'Magicienne',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: ['int', 'wis'],
    ),
  ],
  xp: 100,
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
  late _FakeCharacterSharingRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeCharacterSharingRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        characterSharingRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/p/tok-abc',
          routes: [
            GoRoute(
              path: '/p/:token',
              builder: (context, state) => SharedCharacterViewScreen(
                token: state.pathParameters['token']!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Surface agrandie : les cartes de l'onglet "Personnage" (grille de
  // caractéristiques, jets de sauvegarde) sont autrement hors du cacheExtent
  // par défaut d'un `ListView` sur 800×600 — même ajustement que
  // `character_detail_screen_test.dart`.
  Future<void> pumpSharedView(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestWidget());
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    tester,
  ) async {
    fakeRepository.completer = Completer<CharacterDetail?>();

    await pumpSharedView(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'token invalide/révoqué (résultat null) : affiche l\'état "lien non '
    'valide", pas la barre d\'onglets',
    (tester) async {
      fakeRepository.detailToReturn = null;

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('n\'est plus valide'), findsOneWidget);
      expect(find.text('PERSO'), findsNothing);
    },
  );

  testWidgets(
    'personnage partagé valide : affiche le bandeau "lecture seule", '
    'l\'identité et les caractéristiques, avec la barre de 5 onglets',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      expect(find.text('Vue en lecture seule'), findsOneWidget);
      expect(find.text('Halltesse Ambrelune'), findsOneWidget);
      expect(find.text('Elfe · Magicienne · Niveau 5'), findsOneWidget);
      expect(find.text('PERSO'), findsOneWidget);
      expect(find.text('COMP.'), findsOneWidget);
      expect(find.text('SORTS'), findsOneWidget);
      expect(find.text('SAC'), findsOneWidget);
      expect(find.text('HIST.'), findsOneWidget);
    },
  );

  testWidgets('changer d\'onglet affiche le contenu de l\'onglet Compétences '
      'en lecture seule', (tester) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpSharedView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('COMP.'));
    await tester.pumpAndSettle();

    expect(find.text('COMPÉTENCES'), findsOneWidget);
  });

  testWidgets(
    'échec réseau : affiche le message d\'erreur avec un bouton "Réessayer"',
    (tester) async {
      fakeRepository.errorToThrow = const CharacterFailure(
        'Impossible de charger ce personnage. Réessayez.',
      );

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger ce personnage. Réessayez.'),
        findsOneWidget,
      );

      fakeRepository.errorToThrow = null;
      fakeRepository.detailToReturn = _baseDetail;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    },
  );
}
