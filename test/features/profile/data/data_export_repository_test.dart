// Tests de `LocalFileDataExportRepository.exportMyData`
// (`features/profile/data/data_export_repository.dart`) : assemble le JSON
// attendu depuis un `CharacterRepository` factice (`fetchCharacters` +
// `fetchCharacterDetail`), écrit un fichier dans le répertoire temporaire
// (`path_provider`, remplacé ici par un `PathProviderPlatform` factice, même
// principe que les autres plugins mockés de ce dépôt — jamais un vrai accès
// disque piloté par le canal de plateforme réel, indisponible dans `flutter
// test`), et propage telle quelle toute exception du repository sous-jacent.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/profile/data/data_export_repository.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

/// Double minimal — seuls `fetchCharacters`/`fetchCharacterDetail` sont
/// exercés par `DataExportRepository`, le reste lève
/// `UnimplementedError` (jamais atteint par ces tests).
class _FakeCharacterRepository implements CharacterRepository {
  List<CharacterSummary> summaries = const [];
  final Map<String, CharacterDetail> detailsById = {};
  Object? detailErrorToThrow;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => summaries;

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    final error = detailErrorToThrow;
    if (error != null) throw error;
    final detail = detailsById[characterId];
    if (detail == null) {
      throw const CharacterFailure('Personnage introuvable.');
    }
    return detail;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('nexus-jdr-export-test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  CharacterDetail buildDetail({required String id, required String name}) {
    return CharacterDetail(
      id: id,
      name: name,
      xp: 120,
      currentHp: 9,
      maxHp: 12,
      temporaryHp: 0,
      abilityScores: const {'str': 14, 'dex': 12},
      classes: [
        CharacterDetailClassRow(
          classId: 3,
          className: 'Guerrier',
          level: 2,
          isPrimary: true,
          savingThrowProficiencies: const ['str', 'con'],
          hitDie: 10,
        ),
      ],
      inventory: [
        const CharacterInventoryItem(
          id: 'inv-1',
          itemId: 42,
          name: 'Épée longue',
          category: 'arme',
          quantity: 1,
          equipped: true,
          totalWeight: 1.5,
        ),
      ],
      appearanceText: 'Grand et mince.',
    );
  }

  group('LocalFileDataExportRepository.exportMyData', () {
    test('assemble un JSON avec `exportedAt` et un personnage par entrée de '
        '`fetchCharacters`, écrit dans le répertoire temporaire', () async {
      final characterRepository = _FakeCharacterRepository()
        ..summaries = [
          const CharacterSummary(
            id: 'char-1',
            name: 'Aranea',
            level: 2,
            xp: 120,
          ),
        ]
        ..detailsById['char-1'] = buildDetail(id: 'char-1', name: 'Aranea');
      final repository = LocalFileDataExportRepository(characterRepository);

      final path = await repository.exportMyData();

      expect(path, startsWith(tempDir.path));
      final file = File(path);
      expect(file.existsSync(), isTrue);

      final payload =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(payload['exportedAt'], isA<String>());
      expect(DateTime.tryParse(payload['exportedAt'] as String), isNotNull);

      final characters = payload['characters'] as List<dynamic>;
      expect(characters, hasLength(1));
      final character = characters.single as Map<String, dynamic>;
      expect(character['id'], 'char-1');
      expect(character['name'], 'Aranea');
      expect(character['xp'], 120);
      expect(character['currentHp'], 9);
      expect(character['maxHp'], 12);
      expect(
        (character['story'] as Map<String, dynamic>)['appearanceText'],
        'Grand et mince.',
      );
      final classes = character['classes'] as List<dynamic>;
      expect((classes.single as Map<String, dynamic>)['className'], 'Guerrier');
      final inventory = character['inventory'] as List<dynamic>;
      expect((inventory.single as Map<String, dynamic>)['name'], 'Épée longue');
    });

    test('plusieurs personnages : un élément de `characters` par personnage, '
        'dans l\'ordre de `fetchCharacters`', () async {
      final characterRepository = _FakeCharacterRepository()
        ..summaries = [
          const CharacterSummary(
            id: 'char-1',
            name: 'Aranea',
            level: 2,
            xp: 120,
          ),
          const CharacterSummary(
            id: 'char-2',
            name: 'Borin',
            level: 4,
            xp: 900,
          ),
        ]
        ..detailsById['char-1'] = buildDetail(id: 'char-1', name: 'Aranea')
        ..detailsById['char-2'] = buildDetail(id: 'char-2', name: 'Borin');
      final repository = LocalFileDataExportRepository(characterRepository);

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final characters = payload['characters'] as List<dynamic>;

      expect(characters, hasLength(2));
      expect((characters[0] as Map<String, dynamic>)['id'], 'char-1');
      expect((characters[1] as Map<String, dynamic>)['id'], 'char-2');
    });

    test(
      'aucun personnage : `characters` vide, fichier tout de même généré',
      () async {
        final characterRepository = _FakeCharacterRepository()..summaries = [];
        final repository = LocalFileDataExportRepository(characterRepository);

        final path = await repository.exportMyData();
        final payload =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

        expect(payload['characters'], isEmpty);
      },
    );

    test('propage telle quelle une exception levée par '
        '`fetchCharacterDetail` (ex. `CharacterFailure`)', () async {
      final characterRepository = _FakeCharacterRepository()
        ..summaries = [
          const CharacterSummary(
            id: 'char-1',
            name: 'Aranea',
            level: 2,
            xp: 120,
          ),
        ]
        ..detailErrorToThrow = const CharacterFailure('Erreur serveur.');
      final repository = LocalFileDataExportRepository(characterRepository);

      await expectLater(
        repository.exportMyData(),
        throwsA(isA<CharacterFailure>()),
      );
    });
  });
}
