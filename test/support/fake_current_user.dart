import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Identifiant d'utilisateur piloté par le test (`null` = déconnecté) : permet
/// de simuler un changement de compte sans client Supabase.
class TestUserIdNotifier extends Notifier<String?> {
  @override
  String? build() => 'user-1';

  // Les tests pilotent l'identité directement : un setter est le plus lisible.
  // ignore: use_setters_to_change_properties
  void set(String? id) => state = id;
}

final testUserIdProvider = NotifierProvider<TestUserIdNotifier, String?>(
  TestUserIdNotifier.new,
);

/// Surcharge de `currentUserProvider` suivant [testUserIdProvider].
final currentUserFromTestOverride = currentUserProvider.overrideWith((ref) {
  final id = ref.watch(testUserIdProvider);
  if (id == null) return null;
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  );
});
