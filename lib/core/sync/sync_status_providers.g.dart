// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_status_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Identifiant du compte connecté, ou `null` (pas de session, ou Supabase non
/// initialisé comme dans la plupart des tests de widgets) — jamais
/// d'exception. Surchargeable dans les tests.

@ProviderFor(syncOwnerId)
final syncOwnerIdProvider = SyncOwnerIdProvider._();

/// Identifiant du compte connecté, ou `null` (pas de session, ou Supabase non
/// initialisé comme dans la plupart des tests de widgets) — jamais
/// d'exception. Surchargeable dans les tests.

final class SyncOwnerIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Identifiant du compte connecté, ou `null` (pas de session, ou Supabase non
  /// initialisé comme dans la plupart des tests de widgets) — jamais
  /// d'exception. Surchargeable dans les tests.
  SyncOwnerIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncOwnerIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncOwnerIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return syncOwnerId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$syncOwnerIdHash() => r'69cb731f6cae9f618ba7cc22e95e9b0b82cc460a';

/// Alertes de synchro persistées du compte connecté, la plus ancienne
/// d'abord. Vide si personne n'est connecté.

@ProviderFor(syncAlerts)
final syncAlertsProvider = SyncAlertsProvider._();

/// Alertes de synchro persistées du compte connecté, la plus ancienne
/// d'abord. Vide si personne n'est connecté.

final class SyncAlertsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SyncAlert>>,
          List<SyncAlert>,
          Stream<List<SyncAlert>>
        >
    with $FutureModifier<List<SyncAlert>>, $StreamProvider<List<SyncAlert>> {
  /// Alertes de synchro persistées du compte connecté, la plus ancienne
  /// d'abord. Vide si personne n'est connecté.
  SyncAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncAlertsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncAlertsHash();

  @$internal
  @override
  $StreamProviderElement<List<SyncAlert>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SyncAlert>> create(Ref ref) {
    return syncAlerts(ref);
  }
}

String _$syncAlertsHash() => r'e619f0421adce195c7c50c025fd0e0c48d919e9f';

/// Nombre d'écritures hors-ligne en attente : celles de [characterId] (fiche)
/// ou le total du compte si `null` (liste).

@ProviderFor(pendingWriteCount)
final pendingWriteCountProvider = PendingWriteCountFamily._();

/// Nombre d'écritures hors-ligne en attente : celles de [characterId] (fiche)
/// ou le total du compte si `null` (liste).

final class PendingWriteCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Nombre d'écritures hors-ligne en attente : celles de [characterId] (fiche)
  /// ou le total du compte si `null` (liste).
  PendingWriteCountProvider._({
    required PendingWriteCountFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'pendingWriteCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingWriteCountHash();

  @override
  String toString() {
    return r'pendingWriteCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String?;
    return pendingWriteCount(ref, characterId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingWriteCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingWriteCountHash() => r'15bc3d01331a808b2c25581b6141a22ac28ce190';

/// Nombre d'écritures hors-ligne en attente : celles de [characterId] (fiche)
/// ou le total du compte si `null` (liste).

final class PendingWriteCountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String?> {
  PendingWriteCountFamily._()
    : super(
        retry: null,
        name: r'pendingWriteCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Nombre d'écritures hors-ligne en attente : celles de [characterId] (fiche)
  /// ou le total du compte si `null` (liste).

  PendingWriteCountProvider call({String? characterId}) =>
      PendingWriteCountProvider._(argument: characterId, from: this);

  @override
  String toString() => r'pendingWriteCountProvider';
}

/// Date de dernière synchro réussie du compte connecté (`null` : jamais).

@ProviderFor(lastSyncAt)
final lastSyncAtProvider = LastSyncAtProvider._();

/// Date de dernière synchro réussie du compte connecté (`null` : jamais).

final class LastSyncAtProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime?>, DateTime?, Stream<DateTime?>>
    with $FutureModifier<DateTime?>, $StreamProvider<DateTime?> {
  /// Date de dernière synchro réussie du compte connecté (`null` : jamais).
  LastSyncAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastSyncAtProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastSyncAtHash();

  @$internal
  @override
  $StreamProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime?> create(Ref ref) {
    return lastSyncAt(ref);
  }
}

String _$lastSyncAtHash() => r'3699f0ea272f21b9bd921e315854ee2055db913e';

/// État du bandeau de synchro (`SyncStatusBanner`) pour une portée : la fiche
/// d'un personnage ([characterId] renseigné : compteur de CE personnage,
/// « Hors ligne » affiché même à 0 en attente) ou la liste (`null` : total du
/// compte, hors-ligne seulement si N > 0). Voir [SyncBannerEngine] pour la
/// précédence et les temporisations.

@ProviderFor(SyncBanner)
final syncBannerProvider = SyncBannerFamily._();

/// État du bandeau de synchro (`SyncStatusBanner`) pour une portée : la fiche
/// d'un personnage ([characterId] renseigné : compteur de CE personnage,
/// « Hors ligne » affiché même à 0 en attente) ou la liste (`null` : total du
/// compte, hors-ligne seulement si N > 0). Voir [SyncBannerEngine] pour la
/// précédence et les temporisations.
final class SyncBannerProvider
    extends $NotifierProvider<SyncBanner, SyncBannerState> {
  /// État du bandeau de synchro (`SyncStatusBanner`) pour une portée : la fiche
  /// d'un personnage ([characterId] renseigné : compteur de CE personnage,
  /// « Hors ligne » affiché même à 0 en attente) ou la liste (`null` : total du
  /// compte, hors-ligne seulement si N > 0). Voir [SyncBannerEngine] pour la
  /// précédence et les temporisations.
  SyncBannerProvider._({
    required SyncBannerFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'syncBannerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$syncBannerHash();

  @override
  String toString() {
    return r'syncBannerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SyncBanner create() => SyncBanner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncBannerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncBannerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SyncBannerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$syncBannerHash() => r'abd107868f70ef9790244583d287c1b63911ef2a';

/// État du bandeau de synchro (`SyncStatusBanner`) pour une portée : la fiche
/// d'un personnage ([characterId] renseigné : compteur de CE personnage,
/// « Hors ligne » affiché même à 0 en attente) ou la liste (`null` : total du
/// compte, hors-ligne seulement si N > 0). Voir [SyncBannerEngine] pour la
/// précédence et les temporisations.

final class SyncBannerFamily extends $Family
    with
        $ClassFamilyOverride<
          SyncBanner,
          SyncBannerState,
          SyncBannerState,
          SyncBannerState,
          String?
        > {
  SyncBannerFamily._()
    : super(
        retry: null,
        name: r'syncBannerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// État du bandeau de synchro (`SyncStatusBanner`) pour une portée : la fiche
  /// d'un personnage ([characterId] renseigné : compteur de CE personnage,
  /// « Hors ligne » affiché même à 0 en attente) ou la liste (`null` : total du
  /// compte, hors-ligne seulement si N > 0). Voir [SyncBannerEngine] pour la
  /// précédence et les temporisations.

  SyncBannerProvider call({String? characterId}) =>
      SyncBannerProvider._(argument: characterId, from: this);

  @override
  String toString() => r'syncBannerProvider';
}

/// État du bandeau de synchro (`SyncStatusBanner`) pour une portée : la fiche
/// d'un personnage ([characterId] renseigné : compteur de CE personnage,
/// « Hors ligne » affiché même à 0 en attente) ou la liste (`null` : total du
/// compte, hors-ligne seulement si N > 0). Voir [SyncBannerEngine] pour la
/// précédence et les temporisations.

abstract class _$SyncBanner extends $Notifier<SyncBannerState> {
  late final _$args = ref.$arg as String?;
  String? get characterId => _$args;

  SyncBannerState build({String? characterId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyncBannerState, SyncBannerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncBannerState, SyncBannerState>,
              SyncBannerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(characterId: _$args));
  }
}
