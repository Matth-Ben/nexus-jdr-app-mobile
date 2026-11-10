import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/character_conditions_repository.dart';

part 'character_conditions_providers.g.dart';

/// Écriture des conditions d'un personnage (P6) — voir
/// `CharacterConditionsRepository`.
@Riverpod(keepAlive: true)
CharacterConditionsRepository characterConditionsRepository(Ref ref) {
  return SupabaseCharacterConditionsRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(connectivityCheckerProvider),
    ref.watch(pendingCharacterWriteQueueProvider),
    ref.watch(referenceDataCacheProvider),
  );
}
