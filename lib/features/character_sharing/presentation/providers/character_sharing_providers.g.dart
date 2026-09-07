// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_sharing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(characterSharingRepository)
final characterSharingRepositoryProvider =
    CharacterSharingRepositoryProvider._();

final class CharacterSharingRepositoryProvider
    extends
        $FunctionalProvider<
          CharacterSharingRepository,
          CharacterSharingRepository,
          CharacterSharingRepository
        >
    with $Provider<CharacterSharingRepository> {
  CharacterSharingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterSharingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterSharingRepositoryHash();

  @$internal
  @override
  $ProviderElement<CharacterSharingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterSharingRepository create(Ref ref) {
    return characterSharingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterSharingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterSharingRepository>(value),
    );
  }
}

String _$characterSharingRepositoryHash() =>
    r'96fa69f0bd2cefdd884671947ad72e57d01eefaf';

/// Fiche complète d'un personnage partagé, consultée sans authentification
/// via son [token] — écran "Vue en lecture seule"
/// (`presentation/shared_character_view_screen.dart`).
///
/// `autoDispose` par défaut : cet écran n'a pas besoin de survivre à sa
/// fermeture, même rationale que `charactersProvider`
/// (`features/characters/presentation/providers/character_providers.dart`).
/// `retry: null` pour la même raison que le reste de ce dépôt : l'écran
/// expose son propre bouton "Réessayer" plutôt qu'une relance automatique
/// silencieuse.

@ProviderFor(sharedCharacter)
final sharedCharacterProvider = SharedCharacterFamily._();

/// Fiche complète d'un personnage partagé, consultée sans authentification
/// via son [token] — écran "Vue en lecture seule"
/// (`presentation/shared_character_view_screen.dart`).
///
/// `autoDispose` par défaut : cet écran n'a pas besoin de survivre à sa
/// fermeture, même rationale que `charactersProvider`
/// (`features/characters/presentation/providers/character_providers.dart`).
/// `retry: null` pour la même raison que le reste de ce dépôt : l'écran
/// expose son propre bouton "Réessayer" plutôt qu'une relance automatique
/// silencieuse.

final class SharedCharacterProvider
    extends
        $FunctionalProvider<
          AsyncValue<CharacterDetail?>,
          CharacterDetail?,
          FutureOr<CharacterDetail?>
        >
    with $FutureModifier<CharacterDetail?>, $FutureProvider<CharacterDetail?> {
  /// Fiche complète d'un personnage partagé, consultée sans authentification
  /// via son [token] — écran "Vue en lecture seule"
  /// (`presentation/shared_character_view_screen.dart`).
  ///
  /// `autoDispose` par défaut : cet écran n'a pas besoin de survivre à sa
  /// fermeture, même rationale que `charactersProvider`
  /// (`features/characters/presentation/providers/character_providers.dart`).
  /// `retry: null` pour la même raison que le reste de ce dépôt : l'écran
  /// expose son propre bouton "Réessayer" plutôt qu'une relance automatique
  /// silencieuse.
  SharedCharacterProvider._({
    required SharedCharacterFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'sharedCharacterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sharedCharacterHash();

  @override
  String toString() {
    return r'sharedCharacterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CharacterDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CharacterDetail?> create(Ref ref) {
    final argument = this.argument as String;
    return sharedCharacter(ref, token: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SharedCharacterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sharedCharacterHash() => r'a5311575d6c484c0b7327a6b14c0e5728e2a62ea';

/// Fiche complète d'un personnage partagé, consultée sans authentification
/// via son [token] — écran "Vue en lecture seule"
/// (`presentation/shared_character_view_screen.dart`).
///
/// `autoDispose` par défaut : cet écran n'a pas besoin de survivre à sa
/// fermeture, même rationale que `charactersProvider`
/// (`features/characters/presentation/providers/character_providers.dart`).
/// `retry: null` pour la même raison que le reste de ce dépôt : l'écran
/// expose son propre bouton "Réessayer" plutôt qu'une relance automatique
/// silencieuse.

final class SharedCharacterFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CharacterDetail?>, String> {
  SharedCharacterFamily._()
    : super(
        retry: _noRetry,
        name: r'sharedCharacterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fiche complète d'un personnage partagé, consultée sans authentification
  /// via son [token] — écran "Vue en lecture seule"
  /// (`presentation/shared_character_view_screen.dart`).
  ///
  /// `autoDispose` par défaut : cet écran n'a pas besoin de survivre à sa
  /// fermeture, même rationale que `charactersProvider`
  /// (`features/characters/presentation/providers/character_providers.dart`).
  /// `retry: null` pour la même raison que le reste de ce dépôt : l'écran
  /// expose son propre bouton "Réessayer" plutôt qu'une relance automatique
  /// silencieuse.

  SharedCharacterProvider call({required String token}) =>
      SharedCharacterProvider._(argument: token, from: this);

  @override
  String toString() => r'sharedCharacterProvider';
}
