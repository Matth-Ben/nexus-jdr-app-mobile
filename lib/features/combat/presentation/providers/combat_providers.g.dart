// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(combatRepository)
final combatRepositoryProvider = CombatRepositoryProvider._();

final class CombatRepositoryProvider
    extends
        $FunctionalProvider<
          CombatRepository,
          CombatRepository,
          CombatRepository
        >
    with $Provider<CombatRepository> {
  CombatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'combatRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$combatRepositoryHash();

  @$internal
  @override
  $ProviderElement<CombatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CombatRepository create(Ref ref) {
    return combatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CombatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CombatRepository>(value),
    );
  }
}

String _$combatRepositoryHash() => r'7ef6a4cd00a066266c47b5c39a66d307623797e0';

/// Délai de debounce des refetchs déclenchés par Realtime (une rafale
/// d'évènements — ex. `add_npc_participants` ×20 — ne produit qu'un refetch).
/// Surchargeable en test.

@ProviderFor(combatRefetchDebounce)
final combatRefetchDebounceProvider = CombatRefetchDebounceProvider._();

/// Délai de debounce des refetchs déclenchés par Realtime (une rafale
/// d'évènements — ex. `add_npc_participants` ×20 — ne produit qu'un refetch).
/// Surchargeable en test.

final class CombatRefetchDebounceProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// Délai de debounce des refetchs déclenchés par Realtime (une rafale
  /// d'évènements — ex. `add_npc_participants` ×20 — ne produit qu'un refetch).
  /// Surchargeable en test.
  CombatRefetchDebounceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'combatRefetchDebounceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$combatRefetchDebounceHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return combatRefetchDebounce(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$combatRefetchDebounceHash() =>
    r'27006df90d707fc73c2b38ba3000cb4d0bbbddb5';

/// Horloge injectée (horodatage du dernier état connu). Surchargeable en test.

@ProviderFor(combatClock)
final combatClockProvider = CombatClockProvider._();

/// Horloge injectée (horodatage du dernier état connu). Surchargeable en test.

final class CombatClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Horloge injectée (horodatage du dernier état connu). Surchargeable en test.
  CombatClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'combatClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$combatClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return combatClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$combatClockHash() => r'2867b69ee2f75b988642b4917cee57051e41959b';

/// État du combat du groupe [groupId] : chargement / aucun combat / actif /
/// terminé récemment / erreur, avec horodatage du dernier état connu et
/// drapeau « périmé / lecture seule » quand le dernier refetch a échoué (hors
/// ligne...).
///
/// `keepAlive` : le dernier état est gardé **en mémoire** (jamais persisté,
/// pas de cache drift) pour que l'écran Groupe et la fiche l'affichent
/// immédiatement. Il est **purgé** (`invalidateSelf`) dès que l'utilisateur
/// authentifié change (déconnexion, autre compte) : un autre compte ne voit
/// jamais l'instantané du précédent.
///
/// Stratégie Realtime : « notification de changement puis refetch complet »
/// ([scheduleRefresh] debouncé, [refresh] immédiat). Un seul refetch à la
/// fois : un évènement reçu pendant un refetch en marque un suivant, il n'en
/// lance jamais un second en parallèle. Le tour en cours vient toujours du
/// serveur.

@ProviderFor(CombatNotifier)
final combatProvider = CombatNotifierFamily._();

