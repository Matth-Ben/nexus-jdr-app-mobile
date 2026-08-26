// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_creation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(characterCreationRepository)
final characterCreationRepositoryProvider =
    CharacterCreationRepositoryProvider._();

final class CharacterCreationRepositoryProvider
    extends
        $FunctionalProvider<
          CharacterCreationRepository,
          CharacterCreationRepository,
          CharacterCreationRepository
        >
    with $Provider<CharacterCreationRepository> {
  CharacterCreationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterCreationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterCreationRepositoryHash();

  @$internal
  @override
  $ProviderElement<CharacterCreationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterCreationRepository create(Ref ref) {
    return characterCreationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterCreationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterCreationRepository>(value),
    );
  }
}

String _$characterCreationRepositoryHash() =>
    r'a2ea1c4efe3890562483ad09928d9f290a1cda84';

/// Catalogue races/sous-races de l'étape 1/9, exposé à `RaceStepScreen`.
///
/// `autoDispose` (comportement par défaut du générateur) : pas besoin de
/// survivre à la fermeture de l'écran, contrairement au brouillon de
/// création (`character_creation_draft_provider.dart`) qui doit persister
/// pendant toute la session de création. `retry: null` pour la même raison
/// que `charactersProvider` (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer" plutôt que de masquer une
/// erreur persistante derrière des tentatives automatiques silencieuses.

@ProviderFor(raceCatalog)
final raceCatalogProvider = RaceCatalogProvider._();

/// Catalogue races/sous-races de l'étape 1/9, exposé à `RaceStepScreen`.
///
/// `autoDispose` (comportement par défaut du générateur) : pas besoin de
/// survivre à la fermeture de l'écran, contrairement au brouillon de
/// création (`character_creation_draft_provider.dart`) qui doit persister
/// pendant toute la session de création. `retry: null` pour la même raison
/// que `charactersProvider` (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer" plutôt que de masquer une
/// erreur persistante derrière des tentatives automatiques silencieuses.

final class RaceCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<RaceCatalog>,
          RaceCatalog,
          FutureOr<RaceCatalog>
        >
    with $FutureModifier<RaceCatalog>, $FutureProvider<RaceCatalog> {
  /// Catalogue races/sous-races de l'étape 1/9, exposé à `RaceStepScreen`.
  ///
  /// `autoDispose` (comportement par défaut du générateur) : pas besoin de
  /// survivre à la fermeture de l'écran, contrairement au brouillon de
  /// création (`character_creation_draft_provider.dart`) qui doit persister
  /// pendant toute la session de création. `retry: null` pour la même raison
  /// que `charactersProvider` (`features/characters/presentation/providers/character_providers.dart`) :
  /// l'écran expose son propre bouton "Réessayer" plutôt que de masquer une
  /// erreur persistante derrière des tentatives automatiques silencieuses.
  RaceCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'raceCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$raceCatalogHash();

  @$internal
  @override
  $FutureProviderElement<RaceCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RaceCatalog> create(Ref ref) {
    return raceCatalog(ref);
  }
}

String _$raceCatalogHash() => r'8c79727f6540a4acf682a33db08f636ed983c91e';

/// Catalogue des classes de l'étape 2/9, exposé à `ClassStepScreen` — même
/// rationale que [raceCatalog] (`autoDispose`, pas de retry automatique).

@ProviderFor(classCatalog)
final classCatalogProvider = ClassCatalogProvider._();

/// Catalogue des classes de l'étape 2/9, exposé à `ClassStepScreen` — même
/// rationale que [raceCatalog] (`autoDispose`, pas de retry automatique).

final class ClassCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClassCatalog>,
          ClassCatalog,
          FutureOr<ClassCatalog>
        >
    with $FutureModifier<ClassCatalog>, $FutureProvider<ClassCatalog> {
  /// Catalogue des classes de l'étape 2/9, exposé à `ClassStepScreen` — même
  /// rationale que [raceCatalog] (`autoDispose`, pas de retry automatique).
  ClassCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'classCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classCatalogHash();

  @$internal
  @override
  $FutureProviderElement<ClassCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClassCatalog> create(Ref ref) {
    return classCatalog(ref);
  }
}

String _$classCatalogHash() => r'009b8c24097214888340d26f51ffe44117da5b3f';

/// Catalogue des historiques de l'étape 3/9, exposé à `BackgroundStepScreen`
/// — même rationale que [raceCatalog]/[classCatalog] (`autoDispose`, pas de
/// retry automatique).

