// Tests de widget de l'écran "Liste des personnages".
//
// Comme pour `login_screen_test.dart`, les dépôts de test
// (`_FakeCharacterRepository`/`_FakeAuthRepository`) sont injectés via
// `overrideWithValue`, pour ne jamais toucher à `Supabase.instance.client`.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_return_route_provider.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_elemental_discipline_option.dart';
import 'package:personnages/features/characters/domain/level_up_maneuver_option.dart';
import 'package:personnages/features/characters/domain/level_up_arcane_shot_option.dart';
import 'package:personnages/features/characters/domain/level_up_infusion_option.dart';
import 'package:personnages/features/characters/domain/level_up_infusion_swap.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_option.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_swap.dart';
import 'package:personnages/features/characters/domain/level_up_draconic_ancestry_option.dart';
import 'package:personnages/features/characters/domain/level_up_rune_option.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/cache_providers.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/router/route_observer_provider.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/core/widgets/alert_banner.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/info_banner.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/sync_status_banner.dart';
import 'package:personnages/features/characters/presentation/widgets/character_selection_action_bar.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/core/widgets/selection_checkbox.dart';
import 'package:personnages/features/characters/presentation/character_list_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/fake_connectivity_checker.dart';

class _FakeCharacterRepository implements CharacterRepository {
  int fetchCallCount = 0;
  List<CharacterSummary>? charactersToReturn;
  Object? errorToThrow;
  Completer<List<CharacterSummary>>? completer;

  /// Mode sélection multiple + suppression groupée (voir
  /// `character_list_screen_test.dart` groupe dédié) : par identifiant de
  /// personnage, `WriteOutcome` à retourner ou erreur à lever au prochain
  /// appel de [deleteCharacter] — `WriteOutcome.synced` par défaut (succès)
  /// pour tout identifiant absent de ces deux maps.
  final Map<String, WriteOutcome> deleteOutcomeByCharacterId = {};
  final Map<String, Object> deleteErrorByCharacterId = {};
  final List<String> deleteCharacterCalls = [];

