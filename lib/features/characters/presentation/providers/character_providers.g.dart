// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(characterRepository)
final characterRepositoryProvider = CharacterRepositoryProvider._();

final class CharacterRepositoryProvider
    extends
        $FunctionalProvider<
          CharacterRepository,
          CharacterRepository,
          CharacterRepository
        >
    with $Provider<CharacterRepository> {
  CharacterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterRepositoryHash();

  @$internal
  @override
  $ProviderElement<CharacterRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterRepository create(Ref ref) {
    return characterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterRepository>(value),
    );
  }
}

String _$characterRepositoryHash() =>
    r'14fa9bc4cb41794be0089f9e7c151ca35c3e6fee';

/// Liste des personnages du joueur connecté, exposée à
/// `CharacterListScreen`.
///
/// Volontairement `autoDispose` (comportement par défaut du générateur) :
/// contrairement à l'état d'authentification, cette liste n'a pas besoin de
/// survivre à la fermeture de l'écran qui l'affiche. `ref.invalidate(
/// charactersProvider)` (bouton "Réessayer" de l'état d'erreur) relance un
/// nouvel appel.
///
/// `retry: null` désactive les tentatives automatiques en arrière-plan de
/// Riverpod 3 (comportement par défaut : relances illimitées avec backoff
/// exponentiel sur toute erreur) : l'écran expose déjà un bouton "Réessayer"
/// explicite pour l'état d'erreur, une relance automatique et silencieuse
/// masquerait une erreur persistante (ex. session expirée) derrière des
/// appels réseau répétés sans que le joueur en soit informé.

@ProviderFor(characters)
final charactersProvider = CharactersProvider._();

/// Liste des personnages du joueur connecté, exposée à
/// `CharacterListScreen`.
///
/// Volontairement `autoDispose` (comportement par défaut du générateur) :
/// contrairement à l'état d'authentification, cette liste n'a pas besoin de
/// survivre à la fermeture de l'écran qui l'affiche. `ref.invalidate(
/// charactersProvider)` (bouton "Réessayer" de l'état d'erreur) relance un
/// nouvel appel.
///
/// `retry: null` désactive les tentatives automatiques en arrière-plan de
/// Riverpod 3 (comportement par défaut : relances illimitées avec backoff
/// exponentiel sur toute erreur) : l'écran expose déjà un bouton "Réessayer"
/// explicite pour l'état d'erreur, une relance automatique et silencieuse
/// masquerait une erreur persistante (ex. session expirée) derrière des
/// appels réseau répétés sans que le joueur en soit informé.

final class CharactersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CharacterSummary>>,
          List<CharacterSummary>,
          FutureOr<List<CharacterSummary>>
        >
    with
        $FutureModifier<List<CharacterSummary>>,
        $FutureProvider<List<CharacterSummary>> {
  /// Liste des personnages du joueur connecté, exposée à
  /// `CharacterListScreen`.
  ///
  /// Volontairement `autoDispose` (comportement par défaut du générateur) :
  /// contrairement à l'état d'authentification, cette liste n'a pas besoin de
  /// survivre à la fermeture de l'écran qui l'affiche. `ref.invalidate(
  /// charactersProvider)` (bouton "Réessayer" de l'état d'erreur) relance un
  /// nouvel appel.
  ///
  /// `retry: null` désactive les tentatives automatiques en arrière-plan de
  /// Riverpod 3 (comportement par défaut : relances illimitées avec backoff
  /// exponentiel sur toute erreur) : l'écran expose déjà un bouton "Réessayer"
  /// explicite pour l'état d'erreur, une relance automatique et silencieuse
  /// masquerait une erreur persistante (ex. session expirée) derrière des
  /// appels réseau répétés sans que le joueur en soit informé.
  CharactersProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'charactersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$charactersHash();

  @$internal
  @override
  $FutureProviderElement<List<CharacterSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CharacterSummary>> create(Ref ref) {
    return characters(ref);
  }
}

String _$charactersHash() => r'3a8e32a7a9df2817331ea519b8e72b7ca49ec5ad';
