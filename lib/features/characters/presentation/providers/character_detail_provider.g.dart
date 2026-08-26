// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Détail complet d'un personnage (onglet "Personnage" de la fiche,
/// `presentation/character_detail_screen.dart`), en famille par
/// [characterId].
///
/// Mêmes réglages que [characters] (`character_providers.dart`) :
/// `autoDispose` par défaut (pas besoin de survivre à la fermeture de
/// l'écran), et `retry: null` pour ne jamais masquer une erreur persistante
/// derrière des tentatives automatiques silencieuses — l'écran expose son
/// propre bouton "Réessayer".
///
/// Invalidé explicitement par les écritures de la fiche (ajustement PV,
/// upload/suppression de portrait) plutôt que rafraîchi automatiquement :
/// même pattern que `charactersProvider.invalidate()` après
/// `CharacterCreationRepository.createCharacter` (`summary_step_screen.dart`).

@ProviderFor(characterDetail)
final characterDetailProvider = CharacterDetailFamily._();

/// Détail complet d'un personnage (onglet "Personnage" de la fiche,
/// `presentation/character_detail_screen.dart`), en famille par
/// [characterId].
///
/// Mêmes réglages que [characters] (`character_providers.dart`) :
/// `autoDispose` par défaut (pas besoin de survivre à la fermeture de
/// l'écran), et `retry: null` pour ne jamais masquer une erreur persistante
/// derrière des tentatives automatiques silencieuses — l'écran expose son
/// propre bouton "Réessayer".
///
/// Invalidé explicitement par les écritures de la fiche (ajustement PV,
/// upload/suppression de portrait) plutôt que rafraîchi automatiquement :
/// même pattern que `charactersProvider.invalidate()` après
/// `CharacterCreationRepository.createCharacter` (`summary_step_screen.dart`).

final class CharacterDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<CharacterDetail>,
          CharacterDetail,
          FutureOr<CharacterDetail>
        >
    with $FutureModifier<CharacterDetail>, $FutureProvider<CharacterDetail> {
  /// Détail complet d'un personnage (onglet "Personnage" de la fiche,
  /// `presentation/character_detail_screen.dart`), en famille par
  /// [characterId].
  ///
  /// Mêmes réglages que [characters] (`character_providers.dart`) :
  /// `autoDispose` par défaut (pas besoin de survivre à la fermeture de
  /// l'écran), et `retry: null` pour ne jamais masquer une erreur persistante
  /// derrière des tentatives automatiques silencieuses — l'écran expose son
  /// propre bouton "Réessayer".
  ///
  /// Invalidé explicitement par les écritures de la fiche (ajustement PV,
  /// upload/suppression de portrait) plutôt que rafraîchi automatiquement :
  /// même pattern que `charactersProvider.invalidate()` après
  /// `CharacterCreationRepository.createCharacter` (`summary_step_screen.dart`).
  CharacterDetailProvider._({
    required CharacterDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'characterDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$characterDetailHash();

  @override
  String toString() {
    return r'characterDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CharacterDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CharacterDetail> create(Ref ref) {
    final argument = this.argument as String;
    return characterDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CharacterDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$characterDetailHash() => r'46488f531b5af874269ae3ebc76918d9e1e1754e';

/// Détail complet d'un personnage (onglet "Personnage" de la fiche,
/// `presentation/character_detail_screen.dart`), en famille par
/// [characterId].
///
/// Mêmes réglages que [characters] (`character_providers.dart`) :
/// `autoDispose` par défaut (pas besoin de survivre à la fermeture de
/// l'écran), et `retry: null` pour ne jamais masquer une erreur persistante
/// derrière des tentatives automatiques silencieuses — l'écran expose son
/// propre bouton "Réessayer".
///
/// Invalidé explicitement par les écritures de la fiche (ajustement PV,
/// upload/suppression de portrait) plutôt que rafraîchi automatiquement :
/// même pattern que `charactersProvider.invalidate()` après
/// `CharacterCreationRepository.createCharacter` (`summary_step_screen.dart`).

final class CharacterDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CharacterDetail>, String> {
  CharacterDetailFamily._()
    : super(
        retry: _noRetry,
        name: r'characterDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Détail complet d'un personnage (onglet "Personnage" de la fiche,
  /// `presentation/character_detail_screen.dart`), en famille par
  /// [characterId].
  ///
  /// Mêmes réglages que [characters] (`character_providers.dart`) :
  /// `autoDispose` par défaut (pas besoin de survivre à la fermeture de
  /// l'écran), et `retry: null` pour ne jamais masquer une erreur persistante
  /// derrière des tentatives automatiques silencieuses — l'écran expose son
  /// propre bouton "Réessayer".
  ///
  /// Invalidé explicitement par les écritures de la fiche (ajustement PV,
  /// upload/suppression de portrait) plutôt que rafraîchi automatiquement :
  /// même pattern que `charactersProvider.invalidate()` après
  /// `CharacterCreationRepository.createCharacter` (`summary_step_screen.dart`).

  CharacterDetailProvider call(String characterId) =>
      CharacterDetailProvider._(argument: characterId, from: this);

  @override
  String toString() => r'characterDetailProvider';
}
