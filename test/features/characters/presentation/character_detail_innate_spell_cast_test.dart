// Tests de widget du lancer d'un sort inné de niveau >= 1 depuis la fiche
// (`character_detail_screen.dart::_castInnateSpell`, D08) : lancé sans
// emplacement ni sheet de choix, usage dépensé en mise à jour optimiste,
// retour en arrière hors ligne ou sur échec, remise à zéro au repos long
// (jamais au repos court), et course avec un repos — même classe de course
// que `character_detail_rest_stale_feature_uses_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';

const _innateSpellId = 10;
// D11 : message désormais affiché pour `setInnateSpellUsesSpent` hors ligne
// (mise en file réelle) — même texte que `_offlineQueuedMessage` de
// `character_detail_screen.dart`. L'ancien message « non enregistrée »
// (jamais mis en file) ne s'affiche plus pour cette méthode.
const _offlineQueuedMessage =
    'Hors ligne : sera synchronisé dès que la connexion revient.';
const _slotsLabel = 'Emplacements de sorts : 2 restants sur 2';

CharacterSpellEntry _innate({int spent = 0}) => CharacterSpellEntry(
  id: _innateSpellId,
  name: 'Ténèbres',
  level: 2,
  school: 'Évocation',
  status: 'inné',
  innateUsesSpent: spent,
);

const _innateCantrip = CharacterSpellEntry(
  id: 11,
  name: 'Lumières dansantes',
  level: 0,
  school: 'Évocation',
  status: 'inné',
);

