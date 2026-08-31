// Tests du coordinateur de synchro hors-ligne PV/XP
// (character_write_sync_coordinator.dart).
//
// Contrairement au reste des tests de ce depot, on ne passe pas par un
// double de CharacterRepository complet pour verifier l'invalidation :
// characterDetailProvider delegue directement a characterRepositoryProvider,
// donc un simple double de repository suffit a observer si
// characterDetailProvider(characterId) a ete re-resolu apres invalidation
// (le compteur d'appels de fetchCharacterDetail augmente).
//
// PendingCharacterWriteSyncer n'est pas une abstraction (classe concrete,
// jamais une interface -- voir sa documentation de classe : volontairement
// gardee hors de CharacterRepository) : le double utilise ici est un
// sous-type qui override sync() sans jamais appeler le reseau reel, avec un
// SupabaseClient/PendingCharacterWriteQueue factices jamais utilises (le
// super() les exige, mais sync() override ne les touche jamais).

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/providers/character_write_sync_coordinator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('CharacterWriteSyncCoordinator', () {
    late _FakeCharacterRepository fakeRepository;
    late _ScriptedSyncer fakeSyncer;
    late _FakeConnectivityChecker fakeConnectivity;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = _FakeCharacterRepository();
      fakeSyncer = _ScriptedSyncer();
      fakeConnectivity = _FakeConnectivityChecker();
      container = ProviderContainer(
        overrides: [
          characterRepositoryProvider.overrideWithValue(fakeRepository),
          pendingCharacterWriteSyncerProvider.overrideWithValue(fakeSyncer),
          connectivityCheckerProvider.overrideWithValue(fakeConnectivity),
        ],
      );
      addTearDown(container.dispose);
    });

    test(
      'synchro de demarrage : sync() est appele une fois des que le '
      'coordinateur est instancie (avant tout retour de connectivite)',
      () async {
        fakeSyncer.resultToReturn = const {};

        container.read(characterWriteSyncCoordinatorProvider);
        await pumpEventQueue();

        expect(fakeSyncer.callCount, 1);
      },
    );

    test('un characterId synchronise avec succes invalide '
        'characterDetailProvider(characterId), qui se re-resout ensuite avec '
        'la donnee serveur fraiche', () async {
      const characterId = 'char-1';
      fakeRepository.detailToReturn = _detailWithHp(18);
      fakeSyncer.resultToReturn = const {};

      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();

      final values = <AsyncValue<CharacterDetail>>[];
      container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(characterId),
        (previous, next) => values.add(next),
        fireImmediately: true,
      );
      await pumpEventQueue();

      expect(fakeRepository.fetchDetailCallCountFor(characterId), 1);
      expect(values.last.value?.currentHp, 18);

      fakeRepository.detailToReturn = _detailWithHp(25);
      fakeSyncer.resultToReturn = {characterId};

      fakeConnectivity.emitRestored();
      await pumpEventQueue();

      expect(
        fakeRepository.fetchDetailCallCountFor(characterId),
        2,
        reason:
            'characterDetailProvider(characterId) doit avoir ete '
            'invalide par le coordinateur puis re-resolu (toujours '
            'ecoute), pas seulement marque obsolete sans jamais '
            'redemander la donnee serveur.',
      );
      expect(values.last.value?.currentHp, 25);
    });

    test('un characterId qui n a jamais synchronise (resultat vide) '
        'n invalide jamais characterDetailProvider', () async {
      const characterId = 'char-1';
      fakeRepository.detailToReturn = _detailWithHp(18);
      fakeSyncer.resultToReturn = const {};

      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();

      container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(characterId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(fakeRepository.fetchDetailCallCountFor(characterId), 1);

      fakeSyncer.resultToReturn = const {};
      fakeConnectivity.emitRestored();
      await pumpEventQueue();

      expect(
        fakeRepository.fetchDetailCallCountFor(characterId),
        1,
        reason:
            'aucune invalidation ne doit se produire pour un characterId '
            'jamais retourne par sync().',
      );
    });

    test('retour de connectivite : chaque evenement onConnectivityRestored '
        'declenche une nouvelle tentative de synchro', () async {
      fakeSyncer.resultToReturn = const {};
      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();
      expect(fakeSyncer.callCount, 1, reason: 'synchro de demarrage');

      fakeConnectivity.emitRestored();
      await pumpEventQueue();
      expect(fakeSyncer.callCount, 2);

      fakeConnectivity.emitRestored();
      await pumpEventQueue();
      expect(fakeSyncer.callCount, 3);
    });

    test('dispose() annule l abonnement a onConnectivityRestored : plus '
        'aucune synchro declenchee apres', () async {
      fakeSyncer.resultToReturn = const {};
      final coordinator = container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();
      expect(fakeSyncer.callCount, 1);

      coordinator.dispose();
      fakeConnectivity.emitRestored();
      await pumpEventQueue();

      expect(
        fakeSyncer.callCount,
        1,
        reason:
            'dispose() doit annuler _subscription : un evenement de '
            'connectivite restauree emis apres ne doit plus jamais '
            'declencher sync().',
      );
    });

    test('plusieurs characterId synchronises en une seule passe invalident '
        'chacun leur characterDetailProvider respectif', () async {
      const idA = 'char-a';
      const idB = 'char-b';
      fakeRepository.detailByCharacterId[idA] = _detailWithHp(1, id: idA);
      fakeRepository.detailByCharacterId[idB] = _detailWithHp(1, id: idB);
      fakeSyncer.resultToReturn = const {};

      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();

      container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(idA),
        (previous, next) {},
        fireImmediately: true,
      );
      container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(idB),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(fakeRepository.fetchDetailCallCountFor(idA), 1);
      expect(fakeRepository.fetchDetailCallCountFor(idB), 1);

      fakeSyncer.resultToReturn = {idA, idB};
      fakeConnectivity.emitRestored();
      await pumpEventQueue();

      expect(fakeRepository.fetchDetailCallCountFor(idA), 2);
      expect(fakeRepository.fetchDetailCallCountFor(idB), 2);
    });
  });
}

