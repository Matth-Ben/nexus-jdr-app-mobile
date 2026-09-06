// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(groupRepository)
final groupRepositoryProvider = GroupRepositoryProvider._();

final class GroupRepositoryProvider
    extends
        $FunctionalProvider<GroupRepository, GroupRepository, GroupRepository>
    with $Provider<GroupRepository> {
  GroupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupRepository create(Ref ref) {
    return groupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupRepository>(value),
    );
  }
}

String _$groupRepositoryHash() => r'668d088f6911127682d1bc99c33598240e24f925';

/// Groupes du joueur connecté — bouton "groupes" de
/// `character_list_screen.dart` (0/1/2+ groupes). `autoDispose` (défaut du
/// générateur), `retry: null` : même rationale que `charactersProvider`.

@ProviderFor(myGroups)
final myGroupsProvider = MyGroupsProvider._();

/// Groupes du joueur connecté — bouton "groupes" de
/// `character_list_screen.dart` (0/1/2+ groupes). `autoDispose` (défaut du
/// générateur), `retry: null` : même rationale que `charactersProvider`.

final class MyGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupSummary>>,
          List<GroupSummary>,
          FutureOr<List<GroupSummary>>
        >
    with
        $FutureModifier<List<GroupSummary>>,
        $FutureProvider<List<GroupSummary>> {
  /// Groupes du joueur connecté — bouton "groupes" de
  /// `character_list_screen.dart` (0/1/2+ groupes). `autoDispose` (défaut du
  /// générateur), `retry: null` : même rationale que `charactersProvider`.
  MyGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'myGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myGroupsHash();

  @$internal
  @override
  $FutureProviderElement<List<GroupSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupSummary>> create(Ref ref) {
    return myGroups(ref);
  }
}

String _$myGroupsHash() => r'3a9f8d2ec109c8b6ef0f3b8c218964015e6a641a';

/// Détail d'un groupe — écran "Groupe", famille par [groupId]. `autoDispose`,
/// `retry: null` : mêmes rationales que [myGroups].

@ProviderFor(groupDetail)
final groupDetailProvider = GroupDetailFamily._();

/// Détail d'un groupe — écran "Groupe", famille par [groupId]. `autoDispose`,
/// `retry: null` : mêmes rationales que [myGroups].

