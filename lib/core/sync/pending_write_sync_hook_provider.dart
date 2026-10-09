import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_write_sync_hook_provider.g.dart';

/// Indirection neutre pour que `features/auth/` n'ait jamais besoin
/// d'importer `features/characters/` (D31 du registre de dette technique).
///
/// `SupabaseAuthRepository.signOut`/`deleteAccount`
/// (`features/auth/data/auth_repository.dart`) ont besoin de tenter une
/// synchronisation best-effort de la file d'attente PV/XP hors-ligne
/// (`PendingCharacterWriteSyncer`, `features/characters/`) avant de purger le
/// cache local — mais cette classe vit dans `features/characters/`, et
/// `features/auth/presentation/providers/auth_providers.dart` ne doit jamais
/// importer le code d'une autre `feature` (seule exception historique du
/// dépôt avant ce provider, voir `docs/dette-technique.md` D31).
///
/// Ce provider casse cette dépendance : il expose un
/// `Future<void> Function()` neutre, par défaut un no-op (`() async {}`) —
/// `core/` ne connaît ni ne dépend de `PendingCharacterWriteSyncer`. Le
/// câblage réel
/// (`() => ref.read(pendingCharacterWriteSyncerProvider).sync()`) est posé en
/// `override` dans `lib/main.dart` (`AppBootstrap._wrapChild`), seul point de
/// composition du dépôt qui connaît déjà toutes les `features` — voir la doc
/// de cette méthode pour le rationale de l'emplacement précis de cet
/// `override`.
///
/// Le défaut no-op reste intentionnel plutôt qu'une exception "non câblé" :
/// il permet à tout test qui override `authRepositoryProvider` directement
/// avec un double (tous les tests de widgets existants, voir
/// `test/features/auth/presentation/login_screen_test.dart`) de continuer à
/// ignorer ce provider sans jamais l'overrider explicitement, puisque la
/// fonction `authRepository` ci-dessous (qui, elle, le lit) ne s'exécute
/// alors jamais.
@Riverpod(keepAlive: true)
Future<void> Function() pendingWriteSyncHook(Ref ref) {
  return () async {};
}
