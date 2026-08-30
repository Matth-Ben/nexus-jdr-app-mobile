import '../../character_creation/domain/background_catalog.dart';
import '../../character_creation/domain/class_catalog.dart';
import '../../character_creation/domain/language_catalog.dart';
import '../../character_creation/domain/race_catalog.dart';
import '../../character_creation/domain/spell_catalog.dart';
import '../../character_creation/domain/tool_catalog.dart';
import 'aidedd_reference_tables.dart';
import 'xml_character_import_raw.dart';
import 'xml_character_import_resolved.dart';
import 'xml_coded_field_resolver.dart';
import 'xml_field_resolution.dart';
import 'xml_name_resolver.dart';
import 'xml_named_option.dart';

/// Résout un [XmlCharacterImportRaw] (sortie pure de
/// `data/xml_character_import_parser.dart`) en [XmlCharacterImportResolved]
/// — voir `docs/cahier-des-charges/03-import-xml-aidedd.md`, points 3 et 4
/// du "Comportement attendu de l'import".
///
/// Réutilise directement les catalogues déjà exposés par
/// `character_creation/data/character_creation_repository.dart`
/// ([RaceCatalog], [ClassCatalog], [BackgroundCatalog], [ToolCatalog],
/// [LanguageCatalog], [SpellCatalog]) plutôt que de réinventer une nouvelle
/// requête Supabase pour ces 6 catalogues — mêmes tables, même mécanisme de
/// résolution par nom que l'assistant de création (voir la consigne
/// d'origine de la tâche). L'appelant (un futur provider Riverpod de
/// l'écran de vérification, increment suivant) est responsable de les avoir
/// déjà chargés, exactement comme `SummaryStepScreen` le fait aujourd'hui
/// pour l'étape 9/9 de l'assistant.
///
/// [subclassCandidates]/[invocationCandidates] n'ont **pas** d'équivalent
/// catalogue existant ailleurs dans l'app (voir la documentation de
/// [XmlNamedOption]) : listes vides par défaut, ce qui fait retomber tout
/// `classPath`/`knownInvocation` réellement présent sur
/// [XmlFieldResolution.unrecognized] tant que l'appelant ne les fournit pas
/// — comportement sûr (jamais un crash), pas un blocage de l'import (voir
/// `03-import-xml-aidedd.md` point 4).
abstract final class XmlCharacterImportResolver {
  static XmlCharacterImportResolved resolve({
    required XmlCharacterImportRaw raw,
    required RaceCatalog raceCatalog,
    required ClassCatalog classCatalog,
    required BackgroundCatalog backgroundCatalog,
    required ToolCatalog toolCatalog,
    required LanguageCatalog languageCatalog,
    required SpellCatalog spellCatalog,
    List<XmlNamedOption> subclassCandidates = const [],
    List<XmlNamedOption> invocationCandidates = const [],
  }) {
    final classPath = raw.classPath?.trim();

    return XmlCharacterImportResolved(
      race: XmlNameResolver.resolveByName(
        rawName: raw.race,
        candidates: raceCatalog.races,
        nameOf: (race) => race.name,
      ),
      raceCustomText: raw.raceCustom,
      characterClass: XmlNameResolver.resolveByName(
        rawName: raw.characterClass,
        candidates: classCatalog.classes,
        nameOf: (classOption) => classOption.name,
      ),
      subclass: (classPath == null || classPath.isEmpty)
          ? null
          : XmlNameResolver.resolveByName(
              rawName: classPath,
              candidates: subclassCandidates,
              nameOf: (subclass) => subclass.name,
            ),
      level: raw.level,
      background: XmlNameResolver.resolveByName(
        rawName: raw.background,
        candidates: backgroundCatalog.backgrounds,
        nameOf: (background) => background.name,
      ),
      backgroundCustomText: raw.backSpe,
      abilityScores: raw.abilityScores,
      levels: raw.levels,
      styleCombat1: _unrecognizedIfPresent(raw.styleCombat1),
      styleCombat2: _unrecognizedIfPresent(raw.styleCombat2),
      favoredEnemy0: _unrecognizedIfPresent(raw.favoredEnemy0),
      favoredEnemy6: _unrecognizedIfPresent(raw.favoredEnemy6),
      favoredEnemy14: _unrecognizedIfPresent(raw.favoredEnemy14),
      skillProficiencies: {
        for (final entry in raw.skillsProf.entries)
          entry.key: [
            for (final token in entry.value)
              XmlCodedFieldResolver.resolveByRawToken(
                rawToken: token,
                table: AideddReferenceTables.skills,
              ),
          ],
      },
      toolProficiencies: {
        for (final entry in raw.toolsProf.entries)
          entry.key: [
            for (final name in entry.value)
              XmlNameResolver.resolveByName(
                rawName: name,
                candidates: toolCatalog.tools,
                nameOf: (tool) => tool.name,
              ),
          ],
      },
      languages: {
        for (final entry in raw.languages.entries)
          entry.key: [
            for (final name in entry.value)
              XmlNameResolver.resolveByName(
                rawName: name,
                candidates: languageCatalog.languages,
                nameOf: (language) => language.name,
              ),
          ],
      },
      innateSpells: [
        for (final spell in raw.innateSpells)
          (
            level: spell.level,
            resolution: XmlNameResolver.resolveByName(
              rawName: spell.name,
              candidates: spellCatalog.spells,
              nameOf: (spellOption) => spellOption.name,
            ),
          ),
      ],
      knownSpells: [
        for (final spell in raw.knownSpells)
          (
            level: spell.level,
            resolution: XmlNameResolver.resolveByName(
              rawName: spell.name,
              candidates: spellCatalog.spells,
              nameOf: (spellOption) => spellOption.name,
            ),
          ),
      ],
      knownInvocations: [
        for (final name in raw.knownInvocations)
          XmlNameResolver.resolveByName(
            rawName: name,
            candidates: invocationCandidates,
            nameOf: (invocation) => invocation.name,
          ),
      ],
      gp: raw.gp,
      pp: raw.pp,
      ep: raw.ep,
      sp: raw.sp,
      cp: raw.cp,
      armor: XmlCodedFieldResolver.resolveById(
        id: raw.armor,
        table: AideddReferenceTables.armor,
      ),
      shield: XmlCodedFieldResolver.resolveById(
        id: raw.shield,
        table: AideddReferenceTables.shield,
      ),
      weapons: _resolveQuantifiedIds(
        tokens: raw.weaponIds,
        quantities: raw.weaponQuantities,
        table: AideddReferenceTables.weapons,
      ),
      toolEquipment: _resolveQuantifiedIds(
        tokens: raw.toolEquipmentIds,
        // Pas de liste de quantité dédiée pour `<tools>` dans le XML, voir
        // `XmlCharacterImportRaw.toolEquipmentIds` — toujours 1.
        quantities: List<int>.filled(raw.toolEquipmentIds.length, 1),
        table: AideddReferenceTables.toolsEquipment,
      ),
      items: _resolveQuantifiedIds(
        tokens: raw.itemIds,
        quantities: raw.itemQuantities,
        table: AideddReferenceTables.items,
      ),
      customItems: [
        for (final text in raw.customItemTexts)
          XmlFieldResolution<String>.custom(text),
      ],
      name: raw.name,
      sexe: XmlCodedFieldResolver.resolveById(
        id: raw.sexe,
        table: AideddReferenceTables.sexes,
      ),
      age: raw.age,
      height: raw.height,
      weight: raw.weight,
      alignment: XmlCodedFieldResolver.resolveById(
        id: raw.alignment,
        table: AideddReferenceTables.alignments,
      ),
      xp: raw.xp,
      eyes: raw.eyes,
      skin: raw.skin,
      hair: raw.hair,
      pack: raw.pack == null
          ? null
          : XmlCodedFieldResolver.resolveById(
              id: raw.pack,
              table: AideddReferenceTables.packs,
            ),
      appearanceText: raw.appearanceText,
      traitsText: raw.traitsText,
      idealsText: raw.idealsText,
      bondsText: raw.bondsText,
      flawsText: raw.flawsText,
      backstoryText: raw.backstoryText,
      alliesText: raw.alliesText,
      featuresText: raw.featuresText,
      treasureText: raw.treasureText,
    );
  }

