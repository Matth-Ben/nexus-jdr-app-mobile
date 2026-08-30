// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Connexion SQLite (drift) partagée par toute l'app — doit vivre toute la
/// durée de l'app, jamais recréée par écran, même rationale que
/// `supabaseClientProvider` (`core/network/supabase_client_provider.dart`).
/// Ferme la connexion à la destruction du provider (ne devrait normalement
/// jamais arriver hors test, `keepAlive`).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Connexion SQLite (drift) partagée par toute l'app — doit vivre toute la
/// durée de l'app, jamais recréée par écran, même rationale que
/// `supabaseClientProvider` (`core/network/supabase_client_provider.dart`).
/// Ferme la connexion à la destruction du provider (ne devrait normalement
/// jamais arriver hors test, `keepAlive`).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Connexion SQLite (drift) partagée par toute l'app — doit vivre toute la
  /// durée de l'app, jamais recréée par écran, même rationale que
  /// `supabaseClientProvider` (`core/network/supabase_client_provider.dart`).
  /// Ferme la connexion à la destruction du provider (ne devrait normalement
  /// jamais arriver hors test, `keepAlive`).
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// Cache des données de référence (races, classes, historiques, sorts,
/// objets, compétences, outils, langues) consommé par
/// `SupabaseCharacterCreationRepository` — voir
/// `features/character_creation/presentation/providers/character_creation_providers.dart`.

@ProviderFor(referenceDataCache)
final referenceDataCacheProvider = ReferenceDataCacheProvider._();

/// Cache des données de référence (races, classes, historiques, sorts,
/// objets, compétences, outils, langues) consommé par
/// `SupabaseCharacterCreationRepository` — voir
/// `features/character_creation/presentation/providers/character_creation_providers.dart`.

final class ReferenceDataCacheProvider
    extends
        $FunctionalProvider<
          ReferenceDataCache,
          ReferenceDataCache,
          ReferenceDataCache
        >
    with $Provider<ReferenceDataCache> {
  /// Cache des données de référence (races, classes, historiques, sorts,
  /// objets, compétences, outils, langues) consommé par
  /// `SupabaseCharacterCreationRepository` — voir
  /// `features/character_creation/presentation/providers/character_creation_providers.dart`.
  ReferenceDataCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'referenceDataCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$referenceDataCacheHash();

  @$internal
  @override
  $ProviderElement<ReferenceDataCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReferenceDataCache create(Ref ref) {
    return referenceDataCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReferenceDataCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReferenceDataCache>(value),
    );
  }
}

String _$referenceDataCacheHash() =>
    r'ce85a456b746cdcad4e1419045d81db3ff9dd7df';

/// File de synchro hors-ligne PV/XP (`PendingCharacterWrites`), consommée par
/// `SupabaseCharacterRepository`/`PendingCharacterWriteSyncer` — voir
/// `features/characters/presentation/providers/character_providers.dart`.

@ProviderFor(pendingCharacterWriteQueue)
final pendingCharacterWriteQueueProvider =
    PendingCharacterWriteQueueProvider._();

/// File de synchro hors-ligne PV/XP (`PendingCharacterWrites`), consommée par
/// `SupabaseCharacterRepository`/`PendingCharacterWriteSyncer` — voir
/// `features/characters/presentation/providers/character_providers.dart`.

final class PendingCharacterWriteQueueProvider
    extends
        $FunctionalProvider<
          PendingCharacterWriteQueue,
          PendingCharacterWriteQueue,
          PendingCharacterWriteQueue
        >
    with $Provider<PendingCharacterWriteQueue> {
  /// File de synchro hors-ligne PV/XP (`PendingCharacterWrites`), consommée par
  /// `SupabaseCharacterRepository`/`PendingCharacterWriteSyncer` — voir
  /// `features/characters/presentation/providers/character_providers.dart`.
  PendingCharacterWriteQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingCharacterWriteQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingCharacterWriteQueueHash();

  @$internal
  @override
  $ProviderElement<PendingCharacterWriteQueue> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingCharacterWriteQueue create(Ref ref) {
    return pendingCharacterWriteQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingCharacterWriteQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingCharacterWriteQueue>(value),
    );
  }
}

String _$pendingCharacterWriteQueueHash() =>
    r'd9cebe9c03623117fcd6f08438aaf07e1495091e';
