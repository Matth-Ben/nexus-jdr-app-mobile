// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [ConnectivityChecker] partagé par toute l'app — voir sa documentation de
/// classe. `keepAlive` : même rationale que `supabaseClientProvider`
/// (`core/network/supabase_client_provider.dart`), jamais recréé par écran.

@ProviderFor(connectivityChecker)
final connectivityCheckerProvider = ConnectivityCheckerProvider._();

/// [ConnectivityChecker] partagé par toute l'app — voir sa documentation de
/// classe. `keepAlive` : même rationale que `supabaseClientProvider`
/// (`core/network/supabase_client_provider.dart`), jamais recréé par écran.

final class ConnectivityCheckerProvider
    extends
        $FunctionalProvider<
          ConnectivityChecker,
          ConnectivityChecker,
          ConnectivityChecker
        >
    with $Provider<ConnectivityChecker> {
  /// [ConnectivityChecker] partagé par toute l'app — voir sa documentation de
  /// classe. `keepAlive` : même rationale que `supabaseClientProvider`
  /// (`core/network/supabase_client_provider.dart`), jamais recréé par écran.
  ConnectivityCheckerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityCheckerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityCheckerHash();

  @$internal
  @override
  $ProviderElement<ConnectivityChecker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConnectivityChecker create(Ref ref) {
    return connectivityChecker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectivityChecker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectivityChecker>(value),
    );
  }
}

String _$connectivityCheckerHash() =>
    r'c10b923ed52485894c40fc2e6db9833d5ae346e7';

/// État de connectivité en direct (`true` = connecté) : valeur courante puis
/// chaque changement — voir `ConnectivityChecker.onConnectivityChanged`.
/// Alimente le bandeau de synchro (`core/sync/`). Une erreur du canal de
/// plateforme est laissée à l'`AsyncValue` (le bandeau la traite comme « en
/// ligne », jamais comme un faux hors-ligne).

@ProviderFor(connectivityStatus)
final connectivityStatusProvider = ConnectivityStatusProvider._();

/// État de connectivité en direct (`true` = connecté) : valeur courante puis
/// chaque changement — voir `ConnectivityChecker.onConnectivityChanged`.
/// Alimente le bandeau de synchro (`core/sync/`). Une erreur du canal de
/// plateforme est laissée à l'`AsyncValue` (le bandeau la traite comme « en
/// ligne », jamais comme un faux hors-ligne).

final class ConnectivityStatusProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// État de connectivité en direct (`true` = connecté) : valeur courante puis
  /// chaque changement — voir `ConnectivityChecker.onConnectivityChanged`.
  /// Alimente le bandeau de synchro (`core/sync/`). Une erreur du canal de
  /// plateforme est laissée à l'`AsyncValue` (le bandeau la traite comme « en
  /// ligne », jamais comme un faux hors-ligne).
  ConnectivityStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityStatusHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return connectivityStatus(ref);
  }
}

String _$connectivityStatusHash() =>
    r'73ddb30a7baf147be964c388ae8339383b45f91e';
