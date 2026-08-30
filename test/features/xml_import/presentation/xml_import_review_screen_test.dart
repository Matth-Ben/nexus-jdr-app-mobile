// Tests de widget de l'écran de vérification de l'import XML aidedd.org
// (`XmlImportReviewScreen`) — mêmes principes que
// `character_creation/presentation/summary_step_screen_test.dart` : dépôts
// factices injectés via `overrideWithValue`/`ProviderContainer`, aucun appel
// réseau réel. Couvre les 4 états critiques demandés par la consigne
// d'origine de la tâche : chargement, happy path (0 alerte), alertes
// multiples, erreur (XML invalide).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/alignment_option.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/xml_import/data/xml_import_repository.dart';
import 'package:personnages/features/xml_import/domain/xml_import_save_data.dart';
import 'package:personnages/features/xml_import/presentation/providers/xml_import_providers.dart';
import 'package:personnages/features/xml_import/presentation/xml_import_review_screen.dart';

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

  /// Retarde artificiellement `fetchRaceCatalog` (premier appel du
  /// contrôleur) pour figer l'écran en état "Chargement" le temps du test.
  Completer<RaceCatalog>? raceCatalogCompleter;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async {
    if (raceCatalogCompleter != null) return raceCatalogCompleter!.future;
    return raceCatalogToReturn;
  }

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
    required dynamic draft,
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

class _FakeXmlImportRepository implements XmlImportRepository {
  int saveCallCount = 0;
  XmlImportSaveData? capturedData;
  String? capturedCharacterName;
  Object? errorToThrow;

  @override
  Future<String> saveImportedCharacter({
    required XmlImportSaveData data,
    required String characterName,
  }) async {
    saveCallCount++;
    capturedData = data;
    capturedCharacterName = characterName;
    if (errorToThrow != null) throw errorToThrow!;
    return 'new-character-id';
  }
}

class _FakeCharacterRepository implements CharacterRepository {
  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
  }) {
    throw UnimplementedError();
  }
}

const _elfe = RaceOption(id: 1, name: 'Elfe', abilityBonuses: {}, traits: []);
const _magicien = ClassOption(
  id: 2,
  name: 'Magicien',
  description: '',
  hitDie: 6,
);
const _sage = BackgroundOption(
  id: 3,
  name: 'Sage',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
);
const _neutre = AlignmentOption(id: 4, name: 'Neutre');

/// Export minimal mais valide (`<builder><character>` avec les 4 champs
/// requis par `XmlCharacterImportParser.parse`) — race/classe/historique
/// correspondent aux catalogues factices ci-dessus, armure/bouclier/
/// alignement/sexe portent des identifiants valides ("état vide" légitime ou
/// milieu de table), aucun objet/compétence/sort : aucun champ ne devrait
/// ressortir `unrecognized`.
const _cleanXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test Héros</name>
<race>Elfe</race>
<class>Magicien</class>
<background>Sage</background>
<level>1</level>
<str>10</str><dex>10</dex><con>10</con><int>10</int><wis>10</wis><cha>10</cha>
<armor>0</armor>
<shield>0</shield>
<alignment>4</alignment>
<sexe>0</sexe>
<gp>0</gp><pp>0</pp><ep>0</ep><sp>0</sp><cp>0</cp>
</character>
</builder>
''';

/// Même base que [_cleanXml], mais avec un alignement à un identifiant hors
/// table (`AideddReferenceTables.alignments` ne va que de 0 à 8) et deux
/// objets d'inventaire à des identifiants inconnus de
/// `AideddReferenceTables.items` — déclenche à la fois une alerte simple
/// (Alignement) et une alerte consolidée (Objets, 2 éléments). Race/classe
/// restent reconnues à dessein : ces alertes-ci ne doivent jamais bloquer
/// "Valider le personnage" (voir [_raceAndClassUnresolvedXml] pour le seul
/// cas qui bloque réellement, race/classe).
const _multipleAlertsXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test Héros</name>
<race>Elfe</race>
<class>Magicien</class>
<background>Sage</background>
<level>1</level>
<str>10</str><dex>10</dex><con>10</con><int>10</int><wis>10</wis><cha>10</cha>
<armor>0</armor>
<shield>0</shield>
<alignment>99</alignment>
<sexe>0</sexe>
<item>9001,9002</item>
<itemQ>1,1</itemQ>
<gp>0</gp><pp>0</pp><ep>0</ep><sp>0</sp><cp>0</cp>
</character>
</builder>
''';