/// État du combat du groupe [groupId] : chargement / aucun combat / actif /
/// terminé récemment / erreur, avec horodatage du dernier état connu et
/// drapeau « périmé / lecture seule » quand le dernier refetch a échoué (hors
/// ligne...).
///
/// `keepAlive` : le dernier état est gardé **en mémoire** (jamais persisté,
/// pas de cache drift) pour que l'écran Groupe et la fiche l'affichent
/// immédiatement. Il est **purgé** (`invalidateSelf`) dès que l'utilisateur
/// authentifié change (déconnexion, autre compte) : un autre compte ne voit
/// jamais l'instantané du précédent.
///
/// Stratégie Realtime : « notification de changement puis refetch complet »
/// ([scheduleRefresh] debouncé, [refresh] immédiat). Un seul refetch à la
/// fois : un évènement reçu pendant un refetch en marque un suivant, il n'en
/// lance jamais un second en parallèle. Le tour en cours vient toujours du
/// serveur.
final class CombatNotifierProvider
    extends $NotifierProvider<CombatNotifier, CombatViewState> {
  /// État du combat du groupe [groupId] : chargement / aucun combat / actif /
  /// terminé récemment / erreur, avec horodatage du dernier état connu et
  /// drapeau « périmé / lecture seule » quand le dernier refetch a échoué (hors
  /// ligne...).
  ///
  /// `keepAlive` : le dernier état est gardé **en mémoire** (jamais persisté,
  /// pas de cache drift) pour que l'écran Groupe et la fiche l'affichent
  /// immédiatement. Il est **purgé** (`invalidateSelf`) dès que l'utilisateur
  /// authentifié change (déconnexion, autre compte) : un autre compte ne voit
  /// jamais l'instantané du précédent.
  ///
  /// Stratégie Realtime : « notification de changement puis refetch complet »
  /// ([scheduleRefresh] debouncé, [refresh] immédiat). Un seul refetch à la
  /// fois : un évènement reçu pendant un refetch en marque un suivant, il n'en
  /// lance jamais un second en parallèle. Le tour en cours vient toujours du
  /// serveur.
  CombatNotifierProvider._({
    required CombatNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'combatProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$combatNotifierHash();

  @override
  String toString() {
    return r'combatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CombatNotifier create() => CombatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CombatViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CombatViewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CombatNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$combatNotifierHash() => r'c6665d54a70bdef7f3e41da9d5645801df882596';

/// État du combat du groupe [groupId] : chargement / aucun combat / actif /
/// terminé récemment / erreur, avec horodatage du dernier état connu et
/// drapeau « périmé / lecture seule » quand le dernier refetch a échoué (hors
/// ligne...).
///
/// `keepAlive` : le dernier état est gardé **en mémoire** (jamais persisté,
/// pas de cache drift) pour que l'écran Groupe et la fiche l'affichent
/// immédiatement. Il est **purgé** (`invalidateSelf`) dès que l'utilisateur
/// authentifié change (déconnexion, autre compte) : un autre compte ne voit
/// jamais l'instantané du précédent.
///
/// Stratégie Realtime : « notification de changement puis refetch complet »
/// ([scheduleRefresh] debouncé, [refresh] immédiat). Un seul refetch à la
/// fois : un évènement reçu pendant un refetch en marque un suivant, il n'en
/// lance jamais un second en parallèle. Le tour en cours vient toujours du
/// serveur.

final class CombatNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CombatNotifier,
          CombatViewState,
          CombatViewState,
          CombatViewState,
          String
        > {
  CombatNotifierFamily._()
    : super(
        retry: _noRetry,
        name: r'combatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// État du combat du groupe [groupId] : chargement / aucun combat / actif /
  /// terminé récemment / erreur, avec horodatage du dernier état connu et
  /// drapeau « périmé / lecture seule » quand le dernier refetch a échoué (hors
  /// ligne...).
  ///
  /// `keepAlive` : le dernier état est gardé **en mémoire** (jamais persisté,
  /// pas de cache drift) pour que l'écran Groupe et la fiche l'affichent
  /// immédiatement. Il est **purgé** (`invalidateSelf`) dès que l'utilisateur
  /// authentifié change (déconnexion, autre compte) : un autre compte ne voit
  /// jamais l'instantané du précédent.
  ///
  /// Stratégie Realtime : « notification de changement puis refetch complet »
  /// ([scheduleRefresh] debouncé, [refresh] immédiat). Un seul refetch à la
  /// fois : un évènement reçu pendant un refetch en marque un suivant, il n'en
  /// lance jamais un second en parallèle. Le tour en cours vient toujours du
  /// serveur.

  CombatNotifierProvider call(String groupId) =>
      CombatNotifierProvider._(argument: groupId, from: this);

  @override
  String toString() => r'combatProvider';
}

/// État du combat du groupe [groupId] : chargement / aucun combat / actif /
/// terminé récemment / erreur, avec horodatage du dernier état connu et
/// drapeau « périmé / lecture seule » quand le dernier refetch a échoué (hors
/// ligne...).
///
/// `keepAlive` : le dernier état est gardé **en mémoire** (jamais persisté,
/// pas de cache drift) pour que l'écran Groupe et la fiche l'affichent
/// immédiatement. Il est **purgé** (`invalidateSelf`) dès que l'utilisateur
/// authentifié change (déconnexion, autre compte) : un autre compte ne voit
/// jamais l'instantané du précédent.
///
/// Stratégie Realtime : « notification de changement puis refetch complet »
/// ([scheduleRefresh] debouncé, [refresh] immédiat). Un seul refetch à la
/// fois : un évènement reçu pendant un refetch en marque un suivant, il n'en
/// lance jamais un second en parallèle. Le tour en cours vient toujours du
/// serveur.

abstract class _$CombatNotifier extends $Notifier<CombatViewState> {
  late final _$args = ref.$arg as String;
  String get groupId => _$args;

  CombatViewState build(String groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CombatViewState, CombatViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CombatViewState, CombatViewState>,
              CombatViewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Abonnement Realtime du combat du groupe [groupId] — provider à effet de
/// bord pur, à `ref.watch` depuis l'écran Groupe ou la fiche : il ne vit que
/// tant qu'ils l'observent (`autoDispose`) ET que l'app est au premier plan
/// (`WidgetsBindingObserver` : désabonnement en arrière-plan, réabonnement +
/// resync complet au retour). Un resync complet a aussi lieu à chaque
/// (re)connexion du canal et au retour du réseau.
///
/// Ne dépend que de dépôts `keepAlive` stables : il n'est jamais reconstruit
/// par les changements de l'état du combat (pas de désabonnement/réabonnement
/// parasite).

@ProviderFor(combatRealtimeWatcher)
final combatRealtimeWatcherProvider = CombatRealtimeWatcherFamily._();

/// Abonnement Realtime du combat du groupe [groupId] — provider à effet de
/// bord pur, à `ref.watch` depuis l'écran Groupe ou la fiche : il ne vit que
/// tant qu'ils l'observent (`autoDispose`) ET que l'app est au premier plan
/// (`WidgetsBindingObserver` : désabonnement en arrière-plan, réabonnement +
/// resync complet au retour). Un resync complet a aussi lieu à chaque
/// (re)connexion du canal et au retour du réseau.
///
/// Ne dépend que de dépôts `keepAlive` stables : il n'est jamais reconstruit
/// par les changements de l'état du combat (pas de désabonnement/réabonnement
/// parasite).

final class CombatRealtimeWatcherProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Abonnement Realtime du combat du groupe [groupId] — provider à effet de
  /// bord pur, à `ref.watch` depuis l'écran Groupe ou la fiche : il ne vit que
  /// tant qu'ils l'observent (`autoDispose`) ET que l'app est au premier plan
  /// (`WidgetsBindingObserver` : désabonnement en arrière-plan, réabonnement +
  /// resync complet au retour). Un resync complet a aussi lieu à chaque
  /// (re)connexion du canal et au retour du réseau.
  ///
  /// Ne dépend que de dépôts `keepAlive` stables : il n'est jamais reconstruit
  /// par les changements de l'état du combat (pas de désabonnement/réabonnement
  /// parasite).
  CombatRealtimeWatcherProvider._({
    required CombatRealtimeWatcherFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'combatRealtimeWatcherProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$combatRealtimeWatcherHash();

  @override
  String toString() {
    return r'combatRealtimeWatcherProvider'
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
    return combatRealtimeWatcher(ref, argument);
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
    return other is CombatRealtimeWatcherProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$combatRealtimeWatcherHash() =>
    r'605dd2b619e667927bf77f5ced80c1b8f8bec256';

/// Abonnement Realtime du combat du groupe [groupId] — provider à effet de
/// bord pur, à `ref.watch` depuis l'écran Groupe ou la fiche : il ne vit que
/// tant qu'ils l'observent (`autoDispose`) ET que l'app est au premier plan
/// (`WidgetsBindingObserver` : désabonnement en arrière-plan, réabonnement +
/// resync complet au retour). Un resync complet a aussi lieu à chaque
/// (re)connexion du canal et au retour du réseau.
///
/// Ne dépend que de dépôts `keepAlive` stables : il n'est jamais reconstruit
/// par les changements de l'état du combat (pas de désabonnement/réabonnement
/// parasite).

final class CombatRealtimeWatcherFamily extends $Family
    with $FunctionalFamilyOverride<void, String> {
  CombatRealtimeWatcherFamily._()
    : super(
        retry: null,
        name: r'combatRealtimeWatcherProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Abonnement Realtime du combat du groupe [groupId] — provider à effet de
  /// bord pur, à `ref.watch` depuis l'écran Groupe ou la fiche : il ne vit que
  /// tant qu'ils l'observent (`autoDispose`) ET que l'app est au premier plan
  /// (`WidgetsBindingObserver` : désabonnement en arrière-plan, réabonnement +
  /// resync complet au retour). Un resync complet a aussi lieu à chaque
  /// (re)connexion du canal et au retour du réseau.
  ///
  /// Ne dépend que de dépôts `keepAlive` stables : il n'est jamais reconstruit
  /// par les changements de l'état du combat (pas de désabonnement/réabonnement
  /// parasite).

  CombatRealtimeWatcherProvider call(String groupId) =>
      CombatRealtimeWatcherProvider._(argument: groupId, from: this);

  @override
  String toString() => r'combatRealtimeWatcherProvider';
}

/// Combat actif du groupe [groupId], pour le bandeau de la fiche : `null` si
/// aucun combat actif. **Rebuild ciblé** (`select`) : les changements sans
/// rapport (ex. initiative d'un participant) ne reconstruisent pas le bandeau
/// ni la fiche. Maintient aussi l'abonnement Realtime tant qu'il est observé.
///
/// Le groupe d'un personnage se retrouve avec `characterGroupIdsProvider` /
/// `characterCombatBannerProvider` (`character_combat_provider.dart`).

@ProviderFor(combatBanner)
final combatBannerProvider = CombatBannerFamily._();

/// Combat actif du groupe [groupId], pour le bandeau de la fiche : `null` si
/// aucun combat actif. **Rebuild ciblé** (`select`) : les changements sans
/// rapport (ex. initiative d'un participant) ne reconstruisent pas le bandeau
/// ni la fiche. Maintient aussi l'abonnement Realtime tant qu'il est observé.
///
/// Le groupe d'un personnage se retrouve avec `characterGroupIdsProvider` /
/// `characterCombatBannerProvider` (`character_combat_provider.dart`).

final class CombatBannerProvider
    extends
        $FunctionalProvider<
          CombatBannerInfo?,
          CombatBannerInfo?,
          CombatBannerInfo?
        >
    with $Provider<CombatBannerInfo?> {
  /// Combat actif du groupe [groupId], pour le bandeau de la fiche : `null` si
  /// aucun combat actif. **Rebuild ciblé** (`select`) : les changements sans
  /// rapport (ex. initiative d'un participant) ne reconstruisent pas le bandeau
  /// ni la fiche. Maintient aussi l'abonnement Realtime tant qu'il est observé.
  ///
  /// Le groupe d'un personnage se retrouve avec `characterGroupIdsProvider` /
  /// `characterCombatBannerProvider` (`character_combat_provider.dart`).
  CombatBannerProvider._({
    required CombatBannerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'combatBannerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$combatBannerHash();

  @override
  String toString() {
    return r'combatBannerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CombatBannerInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CombatBannerInfo? create(Ref ref) {
    final argument = this.argument as String;
    return combatBanner(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CombatBannerInfo? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CombatBannerInfo?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CombatBannerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$combatBannerHash() => r'a233a957ed1ec6b7b5da87b3f1d98f8e4ff929ce';

/// Combat actif du groupe [groupId], pour le bandeau de la fiche : `null` si
/// aucun combat actif. **Rebuild ciblé** (`select`) : les changements sans
/// rapport (ex. initiative d'un participant) ne reconstruisent pas le bandeau
/// ni la fiche. Maintient aussi l'abonnement Realtime tant qu'il est observé.
///
/// Le groupe d'un personnage se retrouve avec `characterGroupIdsProvider` /
/// `characterCombatBannerProvider` (`character_combat_provider.dart`).

final class CombatBannerFamily extends $Family
    with $FunctionalFamilyOverride<CombatBannerInfo?, String> {
  CombatBannerFamily._()
    : super(
        retry: null,
        name: r'combatBannerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Combat actif du groupe [groupId], pour le bandeau de la fiche : `null` si
  /// aucun combat actif. **Rebuild ciblé** (`select`) : les changements sans
  /// rapport (ex. initiative d'un participant) ne reconstruisent pas le bandeau
  /// ni la fiche. Maintient aussi l'abonnement Realtime tant qu'il est observé.
  ///
  /// Le groupe d'un personnage se retrouve avec `characterGroupIdsProvider` /
  /// `characterCombatBannerProvider` (`character_combat_provider.dart`).

  CombatBannerProvider call(String groupId) =>
      CombatBannerProvider._(argument: groupId, from: this);

  @override
  String toString() => r'combatBannerProvider';
}
