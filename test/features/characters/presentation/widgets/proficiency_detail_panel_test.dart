// Tests de widget du panneau "Infos" d'un token de maîtrise
// (`presentation/widgets/proficiency_detail_panel.dart`) — même patron que
// `pact_weapon_picker_sheet_test.dart` : `ProviderScope` avec
// `proficiencyCatalogRepositoryProvider` surchargé par un double de test.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/data/proficiency_catalog_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/proficiency_catalog.dart';
import 'package:personnages/features/characters/domain/proficiency_token_resolver.dart';
import 'package:personnages/features/characters/presentation/providers/proficiency_catalog_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/proficiency_detail_panel.dart';

class _FakeProficiencyCatalogRepository
    implements ProficiencyCatalogRepository {
  _FakeProficiencyCatalogRepository({
    this.catalog = const ProficiencyCatalog(),
    this.failures = 0,
  });

  final ProficiencyCatalog catalog;
  int failures;
  int fetchCount = 0;
  Completer<void>? gate;

  @override
  Future<ProficiencyCatalog> fetchCatalog() async {
    fetchCount++;
    await gate?.future;
    if (failures > 0) {
      failures--;
      throw const CharacterFailure('boom');
    }
    return catalog;
  }
}

const _dagger = ProficiencyCatalogWeapon(
  id: 1,
  name: 'Dague',
  damageDice: '1d4',
  damageType: 'perforant',
  properties: ['finesse', 'légère', 'lancer'],
);
const _longSword = ProficiencyCatalogWeapon(
  id: 2,
  name: 'Épée longue',
  damageDice: '1d8',
  damageType: 'tranchant',
);
const _net = ProficiencyCatalogWeapon(id: 3, name: 'Filet');

const _leatherArmor = ProficiencyCatalogArmor(
  id: 10,
  name: 'Armure de cuir',
  category: 'armure',
  acBase: 11,
  acDexBonus: 'illimite',
);
const _plateArmor = ProficiencyCatalogArmor(
  id: 11,
  name: 'Harnois',
  category: 'armure',
  acBase: 18,
  acDexBonus: 'aucun',
  strengthRequirement: 15,
  stealthDisadvantage: true,
);
const _shield = ProficiencyCatalogArmor(
  id: 20,
  name: 'Bouclier',
  category: 'bouclier',
  acBase: 2,
  acDexBonus: 'aucun',
);

