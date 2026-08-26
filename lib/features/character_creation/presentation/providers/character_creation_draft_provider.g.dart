// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_creation_draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Brouillon en mémoire de la session de création en cours, réutilisé par
/// toutes les étapes de l'assistant (voir `domain/character_creation_draft.dart`).
///
/// Volontairement `keepAlive` : doit survivre à la navigation entre les
/// écrans de l'assistant (une étape par écran, poussés avec `context.push`)
/// pendant toute la session en cours.
///
/// Compromis assumé : cet état n'est *pas* persisté (ni en base, ni en cache
/// local `drift`) — une fermeture complète de l'application avant l'étape 9
/// "Récapitulatif" perd le brouillon en cours. C'est un renoncement
/// temporaire à la reprise de création après redémarrage de l'app (objectif
/// de l'ancienne architecture, qui persistait une ligne `characters`
/// incomplète dès l'étape 1 — voir le rapport de la tâche qui a supprimé
/// `CharacterCreationRepository.saveRaceStep`), pas un oubli : à traiter plus
/// tard, probablement avec la persistance locale `drift` du brouillon en
/// cours (au-delà des seules données de référence).

@ProviderFor(CharacterCreationDraftController)
final characterCreationDraftControllerProvider =
    CharacterCreationDraftControllerProvider._();

/// Brouillon en mémoire de la session de création en cours, réutilisé par
/// toutes les étapes de l'assistant (voir `domain/character_creation_draft.dart`).
///
/// Volontairement `keepAlive` : doit survivre à la navigation entre les
/// écrans de l'assistant (une étape par écran, poussés avec `context.push`)
/// pendant toute la session en cours.
///
/// Compromis assumé : cet état n'est *pas* persisté (ni en base, ni en cache
/// local `drift`) — une fermeture complète de l'application avant l'étape 9
/// "Récapitulatif" perd le brouillon en cours. C'est un renoncement
/// temporaire à la reprise de création après redémarrage de l'app (objectif
/// de l'ancienne architecture, qui persistait une ligne `characters`
/// incomplète dès l'étape 1 — voir le rapport de la tâche qui a supprimé
/// `CharacterCreationRepository.saveRaceStep`), pas un oubli : à traiter plus
/// tard, probablement avec la persistance locale `drift` du brouillon en
/// cours (au-delà des seules données de référence).
final class CharacterCreationDraftControllerProvider
    extends
        $NotifierProvider<
          CharacterCreationDraftController,
          CharacterCreationDraft
        > {
  /// Brouillon en mémoire de la session de création en cours, réutilisé par
  /// toutes les étapes de l'assistant (voir `domain/character_creation_draft.dart`).
  ///
  /// Volontairement `keepAlive` : doit survivre à la navigation entre les
  /// écrans de l'assistant (une étape par écran, poussés avec `context.push`)
  /// pendant toute la session en cours.
  ///
  /// Compromis assumé : cet état n'est *pas* persisté (ni en base, ni en cache
  /// local `drift`) — une fermeture complète de l'application avant l'étape 9
  /// "Récapitulatif" perd le brouillon en cours. C'est un renoncement
  /// temporaire à la reprise de création après redémarrage de l'app (objectif
  /// de l'ancienne architecture, qui persistait une ligne `characters`
  /// incomplète dès l'étape 1 — voir le rapport de la tâche qui a supprimé
  /// `CharacterCreationRepository.saveRaceStep`), pas un oubli : à traiter plus
  /// tard, probablement avec la persistance locale `drift` du brouillon en
  /// cours (au-delà des seules données de référence).
  CharacterCreationDraftControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterCreationDraftControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterCreationDraftControllerHash();

  @$internal
  @override
  CharacterCreationDraftController create() =>
      CharacterCreationDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterCreationDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterCreationDraft>(value),
    );
  }
}

String _$characterCreationDraftControllerHash() =>
    r'54765bce0ac1432d74483b93c61b5d76ac92fef5';

/// Brouillon en mémoire de la session de création en cours, réutilisé par
/// toutes les étapes de l'assistant (voir `domain/character_creation_draft.dart`).
///
/// Volontairement `keepAlive` : doit survivre à la navigation entre les
/// écrans de l'assistant (une étape par écran, poussés avec `context.push`)
/// pendant toute la session en cours.
///
/// Compromis assumé : cet état n'est *pas* persisté (ni en base, ni en cache
/// local `drift`) — une fermeture complète de l'application avant l'étape 9
/// "Récapitulatif" perd le brouillon en cours. C'est un renoncement
/// temporaire à la reprise de création après redémarrage de l'app (objectif
/// de l'ancienne architecture, qui persistait une ligne `characters`
/// incomplète dès l'étape 1 — voir le rapport de la tâche qui a supprimé
/// `CharacterCreationRepository.saveRaceStep`), pas un oubli : à traiter plus
/// tard, probablement avec la persistance locale `drift` du brouillon en
/// cours (au-delà des seules données de référence).

abstract class _$CharacterCreationDraftController
    extends $Notifier<CharacterCreationDraft> {
  CharacterCreationDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CharacterCreationDraft, CharacterCreationDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CharacterCreationDraft, CharacterCreationDraft>,
              CharacterCreationDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
