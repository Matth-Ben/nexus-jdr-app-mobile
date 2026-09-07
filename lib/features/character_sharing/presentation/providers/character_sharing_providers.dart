import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../characters/domain/character_detail.dart';
import '../../data/character_sharing_repository.dart';

part 'character_sharing_providers.g.dart';

@Riverpod(keepAlive: true)
CharacterSharingRepository characterSharingRepository(Ref ref) {
  return SupabaseCharacterSharingRepository(ref.watch(supabaseClientProvider));
}

/// Fiche complète d'un personnage partagé, consultée sans authentification
/// via son [token] — écran "Vue en lecture seule"
/// (`presentation/shared_character_view_screen.dart`).
///
/// `autoDispose` par défaut : cet écran n'a pas besoin de survivre à sa
/// fermeture, même rationale que `charactersProvider`
/// (`features/characters/presentation/providers/character_providers.dart`).
/// `retry: null` pour la même raison que le reste de ce dépôt : l'écran
/// expose son propre bouton "Réessayer" plutôt qu'une relance automatique
/// silencieuse.
@Riverpod(retry: _noRetry)
Future<CharacterDetail?> sharedCharacter(Ref ref, {required String token}) {
  return ref.watch(characterSharingRepositoryProvider).fetchSharedCharacter(token);
}

Duration? _noRetry(int retryCount, Object error) => null;
