// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `true` tant qu'au moins une passe de synchro de la file hors-ligne est en
/// cours — publié par `CharacterWriteSyncCoordinator` (features/characters),
/// lu par le bandeau de synchro. Compteur interne : deux passes qui se
/// chevauchent ne repassent à `false` qu'à la fin de la dernière.

@ProviderFor(SyncActivity)
final syncActivityProvider = SyncActivityProvider._();

/// `true` tant qu'au moins une passe de synchro de la file hors-ligne est en
/// cours — publié par `CharacterWriteSyncCoordinator` (features/characters),
/// lu par le bandeau de synchro. Compteur interne : deux passes qui se
/// chevauchent ne repassent à `false` qu'à la fin de la dernière.
final class SyncActivityProvider extends $NotifierProvider<SyncActivity, bool> {
  /// `true` tant qu'au moins une passe de synchro de la file hors-ligne est en
  /// cours — publié par `CharacterWriteSyncCoordinator` (features/characters),
  /// lu par le bandeau de synchro. Compteur interne : deux passes qui se
  /// chevauchent ne repassent à `false` qu'à la fin de la dernière.
  SyncActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncActivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncActivityHash();

  @$internal
  @override
  SyncActivity create() => SyncActivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$syncActivityHash() => r'f0af9eb87db2d161561e5f034174be7bad72d12b';

/// `true` tant qu'au moins une passe de synchro de la file hors-ligne est en
/// cours — publié par `CharacterWriteSyncCoordinator` (features/characters),
/// lu par le bandeau de synchro. Compteur interne : deux passes qui se
/// chevauchent ne repassent à `false` qu'à la fin de la dernière.

abstract class _$SyncActivity extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
