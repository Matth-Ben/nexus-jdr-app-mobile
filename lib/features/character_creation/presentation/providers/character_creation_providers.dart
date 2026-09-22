import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../characters/domain/patron_extended_spells.dart';
import '../../../characters/presentation/providers/character_providers.dart';
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
import '../../domain/skill_catalog.dart';
import '../../domain/spell_catalog.dart';
import '../../domain/tool_catalog.dart';
import 'character_creation_draft_provider.dart';
import 'subclass_choice_providers.dart';

part 'character_creation_providers.g.dart';

@Riverpod(keepAlive: true)
CharacterCreationRepository characterCreationRepository(Ref ref) {
  return SupabaseCharacterCreationRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(referenceDataCacheProvider),
  );
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

/// Sorts candidats de la classe [classId] pour la création : la liste de
/// classe, à laquelle s'ajoutent, pour tout [subclassId] non nul, les sorts de
/// niveau 1 de la liste ÉTENDUE de cette sous-classe
/// (`subclass_spells.grant_kind = 'extends_list'`, `class_level <= 1`) — c'est
/// la base qui décide quelles sous-classes en ont (patrons d'Occultiste), pas
/// le nom de la classe. Même logique que la montée de niveau
/// (`PatronExtendedSpells.merge`), plafond de niveau de sort 1. Utilisé par
/// l'étape Sorts ET par le récapitulatif : `createCharacter` résout les noms
/// choisis contre ce catalogue.
///
/// Un échec de lecture des sorts de patron (ni réseau ni cache) n'échoue pas
/// l'écran : on continue avec le catalogue de classe seul, comme la montée de
/// niveau. [subclassId] est un paramètre de la `family` (celui du brouillon)
/// pour ne pas recharger à chaque modification d'un autre champ.
@Riverpod(retry: _noRetry)
Future<SpellCatalog> creationSpellCatalog(
  Ref ref, {
  required int classId,
  int? subclassId,
}) async {
  final base = await ref.watch(spellCatalogProvider(classId: classId).future);
  if (subclassId == null) return base;

  try {
    final extended = await ref
        .watch(warlockPactSpellRepositoryProvider)
        .fetchPatronExtendedSpells(subclassIds: [subclassId]);
    return PatronExtendedSpells.merge(
      base: base,
      extended: extended[subclassId] ?? const [],
      warlockLevel: 1,
      maxSpellLevel: 1,
    ).catalog;
  } catch (_) {
    // `CharacterFailure` (caractères) ou autre : dégradé sans sorts de patron.
    return base;
  }
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
    creationSpellCatalogProvider(
      classId: classOption.id,
      subclassId: draft.subclassId,
    ).future,
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

/// Catalogue des 18 compétences de l'étape 9/9 "Récapitulatif", exposé à
/// `SummaryStepScreen` — même rationale que [toolCatalog] (`autoDispose`,
/// pas de retry automatique).
@Riverpod(retry: _noRetry)
Future<SkillCatalog> skillCatalog(Ref ref) {
  return ref.watch(characterCreationRepositoryProvider).fetchSkillCatalog();
}

/// Données déjà résolues nécessaires à l'étape 9/9 "Récapitulatif" : la
/// [ClassOption]/[BackgroundOption] déjà choisies aux étapes 2/3 (comme
/// [SkillsAndToolsStepData]), plus les catalogues complets de races
/// (bonus raciaux, en-tête), compétences, outils, langues, sorts (de la
/// classe déjà choisie) et objets — tout ce dont
/// `CharacterCreationRepository.createCharacter` a besoin pour résoudre le
/// brouillon vers de vraies lignes en base, réutilisé tel quel plutôt que
/// rechargé une seconde fois au moment de la soumission finale (voir
/// `presentation/summary_step_screen.dart`).
///
/// Même pattern combinateur que [SkillsAndToolsStepData]/[SpellsStepData]/
/// [EquipmentStepData], simplement combinant davantage de catalogues (dernier
/// écran de l'assistant, celui qui a besoin de la vue d'ensemble la plus
/// large).
typedef SummaryStepData = ({
  RaceCatalog raceCatalog,
  ClassOption classOption,
  BackgroundOption backgroundOption,
  SkillCatalog skillCatalog,
  ToolCatalog toolCatalog,
  LanguageCatalog languageCatalog,
  SpellCatalog spellCatalog,
  ItemCatalog itemCatalog,

  /// Nom de la sous-classe choisie à l'étape 2/9, `null` si aucune ou si son
  /// nom n'a pu être résolu (l'écran affiche alors un repli).
  String? subclassName,
});

@Riverpod(retry: _noRetry)
Future<SummaryStepData> summaryStepData(Ref ref) async {
  final draft = ref.watch(characterCreationDraftControllerProvider);

  final raceCatalog = await ref.watch(raceCatalogProvider.future);
  final classCatalog = await ref.watch(classCatalogProvider.future);
  final backgroundCatalog = await ref.watch(backgroundCatalogProvider.future);
  final skillCatalog = await ref.watch(skillCatalogProvider.future);
  final toolCatalog = await ref.watch(toolCatalogProvider.future);
  final languageCatalog = await ref.watch(languageCatalogProvider.future);
  final itemCatalog = await ref.watch(itemCatalogProvider.future);

  final classOption = classCatalog.classes.firstWhere(
    (option) => option.id == draft.classId,
    orElse: () => throw const CharacterCreationFailure(
      "Classe introuvable pour le récapitulatif. Revenez à l'étape Classe.",
    ),
  );
  final backgroundOption = backgroundCatalog.backgrounds.firstWhere(
    (option) => option.id == draft.backgroundId,
    orElse: () => throw const CharacterCreationFailure(
      "Historique introuvable pour le récapitulatif. Revenez à l'étape "
      'Historique.',
    ),
  );

  final spellCatalog = await ref.watch(
    creationSpellCatalogProvider(
      classId: classOption.id,
      subclassId: draft.subclassId,
    ).future,
  );

  // Nom de la sous-classe : lecture best-effort (hors-ligne sans cache, le
  // récapitulatif ne doit pas échouer) ; l'écran affiche un repli si `null`.
  String? subclassName;
  if (draft.subclassId != null) {
    try {
      final subclassCatalog = await ref.watch(
        subclassChoiceCatalogProvider.future,
      );
      subclassName = subclassCatalog.nameOf(
        classId: classOption.id,
        subclassId: draft.subclassId!,
      );
    } catch (_) {
      subclassName = null;
    }
  }

  return (
    raceCatalog: raceCatalog,
    classOption: classOption,
    backgroundOption: backgroundOption,
    skillCatalog: skillCatalog,
    toolCatalog: toolCatalog,
    languageCatalog: languageCatalog,
    spellCatalog: spellCatalog,
    itemCatalog: itemCatalog,
    subclassName: subclassName,
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
