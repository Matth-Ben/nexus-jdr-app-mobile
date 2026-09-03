// Tests du préchargeur des catalogues de référence de l'assistant de
// création (character_creation_catalog_preloader.dart) — chantier de
// performance perçue (TTL + préchargement, voir la doc de classe de
// `CharacterCreationCatalogPreloader`).
//
// `authStateStreamProvider` (`features/auth/presentation/providers/
// auth_providers.dart`, voir la doc de classe d'`AuthStateStream` pour le
// rationale de cette abstraction plutôt qu'`authStateChangesProvider`) est
// overridé avec un double minimal exposant un `StreamController<AuthState>`
// piloté manuellement, plutôt qu'un vrai `SupabaseClient` — même principe
// que `character_write_sync_coordinator_test.dart` pour
// `connectivityCheckerProvider`. `_FakeCharacterCreationRepository`
// (calqué sur celui de `race_step_screen_test.dart`) compte les appels à
// chacun des 8 catalogues non paramétrés préchargés, et peut être configuré
// pour faire échouer l'un d'entre eux sans jamais lever d'exception non
// gérée dans le test lui-même (le préchargeur doit rester silencieux, voir
// sa doc de classe).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/auth/data/auth_state_stream.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
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
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_catalog_preloader.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('CharacterCreationCatalogPreloader', () {
    late _FakeCharacterCreationRepository fakeRepository;
    late StreamController<AuthState> authStateController;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = _FakeCharacterCreationRepository();
      authStateController = StreamController<AuthState>.broadcast();
      container = ProviderContainer(
        overrides: [
          characterCreationRepositoryProvider.overrideWithValue(fakeRepository),
          authStateStreamProvider.overrideWithValue(
            _FakeAuthStateStream(authStateController.stream),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(authStateController.close);
    });

    test('reprise de session existante au lancement (initialSession avec '
        'session) déclenche le préchargement des 8 catalogues non '
        'paramétrés, jamais fetchSpellCatalog', () async {
      container.read(characterCreationCatalogPreloaderProvider);
      authStateController.add(
        AuthState(AuthChangeEvent.initialSession, _fakeSession()),
      );
      await pumpEventQueue();

      expect(fakeRepository.raceCatalogCallCount, 1);
      expect(fakeRepository.classCatalogCallCount, 1);
      expect(fakeRepository.backgroundCatalogCallCount, 1);
      expect(fakeRepository.toolCatalogCallCount, 1);
      expect(fakeRepository.languageCatalogCallCount, 1);
      expect(fakeRepository.itemCatalogCallCount, 1);
      expect(fakeRepository.skillCatalogCallCount, 1);
      expect(fakeRepository.alignmentCatalogCallCount, 1);
      expect(
        fakeRepository.spellCatalogCallCount,
        0,
        reason:
            'fetchSpellCatalog est paramétré par classId : aucune classe '
            "par défaut n'a de sens à précharger avant l'étape 2/9, voir "
            'la doc de classe du préchargeur.',
      );
    });

    test(
      'connexion réussie (signedIn) déclenche aussi le préchargement',
      () async {
        container.read(characterCreationCatalogPreloaderProvider);
        authStateController.add(
          AuthState(AuthChangeEvent.signedIn, _fakeSession()),
        );
        await pumpEventQueue();

        expect(fakeRepository.raceCatalogCallCount, 1);
        expect(fakeRepository.alignmentCatalogCallCount, 1);
      },
    );

    test('initialSession sans session (utilisateur non connecté au '
        'lancement) ne déclenche aucun préchargement', () async {
      container.read(characterCreationCatalogPreloaderProvider);
      authStateController.add(
        const AuthState(AuthChangeEvent.initialSession, null),
      );
      await pumpEventQueue();

      expect(fakeRepository.raceCatalogCallCount, 0);
    });

    test('un événement qui n\'est ni signedIn ni initialSession-avec-session '
        '(ex. tokenRefreshed) ne redéclenche pas de préchargement', () async {
      container.read(characterCreationCatalogPreloaderProvider);
      authStateController.add(
        AuthState(AuthChangeEvent.initialSession, _fakeSession()),
      );
      await pumpEventQueue();
      expect(fakeRepository.raceCatalogCallCount, 1);

      authStateController.add(
        AuthState(AuthChangeEvent.tokenRefreshed, _fakeSession()),
      );
      await pumpEventQueue();

      expect(
        fakeRepository.raceCatalogCallCount,
        1,
        reason:
            'seuls signedIn et initialSession (avec session) doivent '
            'déclencher un préchargement, pas chaque événement portant '
            'une session (ex. rafraîchissement de token).',
      );
    });

    test('un catalogue en échec (réseau ET cache) n\'empêche jamais les '
        'autres de se précharger, et ne remonte aucune exception', () async {
      fakeRepository.classCatalogErrorToThrow = Exception(
        'échec simulé (double de test)',
      );

      container.read(characterCreationCatalogPreloaderProvider);
      authStateController.add(
        AuthState(AuthChangeEvent.signedIn, _fakeSession()),
      );
      // N'échoue jamais avec une exception non gérée si le préchargeur
      // reste bien silencieux (voir _safeFetch) : le simple fait que ce
      // pumpEventQueue() se termine sans lever prouve déjà l'essentiel.
      await pumpEventQueue();

      expect(fakeRepository.classCatalogCallCount, 1);
      expect(
        fakeRepository.raceCatalogCallCount,
        1,
        reason:
            'fetchClassCatalog en échec ne doit pas empêcher les autres '
            'catalogues (ici fetchRaceCatalog) de se précharger.',
      );
      expect(fakeRepository.alignmentCatalogCallCount, 1);
    });

    test('dispose() annule l\'abonnement : plus aucun préchargement '
        'déclenché après', () async {
      final preloader = container.read(
        characterCreationCatalogPreloaderProvider,
      );

      preloader.dispose();
      authStateController.add(
        AuthState(AuthChangeEvent.signedIn, _fakeSession()),
      );
      await pumpEventQueue();

      expect(
        fakeRepository.raceCatalogCallCount,
        0,
        reason:
            'dispose() doit annuler l\'abonnement à authStateChanges : '
            'un événement signedIn émis après ne doit plus jamais '
            'déclencher de préchargement.',
      );
    });
  });
}

