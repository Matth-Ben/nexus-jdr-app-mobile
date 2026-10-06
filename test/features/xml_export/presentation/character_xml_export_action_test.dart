// Tests de widget du point d'entrée "Exporter en XML" de la fiche
// personnage (bouton `WoodBackHeader.trailing` de l'onglet "Personnage",
// `character_detail_screen.dart`).
//
// `Share.shareXFiles` (package `share_plus`) et `path_provider` sont mockés
// exactement comme `export_data_sheet_test.dart`/
// `data_export_repository_test.dart` — jamais un vrai canal de plateforme ni
// un vrai accès disque réel en test (le fichier temporaire lui-même reste un
// vrai fichier, mais dans un répertoire de test jetable, voir [tempDir]).
//
// `exportCharacterAsXml` écrit un vrai fichier via `dart:io` (contrairement
// à `showExportDataSheet`, dont le dépôt est entièrement factice dans ses
// propres tests) : les taps qui déclenchent réellement la génération
// (mono-classe, "Exporter quand même") doivent passer par
// `tester.runAsync` pour laisser cette vraie E/S disque se terminer — le
// bac à sable temporel de `testWidgets` ne fait autrement jamais progresser
// une opération asynchrone adossée au vrai event loop (contrairement à un
// simple `Future`/`Timer` piloté par l'horloge factice de
// `TestWidgetsFlutterBinding`), ce qui laisserait `shareCalls` vide sans
// jamais lever d'exception (piège rencontré et diagnostiqué pendant
// l'écriture de ce fichier).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

/// Double minimal — seul `fetchCharacterDetail` est exercé par ces tests
/// (voir `providers/character_detail_provider.dart`), le reste lève
/// `UnimplementedError` (jamais atteint : ces tests n'interagissent avec
/// aucun autre onglet/aucune autre écriture).
class _FakeCharacterRepository implements CharacterRepository {
  CharacterDetail? detailToReturn;

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    return detailToReturn!;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _monoClasseDetail = CharacterDetail(
  id: '1',
  name: 'Thoradin Forgefer',
  raceName: 'Nain',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: 'Guerrier',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: ['str', 'con'],
      hitDie: 10,
    ),
  ],
  xp: 6500,
  currentHp: 30,
  maxHp: 44,
  temporaryHp: 0,
  abilityScores: {
    'str': 16,
    'dex': 12,
    'con': 14,
    'int': 10,
    'wis': 11,
    'cha': 8,
  },
);

