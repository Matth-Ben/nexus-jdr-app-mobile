import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/character_creation_repository.dart';
import '../../domain/background_catalog.dart';
import '../../domain/background_equipment_entry.dart';
import '../../domain/background_equipment_parser.dart';
import '../../domain/background_equipment_resolver.dart';
import '../../domain/background_option.dart';
import '../../domain/character_creation_failure.dart';
import '../../domain/class_catalog.dart';
import '../../domain/class_option.dart';
import '../../domain/item_catalog.dart';
import '../../domain/language_catalog.dart';
import '../../domain/race_catalog.dart';
import '../../domain/spell_catalog.dart';
import '../../domain/tool_catalog.dart';
import 'character_creation_draft_provider.dart';

part 'character_creation_providers.g.dart';

@Riverpod(keepAlive: true)
CharacterCreationRepository characterCreationRepository(Ref ref) {
  return SupabaseCharacterCreationRepository(ref.watch(supabaseClientProvider));
}

/// Catalogue races/sous-races de l'étape 1/9, exposé à `RaceStepScreen`.
///
/// `autoDispose` (comportement par défaut du générateur) : pas besoin de
/// survivre à la fermeture de l'écran, contrairement au brouillon de
/// création (`character_creation_draft_provider.dart`) qui doit persister
/// pendant toute la session de création. `retry: null` pour la même raison
/// que `charactersProvider` (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer" plutôt que de masquer une
/// erreur persistante derrière des tentatives automatiques silencieuses.
@Riverpod(retry: _noRetry)
Future<RaceCatalog> raceCatalog(Ref ref) {
  return ref.watch(characterCreationRepositoryProvider).fetchRaceCatalog();
}

/// Catalogue des classes de l'étape 2/9, exposé à `ClassStepScreen` — même
/// rationale que [raceCatalog] (`autoDispose`, pas de retry automatique).
@Riverpod(retry: _noRetry)
Future<ClassCatalog> classCatalog(Ref ref) {
  return ref.watch(characterCreationRepositoryProvider).fetchClassCatalog();
}

/// Catalogue des historiques de l'étape 3/9, exposé à `BackgroundStepScreen`
/// — même rationale que [raceCatalog]/[classCatalog] (`autoDispose`, pas de
/// retry automatique).
@Riverpod(retry: _noRetry)
Future<BackgroundCatalog> backgroundCatalog(Ref ref) {
  return ref
      .watch(characterCreationRepositoryProvider)
      .fetchBackgroundCatalog();
}

/// Catalogue des outils/instruments de l'étape 5/9, exposé à
/// `SkillsAndToolsStepScreen` — même rationale que [raceCatalog]
/// (`autoDispose`, pas de retry automatique).
@Riverpod(retry: _noRetry)
Future<ToolCatalog> toolCatalog(Ref ref) {
  return ref.watch(characterCreationRepositoryProvider).fetchToolCatalog();
}

/// Catalogue des langues de l'étape 5/9, exposé à `SkillsAndToolsStepScreen`
/// — même rationale que [raceCatalog] (`autoDispose`, pas de retry
/// automatique).
@Riverpod(retry: _noRetry)
Future<LanguageCatalog> languageCatalog(Ref ref) {
  return ref.watch(characterCreationRepositoryProvider).fetchLanguageCatalog();
}

/// Données déjà résolues nécessaires à l'étape 5/9 "Compétences et outils" :
/// la [ClassOption]/[BackgroundOption] déjà choisies aux étapes 2/3 (pas les
/// catalogues complets, cet écran n'a besoin que d'une seule entrée de
/// chacun), plus les catalogues d'outils/langues complets pour peupler les
/// sections interactives correspondantes.
///
/// Combine 4 providers déjà existants ([classCatalogProvider]/
/// [backgroundCatalogProvider]/[toolCatalogProvider]/[languageCatalogProvider])
/// plutôt que de refaire une requête dédiée : `classes`/`backgrounds` ont
/// déjà été chargées aux étapes 2/3, `tools`/`languages` sont de petites
/// tables de référence bon marché à récupérer en entier (même principe que
/// `raceCatalogProvider` rechargé en entier à l'étape 4/9 pour les bonus
/// raciaux). Premier écran de l'assistant à combiner plusieurs catalogues :
/// pattern Riverpod standard (`ref.watch(xProvider.future)` dans un provider
/// `Future`), pas une rupture de convention, mais signalé ici puisqu'aucun
/// écran précédent n'en avait eu besoin.
typedef SkillsAndToolsStepData = ({
  ClassOption classOption,
  BackgroundOption backgroundOption,
  ToolCatalog toolCatalog,
  LanguageCatalog languageCatalog,
});

