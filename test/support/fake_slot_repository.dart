// Dépôt en mémoire et fiches de test partagés par les tests de la
// correction/annulation d'emplacements (P9) : journalise les écritures
// absolues `castSpell` (même méthode que le lancer, kind de file `spell_slot`).

import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';

const fireball = CharacterSpellEntry(
  id: 1,
  name: 'Boule de feu',
  level: 3,
  school: 'Évocation',
  status: SpellStatus.prepared,
);
const counterspell = CharacterSpellEntry(
  id: 2,
  name: 'Contresort',
  level: 3,
  school: 'Abjuration',
  status: SpellStatus.prepared,
);
const light = CharacterSpellEntry(
  id: 3,
  name: 'Lumière',
  level: 0,
  school: 'Évocation',
  status: SpellStatus.known,
);
const frostRay = CharacterSpellEntry(
  id: 4,
  name: 'Rayon de givre',
  level: 1,
  school: 'Évocation',
  status: SpellStatus.prepared,
);

/// Magicien niveau 5 : emplacements 1 à 3, les sorts de niveau 3 n'ont qu'un
/// seul niveau d'emplacement éligible (le 3) -> lancés sans sheet de choix.
CharacterDetail wizardDetail({int level3Used = 0}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: const [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 6,
      className: 'Magicien',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 18,
  maxHp: 24,
  temporaryHp: 0,
  abilityScores: const {},
  spells: const [fireball, counterspell, light],
  spellSlots: [
    const CharacterSpellSlot(level: 1, total: 4, used: 0),
    const CharacterSpellSlot(level: 2, total: 3, used: 0),
    CharacterSpellSlot(level: 3, total: 2, used: level3Used),
  ],
);

CharacterDetail warlockDetail() => const CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
      className: 'Occultiste',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 18,
  maxHp: 24,
  temporaryHp: 0,
  abilityScores: {},
  spells: [frostRay],
  spellSlots: [],
  pactSpellSlot: CharacterSpellSlot(level: 2, total: 2, used: 0, isPact: true),
);

typedef SlotWrite = ({int level, int used, bool isPact});

class FakeSlotRepository implements CharacterRepository {
  FakeSlotRepository(this.current);

  CharacterDetail current;
  final writes = <SlotWrite>[];
  WriteOutcome outcome = WriteOutcome.synced;
  Object? error;
  int restCount = 0;

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      current;

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    bool isPactSlot = false,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    writes.add((level: slotLevel, used: slotsUsed, isPact: isPactSlot));
    // Rejoue la superposition de la file : la fiche relue porte la valeur
    // écrite, que l'écriture soit confirmée ou seulement mise en file.
    if (isPactSlot) {
      final pact = current.pactSpellSlot!;
      current = current.copyWith(
        pactSpellSlot: CharacterSpellSlot(
          level: pact.level,
          total: pact.total,
          used: slotsUsed,
          isPact: true,
        ),
      );
    } else {
      current = current.copyWith(
        spellSlots: [
          for (final slot in current.spellSlots)
            if (slot.level == slotLevel)
              CharacterSpellSlot(
                level: slot.level,
                total: slot.total,
                used: slotsUsed,
              )
            else
              slot,
        ],
      );
    }
    return outcome;
  }

  @override
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    Map<String, int> hitDiceSpentByClassId = const {},
    int appliedGain = 0,
    Map<String, int> hitDiceRecoveredByClassId = const {},
  }) async {
    restCount++;
    current = current.copyWith(
      spellSlots: [
        for (final slot in current.spellSlots)
          CharacterSpellSlot(level: slot.level, total: slot.total, used: 0),
      ],
    );
    return WriteOutcome.synced;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
