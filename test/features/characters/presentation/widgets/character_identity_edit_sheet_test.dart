import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/alignment_option.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_identity_edit_sheet.dart';

/// Faux dépôt minimal : seul `updateIdentity` est utilisé par la feuille ;
/// tout autre appel échoue bruyamment via `noSuchMethod`.
class _FakeRepository implements CharacterRepository {
  Map<String, Object?>? lastIdentity;

  @override
  Future<WriteOutcome> updateIdentity({
    required String characterId,
    required String name,
    int? alignmentId,
    String? sexe,
    String? age,
    String? height,
    String? weight,
    String? eyes,
    String? skin,
    String? hair,
    String? appearanceText,
    String? traitsText,
    String? idealsText,
    String? bondsText,
    String? flawsText,
    String? backstoryText,
    String? alliesText,
    String? featuresText,
    String? treasureText,
  }) async {
    lastIdentity = {
      'name': name,
      'alignmentId': alignmentId,
      'sexe': sexe,
      'age': age,
      'hair': hair,
      'backstoryText': backstoryText,
      'treasureText': treasureText,
    };
    return WriteOutcome.synced;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _detail = CharacterDetail(
  id: 'c1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  subraceName: null,
  backgroundName: null,
  alignmentName: 'Neutre bon',
  classes: [],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: {},
  sexe: 'Femme',
  age: '120 ans',
  backstoryText: 'Née sous les étoiles.',
);

const _alignments = AlignmentCatalog(
  alignments: [
    AlignmentOption(id: 1, name: 'Loyal bon'),
    AlignmentOption(id: 2, name: 'Neutre bon'),
  ],
);

Future<_FakeRepository> _pumpAndOpen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = _FakeRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(repository),
        characterDetailProvider('c1').overrideWith((ref) async => _detail),
        alignmentCatalogProvider.overrideWith((ref) async => _alignments),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCharacterIdentityEditSheet(
                  context,
                  characterId: 'c1',
                  detail: _detail,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return repository;
}

Finder _fieldWithText(String text) => find.widgetWithText(TextFormField, text);

void main() {
  testWidgets('préremplit le nom, l\'alignement, l\'identité et l\'histoire', (
    tester,
  ) async {
    await _pumpAndOpen(tester);

    expect(find.text('MODIFIER LE PERSONNAGE'), findsOneWidget);
    expect(_fieldWithText('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Neutre bon'), findsOneWidget);
    expect(_fieldWithText('Femme'), findsOneWidget);
    expect(_fieldWithText('120 ans'), findsOneWidget);
    expect(_fieldWithText('Née sous les étoiles.'), findsOneWidget);
    expect(find.text('Changer le portrait'), findsOneWidget);
  });

  testWidgets('enregistrer écrit les valeurs modifiées (champ vidé -> null) '
      'et ferme la feuille', (tester) async {
    final repository = await _pumpAndOpen(tester);

    await tester.enterText(
      _fieldWithText('Halltesse Ambrelune'),
      ' Halltesse ',
    );
    await tester.enterText(_fieldWithText('120 ans'), '   ');
    await tester.enterText(_fieldWithText('Femme'), 'Non précisé');
    await tester.pump();

    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(repository.lastIdentity, {
      'name': 'Halltesse',
      'alignmentId': 2,
      'sexe': 'Non précisé',
      'age': null,
      'hair': null,
      'backstoryText': 'Née sous les étoiles.',
      'treasureText': null,
    });
    expect(find.text('MODIFIER LE PERSONNAGE'), findsNothing);
    expect(find.text('Personnage mis à jour.'), findsOneWidget);
  });

  testWidgets('un nom vide bloque l\'enregistrement', (tester) async {
    final repository = await _pumpAndOpen(tester);

    await tester.enterText(_fieldWithText('Halltesse Ambrelune'), '  ');
    await tester.pump();

    expect(find.text('Le nom est obligatoire.'), findsOneWidget);
    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
    expect(repository.lastIdentity, isNull);
  });
}
