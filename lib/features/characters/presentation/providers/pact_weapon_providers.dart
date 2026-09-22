import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/pact_weapon_repository.dart';
import '../../domain/pact_weapon_option.dart';

part 'pact_weapon_providers.g.dart';

/// Arme de pacte de l'Occultiste (Pacte de la lame) — voir
/// [PactWeaponRepository].
@Riverpod(keepAlive: true)
PactWeaponRepository pactWeaponRepository(Ref ref) {
  return SupabasePactWeaponRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(connectivityCheckerProvider),
    ref.watch(referenceDataCacheProvider),
  );
}

/// Armes éligibles de la feuille « FORME DE L'ARME » (chargées à
/// l'ouverture de la feuille, libérées à sa fermeture).
///
/// `retry: null` : la feuille expose un bouton « Réessayer » explicite, même
/// rationale que `inventoryCatalogProvider`.
@Riverpod(retry: _noRetry)
Future<List<PactWeaponOption>> pactWeaponOptions(Ref ref) {
  return ref.watch(pactWeaponRepositoryProvider).fetchEligibleWeapons();
}

Duration? _noRetry(int retryCount, Object error) => null;
