import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/lineage_choice_repository.dart';
import '../../domain/lineage_choice_catalog.dart';

part 'lineage_choice_providers.g.dart';

@Riverpod(keepAlive: true)
LineageChoiceRepository lineageChoiceRepository(Ref ref) {
  return SupabaseLineageChoiceRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(referenceDataCacheProvider),
  );
}

/// Lignées 2024 à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
/// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
/// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
/// retry automatique : même rationale que `subclassChoiceCatalogProvider`
/// (l'écran expose son propre bouton « Réessayer »).
@Riverpod(retry: _noRetry)
Future<LineageChoiceCatalog> lineageChoiceCatalog(Ref ref) {
  return ref.watch(lineageChoiceRepositoryProvider).fetchLineageChoices();
}

Duration? _noRetry(int retryCount, Object error) => null;
