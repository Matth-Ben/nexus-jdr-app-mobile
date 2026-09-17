// Tests unitaires des méthodes `keepXxxAsPlaceholder` de
// `XmlImportReviewController`, directement via `ProviderContainer` (pas
// besoin de monter l'écran, contrairement à
// `xml_import_review_screen_test.dart` qui couvre plutôt le câblage UI —
// badge affiché, SnackBar d'erreur — sur ces mêmes méthodes).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/xml_import/data/xml_import_placeholder_catalog_repository.dart';
import 'package:personnages/features/xml_import/domain/xml_field_resolution.dart';
import 'package:personnages/features/xml_import/presentation/providers/xml_import_providers.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  RaceCatalog raceCatalogToReturn = const RaceCatalog(races: [], subraces: []);
  ClassCatalog classCatalogToReturn = const ClassCatalog(classes: []);
  BackgroundCatalog backgroundCatalogToReturn = const BackgroundCatalog(
    backgrounds: [],
  );
  ToolCatalog toolCatalogToReturn = const ToolCatalog(tools: []);
  LanguageCatalog languageCatalogToReturn = const LanguageCatalog(
    languages: [],
  );
  SpellCatalog spellCatalogToReturn = const SpellCatalog(spells: []);
  ItemCatalog itemCatalogToReturn = const ItemCatalog(items: []);
  SkillCatalog skillCatalogToReturn = const SkillCatalog(skills: []);
  AlignmentCatalog alignmentCatalogToReturn = const AlignmentCatalog(
    alignments: [],
  );

  @override
  Future<RaceCatalog> fetchRaceCatalog() async => raceCatalogToReturn;

  @override
  Future<ClassCatalog> fetchClassCatalog() async => classCatalogToReturn;

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async =>
      backgroundCatalogToReturn;

  @override
  Future<ToolCatalog> fetchToolCatalog() async => toolCatalogToReturn;

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async =>
      languageCatalogToReturn;

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async =>
      spellCatalogToReturn;

  @override
  Future<ItemCatalog> fetchItemCatalog() async => itemCatalogToReturn;

  @override
  Future<SkillCatalog> fetchSkillCatalog() async => skillCatalogToReturn;

  @override
  Future<AlignmentCatalog> fetchAlignmentCatalog() async =>
      alignmentCatalogToReturn;

  @override
  Future<String> createCharacter({
    required CharacterCreationDraft draft,
    required String characterName,
    required RaceCatalog raceCatalog,
    required ClassOption classOption,
    required BackgroundOption backgroundOption,
    required SkillCatalog skillCatalog,
    required ToolCatalog toolCatalog,
    required LanguageCatalog languageCatalog,
    required SpellCatalog spellCatalog,
    required ItemCatalog itemCatalog,
  }) {
    throw UnimplementedError();
  }
}

class _FakePlaceholderCatalogRepository
    implements XmlImportPlaceholderCatalogRepository {
  int findOrCreateRaceCallCount = 0;
  int findOrCreateBackgroundCallCount = 0;
  int findOrCreateSpellCallCount = 0;
  String? lastRawName;
  Object? errorToThrow;

  @override
  Future<RaceOption> findOrCreateRace(String rawName) async {
    findOrCreateRaceCallCount++;
    lastRawName = rawName;
    if (errorToThrow != null) throw errorToThrow!;
    return RaceOption(
      id: 901,
      name: rawName,
      abilityBonuses: const {},
      traits: const [],
      isIncomplete: true,
    );
  }

  @override
  Future<BackgroundOption> findOrCreateBackground(String rawName) async {
    findOrCreateBackgroundCallCount++;
    lastRawName = rawName;
    if (errorToThrow != null) throw errorToThrow!;
    return BackgroundOption(
      id: 902,
      name: rawName,
      skillProficiencies: const [],
      featureName: '',
      featureDescription: '',
      isIncomplete: true,
    );
  }

  @override
  Future<SpellOption> findOrCreateSpell(String rawName) async {
    findOrCreateSpellCallCount++;
    lastRawName = rawName;
    if (errorToThrow != null) throw errorToThrow!;
    return SpellOption(
      id: 903,
      name: rawName,
      level: 0,
      school: '',
      castingTime: '',
      isIncomplete: true,
    );
  }
}