Future<void> _open(
  WidgetTester tester,
  _FakeProficiencyCatalogRepository repository, {
  required String token,
  required ProficiencyTokenKind kind,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proficiencyCatalogRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showProficiencyDetailPanel(context, token: token, kind: kind),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("'martiales' : titre, dé/type/propriétés d'une arme", (
    tester,
  ) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(weapons: [_longSword]),
      ),
      token: 'martiales',
      kind: ProficiencyTokenKind.weapon,
    );

    expect(find.text('ARMES DE GUERRE'), findsOneWidget);
    expect(find.text('Épée longue'), findsOneWidget);
    expect(find.text('1d8'), findsOneWidget);
    expect(find.text('tranchant'), findsOneWidget);
  });

  testWidgets("'courantes' : une arme avec propriétés affiche la ligne "
      '« Propriétés : »', (tester) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(weapons: [_dagger]),
      ),
      token: 'courantes',
      kind: ProficiencyTokenKind.weapon,
    );

    expect(find.text('ARMES COURANTES'), findsOneWidget);
    expect(find.text('Dague'), findsOneWidget);
    expect(find.textContaining('finesse, légère, lancer'), findsOneWidget);
  });

  testWidgets('une arme sans dé de dégâts (Filet) : aucun badge de dé, pas '
      'de crash', (tester) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(weapons: [_net]),
      ),
      token: 'Filet',
      kind: ProficiencyTokenKind.weapon,
    );

    expect(find.text('Filet'), findsOneWidget);
  });

  testWidgets("'légère' : gabarit armure complet (CA de base/Bonus Dex)", (
    tester,
  ) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(armors: [_leatherArmor]),
      ),
      token: 'légère',
      kind: ProficiencyTokenKind.armor,
    );

    expect(find.text('ARMURES LÉGÈRES'), findsOneWidget);
    expect(find.text('Armure de cuir'), findsOneWidget);
    expect(find.text('CA de base'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('Bonus Dex'), findsOneWidget);
    expect(find.text('Illimité'), findsOneWidget);
    // Pas de force requise ni désavantage pour cette armure.
    expect(find.text('Force requise'), findsNothing);
    expect(find.text('Désavantage discrétion'), findsNothing);
  });

  testWidgets("'lourde' : force requise et désavantage discrétion affichés "
      'quand renseignés', (tester) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(armors: [_plateArmor]),
      ),
      token: 'lourde',
      kind: ProficiencyTokenKind.armor,
    );

    expect(find.text('ARMURES LOURDES'), findsOneWidget);
    expect(find.text('Force requise'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Désavantage discrétion'), findsOneWidget);
    expect(find.text('Oui'), findsOneWidget);
  });

  testWidgets("'boucliers' : gabarit réduit, une ligne « CA » -> « +2 »", (
    tester,
  ) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(shields: [_shield]),
      ),
      token: 'boucliers',
      kind: ProficiencyTokenKind.armor,
    );

    expect(find.text('BOUCLIERS'), findsOneWidget);
    expect(find.text('Bouclier'), findsOneWidget);
    expect(find.text('CA'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    // Jamais le gabarit complet d'armure pour un bouclier.
    expect(find.text('CA de base'), findsNothing);
  });

  testWidgets("'boucliers (non métalliques)' : état liste vide dédié", (
    tester,
  ) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(shields: [_shield]),
      ),
      token: 'boucliers (non métalliques)',
      kind: ProficiencyTokenKind.armor,
    );

    expect(
      find.text(
        'Aucun bouclier non métallique disponible dans le catalogue '
        'actuel.',
      ),
      findsOneWidget,
    );
    expect(find.text('BOUCLIERS (NON MÉTALLIQUES)'), findsOneWidget);
  });

  testWidgets("'dagues' : titre en repli token.toUpperCase()", (tester) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(weapons: [_dagger]),
      ),
      token: 'dagues',
      kind: ProficiencyTokenKind.weapon,
    );

    expect(find.text('DAGUES'), findsOneWidget);
    expect(find.text('Dague'), findsOneWidget);
  });

  testWidgets('chargement : indicateur de progression', (tester) async {
    final repository = _FakeProficiencyCatalogRepository(
      catalog: const ProficiencyCatalog(weapons: [_dagger]),
    )..gate = Completer<void>();
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proficiencyCatalogRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showProficiencyDetailPanel(
                context,
                token: 'courantes',
                kind: ProficiencyTokenKind.weapon,
              ),
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
    expect(find.text('Dague'), findsOneWidget);
  });

  testWidgets('erreur : message et « Réessayer » relance le chargement', (
    tester,
  ) async {
    final repository = _FakeProficiencyCatalogRepository(
      catalog: const ProficiencyCatalog(weapons: [_dagger]),
      failures: 1,
    );
    await _open(
      tester,
      repository,
      token: 'courantes',
      kind: ProficiencyTokenKind.weapon,
    );

    expect(
      find.text('Impossible de charger le catalogue. Réessayez.'),
      findsOneWidget,
    );
    expect(repository.fetchCount, 1);

    await tester.tap(find.widgetWithText(SecondaryButton, 'RÉESSAYER'));
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 2);
    expect(find.text('Dague'), findsOneWidget);
  });

  testWidgets('fermer via la croix referme le panneau', (tester) async {
    await _open(
      tester,
      _FakeProficiencyCatalogRepository(
        catalog: const ProficiencyCatalog(weapons: [_dagger]),
      ),
      token: 'courantes',
      kind: ProficiencyTokenKind.weapon,
    );

    expect(find.text('ARMES COURANTES'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('ARMES COURANTES'), findsNothing);
  });
}
