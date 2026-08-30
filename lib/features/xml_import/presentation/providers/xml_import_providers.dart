import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../character_creation/domain/alignment_catalog.dart';
import '../../../character_creation/domain/background_catalog.dart';
import '../../../character_creation/domain/class_catalog.dart';
import '../../../character_creation/domain/class_option.dart';
import '../../../character_creation/domain/item_catalog.dart';
import '../../../character_creation/domain/language_catalog.dart';
import '../../../character_creation/domain/race_catalog.dart';
import '../../../character_creation/domain/skill_catalog.dart';
import '../../../character_creation/domain/spell_catalog.dart';
import '../../../character_creation/domain/tool_catalog.dart';
import '../../../character_creation/presentation/providers/character_creation_providers.dart';
import '../../data/xml_character_import_parser.dart';
import '../../data/xml_import_repository.dart';
import '../../domain/xml_character_import_resolved.dart';
import '../../domain/xml_character_import_resolver.dart';
import '../../domain/xml_field_resolution.dart';
import '../../domain/xml_import_parse_result.dart';
import '../../domain/xml_name_resolver.dart';

part 'xml_import_providers.g.dart';

/// Levée par [XmlImportReviewController] quand
/// `XmlCharacterImportParser.parse` échoue (XML illisible, structure
/// `<builder><character>` non reconnue) — un type dédié plutôt que
/// `CharacterCreationFailure` (erreurs réseau des catalogues) pour que
/// `presentation/xml_import_review_screen.dart` distingue les deux états
/// d'erreur (spec visuelle de la tâche : "Erreur (XML invalide/structure non
/// reconnue)" a un rendu dédié, sans bouton "Réessayer", contrairement à un
/// échec réseau).
///
/// Nommée différemment de `XmlImportParseFailure` (la variante générée par
/// freezed pour `XmlImportParseResult.failure`, voir
/// `domain/xml_import_parse_result.dart`) pour éviter toute collision de nom
/// entre les deux classes, bien réelles toutes les deux dans ce module.
class XmlImportInvalidFileFailure implements Exception {
  const XmlImportInvalidFileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

@Riverpod(keepAlive: true)
XmlImportRepository xmlImportRepository(Ref ref) {
  return SupabaseXmlImportRepository(ref.watch(supabaseClientProvider));
}

/// Données complètement chargées et résolues pour l'écran de vérification de
/// l'import XML aidedd.org : le [resolved] affiché/corrigible, plus tous les
/// catalogues déjà chargés dont [XmlImportReviewController] a besoin pour
/// résoudre une correction manuelle par nom (bottom sheet) ou la sauvegarde
/// finale (`domain/xml_import_save_data_resolver.dart`, appelé directement
/// par l'écran au moment de "VALIDER LE PERSONNAGE" avec [itemCatalog]/
/// [skillCatalog]/[alignmentCatalog]).
typedef XmlImportReviewData = ({
  String fileName,
  XmlCharacterImportResolved resolved,
  RaceCatalog raceCatalog,
  ClassCatalog classCatalog,
  BackgroundCatalog backgroundCatalog,
  ToolCatalog toolCatalog,
  LanguageCatalog languageCatalog,
  SpellCatalog spellCatalog,
  ItemCatalog itemCatalog,
  SkillCatalog skillCatalog,
  AlignmentCatalog alignmentCatalog,
});

/// Charge, parse et résout un export XML aidedd.org [xmlSource] (contenu
/// déjà lu par le sélecteur de fichier natif, voir
/// `features/characters/presentation/character_list_screen.dart::
/// _startXmlImport`), puis porte les corrections manuelles faites par
/// l'utilisateur sur l'écran de vérification (bottom sheet de correction).
///
/// `family` par ([fileName], [xmlSource]) plutôt qu'un provider simple : un
/// écran de vérification par fichier importé, jamais partagé entre deux
/// imports différents dans la même session — `autoDispose` (comportement par
/// défaut du générateur) laisse la mémoire se libérer dès que l'écran est
/// quitté (retour arrière avant validation, ou après sauvegarde réussie).
///
/// Toutes les corrections passent par [_updateResolved] plutôt que de
/// réimplémenter la même reconstruction d'enregistrement 11 champs à chaque
/// méthode — chaque méthode publique ne fait que calculer le nouveau
/// [XmlFieldResolution] à injecter dans [XmlCharacterImportResolved.copyWith].
@riverpod
class XmlImportReviewController extends _$XmlImportReviewController {
  @override
  Future<XmlImportReviewData> build({
    required String fileName,
    required String xmlSource,
  }) async {
    final parseResult = XmlCharacterImportParser.parse(xmlSource);
    final raw = switch (parseResult) {
      XmlImportParseSuccess(:final character) => character,
      XmlImportParseFailure(:final message) =>
        throw XmlImportInvalidFileFailure(message),
    };

    final repository = ref.watch(characterCreationRepositoryProvider);

    final raceCatalog = await repository.fetchRaceCatalog();
    final classCatalog = await repository.fetchClassCatalog();
    final backgroundCatalog = await repository.fetchBackgroundCatalog();
    final toolCatalog = await repository.fetchToolCatalog();
    final languageCatalog = await repository.fetchLanguageCatalog();
    final itemCatalog = await repository.fetchItemCatalog();
    final skillCatalog = await repository.fetchSkillCatalog();
    final alignmentCatalog = await repository.fetchAlignmentCatalog();

    // La classe doit être devinée par nom *avant* de pouvoir charger le
    // catalogue de sorts (paramétré par `classId`, voir
    // `CharacterCreationRepository.fetchSpellCatalog`) — même mécanique en
    // deux temps que `SummaryStepData`/`SpellsStepData`
    // (`character_creation_providers.dart`), ici appliquée à un nom brut
    // plutôt qu'à un `classId` déjà choisi par un joueur.
    final guessedClass = XmlNameResolver.resolveByName<ClassOption>(
      rawName: raw.characterClass,
      candidates: classCatalog.classes,
      nameOf: (classOption) => classOption.name,
    );
    final spellCatalog = switch (guessedClass) {
      XmlFieldResolutionRecognized<ClassOption>(:final value) =>
        await repository.fetchSpellCatalog(classId: value.id),
      _ => const SpellCatalog(spells: []),
    };

    final resolved = XmlCharacterImportResolver.resolve(
      raw: raw,
      raceCatalog: raceCatalog,
      classCatalog: classCatalog,
      backgroundCatalog: backgroundCatalog,
      toolCatalog: toolCatalog,
      languageCatalog: languageCatalog,
      spellCatalog: spellCatalog,
    );

    return (
      fileName: fileName,
      resolved: resolved,
      raceCatalog: raceCatalog,
      classCatalog: classCatalog,
      backgroundCatalog: backgroundCatalog,
      toolCatalog: toolCatalog,
      languageCatalog: languageCatalog,
      spellCatalog: spellCatalog,
      itemCatalog: itemCatalog,
      skillCatalog: skillCatalog,
      alignmentCatalog: alignmentCatalog,
    );
  }