/// Race/classe/historique homebrew (aucun ne correspond aux catalogues
/// factices, tous vides ci-dessous), deux sorts innés/connus eux aussi
/// homebrew — de quoi exercer les 4 méthodes `keepXxxAsPlaceholder` sur un
/// seul et même parse.
const _xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test Héros</name>
<race>Race Maison</race>
<class>Classe Maison</class>
<background>Historique Maison</background>
<level>1</level>
<str>10</str><dex>10</dex><con>10</con><int>10</int><wis>10</wis><cha>10</cha>
<armor>0</armor>
<shield>0</shield>
<alignment>0</alignment>
<sexe>0</sexe>
<innateSpell lvl="0">Sort inné maison</innateSpell>
<knownSpell lvl="1">Sort connu maison</knownSpell>
<gp>0</gp><pp>0</pp><ep>0</ep><sp>0</sp><cp>0</cp>
</character>
</builder>
''';

void main() {
  late _FakeCharacterCreationRepository fakeCharacterCreationRepository;
  late _FakePlaceholderCatalogRepository fakePlaceholderRepository;
  late ProviderContainer container;
  late XmlImportReviewControllerProvider provider;

  setUp(() {
    fakeCharacterCreationRepository = _FakeCharacterCreationRepository();
    fakePlaceholderRepository = _FakePlaceholderCatalogRepository();
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(
          fakeCharacterCreationRepository,
        ),
        xmlImportPlaceholderCatalogRepositoryProvider.overrideWithValue(
          fakePlaceholderRepository,
        ),
      ],
    );
    provider = xmlImportReviewControllerProvider(
      fileName: 'test.xml',
      xmlSource: _xml,
    );
  });

  tearDown(() => container.dispose());

  test(
    'keepRaceAsPlaceholder : race non reconnue -> appelle findOrCreateRace, '
    'résout race vers XmlFieldResolution.recognized(nouvelle entrée)',
    () async {
      await container.read(provider.future);
      expect(
        container.read(provider).value!.resolved.race.isUnrecognized,
        isTrue,
      );

      await container
          .read(provider.notifier)
          .keepRaceAsPlaceholder('Race Maison');

      expect(fakePlaceholderRepository.findOrCreateRaceCallCount, 1);
      expect(fakePlaceholderRepository.lastRawName, 'Race Maison');
      final race = container.read(provider).value!.resolved.race;
      expect(race, isA<XmlFieldResolutionRecognized<RaceOption>>());
      final option = (race as XmlFieldResolutionRecognized<RaceOption>).value;
      expect(option.id, 901);
      expect(option.name, 'Race Maison');
      expect(option.isIncomplete, isTrue);
    },
  );

  test(
    'keepBackgroundAsPlaceholder : historique non reconnu -> appelle '
    'findOrCreateBackground, résout background vers la nouvelle entrée',
    () async {
      await container.read(provider.future);

      await container
          .read(provider.notifier)
          .keepBackgroundAsPlaceholder('Historique Maison');

      expect(fakePlaceholderRepository.findOrCreateBackgroundCallCount, 1);
      final background = container.read(provider).value!.resolved.background;
      expect(background, isA<XmlFieldResolutionRecognized<BackgroundOption>>());
      final option =
          (background as XmlFieldResolutionRecognized<BackgroundOption>).value;
      expect(option.id, 902);
      expect(option.isIncomplete, isTrue);
    },
  );

  test('keepInnateSpellAsPlaceholder : résout uniquement l\'entrée [index] de '
      'innateSpells, laisse les autres champs intacts', () async {
    await container.read(provider.future);

    await container
        .read(provider.notifier)
        .keepInnateSpellAsPlaceholder(0, 'Sort inné maison');

    expect(fakePlaceholderRepository.findOrCreateSpellCallCount, 1);
    final entry = container.read(provider).value!.resolved.innateSpells[0];
    expect(entry.resolution, isA<XmlFieldResolutionRecognized<SpellOption>>());
    final option =
        (entry.resolution as XmlFieldResolutionRecognized<SpellOption>).value;
    expect(option.id, 903);
    expect(option.isIncomplete, isTrue);
    // knownSpells n'a pas été touché par cet appel.
    expect(
      container
          .read(provider)
          .value!
          .resolved
          .knownSpells[0]
          .resolution
          .isUnrecognized,
      isTrue,
    );
  });

  test('keepKnownSpellAsPlaceholder : résout uniquement l\'entrée [index] de '
      'knownSpells', () async {
    await container.read(provider.future);

    await container
        .read(provider.notifier)
        .keepKnownSpellAsPlaceholder(0, 'Sort connu maison');

    final entry = container.read(provider).value!.resolved.knownSpells[0];
    expect(entry.resolution, isA<XmlFieldResolutionRecognized<SpellOption>>());
  });

  test('échec réseau (findOrCreateRace) : l\'exception se propage, l\'état '
      'reste inchangé (race toujours unrecognized)', () async {
    fakePlaceholderRepository.errorToThrow = Exception('boom');
    await container.read(provider.future);

    await expectLater(
      container.read(provider.notifier).keepRaceAsPlaceholder('Race Maison'),
      throwsA(isA<Exception>()),
    );

    expect(
      container.read(provider).value!.resolved.race.isUnrecognized,
      isTrue,
    );
  });
}
