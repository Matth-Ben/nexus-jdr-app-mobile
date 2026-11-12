// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_alerts_panel_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Alertes de synchro du compte connecté **triées** pour le panneau (plus
/// récente d'abord). Distinct de `syncAlertsProvider` (ordre d'insertion),
/// qui sert le moteur du bandeau. Lecture locale seule (drift), jamais de
/// réseau.

@ProviderFor(sortedSyncAlerts)
final sortedSyncAlertsProvider = SortedSyncAlertsProvider._();

/// Alertes de synchro du compte connecté **triées** pour le panneau (plus
/// récente d'abord). Distinct de `syncAlertsProvider` (ordre d'insertion),
/// qui sert le moteur du bandeau. Lecture locale seule (drift), jamais de
/// réseau.

final class SortedSyncAlertsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SyncAlert>>,
          List<SyncAlert>,
          Stream<List<SyncAlert>>
        >
    with $FutureModifier<List<SyncAlert>>, $StreamProvider<List<SyncAlert>> {
  /// Alertes de synchro du compte connecté **triées** pour le panneau (plus
  /// récente d'abord). Distinct de `syncAlertsProvider` (ordre d'insertion),
  /// qui sert le moteur du bandeau. Lecture locale seule (drift), jamais de
  /// réseau.
  SortedSyncAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sortedSyncAlertsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sortedSyncAlertsHash();

  @$internal
  @override
  $StreamProviderElement<List<SyncAlert>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SyncAlert>> create(Ref ref) {
    return sortedSyncAlerts(ref);
  }
}

String _$sortedSyncAlertsHash() => r'c89a90432d50cbd0e686d57e5ff2f060d5ec112f';

/// Identifiants des personnages de la liste **déjà chargée**, ou `null` tant
/// qu'on ne sait pas (liste jamais chargée, en chargement initial ou en
/// erreur) : une alerte n'est « orpheline » que si cet ensemble est connu et
/// ne la contient pas — jamais de faux positif pendant le chargement.
///
/// Ne déclenche jamais le chargement de la liste (le panneau ne fait aucun
/// appel réseau) : si `charactersProvider` n'est pas déjà vivant (écran
/// liste sous la feuille, ouverte depuis la liste, la fiche ou le Profil), la
/// réponse est « inconnu ».

@ProviderFor(knownCharacterIds)
final knownCharacterIdsProvider = KnownCharacterIdsProvider._();

/// Identifiants des personnages de la liste **déjà chargée**, ou `null` tant
/// qu'on ne sait pas (liste jamais chargée, en chargement initial ou en
/// erreur) : une alerte n'est « orpheline » que si cet ensemble est connu et
/// ne la contient pas — jamais de faux positif pendant le chargement.
///
/// Ne déclenche jamais le chargement de la liste (le panneau ne fait aucun
/// appel réseau) : si `charactersProvider` n'est pas déjà vivant (écran
/// liste sous la feuille, ouverte depuis la liste, la fiche ou le Profil), la
/// réponse est « inconnu ».

final class KnownCharacterIdsProvider
    extends $FunctionalProvider<Set<String>?, Set<String>?, Set<String>?>
    with $Provider<Set<String>?> {
  /// Identifiants des personnages de la liste **déjà chargée**, ou `null` tant
  /// qu'on ne sait pas (liste jamais chargée, en chargement initial ou en
  /// erreur) : une alerte n'est « orpheline » que si cet ensemble est connu et
  /// ne la contient pas — jamais de faux positif pendant le chargement.
  ///
  /// Ne déclenche jamais le chargement de la liste (le panneau ne fait aucun
  /// appel réseau) : si `charactersProvider` n'est pas déjà vivant (écran
  /// liste sous la feuille, ouverte depuis la liste, la fiche ou le Profil), la
  /// réponse est « inconnu ».
  KnownCharacterIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knownCharacterIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knownCharacterIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String>? create(Ref ref) {
    return knownCharacterIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>?>(value),
    );
  }
}

String _$knownCharacterIdsHash() => r'6f9e73b6bd095cdf876f7503340a3c8dd847180e';
