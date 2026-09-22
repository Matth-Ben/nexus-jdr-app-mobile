// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pact_weapon_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Arme de pacte de l'Occultiste (Pacte de la lame) — voir
/// [PactWeaponRepository].

@ProviderFor(pactWeaponRepository)
final pactWeaponRepositoryProvider = PactWeaponRepositoryProvider._();

/// Arme de pacte de l'Occultiste (Pacte de la lame) — voir
/// [PactWeaponRepository].

final class PactWeaponRepositoryProvider
    extends
        $FunctionalProvider<
          PactWeaponRepository,
          PactWeaponRepository,
          PactWeaponRepository
        >
    with $Provider<PactWeaponRepository> {
  /// Arme de pacte de l'Occultiste (Pacte de la lame) — voir
  /// [PactWeaponRepository].
  PactWeaponRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pactWeaponRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pactWeaponRepositoryHash();

  @$internal
  @override
  $ProviderElement<PactWeaponRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PactWeaponRepository create(Ref ref) {
    return pactWeaponRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PactWeaponRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PactWeaponRepository>(value),
    );
  }
}

String _$pactWeaponRepositoryHash() =>
    r'd2d4d2c01a3fe480c4de32b620b0e8fc54137029';

/// Armes éligibles de la feuille « FORME DE L'ARME » (chargées à
/// l'ouverture de la feuille, libérées à sa fermeture).
///
/// `retry: null` : la feuille expose un bouton « Réessayer » explicite, même
/// rationale que `inventoryCatalogProvider`.

@ProviderFor(pactWeaponOptions)
final pactWeaponOptionsProvider = PactWeaponOptionsProvider._();

/// Armes éligibles de la feuille « FORME DE L'ARME » (chargées à
/// l'ouverture de la feuille, libérées à sa fermeture).
///
/// `retry: null` : la feuille expose un bouton « Réessayer » explicite, même
/// rationale que `inventoryCatalogProvider`.

final class PactWeaponOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PactWeaponOption>>,
          List<PactWeaponOption>,
          FutureOr<List<PactWeaponOption>>
        >
    with
        $FutureModifier<List<PactWeaponOption>>,
        $FutureProvider<List<PactWeaponOption>> {
  /// Armes éligibles de la feuille « FORME DE L'ARME » (chargées à
  /// l'ouverture de la feuille, libérées à sa fermeture).
  ///
  /// `retry: null` : la feuille expose un bouton « Réessayer » explicite, même
  /// rationale que `inventoryCatalogProvider`.
  PactWeaponOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'pactWeaponOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pactWeaponOptionsHash();

  @$internal
  @override
  $FutureProviderElement<List<PactWeaponOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PactWeaponOption>> create(Ref ref) {
    return pactWeaponOptions(ref);
  }
}

String _$pactWeaponOptionsHash() => r'7124ceec3a05eabfa5684324d69f53d063ee3162';