  /// Combine une liste positionnelle de jetons bruts codés (voir
  /// `XmlCharacterImportRaw.weaponIds`/`toolEquipmentIds`/`itemIds` pour le
  /// rationale du type `List<String>` plutôt que `List<int>`) avec sa liste
  /// de quantités associée (`weapon`+`weaponQ`, `item`+`itemQ`, `tools` avec
  /// une quantité 1 implicite) en résolvant chaque jeton via [table] — les
  /// emplacements vides (jeton `"0"`, un entier valide égal à `0`, voir la
  /// documentation de [AideddReferenceTables.weapons]) sont filtrés, jamais
  /// résolus comme "non reconnu". Un jeton corrompu (pas un entier valide,
  /// ex. `"abc"`) n'est **jamais** filtré : il n'est égal à `0` par aucune
  /// interprétation, donc il ressort bien
  /// [XmlFieldResolution.unrecognized] avec le jeton brut préservé plutôt
  /// que de disparaître silencieusement de l'import (bug relevé en revue QA
  /// de l'increment 1). [quantities] plus courte que [tokens] retombe sur
  /// une quantité de 1 pour les entrées en trop (défensif, ne devrait pas
  /// arriver sur un export réel où les deux listes ont toujours la même
  /// longueur).
  static List<XmlQuantifiedResolution> _resolveQuantifiedIds({
    required List<String> tokens,
    required List<int> quantities,
    required Map<int, String> table,
  }) {
    final result = <XmlQuantifiedResolution>[];
    for (var index = 0; index < tokens.length; index++) {
      final token = tokens[index];
      if (int.tryParse(token.trim()) == 0) continue;
      final quantity = index < quantities.length ? quantities[index] : 1;
      result.add((
        resolution: XmlCodedFieldResolver.resolveByRawToken(
          rawToken: token,
          table: table,
        ),
        quantity: quantity,
      ));
    }
    return result;
  }

  /// `null` si [raw] est absent/vide, sinon toujours
  /// [XmlFieldResolution.unrecognized] avec le contenu brut — voir la
  /// documentation de [XmlCharacterImportResolved.styleCombat1] pour le
  /// rationale (aucune table de correspondance fiable pour ces deux champs à
  /// ce stade, voir `docs/xml-import-reference-mapping.md`).
  static XmlFieldResolution<String>? _unrecognizedIfPresent(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return XmlFieldResolution<String>.unrecognized(raw.trim());
  }
}
