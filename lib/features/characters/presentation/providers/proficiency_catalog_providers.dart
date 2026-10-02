import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/proficiency_catalog_repository.dart';
import '../../domain/proficiency_catalog.dart';

part 'proficiency_catalog_providers.g.dart';

/// Catalogue de référence armes/armures/boucliers — voir
/// [ProficiencyCatalogRepository].
@Riverpod(keepAlive: true)
ProficiencyCatalogRepository proficiencyCatalogRepository(Ref ref) {
  return SupabaseProficiencyCatalogRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(referenceDataCacheProvider),
  );
}

/// Catalogue chargé à l'ouverture du panneau "Infos" d'un token de maîtrise
/// (`proficiency_detail_panel.dart`), libéré à sa fermeture.
///
/// `retry: null` : le panneau expose un bouton « Réessayer » explicite, même
/// rationale que `pactWeaponOptionsProvider`.
@Riverpod(retry: _noRetry)
Future<ProficiencyCatalog> proficiencyCatalog(Ref ref) {
  return ref.watch(proficiencyCatalogRepositoryProvider).fetchCatalog();
}

Duration? _noRetry(int retryCount, Object error) => null;
