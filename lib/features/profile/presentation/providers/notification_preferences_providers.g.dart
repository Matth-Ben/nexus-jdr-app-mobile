// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationPreferencesRepository)
final notificationPreferencesRepositoryProvider =
    NotificationPreferencesRepositoryProvider._();

final class NotificationPreferencesRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationPreferencesRepository,
          NotificationPreferencesRepository,
          NotificationPreferencesRepository
        >
    with $Provider<NotificationPreferencesRepository> {
  NotificationPreferencesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPreferencesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$notificationPreferencesRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationPreferencesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationPreferencesRepository create(Ref ref) {
    return notificationPreferencesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPreferencesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPreferencesRepository>(
        value,
      ),
    );
  }
}

String _$notificationPreferencesRepositoryHash() =>
    r'07f09c90a8a0a89e2a996b4997d39b35523d45c4';

/// Préférences de notifications du joueur connecté, exposées à
/// `presentation/profile_notifications_screen.dart`.
///
/// Volontairement `autoDispose` (comportement par défaut du générateur,
/// contrairement à [notificationPreferencesRepositoryProvider] ci-dessus) :
/// même rationale que `characterDetailProvider`
/// (`features/characters/presentation/providers/character_detail_provider.dart`)
/// — cette lecture n'a pas besoin de survivre à la fermeture de l'écran, et
/// `ref.invalidate(notificationPreferencesProvider)` (bouton "Réessayer" de
/// l'état d'erreur) fonctionne quel que soit ce choix.
///
/// `retry: _noRetry` — même rationale exacte que `characterDetailProvider` :
/// ne jamais masquer une erreur persistante derrière des tentatives
/// automatiques silencieuses, l'écran expose son propre bouton "Réessayer".

@ProviderFor(notificationPreferences)
final notificationPreferencesProvider = NotificationPreferencesProvider._();

/// Préférences de notifications du joueur connecté, exposées à
/// `presentation/profile_notifications_screen.dart`.
///
/// Volontairement `autoDispose` (comportement par défaut du générateur,
/// contrairement à [notificationPreferencesRepositoryProvider] ci-dessus) :
/// même rationale que `characterDetailProvider`
/// (`features/characters/presentation/providers/character_detail_provider.dart`)
/// — cette lecture n'a pas besoin de survivre à la fermeture de l'écran, et
/// `ref.invalidate(notificationPreferencesProvider)` (bouton "Réessayer" de
/// l'état d'erreur) fonctionne quel que soit ce choix.
///
/// `retry: _noRetry` — même rationale exacte que `characterDetailProvider` :
/// ne jamais masquer une erreur persistante derrière des tentatives
/// automatiques silencieuses, l'écran expose son propre bouton "Réessayer".

final class NotificationPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationPreferences>,
          NotificationPreferences,
          FutureOr<NotificationPreferences>
        >
    with
        $FutureModifier<NotificationPreferences>,
        $FutureProvider<NotificationPreferences> {
  /// Préférences de notifications du joueur connecté, exposées à
  /// `presentation/profile_notifications_screen.dart`.
  ///
  /// Volontairement `autoDispose` (comportement par défaut du générateur,
  /// contrairement à [notificationPreferencesRepositoryProvider] ci-dessus) :
  /// même rationale que `characterDetailProvider`
  /// (`features/characters/presentation/providers/character_detail_provider.dart`)
  /// — cette lecture n'a pas besoin de survivre à la fermeture de l'écran, et
  /// `ref.invalidate(notificationPreferencesProvider)` (bouton "Réessayer" de
  /// l'état d'erreur) fonctionne quel que soit ce choix.
  ///
  /// `retry: _noRetry` — même rationale exacte que `characterDetailProvider` :
  /// ne jamais masquer une erreur persistante derrière des tentatives
  /// automatiques silencieuses, l'écran expose son propre bouton "Réessayer".
  NotificationPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'notificationPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<NotificationPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotificationPreferences> create(Ref ref) {
    return notificationPreferences(ref);
  }
}

String _$notificationPreferencesHash() =>
    r'a4f50d8267c1a270b057eff53684918c89a03d49';
