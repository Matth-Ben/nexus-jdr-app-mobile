// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lineage_choice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lineageChoiceRepository)
final lineageChoiceRepositoryProvider = LineageChoiceRepositoryProvider._();

final class LineageChoiceRepositoryProvider
    extends
        $FunctionalProvider<
          LineageChoiceRepository,
          LineageChoiceRepository,
          LineageChoiceRepository
        >
    with $Provider<LineageChoiceRepository> {
  LineageChoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lineageChoiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lineageChoiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<LineageChoiceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LineageChoiceRepository create(Ref ref) {
    return lineageChoiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LineageChoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LineageChoiceRepository>(value),
    );
  }
}

String _$lineageChoiceRepositoryHash() =>
    r'9a6e876168e9cb0cab379c9ab26e3fc714a1a896';

/// Lignées à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
/// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
/// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
/// retry automatique : même rationale que `subclassChoiceCatalogProvider`
/// (l'écran expose son propre bouton « Réessayer »).
///
/// `family` paramétrée par [edition] (`CharacterCreationDraft.edition`) —
/// chantier "différenciation 2014/2024 pour les races" (24/10/2026) : le
/// Drakéide a un jeu d'ascendances RAW distinct par édition
/// (`race_lineages.lineage_group`), voir `data/lineage_choice_repository.dart`.
/// Une instance par édition effectivement utilisée pendant une session de
/// création (au plus deux : celle du brouillon, et `'2024'` explicitement
/// pour le lookup du legs "Infernal" du Tieffelin en 2014 — voir
/// `presentation/race_step_screen.dart::_submit`).

@ProviderFor(lineageChoiceCatalog)
final lineageChoiceCatalogProvider = LineageChoiceCatalogFamily._();

/// Lignées à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
/// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
/// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
/// retry automatique : même rationale que `subclassChoiceCatalogProvider`
/// (l'écran expose son propre bouton « Réessayer »).
///
/// `family` paramétrée par [edition] (`CharacterCreationDraft.edition`) —
/// chantier "différenciation 2014/2024 pour les races" (24/10/2026) : le
/// Drakéide a un jeu d'ascendances RAW distinct par édition
/// (`race_lineages.lineage_group`), voir `data/lineage_choice_repository.dart`.
/// Une instance par édition effectivement utilisée pendant une session de
/// création (au plus deux : celle du brouillon, et `'2024'` explicitement
/// pour le lookup du legs "Infernal" du Tieffelin en 2014 — voir
/// `presentation/race_step_screen.dart::_submit`).

final class LineageChoiceCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<LineageChoiceCatalog>,
          LineageChoiceCatalog,
          FutureOr<LineageChoiceCatalog>
        >
    with
        $FutureModifier<LineageChoiceCatalog>,
        $FutureProvider<LineageChoiceCatalog> {
  /// Lignées à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
  /// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
  /// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
  /// retry automatique : même rationale que `subclassChoiceCatalogProvider`
  /// (l'écran expose son propre bouton « Réessayer »).
  ///
  /// `family` paramétrée par [edition] (`CharacterCreationDraft.edition`) —
  /// chantier "différenciation 2014/2024 pour les races" (24/10/2026) : le
  /// Drakéide a un jeu d'ascendances RAW distinct par édition
  /// (`race_lineages.lineage_group`), voir `data/lineage_choice_repository.dart`.
  /// Une instance par édition effectivement utilisée pendant une session de
  /// création (au plus deux : celle du brouillon, et `'2024'` explicitement
  /// pour le lookup du legs "Infernal" du Tieffelin en 2014 — voir
  /// `presentation/race_step_screen.dart::_submit`).
  LineageChoiceCatalogProvider._({
    required LineageChoiceCatalogFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'lineageChoiceCatalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lineageChoiceCatalogHash();

  @override
  String toString() {
    return r'lineageChoiceCatalogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LineageChoiceCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LineageChoiceCatalog> create(Ref ref) {
    final argument = this.argument as String;
    return lineageChoiceCatalog(ref, edition: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LineageChoiceCatalogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lineageChoiceCatalogHash() =>
    r'280292f33cdcad5226d6251ce1bf32f9527af79e';

/// Lignées à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
/// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
/// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
/// retry automatique : même rationale que `subclassChoiceCatalogProvider`
/// (l'écran expose son propre bouton « Réessayer »).
///
/// `family` paramétrée par [edition] (`CharacterCreationDraft.edition`) —
/// chantier "différenciation 2014/2024 pour les races" (24/10/2026) : le
/// Drakéide a un jeu d'ascendances RAW distinct par édition
/// (`race_lineages.lineage_group`), voir `data/lineage_choice_repository.dart`.
/// Une instance par édition effectivement utilisée pendant une session de
/// création (au plus deux : celle du brouillon, et `'2024'` explicitement
/// pour le lookup du legs "Infernal" du Tieffelin en 2014 — voir
/// `presentation/race_step_screen.dart::_submit`).

final class LineageChoiceCatalogFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LineageChoiceCatalog>, String> {
  LineageChoiceCatalogFamily._()
    : super(
        retry: _noRetry,
        name: r'lineageChoiceCatalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Lignées à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
  /// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
  /// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
  /// retry automatique : même rationale que `subclassChoiceCatalogProvider`
  /// (l'écran expose son propre bouton « Réessayer »).
  ///
  /// `family` paramétrée par [edition] (`CharacterCreationDraft.edition`) —
  /// chantier "différenciation 2014/2024 pour les races" (24/10/2026) : le
  /// Drakéide a un jeu d'ascendances RAW distinct par édition
  /// (`race_lineages.lineage_group`), voir `data/lineage_choice_repository.dart`.
  /// Une instance par édition effectivement utilisée pendant une session de
  /// création (au plus deux : celle du brouillon, et `'2024'` explicitement
  /// pour le lookup du legs "Infernal" du Tieffelin en 2014 — voir
  /// `presentation/race_step_screen.dart::_submit`).

  LineageChoiceCatalogProvider call({required String edition}) =>
      LineageChoiceCatalogProvider._(argument: edition, from: this);

  @override
  String toString() => r'lineageChoiceCatalogProvider';
}
