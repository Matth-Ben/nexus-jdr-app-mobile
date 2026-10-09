import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spell_slot_progression.dart';
import 'package:personnages/features/xml_import/data/xml_import_repository.dart';
import 'package:personnages/features/xml_import/domain/xml_import_save_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Couvre `SupabaseXmlImportRepository.saveImportedCharacter` contre un vrai
/// stack Supabase local — voir `test_integration/README.md` pour le
/// rationale général de ce dossier (jamais de mock du client Supabase
/// lui-même, détection des colonnes/contraintes réelles).
///
/// Premier fichier de test pour ce repository (aucun test_integration ne le
/// couvrait avant la tâche D14, `docs/dette-technique.md`) : volontairement
/// resserré sur le correctif D14 (initialisation de `character_spell_slots`
/// à l'import, au niveau RÉELLEMENT importé plutôt qu'au niveau 1), étendu
/// par D71 au même correctif pour `character_pact_slots` (magie de pacte de
/// l'Occultiste) — plutôt qu'une couverture exhaustive de toutes les tables
/// enfants déjà exercées côté
/// `character_creation_repository_integration_test.dart` pour
/// `createCharacter` (le même compromis d'écriture, voir la documentation de
/// classe de `XmlImportRepository`).
///
/// [_minimalSaveData] construit un `XmlImportSaveData` minimal à la main
/// (record, pas de classe à instancier) plutôt que de repasser par tout le
/// pipeline de parsing/résolution XML (`XmlCharacterImportParser` ->
/// `XmlCharacterImportResolver` -> `XmlImportSaveDataResolver`, déjà exercé
/// de bout en bout par `test/features/xml_export/data
/// /xml_character_exporter_round_trip_test.dart`, qui ne parle lui jamais au
/// réseau) : seuls `classId`/`className`/`level` (et les champs non
/// nullables obligatoires) comptent pour ce correctif.
void main() {
  group('SupabaseXmlImportRepository (intégration)', () {
    late SupabaseClient client;
    late ReferenceContent reference;
    // `ReferenceContent.spellcastingClassId` n'est volontairement pas
    // utilisé ici : construit par `fetchReferenceContent` via
    // `spell_classes.select(...).order('class_id').limit(1)` **sans**
    // `ascending: true` explicite, il dépend du défaut du package Postgrest
    // (voir la note déjà présente sur `SupabaseCharacterCreationRepository
    // .fetchRaceCatalog` : ce défaut a changé de comportement selon la
    // version du package, les tests de tri de ce fichier de test
    // d'intégration échouent d'ailleurs déjà pour cette raison en l'état
    // actuel de l'environnement). Sur le contenu peuplé actuel, ce choix non
    // déterministe peut même retomber sur une classe comme l'Artificier, qui
    // a bien des sorts (`spell_classes`) mais n'est PAS encore couverte par
    // `SpellSlotProgression` (dette distincte, hors périmètre D14 — voir
    // `nonZeroSlotTotals`, qui retournerait alors une liste vide, rendant ce
    // test non concluant). On résout donc ici, une seule fois, l'id réel
    // d'une classe du contenu peuplé qu'on SAIT couverte par
    // [SpellSlotProgression.fullCasterClassNames] ('Magicien'), par son nom
    // français exact plutôt que par position.
    late int magicienClassId;
    late int occultisteClassId;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      reference = await fetchReferenceContent(client);
      magicienClassId = await _fetchClassIdByName(client, 'Magicien');
      occultisteClassId = await _fetchClassIdByName(client, 'Occultiste');
    });

    test('saveImportedCharacter peuple character_spell_slots au niveau '
        'RÉELLEMENT importé (pas forcément 1) pour une classe lanceuse de '
        'sorts', () async {
      final repository = SupabaseXmlImportRepository(client);

      // Un lanceur de sorts complet (Magicien) importé déjà au niveau 5
      // (pas 1) : vérifie que l'initialisation D14 utilise bien le niveau
      // réellement importé, pas un niveau 1 implicite (contrairement à
      // `createCharacter`, qui lui n'a jamais que le niveau 1 à la
      // création).
      final data = _minimalSaveData(
        classId: magicienClassId,
        className: 'Magicien',
        level: 5,
      );

      final characterId = await repository.saveImportedCharacter(
        data: data,
        characterName: 'Test Intégration Import Sorts',
      );
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final expectedSlots = SpellSlotProgression.nonZeroSlotTotals([
        (className: 'Magicien', level: 5),
      ]);
      expect(
        expectedSlots,
        isNotEmpty,
        reason: 'niveau 5 : le Magicien a toujours au moins le palier 1',
      );

      final spellSlotRows = await client
          .from('character_spell_slots')
          .select()
          .eq('character_id', characterId)
          .order('slot_level', ascending: true);
      expect(spellSlotRows, hasLength(expectedSlots.length));
      for (var i = 0; i < expectedSlots.length; i++) {
        expect(spellSlotRows[i]['slot_level'], expectedSlots[i].slotLevel);
        expect(
          (spellSlotRows[i]['slots_total'] as num).toInt(),
          expectedSlots[i].total,
        );
        expect((spellSlotRows[i]['slots_used'] as num).toInt(), 0);
      }
    });

    test('saveImportedCharacter n\'écrit aucune ligne character_spell_slots '
        'ni character_pact_slots pour une classe non lanceuse de sorts '
        '(même garde-fou que createCharacter, D14/D71)', () async {
      final repository = SupabaseXmlImportRepository(client);

      // `reference.classId` n'est pas garanti lanceur de sorts (contenu
      // peuplé actuel : Barbare) — voir la documentation de
      // `ReferenceContent.spellcastingClassId`.
      final data = _minimalSaveData(
        classId: reference.classId as int,
        className: reference.className,
        level: 3,
      );

      final characterId = await repository.saveImportedCharacter(
        data: data,
        characterName: 'Test Intégration Import Sans Sorts',
      );
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final spellSlotRows = await client
          .from('character_spell_slots')
          .select()
          .eq('character_id', characterId);
      expect(spellSlotRows, isEmpty);

      final pactSlotRows = await client
          .from('character_pact_slots')
          .select()
          .eq('character_id', characterId);
      expect(pactSlotRows, isEmpty);
    });

    test('saveImportedCharacter peuple character_pact_slots au niveau '
        'RÉELLEMENT importé pour un Occultiste (D71 : avant ce correctif, '
        'cette table n\'était jamais écrite à l\'import)', () async {
      final repository = SupabaseXmlImportRepository(client);

      // Occultiste importé déjà au niveau 11 (pas 1) : vérifie que
      // l'initialisation D71 utilise bien le niveau réellement importé —
      // au niveau 11, les charges passent de 2 à 3 (voir
      // `SpellSlotProgression._pactMagicSlots`), donc ce choix de niveau
      // distingue bien ce correctif d'une simple initialisation au niveau
      // 1 implicite.
      final data = _minimalSaveData(
        classId: occultisteClassId,
        className: 'Occultiste',
        level: 11,
      );

      final characterId = await repository.saveImportedCharacter(
        data: data,
        characterName: 'Test Intégration Import Pacte',
      );
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final expectedPact = SpellSlotProgression.pactMagicFor(11);
      expect(expectedPact, isNotNull);

      final pactSlotRows = await client
          .from('character_pact_slots')
          .select()
          .eq('character_id', characterId);
      expect(pactSlotRows, hasLength(1));
      expect(pactSlotRows.single['slot_level'], expectedPact!.slotLevel);
      expect(
        (pactSlotRows.single['slots_total'] as num).toInt(),
        expectedPact.charges,
      );
      expect((pactSlotRows.single['slots_used'] as num).toInt(), 0);

      // Aucune ligne `character_spell_slots` : l'Occultiste n'est jamais
      // un lanceur "non-pacte".
      final spellSlotRows = await client
          .from('character_spell_slots')
          .select()
          .eq('character_id', characterId);
      expect(spellSlotRows, isEmpty);
    });

    test('saveImportedCharacter n\'écrit aucune ligne character_spell_slots '
        'ni character_pact_slots quand la classe importée est restée non '
        'reconnue (classId/className nuls)', () async {
      final repository = SupabaseXmlImportRepository(client);

      final data = _minimalSaveData(classId: null, className: null, level: 1);

      final characterId = await repository.saveImportedCharacter(
        data: data,
        characterName: 'Test Intégration Import Classe Inconnue',
      );
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final classRows = await client
          .from('character_classes')
          .select()
          .eq('character_id', characterId);
      expect(classRows, isEmpty);

      final spellSlotRows = await client
          .from('character_spell_slots')
          .select()
          .eq('character_id', characterId);
      expect(spellSlotRows, isEmpty);

      final pactSlotRows = await client
          .from('character_pact_slots')
          .select()
          .eq('character_id', characterId);
      expect(pactSlotRows, isEmpty);
    });
  });
}

