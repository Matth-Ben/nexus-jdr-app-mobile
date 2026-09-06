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
/// [multiclassClassId] : `null` (défaut) pour continuer une classe déjà
/// possédée (voir [continueClassId]) ; sinon, `classes.id` de la classe
/// choisie à l'étape `classDecision` pour multiclasser — doit alors être un
/// `classId` présent dans [LevelUpStepData.multiclassOptions] calculé pour le
/// même personnage, sans quoi une [CharacterFailure] est levée (cas
/// défensif : une classe qui a cessé d'être éligible entre l'affichage de
/// `classDecision` et cet appel, ex. un score de caractéristique modifié
/// entre-temps par un autre appareil).
///
/// [continueClassId] : ignoré si [multiclassClassId] est non nul (branche
/// multiclassage, inchangée). Sinon, `null` (défaut, comportement historique)
/// pour continuer la classe primaire (`detail.primaryClass`) ; sinon,
/// `classes.id` d'une classe déjà possédée (primaire OU secondaire — voir
/// `domain/level_up_continue_option.dart`) pour la continuer À LA PLACE de la
/// primaire, ex. un personnage Guerrier 4/Magicien 1 qui choisit de faire
/// progresser son Magicien plutôt que son Guerrier à ce niveau. Doit alors
/// être un `classId` présent dans `detail.classes` pour le même personnage,
/// sans quoi une [CharacterFailure] est levée (même rationale défensive que
/// [multiclassClassId] ci-dessus).

@ProviderFor(levelUpStepData)
final levelUpStepDataProvider = LevelUpStepDataFamily._();

