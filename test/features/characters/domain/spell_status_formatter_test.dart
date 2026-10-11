// Tests unitaires de `domain/spell_status_formatter.dart` — voir
// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section "Onglet
// Sorts" : "Distinction claire entre sorts connus et sorts préparés".

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/domain/spell_status_formatter.dart';

CharacterSpellEntry _spell({required int level, required SpellStatus status}) {
  return CharacterSpellEntry(
    id: 1,
    name: 'Test',
    level: level,
    school: '',
    status: status,
  );
}

void main() {
  group('SpellStatusFormatter.subtitle', () {
    test('sort mineur (niveau 0) -> jamais de sous-titre', () {
      expect(
        SpellStatusFormatter.subtitle(
          _spell(level: 0, status: SpellStatus.known),
        ),
        isNull,
      );
      expect(
        SpellStatusFormatter.subtitle(
          _spell(level: 0, status: SpellStatus.innate),
        ),
        isNull,
      );
    });

    test("sort niveau >= 1 'connu' -> \"connu, non préparé\"", () {
      expect(
        SpellStatusFormatter.subtitle(
          _spell(level: 1, status: SpellStatus.known),
        ),
        'connu, non préparé',
      );
    });

    test("sort niveau >= 1 'préparé' -> \"préparé\"", () {
      expect(
        SpellStatusFormatter.subtitle(
          _spell(level: 3, status: SpellStatus.prepared),
        ),
        'préparé',
      );
    });

    test(
      "sort niveau >= 1 'inné' (toujours disponible) -> aucun sous-titre",
      () {
        expect(
          SpellStatusFormatter.subtitle(
            _spell(level: 2, status: SpellStatus.innate),
          ),
          isNull,
        );
      },
    );
  });

  group('SpellStatusFormatter.canCast', () {
    test('sort mineur -> toujours lançable, quel que soit le statut', () {
      expect(
        SpellStatusFormatter.canCast(
          _spell(level: 0, status: SpellStatus.known),
        ),
        isTrue,
      );
      expect(
        SpellStatusFormatter.canCast(
          _spell(level: 0, status: SpellStatus.prepared),
        ),
        isTrue,
      );
    });

    test("sort niveau >= 1 'connu' (non préparé) -> pas lançable", () {
      expect(
        SpellStatusFormatter.canCast(
          _spell(level: 1, status: SpellStatus.known),
        ),
        isFalse,
      );
    });

    test("sort niveau >= 1 'préparé' -> lançable", () {
      expect(
        SpellStatusFormatter.canCast(
          _spell(level: 1, status: SpellStatus.prepared),
        ),
        isTrue,
      );
    });

    test("sort niveau >= 1 'inné' -> toujours lançable", () {
      expect(
        SpellStatusFormatter.canCast(
          _spell(level: 5, status: SpellStatus.innate),
        ),
        isTrue,
      );
    });
  });

  group('SpellStatusFormatter.canTogglePrepared', () {
    test('sort mineur -> jamais de bascule de préparation', () {
      expect(
        SpellStatusFormatter.canTogglePrepared(
          _spell(level: 0, status: SpellStatus.known),
        ),
        isFalse,
      );
    });

    test("sort inné -> jamais de bascule de préparation", () {
      expect(
        SpellStatusFormatter.canTogglePrepared(
          _spell(level: 2, status: SpellStatus.innate),
        ),
        isFalse,
      );
    });

    test("sort 'connu' niveau >= 1 -> bascule possible", () {
      expect(
        SpellStatusFormatter.canTogglePrepared(
          _spell(level: 1, status: SpellStatus.known),
        ),
        isTrue,
      );
    });

    test("sort 'préparé' niveau >= 1 -> bascule possible", () {
      expect(
        SpellStatusFormatter.canTogglePrepared(
          _spell(level: 1, status: SpellStatus.prepared),
        ),
        isTrue,
      );
    });
  });

  group('SpellStatusFormatter.isUnprepared / preparationLabel', () {
    test('sort mineur -> jamais "non préparé", aucun libellé', () {
      final spell = _spell(level: 0, status: SpellStatus.known);
      expect(SpellStatusFormatter.isUnprepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), isNull);
    });

    test('sort inné -> jamais "non préparé", aucun libellé', () {
      final spell = _spell(level: 3, status: SpellStatus.innate);
      expect(SpellStatusFormatter.isUnprepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), isNull);
    });

    test('sort accordé par une sous-classe -> aucun libellé (porte déjà sa '
        'pastille)', () {
      const spell = CharacterSpellEntry(
        id: 1,
        name: 'Bénédiction',
        level: 1,
        school: '',
        status: SpellStatus.prepared,
        grantSource: SpellGrantSource.domain,
        isPersisted: false,
      );
      expect(SpellStatusFormatter.isUnprepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), isNull);
    });

    test("sort niveau >= 1 'préparé' -> libellé \"préparé\"", () {
      final spell = _spell(level: 1, status: SpellStatus.prepared);
      expect(SpellStatusFormatter.isUnprepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), 'préparé');
    });

    test("sort niveau >= 1 'connu' -> non préparé", () {
      final spell = _spell(level: 1, status: SpellStatus.known);
      expect(SpellStatusFormatter.isUnprepared(spell), isTrue);
      expect(SpellStatusFormatter.preparationLabel(spell), 'non préparé');
    });
  });

  // Barde, Ensorceleur, Occultiste, Rôdeur : leurs sorts ne se préparent pas
  // (`CharacterSpellEntry.requiresPreparation` faux, dérivé à la lecture).
  group('sort qui ne se prépare pas (classe à sorts connus)', () {
    CharacterSpellEntry known({
      required SpellStatus status,
      int level = 1,
      SpellGrantSource? grant,
    }) => CharacterSpellEntry(
      id: 1,
      name: 'Test',
      level: level,
      school: '',
      status: status,
      grantSource: grant,
      requiresPreparation: false,
    );

    test("'connu' niveau >= 1 : lançable, sans bascule, libellé ni "
        'sous-titre', () {
      final spell = known(status: SpellStatus.known, level: 3);
      expect(SpellStatusFormatter.canCast(spell), isTrue);
      expect(SpellStatusFormatter.canTogglePrepared(spell), isFalse);
      expect(SpellStatusFormatter.isUnprepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), isNull);
      expect(SpellStatusFormatter.subtitle(spell), isNull);
    });

    test("déjà passé à 'préparé' en base : lançable, ni \"préparé\" ni "
        'bascule', () {
      final spell = known(status: SpellStatus.prepared);
      expect(SpellStatusFormatter.canCast(spell), isTrue);
      expect(SpellStatusFormatter.canTogglePrepared(spell), isFalse);
      expect(SpellStatusFormatter.isUnprepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), isNull);
      expect(SpellStatusFormatter.subtitle(spell), isNull);
    });

    test('sort mineur : inchangé', () {
      final spell = known(status: SpellStatus.known, level: 0);
      expect(SpellStatusFormatter.canCast(spell), isTrue);
      expect(SpellStatusFormatter.canTogglePrepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), isNull);
      expect(SpellStatusFormatter.subtitle(spell), isNull);
    });

    test('sort inné : inchangé', () {
      final spell = known(status: SpellStatus.innate, level: 2);
      expect(SpellStatusFormatter.canCast(spell), isTrue);
      expect(SpellStatusFormatter.canTogglePrepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), isNull);
      expect(SpellStatusFormatter.subtitle(spell), isNull);
    });

    test('sort accordé par une sous-classe : inchangé (sous-titre "toujours '
        'préparé" conservé)', () {
      final spell = known(
        status: SpellStatus.prepared,
        grant: SpellGrantSource.domain,
      );
      expect(SpellStatusFormatter.canCast(spell), isTrue);
      expect(SpellStatusFormatter.canTogglePrepared(spell), isFalse);
      expect(SpellStatusFormatter.preparationLabel(spell), isNull);
      expect(
        SpellStatusFormatter.subtitle(spell),
        'toujours préparé · ${SpellGrantSource.domain.label}',
      );
    });

    test('requiresPreparation vaut true par défaut (règle historique)', () {
      expect(
        _spell(level: 1, status: SpellStatus.known).requiresPreparation,
        isTrue,
      );
    });
  });
}