/// Même base que [_cleanXml], mais avec une race ET une classe homebrew (non
/// cataloguées) — seul cas qui doit réellement bloquer "Valider le
/// personnage" (voir la doc de
/// `_XmlImportReviewScreenState._handleValidate`).
const _raceAndClassUnresolvedXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test Héros</name>
<race>Race Maison Inventée</race>
<class>Classe Maison Inventée</class>
<background>Sage</background>
<level>1</level>
<str>10</str><dex>10</dex><con>10</con><int>10</int><wis>10</wis><cha>10</cha>
<armor>0</armor>
<shield>0</shield>
<alignment>4</alignment>
<sexe>0</sexe>
<gp>0</gp><pp>0</pp><ep>0</ep><sp>0</sp><cp>0</cp>
</character>
</builder>
''';

/// Même base que [_cleanXml], mais avec un paquetage de départ (`pack`, id
/// 22 = "Pack (a) d'occultiste", table complète depuis l'increment 1), une
/// sous-classe (`classPath`), un style de combat (`styleCombat1`), une
/// invocation connue et une augmentation de caractéristique (`aug_carac0`)
/// — aucun de ces champs n'a de catalogue/table de correspondance fiable
/// (voir la doc de classe de `_buildUnhandledInfoMessage`), ils ne doivent
/// donc jamais compter comme "à corriger" ni disparaître silencieusement.
const _packAndUnhandledFieldsXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<builder>
<character>
<name>Test Héros</name>
<race>Elfe</race>
<class>Magicien</class>
<classPath>Voie Maison</classPath>
<background>Sage</background>
<level>1</level>
<str>10</str><dex>10</dex><con>10</con><int>10</int><wis>10</wis><cha>10</cha>
<lvl lvl="1"><hp_brut>6</hp_brut><aug_carac0>5</aug_carac0><aug_carac1>-1</aug_carac1><aug_carac2>-1</aug_carac2></lvl>
<armor>0</armor>
<shield>0</shield>
<alignment>4</alignment>
<sexe>0</sexe>
<pack>22</pack>
<styleCombat1>11</styleCombat1>
<knownInvocation>Armure d'ombres</knownInvocation>
<gp>0</gp><pp>0</pp><ep>0</ep><sp>0</sp><cp>0</cp>
</character>
</builder>
''';

const _invalidXml = 'ceci n\'est pas du XML';