CharacterDetail _detail({
  int spent = 0,
  List<CharacterSpellSlot> spellSlots = const [
    CharacterSpellSlot(level: 2, total: 2, used: 0),
    CharacterSpellSlot(level: 3, total: 1, used: 0),
  ],
}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: const [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 6,
      className: 'Magicien',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 30,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: const {},
  spells: [
    _innate(spent: spent),
    _innateCantrip,
  ],
  spellSlots: spellSlots,
);

/// Seules les méthodes utiles à ces tests sont implémentées ; toute autre
/// échoue bruyamment via `noSuchMethod`.
class _FakeRepository implements CharacterRepository {
  _FakeRepository(this.current);

  CharacterDetail current;

  /// Laissé non complété pour garder l'écriture du compteur en vol.
  Completer<void>? innateGate;
  WriteOutcome innateOutcome = WriteOutcome.synced;
  Object? innateError;
  final innateCalls = <({int spellId, int usesSpent})>[];
  int castSpellCallCount = 0;
  final restTypes = <RestType>[];
  Object? restError;

  /// Laissé non complété pour garder le repos en vol.
  Completer<void>? restGate;

  void _setSpent(int spent) {
    current = current.copyWith(
      spells: [
        for (final spell in current.spells)
          if (spell.id == _innateSpellId)
            spell.copyWithInnateUsesSpent(spent)
          else
            spell,
      ],
    );
  }

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      current;

  @override
  Future<WriteOutcome> setInnateSpellUsesSpent({
    required String characterId,
    required int spellId,
    required int usesSpent,
  }) async {
    innateCalls.add((spellId: spellId, usesSpent: usesSpent));
    await innateGate?.future;
    if (innateError != null) throw innateError!;
    if (innateOutcome == WriteOutcome.synced) _setSpent(usesSpent);
    return innateOutcome;
  }

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    bool isPactSlot = false,
  }) async {
    castSpellCallCount++;
    return WriteOutcome.synced;
  }

  @override
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    int diceSpent = 0,
    int appliedGain = 0,
  }) async {
    restTypes.add(type);
    await restGate?.future;
    if (restError != null) throw restError!;
    // Dépôt réel : le compteur n'est remis à 0 qu'au repos long.
    if (type == RestType.long) _setSpent(0);
    return WriteOutcome.synced;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<_FakeRepository> _pumpDetail(
  WidgetTester tester,
  CharacterDetail detail,
) async {
  final repository = _FakeRepository(detail);
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/characters/1',
          routes: [
            GoRoute(
              path: '/characters/:id',
              builder: (context, state) => CharacterDetailScreen(
                characterId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _openSpellsTab(WidgetTester tester) async {
  await tester.tap(find.text('SORTS'));
  await tester.pumpAndSettle();
}

/// Ouvre le panneau "Infos" du sort [name] puis tape "Lancer".
Future<void> _cast(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
  await tester.pumpAndSettle();
}

Future<void> _rest(WidgetTester tester, {required bool long}) async {
  await tester.tap(find.text('PERSO'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('REPOS'));
  await tester.pumpAndSettle();
  if (!long) {
    await tester.tap(find.text('REPOS COURT'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('APPLIQUER'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lancer : aucune sheet de choix malgré deux niveaux '
      'd\'emplacement éligibles, usage écrit, aucun emplacement consommé, '
      'message « lancé (sort inné) » et ligne « Épuisé »', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final repository = await _pumpDetail(tester, _detail());
    await _openSpellsTab(tester);
    expect(find.text('INNÉ'), findsOneWidget);
    expect(find.text('Épuisé'), findsNothing);
    expect(find.bySemanticsLabel(_slotsLabel), findsOneWidget);

    await _cast(tester, 'Ténèbres');

    expect(
      find.text("Choisissez le niveau d'emplacement à utiliser."),
      findsNothing,
    );
    // Panneau fermé.
    expect(find.text('TÉNÈBRES'), findsNothing);
    expect(repository.innateCalls, [(spellId: _innateSpellId, usesSpent: 1)]);
    expect(repository.castSpellCallCount, 0);
    expect(find.text('Ténèbres lancé (sort inné).'), findsOneWidget);
    expect(find.text('Épuisé'), findsOneWidget);
    // Les pastilles d'emplacements du titre de groupe n'ont pas bougé.
    expect(find.bySemanticsLabel(_slotsLabel), findsOneWidget);

    semanticsHandle.dispose();
  });

  testWidgets('personnage sans aucun emplacement : le sort inné se lance '
      'quand même', (tester) async {
    final repository = await _pumpDetail(tester, _detail(spellSlots: const []));
    await _openSpellsTab(tester);

    await _cast(tester, 'Ténèbres');

    expect(repository.innateCalls, [(spellId: _innateSpellId, usesSpent: 1)]);
    expect(find.text('Ténèbres lancé (sort inné).'), findsOneWidget);
  });

  testWidgets('mise à jour optimiste : la ligne passe à « Épuisé » avant la '
      'fin de l\'écriture, et l\'onglet est verrouillé pendant l\'appel', (
    tester,
  ) async {
    final repository = await _pumpDetail(tester, _detail());
    repository.innateGate = Completer<void>();
    await _openSpellsTab(tester);

    await _cast(tester, 'Ténèbres');

    expect(repository.innateCalls, hasLength(1));
    expect(find.text('Épuisé'), findsOneWidget);
    expect(find.text('Ténèbres lancé (sort inné).'), findsNothing);
    // Verrou : un second tap pendant l'appel n'ouvre rien.
    await tester.tap(find.text('Ténèbres'));
    await tester.pumpAndSettle();
    expect(find.text('TÉNÈBRES'), findsNothing);

    repository.innateGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Épuisé'), findsOneWidget);
    expect(find.text('Ténèbres lancé (sort inné).'), findsOneWidget);
    expect(repository.innateCalls, hasLength(1));
  });

  // Double déclenchement (QA) : le verrou de l'onglet ferme le double tap
  // ordinaire, et `_castInnateSpell` relit l'usage sur la fiche effective —
  // un second « Lancer » parti d'un état périmé n'écrit donc jamais un
  // compteur à 2.
  testWidgets('double tap rapide sur « Lancer » : une seule écriture, '
      'compteur à 1', (tester) async {
    final repository = await _pumpDetail(tester, _detail());
    repository.innateGate = Completer<void>();
    await _openSpellsTab(tester);
    await tester.tap(find.text('Ténèbres'));
    await tester.pumpAndSettle();

    final castButton = find.widgetWithText(PrimaryButton, 'LANCER');
    await tester.tap(castButton);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(castButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    // Panneau fermé, et la ligne verrouillée ne le rouvre pas.
    await tester.tap(find.text('Ténèbres'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PrimaryButton, 'LANCER'), findsNothing);

    repository.innateGate!.complete();
    await tester.pumpAndSettle();

    expect(repository.innateCalls, [(spellId: _innateSpellId, usesSpent: 1)]);
    expect(repository.current.spells.first.innateUsesSpent, 1);
    expect(repository.castSpellCallCount, 0);
  });

  testWidgets('second « Lancer » parti d\'un état périmé (sort encore vu '
      'disponible) pendant le premier appel : ignoré, aucune écriture à 2', (
    tester,
  ) async {
    final repository = await _pumpDetail(tester, _detail());
    repository.innateGate = Completer<void>();
    await _openSpellsTab(tester);
    final body = tester.widget<CharacterSpellsTabBody>(
      find.byType(CharacterSpellsTabBody),
    );

    // Même instantané « disponible » pour les deux appels, comme deux
    // panneaux « Infos » ouverts sur le même état.
    body.onCastSpell(_innate(), null);
    body.onCastSpell(_innate(), null);
    await tester.pump();

    expect(repository.innateCalls, [(spellId: _innateSpellId, usesSpent: 1)]);

    repository.innateGate!.complete();
    await tester.pumpAndSettle();

    expect(repository.innateCalls, [(spellId: _innateSpellId, usesSpent: 1)]);
    expect(repository.current.spells.first.innateUsesSpent, 1);
    expect(find.text('Épuisé'), findsOneWidget);
  });

  testWidgets('épuisé : « Lancer » désactivé avec sa raison, aucune '
      'écriture', (tester) async {
    final repository = await _pumpDetail(tester, _detail(spent: 1));
    await _openSpellsTab(tester);
    expect(find.text('Épuisé'), findsOneWidget);

    await tester.tap(find.text('Ténèbres'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'LANCER'))
          .onPressed,
      isNull,
    );
    expect(
      find.text('Déjà utilisé : disponible après un repos long.'),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(PrimaryButton, 'LANCER'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(repository.innateCalls, isEmpty);
    expect(repository.castSpellCallCount, 0);
  });

  // D11 du registre de dette technique (09/10/2026) : `setInnateSpellUsesSpent`
  // est désormais réellement mise en file hors ligne (contrairement au
  // comportement antérieur, jamais mis en file) — l'état optimiste local
  // (« Épuisé ») reste donc affiché tel quel, jamais revert, avec le même
  // message honnête que PV/XP (`_offlineQueuedMessage`).
  testWidgets(
    'hors ligne : message de mise en file, la ligne passe à « Épuisé » et '
    'le sort reste affiché comme tel (rien à annuler)',
    (tester) async {
      final repository = await _pumpDetail(tester, _detail());
      repository.innateOutcome = WriteOutcome.queued;
      await _openSpellsTab(tester);

      await _cast(tester, 'Ténèbres');

      expect(find.text(_offlineQueuedMessage), findsOneWidget);
      expect(find.text('Ténèbres lancé (sort inné).'), findsNothing);
      expect(
        find.text('Épuisé'),
        findsOneWidget,
        reason:
            'mis en file : contrairement à l\'ancien comportement (jamais '
            'mis en file, revert), l\'usage reste affiché comme dépensé — il '
            'sera rejoué au retour du réseau',
      );
    },
  );

  testWidgets('échec (CharacterFailure) : message du dépôt, retour à '
      '« disponible »', (tester) async {
    final repository = await _pumpDetail(tester, _detail());
    repository.innateError = const CharacterFailure('Accès refusé.');
    await _openSpellsTab(tester);

    await _cast(tester, 'Ténèbres');

    expect(find.text('Accès refusé.'), findsOneWidget);
    expect(find.text('Épuisé'), findsNothing);
  });

  testWidgets('échec inattendu : message générique existant, retour à '
      '« disponible »', (tester) async {
    final repository = await _pumpDetail(tester, _detail());
    repository.innateError = StateError('boom');
    await _openSpellsTab(tester);

    await _cast(tester, 'Ténèbres');

    expect(
      find.text('Impossible de lancer ce sort. Réessayez.'),
      findsOneWidget,
    );
    expect(find.text('Épuisé'), findsNothing);
  });

  testWidgets('sort mineur inné : à volonté, rien n\'est écrit, message '
      '« lancé. » inchangé', (tester) async {
    final repository = await _pumpDetail(tester, _detail());
    await _openSpellsTab(tester);

    await _cast(tester, 'Lumières dansantes');
    await _cast(tester, 'Lumières dansantes');

    expect(repository.innateCalls, isEmpty);
    expect(repository.castSpellCallCount, 0);
    expect(find.text('Lumières dansantes lancé.'), findsOneWidget);
  });

  group('repos', () {
    testWidgets('repos long après un lancer : usage rendu, la ligne revient '
        'à « disponible » et le sort se relance', (tester) async {
      final repository = await _pumpDetail(tester, _detail());
      await _openSpellsTab(tester);
      await _cast(tester, 'Ténèbres');
      expect(find.text('Épuisé'), findsOneWidget);

      await _rest(tester, long: true);
      await _openSpellsTab(tester);

      expect(repository.restTypes, [RestType.long]);
      expect(find.text('Épuisé'), findsNothing);
      expect(find.text('INNÉ'), findsOneWidget);

      await _cast(tester, 'Ténèbres');
      expect(repository.innateCalls, [
        (spellId: _innateSpellId, usesSpent: 1),
        (spellId: _innateSpellId, usesSpent: 1),
      ]);
    });

    testWidgets('repos long, usage déjà dépensé à l\'ouverture de la fiche : '
        'la ligne revient à « disponible »', (tester) async {
      await _pumpDetail(tester, _detail(spent: 1));
      await _openSpellsTab(tester);
      expect(find.text('Épuisé'), findsOneWidget);

      await _rest(tester, long: true);
      await _openSpellsTab(tester);

      expect(find.text('Épuisé'), findsNothing);
    });

    testWidgets('repos court : l\'usage reste dépensé', (tester) async {
      final repository = await _pumpDetail(tester, _detail());
      await _openSpellsTab(tester);
      await _cast(tester, 'Ténèbres');

      await _rest(tester, long: false);
      await _openSpellsTab(tester);

      expect(repository.restTypes, [RestType.short]);
      expect(find.text('Épuisé'), findsOneWidget);
    });

    testWidgets('repos long en échec pendant un lancer encore en vol : la '
        'surcouche purgée est rétablie, la ligne reste « Épuisé »', (
      tester,
    ) async {
      final repository = await _pumpDetail(tester, _detail());
      repository.innateGate = Completer<void>();
      repository.restError = const CharacterFailure('Repos impossible.');
      await _openSpellsTab(tester);
      await _cast(tester, 'Ténèbres');

      await _rest(tester, long: true);
      await _openSpellsTab(tester);

      expect(find.text('Épuisé'), findsOneWidget);
      repository.innateGate!.complete();
      await tester.pumpAndSettle();
    });

    // Même classe de course que
    // `character_detail_rest_stale_feature_uses_test.dart`.
    testWidgets('COURSE — un lancer resté en vol au moment d\'un repos long '
        'ne doit pas écraser le résultat du repos une fois résolu', (
      tester,
    ) async {
      final repository = await _pumpDetail(tester, _detail());
      repository.innateGate = Completer<void>();
      await _openSpellsTab(tester);
      await _cast(tester, 'Ténèbres');
      expect(repository.innateCalls, hasLength(1));

      // Le repos long démarre et résout pendant que le lancer est en vol.
      await _rest(tester, long: true);
      expect(repository.restTypes, [RestType.long]);
      expect(repository.current.spells.first.innateUsesSpent, 0);

      // Le lancer resté en vol résout enfin, avec sa valeur pré-repos (1).
      repository.innateGate!.complete();
      await tester.pumpAndSettle();

      expect(
        repository.current.spells.first.innateUsesSpent,
        0,
        reason:
            'le lancer resté en vol a écrasé la remise à zéro du repos long',
      );
      await _openSpellsTab(tester);
      expect(find.text('Épuisé'), findsNothing);
    });

    testWidgets('COURSE — un lancer resté en vol au moment d\'un repos court '
        '(qui ne rend pas l\'usage) reste dépensé une fois résolu', (
      tester,
    ) async {
      final repository = await _pumpDetail(tester, _detail());
      repository.innateGate = Completer<void>();
      await _openSpellsTab(tester);
      await _cast(tester, 'Ténèbres');

      await _rest(tester, long: false);
      expect(repository.restTypes, [RestType.short]);
      repository.innateGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.current.spells.first.innateUsesSpent, 1);
      await _openSpellsTab(tester);
      expect(find.text('Épuisé'), findsOneWidget);
    });

    // Retour QA : un repos court avance le jeton de course mais ne purge pas
    // la surcouche des sorts innés. Un lancer en vol qui échoue (ou n'est
    // pas envoyé) après ce repos doit quand même revenir à « disponible ».
    group('lancer en vol non enregistré après le démarrage d\'un repos', () {
      /// Laisse défiler la SnackBar du repos pour afficher la suivante.
      Future<void> showNextSnackBar(WidgetTester tester) async {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }

      Future<_FakeRepository> castThenRest(
        WidgetTester tester, {
        required bool long,
        Object? innateError,
        WriteOutcome innateOutcome = WriteOutcome.synced,
        Object? restError,
      }) async {
        final repository = await _pumpDetail(tester, _detail());
        repository
          ..innateGate = Completer<void>()
          ..innateError = innateError
          ..innateOutcome = innateOutcome
          ..restError = restError;
        await _openSpellsTab(tester);
        await _cast(tester, 'Ténèbres');
        expect(find.text('Épuisé'), findsOneWidget);

        await _rest(tester, long: long);
        expect(repository.restTypes, [long ? RestType.long : RestType.short]);

        repository.innateGate!.complete();
        await tester.pumpAndSettle();
        return repository;
      }

      Future<void> expectAvailableAgain(
        WidgetTester tester,
        _FakeRepository repository,
        String message,
      ) async {
        await showNextSnackBar(tester);
        expect(find.text(message), findsOneWidget);
        // Rien n'a été écrit, et aucune réécriture n'a été tentée.
        expect(repository.current.spells.first.innateUsesSpent, 0);
        expect(repository.innateCalls, hasLength(1));
        await _openSpellsTab(tester);
        expect(find.text('Épuisé'), findsNothing);
        expect(find.text('INNÉ'), findsOneWidget);
      }

      // D11 : un lancer mis en file (hors ligne) n'est plus jamais annulé —
      // contrairement à [expectAvailableAgain] (erreur dure ou inattendue),
      // rien n'est rejoué tant que le réseau n'est pas revenu. [expectSpent]
      // est `false` dans le seul cas où un repos LONG (sans gate) a déjà eu
      // le temps de réinitialiser le compteur AVANT que cette résolution
      // tardive n'arrive (voir le test "repos long puis lancer mis en
      // file") : la réussite déjà confirmée du repos n'est alors jamais
      // écrasée par une intention hors ligne arrivée après coup — même
      // principe défensif que [_restGeneration] pour les écritures qui
      // RÉUSSISSENT, étendu ici à une mise en file tardive.
      Future<void> expectQueuedAndKept(
        WidgetTester tester,
        _FakeRepository repository, {
        required bool expectSpent,
      }) async {
        await showNextSnackBar(tester);
        expect(find.text(_offlineQueuedMessage), findsOneWidget);
        expect(repository.innateCalls, hasLength(1));
        await _openSpellsTab(tester);
        expect(
          find.text('Épuisé'),
          expectSpent ? findsOneWidget : findsNothing,
        );
      }

      testWidgets('repos court puis échec du lancer : message du dépôt, la '
          'ligne revient à « disponible »', (tester) async {
        final repository = await castThenRest(
          tester,
          long: false,
          innateError: const CharacterFailure('Accès refusé.'),
        );

        await expectAvailableAgain(tester, repository, 'Accès refusé.');
      });

      testWidgets('repos court puis échec inattendu du lancer : message '
          'générique, la ligne revient à « disponible »', (tester) async {
        final repository = await castThenRest(
          tester,
          long: false,
          innateError: StateError('boom'),
        );

        await expectAvailableAgain(
          tester,
          repository,
          'Impossible de lancer ce sort. Réessayez.',
        );
      });

      testWidgets(
        'repos court puis lancer mis en file (hors ligne, D11) : message '
        'de mise en file, la ligne reste « Épuisé »',
        (tester) async {
          final repository = await castThenRest(
            tester,
            long: false,
            innateOutcome: WriteOutcome.queued,
          );

          await expectQueuedAndKept(tester, repository, expectSpent: true);
        },
      );

      testWidgets('repos long puis échec du lancer : message du dépôt, la '
          'ligne reste « disponible »', (tester) async {
        final repository = await castThenRest(
          tester,
          long: true,
          innateError: const CharacterFailure('Accès refusé.'),
        );

        await expectAvailableAgain(tester, repository, 'Accès refusé.');
      });

      // D11, cas particulier : `castThenRest` ne pose jamais de `restGate`
      // (seul `innateGate` retarde l'écriture du sort) — le repos LONG a
      // donc déjà fini (avec succès) et réinitialisé le compteur AVANT que
      // cette résolution tardive « queued » n'arrive. Contrairement au cas
      // "repos court" ci-dessus (qui ne touche jamais ce compteur), la
      // réussite déjà confirmée du repos long l'emporte : la ligne ne doit
      // pas redevenir « Épuisé » à cause d'une intention hors ligne
      // dépassée par un événement entre-temps déjà réglé côté serveur.
      testWidgets(
        'repos long puis lancer mis en file (hors ligne, D11) : message de '
        'mise en file, mais le repos long (déjà réussi) a priorité — la '
        'ligne reste « disponible »',
        (tester) async {
          final repository = await castThenRest(
            tester,
            long: true,
            innateOutcome: WriteOutcome.queued,
          );

          await expectQueuedAndKept(tester, repository, expectSpent: false);
        },
      );

      // Retour de revue : ordre inverse du test suivant. Le lancer échoue
      // PENDANT que le repos long est encore en vol (surcouche purgée,
      // instantané pré-repos encore détenu par le repos), puis le repos
      // échoue : il ne doit pas rétablir l'entrée d'un lancer jamais
      // enregistré.
      testWidgets(
        'repos long EN VOL, le lancer échoue, PUIS le repos échoue : la '
        'ligne revient à « disponible », base à 0',
        (tester) async {
          final repository = await _pumpDetail(tester, _detail());
          repository
            ..innateGate = Completer<void>()
            ..innateError = const CharacterFailure('Accès refusé.')
            ..restGate = Completer<void>()
            ..restError = const CharacterFailure('Repos impossible.');
          await _openSpellsTab(tester);
          await _cast(tester, 'Ténèbres');
          expect(find.text('Épuisé'), findsOneWidget);

          // Le repos long démarre et reste en vol.
          await _rest(tester, long: true);
          expect(repository.restTypes, [RestType.long]);

          // Le lancer échoue pendant le repos.
          repository.innateGate!.complete();
          await tester.pumpAndSettle();
          expect(find.text('Accès refusé.'), findsOneWidget);

          // Puis le repos échoue à son tour.
          repository.restGate!.complete();
          await tester.pumpAndSettle();
          await showNextSnackBar(tester);
          expect(find.text('Repos impossible.'), findsOneWidget);

          expect(repository.current.spells.first.innateUsesSpent, 0);
          expect(repository.innateCalls, hasLength(1));
          await _openSpellsTab(tester);
          expect(find.text('Épuisé'), findsNothing);
          expect(find.text('INNÉ'), findsOneWidget);

          // Le sort se relance normalement.
          repository
            ..innateGate = null
            ..innateError = null
            ..innateOutcome = WriteOutcome.synced;
          await _cast(tester, 'Ténèbres');
          expect(repository.innateCalls.last, (
            spellId: _innateSpellId,
            usesSpent: 1,
          ));
        },
      );

      // D11 : contrairement au cas d'erreur ci-dessus, un lancer mis en file
      // pendant un repos long en vol n'est PLUS jamais annulé — y compris si
      // ce repos échoue à son tour. L'instantané pré-repos
      // (`_innateOverrideBeforeRest`) que le repos restaure en cas d'échec
      // contient donc toujours l'entrée « dépensé » (jamais retirée, voir
      // `revertOverride` dans `_castInnateSpell`) : la ligne reste
      // « Épuisé », pas « disponible » — le lancer reste promis à une
      // synchronisation future.
      testWidgets(
        'repos long EN VOL, le lancer est mis en file (hors ligne, D11), '
        'PUIS le repos échoue : la ligne reste « Épuisé »',
        (tester) async {
          final repository = await _pumpDetail(tester, _detail());
          repository
            ..innateGate = Completer<void>()
            ..innateOutcome = WriteOutcome.queued
            ..restGate = Completer<void>()
            ..restError = const CharacterFailure('Repos impossible.');
          await _openSpellsTab(tester);
          await _cast(tester, 'Ténèbres');
          expect(find.text('Épuisé'), findsOneWidget);

          // Le repos long démarre et reste en vol.
          await _rest(tester, long: true);
          expect(repository.restTypes, [RestType.long]);

          // Le lancer est mis en file pendant le repos.
          repository.innateGate!.complete();
          await tester.pumpAndSettle();
          expect(find.text(_offlineQueuedMessage), findsOneWidget);

          // Puis le repos échoue à son tour.
          repository.restGate!.complete();
          await tester.pumpAndSettle();
          await showNextSnackBar(tester);
          expect(find.text('Repos impossible.'), findsOneWidget);

          expect(repository.innateCalls, hasLength(1));
          await _openSpellsTab(tester);
          expect(
            find.text('Épuisé'),
            findsOneWidget,
            reason:
                'le lancer mis en file n\'a jamais été annulé : '
                'l\'instantané restauré par l\'échec du repos le porte '
                'encore',
          );
        },
      );

      testWidgets('repos long SUCCÈS encore en vol, le lancer échoue, puis '
          'le repos réussit : la ligne reste « disponible »', (tester) async {
        final repository = await _pumpDetail(tester, _detail());
        repository
          ..innateGate = Completer<void>()
          ..innateError = const CharacterFailure('Accès refusé.')
          ..restGate = Completer<void>();
        await _openSpellsTab(tester);
        await _cast(tester, 'Ténèbres');

        await _rest(tester, long: true);
        repository.innateGate!.complete();
        await tester.pumpAndSettle();
        repository.restGate!.complete();
        await tester.pumpAndSettle();

        expect(repository.current.spells.first.innateUsesSpent, 0);
        await _openSpellsTab(tester);
        expect(find.text('Épuisé'), findsNothing);
      });

      testWidgets('repos long EN ÉCHEC (surcouche rétablie) puis échec du '
          'lancer : la ligne revient à « disponible »', (tester) async {
        final repository = await castThenRest(
          tester,
          long: true,
          innateError: const CharacterFailure('Accès refusé.'),
          restError: const CharacterFailure('Repos impossible.'),
        );

        await expectAvailableAgain(tester, repository, 'Accès refusé.');
      });
    });
  });
}
