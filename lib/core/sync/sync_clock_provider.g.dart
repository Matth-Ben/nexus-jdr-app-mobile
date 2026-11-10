// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Horloge de l'UI de synchro (libellé « Dernière synchronisation » du
/// Profil) — `DateTime.now` par défaut, surchargeable dans les tests.

@ProviderFor(syncClock)
final syncClockProvider = SyncClockProvider._();

/// Horloge de l'UI de synchro (libellé « Dernière synchronisation » du
/// Profil) — `DateTime.now` par défaut, surchargeable dans les tests.

final class SyncClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Horloge de l'UI de synchro (libellé « Dernière synchronisation » du
  /// Profil) — `DateTime.now` par défaut, surchargeable dans les tests.
  SyncClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return syncClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$syncClockHash() => r'c02b1d0a7e2e6d34fcd79235b527cfb9a1f4e513';