const _multiclasseDetail = CharacterDetail(
  id: '2',
  name: 'Rix',
  raceName: 'Humain',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: 'Guerrier',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: ['str', 'con'],
      hitDie: 10,
    ),
    CharacterDetailClassRow(
      classId: 2,
      className: 'Roublard',
      level: 2,
      isPrimary: false,
      savingThrowProficiencies: [],
      hitDie: 8,
    ),
  ],
  xp: 2700,
  currentHp: 20,
  maxHp: 28,
  temporaryHp: 0,
  abilityScores: {
    'str': 10,
    'dex': 16,
    'con': 12,
    'int': 12,
    'wis': 10,
    'cha': 14,
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCharacterRepository fakeRepository;
  late Directory tempDir;
  final shareCalls = <MethodCall>[];

  // Invoqué par le faux canal `share_plus` à chaque appel reçu : c'est
  // l'événement qui marque la fin de l'export (voir [awaitShareCall]).
  void Function()? onShareCall;

  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        shareCalls.add(call);
        onShareCall?.call();
        if (call.method == 'share') return '';
        return null;
      });

  setUp(() {
    fakeRepository = _FakeCharacterRepository();
    tempDir = Directory.systemTemp.createTempSync('nexus-jdr-xml-export-test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    shareCalls.clear();
    onShareCall = null;
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Widget buildTestWidget(String characterId) {
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/characters/$characterId',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Liste'))),
            ),
            GoRoute(
              path: '/characters/:id',
              builder: (context, state) => CharacterDetailScreen(
                characterId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pumpDetail(WidgetTester tester, String characterId) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestWidget(characterId));
    await tester.pumpAndSettle();
  }

  // Borne haute de l'attente de l'appel au partage. Volontairement très
  // large : ce n'est pas une estimation du temps d'écriture, seulement un
  // garde-fou pour qu'une régression (partage jamais demandé) échoue avec un
  // message clair plutôt que de bloquer jusqu'au timeout global du test.
  const shareCallTimeout = Duration(seconds: 10);

  /// Exécute [trigger] (les taps qui lancent l'export) puis attend que
  /// `exportCharacterAsXml` ait réellement demandé le partage — à appeler
  /// **dans** `tester.runAsync`.
  ///
  /// Entre le tap et cet appel, la production écrit un vrai fichier
  /// (`File.writeAsString`, E/S disque réelle de durée non bornée, hors de
  /// l'horloge simulée) puis appelle `SharePlus.instance.share`, dernière
  /// étape de l'export : le fichier est donc entièrement écrit quand le faux
  /// canal reçoit l'appel. Une attente à durée fixe (historiquement 200 ms
  /// d'horloge réelle) était une course contre cette écriture ; on attend
  /// l'événement lui-même, signalé par `onShareCall`.
  ///
  /// Le `Completer` est créé ici, donc dans la zone réelle de `runAsync`, et
  /// non dans le corps du test : un `Future` prévient ses auditeurs via la
  /// zone où il a été créé, et celle du test (horloge simulée) est à
  /// l'arrêt pendant `runAsync` — l'attente expirerait alors même si le
  /// partage a bien été demandé.
  Future<void> awaitShareCall(Future<void> Function() trigger) async {
    final shared = Completer<void>();
    onShareCall = () {
      if (!shared.isCompleted) shared.complete();
    };

    await trigger();
    await shared.future.timeout(
      shareCallTimeout,
      onTimeout: () => fail(
        "Le partage (share_plus) n'a pas été demandé dans les "
        "${shareCallTimeout.inSeconds} s suivant le tap d'export (écriture "
        'du fichier XML jamais aboutie ?).',
      ),
    );
    // Un tour de boucle d'événements : vide la file de microtâches, donc la
    // fin de `exportCharacterAsXml` après la réponse du faux canal. Ce n'est
    // pas une attente temporelle.
    await Future<void>.delayed(Duration.zero);
  }

  /// Ouvre le menu "…" du bandeau bois ET tape "Exporter en XML" dans le
  /// **même** `runAsync` (voir la note d'en-tête de fichier sur l'affinité
  /// de zone) : déclenche une vraie écriture disque, personnage
  /// mono-classe (aucun avertissement intermédiaire).
  Future<void> openHeaderMenuAndExport(WidgetTester tester) async {
    await tester.runAsync(() async {
      await awaitShareCall(() async {
        await tester.tap(find.byTooltip('Plus d\'options'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Exporter en XML'));
      });
    });
    await tester.pumpAndSettle();
  }

  /// Ouvre le menu "…" du bandeau bois de l'onglet "Personnage" (recettage
  /// direction-artistique du 13/09 : "Exporter en XML" y a été relogé
  /// depuis sa propre icône, voir `character_detail_screen.dart`).
  Future<void> openCharacterHeaderMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Plus d\'options'));
    await tester.pumpAndSettle();
  }

  /// Ouvre le dialogue d'avertissement multiclassage puis confirme
  /// ("Exporter quand même") — les **deux** taps doivent être émis dans le
  /// **même** `tester.runAsync` (et donc dans le même `Future`
  /// `exportCharacterAsXml`, invoqué pour la première fois directement
  /// depuis l'intérieur de ce bloc) : `Future.then`/`await` conservent
  /// l'affinité de zone de leur point d'enregistrement, pas celle de la
  /// zone qui déclenche leur achèvement (voir `dart:async` — un objet
  /// `Zone`). Si le premier tap (celui qui ouvre le dialogue et lance
  /// `exportCharacterAsXml`) était émis hors de `runAsync` (zone "temps
  /// factice" par défaut de `testWidgets`), toute la suite de cette
  /// fonction — y compris l'E/S disque réelle après confirmation —
  /// resterait liée à cette zone factice et ne progresserait jamais dans la
  /// fenêtre réelle ouverte par un `runAsync` ultérieur : le fichier
  /// finirait par s'écrire bien après la fin du test (constaté par un
  /// verrou de fichier au moment du nettoyage), jamais avant l'assertion —
  /// piège rencontré et diagnostiqué pendant l'écriture de ce fichier.
  Future<void> openMulticlassDialogAndConfirm(WidgetTester tester) async {
    await tester.runAsync(() async {
      await awaitShareCall(() async {
        await openCharacterHeaderMenu(tester);
        await tester.tap(find.text('Exporter en XML'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('EXPORTER QUAND MÊME'));
      });
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'onglet "Personnage" : entrée "Exporter en XML" présente dans le menu '
    '"…" du bandeau',
    (tester) async {
      fakeRepository.detailToReturn = _monoClasseDetail;
      await pumpDetail(tester, '1');

      await openCharacterHeaderMenu(tester);

      expect(find.text('Exporter en XML'), findsOneWidget);
    },
  );

  testWidgets(
    'personnage mono-classe : tap déclenche directement la génération puis '
    'le partage, sans avertissement',
    (tester) async {
      fakeRepository.detailToReturn = _monoClasseDetail;
      await pumpDetail(tester, '1');

      await openHeaderMenuAndExport(tester);

      expect(find.text('Personnage multiclassé'), findsNothing);
      expect(shareCalls, hasLength(1));
      expect(shareCalls.single.method, 'share');

      final sharedPaths = (shareCalls.single.arguments as Map)['paths'] as List;
      expect(sharedPaths, hasLength(1));
      final sharedFile = File(sharedPaths.single as String);
      expect(sharedFile.existsSync(), isTrue);
      expect(sharedFile.path, endsWith('Thoradin_Forgefer.xml'));
      expect(sharedFile.readAsStringSync(), contains('<builder>'));
      expect(
        sharedFile.readAsStringSync(),
        contains('<class>Guerrier</class>'),
      );
    },
  );

  testWidgets('personnage multiclassé : avertissement avant export, "Annuler" '
      'n\'exporte rien', (tester) async {
    fakeRepository.detailToReturn = _multiclasseDetail;
    await pumpDetail(tester, '2');

    // Le dialogue d'avertissement lui-même ne touche pas au disque —
    // pas besoin de `runAsync` pour cette étape.
    await openCharacterHeaderMenu(tester);
    await tester.tap(find.text('Exporter en XML'));
    await tester.pumpAndSettle();

    expect(find.text('Personnage multiclassé'), findsOneWidget);
    expect(
      find.textContaining("qu'une seule classe par personnage"),
      findsOneWidget,
    );

    // `SecondaryButton`/`PrimaryButton` mettent leur libellé en majuscules
    // à l'affichage (`label.toUpperCase()`), même convention que
    // `export_data_sheet_test.dart`.
    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(find.text('Personnage multiclassé'), findsNothing);
    expect(shareCalls, isEmpty);
  });

  testWidgets(
    'personnage multiclassé : "Exporter quand même" exporte seulement la '
    'classe primaire',
    (tester) async {
      fakeRepository.detailToReturn = _multiclasseDetail;
      await pumpDetail(tester, '2');

      await openMulticlassDialogAndConfirm(tester);

      expect(find.text('Personnage multiclassé'), findsNothing);
      expect(shareCalls, hasLength(1));

      final sharedPaths = (shareCalls.single.arguments as Map)['paths'] as List;
      final content = File(sharedPaths.single as String).readAsStringSync();
      expect(content, contains('<class>Guerrier</class>'));
      expect(content, isNot(contains('Roublard')));
    },
  );
}