/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").
///
/// [multiclassClassId] : `null` (défaut) pour continuer une classe déjà
/// possédée (voir [continueClassId]) ; sinon, `classes.id` de la classe
/// choisie à l'étape `classDecision` pour multiclasser — doit alors être un
/// `classId` présent dans [LevelUpStepData.multiclassOptions] calculé pour le
/// même personnage, sans quoi une [CharacterFailure] est levée (cas
/// défensif : une classe qui a cessé d'être éligible entre l'affichage de
/// `classDecision` et cet appel, ex. un score de caractéristique modifié
/// entre-temps par un autre appareil).
///
/// [continueClassId] : ignoré si [multiclassClassId] est non nul (branche
/// multiclassage, inchangée). Sinon, `null` (défaut, comportement historique)
/// pour continuer la classe primaire (`detail.primaryClass`) ; sinon,
/// `classes.id` d'une classe déjà possédée (primaire OU secondaire — voir
/// `domain/level_up_continue_option.dart`) pour la continuer À LA PLACE de la
/// primaire, ex. un personnage Guerrier 4/Magicien 1 qui choisit de faire
/// progresser son Magicien plutôt que son Guerrier à ce niveau. Doit alors
/// être un `classId` présent dans `detail.classes` pour le même personnage,
/// sans quoi une [CharacterFailure] est levée (même rationale défensive que
/// [multiclassClassId] ci-dessus).

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
  /// [multiclassClassId] : `null` (défaut) pour continuer une classe déjà
  /// possédée (voir [continueClassId]) ; sinon, `classes.id` de la classe
  /// choisie à l'étape `classDecision` pour multiclasser — doit alors être un
  /// `classId` présent dans [LevelUpStepData.multiclassOptions] calculé pour le
  /// même personnage, sans quoi une [CharacterFailure] est levée (cas
  /// défensif : une classe qui a cessé d'être éligible entre l'affichage de
  /// `classDecision` et cet appel, ex. un score de caractéristique modifié
  /// entre-temps par un autre appareil).
  ///
  /// [continueClassId] : ignoré si [multiclassClassId] est non nul (branche
  /// multiclassage, inchangée). Sinon, `null` (défaut, comportement historique)
  /// pour continuer la classe primaire (`detail.primaryClass`) ; sinon,
  /// `classes.id` d'une classe déjà possédée (primaire OU secondaire — voir
  /// `domain/level_up_continue_option.dart`) pour la continuer À LA PLACE de la
  /// primaire, ex. un personnage Guerrier 4/Magicien 1 qui choisit de faire
  /// progresser son Magicien plutôt que son Guerrier à ce niveau. Doit alors
  /// être un `classId` présent dans `detail.classes` pour le même personnage,
  /// sans quoi une [CharacterFailure] est levée (même rationale défensive que
  /// [multiclassClassId] ci-dessus).
  LevelUpStepDataProvider._({
    required LevelUpStepDataFamily super.from,
    required ({
      String characterId,
      int targetLevel,
      Object? multiclassClassId,
      Object? continueClassId,
    })
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
              Object? continueClassId,
            });
    return levelUpStepData(
      ref,
      characterId: argument.characterId,
      targetLevel: argument.targetLevel,
      multiclassClassId: argument.multiclassClassId,
      continueClassId: argument.continueClassId,
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

String _$levelUpStepDataHash() => r'ca643b5e3ecc4513ca6529cb451cb3ade59e385c';

/// Même rationale que [characterDetailProvider] : `autoDispose` par défaut,
/// `retry: null` pour ne jamais masquer une erreur persistante derrière des
/// tentatives automatiques silencieuses (l'écran expose son propre bouton
/// "Réessayer").
///
/// [multiclassClassId] : `null` (défaut) pour continuer une classe déjà
/// possédée (voir [continueClassId]) ; sinon, `classes.id` de la classe
/// choisie à l'étape `classDecision` pour multiclasser — doit alors être un
/// `classId` présent dans [LevelUpStepData.multiclassOptions] calculé pour le
/// même personnage, sans quoi une [CharacterFailure] est levée (cas
/// défensif : une classe qui a cessé d'être éligible entre l'affichage de
/// `classDecision` et cet appel, ex. un score de caractéristique modifié
/// entre-temps par un autre appareil).
///
/// [continueClassId] : ignoré si [multiclassClassId] est non nul (branche
/// multiclassage, inchangée). Sinon, `null` (défaut, comportement historique)
/// pour continuer la classe primaire (`detail.primaryClass`) ; sinon,
/// `classes.id` d'une classe déjà possédée (primaire OU secondaire — voir
/// `domain/level_up_continue_option.dart`) pour la continuer À LA PLACE de la
/// primaire, ex. un personnage Guerrier 4/Magicien 1 qui choisit de faire
/// progresser son Magicien plutôt que son Guerrier à ce niveau. Doit alors
/// être un `classId` présent dans `detail.classes` pour le même personnage,
/// sans quoi une [CharacterFailure] est levée (même rationale défensive que
/// [multiclassClassId] ci-dessus).

final class LevelUpStepDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<LevelUpStepData>,
          ({
            String characterId,
            int targetLevel,
            Object? multiclassClassId,
            Object? continueClassId,
          })
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
  /// [multiclassClassId] : `null` (défaut) pour continuer une classe déjà
  /// possédée (voir [continueClassId]) ; sinon, `classes.id` de la classe
  /// choisie à l'étape `classDecision` pour multiclasser — doit alors être un
  /// `classId` présent dans [LevelUpStepData.multiclassOptions] calculé pour le
  /// même personnage, sans quoi une [CharacterFailure] est levée (cas
  /// défensif : une classe qui a cessé d'être éligible entre l'affichage de
  /// `classDecision` et cet appel, ex. un score de caractéristique modifié
  /// entre-temps par un autre appareil).
  ///
  /// [continueClassId] : ignoré si [multiclassClassId] est non nul (branche
  /// multiclassage, inchangée). Sinon, `null` (défaut, comportement historique)
  /// pour continuer la classe primaire (`detail.primaryClass`) ; sinon,
  /// `classes.id` d'une classe déjà possédée (primaire OU secondaire — voir
  /// `domain/level_up_continue_option.dart`) pour la continuer À LA PLACE de la
  /// primaire, ex. un personnage Guerrier 4/Magicien 1 qui choisit de faire
  /// progresser son Magicien plutôt que son Guerrier à ce niveau. Doit alors
  /// être un `classId` présent dans `detail.classes` pour le même personnage,
  /// sans quoi une [CharacterFailure] est levée (même rationale défensive que
  /// [multiclassClassId] ci-dessus).

  LevelUpStepDataProvider call({
    required String characterId,
    required int targetLevel,
    Object? multiclassClassId,
    Object? continueClassId,
  }) => LevelUpStepDataProvider._(
    argument: (
      characterId: characterId,
      targetLevel: targetLevel,
      multiclassClassId: multiclassClassId,
      continueClassId: continueClassId,
    ),
    from: this,
  );

  @override
  String toString() => r'levelUpStepDataProvider';
}