CharacterDetail _detailWithHp(int currentHp, {String id = 'char-1'}) {
  return CharacterDetail(
    id: id,
    name: 'Personnage de test',
    raceName: null,
    subraceName: null,
    backgroundName: null,
    alignmentName: null,
    classes: const [
      CharacterDetailClassRow(
        classId: 1,
        hitDie: 8,
        className: 'Guerrier',
        level: 1,
        isPrimary: true,
        savingThrowProficiencies: ['str', 'con'],
      ),
    ],
    xp: 0,
    currentHp: currentHp,
    maxHp: 30,
    temporaryHp: 0,
    abilityScores: const {
      'str': 10,
      'dex': 10,
      'con': 10,
      'int': 10,
      'wis': 10,
      'cha': 10,
    },
  );
}

/// Retourne systematiquement [resultToReturn] a chaque appel de sync(), tout
/// en comptant les appels -- jamais un vrai acces reseau/local (_client et
/// _pendingWrites du parent ne sont jamais lus par sync() overrides
/// ci-dessous).
class _ScriptedSyncer extends PendingCharacterWriteSyncer {
  _ScriptedSyncer()
    : super(
        SupabaseClient('https://fake.supabase.test', 'fake-anon-key'),
        PendingCharacterWriteQueue(AppDatabase(NativeDatabase.memory())),
      );

  Set<String> resultToReturn = const {};
  int callCount = 0;

  @override
  Future<Set<String>> sync() async {
    callCount++;
    return resultToReturn;
  }
}

/// onConnectivityRestored pilote manuellement via [emitRestored] -- jamais le
/// vrai canal de plateforme connectivity_plus.
class _FakeConnectivityChecker implements ConnectivityChecker {
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => _controller.stream;

  void emitRestored() => _controller.add(true);
}

/// Double minimal de CharacterRepository -- seul fetchCharacterDetail est
/// exerce par ces tests (compte les appels, par characterId, pour detecter
/// une invalidation suivie d'un rafraichissement effectif).
class _FakeCharacterRepository implements CharacterRepository {
  CharacterDetail? detailToReturn;
  final Map<String, CharacterDetail> detailByCharacterId = {};
  final Map<String, int> _fetchCallCountByCharacterId = {};

  int fetchDetailCallCountFor(String characterId) =>
      _fetchCallCountByCharacterId[characterId] ?? 0;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    _fetchCallCountByCharacterId[characterId] =
        (_fetchCallCountByCharacterId[characterId] ?? 0) + 1;
    return detailByCharacterId[characterId] ??
        detailToReturn ??
        _detailWithHp(0, id: characterId);
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) async => WriteOutcome.synced;

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required dynamic bytes,
  }) async => 'https://example.com/portrait.png';

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) async {}

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) async => WriteOutcome.synced;

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
  }) async {}

  @override
  Future<void> leaveStory({required String characterCampaignId}) async {}
}