void main() {
  late _FakeCharacterCreationRepository fakeCharacterCreationRepository;
  late _FakeXmlImportRepository fakeXmlImportRepository;
  late ProviderContainer container;

  setUp(() {
    fakeCharacterCreationRepository = _FakeCharacterCreationRepository()
      ..raceCatalogToReturn = const RaceCatalog(races: [_elfe], subraces: [])
      ..classCatalogToReturn = const ClassCatalog(classes: [_magicien])
      ..backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_sage],
      )
      ..alignmentCatalogToReturn = const AlignmentCatalog(
        alignments: [_neutre],
      );
    fakeXmlImportRepository = _FakeXmlImportRepository();
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(
          fakeCharacterCreationRepository,
        ),
        xmlImportRepositoryProvider.overrideWithValue(fakeXmlImportRepository),
        characterRepositoryProvider.overrideWithValue(
          _FakeCharacterRepository(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  // Surface de test agrandie en hauteur — même rationale que
  // `summary_step_screen_test.dart` : cet écran affiche potentiellement plus
  // de 20 cartes (résumé + alertes), une `ListView` ne construit que les
  // éléments visibles dans le banc de test par défaut (~600 logiques).
  void growTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildTestWidget({
    required String xmlSource,
    String fileName = 'test.xml',
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/import',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Liste'))),
            ),
            GoRoute(
              path: '/import',
              builder: (context, state) => XmlImportReviewScreen(
                fileName: fileName,
                xmlSource: xmlSource,
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets(
    'état "Chargement" : spinner foncé, sous-titre "Analyse en cours"',
    (WidgetTester tester) async {
      fakeCharacterCreationRepository.raceCatalogCompleter = Completer();

      growTestViewport(tester);
      await tester.pumpWidget(buildTestWidget(xmlSource: _cleanXml));
      await tester.pump();

      expect(
        find.textContaining('Analyse de test.xml en cours'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('VALIDER LE PERSONNAGE'), findsNothing);
    },
  );

  testWidgets(
    'happy path (0 alerte) : toutes les cartes en lecture seule, texte '
    'positif, "VALIDER LE PERSONNAGE" toujours actif',
    (WidgetTester tester) async {
      growTestViewport(tester);
      await tester.pumpWidget(buildTestWidget(xmlSource: _cleanXml));
      await tester.pumpAndSettle();

      expect(
        find.text('Tous les champs ont été reconnus automatiquement.'),
        findsOneWidget,
      );
      expect(find.text('Elfe'), findsOneWidget);
      expect(find.text('Magicien'), findsOneWidget);
      expect(find.text('Sage'), findsOneWidget);

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'tap "VALIDER LE PERSONNAGE" (0 alerte) : sauvegarde directe, pas de '
    'dialogue de confirmation',
    (WidgetTester tester) async {
      growTestViewport(tester);
      await tester.pumpWidget(buildTestWidget(xmlSource: _cleanXml));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VALIDER LE PERSONNAGE'));
      await tester.pumpAndSettle();

      expect(fakeXmlImportRepository.saveCallCount, 1);
      expect(fakeXmlImportRepository.capturedCharacterName, 'Test Héros');
      expect(find.text('CHAMPS NON RÉSOLUS'), findsNothing);
    },
  );

  testWidgets(
    'échec de sauvegarde : message d\'erreur affiché, le bouton redevient '
    'actif (pas de spinner figé)',
    (WidgetTester tester) async {
      fakeXmlImportRepository.errorToThrow = const CharacterCreationFailure(
        'Erreur simulée de sauvegarde.',
      );

      await tester.pumpWidget(buildTestWidget(xmlSource: _cleanXml));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VALIDER LE PERSONNAGE'));
      await tester.pumpAndSettle();

      expect(fakeXmlImportRepository.saveCallCount, 1);
      expect(find.text('Erreur simulée de sauvegarde.'), findsOneWidget);

      // Le bouton est repassé à l'état actif (pas `isLoading`) : son
      // libellé redevient visible et son `onPressed` n'est plus `null`.
      expect(find.text('VALIDER LE PERSONNAGE'), findsOneWidget);
      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.isLoading, isFalse);
      expect(button.onPressed, isNotNull);

      // Un nouveau tap, une fois l'erreur levée côté dépôt, doit pouvoir
      // aboutir normalement (le bouton n'est pas resté verrouillé par
      // l'échec précédent).
      fakeXmlImportRepository.errorToThrow = null;
      await tester.tap(find.text('VALIDER LE PERSONNAGE'));
      await tester.pumpAndSettle();

      expect(fakeXmlImportRepository.saveCallCount, 2);
    },
  );

  testWidgets('alertes multiples : carte d\'alerte simple (Alignement) + carte '
      'consolidée (Objets, 2 éléments), texte de statut compte les champs '
      'individuels', (WidgetTester tester) async {
    growTestViewport(tester);
    await tester.pumpWidget(buildTestWidget(xmlSource: _multipleAlertsXml));
    await tester.pumpAndSettle();

    expect(
      find.text('3 champs à vérifier avant l\'enregistrement.'),
      findsOneWidget,
    );
    expect(find.textContaining('Alignement non reconnu'), findsOneWidget);
    expect(
      find.text('2 éléments non catalogués — à corriger manuellement.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'tap "VALIDER LE PERSONNAGE" (≥1 alerte) : ouvre le dialogue "CHAMPS NON '
    'RÉSOLUS" avant toute sauvegarde',
    (WidgetTester tester) async {
      growTestViewport(tester);
      await tester.pumpWidget(buildTestWidget(xmlSource: _multipleAlertsXml));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VALIDER LE PERSONNAGE'));
      await tester.pumpAndSettle();

      expect(find.text('CHAMPS NON RÉSOLUS'), findsOneWidget);
      expect(fakeXmlImportRepository.saveCallCount, 0);

      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();

      expect(fakeXmlImportRepository.saveCallCount, 1);
    },
  );

  testWidgets('dialogue "CHAMPS NON RÉSOLUS" : "RETOURNER CORRIGER" annule la '
      'sauvegarde', (WidgetTester tester) async {
    growTestViewport(tester);
    await tester.pumpWidget(buildTestWidget(xmlSource: _multipleAlertsXml));
    await tester.pumpAndSettle();

    await tester.tap(find.text('VALIDER LE PERSONNAGE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RETOURNER CORRIGER'));
    await tester.pumpAndSettle();

    expect(find.text('CHAMPS NON RÉSOLUS'), findsNothing);
    expect(fakeXmlImportRepository.saveCallCount, 0);
  });

  testWidgets(
    'race et classe non reconnues : tap "VALIDER LE PERSONNAGE" bloque '
    'directement (message, pas de dialogue), aucune sauvegarde tentée',
    (WidgetTester tester) async {
      growTestViewport(tester);
      await tester.pumpWidget(
        buildTestWidget(xmlSource: _raceAndClassUnresolvedXml),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('VALIDER LE PERSONNAGE'));
      await tester.pumpAndSettle();

      expect(find.text('CHAMPS NON RÉSOLUS'), findsNothing);
      expect(fakeXmlImportRepository.saveCallCount, 0);
      expect(
        find.text(
          'Corrigez d\'abord la race et la classe avant d\'enregistrer ce '
          'personnage.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pack affiché en carte lecture seule ; sous-classe/style de combat/'
    'invocation/ASI listés dans une carte informative neutre, jamais '
    'silencieusement perdus, jamais comptés comme "à corriger"',
    (WidgetTester tester) async {
      growTestViewport(tester);
      await tester.pumpWidget(
        buildTestWidget(xmlSource: _packAndUnhandledFieldsXml),
      );
      await tester.pumpAndSettle();

      // Aucun de ces champs n'est compté comme "à corriger" (aucune table
      // fiable, voir la doc de `XmlImportAlertSummary.countUnresolved`) :
      // le texte de statut positif reste affiché malgré leur présence.
      expect(
        find.text('Tous les champs ont été reconnus automatiquement.'),
        findsOneWidget,
      );

      // Paquetage de départ : carte lecture seule, jamais une alerte.
      expect(find.text('Pack (a) d\'occultiste'), findsOneWidget);

      // Carte informative neutre : liste bien les 3 champs réellement
      // présents dans ce fichier (Style de combat, Sous-classe, Invocation
      // connue) mais pas "Ennemi juré" (absent de ce fichier précis), plus
      // la note ASI séparée.
      expect(
        find.textContaining(
          'Non importé automatiquement dans cette version : Style de '
          'combat, Sous-classe, Invocation connue.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Ennemi juré'), findsNothing);
      expect(
        find.textContaining('Augmentations de caractéristiques'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'état "Erreur" (XML invalide) : message dédié, bouton "CHOISIR UN AUTRE '
    'FICHIER", pas de liste de cartes ni de bouton primaire',
    (WidgetTester tester) async {
      growTestViewport(tester);
      await tester.pumpWidget(buildTestWidget(xmlSource: _invalidXml));
      await tester.pumpAndSettle();

      expect(
        find.text('Ce fichier ne semble pas être un export aidedd.org valide.'),
        findsOneWidget,
      );
      expect(find.textContaining('échec de l\'analyse'), findsOneWidget);
      expect(find.text('CHOISIR UN AUTRE FICHIER'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsNothing);
    },
  );
}
