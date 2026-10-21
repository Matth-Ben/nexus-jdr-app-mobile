import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/subclass_feature_choice_repository.dart';
import '../../domain/subclass_feature_choice.dart';

part 'subclass_feature_choice_providers.g.dart';

@Riverpod(keepAlive: true)
SubclassFeatureChoiceRepository subclassFeatureChoiceRepository(Ref ref) {
  return SupabaseSubclassFeatureChoiceRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(referenceDataCacheProvider),
  );
}

/// Second choix de niveau 1 de la sous-classe [subclassId] (ex. Ancêtre
/// draconique), `null` si cette sous-classe n'en a pas — exposé à
/// `SubclassFeatureChoiceBlock` (correctif D99, `docs/dette-technique.md`).
/// `autoDispose`, pas de retry automatique : même rationale que
/// `subclassChoiceCatalogProvider` (l'écran expose son propre bouton
/// « Réessayer »).
@Riverpod(retry: _noRetry)
Future<SubclassFeatureChoice?> subclassFeatureChoice(Ref ref, int subclassId) {
  return ref
      .watch(subclassFeatureChoiceRepositoryProvider)
      .fetchFor(subclassId);
}

Duration? _noRetry(int retryCount, Object error) => null;
