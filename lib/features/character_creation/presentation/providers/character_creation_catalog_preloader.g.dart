// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_creation_catalog_preloader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(characterCreationCatalogPreloader)
final characterCreationCatalogPreloaderProvider =
    CharacterCreationCatalogPreloaderProvider._();

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

final class CharacterCreationCatalogPreloaderProvider
    extends
        $FunctionalProvider<
          CharacterCreationCatalogPreloader,
          CharacterCreationCatalogPreloader,
          CharacterCreationCatalogPreloader
        >
    with $Provider<CharacterCreationCatalogPreloader> {
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
  CharacterCreationCatalogPreloaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterCreationCatalogPreloaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$characterCreationCatalogPreloaderHash();

  @$internal
  @override
  $ProviderElement<CharacterCreationCatalogPreloader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterCreationCatalogPreloader create(Ref ref) {
    return characterCreationCatalogPreloader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterCreationCatalogPreloader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterCreationCatalogPreloader>(
        value,
      ),
    );
  }
}

String _$characterCreationCatalogPreloaderHash() =>
    r'8e2dea69e1b140ca031c6d0a93de37a70b8f28b4';
