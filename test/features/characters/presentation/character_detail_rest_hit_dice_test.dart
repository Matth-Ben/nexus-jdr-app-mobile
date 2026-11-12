// Tests de la fiche personnage pour les dés de vie au repos (F13/F14 du
// registre `docs/retours-utilisateurs.md`).
//
// F13 : un repos long ouvert juste après un repos court recevait des pools de
// dés de vie PÉRIMÉS (la fiche n'était pas encore relue) : le payload
// `hitDiceRecoveredByClassId` partait vide et le serveur n'écrivait rien. Le
// correctif fait attendre le refetch à `_applyRest` et verrouille le bouton
// « Repos » pendant ce temps.
//
// F14 : retour sur les dés récupérés au repos long + messages localisés.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

CharacterDetail _fighter({required int level, int spent = 0}) =>
    CharacterDetail(
      id: '1',
      name: 'Test',
      classes: [
        CharacterDetailClassRow(
          classId: 1,
          hitDie: 8,
          className: 'Guerrier',
          level: level,
          isPrimary: true,
          savingThrowProficiencies: const [],
          hitDiceSpent: spent,
        ),
      ],
      xp: 0,
      currentHp: 18,
      maxHp: 30,
      temporaryHp: 0,
      abilityScores: const {},
    );

class _LongRestCall {
  _LongRestCall(this.recovered, this.serverSpentBefore);
  final Map<String, int> recovered;
  final int serverSpentBefore;
}

/// Seules les méthodes utiles sont implémentées ; le reste échoue via
/// `noSuchMethod`.
class _FakeRepository implements CharacterRepository {
  _FakeRepository(this.current);

  CharacterDetail current;

  /// Non nul : toute lecture de fiche attend ce `Completer` (refetch retardé).
  Completer<void>? fetchGate;

  /// Non nul : `applyRest` lève cette erreur.
  Object? applyRestError;

  final List<_LongRestCall> longRestCalls = [];

  int get spent => current.classes.single.hitDiceSpent;

