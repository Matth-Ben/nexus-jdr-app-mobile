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