  /// Permet de geler [deleteCharacter] en plein vol (dette technique D89,
  /// registre `docs/dette-technique.md`) : quand défini, l'appel
  /// n'aboutit qu'une fois ce `Completer` complété, pour qu'un test puisse
  /// interagir avec l'écran pendant qu'une suppression groupée est
  /// réellement "en cours" (`_isDeletingSelection == true`), plutôt que de
  /// se fier à un simple `Future` déjà résolu.
  Completer<void>? deleteCharacterGate;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async {
    fetchCallCount++;
    if (completer != null) {
      return completer!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return charactersToReturn ?? const [];
  }

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
  }) {
    throw UnimplementedError();
  }

  /// P18 : appels de [setArchived] `(id, isArchived)`, et résultats à
  /// consommer dans l'ordre (un `WriteOutcome` à retourner, ou toute autre
  /// valeur à lever) ; vide = succès. Un succès met à jour
  /// [charactersToReturn] comme le ferait le serveur.
  final List<(String, bool)> setArchivedCalls = [];
  final List<Object> setArchivedResults = [];

  @override
  Future<WriteOutcome> setArchived({
    required String characterId,
    required bool isArchived,
  }) async {
    setArchivedCalls.add((characterId, isArchived));
    if (setArchivedResults.isNotEmpty) {
      final result = setArchivedResults.removeAt(0);
      if (result is WriteOutcome) return result;
      throw result;
    }
    charactersToReturn = [
      for (final c in charactersToReturn ?? const <CharacterSummary>[])
        if (c.id == characterId) c.copyWith(isArchived: isArchived) else c,
    ];
    return WriteOutcome.synced;
  }

  @override
  Future<WriteOutcome> deleteCharacter({required String characterId}) async {
    deleteCharacterCalls.add(characterId);
    if (deleteCharacterGate != null) {
      await deleteCharacterGate!.future;
    }
    final error = deleteErrorByCharacterId[characterId];
    if (error != null) throw error;
    return deleteOutcomeByCharacterId[characterId] ?? WriteOutcome.synced;
  }

  @override
  Future<WriteOutcome> setInspiration({
    required String characterId,
    required bool inspiration,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setArmorClassBonus({
    required String characterId,
    required int bonus,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setSpellPrepared({
    required String characterId,
    required int spellId,
    required bool prepared,
  }) => throw UnimplementedError();

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
  Future<void> addGalleryPhoto({
    required String characterId,
    required Uint8List bytes,
  }) => throw UnimplementedError();

  @override
  Future<void> removeGalleryPhoto({
    required String characterId,
    required String photoId,
    required String url,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addJournalEntry({
    required String characterId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> updateJournalEntry({
    required String characterId,
    required String entryId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> removeJournalEntry({
    required String characterId,
    required String entryId,
  }) => throw UnimplementedError();

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
  Future<List<LevelUpFeatOption>> fetchAvailableFeats({
    required String characterId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpInvocationOption>> fetchAvailableInvocations({
    required String characterId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpElementalDisciplineOption>>
  fetchAvailableElementalDisciplines({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpManeuverOption>> fetchAvailableManeuvers({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpArcaneShotOption>> fetchAvailableArcaneShots({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpRuneOption>> fetchAvailableRunes({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpInfusionOption>> fetchAvailableInfusions({
    required String characterId,
    required Object classId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> fetchKnownInfusionNames({
    required String characterId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpMetamagicOption>> fetchAvailableMetamagicOptions({
    required String characterId,
    required Object classId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> fetchKnownMetamagicNames({
    required String characterId,
    required Object classId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpDraconicAncestryOption>>
  fetchAvailableDraconicAncestryOptions({required Object subclassId}) async =>
      throw UnimplementedError();

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required Object classId,
    required String className,
    required bool isMulticlassing,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
    List<int> initialSpellIds = const [],
    List<int> invocationIds = const [],
    List<String> elementalDisciplineNames = const [],
    List<String> maneuverNames = const [],
    List<String> arcaneShotNames = const [],
    List<String> runeNames = const [],
    List<String> infusionNames = const [],
    LevelUpInfusionSwap? infusionSwap,
    List<String> metamagicNames = const [],
    LevelUpMetamagicSwap? metamagicSwap,
    List<int> expertiseSkillIds = const [],
    bool expertiseThievesToolsSubstitution = false,
    String? draconicAncestryDamageType,
    List<int> racialInnateSpellIds = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    Map<String, int> hitDiceSpentByClassId = const {},
    int appliedGain = 0,
    Map<String, int> hitDiceRecoveredByClassId = const {},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveStory({required String characterCampaignId}) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> updateStoryFields({
    required String characterId,
    String? appearanceText,
    String? traitsText,
    String? idealsText,
    String? bondsText,
    String? flawsText,
    String? backstoryText,
    String? alliesText,
    String? featuresText,
    String? treasureText,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> useInventoryItem({
    required String characterId,
    required String inventoryId,
    required int newQuantity,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> equipWeaponToSlot({
    required String characterId,
    required String inventoryId,
    required WeaponSlot slot,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> setInventoryItemAttuned({
    required String characterId,
    required String inventoryId,
    required bool attuned,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> removeInventoryItem({
    required String characterId,
    required String inventoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addCustomInventoryItem({
    required String characterId,
    required String customName,
    required int quantity,
    String? description,
    String? damageDice,
    String? damageType,
    List<String> properties = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    bool isPactSlot = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> setInnateSpellUsesSpent({
    required String characterId,
    required int spellId,
    required int usesSpent,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) {
    throw UnimplementedError();
  }
}

class _FakeAuthRepository implements AuthRepository {
  int signOutCallCount = 0;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async => false;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {}

  @override
  Future<void> updateDisplayName({required String? displayName}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> updateEmail({required String newEmail}) async {}

  @override
  Future<String> updateAvatar({required Uint8List bytes}) async => '';

  @override
  Future<void> removeAvatar() async {}

  @override
  Future<void> markOnboardingSeen() async {}
}

/// Double d'`AppVersionRepository` (`features/app_update/`) — voir la
/// documentation de classe de `UpdateSuggestedBanner` dans
/// `character_list_screen.dart::build` : la bannière "Mise à jour suggérée"
/// est insérée inconditionnellement, ce fichier ne teste donc que sa
/// présence/absence selon le statut résolu, jamais son contenu détaillé
/// (voir `test/features/app_update/presentation/widgets/update_suggested_banner_test.dart`
/// pour ça).
class _FakeAppVersionRepository implements AppVersionRepository {
  _FakeAppVersionRepository(this._row);

  final AppVersionRow _row;

  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async => _row;
}

/// Bouton de filtre de la barre de recherche, cible réelle du tap de
/// l'utilisateur (l'`InkWell` 44×44 de `_FilterButton`, privé à l'écran).
///
/// Ne pas taper `find.byIcon(Icons.filter_list)` directement : dès qu'un
/// filtre est actif, la pastille dorée `_FilterActiveDot` est superposée au
/// centre du glyphe et intercepte le hit test à sa place. Le tap atteignait
/// quand même l'`InkWell` (la sheet s'ouvrait), mais `tester.tap` émettait
/// un avertissement "would not hit test on the specified widget".
Finder _filterButton() => find.ancestor(
  of: find.byIcon(Icons.filter_list),
  matching: find.byType(InkWell),
);

/// Fait défiler la feuille de filtre jusqu'à [finder] (liste paresseuse : la
/// section « TRIER PAR » en tête pousse « STATUT » hors de la zone montée).
Future<void> _scrollFilterSheetTo(WidgetTester tester, Finder finder) =>
    tester.dragUntilVisible(
      finder,
      find.byKey(const Key('characterListFilterOptions')),
      const Offset(0, -100),
    );

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

void main() {
  // `packageInfoProvider` (lu par `appVersionCheckProvider`, dépendance de
  // `UpdateSuggestedBanner`) : mockée une fois pour tout le fichier, même
  // convention que `profile_screen_test.dart`.
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'com.nexusjdr.personnages',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeAuthRepository fakeAuthRepository;
  // Statut "à jour" par défaut (`installedVersion` == `latestVersion`, voir
  // `setUpAll` ci-dessus) : la bannière "Mise à jour suggérée" reste
  // invisible pour tous les tests de ce fichier qui ne la concernent pas
  // explicitement — important en particulier pour ne pas faire doublon avec
  // l'icône `Icons.close` déjà utilisée par le champ de recherche (voir le
  // groupe "recherche/filtre" plus bas).
  late _FakeAppVersionRepository fakeAppVersionRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeAuthRepository = _FakeAuthRepository();
    fakeAppVersionRepository = _FakeAppVersionRepository(
      const AppVersionRow(
        minimumSupportedVersion: '0.1.0',
        latestVersion: '0.1.0',
      ),
    );
  });

  GoRouter buildTestRouter({List<NavigatorObserver> observers = const []}) {
    return GoRouter(
      initialLocation: '/',
      observers: observers,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CharacterListScreen(),
        ),
        GoRoute(
          path: '/characters/new/edition',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Assistant de création')),
          ),
        ),
        GoRoute(
          path: '/characters/new',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Assistant de création')),
          ),
        ),
        GoRoute(
          path: '/characters/:id',
          // Un bouton "Retour" explicite (plutôt que de compter sur la
          // flèche `AppBar` par défaut, absente ici) : simule le pop vers
          // `CharacterListScreen` déclenché en vrai depuis
          // `character_detail_screen.dart` — voir les tests
          // "RouteAware.didPopNext" plus bas, qui vérifient que ce pop
          // relance `charactersProvider`.
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Fiche personnage ${state.pathParameters['id']}'),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          // Simule la fin de la création d'un personnage
          // (`edition_step_screen.dart` : `context.go('/')`) : le routeur
          // reconstruit la pile de pages, et le `RouteObserver` notifie
          // `didPopNext` pendant le `didUpdateWidget` du `Navigator`.
          path: '/retour-par-go',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Terminer par go'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/join',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Rejoindre une histoire — étape 1')),
          ),
        ),
        GoRoute(
          // Cible du bouton profil rond de l'en-tête
          // (`character_list_screen.dart::_ProfileButton`) — voir le test
          // "le bouton profil navigue vers l'écran Profil" plus bas.
          // `ProfileScreen` réel non utilisé ici : ce fichier ne teste que
          // la navigation déclenchée par `CharacterListScreen`, pas le
          // contenu de l'écran de destination (voir
          // `test/features/profile/presentation/profile_screen_test.dart`).
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Écran Profil'))),
        ),
        GoRoute(
          // Cible du bouton "groupes" de l'en-tête
          // (`character_list_screen.dart::_GroupsButton`) — navigue
          // TOUJOURS ici, quel que soit le nombre de groupes du joueur.
          // Écran "Groupes" réel non utilisé ici (voir les tests dédiés
          // `test/features/groups/presentation/group_list_screen_test.dart`) :
          // ce fichier ne teste que la navigation déclenchée par
          // `CharacterListScreen`, pas le contenu de l'écran de destination.
          path: '/groups',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Écran Groupes'))),
        ),
      ],
    );
  }

  Widget buildTestWidget({
    RouteObserver<PageRoute<dynamic>>? routeObserver,
    AppVersionRepository? appVersionRepository,
    Locale locale = const Locale('fr'),
    double textScale = 1.0,
    List<Override> extraOverrides = const [],
    User? currentUser,
  }) {
    final observer = routeObserver ?? RouteObserver<PageRoute<dynamic>>();
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeCharacterRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        routeObserverProvider.overrideWithValue(observer),
        currentUserProvider.overrideWithValue(currentUser),
        ...extraOverrides,
        appVersionRepositoryProvider.overrideWithValue(
          appVersionRepository ?? fakeAppVersionRepository,
        ),
      ],
      child: MaterialApp.router(
        // `CharacterListScreen` et ses widgets de liste lisent
        // `AppLocalizations.of(context)!` (chantier "traduction de l'app"
        // Phase B, lot "Characters — liste") : sans ces delegates, l'appel
        // renverrait `null` et le `!` planterait. `fr` par défaut, `en`
        // passé explicitement par le groupe "locale anglaise" plus bas.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        // Police système agrandie (F21) : simule le réglage d'accessibilité
        // de l'OS sans dépendre de la plateforme d'exécution.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: buildTestRouter(observers: [observer]),
      ),
    );
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeCharacterRepository.completer = Completer<List<CharacterSummary>>();

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('affiche les personnages retournés par le dépôt', (
    WidgetTester tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(
        id: '1',
        name: 'Halltesse Ambrelune',
        raceName: 'Elfe',
        className: 'Magicienne',
        level: 5,
        xp: 7000,
      ),
      CharacterSummary(
        id: '2',
        name: 'Borgan Pierrefort',
        raceName: 'Nain',
        className: 'Guerrier',
        level: 3,
        xp: 1200,
      ),
    ];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Elfe · Magicienne · Niv. 5'), findsOneWidget);
    expect(find.text('Borgan Pierrefort'), findsOneWidget);
    expect(find.text('Nain · Guerrier · Niv. 3'), findsOneWidget);
    expect(find.text('XP'), findsNWidgets(2));
  });

  testWidgets(
    'un personnage sans race/classe résolues affiche seulement le niveau',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Sylvi Aubefeuille', level: 1, xp: 0),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sylvi Aubefeuille'), findsOneWidget);
      expect(find.text('Niv. 1'), findsOneWidget);
    },
  );

  testWidgets(
    'un personnage avec seulement une classe résolue (race personnalisée '
    'non résolue) affiche "Classe · Niv. X" sans le segment race',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '1',
          name: 'Kaeloth',
          className: 'Barde',
          level: 2,
          xp: 500,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Barde · Niv. 2'), findsOneWidget);
    },
  );

  testWidgets(
    'un personnage avec seulement une race résolue (personnage sans classe '
    'enregistrée) affiche "Race · Niv. X" sans le segment classe',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '1',
          name: 'Orim',
          raceName: 'Demi-orque',
          // Niveau 1 : repli documenté du dépôt pour un personnage sans
          // ligne `character_classes` (voir `character_repository.dart`).
          level: 1,
          xp: 0,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Demi-orque · Niv. 1'), findsOneWidget);
    },
  );

  testWidgets(
    'un personnage sans portrait affiche l\'icône de substitution générique '
    'dans la liste (docs/cahier-des-charges/04-fonctionnalites-app-mobile.md '
    'section 2)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Sylvi Aubefeuille', level: 1, xp: 0),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // `Icons.person_outline` est aussi utilisé par le bouton profil de
      // l'en-tête : on restreint la recherche aux icônes à l'intérieur d'une
      // carte personnage pour ne cibler que le portrait de substitution.
      expect(
        find.descendant(
          of: find.byType(CharacterCard),
          matching: find.byIcon(Icons.person_outline),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un personnage avec un portrait défini construit une image réseau '
    'configurée sur son URL (`characters.portrait_url`)',
    (WidgetTester tester) async {
      const portraitUrl = 'https://example.com/halltesse.jpg';
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '1',
          name: 'Halltesse Ambrelune',
          portraitUrl: portraitUrl,
          raceName: 'Elfe',
          className: 'Magicienne',
          level: 5,
          xp: 7000,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // `flutter test` ne fait aucune requête réseau réelle (voir
      // `test/core/widgets/portrait_frame_test.dart` pour le détail) : on
      // vérifie donc la configuration de l'image demandée, pas le rendu
      // pixel final, qui dépend d'un vrai téléchargement hors périmètre de
      // ce test.
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byType(CharacterCard),
          matching: find.byType(Image),
        ),
      );
      expect((image.image as NetworkImage).url, portraitUrl);
    },
  );

  testWidgets('affiche un état vide quand le joueur n\'a aucun personnage', (
    WidgetTester tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('AUCUN AVENTURIER'), findsOneWidget);
  });

  testWidgets('état vide "aucun personnage" : reste sans débordement quand la '
      'hauteur disponible est trop juste (F06, `docs/retours-utilisateurs.md`) '
      '— ex. petit écran + bandeau "Mise à jour suggérée" visible au-dessus, '
      'texte système agrandi', (WidgetTester tester) async {
    fakeCharacterRepository.charactersToReturn = const [];
    // Hauteur volontairement très réduite : reproduit sans ambiguïté le
    // débordement VERTICAL confirmé sur le `Column` de [_EmptyState]
    // (icône 88×88 + titre + corps) quand l'[Expanded] qui l'héberge
    // devient trop petit — jamais atteint par les tests existants
    // (`buildTestWidget()` sans surface réduite, 800×600 par défaut).
    tester.view.physicalSize = const Size(375, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Avant correctif : `FlutterError` ("A RenderFlex overflowed...") sur
    // le `Column` de [_EmptyState] — `tester.takeException()` l'aurait
    // renvoyée ici, faisant échouer ce test tant que le correctif n'est
    // pas appliqué (la bannière jaune/noire de rendu ne fait pas échouer
    // le test à elle seule, mais l'erreur de layout sous-jacente, elle,
    // le fait).
    expect(tester.takeException(), isNull);
    // Le texte doit rester intégralement lisible (défilable), pas
    // seulement "ne plus planter" : un `TextOverflow.clip`/`ellipsis`
    // masquerait le symptôme sans garantir que le contenu reste
    // consultable.
    expect(find.textContaining('AUCUN AVENTURIER'), findsOneWidget);
    // Refonte du 12/11/2026 : l'état vide n'a plus de défilement propre (F06),
    // c'est le `CustomScrollView` unique de l'écran qui le fait défiler.
    expect(
      find.ancestor(
        of: find.textContaining('AUCUN AVENTURIER'),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.textContaining('AUCUN AVENTURIER'),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // Hauteur trop juste : le contenu dépasse et le défilement l'atteint.
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('état vide "aucun personnage" : médaillon en bordure pointillée '
      'circulaire, icône explore_outlined en accentTeal (recettage direction '
      'artistique du 13/09)', (WidgetTester tester) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is DashedBorderPainter &&
            (widget.painter! as DashedBorderPainter).shape == BoxShape.circle &&
            (widget.painter! as DashedBorderPainter).color ==
                AppColors.textOnWoodMuted,
      ),
      findsOneWidget,
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.explore_outlined));
    expect(icon.color, AppColors.accentTeal);
    expect(find.byIcon(Icons.shield_moon_outlined), findsNothing);
  });

  group(
    'échec du chargement initial : écran "Connexion impossible" '
    '(recettage direction artistique du 13/09/2026, remplace l\'ancien '
    '`_ErrorState` générique — voir `widgets/connection_error_state.dart`)',
    () {
      testWidgets(
        'affiche le bandeau "CONNEXION", le titre, le texte explicatif et '
        'l\'icône wifi barrée, quelle que soit l\'erreur levée par le dépôt',
        (WidgetTester tester) async {
          fakeCharacterRepository.errorToThrow = const CharacterFailure(
            'Session expirée, reconnecte-toi.',
          );

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('CONNEXION'), findsOneWidget);
          expect(find.text('Connexion impossible'), findsOneWidget);
          expect(
            find.textContaining(
              'les modifications se synchroniseront automatiquement',
            ),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.wifi_off), findsOneWidget);
          // Copie statique de la maquette, jamais le message de la
          // `CharacterFailure` sous-jacente (spec de la tâche).
          expect(find.text('Session expirée, reconnecte-toi.'), findsNothing);
        },
      );

      testWidgets(
        'même écran statique quand le dépôt lève une exception qui n\'est '
        'pas une CharacterFailure',
        (WidgetTester tester) async {
          fakeCharacterRepository.errorToThrow = StateError('boom réseau');

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('Connexion impossible'), findsOneWidget);
        },
      );

      testWidgets('le bouton "RÉESSAYER" relance la requête', (
        WidgetTester tester,
      ) async {
        fakeCharacterRepository.errorToThrow = const CharacterFailure(
          'Impossible de charger vos personnages. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        expect(fakeCharacterRepository.fetchCallCount, 1);

        await tester.tap(find.text('RÉESSAYER'));
        await tester.pumpAndSettle();

        expect(fakeCharacterRepository.fetchCallCount, 2);
      });

      testWidgets('un nouvel échec après "RÉESSAYER" réaffiche le même écran '
          '"Connexion impossible" (pas de crash, pas de retour à la liste)', (
        WidgetTester tester,
      ) async {
        fakeCharacterRepository.errorToThrow = const CharacterFailure(
          'Impossible de charger vos personnages. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('RÉESSAYER'));
        await tester.pumpAndSettle();

        expect(find.text('Connexion impossible'), findsOneWidget);
        expect(fakeCharacterRepository.fetchCallCount, 2);
      });

      testWidgets('affiche le lien "Continuer hors ligne", visuellement neutre '
          '(aucun fallback cache réel tant que la Phase 4 n\'est pas livrée '
          '— voir `widgets/connection_error_state.dart`)', (
        WidgetTester tester,
      ) async {
        fakeCharacterRepository.errorToThrow = const CharacterFailure(
          'Impossible de charger vos personnages. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Continuer hors ligne'), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Continuer hors ligne'),
            matching: find.byType(Tooltip),
          ),
          findsOneWidget,
        );
      });

      testWidgets('aucune flèche retour dans le bandeau "CONNEXION" : '
          '`CharacterListScreen` est l\'écran d\'accueil (route `/`), rien de '
          'cohérent vers quoi revenir (écart assumé par rapport à la maquette, '
          'voir la documentation de classe de `ConnectionErrorState`)', (
        WidgetTester tester,
      ) async {
        fakeCharacterRepository.errorToThrow = const CharacterFailure(
          'Impossible de charger vos personnages. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      });
    },
  );

  testWidgets('le bouton "Importer XML" ouvre le sélecteur de fichier natif et '
      'affiche un message d\'erreur si aucun plugin n\'est disponible '
      '(environnement de test)', (WidgetTester tester) async {
    // `file_picker` n'a pas d'implémentation de plateforme enregistrée
    // sous `flutter test` (pas de mock de canal ici) : `pickFiles()` lève
    // une `MissingPluginException`, capturée par
    // `CharacterListScreen._startXmlImport` — ce test vérifie donc le
    // chemin d'erreur réel de cet environnement plutôt que le chemin
    // "sélection réussie" (nécessiterait de mocker le `MethodChannel` du
    // plugin, hors périmètre de ce test ciblé sur `CharacterListScreen`
    // elle-même ; voir `test/features/xml_import/` pour les tests de
    // l'écran de vérification qui suit une sélection réussie).
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('IMPORTER XML'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Impossible de lire ce fichier'),
      findsOneWidget,
    );
  });

  testWidgets(
    'le bouton "Rejoindre une histoire" est masqué (fonctionnalité mise de '
    'côté le temps du reste du recettage direction-artistique — voir le '
    'commentaire de `character_list_screen.dart::build`)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('REJOINDRE UNE HISTOIRE'), findsNothing);
    },
  );

  testWidgets('le bouton "+ Créer" navigue vers l\'assistant de création', (
    WidgetTester tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ CRÉER'));
    await tester.pumpAndSettle();

    expect(find.text('Assistant de création'), findsOneWidget);
  });

  testWidgets(
    'le bouton "+ Créer" réinitialise le brouillon de création en mémoire '
    'et efface toute route de retour laissée par une session "Rejoindre '
    'une histoire" abandonnée, avant de naviguer',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      final container = ProviderContainer(
        overrides: [
          characterRepositoryProvider.overrideWithValue(
            fakeCharacterRepository,
          ),
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          currentUserProvider.overrideWithValue(null),
          appVersionRepositoryProvider.overrideWithValue(
            fakeAppVersionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      // Simule un brouillon abandonné d'une session précédente.
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 7, subraceId: 3);
      // Simule une route de retour laissée par une session "Rejoindre une
      // histoire" abandonnée avant l'étape 9 (voir la documentation de
      // classe de `CharacterCreationReturnRouteController`) — une création
      // lancée normalement depuis cet écran ne doit jamais la reprendre.
      container
          .read(characterCreationReturnRouteControllerProvider.notifier)
          .set('/join/step-3?code=AB3F7K');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            routerConfig: buildTestRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ CRÉER'));
      await tester.pumpAndSettle();

      expect(
        container.read(characterCreationDraftControllerProvider),
        const CharacterCreationDraft(),
      );
      expect(
        container.read(characterCreationReturnRouteControllerProvider),
        isNull,
      );
    },
  );

  testWidgets(
    'taper une carte personnage navigue vers sa fiche (/characters/:id)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '42',
          name: 'Halltesse Ambrelune',
          level: 5,
          xp: 7000,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();

      expect(find.text('Fiche personnage 42'), findsOneWidget);
    },
  );

  group('RouteAware.didPopNext (rafraîchissement au retour d\'un écran poussé '
      'par-dessus la liste, ex. fiche personnage/montée de niveau)', () {
    testWidgets(
      'revenir de la fiche personnage (pop) relance charactersProvider, '
      'même sans aucune interaction explicite de rafraîchissement',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(
            id: '42',
            name: 'Halltesse Ambrelune',
            level: 5,
            xp: 7000,
          ),
        ];
        final observer = RouteObserver<PageRoute<dynamic>>();

        await tester.pumpWidget(buildTestWidget(routeObserver: observer));
        await tester.pumpAndSettle();
        expect(fakeCharacterRepository.fetchCallCount, 1);

        await tester.tap(find.byType(CharacterCard));
        await tester.pumpAndSettle();
        expect(find.text('Fiche personnage 42'), findsOneWidget);

        // Simule un level-up (ou toute autre écriture) appliqué depuis la
        // fiche : la prochaine requête réseau renverrait un niveau à jour,
        // exactement comme le ferait Supabase après une écriture réussie.
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(
            id: '42',
            name: 'Halltesse Ambrelune',
            level: 6,
            xp: 14000,
          ),
        ];

        await tester.tap(find.text('Retour'));
        await tester.pumpAndSettle();

        expect(find.text('Elfe · Magicienne · Niv. 6'), findsNothing);
        expect(find.text('Niv. 6'), findsOneWidget);
        expect(
          fakeCharacterRepository.fetchCallCount,
          2,
          reason:
              'le retour de la fiche (pop) doit déclencher un nouveau '
              'fetch, sans quoi la carte resterait sur le niveau '
              'obsolète (Niv. 5)',
        );
      },
    );

    testWidgets('un pop en cascade depuis un écran poussé par-dessus la fiche '
        '(ex. "Montée de niveau") relance aussi charactersProvider une '
        'fois revenu sur la liste', (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '42',
          name: 'Borgan Pierrefort',
          level: 3,
          xp: 900,
        ),
      ];
      final observer = RouteObserver<PageRoute<dynamic>>();

      await tester.pumpWidget(buildTestWidget(routeObserver: observer));
      await tester.pumpAndSettle();
      expect(fakeCharacterRepository.fetchCallCount, 1);

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();
      expect(find.text('Fiche personnage 42'), findsOneWidget);

      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '42',
          name: 'Borgan Pierrefort',
          level: 4,
          xp: 2700,
        ),
      ];

      // Pop direct de la fiche vers la liste (le flux réel "Montée de
      // niveau" empile une route supplémentaire par-dessus la fiche puis
      // dépile jusqu'à la liste ; `didPopNext` se déclenche de la même
      // façon dans les deux cas — seul compte le fait que cet écran
      // redevienne visible après un pop, peu importe la profondeur de la
      // pile dépilée, voir la documentation de classe de
      // `CharacterListScreen`).
      await tester.tap(find.text('Retour'));
      await tester.pumpAndSettle();

      expect(find.text('Niv. 4'), findsOneWidget);
      expect(fakeCharacterRepository.fetchCallCount, 2);
    });

    testWidgets(
      'un simple retour depuis la fiche personnage SANS aucune écriture '
      'ne casse rien : refetch inoffensif (redondant mais sans effet '
      "visible), pas de crash au démontage de l'écran",
      (WidgetTester tester) async {
        const unchanged = [
          CharacterSummary(
            id: '42',
            name: 'Halltesse Ambrelune',
            level: 5,
            xp: 7000,
          ),
        ];
        fakeCharacterRepository.charactersToReturn = unchanged;
        final observer = RouteObserver<PageRoute<dynamic>>();

        await tester.pumpWidget(buildTestWidget(routeObserver: observer));
        await tester.pumpAndSettle();
        expect(fakeCharacterRepository.fetchCallCount, 1);

        await tester.tap(find.byType(CharacterCard));
        await tester.pumpAndSettle();
        expect(find.text('Fiche personnage 42'), findsOneWidget);

        // Aucune écriture simulée ici (`charactersToReturn` inchangé) :
        // simple consultation de la fiche puis retour immédiat.
        await tester.tap(find.text('Retour'));
        await tester.pumpAndSettle();

        // Refetch quand même déclenché (comportement voulu, documenté sur
        // `CharacterListScreen` : pas d'optimisation pour éviter un
        // refetch inutile), mais sans régression visible : la carte
        // affiche toujours les mêmes données, aucune exception levée
        // pendant le pop (ce test échouerait sinon, `tester.pumpAndSettle`
        // remonte toute exception non interceptée).
        expect(find.text('Halltesse Ambrelune'), findsOneWidget);
        expect(find.text('Niv. 5'), findsOneWidget);
        expect(fakeCharacterRepository.fetchCallCount, 2);
      },
    );

    testWidgets('un retour par context.go (fin de la création) relance '
        'charactersProvider SANS invalider pendant le build (aucune erreur '
        '"setState() or markNeedsBuild() called during build")', (
      WidgetTester tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '42',
          name: 'Halltesse Ambrelune',
          level: 5,
          xp: 7000,
        ),
      ];
      final observer = RouteObserver<PageRoute<dynamic>>();
      await tester.pumpWidget(buildTestWidget(routeObserver: observer));
      await tester.pumpAndSettle();
      expect(fakeCharacterRepository.fetchCallCount, 1);

      final router = GoRouter.of(tester.element(find.byType(CharacterCard)));
      unawaited(router.push('/retour-par-go'));
      await tester.pumpAndSettle();
      expect(find.text('Terminer par go'), findsOneWidget);

      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '42',
          name: 'Halltesse Ambrelune',
          level: 6,
          xp: 14000,
        ),
      ];

      await tester.tap(find.text('Terminer par go'));
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason:
            'didPopNext ne doit pas invalider un provider pendant le '
            'build du Navigator : $exception',
      );
      expect(find.text('Niv. 6'), findsOneWidget);
      expect(
        fakeCharacterRepository.fetchCallCount,
        2,
        reason: 'un seul refetch au retour, pas de requête doublée',
      );
    });

    testWidgets(
      'ne relance pas charactersProvider au premier affichage (pas de '
      'pop encore survenu)',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(fakeCharacterRepository.fetchCallCount, 1);
      },
    );
  });

  testWidgets(
    'le bouton profil rond navigue vers l\'écran "Profil" (route /profile) '
    '— remplace l\'ancien menu minimal "Se déconnecter" (déplacé sur cet '
    'écran, voir `test/features/profile/presentation/profile_screen_test.dart`)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('Écran Profil'), findsOneWidget);
    },
  );

  group('bouton "groupes" (_GroupsButton)', () {
    testWidgets(
      'navigue toujours vers l\'écran "Groupes" (/groups), quel que soit '
      'le nombre de groupes du joueur (voir les tests dédiés de '
      'group_list_screen_test.dart pour le contenu de cet écran)',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Écran Groupes'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'en-tête : le bouton "groupes" est affiché à gauche du bouton "profil" '
    '(conforme à la maquette "Liste des personnages" de '
    '`09-maquettes-captures.md`, recettage direction artistique du 13/09)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final groupsX = tester.getTopLeft(find.byIcon(Icons.groups_outlined)).dx;
      final profileX = tester
          .getTopLeft(find.byIcon(Icons.person_outline).last)
          .dx;

      expect(
        groupsX,
        lessThan(profileX),
        reason:
            'le bouton "groupes" doit précéder le bouton "profil" '
            'horizontalement dans l\'en-tête',
      );
    },
  );

  group('recherche/filtre (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section 2)', () {
    const characters = [
      CharacterSummary(
        id: '1',
        name: 'Halltesse Ambrelune',
        className: 'Magicien',
        level: 5,
        xp: 7000,
      ),
      CharacterSummary(
        id: '2',
        name: 'Borgan Pierrefort',
        className: 'Guerrier',
        level: 3,
        xp: 1200,
      ),
      CharacterSummary(
        id: '3',
        name: 'Sylvi Aubefeuille',
        className: 'Roublard',
        level: 1,
        xp: 0,
      ),
    ];

    testWidgets(
      'taper dans le champ de recherche ne garde que les personnages dont '
      'le nom correspond',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'borgan',
        );
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsNothing);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsNothing);
      },
    );

    testWidgets(
      'aucun résultat pour la recherche : affiche l\'état dédié avec la '
      'requête, "Réinitialiser" restaure la liste complète',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'Zar',
        );
        await tester.pumpAndSettle();

        expect(find.text('AUCUN RÉSULTAT POUR « ZAR »'), findsOneWidget);
        expect(find.text('Halltesse Ambrelune'), findsNothing);

        await tester.tap(find.text('RÉINITIALISER'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsOneWidget);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsOneWidget);
      },
    );

    testWidgets(
      'état "aucun résultat" : médaillon en bordure pointillée circulaire '
      '(recettage direction artistique du 13/09)',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'Zar',
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint &&
                widget.painter is DashedBorderPainter &&
                (widget.painter! as DashedBorderPainter).shape ==
                    BoxShape.circle &&
                (widget.painter! as DashedBorderPainter).color ==
                    AppColors.textOnWoodMuted,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'icône "×" du champ efface la recherche et restaure la liste complète',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'borgan',
        );
        await tester.pumpAndSettle();
        expect(find.text('Halltesse Ambrelune'), findsNothing);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsOneWidget);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
      },
    );

    testWidgets(
      'icône filtre : ouvre la sheet "FILTRER", cocher une classe puis '
      '"Appliquer" ne garde que les personnages de cette classe',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(_filterButton());
        await tester.pumpAndSettle();

        expect(find.text('FILTRER ET TRIER'), findsOneWidget);

        // La section "CLASSE" est en bas de la sheet, sous "STATUT"
        // (`ListView`, chargement paresseux des enfants hors viewport) :
        // scroller jusqu'à ce qu'elle soit montée avant de la chercher.
        await tester.dragUntilVisible(
          find.text('Roublard'),
          find.byKey(const Key('characterListFilterOptions')),
          const Offset(0, -100),
        );
        expect(find.text('Magicien'), findsOneWidget);
        expect(find.text('Guerrier'), findsOneWidget);
        expect(find.text('Roublard'), findsOneWidget);

        await tester.tap(find.text('Guerrier'));
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsNothing);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsNothing);
      },
    );

    testWidgets(
      'sheet de filtre : "Réinitialiser" vide la sélection avant même de '
      'fermer la sheet',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(_filterButton());
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.text('Guerrier'),
          find.byKey(const Key('characterListFilterOptions')),
          const Offset(0, -100),
        );
        await tester.ensureVisible(find.text('Guerrier'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guerrier'));
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();
        expect(find.text('Halltesse Ambrelune'), findsNothing);

        await tester.tap(_filterButton());
        await tester.pumpAndSettle();
        // La liste d'options est paresseuse : "Guerrier" doit être monté
        // pour lire l'état de sa case.
        await tester.dragUntilVisible(
          find.text('Guerrier'),
          find.byKey(const Key('characterListFilterOptions')),
          const Offset(0, -100),
        );
        bool guerrierChecked() => tester
            .widget<CheckableOptionTile>(
              find.widgetWithText(CheckableOptionTile, 'Guerrier'),
            )
            .checked;
        expect(guerrierChecked(), isTrue);

        await tester.tap(find.text('RÉINITIALISER'));
        await tester.pump();
        // Sheet encore ouverte, "Appliquer" pas encore tapé : la case est
        // déjà décochée et le filtre de la liste, lui, n'a pas bougé.
        expect(find.text('APPLIQUER'), findsOneWidget);
        expect(guerrierChecked(), isFalse);
        expect(find.text('Halltesse Ambrelune'), findsNothing);

        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsOneWidget);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsOneWidget);
      },
    );

    testWidgets('recherche ET filtre de classe combinés (intersection)', (
      WidgetTester tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = characters;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(_filterButton());
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Roublard'),
        find.byKey(const Key('characterListFilterOptions')),
        const Offset(0, -100),
      );
      await tester.tap(find.text('Roublard'));
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher un personnage'),
        'Sylvi',
      );
      await tester.pumpAndSettle();
      expect(find.text('Sylvi Aubefeuille'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher un personnage'),
        'Borgan',
      );
      await tester.pumpAndSettle();
      expect(find.text('Borgan Pierrefort'), findsNothing);
      expect(find.textContaining('AUCUN RÉSULTAT'), findsOneWidget);
    });

    group('filtre par statut (16/09/2026, hors cahier des charges)', () {
      const statusCharacters = [
        CharacterSummary(
          id: '1',
          name: 'Halltesse Ambrelune',
          level: 5,
          xp: 7000,
        ),
        CharacterSummary(
          id: '2',
          name: 'Borgan Pierrefort',
          level: 3,
          xp: 1200,
          isArchived: true,
        ),
        CharacterSummary(
          id: '3',
          name: 'Sylvi Aubefeuille',
          level: 1,
          xp: 0,
          isDead: true,
        ),
      ];

      testWidgets(
        'sheet "FILTRER" : cocher "Vivants" ne garde que les personnages ni '
        'morts ni archivés',
        (WidgetTester tester) async {
          fakeCharacterRepository.charactersToReturn = statusCharacters;

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          await tester.tap(_filterButton());
          await tester.pumpAndSettle();

          await _scrollFilterSheetTo(tester, find.text('Mort'));
          expect(find.text('STATUT'), findsOneWidget);
          expect(find.text('Vivants'), findsOneWidget);
          expect(find.text('Archivé'), findsOneWidget);
          expect(find.text('Mort'), findsOneWidget);

          await tester.tap(find.text('Vivants'));
          await tester.tap(find.text('APPLIQUER'));
          await tester.pumpAndSettle();

          expect(find.text('Halltesse Ambrelune'), findsOneWidget);
          expect(find.text('Borgan Pierrefort'), findsNothing);
          expect(find.text('Sylvi Aubefeuille'), findsNothing);
        },
      );

      testWidgets('cocher "Archivé" et "Mort" ensemble (union) : tout sauf '
          'les vivants', (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = statusCharacters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(_filterButton());
        await tester.pumpAndSettle();
        await _scrollFilterSheetTo(tester, find.text('Mort'));
        await tester.tap(find.text('Archivé'));
        await tester.tap(find.text('Mort'));
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsNothing);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsOneWidget);
      });

      testWidgets(
        '"Réinitialiser" vide aussi la sélection de statut, pas seulement '
        'la classe',
        (WidgetTester tester) async {
          fakeCharacterRepository.charactersToReturn = statusCharacters;

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          await tester.tap(_filterButton());
          await tester.pumpAndSettle();
          await _scrollFilterSheetTo(tester, find.text('Mort'));
          await tester.tap(find.text('Mort'));
          await tester.tap(find.text('APPLIQUER'));
          await tester.pumpAndSettle();
          expect(find.text('Halltesse Ambrelune'), findsNothing);

          await tester.tap(_filterButton());
          await tester.pumpAndSettle();
          await tester.tap(find.text('RÉINITIALISER'));
          await tester.tap(find.text('APPLIQUER'));
          await tester.pumpAndSettle();

          expect(find.text('Halltesse Ambrelune'), findsOneWidget);
          expect(find.text('Borgan Pierrefort'), findsOneWidget);
          expect(find.text('Sylvi Aubefeuille'), findsOneWidget);
        },
      );
    });
  });

  group('bannière "Mise à jour suggérée" (`UpdateSuggestedBanner`, recettage '
      'direction-artistique du 13/09/2026) — insérée entre l\'en-tête et la '
      'barre de recherche, contenu détaillé testé séparément dans '
      'update_suggested_banner_test.dart', () {
    testWidgets('invisible par défaut (statut "à jour", voir le double '
        '`_FakeAppVersionRepository` par défaut de `setUp`)', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle version disponible'), findsNothing);
    });

    testWidgets('visible entre l\'en-tête ("TES AVENTURIERS") et la barre de '
        'recherche quand une mise à jour est suggérée', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(
        buildTestWidget(
          appVersionRepository: _FakeAppVersionRepository(
            const AppVersionRow(
              minimumSupportedVersion: '0.1.0',
              latestVersion: '0.5.0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle version disponible'), findsOneWidget);

      final headerY = tester.getBottomLeft(find.text('TES AVENTURIERS')).dy;
      final bannerY = tester
          .getTopLeft(find.text('Nouvelle version disponible'))
          .dy;
      final searchY = tester
          .getTopLeft(
            find.widgetWithText(TextField, 'Rechercher un personnage'),
          )
          .dy;

      expect(
        headerY,
        lessThan(bannerY),
        reason: 'la bannière doit être sous l\'en-tête',
      );
      expect(
        bannerY,
        lessThan(searchY),
        reason:
            'la bannière doit être au-dessus de la barre de '
            'recherche',
      );
    });

    testWidgets(
      'invisible quand une mise à jour est obligatoire (c\'est l\'écran '
      'bloquant `ForceUpdateScreen` qui prend le relais avant même '
      'd\'atteindre cet écran, jamais la bannière)',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(
          buildTestWidget(
            appVersionRepository: _FakeAppVersionRepository(
              const AppVersionRow(
                minimumSupportedVersion: '0.5.0',
                latestVersion: '0.6.0',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nouvelle version disponible'), findsNothing);
      },
    );
  });

  group('mode sélection multiple + suppression groupée', () {
    const twoCharacters = [
      CharacterSummary(id: '1', name: 'Halltesse Ambrelune', level: 5, xp: 0),
      CharacterSummary(id: '2', name: 'Borgan Pierrefort', level: 3, xp: 0),
    ];

    testWidgets(
      'bouton de sélection désactivé (sans effet au tap) quand la liste '
      'visible est vide',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.checklist), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('Annuler'), findsNothing);
      },
    );

    testWidgets(
      'bouton de sélection désactivé pendant le chargement de la liste',
      (tester) async {
        fakeCharacterRepository.completer = Completer<List<CharacterSummary>>();

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        await tester.tap(find.byIcon(Icons.checklist), warnIfMissed: false);
        await tester.pump();

        expect(find.text('Annuler'), findsNothing);
      },
    );

    testWidgets(
      'bouton de sélection désactivé quand une recherche/un filtre ne '
      'laisse aucun personnage visible (liste non vide côté serveur, mais '
      'rien à sélectionner dans l\'état filtré actuel)',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = twoCharacters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'Zarbingle introuvable',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('AUCUN RÉSULTAT'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.checklist), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('Annuler'), findsNothing);
      },
    );

    testWidgets(
      'tap sur le bouton de sélection : masque filtre/sélection, affiche '
      'une case à cocher par carte et la barre d\'action du bas',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = twoCharacters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.checklist), findsNothing);
        expect(find.byIcon(Icons.filter_list), findsNothing);
        expect(find.byType(SelectionCheckbox), findsNWidgets(2));
        expect(find.text('Aucun personnage sélectionné'), findsOneWidget);
        expect(find.text('+ CRÉER'), findsNothing);
      },
    );

    testWidgets(
      'taper une carte en mode sélection coche/décoche sans naviguer, met à '
      'jour le compteur',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = twoCharacters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Halltesse Ambrelune'));
        await tester.pumpAndSettle();

        expect(find.text('1 personnage sélectionné'), findsOneWidget);
        expect(find.text('Fiche personnage 1'), findsNothing);

        await tester.tap(find.text('Borgan Pierrefort'));
        await tester.pumpAndSettle();
        expect(find.text('2 personnages sélectionnés'), findsOneWidget);

        // Re-taper désélectionne.
        await tester.tap(find.text('Halltesse Ambrelune'));
        await tester.pumpAndSettle();
        expect(find.text('1 personnage sélectionné'), findsOneWidget);
      },
    );

    testWidgets('"Annuler" sort du mode sélection et désélectionne tout', (
      tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = twoCharacters;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Halltesse Ambrelune'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectionCheckbox), findsNothing);
      expect(find.text('+ CRÉER'), findsOneWidget);

      // Rentrer de nouveau en mode sélection reconfirme que tout a bien
      // été désélectionné (pas seulement masqué).
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();
      expect(find.text('Aucun personnage sélectionné'), findsOneWidget);
    });

    testWidgets('bouton "Supprimer" désactivé tant qu\'aucun personnage n\'est '
        'sélectionné', (tester) async {
      fakeCharacterRepository.charactersToReturn = twoCharacters;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUPPRIMER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(fakeCharacterRepository.deleteCharacterCalls, isEmpty);
    });

    testWidgets('un seul personnage sélectionné : confirmation au singulier, '
        'confirmer appelle deleteCharacter et sort du mode sélection', (
      tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = twoCharacters;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Halltesse Ambrelune'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUPPRIMER'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer Halltesse Ambrelune ?'), findsOneWidget);

      fakeCharacterRepository.charactersToReturn = [twoCharacters[1]];
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(fakeCharacterRepository.deleteCharacterCalls, ['1']);
      expect(find.text('Annuler'), findsNothing);
      expect(find.text('+ CRÉER'), findsOneWidget);
    });

    testWidgets(
      'plusieurs personnages sélectionnés : confirmation au pluriel avec '
      'le compte',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = twoCharacters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Halltesse Ambrelune'));
        await tester.tap(find.text('Borgan Pierrefort'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('SUPPRIMER'));
        await tester.pumpAndSettle();

        expect(find.text('Supprimer ces 2 personnages ?'), findsOneWidget);

        await tester.tap(find.text('ANNULER'));
        await tester.pumpAndSettle();

        expect(fakeCharacterRepository.deleteCharacterCalls, isEmpty);
        // Le mode sélection reste actif après une annulation du dialogue.
        expect(find.text('2 personnages sélectionnés'), findsOneWidget);
      },
    );

    testWidgets(
      'échec total hors ligne (WriteOutcome.rejectedOffline pour les deux) : '
      'SnackBar hors-ligne, le mode sélection reste actif avec les deux '
      'toujours cochés',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = twoCharacters;
        fakeCharacterRepository.deleteOutcomeByCharacterId['1'] =
            WriteOutcome.rejectedOffline;
        fakeCharacterRepository.deleteOutcomeByCharacterId['2'] =
            WriteOutcome.rejectedOffline;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Halltesse Ambrelune'));
        await tester.tap(find.text('Borgan Pierrefort'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('SUPPRIMER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer (2)'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining("n'a pas pu être enregistrée"),
          findsOneWidget,
        );
        expect(find.text('2 personnages sélectionnés'), findsOneWidget);
      },
    );

    testWidgets(
      'échec partiel : SnackBar récapitulatif, le mode sélection reste '
      'actif avec seulement le personnage en échec encore coché',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = twoCharacters;
        fakeCharacterRepository.deleteErrorByCharacterId['2'] =
            const CharacterFailure('boom');

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Halltesse Ambrelune'));
        await tester.tap(find.text('Borgan Pierrefort'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('SUPPRIMER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer (2)'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            '1 personnage supprimé, 1 personnage n\'a pas pu être supprimé.',
          ),
          findsOneWidget,
        );
        // Un seul encore sélectionné (celui en échec) : le mode sélection
        // reste actif.
        expect(find.text('1 personnage sélectionné'), findsOneWidget);
      },
    );

    testWidgets(
      'échec partiel avec au moins deux succès et deux échecs : SnackBar '
      'récapitulatif utilisant la forme "other" (pluriel ICU) des deux '
      'messages `characterListDeleteSelectionSucceededLabel`/'
      '`...FailedLabel`, jamais exercée par le scénario à 2 personnages '
      'ci-dessus (singulier des deux côtés)',
      (tester) async {
        const fourCharacters = [
          CharacterSummary(
            id: '1',
            name: 'Halltesse Ambrelune',
            level: 5,
            xp: 0,
          ),
          CharacterSummary(id: '2', name: 'Borgan Pierrefort', level: 3, xp: 0),
          CharacterSummary(id: '3', name: 'Sylvi Aubefeuille', level: 1, xp: 0),
          CharacterSummary(id: '4', name: 'Kaeloth', level: 2, xp: 0),
        ];
        fakeCharacterRepository.charactersToReturn = fourCharacters;
        fakeCharacterRepository.deleteErrorByCharacterId['3'] =
            const CharacterFailure('boom');
        fakeCharacterRepository.deleteErrorByCharacterId['4'] =
            const CharacterFailure('boom');

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Halltesse Ambrelune'));
        await tester.tap(find.text('Borgan Pierrefort'));
        await tester.pumpAndSettle();
        // "Sylvi Aubefeuille" et "Kaeloth" (3e/4e cartes) ne sont pas
        // forcément visibles sans scroll sur la taille d'écran de test :
        // `ensureVisible` fait défiler la liste avant de taper, même
        // principe que `dragUntilVisible` utilisé pour la sheet "FILTRER"
        // plus haut dans ce fichier.
        await tester.ensureVisible(find.text('Sylvi Aubefeuille'));
        await tester.tap(find.text('Sylvi Aubefeuille'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Kaeloth'));
        await tester.tap(find.text('Kaeloth'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('SUPPRIMER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer (4)'));
        await tester.pumpAndSettle();

        // Deux succès ("1" et "2") et deux échecs ("3" et "4") : les deux
        // segments du message récapitulatif passent par la forme "other"
        // (`{count} personnages supprimés`/`{count} personnages n'ont pas
        // pu être supprimés`), jamais atteinte par le test "échec partiel"
        // ci-dessus (1 succès, 1 échec, forme `=1` des deux côtés).
        expect(
          find.text(
            '2 personnages supprimés, 2 personnages n\'ont pas pu être '
            'supprimés.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'échec partiel : le personnage dont la suppression a réussi disparaît '
      'bien de la liste visible une fois charactersProvider invalidé (pas '
      'seulement le compteur/la sélection, voir le test ci-dessus) — simule '
      'côté serveur ce que `deleteCharacter` a réellement fait pour "1"',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = twoCharacters;
        fakeCharacterRepository.deleteErrorByCharacterId['2'] =
            const CharacterFailure('boom');

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Halltesse Ambrelune'));
        await tester.tap(find.text('Borgan Pierrefort'));
        await tester.pumpAndSettle();

        // Le refetch déclenché par `ref.invalidate(charactersProvider)`
        // appelle à nouveau `fetchCharacters` : seul "2" (Borgan, en échec)
        // doit encore exister côté serveur une fois "1" réellement
        // supprimé.
        fakeCharacterRepository.charactersToReturn = [twoCharacters[1]];

        await tester.tap(find.text('SUPPRIMER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer (2)'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsNothing);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        // Toujours cochée (personnage en échec) : la case à cocher doit
        // rester visible, pas de doublon ni de carte fantôme.
        expect(find.byType(SelectionCheckbox), findsOneWidget);
      },
    );

    testWidgets(
      'dette technique D89 : taper une carte pendant qu\'une suppression '
      'groupée est en cours (_isDeletingSelection == true) ne modifie pas '
      'la sélection — seul le tap/clic long de bascule est désactivé, pas '
      'besoin d\'attendre la fin de l\'appel réseau pour le constater',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = twoCharacters;
        fakeCharacterRepository.deleteCharacterGate = Completer<void>();

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Halltesse Ambrelune'));
        await tester.pumpAndSettle();
        expect(find.text('1 personnage sélectionné'), findsOneWidget);

        await tester.tap(find.text('SUPPRIMER'));
        await tester.pumpAndSettle();
        expect(find.text('Supprimer Halltesse Ambrelune ?'), findsOneWidget);
        await tester.tap(find.text('Supprimer'));
        // Pas de `pumpAndSettle` ici : une fois la suppression "en cours"
        // (`_isDeletingSelection == true`), `DestructiveButton.isLoading`
        // affiche un `CircularProgressIndicator` qui s'anime indéfiniment
        // tant que [_FakeCharacterRepository.deleteCharacterGate] n'est pas
        // complété — `pumpAndSettle` ne se stabiliserait donc jamais. Une
        // poignée de frames suffit à fermer le dialogue de confirmation et
        // à atteindre l'état "suppression en cours".
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap sur l'autre carte (non sélectionnée) pendant l'attente :
        // avant le correctif, cela l'aurait cochée (bascule normale en
        // mode sélection) — désormais sans effet.
        await tester.tap(find.text('Borgan Pierrefort'), warnIfMissed: false);
        await tester.pump();
        expect(find.text('1 personnage sélectionné'), findsOneWidget);
        expect(find.text('2 personnages sélectionnés'), findsNothing);

        // Un clic long pendant l'attente n'a pas plus d'effet (même
        // callback que le tap en mode sélection).
        await tester.longPress(
          find.text('Borgan Pierrefort'),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(find.text('1 personnage sélectionné'), findsOneWidget);

        // Débloque la suppression : l'écran revient à son état normal,
        // rien n'a jamais été perdu ni corrompu par les taps ignorés
        // ci-dessus.
        fakeCharacterRepository.deleteCharacterGate!.complete();
        await tester.pumpAndSettle();

        expect(fakeCharacterRepository.deleteCharacterCalls, ['1']);
        expect(find.text('Annuler'), findsNothing);
        expect(find.text('+ CRÉER'), findsOneWidget);
      },
    );
  });

  group('clic long sur une carte (hors mode sélection) : menu d\'actions', () {
    testWidgets(
      'ouvre la sheet "Actions de personnage" (titre = nom du personnage)',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(
            id: '1',
            name: 'Halltesse Ambrelune',
            raceName: 'Elfe',
            className: 'Magicienne',
            level: 5,
            xp: 0,
          ),
        ];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(CharacterCard));
        await tester.pumpAndSettle();

        // 2 occurrences : la carte (toujours visible sous la sheet) et le
        // sous-titre de la sheet elle-même.
        expect(find.text('Elfe · Magicienne · Niv. 5'), findsNWidgets(2));
        expect(find.text('Modifier'), findsOneWidget);
        expect(find.text('Supprimer le personnage'), findsOneWidget);
      },
    );

    testWidgets(
      'en mode sélection multiple, le clic long bascule la sélection au '
      'lieu d\'ouvrir la sheet (spec de la tâche)',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(
            id: '1',
            name: 'Halltesse Ambrelune',
            level: 5,
            xp: 0,
          ),
        ];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(CharacterCard));
        await tester.pumpAndSettle();

        // La sheet ne s'est pas ouverte : pas d'action "Modifier"/"Supprimer
        // le personnage" affichée, et le compteur de sélection reflète bien
        // la bascule.
        expect(find.text('Modifier'), findsNothing);
        expect(find.text('Supprimer le personnage'), findsNothing);
        expect(find.text('1 personnage sélectionné'), findsOneWidget);
      },
    );
  });

  group('bandeau de synchro et retour Android (T2 du chantier hors-ligne)', () {
    late AppDatabase db;
    late FakeConnectivityChecker connectivity;
    late PendingCharacterWriteQueue queue;
    late List<MethodCall> platformCalls;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      connectivity = FakeConnectivityChecker();
      queue = PendingCharacterWriteQueue(db);
      platformCalls = [];
    });

    tearDown(() async {
      await connectivity.close();
      await db.close();
    });

    List<Override> syncOverrides() => [
      appDatabaseProvider.overrideWithValue(db),
      syncOwnerIdProvider.overrideWithValue('owner-1'),
      connectivityCheckerProvider.overrideWithValue(connectivity),
    ];

    Future<void> flushDb(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    Future<void> enqueue(WidgetTester tester, String characterId) async {
      await tester.runAsync(
        () => queue.enqueue(
          characterId: characterId,
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.hp,
          targetId: '',
          payload: {'currentHp': 1, 'temporaryHp': 0},
        ),
      );
      await flushDb(tester);
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(seconds: 10));
    }

    void mockPlatform(WidgetTester tester) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    int popCalls() => platformCalls
        .where((call) => call.method == 'SystemNavigator.pop')
        .length;

    Future<void> addAlert(
      WidgetTester tester, {
      SyncAlertKind kind = SyncAlertKind.abandon,
      String name = 'Aria',
    }) => tester.runAsync(
      () => SyncAlertStore(db).add(
        ownerId: 'owner-1',
        kind: kind,
        characterId: 'c1',
        characterName: name,
        dataKind: 'hp',
        serverValue: {'currentHp': 7, 'maxHp': 12},
      ),
    );

    final updateSuggested = _FakeAppVersionRepository(
      const AppVersionRow(
        minimumSupportedVersion: '0.1.0',
        latestVersion: '0.5.0',
      ),
    );

    testWidgets('règle 8 : le bandeau de synchro est au-dessus de la mise à '
        'jour suggérée et de la recherche', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];
      await addAlert(tester);

      await tester.pumpWidget(
        buildTestWidget(
          extraOverrides: syncOverrides(),
          appVersionRepository: updateSuggested,
        ),
      );
      await tester.pumpAndSettle();
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));

      final headerBottom = tester
          .getBottomLeft(find.text('TES AVENTURIERS'))
          .dy;
      final alertTop = tester.getTopLeft(find.byType(AlertBanner)).dy;
      final updateTop = tester
          .getTopLeft(find.text('Nouvelle version disponible'))
          .dy;
      final searchTop = tester
          .getTopLeft(
            find.widgetWithText(TextField, 'Rechercher un personnage'),
          )
          .dy;
      expect(headerBottom, lessThan(alertTop));
      expect(alertTop, lessThan(updateTop));
      expect(updateTop, lessThan(searchTop));
      await finish(tester);
    });

    testWidgets('règle 8 : 360 dp x police 2,0, alerte + mise à jour '
        'suggérée : aucun débordement', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      fakeCharacterRepository.charactersToReturn = const [];
      await addAlert(
        tester,
        kind: SyncAlertKind.conflict,
        name: 'Halltesse Ambrelune',
      );

      await tester.pumpWidget(
        buildTestWidget(
          textScale: 2,
          extraOverrides: syncOverrides(),
          appVersionRepository: updateSuggested,
        ),
      );
      await tester.pumpAndSettle();
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('décision (a) : la liste n\'affiche pas « Hors ligne » sans '
        'modification en attente, mais l\'affiche avec le TOTAL du compte '
        'dès N > 0', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];
      await tester.pumpWidget(buildTestWidget(extraOverrides: syncOverrides()));
      await tester.pumpAndSettle();
      await flushDb(tester);

      connectivity.goOffline();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(InfoBanner), findsNothing);

      await enqueue(tester, 'c1');
      await enqueue(tester, 'c2');
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Hors ligne · 2 modifications en attente'),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('règle 9 : retour Android sans modification en attente -> '
        'pas de dialogue, l\'app quitte', (tester) async {
      mockPlatform(tester);
      fakeCharacterRepository.charactersToReturn = const [];
      await tester.pumpWidget(buildTestWidget(extraOverrides: syncOverrides()));
      await tester.pumpAndSettle();
      await flushDb(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text("Quitter l'app ?"), findsNothing);
      expect(popCalls(), 1);
      await finish(tester);
    });

    testWidgets('règle 9 : retour Android avec N > 0 -> dialogue ; « Rester » '
        'ferme sans quitter, « Quitter quand même » quitte', (tester) async {
      mockPlatform(tester);
      fakeCharacterRepository.charactersToReturn = const [];
      await tester.pumpWidget(buildTestWidget(extraOverrides: syncOverrides()));
      await tester.pumpAndSettle();
      await enqueue(tester, 'c1');
      await tester.pump(const Duration(milliseconds: 300));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text("Quitter l'app ?"), findsOneWidget);
      expect(
        find.textContaining("1 modification en attente d'envoi."),
        findsOneWidget,
      );
      expect(popCalls(), 0);

      await tester.tap(find.text('RESTER'));
      await tester.pumpAndSettle();
      expect(find.text("Quitter l'app ?"), findsNothing);
      expect(popCalls(), 0);

      // Un tap hors du dialogue vaut « Rester ».
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text("Quitter l'app ?"), findsNothing);
      expect(popCalls(), 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('QUITTER QUAND MÊME'));
      await tester.pumpAndSettle();
      expect(popCalls(), 1);
      await finish(tester);
    });
  });

  group('locale anglaise', () {
    // Même rationale que `login_screen_test.dart`/`profile_screen_test.dart`
    // (chantier "traduction de l'app" Phase B) : vérifie qu'un texte anglais
    // s'affiche réellement, pas seulement que l'écran ne plante pas.
    // Échantillon représentatif plutôt qu'exhaustif (en-tête, recherche,
    // état vide, carte, sheet de filtre) — chaque widget a déjà sa propre
    // couverture anglaise dédiée dans son fichier de test.
    testWidgets('en-tête, barre de recherche et carte personnage en anglais', (
      tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '1',
          name: 'Halltesse Ambrelune',
          className: 'Magicienne',
          level: 5,
          xp: 7000,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('YOUR ADVENTURERS'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Search for a character'),
        findsOneWidget,
      );
      expect(find.text('Magicienne · Lvl. 5'), findsOneWidget);
    });

    testWidgets('état vide "aucun personnage" en anglais', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('NO ADVENTURERS YET'), findsOneWidget);
      expect(
        find.textContaining('Create your first character'),
        findsOneWidget,
      );
      expect(find.text('+ CREATE'), findsOneWidget);
      expect(find.text('IMPORT XML'), findsOneWidget);
    });

    testWidgets('sheet de filtre en anglais', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '1',
          name: 'Halltesse Ambrelune',
          className: 'Magicien',
          level: 5,
          xp: 7000,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(_filterButton());
      await tester.pumpAndSettle();

      expect(find.text('FILTER AND SORT'), findsOneWidget);
      await _scrollFilterSheetTo(tester, find.text('Dead'));
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('Alive'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Dead'), findsOneWidget);
    });

    testWidgets('écran "Connexion impossible" en anglais', (tester) async {
      fakeCharacterRepository.errorToThrow = const CharacterFailure('boom');

      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('CONNECTION'), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.text('Continue offline'), findsOneWidget);
    });
  });

  group('police système agrandie (F21, `docs/retours-utilisateurs.md`)', () {
    const surfaces = <Size>[
      Size(360, 640),
      Size(320, 568),
      Size(480, 800),
      Size(320, 533),
    ];
    const scales = <double>[1.3, 2.0];

    for (final surface in surfaces) {
      for (final scale in scales) {
        final label =
            '${surface.width.toInt()}x${surface.height.toInt()} '
            'police x$scale';

        testWidgets('liste + bandeau de mise à jour, $label : aucun '
            'débordement', (tester) async {
          fakeCharacterRepository.charactersToReturn = const [
            CharacterSummary(
              id: '1',
              name: 'Halltesse Ambrelune',
              raceName: 'Elfe',
              className: 'Magicienne',
              level: 5,
              xp: 7000,
            ),
            CharacterSummary(
              id: '2',
              name: 'Borgan Pierrefort',
              raceName: 'Nain',
              className: 'Guerrier',
              level: 3,
              xp: 1200,
            ),
          ];
          tester.view.physicalSize = surface;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            buildTestWidget(
              textScale: scale,
              appVersionRepository: _FakeAppVersionRepository(
                const AppVersionRow(
                  minimumSupportedVersion: '0.1.0',
                  latestVersion: '0.5.0',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Mettre à jour'), findsOneWidget);
        });

        testWidgets('état vide + bandeau, $label : aucun débordement', (
          tester,
        ) async {
          fakeCharacterRepository.charactersToReturn = const [];
          tester.view.physicalSize = surface;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            buildTestWidget(
              textScale: scale,
              appVersionRepository: _FakeAppVersionRepository(
                const AppVersionRow(
                  minimumSupportedVersion: '0.1.0',
                  latestVersion: '0.5.0',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  // Refonte du 12/11/2026 : tout défile ensemble dans UN `CustomScrollView`
  // (titre, bandeaux, recherche, cartes) ; restent fixes le bandeau de synchro
  // (épinglé), la recherche (épinglée sauf police > x1,3 ou hauteur réduite) et
  // le pied Créer/Importer. Polices réelles : les largeurs de mots de la police
  // de test (un em par glyphe) fausseraient les contrôles de débordement.
  group('un seul défilement (refonte de la liste, 12/11/2026)', () {
    setUpAll(() async {
      await _loadFont(
        'WorkSans',
        'assets/fonts/WorkSans-VariableFont_wght.ttf',
      );
      await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
    });

    setUp(() => SharedPreferences.setMockInitialValues({}));

    final updateSuggested = _FakeAppVersionRepository(
      const AppVersionRow(
        minimumSupportedVersion: '0.1.0',
        latestVersion: '0.5.0',
      ),
    );

    List<CharacterSummary> many(int count) => [
      for (var i = 0; i < count; i++)
        CharacterSummary(
          id: 'id$i',
          name: 'Perso ${i.toString().padLeft(2, '0')}',
          raceName: 'Elfe',
          className: 'Magicienne',
          level: 3,
          xp: 1200,
        ),
    ];

    void surface(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> pumpList(
      WidgetTester tester, {
      double scale = 1.0,
      AppVersionRepository? versions,
      Locale locale = const Locale('fr'),
    }) async {
      await tester.pumpWidget(
        buildTestWidget(
          textScale: scale,
          appVersionRepository: versions,
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder mainScrollable() => find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;

    double offset(WidgetTester tester) =>
        tester.state<ScrollableState>(mainScrollable()).position.pixels;

    /// Glisse depuis le bas de la zone de défilement (jamais depuis le
    /// bandeau de synchro plafonné, qui défile en interne).
    Future<void> scrollBy(WidgetTester tester, double dy) async {
      final rect = tester.getRect(find.byType(CustomScrollView));
      await tester.dragFrom(
        Offset(rect.center.dx, rect.bottom - 20),
        Offset(0, -dy),
      );
      await tester.pumpAndSettle();
    }

    Future<void> scrollUntilText(WidgetTester tester, String text) async {
      for (var i = 0; i < 80 && find.text(text).evaluate().isEmpty; i++) {
        await scrollBy(tester, 120);
      }
      expect(find.text(text), findsOneWidget);
    }

    Finder searchField() => find.byType(TextField, skipOffstage: false);
    Finder footerCreate() => find.byType(PrimaryButton);
    Finder footerImport() => find.byType(SecondaryButton);

    /// Nombre de `Scrollable` verticaux hors champ de texte (le `TextField`
    /// embarque son propre `Scrollable` interne).
    int scrollableCount() => find
        .byType(Scrollable)
        .evaluate()
        .where((e) => e.findAncestorWidgetOfExactType<TextField>() == null)
        .length;

    void expectWithinScreen(WidgetTester tester, Finder finder, Size size) {
      final rect = tester.getRect(finder.first);
      expect(rect.left, greaterThanOrEqualTo(-0.5), reason: '$finder');
      expect(
        rect.right,
        lessThanOrEqualTo(size.width + 0.5),
        reason: '$finder',
      );
    }

    group('structure', () {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets('x$scale sur 360x640 : un seul Scrollable, aucun pied '
            'défilant', (tester) async {
          surface(tester, const Size(360, 640));
          fakeCharacterRepository.charactersToReturn = many(12);
          await pumpList(tester, scale: scale, versions: updateSuggested);

          expect(tester.takeException(), isNull);
          expect(find.byType(CustomScrollView), findsOneWidget);
          expect(scrollableCount(), 1);
          expect(
            find.byKey(const Key('characterListFooterScroll')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('characterListSyncBandScroll')),
            findsNothing,
          );
        });
      }

      testWidgets('x2,0 : le seul défilement en plus est le pied plafonné', (
        tester,
      ) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(12);
        await pumpList(tester, scale: 2, versions: updateSuggested);

        expect(tester.takeException(), isNull);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(
          find.byKey(const Key('characterListFooterScroll')),
          findsOneWidget,
        );
        expect(scrollableCount(), 2);
      });
    });

    group('recherche', () {
      testWidgets('épinglée en usage normal : reste en haut après défilement', (
        tester,
      ) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester, versions: updateSuggested);

        final before = tester.getTopLeft(searchField()).dy;
        await scrollBy(tester, 900);

        expect(offset(tester), greaterThan(500));
        // Le titre et le bandeau de mise à jour ont quitté l'écran, la
        // recherche reste visible, plus haut qu'avant.
        expect(
          tester
              .getBottomLeft(find.text('TES AVENTURIERS', skipOffstage: false))
              .dy,
          lessThan(1),
        );
        final after = tester.getTopLeft(searchField()).dy;
        expect(after, lessThan(before));
        expect(after, lessThan(80));
        expect(tester.getBottomLeft(searchField()).dy, greaterThan(0));
        // Et elle reste utilisable : un tap l'atteint.
        await tester.tap(searchField());
        await tester.pump();
        expect(
          tester
              .state<EditableTextState>(
                find.byType(EditableText, skipOffstage: false),
              )
              .widget
              .focusNode
              .hasFocus,
          isTrue,
        );
      });

      testWidgets('non épinglée au-delà de x1,3 : elle défile avec le reste', (
        tester,
      ) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester, scale: 1.5);

        expect(tester.getTopLeft(searchField()).dy, greaterThan(0));
        await scrollBy(tester, 900);

        expect(tester.getBottomLeft(searchField()).dy, lessThan(1));
        // De retour en haut, elle réapparaît.
        await scrollBy(tester, -2000);
        expect(offset(tester), 0);
        expect(tester.getTopLeft(searchField()).dy, greaterThan(0));
      });

      testWidgets('x1,3 reste épinglée (seuil strictement supérieur à 1,3)', (
        tester,
      ) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester, scale: 1.3);
        await scrollBy(tester, 900);

        expect(tester.getBottomLeft(searchField()).dy, greaterThan(0));
        expect(tester.getTopLeft(searchField()).dy, lessThan(100));
      });

      testWidgets('police agrandie : la saisie garde le focus et le texte '
          'quand le champ sort de l\'écran en défilant', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester, scale: 1.5);

        await tester.tap(searchField());
        await tester.pumpAndSettle();
        await tester.enterText(searchField(), 'Perso');
        await tester.pumpAndSettle();
        await scrollBy(tester, 1200);

        expect(tester.getBottomLeft(searchField()).dy, lessThan(1));
        final editable = tester.state<EditableTextState>(
          find.byType(EditableText, skipOffstage: false),
        );
        expect(editable.widget.focusNode.hasFocus, isTrue);
        expect(editable.widget.controller.text, 'Perso');
      });

      testWidgets('usage normal : la saisie garde le focus pendant un '
          'défilement', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester);

        await tester.tap(searchField());
        await tester.pumpAndSettle();
        await tester.enterText(searchField(), 'Perso');
        await tester.pumpAndSettle();
        await scrollBy(tester, 600);

        final editable = tester.state<EditableTextState>(
          find.byType(EditableText, skipOffstage: false),
        );
        expect(editable.widget.focusNode.hasFocus, isTrue);
        expect(editable.widget.controller.text, 'Perso');
      });

      testWidgets(
        'ensureVisible + tap (parcours des scénarios integration_test) '
        ': la carte reste atteignable sous la recherche épinglée',
        (tester) async {
          surface(tester, const Size(360, 640));
          fakeCharacterRepository.charactersToReturn = many(30);
          await pumpList(tester);

          await scrollUntilText(tester, 'Perso 20');
          await tester.ensureVisible(find.text('Perso 20'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Perso 20'));
          await tester.pumpAndSettle();

          expect(find.text('Fiche personnage id20'), findsOneWidget);
        },
      );

      testWidgets('changement de tri : pas de saut de défilement', (
        tester,
      ) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester);
        await scrollBy(tester, 500);
        final before = offset(tester);
        expect(before, greaterThan(300));

        await tester.tap(_filterButton());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nom (A → Z)'));
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(offset(tester), before);
      });
    });

    group('bandeaux', () {
      late AppDatabase db;
      late FakeConnectivityChecker connectivity;

      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        connectivity = FakeConnectivityChecker();
      });

      tearDown(() async {
        await connectivity.close();
        await db.close();
      });

      List<Override> syncOverrides() => [
        appDatabaseProvider.overrideWithValue(db),
        syncOwnerIdProvider.overrideWithValue('owner-1'),
        connectivityCheckerProvider.overrideWithValue(connectivity),
      ];

      Future<void> flushDb(WidgetTester tester) async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }

      Future<void> addAlert(WidgetTester tester) => tester.runAsync(
        () => SyncAlertStore(db).add(
          ownerId: 'owner-1',
          kind: SyncAlertKind.abandon,
          characterId: 'c1',
          characterName: 'Aria',
          dataKind: 'hp',
          serverValue: {'currentHp': 7, 'maxHp': 12},
        ),
      );

      Future<void> finish(WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(seconds: 10));
      }

      Future<void> pumpWithSync(
        WidgetTester tester, {
        double scale = 1.0,
        bool withUpdate = false,
      }) async {
        await tester.pumpWidget(
          buildTestWidget(
            textScale: scale,
            extraOverrides: syncOverrides(),
            appVersionRepository: withUpdate ? updateSuggested : null,
          ),
        );
        await tester.pumpAndSettle();
        await flushDb(tester);
        await tester.pump(const Duration(milliseconds: 300));
      }

      testWidgets('synchro épinglé : toujours en haut après défilement, alors '
          'que le bandeau de mise à jour part avec le reste', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await addAlert(tester);
        await pumpWithSync(tester, withUpdate: true);

        expect(find.byType(AlertBanner), findsOneWidget);
        await scrollBy(tester, 1200);

        expect(offset(tester), greaterThan(800));
        final alertTop = tester.getTopLeft(find.byType(AlertBanner)).dy;
        expect(alertTop, greaterThanOrEqualTo(0));
        expect(alertTop, lessThan(60));
        expect(
          tester
              .getBottomLeft(
                find.text('Nouvelle version disponible', skipOffstage: false),
              )
              .dy,
          lessThan(1),
        );
        // La recherche est épinglée juste dessous.
        expect(
          tester.getTopLeft(searchField()).dy,
          greaterThanOrEqualTo(
            tester.getBottomLeft(find.byType(AlertBanner)).dy,
          ),
        );
        await finish(tester);
      });

      testWidgets('rien à dire : aucun bandeau et aucune hauteur réservée en '
          'haut après défilement', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpWithSync(tester);

        expect(find.byType(AlertBanner), findsNothing);
        expect(find.byType(InfoBanner), findsNothing);
        expect(
          tester
              .getSize(find.byType(SyncStatusBanner, skipOffstage: false))
              .height,
          0,
        );
        await scrollBy(tester, 1200);
        // La recherche est collée en haut, rien d'épinglé au-dessus.
        expect(tester.getTopLeft(searchField()).dy, lessThan(30));
        await finish(tester);
      });

      Future<void> addSecondAlert(WidgetTester tester) => tester.runAsync(
        () => SyncAlertStore(db).add(
          ownerId: 'owner-1',
          kind: SyncAlertKind.abandon,
          characterId: 'c2',
          characterName: 'Borgan Pierrefort',
          dataKind: 'hp',
          serverValue: {'currentHp': 3, 'maxHp': 20},
        ),
      );

      for (final size in const [Size(360, 640), Size(320, 568)]) {
        testWidgets('x2,0 sur ${size.width.toInt()}x${size.height.toInt()} : '
            'alerte de synchro longue + mise à jour, sans chevauchement et '
            'avec de la place pour la liste', (tester) async {
          surface(tester, size);
          fakeCharacterRepository.charactersToReturn = many(8);
          await addAlert(tester);
          await addSecondAlert(tester);
          await pumpWithSync(tester, scale: 2, withUpdate: true);

          expect(tester.takeException(), isNull);
          final band = find.byKey(const Key('characterListSyncBandScroll'));
          final update = find.text(
            'Nouvelle version disponible',
            skipOffstage: false,
          );
          final footer = find.byKey(const Key('characterListFooterScroll'));
          final bandRect = tester.getRect(band);
          final updateRect = tester.getRect(update);
          // Pas de chevauchement au repos : la mise à jour est sous le bandeau.
          expect(updateRect.top, greaterThanOrEqualTo(bandRect.bottom - 0.5));
          // Le bandeau reste plafonné à 30 %, avec défilement interne.
          expect(bandRect.height, lessThanOrEqualTo(size.height * 0.3 + 0.5));
          // Défilé jusqu'à ce que l'en-tête soit sorti, le bandeau reste
          // épinglé en haut : la zone de la liste (sous lui, au-dessus du pied)
          // garde au moins 40 % de la hauteur de l'écran.
          await scrollBy(tester, 150);
          final pinned = tester.getRect(band);
          expect(pinned.top, lessThan(1));
          final listArea = tester.getRect(footer).top - pinned.bottom;
          expect(listArea, greaterThanOrEqualTo(size.height * 0.4 - 0.5));
          expect(tester.takeException(), isNull);
          await finish(tester);
        });
      }

      testWidgets('x3,0 sur 320x568 : bandeau épinglé plafonné à 30 % de la '
          'hauteur, tout reste atteignable', (tester) async {
        surface(tester, const Size(320, 568));
        fakeCharacterRepository.charactersToReturn = many(8);
        await addAlert(tester);
        await pumpWithSync(tester, scale: 3, withUpdate: true);

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('characterListSyncBandScroll')),
          findsOneWidget,
        );
        expect(
          tester
              .getSize(find.byKey(const Key('characterListSyncBandScroll')))
              .height,
          lessThanOrEqualTo(568 * 0.3 + 0.5),
        );
        // Le dernier personnage reste atteignable en défilant.
        await scrollUntilText(tester, 'Perso 07');
        expect(tester.takeException(), isNull);
        await finish(tester);
      });
    });

    group('états centrés dans l\'espace restant', () {
      /// Écart vertical entre le centre de [content] et le centre de la zone
      /// située entre la recherche et le pied.
      double offCenter(WidgetTester tester, Rect content) {
        final top = tester.getBottomLeft(searchField()).dy;
        final bottom = tester.getTopLeft(footerCreate()).dy;
        return (content.center.dy - (top + bottom) / 2).abs();
      }

      testWidgets('chargement', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.completer = Completer();
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        final rect = tester.getRect(find.byType(CircularProgressIndicator));
        expect(offCenter(tester, rect), lessThan(12));
        expect(scrollableCount(), 1);
      });

      testWidgets('aucun personnage', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = const [];
        await pumpList(tester);

        final column = find
            .ancestor(
              of: find.textContaining('AUCUN AVENTURIER'),
              matching: find.byType(Column),
            )
            .first;
        expect(offCenter(tester, tester.getRect(column)), lessThan(12));
        expect(scrollableCount(), 1);
        expect(offset(tester), 0);
      });

      testWidgets('aucun résultat', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(3);
        await pumpList(tester);
        await tester.enterText(searchField(), 'zzzz');
        await tester.pumpAndSettle();

        final column = find
            .ancestor(
              of: find.textContaining('AUCUN RÉSULTAT'),
              matching: find.byType(Column),
            )
            .first;
        expect(offCenter(tester, tester.getRect(column)), lessThan(12));
        expect(scrollableCount(), 1);
        expect(offset(tester), 0);
      });

      testWidgets('aucun personnage, x2,0 sur 320x568 : contenu entier '
          'atteignable par le défilement unique', (tester) async {
        surface(tester, const Size(320, 568));
        fakeCharacterRepository.charactersToReturn = const [];
        await pumpList(tester, scale: 2, versions: updateSuggested);

        expect(tester.takeException(), isNull);
        await tester.dragUntilVisible(
          find.text(
            AppLocalizations.of(tester.element(find.byType(Scaffold).first))!
                .characterListEmptyBody,
          ),
          find.byType(CustomScrollView),
          const Offset(0, -100),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.ancestor(
            of: find.textContaining('AUCUN AVENTURIER'),
            matching: find.byType(SingleChildScrollView),
          ),
          findsNothing,
        );
      });
    });

    group('pied fixe', () {
      testWidgets('usage normal : côte à côte, immobile pendant le '
          'défilement', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester);

        final create = tester.getRect(footerCreate());
        final import = tester.getRect(footerImport());
        expect(create.top, import.top);
        expect(create.right, lessThan(import.left));
        expect(create.bottom, lessThanOrEqualTo(640));

        await scrollBy(tester, 900);
        expect(tester.getRect(footerCreate()), create);
        expect(tester.getRect(footerImport()), import);
      });

      testWidgets('au-delà de x1,3 : boutons en colonne pleine largeur', (
        tester,
      ) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester, scale: 1.5);

        final create = tester.getRect(footerCreate());
        final import = tester.getRect(footerImport());
        expect(create.left, import.left);
        expect(create.width, import.width);
        expect(create.width, greaterThan(360 - 2 * 22 - 1));
        expect(create.bottom, lessThanOrEqualTo(import.top));
        expect(import.bottom, lessThanOrEqualTo(640));
      });

      testWidgets('plafond FORCÉ (x3,0 sur 320x300) : pied limité à 35 %, '
          'défilement interne réel, contenu complet atteignable', (
        tester,
      ) async {
        surface(tester, const Size(320, 300));
        fakeCharacterRepository.charactersToReturn = many(4);
        await pumpList(tester, scale: 3);

        expect(tester.takeException(), isNull);
        final footer = find.byKey(const Key('characterListFooterScroll'));
        final footerRect = tester.getRect(footer);
        // Hauteur naturelle des deux boutons en colonne à x3,0 > 105 dp :
        // c'est bien le plafond qui borne le pied.
        expect(footerRect.height, closeTo(300 * 0.35, 0.5));
        final position = tester
            .state<ScrollableState>(
              find.descendant(of: footer, matching: find.byType(Scrollable)),
            )
            .position;
        expect(position.maxScrollExtent, greaterThan(0));
        expect(position.pixels, 0);
        // Départ : « Importer » dépasse du pied (rogné).
        expect(
          tester.getRect(footerImport()).bottom,
          greaterThan(footerRect.bottom),
        );
        await tester.dragFrom(footerRect.center, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
        // Fin : « Importer » entièrement dans la fenêtre du pied.
        expect(
          tester.getRect(footerImport()).bottom,
          lessThanOrEqualTo(footerRect.bottom + 0.5),
        );
        expect(tester.takeException(), isNull);
      });

      for (final size in const [Size(360, 640), Size(320, 568)]) {
        testWidgets('x3,0 sur ${size.width.toInt()}x${size.height.toInt()} : '
            'pied sous le plafond de 35 %, boutons atteignables', (
          tester,
        ) async {
          surface(tester, size);
          fakeCharacterRepository.charactersToReturn = many(12);
          await pumpList(tester, scale: 3, versions: updateSuggested);

          expect(tester.takeException(), isNull);
          final footer = find.byKey(const Key('characterListFooterScroll'));
          expect(footer, findsOneWidget);
          expect(
            tester.getSize(footer).height,
            lessThanOrEqualTo(size.height * 0.35 + 0.5),
          );
          // Le pied est toujours visible : son bas est dans l'écran.
          expect(tester.getRect(footer).bottom, lessThanOrEqualTo(size.height));
          // Les deux boutons sont atteignables (défilement interne du pied).
          await tester.ensureVisible(footerImport());
          await tester.pumpAndSettle();
          expect(
            tester.getRect(footerImport()).bottom,
            lessThanOrEqualTo(size.height),
          );
          await tester.ensureVisible(footerCreate());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // La liste garde de la place : le haut du contenu reste visible.
          expect(tester.getRect(footer).top, greaterThan(size.height * 0.6));
        });
      }
    });

    group('mode sélection', () {
      testWidgets('barre d\'actions fixe en pied, recherche pleine largeur '
          'épinglée', (tester) async {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(30);
        await pumpList(tester);

        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        final bar = find.byType(CharacterSelectionActionBar);
        expect(bar, findsOneWidget);
        expect(footerCreate(), findsNothing);
        expect(find.byIcon(Icons.filter_list), findsNothing);
        final barRect = tester.getRect(bar);
        expect(barRect.bottom, lessThanOrEqualTo(640));

        await scrollBy(tester, 900);
        expect(tester.getRect(bar), barRect);
        expect(tester.getTopLeft(searchField()).dy, lessThan(80));

        // Cocher une carte fonctionne toujours après défilement.
        await tester.tap(find.byType(CharacterCard).hitTestable().first);
        await tester.pumpAndSettle();
        expect(find.text('1 personnage sélectionné'), findsOneWidget);
      });
    });

    group('mode sélection à police agrandie', () {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        for (final size in const [Size(320, 568), Size(360, 640)]) {
          for (final scale in <double>[1.0, 2.0, 3.0]) {
            testWidgets('${locale.languageCode} x$scale sur '
                '${size.width.toInt()}x${size.height.toInt()} : le texte '
                'passe sur des lignes lisibles, boutons >= 44 atteignables', (
              tester,
            ) async {
              surface(tester, size);
              fakeCharacterRepository.charactersToReturn = many(6);
              await pumpList(tester, scale: scale, locale: locale);

              await tester.tap(find.byIcon(Icons.checklist));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);

              final text = locale.languageCode == 'fr'
                  ? 'Aucun personnage sélectionné'
                  : 'No character selected';
              final count = find.text(text);
              expect(count, findsOneWidget);
              final paragraph = tester.renderObject<RenderParagraph>(count);
              var longest = 0.0;
              for (final word in text.split(' ')) {
                final painter = TextPainter(
                  text: TextSpan(text: word, style: paragraph.text.style),
                  textDirection: TextDirection.ltr,
                  textScaler: paragraph.textScaler,
                )..layout();
                longest = math.max(longest, painter.width);
                painter.dispose();
              }
              // Aucun mot coupé lettre par lettre : le paragraphe est au
              // moins aussi large que son plus long mot.
              expect(
                tester.getSize(count).width,
                greaterThanOrEqualTo(longest - 0.5),
              );
              // Le texte n'est jamais tronqué.
              expect(paragraph.didExceedMaxLines, isFalse);

              final cancel = find.text(
                locale.languageCode == 'fr' ? 'Annuler' : 'Cancel',
              );
              for (final target in [
                find.ancestor(of: cancel, matching: find.byType(InkWell)),
                find.byType(DestructiveButton),
              ]) {
                await tester.ensureVisible(target);
                await tester.pumpAndSettle();
                final rect = tester.getRect(target);
                expect(rect.height, greaterThanOrEqualTo(44));
                expect(rect.width, greaterThanOrEqualTo(44));
                expect(rect.left, greaterThanOrEqualTo(-0.5));
                expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
                expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
              }
              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    });

    group('en-tête (D174)', () {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        for (final scale in <double>[1.0, 2.0, 3.0]) {
          final width = scale == 1.0 ? 360.0 : 320.0;
          testWidgets(
            '${locale.languageCode} x$scale sur ${width.toInt()} dp : '
            'aucun débordement horizontal, boutons 44x44 dans l\'écran',
            (tester) async {
              surface(tester, Size(width, 568));
              fakeCharacterRepository.charactersToReturn = many(2);
              await pumpList(tester, scale: scale, locale: locale);

              expect(tester.takeException(), isNull);
              final title = find.text(
                locale.languageCode == 'fr'
                    ? 'TES AVENTURIERS'
                    : 'YOUR ADVENTURERS',
              );
              final tapBox = find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.constraints ==
                        const BoxConstraints.tightFor(width: 44, height: 44),
              );
              final groups = find.byIcon(Icons.groups_outlined);
              final profile = find.byIcon(Icons.person_outline);
              final titleRect = tester.getRect(title);
              final groupsRect = tester.getRect(
                find.ancestor(of: groups, matching: tapBox),
              );
              final profileRect = tester.getRect(
                find.ancestor(of: profile, matching: tapBox),
              );
              expect(groupsRect.size, const Size(44, 44));
              expect(profileRect.size, const Size(44, 44));
              for (final r in [titleRect, groupsRect, profileRect]) {
                expect(r.left, greaterThanOrEqualTo(0));
                expect(r.right, lessThanOrEqualTo(width + 0.5));
              }
              // Ni chevauchement, ni mot coupé : soit le titre est à gauche des
              // boutons, soit il est entièrement au-dessus.
              final buttonsLeft = groupsRect.left;
              final sideBySide = titleRect.right <= buttonsLeft + 0.5;
              final stacked = titleRect.bottom <= groupsRect.top + 0.5;
              expect(sideBySide || stacked, isTrue);
              // Le paragraphe est assez large pour son plus long mot (aucun mot
              // coupé en pleine largeur).
              final paragraph = tester.renderObject<RenderParagraph>(title);
              var longest = 0.0;
              for (final word
                  in (paragraph.text as TextSpan).toPlainText().split(' ')) {
                final painter = TextPainter(
                  text: TextSpan(text: word, style: paragraph.text.style),
                  textDirection: TextDirection.ltr,
                  textScaler: paragraph.textScaler,
                )..layout();
                longest = math.max(longest, painter.width);
                painter.dispose();
              }
              expect(paragraph.size.width, greaterThanOrEqualTo(longest - 0.5));
              if (scale == 1.0) expect(sideBySide, isTrue);
            },
          );
        }
      }
    });

    group('toutes tailles', () {
      for (final scale in <double>[1.3, 2.0, 3.0]) {
        testWidgets('x$scale sur 320x568 (vraies polices) : rien ne déborde, '
            'tout est atteignable', (tester) async {
          surface(tester, const Size(320, 568));
          fakeCharacterRepository.charactersToReturn = many(6);
          await pumpList(tester, scale: scale, versions: updateSuggested);

          expect(tester.takeException(), isNull);
          expect(find.text('Mettre à jour'), findsOneWidget);
          expect(
            tester.getRect(footerCreate()).right,
            lessThanOrEqualTo(320.5),
          );
          for (final finder in [
            searchField(),
            footerCreate(),
            footerImport(),
          ]) {
            expectWithinScreen(tester, finder, const Size(320, 568));
          }
          await scrollUntilText(tester, 'Perso 05');
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('état vide x3,0 sur 320x568 : aucune exception', (
        tester,
      ) async {
        surface(tester, const Size(320, 568));
        fakeCharacterRepository.charactersToReturn = const [];
        await pumpList(tester, scale: 3, versions: updateSuggested);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('clavier ouvert (x1,0 et x1,3) : le champ garde le focus '
        'malgré le passage d\'épinglé à défilant', (tester) async {
      for (final scale in <double>[1.0, 1.3]) {
        surface(tester, const Size(360, 640));
        fakeCharacterRepository.charactersToReturn = many(6);
        await pumpList(tester, scale: scale, versions: updateSuggested);
        await tester.tap(searchField());
        await tester.pumpAndSettle();

        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final editable = tester.state<EditableTextState>(
          find.byType(EditableText, skipOffstage: false),
        );
        expect(editable.widget.focusNode.hasFocus, isTrue);
        tester.view.resetViewInsets();
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('tablette 768x1024 : contenu limité à 600 dp et centré, '
        'boutons du pied côte à côte', (tester) async {
      surface(tester, const Size(768, 1024));
      fakeCharacterRepository.charactersToReturn = many(4);
      await pumpList(tester);

      final card = tester.getRect(find.byType(CharacterCard).first);
      expect(card.width, closeTo(600, 1));
      expect(card.center.dx, closeTo(384, 1));
      final create = tester.getRect(footerCreate());
      final import = tester.getRect(footerImport());
      expect(create.top, import.top);
      expect(create.left, closeTo(84, 1));
      expect(import.right, closeTo(684, 1));
      final search = tester.getRect(searchField());
      expect(search.left, closeTo(84, 1));
      // La barre de défilement vit au bord de l'écran : le défilement occupe
      // toute la largeur.
      expect(tester.getSize(find.byType(CustomScrollView)).width, 768);
    });
  });

  group('P18 — annuler l\'archivage', () {
    const halltesse = CharacterSummary(
      id: '1',
      name: 'Halltesse Ambrelune',
      level: 5,
      xp: 0,
    );
    const offlineMessage =
        'Hors ligne : cette action n\'a pas pu être enregistrée. '
        'Réessayez une fois reconnecté.';

    Future<void> pumpList(
      WidgetTester tester,
      List<CharacterSummary> characters,
    ) async {
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
    }

    /// Ouvre la sheet d'actions et tape [label]. Pas de `pumpAndSettle` après
    /// l'action : il laisserait le SnackBar expirer (6 s).
    Future<void> runAction(WidgetTester tester, String label) async {
      await tester.longPress(find.byType(CharacterCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> tapUndo(WidgetTester tester) async {
      await tester.tap(find.text('ANNULER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('archivage réussi : SnackBar « {nom} archivé » + Annuler, '
        'écriture serveur immédiate, liste rechargée', (tester) async {
      await pumpList(tester, const [halltesse]);
      final fetchesBefore = fakeCharacterRepository.fetchCallCount;

      await runAction(tester, 'Archiver ce personnage');

      expect(find.text('Halltesse Ambrelune archivé'), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);
      expect(fakeCharacterRepository.setArchivedCalls, [('1', true)]);
      expect(
        fakeCharacterRepository.fetchCallCount,
        greaterThan(fetchesBefore),
      );
      expect(find.text('ARCHIVÉ'), findsOneWidget);
    });

    testWidgets('Annuler : désarchive, invalide la liste, silencieux', (
      tester,
    ) async {
      await pumpList(tester, const [halltesse]);
      await runAction(tester, 'Archiver ce personnage');
      final fetchesBefore = fakeCharacterRepository.fetchCallCount;

      await tapUndo(tester);

      expect(fakeCharacterRepository.setArchivedCalls, [
        ('1', true),
        ('1', false),
      ]);
      expect(
        fakeCharacterRepository.fetchCallCount,
        greaterThan(fetchesBefore),
      );
      expect(find.text('ARCHIVÉ'), findsNothing);
      expect(find.text('Halltesse Ambrelune archivé'), findsNothing);
      expect(find.text('ANNULER'), findsNothing);
      expect(find.text(offlineMessage), findsNothing);
    });

    testWidgets('Annuler hors ligne : message dédié, le personnage reste '
        'archivé, liste non invalidée', (tester) async {
      await pumpList(tester, const [halltesse]);
      await runAction(tester, 'Archiver ce personnage');
      fakeCharacterRepository.setArchivedResults.add(
        WriteOutcome.rejectedOffline,
      );
      final fetchesBefore = fakeCharacterRepository.fetchCallCount;

      await tapUndo(tester);

      expect(find.text(offlineMessage), findsOneWidget);
      expect(fakeCharacterRepository.fetchCallCount, fetchesBefore);
      expect(find.text('ARCHIVÉ'), findsOneWidget);
    });

    testWidgets('Annuler en erreur : message générique, liste non invalidée', (
      tester,
    ) async {
      await pumpList(tester, const [halltesse]);
      await runAction(tester, 'Archiver ce personnage');
      fakeCharacterRepository.setArchivedResults.add(Exception('boom'));
      final fetchesBefore = fakeCharacterRepository.fetchCallCount;

      await tapUndo(tester);

      expect(
        find.text('Impossible de mettre à jour le statut. Réessayez.'),
        findsOneWidget,
      );
      expect(fakeCharacterRepository.fetchCallCount, fetchesBefore);
    });

    testWidgets('échec de l\'archivage : message d\'erreur, pas de SnackBar '
        'Annuler', (tester) async {
      await pumpList(tester, const [halltesse]);
      fakeCharacterRepository.setArchivedResults.add(
        const CharacterFailure('Refusé par le serveur.'),
      );

      await runAction(tester, 'Archiver ce personnage');

      expect(find.text('Refusé par le serveur.'), findsOneWidget);
      expect(find.text('Halltesse Ambrelune archivé'), findsNothing);
      expect(find.text('ANNULER'), findsNothing);
    });

    testWidgets('archivage hors ligne (refus actuel) : pas de SnackBar '
        'Annuler', (tester) async {
      await pumpList(tester, const [halltesse]);
      fakeCharacterRepository.setArchivedResults.add(
        WriteOutcome.rejectedOffline,
      );

      await runAction(tester, 'Archiver ce personnage');

      expect(find.text(offlineMessage), findsOneWidget);
      expect(find.text('ANNULER'), findsNothing);
    });

    testWidgets('désarchiver : aucun SnackBar d\'annulation', (tester) async {
      await pumpList(tester, [halltesse.copyWith(isArchived: true)]);

      await runAction(tester, 'Désarchiver');

      expect(fakeCharacterRepository.setArchivedCalls, [('1', false)]);
      expect(find.text('ANNULER'), findsNothing);
      expect(find.textContaining('archivé'), findsNothing);
    });

    testWidgets('annonce sémantique (liveRegion) avec mention du bouton', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpList(tester, const [halltesse]);

      await runAction(tester, 'Archiver ce personnage');

      expect(
        find.bySemanticsLabel(
          RegExp('Halltesse Ambrelune archivé. Bouton Annuler disponible.'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('en anglais : « archived » et « Undo »', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [halltesse];
      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await tester.longPress(find.byType(CharacterCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive this character'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Halltesse Ambrelune archived'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
    });

    testWidgets('le SnackBar survit au démontage de la liste : Annuler '
        'fonctionne encore', (tester) async {
      await pumpList(tester, const [halltesse]);
      await runAction(tester, 'Archiver ce personnage');
      expect(find.text('ANNULER'), findsOneWidget);

      // La liste est démontée (navigation par remplacement).
      GoRouter.of(tester.element(find.byType(CharacterListScreen)))
          .go('/profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CharacterListScreen), findsNothing);
      expect(find.text('Halltesse Ambrelune archivé'), findsOneWidget);

      await tapUndo(tester);

      expect(fakeCharacterRepository.setArchivedCalls, [
        ('1', true),
        ('1', false),
      ]);
      expect(tester.takeException(), isNull);
    });
  });

  group('P18 — tri de la liste', () {
    final owner = User(
      id: 'owner-1',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    );

    const characters = [
      CharacterSummary(id: 'b', name: 'Borgan', level: 1, xp: 0),
      CharacterSummary(id: 'e', name: 'émile', level: 1, xp: 0),
      CharacterSummary(id: 'a', name: 'Adèle', level: 1, xp: 0),
      CharacterSummary(
        id: 'arch',
        name: 'Aaron archivé',
        level: 1,
        xp: 0,
        isArchived: true,
      ),
      CharacterSummary(
        id: 'dead',
        name: 'Aaa mort',
        level: 1,
        xp: 0,
        isDead: true,
      ),
    ];

    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget screen({User? user}) => buildTestWidget(currentUser: user);

    // Surface haute : les 5 cartes doivent toutes être montées (liste
    // paresseuse).
    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    /// Noms affichés, du haut vers le bas.
    List<String> displayedOrder(WidgetTester tester) {
      final names = [for (final c in characters) c.name]
          .where((n) => find.text(n).evaluate().isNotEmpty)
          .toList();
      names.sort(
        (x, y) => tester
            .getTopLeft(find.text(x))
            .dy
            .compareTo(tester.getTopLeft(find.text(y)).dy),
      );
      return names;
    }

    Future<void> chooseSort(WidgetTester tester, String title) async {
      await tester.tap(_filterButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();
    }

    Finder activeDot() => find.descendant(
      of: _filterButton(),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle &&
            decoration.color == AppColors.goldEnd;
      }),
    );

    testWidgets('la feuille s\'appelle « FILTRER ET TRIER » et commence par '
        '« TRIER PAR » (3 options, sous-titres, Par défaut coché)', (
      tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(_filterButton());
      await tester.pumpAndSettle();

      expect(find.text('FILTRER ET TRIER'), findsOneWidget);
      expect(find.text('TRIER PAR'), findsOneWidget);
      expect(find.text('Par défaut'), findsOneWidget);
      expect(
        find.text('En jeu, archivés, puis morts, par date de création'),
        findsOneWidget,
      );
      expect(find.text('Nom (A → Z)'), findsOneWidget);
      expect(find.text('Au sein de chaque groupe'), findsOneWidget);
      expect(find.text('Dernière ouverture'), findsOneWidget);
      expect(
        find.text('Les plus récents d\'abord, au sein de chaque groupe'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SelectableOptionTile>(
              find.widgetWithText(SelectableOptionTile, 'Par défaut'),
            )
            .selected,
        isTrue,
      );
      // « TRIER PAR » est au-dessus de « STATUT ».
      expect(
        tester.getTopLeft(find.text('TRIER PAR')).dy,
        lessThan(tester.getTopLeft(find.text('STATUT')).dy),
      );
    });

    testWidgets('par nom : insensible à la casse/accents, groupes toujours '
        'en jeu / archivés / morts', (tester) async {
      tall(tester);
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(displayedOrder(tester), [
        'Borgan',
        'émile',
        'Adèle',
        'Aaron archivé',
        'Aaa mort',
      ]);

      await chooseSort(tester, 'Nom (A → Z)');

      expect(displayedOrder(tester), [
        'Adèle',
        'Borgan',
        'émile',
        'Aaron archivé',
        'Aaa mort',
      ]);
    });

    testWidgets('dernière ouverture : les plus récents d\'abord, jamais '
        'ouvert en dernier, groupes préservés', (tester) async {
      tall(tester);
      SharedPreferences.setMockInitialValues({
        'character_last_opened:owner-1': '{"e":300,"a":200,"arch":999}',
      });
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(screen(user: owner));
      await tester.pumpAndSettle();

      await chooseSort(tester, 'Dernière ouverture');

      expect(displayedOrder(tester), [
        'émile',
        'Adèle',
        'Borgan',
        'Aaron archivé',
        'Aaa mort',
      ]);
    });

    testWidgets('un tri seul : pastille active, valeur sémantique « Filtre ou '
        'tri actif », jamais l\'état vide de recherche', (tester) async {
      final handle = tester.ensureSemantics();
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(activeDot(), findsNothing);

      await chooseSort(tester, 'Nom (A → Z)');

      expect(activeDot(), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel('Filtrer et trier les personnages'),
            )
            .value,
        'Filtre ou tri actif',
      );
      expect(find.textContaining('AUCUN RÉSULTAT'), findsNothing);
      expect(find.text('Borgan'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Réinitialiser remet « Par défaut » et éteint la pastille', (
      tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await chooseSort(tester, 'Nom (A → Z)');
      expect(activeDot(), findsOneWidget);

      await tester.tap(_filterButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('RÉINITIALISER'));
      await tester.pump();
      expect(
        tester
            .widget<SelectableOptionTile>(
              find.widgetWithText(SelectableOptionTile, 'Par défaut'),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(activeDot(), findsNothing);
      expect(displayedOrder(tester).first, 'Borgan');
    });

    testWidgets('la réinitialisation de la recherche ne touche pas au tri', (
      tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await chooseSort(tester, 'Nom (A → Z)');

      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher un personnage'),
        'zzz',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('AUCUN RÉSULTAT'), findsOneWidget);
      await tester.tap(find.text('RÉINITIALISER'));
      await tester.pumpAndSettle();

      expect(activeDot(), findsOneWidget);
      expect(displayedOrder(tester).first, 'Adèle');
    });

    testWidgets('le choix de tri n\'est pas persisté : un nouvel écran '
        'repart sur « Par défaut »', (tester) async {
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await chooseSort(tester, 'Nom (A → Z)');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(activeDot(), findsNothing);
      expect(displayedOrder(tester).first, 'Borgan');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => !k.startsWith('character_last_opened')),
        isEmpty,
      );
    });

    testWidgets('purge : la liste chargée retire les identifiants disparus '
        'des horodatages', (tester) async {
      SharedPreferences.setMockInitialValues({
        'character_last_opened:owner-1': '{"e":300,"gone":5}',
      });
      fakeCharacterRepository.charactersToReturn = characters;
      await tester.pumpWidget(screen(user: owner));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('character_last_opened:owner-1'), '{"e":300}');
    });
  });
}
