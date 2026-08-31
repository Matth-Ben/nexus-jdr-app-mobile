// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_story_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storyInviteRepository)
final storyInviteRepositoryProvider = StoryInviteRepositoryProvider._();

final class StoryInviteRepositoryProvider
    extends
        $FunctionalProvider<
          StoryInviteRepository,
          StoryInviteRepository,
          StoryInviteRepository
        >
    with $Provider<StoryInviteRepository> {
  StoryInviteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storyInviteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storyInviteRepositoryHash();

  @$internal
  @override
  $ProviderElement<StoryInviteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StoryInviteRepository create(Ref ref) {
    return storyInviteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StoryInviteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StoryInviteRepository>(value),
    );
  }
}

String _$storyInviteRepositoryHash() =>
    r'1ca3275c84e41fdaac017d19ae56ae11dbf728c2';

/// Aperçu d'histoire de l'étape 2/4 ("Confirmation"), en famille par [code]
/// — un aperçu par code résolu, jamais partagé entre deux codes différents
/// dans la même session. `autoDispose` (comportement par défaut du
/// générateur) : ne doit pas survivre à la fermeture de cet écran.
///
/// `retry: null`, même rationale que `charactersProvider`
/// (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer"/"Modifier le code" pour
/// chaque état d'erreur (voir `presentation/join_confirmation_step_screen.dart`),
/// une relance automatique masquerait un code invalide/une invitation
/// désactivée derrière des tentatives répétées silencieuses.

@ProviderFor(storyInvitePreview)
final storyInvitePreviewProvider = StoryInvitePreviewFamily._();

/// Aperçu d'histoire de l'étape 2/4 ("Confirmation"), en famille par [code]
/// — un aperçu par code résolu, jamais partagé entre deux codes différents
/// dans la même session. `autoDispose` (comportement par défaut du
/// générateur) : ne doit pas survivre à la fermeture de cet écran.
///
/// `retry: null`, même rationale que `charactersProvider`
/// (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer"/"Modifier le code" pour
/// chaque état d'erreur (voir `presentation/join_confirmation_step_screen.dart`),
/// une relance automatique masquerait un code invalide/une invitation
/// désactivée derrière des tentatives répétées silencieuses.

final class StoryInvitePreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<StoryPreview>,
          StoryPreview,
          FutureOr<StoryPreview>
        >
    with $FutureModifier<StoryPreview>, $FutureProvider<StoryPreview> {
  /// Aperçu d'histoire de l'étape 2/4 ("Confirmation"), en famille par [code]
  /// — un aperçu par code résolu, jamais partagé entre deux codes différents
  /// dans la même session. `autoDispose` (comportement par défaut du
  /// générateur) : ne doit pas survivre à la fermeture de cet écran.
  ///
  /// `retry: null`, même rationale que `charactersProvider`
  /// (`features/characters/presentation/providers/character_providers.dart`) :
  /// l'écran expose son propre bouton "Réessayer"/"Modifier le code" pour
  /// chaque état d'erreur (voir `presentation/join_confirmation_step_screen.dart`),
  /// une relance automatique masquerait un code invalide/une invitation
  /// désactivée derrière des tentatives répétées silencieuses.
  StoryInvitePreviewProvider._({
    required StoryInvitePreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'storyInvitePreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$storyInvitePreviewHash();

  @override
  String toString() {
    return r'storyInvitePreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StoryPreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StoryPreview> create(Ref ref) {
    final argument = this.argument as String;
    return storyInvitePreview(ref, code: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StoryInvitePreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$storyInvitePreviewHash() =>
    r'bc63d15be2161edfd76ebe40ff286130e56fca9b';

/// Aperçu d'histoire de l'étape 2/4 ("Confirmation"), en famille par [code]
/// — un aperçu par code résolu, jamais partagé entre deux codes différents
/// dans la même session. `autoDispose` (comportement par défaut du
/// générateur) : ne doit pas survivre à la fermeture de cet écran.
///
/// `retry: null`, même rationale que `charactersProvider`
/// (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer"/"Modifier le code" pour
/// chaque état d'erreur (voir `presentation/join_confirmation_step_screen.dart`),
/// une relance automatique masquerait un code invalide/une invitation
/// désactivée derrière des tentatives répétées silencieuses.

final class StoryInvitePreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StoryPreview>, String> {
  StoryInvitePreviewFamily._()
    : super(
        retry: _noRetry,
        name: r'storyInvitePreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Aperçu d'histoire de l'étape 2/4 ("Confirmation"), en famille par [code]
  /// — un aperçu par code résolu, jamais partagé entre deux codes différents
  /// dans la même session. `autoDispose` (comportement par défaut du
  /// générateur) : ne doit pas survivre à la fermeture de cet écran.
  ///
  /// `retry: null`, même rationale que `charactersProvider`
  /// (`features/characters/presentation/providers/character_providers.dart`) :
  /// l'écran expose son propre bouton "Réessayer"/"Modifier le code" pour
  /// chaque état d'erreur (voir `presentation/join_confirmation_step_screen.dart`),
  /// une relance automatique masquerait un code invalide/une invitation
  /// désactivée derrière des tentatives répétées silencieuses.

  StoryInvitePreviewProvider call({required String code}) =>
      StoryInvitePreviewProvider._(argument: code, from: this);

  @override
  String toString() => r'storyInvitePreviewProvider';
}
