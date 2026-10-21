// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subclass_feature_choice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subclassFeatureChoiceRepository)
final subclassFeatureChoiceRepositoryProvider =
    SubclassFeatureChoiceRepositoryProvider._();

final class SubclassFeatureChoiceRepositoryProvider
    extends
        $FunctionalProvider<
          SubclassFeatureChoiceRepository,
          SubclassFeatureChoiceRepository,
          SubclassFeatureChoiceRepository
        >
    with $Provider<SubclassFeatureChoiceRepository> {
  SubclassFeatureChoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subclassFeatureChoiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subclassFeatureChoiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubclassFeatureChoiceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubclassFeatureChoiceRepository create(Ref ref) {
    return subclassFeatureChoiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubclassFeatureChoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubclassFeatureChoiceRepository>(
        value,
      ),
    );
  }
}

String _$subclassFeatureChoiceRepositoryHash() =>
    r'cd9ef2b1ff859486085942e60477ac394432f1e1';

/// Second choix de niveau 1 de la sous-classe [subclassId] (ex. Ancêtre
/// draconique), `null` si cette sous-classe n'en a pas — exposé à
/// `SubclassFeatureChoiceBlock` (correctif D99, `docs/dette-technique.md`).
/// `autoDispose`, pas de retry automatique : même rationale que
/// `subclassChoiceCatalogProvider` (l'écran expose son propre bouton
/// « Réessayer »).

@ProviderFor(subclassFeatureChoice)
final subclassFeatureChoiceProvider = SubclassFeatureChoiceFamily._();

/// Second choix de niveau 1 de la sous-classe [subclassId] (ex. Ancêtre
/// draconique), `null` si cette sous-classe n'en a pas — exposé à
/// `SubclassFeatureChoiceBlock` (correctif D99, `docs/dette-technique.md`).
/// `autoDispose`, pas de retry automatique : même rationale que
/// `subclassChoiceCatalogProvider` (l'écran expose son propre bouton
/// « Réessayer »).

final class SubclassFeatureChoiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<SubclassFeatureChoice?>,
          SubclassFeatureChoice?,
          FutureOr<SubclassFeatureChoice?>
        >
    with
        $FutureModifier<SubclassFeatureChoice?>,
        $FutureProvider<SubclassFeatureChoice?> {
  /// Second choix de niveau 1 de la sous-classe [subclassId] (ex. Ancêtre
  /// draconique), `null` si cette sous-classe n'en a pas — exposé à
  /// `SubclassFeatureChoiceBlock` (correctif D99, `docs/dette-technique.md`).
  /// `autoDispose`, pas de retry automatique : même rationale que
  /// `subclassChoiceCatalogProvider` (l'écran expose son propre bouton
  /// « Réessayer »).
  SubclassFeatureChoiceProvider._({
    required SubclassFeatureChoiceFamily super.from,
    required int super.argument,
  }) : super(
         retry: _noRetry,
         name: r'subclassFeatureChoiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subclassFeatureChoiceHash();

  @override
  String toString() {
    return r'subclassFeatureChoiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SubclassFeatureChoice?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SubclassFeatureChoice?> create(Ref ref) {
    final argument = this.argument as int;
    return subclassFeatureChoice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SubclassFeatureChoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subclassFeatureChoiceHash() =>
    r'b085c80b799eed3cc39d38eb8fe7c22f44aa4255';

/// Second choix de niveau 1 de la sous-classe [subclassId] (ex. Ancêtre
/// draconique), `null` si cette sous-classe n'en a pas — exposé à
/// `SubclassFeatureChoiceBlock` (correctif D99, `docs/dette-technique.md`).
/// `autoDispose`, pas de retry automatique : même rationale que
/// `subclassChoiceCatalogProvider` (l'écran expose son propre bouton
/// « Réessayer »).

final class SubclassFeatureChoiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SubclassFeatureChoice?>, int> {
  SubclassFeatureChoiceFamily._()
    : super(
        retry: _noRetry,
        name: r'subclassFeatureChoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Second choix de niveau 1 de la sous-classe [subclassId] (ex. Ancêtre
  /// draconique), `null` si cette sous-classe n'en a pas — exposé à
  /// `SubclassFeatureChoiceBlock` (correctif D99, `docs/dette-technique.md`).
  /// `autoDispose`, pas de retry automatique : même rationale que
  /// `subclassChoiceCatalogProvider` (l'écran expose son propre bouton
  /// « Réessayer »).

  SubclassFeatureChoiceProvider call(int subclassId) =>
      SubclassFeatureChoiceProvider._(argument: subclassId, from: this);

  @override
  String toString() => r'subclassFeatureChoiceProvider';
}
