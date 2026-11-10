import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';

void main() {
  group('ConditionType', () {
    test('14 conditions, clés serveur anglaises uniques, sans épuisement', () {
      expect(ConditionType.values.length, 14);
      final keys = ConditionType.values.map((c) => c.storageKey).toList();
      expect(keys.toSet().length, 14);
      expect(keys, isNot(contains('exhaustion')));
    });

    test('fromStorageKey : aller-retour sur les 14 clés, null si inconnue', () {
      for (final type in ConditionType.values) {
        expect(ConditionType.fromStorageKey(type.storageKey), type);
      }
      expect(ConditionType.fromStorageKey('exhaustion'), isNull);
      expect(ConditionType.fromStorageKey('Blinded'), isNull);
    });

    group('parse tolérant', () {
      test('clé inconnue ignorée, jamais d exception', () {
        expect(ConditionType.parse(['prone', 'futur_etat', 'blinded']), [
          ConditionType.blinded,
          ConditionType.prone,
        ]);
      });

      test('null, non-liste, éléments non textuels : vide / ignorés', () {
        expect(ConditionType.parse(null), isEmpty);
        expect(ConditionType.parse('blinded'), isEmpty);
        expect(ConditionType.parse({'blinded': true}), isEmpty);
        expect(ConditionType.parse(42), isEmpty);
        expect(ConditionType.parse([1, null, true, 'stunned']), [
          ConditionType.stunned,
        ]);
      });

      test('doublons retirés, ordre canonique', () {
        expect(ConditionType.parse(['unconscious', 'blinded', 'blinded']), [
          ConditionType.blinded,
          ConditionType.unconscious,
        ]);
      });
    });

    test('unknownKeys : clés non reconnues, dédoublonnées ; toStorage les '
        'réinjecte sans doublon, la désélection reste effective', () {
      const raw = ['blinded', 'futur_a', 'futur_a', 'futur_b', 3];
      expect(ConditionType.unknownKeys(raw), ['futur_a', 'futur_b']);
      expect(ConditionType.unknownKeys(null), isEmpty);
      expect(
        ConditionType.toStorage(const [
          ConditionType.prone,
        ], unknownKeys: ConditionType.unknownKeys(raw)),
        ['prone', 'futur_a', 'futur_b'],
      );
      expect(
        ConditionType.toStorage(
          const [],
          unknownKeys: ['futur_a', 'blinded', 'futur_a'],
        ),
        ['futur_a'],
      );
    });

    test('toStorage : remplacement complet, canonique, sans doublon', () {
      expect(
        ConditionType.toStorage([
          ConditionType.stunned,
          ConditionType.blinded,
          ConditionType.stunned,
        ]),
        ['blinded', 'stunned'],
      );
      expect(ConditionType.toStorage(const []), isEmpty);
    });
  });
}
