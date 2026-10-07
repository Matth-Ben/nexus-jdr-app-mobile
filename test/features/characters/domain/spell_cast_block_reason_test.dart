// Tests unitaires de `domain/spell_cast_block_reason.dart` : quelle raison
// afficher sous le bouton "Lancer" désactivé du panneau "Infos" d'un sort.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/innate_spell_usage.dart';
import 'package:personnages/features/characters/domain/spell_cast_block_reason.dart';
import 'package:personnages/features/characters/domain/spell_cast_eligibility.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/domain/spell_status_formatter.dart';

CharacterSpellEntry _spell({
  required int level,
  required String status,
  int innateUsesSpent = 0,
}) {
  return CharacterSpellEntry(
    id: 1,
    name: 'Test',
    level: level,
    school: '',
    status: status,
    innateUsesSpent: innateUsesSpent,
  );
}

void main() {
  const available = [CharacterSpellSlot(level: 3, total: 2, used: 1)];
  const exhausted = [CharacterSpellSlot(level: 3, total: 2, used: 2)];

  group('SpellCastBlockReason.of', () {
    test('sort préparé avec un emplacement disponible -> null', () {
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 3, status: 'préparé'),
          spellSlots: available,
        ),
        isNull,
      );
    });

    test("sort 'connu' (non préparé) avec un emplacement -> unprepared", () {
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 3, status: 'connu'),
          spellSlots: available,
        ),
        SpellCastBlockReason.unprepared,
      );
    });

    test('sort préparé, emplacements épuisés -> noSlotAvailable', () {
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 3, status: 'préparé'),
          spellSlots: exhausted,
        ),
        SpellCastBlockReason.noSlotAvailable,
      );
    });

    test('non préparé ET plus d\'emplacement -> unprepared en priorité', () {
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 3, status: 'connu'),
          spellSlots: exhausted,
        ),
        SpellCastBlockReason.unprepared,
      );
    });

    // Inversé (D08) : un sort inné de niveau >= 1 exigeait un emplacement
    // (« sort 'inné' : jamais unprepared, seul l'emplacement compte »).
    test("sort 'inné' de niveau >= 1, usage disponible : lançable sans "
        'emplacement, quels que soient les emplacements', () {
      for (final slots in [
        available,
        exhausted,
        const <CharacterSpellSlot>[],
      ]) {
        expect(
          SpellCastBlockReason.of(
            spell: _spell(level: 3, status: 'inné'),
            spellSlots: slots,
          ),
          isNull,
          reason: '$slots',
        );
      }
    });

    test("sort 'inné' de niveau >= 1, usage dépensé : innateUseSpent, même "
        'avec des emplacements disponibles (pas de relance avec un '
        'emplacement)', () {
      for (final slots in [
        available,
        exhausted,
        const <CharacterSpellSlot>[],
      ]) {
        expect(
          SpellCastBlockReason.of(
            spell: _spell(level: 3, status: 'inné', innateUsesSpent: 1),
            spellSlots: slots,
          ),
          SpellCastBlockReason.innateUseSpent,
          reason: '$slots',
        );
      }
    });

    test("sort 'inné' épuisé d'une classe à préparation (origine inconnue) : "
        'innateUseSpent prioritaire, jamais unprepared ni noSlotAvailable', () {
      for (var level = 1; level <= 9; level++) {
        for (final spent in [1, 2, 99]) {
          expect(
            SpellCastBlockReason.of(
              spell: _spell(
                level: level,
                status: 'inné',
                innateUsesSpent: spent,
              ),
              spellSlots: const [],
            ),
            SpellCastBlockReason.innateUseSpent,
            reason: 'niveau $level, $spent dépensé(s)',
          );
        }
      }
    });

    test('sort mineur inné (niveau 0) : à volonté, null même avec un '
        'compteur dépensé aberrant', () {
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 0, status: 'inné', innateUsesSpent: 1),
          spellSlots: const [],
        ),
        isNull,
      );
    });

    test("le compteur n'a aucun effet sur un sort qui n'est pas inné", () {
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 3, status: 'préparé', innateUsesSpent: 1),
          spellSlots: available,
        ),
        isNull,
      );
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 3, status: 'connu', innateUsesSpent: 1),
          spellSlots: available,
        ),
        SpellCastBlockReason.unprepared,
      );
    });

    test('sort mineur (niveau 0) -> toujours null, quel que soit le statut '
        'et sans aucun emplacement', () {
      for (final status in ['connu', 'préparé', 'inné']) {
        expect(
          SpellCastBlockReason.of(
            spell: _spell(level: 0, status: status),
            spellSlots: const [],
          ),
          isNull,
          reason: status,
        );
      }
    });
  });

  // L'ajout de la raison ne doit pas changer quand "Lancer" est actif.
  group('SpellCastBlockReason.of — activation de "Lancer" inchangée', () {
    test('équivalence stricte avec l\'ancienne règle '
        '(hasAvailableSlot && canCast) sur toute la matrice '
        'niveau x statut x origine x emplacements', () {
      const slotConfigs = <String, List<CharacterSpellSlot>>{
        'aucun emplacement': [],
        'niv.1 disponible': [CharacterSpellSlot(level: 1, total: 2, used: 0)],
        'niv.1 épuisé': [CharacterSpellSlot(level: 1, total: 2, used: 2)],
        'niv.3 épuisé, niv.5 disponible': [
          CharacterSpellSlot(level: 3, total: 2, used: 2),
          CharacterSpellSlot(level: 5, total: 1, used: 0),
        ],
        'niv.3 disponible, niv.5 épuisé': [
          CharacterSpellSlot(level: 3, total: 2, used: 1),
          CharacterSpellSlot(level: 5, total: 1, used: 1),
        ],
        'pacte seul niv.2 disponible': [
          CharacterSpellSlot(level: 2, total: 2, used: 1, isPact: true),
        ],
        'pacte seul niv.2 épuisé': [
          CharacterSpellSlot(level: 2, total: 2, used: 2, isPact: true),
        ],
        'classique épuisé + pacte disponible': [
          CharacterSpellSlot(level: 1, total: 4, used: 4),
          CharacterSpellSlot(level: 3, total: 2, used: 0, isPact: true),
        ],
        'données incohérentes (used > total, total 0)': [
          CharacterSpellSlot(level: 2, total: 1, used: 5),
          CharacterSpellSlot(level: 9, total: 0, used: 0),
        ],
        'niv.9 disponible': [CharacterSpellSlot(level: 9, total: 1, used: 0)],
      };
      // '' / 'autre' : valeur inattendue (contrainte check côté base).
      const statuses = ['connu', 'préparé', 'inné', '', 'autre'];
      const grants = <SpellGrantSource?>[null, ...SpellGrantSource.values];

      var checked = 0;
      for (var level = 0; level <= 9; level++) {
        for (final status in statuses) {
          for (final grant in grants) {
            for (final config in slotConfigs.entries) {
              final spell = CharacterSpellEntry(
                id: 1,
                name: 'Test',
                level: level,
                school: '',
                status: status,
                grantSource: grant,
              );
              final legacyCanCast =
                  SpellCastEligibility.hasAvailableSlot(
                    spellSlots: config.value,
                    spellLevel: spell.level,
                  ) &&
                  SpellStatusFormatter.canCast(spell);
              final reason = SpellCastBlockReason.of(
                spell: spell,
                spellSlots: config.value,
              );
              final context =
                  'niveau $level, statut "$status", origine $grant, '
                  '${config.key}';

              // Seule exception à l'ancienne règle (D08) : un sort inné de
              // niveau >= 1 se lance sans emplacement tant que son usage est
              // disponible (compteur à 0 ici).
              if (InnateSpellUsage.isLimited(spell)) {
                expect(reason, isNull, reason: context);
                checked++;
                continue;
              }

              expect(reason == null, legacyCanCast, reason: context);
              // La raison retournée doit être la bonne, pas seulement
              // "non nulle" : "non préparé" prioritaire, sinon emplacement.
              if (!legacyCanCast) {
                expect(
                  reason,
                  SpellStatusFormatter.canCast(spell)
                      ? SpellCastBlockReason.noSlotAvailable
                      : SpellCastBlockReason.unprepared,
                  reason: context,
                );
              }
              checked++;
            }
          }
        }
      }
      // Garde-fou : la matrice a bien été parcourue.
      expect(
        checked,
        10 * statuses.length * grants.length * slotConfigs.length,
      );
    });

    test('sort accordé par une sous-classe (grantSource non nul, statut '
        "'préparé') : jamais unprepared", () {
      for (final grant in SpellGrantSource.values) {
        CharacterSpellEntry granted() => CharacterSpellEntry(
          id: 1,
          name: 'Test',
          level: 3,
          school: '',
          status: 'préparé',
          grantSource: grant,
          isPersisted: false,
          // Ligne en base 'connu' : seul [status] (toujours 'préparé' pour
          // un sort accordé) doit compter, jamais [storedStatus].
          storedStatus: 'connu',
        );
        expect(
          SpellCastBlockReason.of(spell: granted(), spellSlots: available),
          isNull,
          reason: '$grant',
        );
        expect(
          SpellCastBlockReason.of(spell: granted(), spellSlots: exhausted),
          SpellCastBlockReason.noSlotAvailable,
          reason: '$grant',
        );
      }
    });

    test('Occultiste : un emplacement de pacte (isPact) compte comme un '
        'emplacement classique', () {
      const pactAvailable = [
        CharacterSpellSlot(level: 2, total: 2, used: 1, isPact: true),
      ];
      const pactExhausted = [
        CharacterSpellSlot(level: 2, total: 2, used: 2, isPact: true),
      ];
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 1, status: 'préparé'),
          spellSlots: pactAvailable,
        ),
        isNull,
      );
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 1, status: 'préparé'),
          spellSlots: pactExhausted,
        ),
        SpellCastBlockReason.noSlotAvailable,
      );
      // Sort de niveau supérieur au niveau de l'emplacement de pacte.
      expect(
        SpellCastBlockReason.of(
          spell: _spell(level: 3, status: 'préparé'),
          spellSlots: pactAvailable,
        ),
        SpellCastBlockReason.noSlotAvailable,
      );
    });
  });

  group('SpellCastBlockReason.message', () {
    test('formulations affichées au joueur', () {
      expect(
        SpellCastBlockReason.unprepared.message,
        'Sort non préparé : préparez-le pour pouvoir le lancer.',
      );
      expect(
        SpellCastBlockReason.noSlotAvailable.message,
        "Plus d'emplacement de sort disponible pour ce niveau ou un niveau "
        'supérieur.',
      );
      expect(
        SpellCastBlockReason.innateUseSpent.message,
        'Déjà utilisé : disponible après un repos long.',
      );
    });
  });

  group('sort qui ne se prépare pas (classe à sorts connus)', () {
    const knownSpell = CharacterSpellEntry(
      id: 1,
      name: 'Test',
      level: 3,
      school: '',
      status: 'connu',
      requiresPreparation: false,
    );

    test("'connu' avec un emplacement disponible -> null (lançable)", () {
      expect(
        SpellCastBlockReason.of(spell: knownSpell, spellSlots: available),
        isNull,
      );
    });

    test("'connu', emplacements épuisés -> noSlotAvailable, jamais "
        'unprepared', () {
      expect(
        SpellCastBlockReason.of(spell: knownSpell, spellSlots: exhausted),
        SpellCastBlockReason.noSlotAvailable,
      );
      expect(
        SpellCastBlockReason.of(spell: knownSpell, spellSlots: const []),
        SpellCastBlockReason.noSlotAvailable,
      );
    });
  });
}
