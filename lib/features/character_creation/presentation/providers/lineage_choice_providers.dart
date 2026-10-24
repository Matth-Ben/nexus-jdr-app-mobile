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

/// Lignées à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
/// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
/// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
/// retry automatique : même rationale que `subclassChoiceCatalogProvider`
/// (l'écran expose son propre bouton « Réessayer »).
///
/// `family` paramétrée par [edition] (`CharacterCreationDraft.edition`) —
/// chantier "différenciation 2014/2024 pour les races" (24/10/2026) : le
/// Drakéide a un jeu d'ascendances RAW distinct par édition
/// (`race_lineages.lineage_group`), voir `data/lineage_choice_repository.dart`.
/// Une instance par édition effectivement utilisée pendant une session de
/// création (au plus deux : celle du brouillon, et `'2024'` explicitement
/// pour le lookup du legs "Infernal" du Tieffelin en 2014 — voir
/// `presentation/race_step_screen.dart::_submit`).
@Riverpod(retry: _noRetry)
Future<LineageChoiceCatalog> lineageChoiceCatalog(
  Ref ref, {
  required String edition,
}) {
  return ref
      .watch(lineageChoiceRepositoryProvider)
      .fetchLineageChoices(edition: edition);
}

Duration? _noRetry(int retryCount, Object error) => null;
