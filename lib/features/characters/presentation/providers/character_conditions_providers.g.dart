// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_conditions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Écriture des conditions d'un personnage (P6) — voir
/// `CharacterConditionsRepository`.

@ProviderFor(characterConditionsRepository)
final characterConditionsRepositoryProvider =
    CharacterConditionsRepositoryProvider._();

/// Écriture des conditions d'un personnage (P6) — voir
/// `CharacterConditionsRepository`.

final class CharacterConditionsRepositoryProvider
    extends
        $FunctionalProvider<
          CharacterConditionsRepository,
          CharacterConditionsRepository,
          CharacterConditionsRepository
        >
    with $Provider<CharacterConditionsRepository> {
  /// Écriture des conditions d'un personnage (P6) — voir
  /// `CharacterConditionsRepository`.
  CharacterConditionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterConditionsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterConditionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CharacterConditionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterConditionsRepository create(Ref ref) {
    return characterConditionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterConditionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterConditionsRepository>(
        value,
      ),
    );
  }
}

String _$characterConditionsRepositoryHash() =>
    r'3b2b04a3ba9de05e74bd186da4b820c06a9a50b7';
