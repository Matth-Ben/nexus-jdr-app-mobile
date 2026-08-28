// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_up_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").

@ProviderFor(levelUpStepData)
final levelUpStepDataProvider = LevelUpStepDataFamily._();

/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").

final class LevelUpStepDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<LevelUpStepData>,
          LevelUpStepData,
          FutureOr<LevelUpStepData>
        >
    with $FutureModifier<LevelUpStepData>, $FutureProvider<LevelUpStepData> {
  /// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
  /// `retry: null` pour ne jamais masquer une erreur persistante derrière des
  /// tentatives automatiques silencieuses (l'écran expose son propre bouton
  /// "Réessayer").
  LevelUpStepDataProvider._({
    required LevelUpStepDataFamily super.from,
    required ({String characterId, int targetLevel}) super.argument,
  }) : super(
         retry: _noRetry,
         name: r'levelUpStepDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$levelUpStepDataHash();

  @override
  String toString() {
    return r'levelUpStepDataProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<LevelUpStepData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LevelUpStepData> create(Ref ref) {
    final argument = this.argument as ({String characterId, int targetLevel});
    return levelUpStepData(
      ref,
      characterId: argument.characterId,
      targetLevel: argument.targetLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LevelUpStepDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$levelUpStepDataHash() => r'3f8961c0c569eb08f7e0a0b2be1a4b1d6f0fcbdf';

/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").

final class LevelUpStepDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<LevelUpStepData>,
          ({String characterId, int targetLevel})
        > {
  LevelUpStepDataFamily._()
    : super(
        retry: _noRetry,
        name: r'levelUpStepDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
  /// `retry: null` pour ne jamais masquer une erreur persistante derrière des
  /// tentatives automatiques silencieuses (l'écran expose son propre bouton
  /// "Réessayer").

  LevelUpStepDataProvider call({
    required String characterId,
    required int targetLevel,
  }) => LevelUpStepDataProvider._(
    argument: (characterId: characterId, targetLevel: targetLevel),
    from: this,
  );

  @override
  String toString() => r'levelUpStepDataProvider';
}
