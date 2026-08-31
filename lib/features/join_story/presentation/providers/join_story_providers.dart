import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/story_invite_repository.dart';
import '../../domain/story_preview.dart';

part 'join_story_providers.g.dart';

@Riverpod(keepAlive: true)
StoryInviteRepository storyInviteRepository(Ref ref) {
  return SupabaseStoryInviteRepository(ref.watch(supabaseClientProvider));
}

/// Aperçu d'histoire de l'étape 2/4 ("Confirmation"), en famille par [code]
/// — un aperçu par code résolu, jamais partagé entre deux codes différents
/// dans la même session. `autoDispose` (comportement par défaut du
/// générateur) : ne doit pas survivre à la fermeture de cet écran.
///
/// `retry: null`, même rationale que `charactersProvider`
/// (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer"/"Modifier le code" pour
/// chaque état d'erreur (voir `presentation/join_confirmation_step_screen.dart`),
/// une relance automatique masquerait un code invalide/une invitation
/// désactivée derrière des tentatives répétées silencieuses.
@Riverpod(retry: _noRetry)
Future<StoryPreview> storyInvitePreview(Ref ref, {required String code}) {
  return ref.watch(storyInviteRepositoryProvider).previewInvite(code);
}

Duration? _noRetry(int retryCount, Object error) => null;