Session _fakeSession() {
  return Session(
    accessToken: 'fake-access-token',
    tokenType: 'bearer',
    user: User(
      id: 'fake-user-id',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  );
}

/// Double minimal d'`AuthStateStream` — expose tel quel le `Stream<AuthState>`
/// d'un `StreamController` piloté par le test, jamais `Supabase.instance
/// .client`.
class _FakeAuthStateStream implements AuthStateStream {
  const _FakeAuthStateStream(this.onAuthStateChange);

  @override
  final Stream<AuthState> onAuthStateChange;
}

/// Double minimal de `CharacterCreationRepository` — compte les appels à
/// chacun des 8 catalogues non paramétrés préchargés (voir la doc de classe
/// de `CharacterCreationCatalogPreloader`), plus `fetchSpellCatalog` (jamais
/// censé être appelé par ce préchargeur, voir les tests ci-dessus).
/// `createCharacter` n'est jamais exercé par ces tests.
class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  int raceCatalogCallCount = 0;
  int classCatalogCallCount = 0;
  int backgroundCatalogCallCount = 0;
  int toolCatalogCallCount = 0;
  int languageCatalogCallCount = 0;
  int spellCatalogCallCount = 0;
  int itemCatalogCallCount = 0;
  int skillCatalogCallCount = 0;
  int alignmentCatalogCallCount = 0;

  Object? classCatalogErrorToThrow;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async {
    raceCatalogCallCount++;
    return const RaceCatalog(races: [], subraces: []);
  }

  @override
  Future<ClassCatalog> fetchClassCatalog() async {
    classCatalogCallCount++;
    final error = classCatalogErrorToThrow;
    if (error != null) {
      throw error;
    }
    return const ClassCatalog(classes: []);
  }

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async {
    backgroundCatalogCallCount++;
    return const BackgroundCatalog(backgrounds: []);
  }

  @override
  Future<ToolCatalog> fetchToolCatalog() async {
    toolCatalogCallCount++;
    return const ToolCatalog(tools: []);
  }

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async {
    languageCatalogCallCount++;
    return const LanguageCatalog(languages: []);
  }

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async {
    spellCatalogCallCount++;
    return const SpellCatalog(spells: []);
  }

  @override
  Future<ItemCatalog> fetchItemCatalog() async {
    itemCatalogCallCount++;
    return const ItemCatalog(items: []);
  }

  @override
  Future<SkillCatalog> fetchSkillCatalog() async {
    skillCatalogCallCount++;
    return const SkillCatalog(skills: []);
  }

  @override
  Future<AlignmentCatalog> fetchAlignmentCatalog() async {
    alignmentCatalogCallCount++;
    return const AlignmentCatalog(alignments: []);
  }

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
