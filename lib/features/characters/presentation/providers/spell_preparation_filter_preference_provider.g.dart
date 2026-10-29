// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spell_preparation_filter_preference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persiste le filtre "Tous"/"Préparés"/"Non préparés" de
/// [SpellPreparationCard][spell_preparation_card] (onglet "Sorts" de
/// `CharacterSpellsTabBody`), sous forme de la chaîne [SpellPreparationFilter.name]
/// via `SharedPreferences` — même pattern que
/// `app_update/presentation/providers/update_banner_dismissal_provider.dart`
/// (réutilise [sharedPreferencesProvider], défini là-bas, sans le
/// redéfinir ici).
///
/// **Portée volontairement globale à l'appareil, pas par personnage** :
/// demande utilisateur explicite du 29/10/2026 — contrairement à la
/// recherche de `character_list_screen.dart`, restée volontairement non
/// persistée, ce choix-ci doit survivre à la fermeture/réouverture de
/// n'importe quelle fiche. Stockage purement local (jamais synchronisé
/// entre appareils ni lié à un compte), donc valable aussi pour un lecteur
/// anonyme de `shared_character_view_screen.dart`.
///
/// [spell_preparation_card]: ../widgets/spell_preparation_card.dart

@ProviderFor(SpellPreparationFilterPreferenceController)
final spellPreparationFilterPreferenceControllerProvider =
    SpellPreparationFilterPreferenceControllerProvider._();

/// Persiste le filtre "Tous"/"Préparés"/"Non préparés" de
/// [SpellPreparationCard][spell_preparation_card] (onglet "Sorts" de
/// `CharacterSpellsTabBody`), sous forme de la chaîne [SpellPreparationFilter.name]
/// via `SharedPreferences` — même pattern que
/// `app_update/presentation/providers/update_banner_dismissal_provider.dart`
/// (réutilise [sharedPreferencesProvider], défini là-bas, sans le
/// redéfinir ici).
///
/// **Portée volontairement globale à l'appareil, pas par personnage** :
/// demande utilisateur explicite du 29/10/2026 — contrairement à la
/// recherche de `character_list_screen.dart`, restée volontairement non
/// persistée, ce choix-ci doit survivre à la fermeture/réouverture de
/// n'importe quelle fiche. Stockage purement local (jamais synchronisé
/// entre appareils ni lié à un compte), donc valable aussi pour un lecteur
/// anonyme de `shared_character_view_screen.dart`.
///
/// [spell_preparation_card]: ../widgets/spell_preparation_card.dart
final class SpellPreparationFilterPreferenceControllerProvider
    extends
        $NotifierProvider<
          SpellPreparationFilterPreferenceController,
          SpellPreparationFilter
        > {
  /// Persiste le filtre "Tous"/"Préparés"/"Non préparés" de
  /// [SpellPreparationCard][spell_preparation_card] (onglet "Sorts" de
  /// `CharacterSpellsTabBody`), sous forme de la chaîne [SpellPreparationFilter.name]
  /// via `SharedPreferences` — même pattern que
  /// `app_update/presentation/providers/update_banner_dismissal_provider.dart`
  /// (réutilise [sharedPreferencesProvider], défini là-bas, sans le
  /// redéfinir ici).
  ///
  /// **Portée volontairement globale à l'appareil, pas par personnage** :
  /// demande utilisateur explicite du 29/10/2026 — contrairement à la
  /// recherche de `character_list_screen.dart`, restée volontairement non
  /// persistée, ce choix-ci doit survivre à la fermeture/réouverture de
  /// n'importe quelle fiche. Stockage purement local (jamais synchronisé
  /// entre appareils ni lié à un compte), donc valable aussi pour un lecteur
  /// anonyme de `shared_character_view_screen.dart`.
  ///
  /// [spell_preparation_card]: ../widgets/spell_preparation_card.dart
  SpellPreparationFilterPreferenceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spellPreparationFilterPreferenceControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$spellPreparationFilterPreferenceControllerHash();

  @$internal
  @override
  SpellPreparationFilterPreferenceController create() =>
      SpellPreparationFilterPreferenceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpellPreparationFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpellPreparationFilter>(value),
    );
  }
}

String _$spellPreparationFilterPreferenceControllerHash() =>
    r'1aa41827f2efb257db2b03a8aa1a6c144a0194cc';

/// Persiste le filtre "Tous"/"Préparés"/"Non préparés" de
/// [SpellPreparationCard][spell_preparation_card] (onglet "Sorts" de
/// `CharacterSpellsTabBody`), sous forme de la chaîne [SpellPreparationFilter.name]
/// via `SharedPreferences` — même pattern que
/// `app_update/presentation/providers/update_banner_dismissal_provider.dart`
/// (réutilise [sharedPreferencesProvider], défini là-bas, sans le
/// redéfinir ici).
///
/// **Portée volontairement globale à l'appareil, pas par personnage** :
/// demande utilisateur explicite du 29/10/2026 — contrairement à la
/// recherche de `character_list_screen.dart`, restée volontairement non
/// persistée, ce choix-ci doit survivre à la fermeture/réouverture de
/// n'importe quelle fiche. Stockage purement local (jamais synchronisé
/// entre appareils ni lié à un compte), donc valable aussi pour un lecteur
/// anonyme de `shared_character_view_screen.dart`.
///
/// [spell_preparation_card]: ../widgets/spell_preparation_card.dart

abstract class _$SpellPreparationFilterPreferenceController
    extends $Notifier<SpellPreparationFilter> {
  SpellPreparationFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SpellPreparationFilter, SpellPreparationFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpellPreparationFilter, SpellPreparationFilter>,
              SpellPreparationFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
