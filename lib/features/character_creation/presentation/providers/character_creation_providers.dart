import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/character_creation_repository.dart';
import '../../domain/class_catalog.dart';
import '../../domain/race_catalog.dart';

part 'character_creation_providers.g.dart';

@Riverpod(keepAlive: true)
CharacterCreationRepository characterCreationRepository(Ref ref) {
  return SupabaseCharacterCreationRepository(ref.watch(supabaseClientProvider));
}

/// Catalogue races/sous-races de l'étape 1/9, exposé à `RaceStepScreen`.
///
/// `autoDispose` (comportement par défaut du générateur) : pas besoin de
/// survivre à la fermeture de l'écran, contrairement au brouillon de
/// création (`character_creation_draft_provider.dart`) qui doit persister
/// pendant toute la session de création. `retry: null` pour la même raison
/// que `charactersProvider` (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer" plutôt que de masquer une
/// erreur persistante derrière des tentatives automatiques silencieuses.
@Riverpod(retry: _noRetry)
Future<RaceCatalog> raceCatalog(Ref ref) {
  return ref.watch(characterCreationRepositoryProvider).fetchRaceCatalog();
}

/// Catalogue des classes de l'étape 2/9, exposé à `ClassStepScreen` — même
/// rationale que [raceCatalog] (`autoDispose`, pas de retry automatique).
@Riverpod(retry: _noRetry)
Future<ClassCatalog> classCatalog(Ref ref) {
  return ref.watch(characterCreationRepositoryProvider).fetchClassCatalog();
}

Duration? _noRetry(int retryCount, Object error) => null;
