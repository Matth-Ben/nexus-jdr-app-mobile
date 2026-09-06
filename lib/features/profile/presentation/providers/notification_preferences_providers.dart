import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/notification_preferences_repository.dart';
import '../../domain/notification_preferences.dart';

part 'notification_preferences_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationPreferencesRepository notificationPreferencesRepository(Ref ref) {
  return SupabaseNotificationPreferencesRepository(
    ref.watch(supabaseClientProvider),
  );
}

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
@Riverpod(retry: _noRetry)
Future<NotificationPreferences> notificationPreferences(Ref ref) {
  return ref.watch(notificationPreferencesRepositoryProvider).fetch();
}

Duration? _noRetry(int retryCount, Object error) => null;
