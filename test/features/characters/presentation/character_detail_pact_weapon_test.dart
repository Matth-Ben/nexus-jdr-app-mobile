// Tests de câblage de la carte « Arme de pacte » côté
// `character_detail_screen.dart` : ouverture de la feuille, upsert via
// `PactWeaponRepository`, rafraîchissement, messages, verrou pendant
// l'écriture.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pact_weapon_repository.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/pact_weapon_option.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/providers/pact_weapon_providers.dart';

/// Seules `fetchCharacters`/`fetchCharacterDetail` sont utilisées ici ; toute
/// autre méthode échoue bruyamment via `noSuchMethod`.
class _FakeCharacterRepository implements CharacterRepository {
  _FakeCharacterRepository(this.current);

  CharacterDetail current;
  int fetchCount = 0;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    fetchCount++;
    return current;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

const _rapier = PactWeaponOption(
  id: 1,
  name: 'Rapière',
  damageDice: '1d8',
  damageType: 'perforant',
  properties: ['finesse'],
);
const _dagger = PactWeaponOption(
  id: 2,
  name: 'Dague',
  damageDice: '1d4',
  damageType: 'perforant',
  properties: ['finesse', 'légère'],
);

class _FakePactWeaponRepository implements PactWeaponRepository {
  final List<(String, int)> setCalls = [];
  WriteOutcome outcome = WriteOutcome.synced;
  Object? error;
  Completer<void>? gate;

  /// Appelé à l'écriture : simule le serveur qui mémorise la nouvelle forme.
  void Function(int itemId)? onWrite;

  @override
  Future<List<PactWeaponOption>> fetchEligibleWeapons() async => [
    _rapier,
    _dagger,
  ];

  @override
  Future<WriteOutcome> setPactWeapon({
    required String characterId,
    required int itemId,
  }) async {
    setCalls.add((characterId, itemId));
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    if (outcome == WriteOutcome.synced) onWrite?.call(itemId);
    return outcome;
  }
}

CharacterDetail _warlock({PactWeaponOption? pactWeapon}) => CharacterDetail(
  id: '1',
  name: 'Sylas',
  classes: const [
    CharacterDetailClassRow(
      classId: 1,
      className: 'Occultiste',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
      hitDie: 8,
    ),
  ],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: const {},
  classChoices: const [
    CharacterClassChoice(featureName: 'Faveur de pacte', chosenValue: 'lame'),
  ],
  pactWeapon: pactWeapon,
);

Future<(_FakeCharacterRepository, _FakePactWeaponRepository)> _pump(
  WidgetTester tester, {
  PactWeaponOption? initial,
}) async {
  final characters = _FakeCharacterRepository(_warlock(pactWeapon: initial));
  final pact = _FakePactWeaponRepository();
  pact.onWrite = (itemId) => characters.current = _warlock(
    pactWeapon: itemId == 1 ? _rapier : _dagger,
  );
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(characters),
        pactWeaponRepositoryProvider.overrideWithValue(pact),
      ],
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
  // La carte « Arme de pacte » est désormais sur l'onglet « Personnage »
  // (par défaut), plus besoin de naviguer vers l'onglet « Inventaire ».
  return (characters, pact);
}

void main() {
  testWidgets('choisir une forme : upsert, rafraîchissement, snackbar', (
    tester,
  ) async {
    final (characters, pact) = await _pump(tester);
    expect(find.text('Aucune forme choisie'), findsOneWidget);
    final fetchesBefore = characters.fetchCount;

    await tester.tap(find.text('Choisir une forme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dague'));
    await tester.pumpAndSettle();

    expect(pact.setCalls, [('1', 2)]);
    expect(characters.fetchCount, greaterThan(fetchesBefore));
    expect(find.text("Forme de l'arme de pacte : Dague."), findsOneWidget);
    expect(find.text('1d4 perforant'), findsOneWidget);
    expect(find.text('Changer de forme'), findsOneWidget);
  });

  testWidgets('taper la forme déjà choisie : aucune écriture', (tester) async {
    final (_, pact) = await _pump(tester, initial: _rapier);

    await tester.tap(find.text('Changer de forme'));
    await tester.pumpAndSettle();
    // La ligne de la feuille porte le même nom que la carte : cibler la feuille.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Rapière'),
      ),
    );
    await tester.pumpAndSettle();

    expect(pact.setCalls, isEmpty);
    expect(find.textContaining("Forme de l'arme de pacte"), findsNothing);
  });

  testWidgets('fermer la feuille sans choisir : aucune écriture', (
    tester,
  ) async {
    final (_, pact) = await _pump(tester);

    await tester.tap(find.text('Choisir une forme'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(pact.setCalls, isEmpty);
  });

  testWidgets('hors ligne (queued) : message dédié, pas de rafraîchissement', (
    tester,
  ) async {
    final (characters, pact) = await _pump(tester);
    pact.outcome = WriteOutcome.queued;
    final fetchesBefore = characters.fetchCount;

    await tester.tap(find.text('Choisir une forme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dague'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
        'fois reconnecté.',
      ),
      findsOneWidget,
    );
    expect(characters.fetchCount, fetchesBefore);
    expect(find.text('Aucune forme choisie'), findsOneWidget);
  });

  testWidgets('échec typé : message de la CharacterFailure', (tester) async {
    final (_, pact) = await _pump(tester);
    pact.error = const CharacterFailure('Accès refusé.');

    await tester.tap(find.text('Choisir une forme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dague'));
    await tester.pumpAndSettle();

    expect(find.text('Accès refusé.'), findsOneWidget);
  });

  testWidgets('échec inattendu : message générique', (tester) async {
    final (_, pact) = await _pump(tester);
    pact.error = Exception('boom');

    await tester.tap(find.text('Choisir une forme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dague'));
    await tester.pumpAndSettle();

    expect(
      find.text("Impossible de changer la forme de l'arme. Réessayez."),
      findsOneWidget,
    );
  });

  testWidgets('pendant l\'écriture : bouton verrouillé, puis rendu', (
    tester,
  ) async {
    final (_, pact) = await _pump(tester);
    pact.gate = Completer<void>();

    await tester.tap(find.text('Choisir une forme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dague'));
    await tester.pump();
    await tester.pump();

    final lockedOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Choisir une forme'),
        matching: find.byType(Opacity),
      ),
    );
    expect(lockedOpacity.opacity, 0.6);

    pact.gate!.complete();
    await tester.pumpAndSettle();

    final unlocked = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Changer de forme'),
        matching: find.byType(Opacity),
      ),
    );
    expect(unlocked.opacity, 1);
  });
}