@Riverpod(retry: _noRetry)
Future<SkillsAndToolsStepData> skillsAndToolsStepData(Ref ref) async {
  final draft = ref.watch(characterCreationDraftControllerProvider);

  final classCatalog = await ref.watch(classCatalogProvider.future);
  final backgroundCatalog = await ref.watch(backgroundCatalogProvider.future);
  final toolCatalog = await ref.watch(toolCatalogProvider.future);
  final languageCatalog = await ref.watch(languageCatalogProvider.future);

  final classOption = classCatalog.classes.firstWhere(
    (option) => option.id == draft.classId,
    orElse: () => throw const CharacterCreationFailure(
      "Classe introuvable pour l'étape Compétences et outils. Revenez à "
      "l'étape Classe.",
    ),
  );
  final backgroundOption = backgroundCatalog.backgrounds.firstWhere(
    (option) => option.id == draft.backgroundId,
    orElse: () => throw const CharacterCreationFailure(
      "Historique introuvable pour l'étape Compétences et outils. Revenez "
      "à l'étape Historique.",
    ),
  );

  return (
    classOption: classOption,
    backgroundOption: backgroundOption,
    toolCatalog: toolCatalog,
    languageCatalog: languageCatalog,
  );
}

/// Sorts (mineurs et niveau 1 mélangés) accessibles à la classe [classId],
/// exposé à `SpellsStepScreen` — étape 6/9 "Sorts". `family` (paramétré par
/// `classId`) plutôt qu'un provider simple : contrairement à
/// [toolCatalogProvider]/[languageCatalogProvider] (petites tables complètes,
/// indépendantes de tout choix précédent), les sorts sont filtrés côté
/// requête par la classe déjà choisie à l'étape 2/9 (voir
/// `SupabaseCharacterCreationRepository.fetchSpellCatalog`) — même rationale
/// que [raceCatalog]/[classCatalog] pour le reste (`autoDispose`, pas de
/// retry automatique).
@Riverpod(retry: _noRetry)
Future<SpellCatalog> spellCatalog(Ref ref, {required int classId}) {
  return ref
      .watch(characterCreationRepositoryProvider)
      .fetchSpellCatalog(classId: classId);
}

/// Données déjà résolues nécessaires à l'étape 6/9 "Sorts" : la [ClassOption]
/// déjà choisie à l'étape 2/9 (pour son nom, utilisé par
/// `SpellcastingRules` pour les quotas), plus le [SpellCatalog] complet de
/// cette classe — même pattern combinateur que [SkillsAndToolsStepData].
typedef SpellsStepData = ({ClassOption classOption, SpellCatalog spellCatalog});

@Riverpod(retry: _noRetry)
Future<SpellsStepData> spellsStepData(Ref ref) async {
  final draft = ref.watch(characterCreationDraftControllerProvider);

  final classCatalog = await ref.watch(classCatalogProvider.future);
  final classOption = classCatalog.classes.firstWhere(
    (option) => option.id == draft.classId,
    orElse: () => throw const CharacterCreationFailure(
      "Classe introuvable pour l'étape Sorts. Revenez à l'étape Classe.",
    ),
  );

  final spellCatalog = await ref.watch(
    spellCatalogProvider(classId: classOption.id).future,
  );

  return (classOption: classOption, spellCatalog: spellCatalog);
}

/// Catalogue complet des objets de l'étape 7/9 "Équipement de départ",
/// exposé à `EquipmentStepScreen` — même rationale que [toolCatalog]
/// (`autoDispose`, pas de retry automatique).
@Riverpod(retry: _noRetry)
Future<ItemCatalog> itemCatalog(Ref ref) {
  return ref.watch(characterCreationRepositoryProvider).fetchItemCatalog();
}

/// Données déjà résolues nécessaires à l'étape 7/9 "Équipement de départ" :
/// le [BackgroundOption] déjà choisi à l'étape 3/9 (pour son nom et son
/// équipement brut), l'[ItemCatalog] complet (onglet "Acheter" ET résolution
/// de l'équipement d'historique, un seul fetch pour les deux, voir
/// `domain/item_catalog.dart`), l'or de départ déjà extrait
/// (`domain/background_equipment_parser.dart`) et l'équipement d'historique
/// déjà résolu (`domain/background_equipment_resolver.dart`) — même pattern
/// combinateur que [SkillsAndToolsStepData]/[SpellsStepData].
typedef EquipmentStepData = ({
  BackgroundOption backgroundOption,
  ItemCatalog itemCatalog,
  int startingGold,
  List<BackgroundEquipmentEntry> historyEquipment,
});

@Riverpod(retry: _noRetry)
Future<EquipmentStepData> equipmentStepData(Ref ref) async {
  final draft = ref.watch(characterCreationDraftControllerProvider);

  final backgroundCatalog = await ref.watch(backgroundCatalogProvider.future);
  final itemCatalog = await ref.watch(itemCatalogProvider.future);

  final backgroundOption = backgroundCatalog.backgrounds.firstWhere(
    (option) => option.id == draft.backgroundId,
    orElse: () => throw const CharacterCreationFailure(
      "Historique introuvable pour l'étape Équipement. Revenez à l'étape "
      'Historique.',
    ),
  );

  final startingGold =
      BackgroundEquipmentParser.extractStartingGold(
        backgroundOption.equipment,
      ) ??
      0;
  final equipmentLines = BackgroundEquipmentParser.withoutStartingGoldLine(
    backgroundOption.equipment,
  );
  final historyEquipment = BackgroundEquipmentResolver.resolve(
    equipmentLines: equipmentLines,
    catalog: itemCatalog,
  );

  return (
    backgroundOption: backgroundOption,
    itemCatalog: itemCatalog,
    startingGold: startingGold,
    historyEquipment: historyEquipment,
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