final class GroupDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupDetail>,
          GroupDetail,
          FutureOr<GroupDetail>
        >
    with $FutureModifier<GroupDetail>, $FutureProvider<GroupDetail> {
  /// Détail d'un groupe — écran "Groupe", famille par [groupId]. `autoDispose`,
  /// `retry: null` : mêmes rationales que [myGroups].
  GroupDetailProvider._({
    required GroupDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'groupDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupDetailHash();

  @override
  String toString() {
    return r'groupDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GroupDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupDetail> create(Ref ref) {
    final argument = this.argument as String;
    return groupDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupDetailHash() => r'f83afb3352bec4d72c36d130790a1004f9d7134d';

/// Détail d'un groupe — écran "Groupe", famille par [groupId]. `autoDispose`,
/// `retry: null` : mêmes rationales que [myGroups].

final class GroupDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GroupDetail>, String> {
  GroupDetailFamily._()
    : super(
        retry: _noRetry,
        name: r'groupDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Détail d'un groupe — écran "Groupe", famille par [groupId]. `autoDispose`,
  /// `retry: null` : mêmes rationales que [myGroups].

  GroupDetailProvider call(String groupId) =>
      GroupDetailProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupDetailProvider';
}

/// Butin commun d'un groupe — onglet "Butin", famille par [groupId].

@ProviderFor(groupTreasure)
final groupTreasureProvider = GroupTreasureFamily._();

/// Butin commun d'un groupe — onglet "Butin", famille par [groupId].

final class GroupTreasureProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupTreasure>,
          GroupTreasure,
          FutureOr<GroupTreasure>
        >
    with $FutureModifier<GroupTreasure>, $FutureProvider<GroupTreasure> {
  /// Butin commun d'un groupe — onglet "Butin", famille par [groupId].
  GroupTreasureProvider._({
    required GroupTreasureFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'groupTreasureProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupTreasureHash();

  @override
  String toString() {
    return r'groupTreasureProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GroupTreasure> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupTreasure> create(Ref ref) {
    final argument = this.argument as String;
    return groupTreasure(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupTreasureProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupTreasureHash() => r'60bea8de740afc170ae5717b36cdd63161822923';

/// Butin commun d'un groupe — onglet "Butin", famille par [groupId].

final class GroupTreasureFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GroupTreasure>, String> {
  GroupTreasureFamily._()
    : super(
        retry: _noRetry,
        name: r'groupTreasureProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Butin commun d'un groupe — onglet "Butin", famille par [groupId].

  GroupTreasureProvider call(String groupId) =>
      GroupTreasureProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupTreasureProvider';
}

/// Aperçu d'un groupe (étape 2/3 "Confirmation" du flux "Rejoindre un
/// groupe"), en famille par [code] — même rationale que
/// `storyInvitePreviewProvider` (`features/join_story/presentation/
/// providers/join_story_providers.dart`) : `autoDispose`, `retry: null`
/// (l'écran expose son propre bouton "Réessayer"/"Modifier le code").

@ProviderFor(groupInvitePreview)
final groupInvitePreviewProvider = GroupInvitePreviewFamily._();

/// Aperçu d'un groupe (étape 2/3 "Confirmation" du flux "Rejoindre un
/// groupe"), en famille par [code] — même rationale que
/// `storyInvitePreviewProvider` (`features/join_story/presentation/
/// providers/join_story_providers.dart`) : `autoDispose`, `retry: null`
/// (l'écran expose son propre bouton "Réessayer"/"Modifier le code").

final class GroupInvitePreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupPreview>,
          GroupPreview,
          FutureOr<GroupPreview>
        >
    with $FutureModifier<GroupPreview>, $FutureProvider<GroupPreview> {
  /// Aperçu d'un groupe (étape 2/3 "Confirmation" du flux "Rejoindre un
  /// groupe"), en famille par [code] — même rationale que
  /// `storyInvitePreviewProvider` (`features/join_story/presentation/
  /// providers/join_story_providers.dart`) : `autoDispose`, `retry: null`
  /// (l'écran expose son propre bouton "Réessayer"/"Modifier le code").
  GroupInvitePreviewProvider._({
    required GroupInvitePreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'groupInvitePreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupInvitePreviewHash();

  @override
  String toString() {
    return r'groupInvitePreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GroupPreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupPreview> create(Ref ref) {
    final argument = this.argument as String;
    return groupInvitePreview(ref, code: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupInvitePreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupInvitePreviewHash() =>
    r'e8ccc79411f15a180d60cea1b488aa116e513505';

/// Aperçu d'un groupe (étape 2/3 "Confirmation" du flux "Rejoindre un
/// groupe"), en famille par [code] — même rationale que
/// `storyInvitePreviewProvider` (`features/join_story/presentation/
/// providers/join_story_providers.dart`) : `autoDispose`, `retry: null`
/// (l'écran expose son propre bouton "Réessayer"/"Modifier le code").

final class GroupInvitePreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GroupPreview>, String> {
  GroupInvitePreviewFamily._()
    : super(
        retry: _noRetry,
        name: r'groupInvitePreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Aperçu d'un groupe (étape 2/3 "Confirmation" du flux "Rejoindre un
  /// groupe"), en famille par [code] — même rationale que
  /// `storyInvitePreviewProvider` (`features/join_story/presentation/
  /// providers/join_story_providers.dart`) : `autoDispose`, `retry: null`
  /// (l'écran expose son propre bouton "Réessayer"/"Modifier le code").

  GroupInvitePreviewProvider call({required String code}) =>
      GroupInvitePreviewProvider._(argument: code, from: this);

  @override
  String toString() => r'groupInvitePreviewProvider';
}

/// Abonnement Realtime aux membres du groupe [groupId] (voir
/// `GroupRepository.subscribeToMemberUpdates`) — provider "à effet de bord
/// pur" (aucune valeur exploitée par l'appelant), à `ref.watch` depuis l'écran
/// "Groupe" pour que l'abonnement suive exactement son cycle de vie :
/// souscrit dès que [groupDetailProvider] résout une liste de membres non
/// vide, se désabonne (`ref.onDispose`) à chaque reconstruction (ex. la
/// liste de membres change) ou à la fermeture de l'écran — **jamais
/// `keepAlive`** (première utilisation de Supabase Realtime dans ce dépôt,
/// contrairement aux coordinateurs `keepAlive` existants comme
/// `CharacterWriteSyncCoordinator`, qui vivent toute la durée de l'app).
///
/// Se réabonne automatiquement si la liste de membres change (ex. un
/// coéquipier rejoint/quitte le groupe pendant que l'écran est ouvert) : ce
/// provider dépend de [groupDetailProvider], dont l'invalidation (déclenchée
/// par [onChanged] lui-même à chaque évènement Realtime reçu) reconstruit ce
/// watcher avec la liste de personnages à jour.

@ProviderFor(groupMembersRealtimeWatcher)
final groupMembersRealtimeWatcherProvider =
    GroupMembersRealtimeWatcherFamily._();

/// Abonnement Realtime aux membres du groupe [groupId] (voir
/// `GroupRepository.subscribeToMemberUpdates`) — provider "à effet de bord
/// pur" (aucune valeur exploitée par l'appelant), à `ref.watch` depuis l'écran
/// "Groupe" pour que l'abonnement suive exactement son cycle de vie :
/// souscrit dès que [groupDetailProvider] résout une liste de membres non
/// vide, se désabonne (`ref.onDispose`) à chaque reconstruction (ex. la
/// liste de membres change) ou à la fermeture de l'écran — **jamais
/// `keepAlive`** (première utilisation de Supabase Realtime dans ce dépôt,
/// contrairement aux coordinateurs `keepAlive` existants comme
/// `CharacterWriteSyncCoordinator`, qui vivent toute la durée de l'app).
///
/// Se réabonne automatiquement si la liste de membres change (ex. un
/// coéquipier rejoint/quitte le groupe pendant que l'écran est ouvert) : ce
/// provider dépend de [groupDetailProvider], dont l'invalidation (déclenchée
/// par [onChanged] lui-même à chaque évènement Realtime reçu) reconstruit ce
/// watcher avec la liste de personnages à jour.

final class GroupMembersRealtimeWatcherProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Abonnement Realtime aux membres du groupe [groupId] (voir
  /// `GroupRepository.subscribeToMemberUpdates`) — provider "à effet de bord
  /// pur" (aucune valeur exploitée par l'appelant), à `ref.watch` depuis l'écran
  /// "Groupe" pour que l'abonnement suive exactement son cycle de vie :
  /// souscrit dès que [groupDetailProvider] résout une liste de membres non
  /// vide, se désabonne (`ref.onDispose`) à chaque reconstruction (ex. la
  /// liste de membres change) ou à la fermeture de l'écran — **jamais
  /// `keepAlive`** (première utilisation de Supabase Realtime dans ce dépôt,
  /// contrairement aux coordinateurs `keepAlive` existants comme
  /// `CharacterWriteSyncCoordinator`, qui vivent toute la durée de l'app).
  ///
  /// Se réabonne automatiquement si la liste de membres change (ex. un
  /// coéquipier rejoint/quitte le groupe pendant que l'écran est ouvert) : ce
  /// provider dépend de [groupDetailProvider], dont l'invalidation (déclenchée
  /// par [onChanged] lui-même à chaque évènement Realtime reçu) reconstruit ce
  /// watcher avec la liste de personnages à jour.
  GroupMembersRealtimeWatcherProvider._({
    required GroupMembersRealtimeWatcherFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupMembersRealtimeWatcherProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupMembersRealtimeWatcherHash();

  @override
  String toString() {
    return r'groupMembersRealtimeWatcherProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    final argument = this.argument as String;
    return groupMembersRealtimeWatcher(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersRealtimeWatcherProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupMembersRealtimeWatcherHash() =>
    r'a5314c386f2e5e7a6825b43c6f428f76013ef220';

/// Abonnement Realtime aux membres du groupe [groupId] (voir
/// `GroupRepository.subscribeToMemberUpdates`) — provider "à effet de bord
/// pur" (aucune valeur exploitée par l'appelant), à `ref.watch` depuis l'écran
/// "Groupe" pour que l'abonnement suive exactement son cycle de vie :
/// souscrit dès que [groupDetailProvider] résout une liste de membres non
/// vide, se désabonne (`ref.onDispose`) à chaque reconstruction (ex. la
/// liste de membres change) ou à la fermeture de l'écran — **jamais
/// `keepAlive`** (première utilisation de Supabase Realtime dans ce dépôt,
/// contrairement aux coordinateurs `keepAlive` existants comme
/// `CharacterWriteSyncCoordinator`, qui vivent toute la durée de l'app).
///
/// Se réabonne automatiquement si la liste de membres change (ex. un
/// coéquipier rejoint/quitte le groupe pendant que l'écran est ouvert) : ce
/// provider dépend de [groupDetailProvider], dont l'invalidation (déclenchée
/// par [onChanged] lui-même à chaque évènement Realtime reçu) reconstruit ce
/// watcher avec la liste de personnages à jour.

final class GroupMembersRealtimeWatcherFamily extends $Family
    with $FunctionalFamilyOverride<void, String> {
  GroupMembersRealtimeWatcherFamily._()
    : super(
        retry: null,
        name: r'groupMembersRealtimeWatcherProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Abonnement Realtime aux membres du groupe [groupId] (voir
  /// `GroupRepository.subscribeToMemberUpdates`) — provider "à effet de bord
  /// pur" (aucune valeur exploitée par l'appelant), à `ref.watch` depuis l'écran
  /// "Groupe" pour que l'abonnement suive exactement son cycle de vie :
  /// souscrit dès que [groupDetailProvider] résout une liste de membres non
  /// vide, se désabonne (`ref.onDispose`) à chaque reconstruction (ex. la
  /// liste de membres change) ou à la fermeture de l'écran — **jamais
  /// `keepAlive`** (première utilisation de Supabase Realtime dans ce dépôt,
  /// contrairement aux coordinateurs `keepAlive` existants comme
  /// `CharacterWriteSyncCoordinator`, qui vivent toute la durée de l'app).
  ///
  /// Se réabonne automatiquement si la liste de membres change (ex. un
  /// coéquipier rejoint/quitte le groupe pendant que l'écran est ouvert) : ce
  /// provider dépend de [groupDetailProvider], dont l'invalidation (déclenchée
  /// par [onChanged] lui-même à chaque évènement Realtime reçu) reconstruit ce
  /// watcher avec la liste de personnages à jour.

  GroupMembersRealtimeWatcherProvider call(String groupId) =>
      GroupMembersRealtimeWatcherProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupMembersRealtimeWatcherProvider';
}
