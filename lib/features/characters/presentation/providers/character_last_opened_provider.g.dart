// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_last_opened_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Horodatage **local** (par appareil, jamais synchronisé) de la dernière
/// ouverture de la fiche de chaque personnage, `{characterId: epochMs}` —
/// alimente le tri « Dernière ouverture » de la liste (P18).
///
/// Persisté dans `SharedPreferences` sous une clé **scopée par `ownerId`**
/// (`character_last_opened:<ownerId>`) : un autre compte du même appareil ne
/// relit jamais ces horodatages. Aucun champ serveur, aucune migration.

@ProviderFor(CharacterLastOpened)
final characterLastOpenedProvider = CharacterLastOpenedProvider._();

/// Horodatage **local** (par appareil, jamais synchronisé) de la dernière
/// ouverture de la fiche de chaque personnage, `{characterId: epochMs}` —
/// alimente le tri « Dernière ouverture » de la liste (P18).
///
/// Persisté dans `SharedPreferences` sous une clé **scopée par `ownerId`**
/// (`character_last_opened:<ownerId>`) : un autre compte du même appareil ne
/// relit jamais ces horodatages. Aucun champ serveur, aucune migration.
final class CharacterLastOpenedProvider
    extends $NotifierProvider<CharacterLastOpened, Map<String, int>> {
  /// Horodatage **local** (par appareil, jamais synchronisé) de la dernière
  /// ouverture de la fiche de chaque personnage, `{characterId: epochMs}` —
  /// alimente le tri « Dernière ouverture » de la liste (P18).
  ///
  /// Persisté dans `SharedPreferences` sous une clé **scopée par `ownerId`**
  /// (`character_last_opened:<ownerId>`) : un autre compte du même appareil ne
  /// relit jamais ces horodatages. Aucun champ serveur, aucune migration.
  CharacterLastOpenedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterLastOpenedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterLastOpenedHash();

  @$internal
  @override
  CharacterLastOpened create() => CharacterLastOpened();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$characterLastOpenedHash() =>
    r'2e75253b223e945eae1cbe45aadf34d01c60e533';

/// Horodatage **local** (par appareil, jamais synchronisé) de la dernière
/// ouverture de la fiche de chaque personnage, `{characterId: epochMs}` —
/// alimente le tri « Dernière ouverture » de la liste (P18).
///
/// Persisté dans `SharedPreferences` sous une clé **scopée par `ownerId`**
/// (`character_last_opened:<ownerId>`) : un autre compte du même appareil ne
/// relit jamais ces horodatages. Aucun champ serveur, aucune migration.

abstract class _$CharacterLastOpened extends $Notifier<Map<String, int>> {
  Map<String, int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, int>, Map<String, int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, int>, Map<String, int>>,
              Map<String, int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
