// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_locale_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountLocaleRepository)
final accountLocaleRepositoryProvider = AccountLocaleRepositoryProvider._();

final class AccountLocaleRepositoryProvider
    extends
        $FunctionalProvider<
          AccountLocaleRepository,
          AccountLocaleRepository,
          AccountLocaleRepository
        >
    with $Provider<AccountLocaleRepository> {
  AccountLocaleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountLocaleRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountLocaleRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountLocaleRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountLocaleRepository create(Ref ref) {
    return accountLocaleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountLocaleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountLocaleRepository>(value),
    );
  }
}

String _$accountLocaleRepositoryHash() =>
    r'5261bd187ddede1d2b0173b508b0214fca8d3dbc';

/// [AccountLocaleSync] de l'app (`keepAlive`) : réessaie à chaque connexion
/// effective (`signedIn`, reprise de session) et au retour du réseau.

@ProviderFor(accountLocaleSync)
final accountLocaleSyncProvider = AccountLocaleSyncProvider._();

/// [AccountLocaleSync] de l'app (`keepAlive`) : réessaie à chaque connexion
/// effective (`signedIn`, reprise de session) et au retour du réseau.

final class AccountLocaleSyncProvider
    extends
        $FunctionalProvider<
          AccountLocaleSync,
          AccountLocaleSync,
          AccountLocaleSync
        >
    with $Provider<AccountLocaleSync> {
  /// [AccountLocaleSync] de l'app (`keepAlive`) : réessaie à chaque connexion
  /// effective (`signedIn`, reprise de session) et au retour du réseau.
  AccountLocaleSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountLocaleSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountLocaleSyncHash();

  @$internal
  @override
  $ProviderElement<AccountLocaleSync> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountLocaleSync create(Ref ref) {
    return accountLocaleSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountLocaleSync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountLocaleSync>(value),
    );
  }
}

String _$accountLocaleSyncHash() => r'c21f3ac1d0b8b8491970b0b11260c9049f261768';