/// `classes.id` réel pour le nom de classe français exact [name] — requête
/// inverse de `test_environment.dart::_fetchFirstTranslatedName` (qui va de
/// l'id vers le nom) : ici on connaît déjà le nom qu'on veut (une classe
/// couverte par `SpellSlotProgression`, voir la note d'appel) et on a besoin
/// de son id réel pour construire un `XmlImportSaveData` valide
/// (`character_classes.class_id` est une vraie FK).
Future<int> _fetchClassIdByName(SupabaseClient client, String name) async {
  final row = await client
      .from('translations')
      .select('entity_id')
      .eq('entity_type', 'class')
      .eq('field_name', 'name')
      .eq('locale', 'fr')
      .eq('value', name)
      .single();
  return int.parse(row['entity_id'] as String);
}

XmlImportSaveData _minimalSaveData({
  required int? classId,
  required String? className,
  required int level,
}) {
  return (
    raceId: null,
    subraceId: null,
    raceCustomText: null,
    backgroundId: null,
    backgroundCustomText: null,
    alignmentId: null,
    xp: 0,
    maxHp: 1,
    sexe: 'Non renseigné',
    age: null,
    height: null,
    weight: null,
    eyes: null,
    skin: null,
    hair: null,
    appearanceText: '',
    traitsText: '',
    idealsText: '',
    bondsText: '',
    flawsText: '',
    backstoryText: '',
    alliesText: '',
    featuresText: '',
    treasureText: '',
    currencyGp: 0,
    currencyPp: 0,
    currencyEp: 0,
    currencySp: 0,
    currencyCp: 0,
    classId: classId,
    className: className,
    level: level,
    abilityScores: const <String, int>{},
    levelHp: const [],
    skillProficiencyLines: const [],
    toolProficiencyLines: const [],
    languageIds: const [],
    spellLines: const [],
    inventoryLines: const [],
  );
}
