import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import 'character_creation_providers.dart';

part 'character_creation_catalog_preloader.g.dart';

/// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
/// `main.dart`) : précharge en arrière-plan les 8 catalogues de référence
/// non paramétrés de l'assistant de création (`CharacterCreationRepository
/// .fetchRaceCatalog`/`fetchClassCatalog`/`fetchBackgroundCatalog`/
/// `fetchToolCatalog`/`fetchLanguageCatalog`/`fetchItemCatalog`/
/// `fetchSkillCatalog`/`fetchAlignmentCatalog`), pour que leur cache local
/// (`ReferenceDataCache`, TTL 48h — voir la doc de classe de
/// `SupabaseCharacterCreationRepository`) soit déjà chaud avant que
/// l'utilisateur n'atteigne l'assistant de création lui-même — chantier de
/// performance perçue (réduire les allers-retours réseau visibles à
/// l'ouverture d'un écran).
///
/// `fetchSpellCatalog` (le 9e catalogue) est délibérément exclu de ce
/// préchargement : il est paramétré par `classId` (`spell_catalog:$classId`,
/// une entrée de cache par classe), et aucune classe "par défaut" n'a de
/// sens à précharger avant que l'utilisateur n'en choisisse une à l'étape
/// 2/9 — voir la doc de classe de `CharacterCreationRepository
/// .fetchSpellCatalog`. Ce catalogue continue de se peupler normalement à la
/// demande, comme avant ce chantier.
///
/// Déclenché une fois par connexion effective (voir [start]) :
/// - au démarrage de l'app, si une session existante a déjà été reprise
///   depuis le stockage local avant que ce provider ne soit instancié
///   (`AuthChangeEvent.initialSession` avec une session non nulle) ;
/// - à chaque connexion réussie (`AuthChangeEvent.signedIn`).
///
/// Écoute [authStateStreamProvider] (le `Stream<AuthState>` **brut**, voir sa
/// doc de classe) — délibérément **pas** [authStateChangesProvider] (la
/// version enveloppée dans un `AsyncValue` Riverpod) : un abonnement via
/// `Ref.listen(authStateChangesProvider, ...)` s'est avéré silencieusement
/// inerte en écrivant ce préchargeur (aucun événement du flux source
/// n'atteignait jamais le callback), reproduit uniquement lorsque ce
/// provider `keepAlive` n'est lui-même jamais *activement* écouté ailleurs
/// que par un `container.read(...)` ponctuel (typiquement en test — en
/// production, `main.dart` fait un vrai `ref.watch` persistant, qui masque
/// le piège). Voir la doc de classe d'[AuthStateStream]
/// (`features/auth/data/auth_state_stream.dart`) pour le détail complet du
/// mécanisme en cause et le précédent qui l'a déjà contourné
/// (`CharacterWriteSyncCoordinator`/`ConnectivityChecker`).
///
/// `Supabase.instance.client.auth.onAuthStateChange` repose sur un
/// `ReplaySubject` côté `supabase_flutter`/`gotrue` : un nouvel abonné (ce
/// préchargeur, instancié après que `Supabase.initialize` a déjà résolu une
/// éventuelle session existante) reçoit malgré tout le dernier événement
/// déjà émis — pas besoin d'une vérification synchrone supplémentaire de
/// `currentUser` au démarrage.
///
/// Best-effort et silencieux de bout en bout (voir [_preload]) : aucune
/// exception ne doit jamais remonter jusqu'à l'appelant de [start], aucun
/// indicateur de chargement ni erreur ne doit jamais être visible à
/// l'utilisateur — si le préchargement n'a pas eu le temps de finir (ou a
/// échoué) avant que l'utilisateur n'atteigne l'assistant de création, les
/// providers `fetchXxxCatalog` habituels prennent simplement le relais,
/// exactement comme avant ce chantier.
///
/// Compromis assumé : si l'utilisateur atteint l'assistant de création
/// pendant qu'un catalogue est encore en cours de préchargement, deux
/// requêtes réseau indépendantes partent pour la même donnée (celle du
/// préchargeur et celle du provider d'écran habituel, aucune garde
/// anti-doublon). Sans danger — `ReferenceDataCache.put` est un upsert
/// atomique par appel, dernier écrivain gagne — juste un aller-retour réseau
/// superflu dans cette fenêtre de recouvrement, jugé négligeable au vu de sa
/// rareté (fenêtre de quelques centaines de ms typiquement) face à la
/// complexité d'une garde dédiée.
@Riverpod(keepAlive: true)
CharacterCreationCatalogPreloader characterCreationCatalogPreloader(Ref ref) {
  final preloader = CharacterCreationCatalogPreloader(ref);
  preloader.start();
  ref.onDispose(preloader.dispose);
  return preloader;
}

class CharacterCreationCatalogPreloader {
  CharacterCreationCatalogPreloader(this._ref);

  final Ref _ref;
  StreamSubscription<AuthState>? _subscription;

  void start() {
    _subscription = _ref.read(authStateStreamProvider).onAuthStateChange.listen(
      (authState) {
        final isNewSignIn = authState.event == AuthChangeEvent.signedIn;
        final isResumedSession =
            authState.event == AuthChangeEvent.initialSession &&
            authState.session != null;
        if (isNewSignIn || isResumedSession) {
          unawaited(_preload());
        }
      },
    );
  }

  /// Appelle les 8 catalogues non paramétrés en parallèle
  /// (`Future.wait`) — chacun protégé individuellement par [_safeFetch] pour
  /// qu'un catalogue en échec (réseau ET cache, ex. tout premier lancement
  /// hors-ligne) n'empêche jamais les autres de se précharger.
  Future<void> _preload() async {
    final repository = _ref.read(characterCreationRepositoryProvider);
    await Future.wait([
      _safeFetch(repository.fetchRaceCatalog),
      _safeFetch(repository.fetchClassCatalog),
      _safeFetch(repository.fetchBackgroundCatalog),
      _safeFetch(repository.fetchToolCatalog),
      _safeFetch(repository.fetchLanguageCatalog),
      _safeFetch(repository.fetchItemCatalog),
      _safeFetch(repository.fetchSkillCatalog),
      _safeFetch(repository.fetchAlignmentCatalog),
    ]);
  }

  Future<void> _safeFetch(Future<Object?> Function() fetch) async {
    try {
      await fetch();
    } catch (_) {
      // Best-effort, silencieux — voir la doc de classe.
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
  }
}
