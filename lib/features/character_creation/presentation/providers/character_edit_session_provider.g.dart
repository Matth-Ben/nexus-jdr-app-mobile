// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_edit_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(characterEditRepository)
final characterEditRepositoryProvider = CharacterEditRepositoryProvider._();

final class CharacterEditRepositoryProvider
    extends
        $FunctionalProvider<
          CharacterEditRepository,
          CharacterEditRepository,
          CharacterEditRepository
        >
    with $Provider<CharacterEditRepository> {
  CharacterEditRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterEditRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterEditRepositoryHash();

  @$internal
  @override
  $ProviderElement<CharacterEditRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterEditRepository create(Ref ref) {
    return characterEditRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterEditRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterEditRepository>(value),
    );
  }
}

String _$characterEditRepositoryHash() =>
    r'cab43bbf4769cdde11a5844e86a6722db8321c8e';

@ProviderFor(CharacterEditSessionController)
final characterEditSessionControllerProvider =
    CharacterEditSessionControllerProvider._();

final class CharacterEditSessionControllerProvider
    extends
        $NotifierProvider<
          CharacterEditSessionController,
          CharacterEditSession?
        > {
  CharacterEditSessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterEditSessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterEditSessionControllerHash();

  @$internal
  @override
  CharacterEditSessionController create() => CharacterEditSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterEditSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterEditSession?>(value),
    );
  }
}

String _$characterEditSessionControllerHash() =>
    r'8eb679a8e72bb71240b222ae60f244492e6d6c57';

abstract class _$CharacterEditSessionController
    extends $Notifier<CharacterEditSession?> {
  CharacterEditSession? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CharacterEditSession?, CharacterEditSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CharacterEditSession?, CharacterEditSession?>,
              CharacterEditSession?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