  void _updateResolved(XmlCharacterImportResolved resolved) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData((
      fileName: current.fileName,
      resolved: resolved,
      raceCatalog: current.raceCatalog,
      classCatalog: current.classCatalog,
      backgroundCatalog: current.backgroundCatalog,
      toolCatalog: current.toolCatalog,
      languageCatalog: current.languageCatalog,
      spellCatalog: current.spellCatalog,
      itemCatalog: current.itemCatalog,
      skillCatalog: current.skillCatalog,
      alignmentCatalog: current.alignmentCatalog,
    ));
  }

  /// Corrige la race vers l'entrée [name] de [RaceCatalog.races] (candidats
  /// affichés par la bottom sheet de correction) — sans effet si l'état n'est
  /// pas encore chargé.
  void correctRace(String name) {
    final current = state.value;
    if (current == null) return;
    final match = XmlNameResolver.resolveByName(
      rawName: name,
      candidates: current.raceCatalog.races,
      nameOf: (race) => race.name,
    );
    _updateResolved(current.resolved.copyWith(race: match));
  }

  void correctClass(String name) {
    final current = state.value;
    if (current == null) return;
    final match = XmlNameResolver.resolveByName(
      rawName: name,
      candidates: current.classCatalog.classes,
      nameOf: (classOption) => classOption.name,
    );
    _updateResolved(current.resolved.copyWith(characterClass: match));
  }

  void correctBackground(String name) {
    final current = state.value;
    if (current == null) return;
    final match = XmlNameResolver.resolveByName(
      rawName: name,
      candidates: current.backgroundCatalog.backgrounds,
      nameOf: (background) => background.name,
    );
    _updateResolved(current.resolved.copyWith(background: match));
  }

  /// Corrige une entrée de `toolProficiencies[groupId][index]` vers l'outil
  /// [name] de [ToolCatalog.tools] — [groupId] est la source aidedd (`0`
  /// race, `1` classe, `2` historique, `3` autres, voir
  /// `AideddReferenceTables.proficiencySources`).
  void correctToolProficiency({
    required int groupId,
    required int index,
    required String name,
  }) {
    final current = state.value;
    if (current == null) return;
    final match = XmlNameResolver.resolveByName(
      rawName: name,
      candidates: current.toolCatalog.tools,
      nameOf: (tool) => tool.name,
    );
    final group = [...?current.resolved.toolProficiencies[groupId]];
    if (index < 0 || index >= group.length) return;
    group[index] = match;
    _updateResolved(
      current.resolved.copyWith(
        toolProficiencies: {
          ...current.resolved.toolProficiencies,
          groupId: group,
        },
      ),
    );
  }

