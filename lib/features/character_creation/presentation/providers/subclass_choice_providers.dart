import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/subclass_choice_repository.dart';
import '../../domain/subclass_choice_catalog.dart';

part 'subclass_choice_providers.g.dart';

@Riverpod(keepAlive: true)
SubclassChoiceRepository subclassChoiceRepository(Ref ref) {
  return SupabaseSubclassChoiceRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(referenceDataCacheProvider),
  );
}

/// Classes qui choisissent leur sous-classe au niveau 1, avec leurs options —
/// exposé à `ClassStepScreen` et au récapitulatif. `autoDispose`, pas de
/// retry automatique : même rationale que `classCatalogProvider` (l'écran
/// expose son propre bouton « Réessayer »).
@Riverpod(retry: _noRetry)
Future<SubclassChoiceCatalog> subclassChoiceCatalog(Ref ref) {
  return ref
      .watch(subclassChoiceRepositoryProvider)
      .fetchLevelOneSubclassChoices();
}

Duration? _noRetry(int retryCount, Object error) => null;
