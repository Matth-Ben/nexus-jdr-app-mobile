import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spell_duration.dart';

SpellDuration _timed(int value, String unit) =>
    SpellDuration.fromColumns(kind: 'timed', value: value, unit: unit);

void main() {
  group('SpellDuration.fromColumns', () {
    test('lit les quatre kinds', () {
      expect(
        SpellDuration.fromColumns(kind: 'instant').kind,
        SpellDurationKind.instant,
      );
      expect(
        SpellDuration.fromColumns(kind: 'until_dispelled').kind,
        SpellDurationKind.untilDispelled,
      );
      expect(
        SpellDuration.fromColumns(kind: 'special').kind,
        SpellDurationKind.special,
      );
      final timed = _timed(10, 'minute');
      expect(timed.kind, SpellDurationKind.timed);
      expect(timed.value, 10);
      expect(timed.unit, SpellDurationUnit.minute);
      expect(timed.isTimed, isTrue);
    });

    test('colonnes absentes ou kind inconnu : durée inconnue, sans crash', () {
      expect(SpellDuration.fromColumns(), SpellDuration.unknown);
      expect(SpellDuration.fromColumns(kind: 'forever'), SpellDuration.unknown);
      expect(SpellDuration.fromColumns(kind: 42), SpellDuration.unknown);
      expect(SpellDuration.unknown.isTimed, isFalse);
      expect(SpellDuration.unknown.isTrackable, isFalse);
      expect(SpellDuration.unknown.gameDuration, isNull);
    });

    test('timed incohérent : retombe sur inconnu', () {
      expect(
        SpellDuration.fromColumns(kind: 'timed', unit: 'minute'),
        SpellDuration.unknown,
      );
      expect(
        SpellDuration.fromColumns(kind: 'timed', value: 3),
        SpellDuration.unknown,
      );
      expect(
        SpellDuration.fromColumns(kind: 'timed', value: 0, unit: 'round'),
        SpellDuration.unknown,
      );
      expect(
        SpellDuration.fromColumns(kind: 'timed', value: -2, unit: 'round'),
        SpellDuration.unknown,
      );
      expect(
        SpellDuration.fromColumns(kind: 'timed', value: 2, unit: 'decade'),
        SpellDuration.unknown,
      );
      expect(
        SpellDuration.fromColumns(kind: 'timed', value: '2', unit: 'hour'),
        SpellDuration.unknown,
      );
      expect(
        SpellDuration.fromColumns(kind: 'timed', value: 1.5, unit: 'hour'),
        SpellDuration.unknown,
      );
    });

    test('valeur numérique non entière typée (2.0) acceptée', () {
      expect(
        SpellDuration.fromColumns(
          kind: 'timed',
          value: 2.0,
          unit: 'hour',
        ).value,
        2,
      );
    });

    test('valeur/unité ignorées pour un kind non timed', () {
      final d = SpellDuration.fromColumns(
        kind: 'instant',
        value: 5,
        unit: 'round',
      );
      expect(d.value, isNull);
      expect(d.unit, isNull);
      expect(d.isTimed, isFalse);
    });

    test('concentration conservée, même sur une durée inconnue', () {
      expect(
        SpellDuration.fromColumns(concentration: true).isConcentration,
        isTrue,
      );
      expect(
        SpellDuration.fromColumns(
          kind: 'timed',
          value: 1,
          unit: 'minute',
          concentration: true,
        ).isConcentration,
        isTrue,
      );
      expect(SpellDuration.unknown.isConcentration, isFalse);
    });
  });

  group('SpellDuration.gameDuration', () {
    const expected = {
      'round': 6,
      'minute': 60,
      'hour': 3600,
      'day': 86400,
      'week': 604800,
      'year': 31536000,
    };
    for (final entry in expected.entries) {
      test('1 ${entry.key} = ${entry.value} s de jeu', () {
        final d = _timed(1, entry.key);
        expect(d.gameSeconds, entry.value);
        expect(d.gameDuration, Duration(seconds: entry.value));
      });
      test('3 ${entry.key} = ${3 * entry.value} s de jeu', () {
        expect(_timed(3, entry.key).gameSeconds, 3 * entry.value);
      });
    }

    test('non chiffrée : null', () {
      for (final kind in ['instant', 'until_dispelled', 'special']) {
        expect(SpellDuration.fromColumns(kind: kind).gameDuration, isNull);
        expect(SpellDuration.fromColumns(kind: kind).gameSeconds, isNull);
      }
    });
  });

  group('SpellDuration.isTrackable (<= 10 min de jeu inclus)', () {
    test('rounds : 100 inclus, 101 exclu', () {
      expect(_timed(1, 'round').isTrackable, isTrue);
      expect(_timed(100, 'round').isTrackable, isTrue);
      expect(_timed(101, 'round').isTrackable, isFalse);
    });

    test('minutes : 10 inclus, 11 exclu', () {
      expect(_timed(1, 'minute').isTrackable, isTrue);
      expect(_timed(10, 'minute').isTrackable, isTrue);
      expect(_timed(11, 'minute').isTrackable, isFalse);
    });

    test('heures, jours, semaines, années : jamais', () {
      for (final unit in ['hour', 'day', 'week', 'year']) {
        expect(_timed(1, unit).isTrackable, isFalse, reason: unit);
      }
    });

    test('instantanée, dissipation, spéciale, inconnue : jamais', () {
      for (final kind in ['instant', 'until_dispelled', 'special', null]) {
        expect(
          SpellDuration.fromColumns(kind: kind).isTrackable,
          isFalse,
          reason: '$kind',
        );
      }
    });
  });

  group('SpellDurationKind/Unit.fromValue', () {
    test('valeurs connues et inconnues', () {
      expect(SpellDurationKind.fromValue(null), SpellDurationKind.unknown);
      expect(SpellDurationKind.fromValue(''), SpellDurationKind.unknown);
      expect(SpellDurationKind.fromValue('timed'), SpellDurationKind.timed);
      expect(SpellDurationUnit.fromValue('week'), SpellDurationUnit.week);
      expect(SpellDurationUnit.fromValue(null), isNull);
    });
  });
}