  void correctLanguage({
    required int groupId,
    required int index,
    required String name,
  }) {
    final current = state.value;
    if (current == null) return;
    final match = XmlNameResolver.resolveByName(
      rawName: name,
      candidates: current.languageCatalog.languages,
      nameOf: (language) => language.name,
    );
    final group = [...?current.resolved.languages[groupId]];
    if (index < 0 || index >= group.length) return;
    group[index] = match;
    _updateResolved(
      current.resolved.copyWith(
        languages: {...current.resolved.languages, groupId: group},
      ),
    );
  }

  /// Corrige une entrée de `skillProficiencies[groupId][index]` vers le
  /// libellé aidedd [label] (candidats : `AideddReferenceTables.skills`, voir
  /// la spec de la bottom sheet — pas un `SkillOption` réel, la résolution
  /// vers un `skill_id` réel n'a lieu qu'à la sauvegarde, voir
  /// `domain/xml_import_save_data_resolver.dart`).
  void correctSkill({
    required int groupId,
    required int index,
    required String label,
  }) {
    final current = state.value;
    if (current == null) return;
    final group = [...?current.resolved.skillProficiencies[groupId]];
    if (index < 0 || index >= group.length) return;
    group[index] = XmlFieldResolution<String>.recognized(label);
    _updateResolved(
      current.resolved.copyWith(
        skillProficiencies: {
          ...current.resolved.skillProficiencies,
          groupId: group,
        },
      ),
    );
  }

  void correctInnateSpell(int index, String name) {
    final current = state.value;
    if (current == null) return;
    final match = XmlNameResolver.resolveByName(
      rawName: name,
      candidates: current.spellCatalog.spells,
      nameOf: (spell) => spell.name,
    );
    final list = [...current.resolved.innateSpells];
    if (index < 0 || index >= list.length) return;
    list[index] = (level: list[index].level, resolution: match);
    _updateResolved(current.resolved.copyWith(innateSpells: list));
  }

  void correctKnownSpell(int index, String name) {
    final current = state.value;
    if (current == null) return;
    final match = XmlNameResolver.resolveByName(
      rawName: name,
      candidates: current.spellCatalog.spells,
      nameOf: (spell) => spell.name,
    );
    final list = [...current.resolved.knownSpells];
    if (index < 0 || index >= list.length) return;
    list[index] = (level: list[index].level, resolution: match);
    _updateResolved(current.resolved.copyWith(knownSpells: list));
  }

  /// Corrige une entrée de `weapons[index]` vers le libellé aidedd [label]
  /// (candidats : `AideddReferenceTables.weapons`) — la quantité déjà
  /// résolue est préservée.
  void correctWeapon(int index, String label) {
    final current = state.value;
    if (current == null) return;
    final list = [...current.resolved.weapons];
    if (index < 0 || index >= list.length) return;
    list[index] = (
      resolution: XmlFieldResolution<String>.recognized(label),
      quantity: list[index].quantity,
    );
    _updateResolved(current.resolved.copyWith(weapons: list));
  }

  void correctToolEquipment(int index, String label) {
    final current = state.value;
    if (current == null) return;
    final list = [...current.resolved.toolEquipment];
    if (index < 0 || index >= list.length) return;
    list[index] = (
      resolution: XmlFieldResolution<String>.recognized(label),
      quantity: list[index].quantity,
    );
    _updateResolved(current.resolved.copyWith(toolEquipment: list));
  }

  void correctItem(int index, String label) {
    final current = state.value;
    if (current == null) return;
    final list = [...current.resolved.items];
    if (index < 0 || index >= list.length) return;
    list[index] = (
      resolution: XmlFieldResolution<String>.recognized(label),
      quantity: list[index].quantity,
    );
    _updateResolved(current.resolved.copyWith(items: list));
  }

  /// Corrige un champ singulier `XmlFieldResolution<String>` par simple
  /// remplacement de sa valeur (`armor`/`shield`/`alignment`/`sexe`, voir
  /// `presentation/xml_import_review_screen.dart` pour la liste des
  /// identifiants gérés) — un seul point d'entrée plutôt qu'une méthode par
  /// champ, ces 4 champs partageant exactement la même mécanique de
  /// correction (candidats `AideddReferenceTables.xxx`, aucun catalogue réel
  /// à interroger).
  void correctCodedField(String fieldId, String label) {
    final current = state.value;
    if (current == null) return;
    final value = XmlFieldResolution<String>.recognized(label);
    final updated = switch (fieldId) {
      'armor' => current.resolved.copyWith(armor: value),
      'shield' => current.resolved.copyWith(shield: value),
      'alignment' => current.resolved.copyWith(alignment: value),
      'sexe' => current.resolved.copyWith(sexe: value),
      _ => current.resolved,
    };
    _updateResolved(updated);
  }
}