  void _setSpent(int value) {
    final row = current.classes.single;
    current = current.copyWith(
      classes: [
        CharacterDetailClassRow(
          classId: row.classId,
          hitDie: row.hitDie,
          className: row.className,
          level: row.level,
          isPrimary: row.isPrimary,
          savingThrowProficiencies: row.savingThrowProficiencies,
          hitDiceSpent: value,
        ),
      ],
    );
  }

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    final gate = fetchGate;
    final snapshot = current;
    if (gate != null) await gate.future;
    return snapshot;
  }

  @override
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    Map<String, int> hitDiceSpentByClassId = const {},
    int appliedGain = 0,
    Map<String, int> hitDiceRecoveredByClassId = const {},
  }) async {
    final error = applyRestError;
    if (error != null) throw error;
    if (type == RestType.long) {
      longRestCalls.add(_LongRestCall(hitDiceRecoveredByClassId, spent));
      final recovered = hitDiceRecoveredByClassId.values.fold(
        0,
        (a, b) => a + b,
      );
      _setSpent((spent - recovered).clamp(0, 99));
      current = current.copyWith(currentHp: current.maxHp);
    } else {
      final dice = hitDiceSpentByClassId.values.fold(0, (a, b) => a + b);
      _setSpent(spent + dice);
      current = current.copyWith(
        currentHp: (current.currentHp + appliedGain).clamp(0, current.maxHp),
      );
    }
    return WriteOutcome.synced;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<void> _pump(
  WidgetTester tester,
  _FakeRepository repository, {
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
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
}

/// Libellés de la feuille « Repos », par locale.
class _Labels {
  const _Labels(this.rest, this.short, this.apply, this.average);
  final String rest;
  final String short;
  final String apply;
  final String average;
}

const _fr = _Labels('REPOS', 'REPOS COURT', 'APPLIQUER', 'VALEUR MOYENNE');
const _en = _Labels('REST', 'SHORT REST', 'APPLY', 'AVERAGE VALUE');

Future<void> _openRest(WidgetTester tester, _Labels l) async {
  await tester.tap(find.text(l.rest));
  await tester.pumpAndSettle();
}

/// Repos court dépensant [dice] dés (valeur moyenne, déterministe).
Future<void> _shortRest(WidgetTester tester, _Labels l, int dice) async {
  await _openRest(tester, l);
  await tester.tap(find.text(l.short));
  await tester.pumpAndSettle();
  for (var i = 0; i < dice; i++) {
    await tester.tap(find.bySemanticsLabel(RegExp('Augmenter|Increase')));
    await tester.pumpAndSettle();
  }
  if (dice > 0) {
    await tester.tap(find.text(l.average));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(l.apply));
  await tester.pumpAndSettle();
}

Future<void> _longRest(WidgetTester tester, _Labels l) async {
  await _openRest(tester, l);
  await tester.tap(find.text(l.apply));
  await tester.pumpAndSettle();
}

void main() {
  group('F13 : repos long enchaîné après un repos court', () {
    testWidgets(
      'refetch retardé : aucun repos long ne part avec des pools périmés',
      (tester) async {
        final repo = _FakeRepository(_fighter(level: 4));
        await _pump(tester, repo);

        repo.fetchGate = Completer<void>();
        await _shortRest(tester, _fr, 2);
        // Le serveur a bien reçu la dépense, la fiche affichée est périmée.
        expect(repo.spent, 2);

        // Tentative d'ouvrir un repos long pendant le refetch.
        await tester.tap(find.text('REPOS'), warnIfMissed: false);
        await tester.pumpAndSettle();
        if (find.text('APPLIQUER').evaluate().isNotEmpty) {
          await tester.tap(find.text('APPLIQUER'));
          await tester.pumpAndSettle();
        }

        repo.fetchGate!.complete();
        await tester.pumpAndSettle();

        for (final call in repo.longRestCalls) {
          final recovered = call.recovered.values.fold(0, (a, b) => a + b);
          expect(
            recovered,
            call.serverSpentBefore.clamp(0, 2),
            reason:
                'Repos long calculé sur des pools périmés : '
                '${call.recovered} alors que ${call.serverSpentBefore} dés '
                'étaient dépensés côté serveur.',
          );
        }
      },
    );

    testWidgets(
      'repos court (3 dés) puis long : hit_dice_spent final = max(0, N - '
      'max(1, niveau ~/ 2))',
      (tester) async {
        final repo = _FakeRepository(_fighter(level: 4));
        await _pump(tester, repo);

        repo.fetchGate = Completer<void>();
        await _shortRest(tester, _fr, 3);
        repo.fetchGate!.complete();
        await tester.pumpAndSettle();
        repo.fetchGate = null;
        expect(repo.spent, 3);

        await _longRest(tester, _fr);

        expect(repo.longRestCalls.single.recovered, {'1': 2});
        expect(repo.spent, 1); // max(0, 3 - max(1, 4 ~/ 2))
      },
    );

    testWidgets('le bouton Repos est verrouillé pendant le refetch', (
      tester,
    ) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo);

      repo.fetchGate = Completer<void>();
      await _shortRest(tester, _fr, 1);

      Finder restButton() =>
          find.ancestor(of: find.text('REPOS'), matching: find.byType(InkWell));
      expect(
        tester.widget<InkWell>(restButton().first).onTap,
        isNull,
        reason:
            'Le bouton Repos doit être inactif tant que la fiche est '
            'en cours de relecture.',
      );

      repo.fetchGate!.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<InkWell>(restButton().first).onTap, isNotNull);
    });
  });

  group('F14 : messages de repos', () {
    testWidgets('repos long FR, 2 dés récupérés (pluriel)', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4, spent: 3));
      await _pump(tester, repo);
      await _longRest(tester, _fr);
      expect(
        find.text(
          'Repos long effectué. PV restaurés au maximum. '
          '+2 dés de vie récupérés.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('repos long FR, 1 dé récupéré (singulier)', (tester) async {
      final repo = _FakeRepository(_fighter(level: 3, spent: 3));
      await _pump(tester, repo);
      await _longRest(tester, _fr);
      expect(
        find.text(
          'Repos long effectué. PV restaurés au maximum. '
          '+1 dé de vie récupéré.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('repos long FR sans dé dépensé : phrase omise', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo);
      await _longRest(tester, _fr);
      expect(
        find.text('Repos long effectué. PV restaurés au maximum.'),
        findsOneWidget,
      );
    });

    testWidgets('repos long EN, 2 dés récupérés', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4, spent: 3));
      await _pump(tester, repo, locale: const Locale('en'));
      await _longRest(tester, _en);
      expect(
        find.text(
          'Long rest complete. HP restored to maximum. '
          '+2 hit dice recovered.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('repos long EN, 1 dé récupéré', (tester) async {
      final repo = _FakeRepository(_fighter(level: 3, spent: 1));
      await _pump(tester, repo, locale: const Locale('en'));
      await _longRest(tester, _en);
      expect(
        find.text(
          'Long rest complete. HP restored to maximum. '
          '+1 hit die recovered.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('repos long EN sans dé dépensé : phrase omise', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo, locale: const Locale('en'));
      await _longRest(tester, _en);
      expect(
        find.text('Long rest complete. HP restored to maximum.'),
        findsOneWidget,
      );
    });

    testWidgets('repos court FR : 1 dé dépensé', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo);
      await _shortRest(tester, _fr, 1);
      expect(
        find.text('Repos court effectué. +5 PV (1 dé de vie dépensé).'),
        findsOneWidget,
      );
    });

    testWidgets('repos court FR : 2 dés dépensés', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo);
      await _shortRest(tester, _fr, 2);
      expect(
        find.text('Repos court effectué. +10 PV (2 dés de vie dépensés).'),
        findsOneWidget,
      );
    });

    testWidgets('repos court EN : 2 dés dépensés', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo, locale: const Locale('en'));
      await _shortRest(tester, _en, 2);
      expect(
        find.text('Short rest complete. +10 HP (2 hit dice spent).'),
        findsOneWidget,
      );
    });

    testWidgets('repos court EN : 1 dé dépensé', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo, locale: const Locale('en'));
      await _shortRest(tester, _en, 1);
      expect(
        find.text('Short rest complete. +5 HP (1 hit die spent).'),
        findsOneWidget,
      );
    });

    testWidgets('repos court sans dé FR', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo);
      await _shortRest(tester, _fr, 0);
      expect(find.text('Repos court effectué.'), findsOneWidget);
    });

    testWidgets('repos court sans dé EN', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4));
      await _pump(tester, repo, locale: const Locale('en'));
      await _shortRest(tester, _en, 0);
      expect(find.text('Short rest complete.'), findsOneWidget);
    });

    testWidgets('erreur générique localisée FR', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4))
        ..applyRestError = Exception('boom');
      await _pump(tester, repo);
      await _longRest(tester, _fr);
      expect(
        find.text("Impossible d'effectuer le repos. Réessayez."),
        findsOneWidget,
      );
    });

    testWidgets('erreur générique localisée EN', (tester) async {
      final repo = _FakeRepository(_fighter(level: 4))
        ..applyRestError = Exception('boom');
      await _pump(tester, repo, locale: const Locale('en'));
      await _longRest(tester, _en);
      expect(
        find.text('Unable to complete the rest. Please try again.'),
        findsOneWidget,
      );
    });
  });

  test('aucun texte français en dur dans _applyRest', () {
    final source = File(
      'lib/features/characters/presentation/character_detail_screen.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    final start = source.indexOf('Future<bool> _applyRest(');
    final end = source.indexOf('Future<void> _applyRestFromSheet(');
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));
    final body = source
        .substring(start, end)
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
    final literals = RegExp('(?:\'[^\'\\n]*\'|"[^"\\n]*")')
        .allMatches(body)
        .map((m) => m.group(0)!);
    final french = RegExp('[éèêàçùûôî]|Repos|Impossible|dépensé|effectué');
    expect(
      literals.where(french.hasMatch).toList(),
      isEmpty,
      reason: 'Texte utilisateur à passer par AppLocalizations.',
    );
  });
}