@ProviderFor(backgroundCatalog)
final backgroundCatalogProvider = BackgroundCatalogProvider._();

/// Catalogue des historiques de l'étape 3/9, exposé à `BackgroundStepScreen`
/// — même rationale que [raceCatalog]/[classCatalog] (`autoDispose`, pas de
/// retry automatique).

final class BackgroundCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<BackgroundCatalog>,
          BackgroundCatalog,
          FutureOr<BackgroundCatalog>
        >
    with
        $FutureModifier<BackgroundCatalog>,
        $FutureProvider<BackgroundCatalog> {
  /// Catalogue des historiques de l'étape 3/9, exposé à `BackgroundStepScreen`
  /// — même rationale que [raceCatalog]/[classCatalog] (`autoDispose`, pas de
  /// retry automatique).
  BackgroundCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'backgroundCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundCatalogHash();

  @$internal
  @override
  $FutureProviderElement<BackgroundCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BackgroundCatalog> create(Ref ref) {
    return backgroundCatalog(ref);
  }
}

String _$backgroundCatalogHash() => r'f03bb8230dc30985f627cac63f3d258a06e61d5d';

/// Catalogue des outils/instruments de l'étape 5/9, exposé à
/// `SkillsAndToolsStepScreen` — même rationale que [raceCatalog]
/// (`autoDispose`, pas de retry automatique).

@ProviderFor(toolCatalog)
final toolCatalogProvider = ToolCatalogProvider._();

/// Catalogue des outils/instruments de l'étape 5/9, exposé à
/// `SkillsAndToolsStepScreen` — même rationale que [raceCatalog]
/// (`autoDispose`, pas de retry automatique).

final class ToolCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<ToolCatalog>,
          ToolCatalog,
          FutureOr<ToolCatalog>
        >
    with $FutureModifier<ToolCatalog>, $FutureProvider<ToolCatalog> {
  /// Catalogue des outils/instruments de l'étape 5/9, exposé à
  /// `SkillsAndToolsStepScreen` — même rationale que [raceCatalog]
  /// (`autoDispose`, pas de retry automatique).
  ToolCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'toolCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolCatalogHash();

  @$internal
  @override
  $FutureProviderElement<ToolCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ToolCatalog> create(Ref ref) {
    return toolCatalog(ref);
  }
}

String _$toolCatalogHash() => r'fc8c55981cc99895e180f79d1e3abfc1e514a451';

/// Catalogue des langues de l'étape 5/9, exposé à `SkillsAndToolsStepScreen`
/// — même rationale que [raceCatalog] (`autoDispose`, pas de retry
/// automatique).

@ProviderFor(languageCatalog)
final languageCatalogProvider = LanguageCatalogProvider._();

/// Catalogue des langues de l'étape 5/9, exposé à `SkillsAndToolsStepScreen`
/// — même rationale que [raceCatalog] (`autoDispose`, pas de retry
/// automatique).

final class LanguageCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<LanguageCatalog>,
          LanguageCatalog,
          FutureOr<LanguageCatalog>
        >
    with $FutureModifier<LanguageCatalog>, $FutureProvider<LanguageCatalog> {
  /// Catalogue des langues de l'étape 5/9, exposé à `SkillsAndToolsStepScreen`
  /// — même rationale que [raceCatalog] (`autoDispose`, pas de retry
  /// automatique).
  LanguageCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'languageCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageCatalogHash();

  @$internal
  @override
  $FutureProviderElement<LanguageCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LanguageCatalog> create(Ref ref) {
    return languageCatalog(ref);
  }
}

String _$languageCatalogHash() => r'8a9e87cda7d631331b87853fe52dd2777b67525c';

@ProviderFor(skillsAndToolsStepData)
final skillsAndToolsStepDataProvider = SkillsAndToolsStepDataProvider._();

final class SkillsAndToolsStepDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<SkillsAndToolsStepData>,
          SkillsAndToolsStepData,
          FutureOr<SkillsAndToolsStepData>
        >
    with
        $FutureModifier<SkillsAndToolsStepData>,
        $FutureProvider<SkillsAndToolsStepData> {
  SkillsAndToolsStepDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'skillsAndToolsStepDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillsAndToolsStepDataHash();

  @$internal
  @override
  $FutureProviderElement<SkillsAndToolsStepData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SkillsAndToolsStepData> create(Ref ref) {
    return skillsAndToolsStepData(ref);
  }
}

String _$skillsAndToolsStepDataHash() =>
    r'baaeb5eafc430a19a126f1e0e291e21e36fd8ff5';
