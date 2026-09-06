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
///
/// [multiclassClassId] : `null` (défaut) pour continuer la classe primaire
/// (comportement historique, avant le multiclassage) ; sinon, `classes.id`
/// de la classe choisie à l'étape `classDecision` pour multiclasser — doit
/// alors être un `classId` présent dans [LevelUpStepData.multiclassOptions]
/// calculé pour le même personnage, sans quoi une [CharacterFailure] est
/// levée (cas défensif : une classe qui a cessé d'être éligible entre
/// l'affichage de `classDecision` et cet appel, ex. un score de
/// caractéristique modifié entre-temps par un autre appareil).

@ProviderFor(levelUpStepData)
final levelUpStepDataProvider = LevelUpStepDataFamily._();

/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").
///
/// [multiclassClassId] : `null` (défaut) pour continuer la classe primaire
/// (comportement historique, avant le multiclassage) ; sinon, `classes.id`
/// de la classe choisie à l'étape `classDecision` pour multiclasser — doit
/// alors être un `classId` présent dans [LevelUpStepData.multiclassOptions]
/// calculé pour le même personnage, sans quoi une [CharacterFailure] est
/// levée (cas défensif : une classe qui a cessé d'être éligible entre
/// l'affichage de `classDecision` et cet appel, ex. un score de
/// caractéristique modifié entre-temps par un autre appareil).

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
  ///
  /// [multiclassClassId] : `null` (défaut) pour continuer la classe primaire
  /// (comportement historique, avant le multiclassage) ; sinon, `classes.id`
  /// de la classe choisie à l'étape `classDecision` pour multiclasser — doit
  /// alors être un `classId` présent dans [LevelUpStepData.multiclassOptions]
  /// calculé pour le même personnage, sans quoi une [CharacterFailure] est
  /// levée (cas défensif : une classe qui a cessé d'être éligible entre
  /// l'affichage de `classDecision` et cet appel, ex. un score de
  /// caractéristique modifié entre-temps par un autre appareil).
  LevelUpStepDataProvider._({
    required LevelUpStepDataFamily super.from,
    required ({String characterId, int targetLevel, Object? multiclassClassId})
    super.argument,
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
    final argument =
        this.argument
            as ({
              String characterId,
              int targetLevel,
              Object? multiclassClassId,
            });
    return levelUpStepData(
      ref,
      characterId: argument.characterId,
      targetLevel: argument.targetLevel,
      multiclassClassId: argument.multiclassClassId,
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

String _$levelUpStepDataHash() => r'f06fde908c360295805106b684dfbdcde34210a4';

/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").
///
/// [multiclassClassId] : `null` (défaut) pour continuer la classe primaire
/// (comportement historique, avant le multiclassage) ; sinon, `classes.id`
/// de la classe choisie à l'étape `classDecision` pour multiclasser — doit
/// alors être un `classId` présent dans [LevelUpStepData.multiclassOptions]
/// calculé pour le même personnage, sans quoi une [CharacterFailure] est
/// levée (cas défensif : une classe qui a cessé d'être éligible entre
/// l'affichage de `classDecision` et cet appel, ex. un score de
/// caractéristique modifié entre-temps par un autre appareil).

final class LevelUpStepDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<LevelUpStepData>,
          ({String characterId, int targetLevel, Object? multiclassClassId})
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
  ///
  /// [multiclassClassId] : `null` (défaut) pour continuer la classe primaire
  /// (comportement historique, avant le multiclassage) ; sinon, `classes.id`
  /// de la classe choisie à l'étape `classDecision` pour multiclasser — doit
  /// alors être un `classId` présent dans [LevelUpStepData.multiclassOptions]
  /// calculé pour le même personnage, sans quoi une [CharacterFailure] est
  /// levée (cas défensif : une classe qui a cessé d'être éligible entre
  /// l'affichage de `classDecision` et cet appel, ex. un score de
  /// caractéristique modifié entre-temps par un autre appareil).

  LevelUpStepDataProvider call({
    required String characterId,
    required int targetLevel,
    Object? multiclassClassId,
  }) => LevelUpStepDataProvider._(
    argument: (
      characterId: characterId,
      targetLevel: targetLevel,
      multiclassClassId: multiclassClassId,
    ),
    from: this,
  );

  @override
  String toString() => r'levelUpStepDataProvider';
}
