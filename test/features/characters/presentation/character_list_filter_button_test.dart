// Tests de widget du bouton de filtre de l'écran "Liste des personnages"
// (`character_list_screen.dart::_FilterButton`) : pastille "filtre actif" et
// sémantique du bouton.
//
// Fichier distinct de `character_list_screen_test.dart` (qui couvre le
// comportement du filtre lui-même) : le bouton est privé à l'écran, il est
// donc exercé ici à travers `CharacterListScreen`, avec les mêmes doubles
// injectés via `overrideWithValue`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/core/router/route_observer_provider.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/presentation/character_list_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

/// Seule `fetchCharacters` est utilisée ici ; toute autre méthode échoue
/// bruyamment via `noSuchMethod`.
class _FakeCharacterRepository implements CharacterRepository {
  List<CharacterSummary> charactersToReturn = const [];

  /// Non nul : `fetchCharacters` reste en attente (état "chargement").
  Completer<List<CharacterSummary>>? completer;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async {
    if (completer != null) return completer!.future;
    return charactersToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// Jamais sollicité par ces tests : toute méthode échoue bruyamment.
class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// Statut "à jour" : la bannière "Mise à jour suggérée" reste invisible.
class _FakeAppVersionRepository implements AppVersionRepository {
  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async =>
      const AppVersionRow(
        minimumSupportedVersion: '0.1.0',
        latestVersion: '0.1.0',
      );
}

const _characters = [
  CharacterSummary(id: '1', name: 'Halltesse Ambrelune', level: 5, xp: 7000),
  CharacterSummary(
    id: '2',
    name: 'Sylvi Aubefeuille',
    level: 1,
    xp: 0,
    isDead: true,
  ),
];

/// Emprise du pictogramme `Icons.filter_list` dans sa boîte 24×24 : trois
/// barres, de (3, 6) à (21, 18) (tracé Material
/// `M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z`). La boîte 24×24 de
/// l'`Icon` est plus grande que ce que l'œil voit : c'est le pictogramme que
/// la pastille ne doit pas chevaucher.
const _glyphInsets = EdgeInsets.fromLTRB(3, 6, 3, 6);

Finder _filterIcon() => find.byIcon(Icons.filter_list);

/// L'`InkWell` 44×44 du bouton de filtre : la zone de tap réelle.
Finder _filterButton() =>
    find.ancestor(of: _filterIcon(), matching: find.byType(InkWell));

/// La pastille "filtre actif" : le disque `gold-end` porté par le bouton.
Finder _activeDot() => find.descendant(
  of: _filterButton(),
  matching: find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final decoration = widget.decoration;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == AppColors.goldEnd;
  }),
);

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'com.nexusjdr.personnages',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  late _FakeCharacterRepository fakeCharacterRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository()
      ..charactersToReturn = _characters;
  });

  Widget buildTestWidget() {
    final observer = RouteObserver<PageRoute<dynamic>>();
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeCharacterRepository),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        routeObserverProvider.overrideWithValue(observer),
        appVersionRepositoryProvider.overrideWithValue(
          _FakeAppVersionRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          observers: [observer],
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const CharacterListScreen(),
            ),
          ],
        ),
      ),
    );
  }

  /// Monte l'écran, liste résolue, aucun filtre actif.
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
  }

  /// Active le filtre de statut "Mort" depuis la sheet "FILTRER".
  Future<void> activateFilter(WidgetTester tester) async {
    await tester.tap(_filterButton());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mort'));
    await tester.tap(find.text('APPLIQUER'));
    await tester.pumpAndSettle();
    expect(find.text('Halltesse Ambrelune'), findsNothing);
  }

  /// Rectangle de [finder] dans le repère du bouton de filtre (44×44).
  Rect rectInButton(WidgetTester tester, Finder finder) {
    final origin = tester.getTopLeft(_filterButton());
    return tester.getRect(finder).shift(-origin);
  }

  group('pastille "filtre actif"', () {
    testWidgets('absente tant qu\'aucun filtre n\'est actif', (tester) async {
      await pumpScreen(tester);

      expect(_filterButton(), findsOneWidget);
      expect(_activeDot(), findsNothing);
    });

    testWidgets('présente dès qu\'un filtre est actif, retirée quand il est '
        'réinitialisé', (tester) async {
      await pumpScreen(tester);
      await activateFilter(tester);

      expect(_activeDot(), findsOneWidget);

      await tester.tap(_filterButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('RÉINITIALISER'));
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(_activeDot(), findsNothing);
    });

    testWidgets('disque gold-end cerclé d\'un liseré wood.dark de 1 px', (
      tester,
    ) async {
      await pumpScreen(tester);
      await activateFilter(tester);

      final decoration =
          tester.widget<Container>(_activeDot()).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.goldEnd);
      expect(decoration.shape, BoxShape.circle);
      // Largeur fixée par la spec (1 px), en littéral : indépendante du
      // token employé en production comme de la valeur par défaut de Flutter.
      final border = decoration.border! as Border;
      expect(border.isUniform, isTrue);
      expect(border.top.color, AppColors.woodDark);
      expect(border.top.width, 1);
      expect(border.top.style, BorderStyle.solid);
    });

    testWidgets('dans le coin supérieur droit du bouton, entièrement à '
        'l\'intérieur, sans chevaucher le pictogramme', (tester) async {
      await pumpScreen(tester);
      await activateFilter(tester);

      const button = Rect.fromLTWH(0, 0, 44, 44);
      expect(tester.getSize(_filterButton()), button.size);

      final dot = rectInButton(tester, _activeDot());
      final icon = rectInButton(tester, _filterIcon());
      final glyph = _glyphInsets.deflateRect(icon);

      // Critère de la spec direction-artistique : diamètre hors tout 10 px
      // (disque de 8 px + liseré de 1 px), centre en (34, 10).
      expect(dot, const Rect.fromLTRB(29, 5, 39, 15));

      expect(
        button.contains(dot.topLeft) && button.contains(dot.bottomRight),
        isTrue,
        reason: 'la pastille ne doit pas déborder du bouton',
      );
      expect(
        dot.center.dx > button.center.dx && dot.center.dy < button.center.dy,
        isTrue,
        reason: 'la pastille doit être dans le quart supérieur droit',
      );
      expect(
        dot.contains(icon.center),
        isFalse,
        reason: 'la pastille ne doit pas recouvrir le centre de l\'icône',
      );
      expect(
        dot.overlaps(glyph),
        isFalse,
        reason: 'la pastille ne doit pas chevaucher le pictogramme',
      );
    });

    testWidgets('n\'intercepte pas le tap : taper sur la pastille ouvre la '
        'sheet de filtre', (tester) async {
      await pumpScreen(tester);
      await activateFilter(tester);
      expect(find.text('FILTRER'), findsNothing);

      await tester.tap(_activeDot());
      await tester.pumpAndSettle();

      expect(find.text('FILTRER'), findsOneWidget);
    });
  });

  group('géométrie du bouton', () {
    testWidgets('bouton 44×44 et icône au même endroit avec et sans pastille', (
      tester,
    ) async {
      await pumpScreen(tester);
      final buttonWithoutDot = tester.getRect(_filterButton());
      final iconWithoutDot = rectInButton(tester, _filterIcon());

      await activateFilter(tester);

      expect(tester.getRect(_filterButton()), buttonWithoutDot);
      expect(buttonWithoutDot.size, const Size(44, 44));
      expect(rectInButton(tester, _filterIcon()), iconWithoutDot);
      // Icône centrée dans le bouton.
      expect(iconWithoutDot, const Rect.fromLTRB(10, 10, 34, 34));
    });

    testWidgets('rendu indépendant de l\'échelle de texte', (tester) async {
      await pumpScreen(tester);
      await activateFilter(tester);
      final icon = rectInButton(tester, _filterIcon());
      final dot = rectInButton(tester, _activeDot());

      // Échelle de texte du système doublée, écran et filtre conservés.
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(
        MediaQuery.textScalerOf(tester.element(_filterButton())).scale(10),
        20,
      );

      expect(tester.getSize(_filterButton()), const Size(44, 44));
      expect(rectInButton(tester, _filterIcon()), icon);
      expect(rectInButton(tester, _activeDot()), dot);
    });
  });

  group('sémantique', () {
    testWidgets('filtre inactif : bouton "Filtrer les personnages", sans '
        'valeur', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      expect(
        tester.getSemantics(_filterButton()),
        matchesSemantics(
          label: 'Filtrer les personnages',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      // `matchesSemantics` ne compare pas une valeur qu'on ne lui passe pas :
      // l'absence de valeur doit être vérifiée explicitement.
      expect(tester.getSemantics(_filterButton()).value, isEmpty);
      handle.dispose();
    });

    testWidgets('filtre actif : même libellé, valeur "Filtre actif"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);
      await activateFilter(tester);

      expect(
        tester.getSemantics(_filterButton()),
        matchesSemantics(
          label: 'Filtrer les personnages',
          value: 'Filtre actif',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('chargement : bouton annoncé désactivé, sans action de tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      fakeCharacterRepository.completer = Completer<List<CharacterSummary>>();
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(
        tester.getSemantics(_filterButton()),
        matchesSemantics(
          label: 'Filtrer les personnages',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      expect(tester.getSemantics(_filterButton()).value, isEmpty);

      // Sans effet : rien à filtrer tant que la liste n'a pas résolu.
      await tester.tap(_filterButton());
      await tester.pump();
      expect(find.text('FILTRER'), findsNothing);
      handle.dispose();
    });

    testWidgets('un seul nœud : ni l\'icône ni la pastille n\'en créent un', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);
      await activateFilter(tester);

      final button = tester.getSemantics(_filterButton());
      expect(button.childrenCount, 0);
      expect(tester.getSemantics(_filterIcon()).id, button.id);
      expect(tester.getSemantics(_activeDot()).id, button.id);
      expect(find.bySemanticsLabel('Filtrer les personnages'), findsOneWidget);
      handle.dispose();
    });
  });
}
