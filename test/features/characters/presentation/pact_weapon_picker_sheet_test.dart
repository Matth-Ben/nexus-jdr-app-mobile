// Tests de widget de la feuille « FORME DE L'ARME »
// (`presentation/widgets/pact_weapon_picker_sheet.dart`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/data/pact_weapon_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/pact_weapon_option.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/pact_weapon_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/pact_weapon_picker_sheet.dart';

class _FakePactWeaponRepository implements PactWeaponRepository {
  _FakePactWeaponRepository({this.options = const [], this.failures = 0});

  final List<PactWeaponOption> options;

  /// Nombre d'appels à faire échouer avant de répondre normalement.
  int failures;
  int fetchCount = 0;
  Completer<void>? gate;

  @override
  Future<List<PactWeaponOption>> fetchEligibleWeapons() async {
    fetchCount++;
    await gate?.future;
    if (failures > 0) {
      failures--;
      throw const CharacterFailure('boom');
    }
    return options;
  }

  @override
  Future<WriteOutcome> setPactWeapon({
    required String characterId,
    required int itemId,
  }) => throw UnimplementedError('la feuille ne doit jamais écrire');
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
  properties: ['finesse', 'légère', 'lancer'],
);
const _shortSword = PactWeaponOption(
  id: 3,
  name: 'Épée courte',
  damageDice: '1d6',
  damageType: 'perforant',
);

/// Ouvre la feuille depuis un bouton ; le résultat (arme choisie ou `null`)
/// est stocké dans [result].
class _Harness {
  bool completed = false;
  PactWeaponOption? result;
}

Future<_Harness> _open(
  WidgetTester tester,
  _FakePactWeaponRepository repository, {
  int? currentWeaponId,
}) async {
  final harness = _Harness();
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [pactWeaponRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                harness.result = await showPactWeaponPickerSheet(
                  context,
                  currentWeaponId: currentWeaponId,
                );
                harness.completed = true;
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  testWidgets('titre, recherche, liste triée sans accents ni casse avec '
      'sous-titres', (tester) async {
    await _open(
      tester,
      _FakePactWeaponRepository(options: [_rapier, _shortSword, _dagger]),
    );

    expect(find.text("FORME DE L'ARME"), findsOneWidget);
    expect(find.text('Rechercher une arme...'), findsOneWidget);
    expect(find.text('1d8 perforant · finesse'), findsOneWidget);
    expect(find.text('1d6 perforant'), findsOneWidget);
    expect(
      find.text('1d4 perforant · finesse, légère, lancer'),
      findsOneWidget,
    );

    final dague = tester.getTopLeft(find.text('Dague')).dy;
    final epee = tester.getTopLeft(find.text('Épée courte')).dy;
    final rapiere = tester.getTopLeft(find.text('Rapière')).dy;
    expect(dague, lessThan(epee));
    expect(epee, lessThan(rapiere));
  });

  testWidgets(
    'un tap ferme la feuille et retourne l\'arme, sans confirmation',
    (tester) async {
      final harness = await _open(
        tester,
        _FakePactWeaponRepository(options: [_rapier, _dagger]),
      );

      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();

      expect(find.text("FORME DE L'ARME"), findsNothing);
      expect(harness.completed, isTrue);
      expect(harness.result, _dagger);
    },
  );

  testWidgets('la forme courante est marquée sélectionnée (sémantique)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(
      tester,
      _FakePactWeaponRepository(options: [_rapier, _dagger]),
      currentWeaponId: 1,
    );

    expect(
      tester.getSemantics(find.text('Rapière')),
      matchesSemantics(
        isSelected: true,
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        label: 'Rapière\n1d8 perforant · finesse',
      ),
    );
    handle.dispose();
  });

  testWidgets('retaper la forme courante ferme en renvoyant la même arme', (
    tester,
  ) async {
    final harness = await _open(
      tester,
      _FakePactWeaponRepository(options: [_rapier, _dagger]),
      currentWeaponId: 1,
    );

    await tester.tap(find.text('Rapière'));
    await tester.pumpAndSettle();

    expect(harness.result, _rapier);
  });

  testWidgets('recherche sans accents ni casse ; aucun résultat', (
    tester,
  ) async {
    await _open(
      tester,
      _FakePactWeaponRepository(options: [_rapier, _dagger, _shortSword]),
    );

    await tester.enterText(find.byType(TextFormField), 'EPEE');
    await tester.pump();
    expect(find.text('Épée courte'), findsOneWidget);
    expect(find.text('Dague'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'zzz');
    await tester.pump();
    expect(find.text('Aucune arme trouvée.'), findsOneWidget);
  });

  testWidgets('liste vide : « Aucune arme disponible. »', (tester) async {
    await _open(tester, _FakePactWeaponRepository());

    expect(find.text('Aucune arme disponible.'), findsOneWidget);
  });

  testWidgets('chargement : indicateur de progression', (tester) async {
    final repository = _FakePactWeaponRepository(options: [_rapier])
      ..gate = Completer<void>();
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pactWeaponRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPactWeaponPickerSheet(context),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Rapière'), findsOneWidget);
  });

  testWidgets('erreur : message et « Réessayer » relance le chargement', (
    tester,
  ) async {
    final repository = _FakePactWeaponRepository(
      options: [_rapier],
      failures: 1,
    );
    await _open(tester, repository);

    expect(
      find.text('Impossible de charger les armes. Réessayez.'),
      findsOneWidget,
    );
    expect(repository.fetchCount, 1);

    await tester.tap(find.widgetWithText(SecondaryButton, 'RÉESSAYER'));
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 2);
    expect(find.text('Rapière'), findsOneWidget);
  });

  testWidgets('fermer sans choisir retourne null', (tester) async {
    final harness = await _open(
      tester,
      _FakePactWeaponRepository(options: [_rapier]),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(harness.completed, isTrue);
    expect(harness.result, isNull);
  });
}
