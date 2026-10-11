// Tests unitaires de `core/rules/spell_status.dart` — remplace les chaînes
// brutes 'connu'/'préparé'/'inné' (dette D04, `docs/dette-technique.md`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';

void main() {
  group('SpellStatus.value', () {
    test('valeurs stockées côté Supabase', () {
      expect(SpellStatus.known.value, 'connu');
      expect(SpellStatus.prepared.value, 'préparé');
      expect(SpellStatus.innate.value, 'inné');
    });
  });

  group('SpellStatus.fromValue', () {
    test('résout chacune des 3 valeurs valides', () {
      expect(SpellStatus.fromValue('connu'), SpellStatus.known);
      expect(SpellStatus.fromValue('préparé'), SpellStatus.prepared);
      expect(SpellStatus.fromValue('inné'), SpellStatus.innate);
    });

    test('valeur null, vide ou inattendue -> SpellStatus.known par défaut', () {
      expect(SpellStatus.fromValue(null), SpellStatus.known);
      expect(SpellStatus.fromValue(''), SpellStatus.known);
      expect(SpellStatus.fromValue('autre'), SpellStatus.known);
    });

    test('repli explicite personnalisé', () {
      expect(
        SpellStatus.fromValue('autre', fallback: SpellStatus.innate),
        SpellStatus.innate,
      );
      // Une valeur valide ignore toujours le repli.
      expect(
        SpellStatus.fromValue('préparé', fallback: SpellStatus.innate),
        SpellStatus.prepared,
      );
    });

    test('aller-retour value -> fromValue -> même statut, pour les 3 '
        'valeurs', () {
      for (final status in SpellStatus.values) {
        expect(SpellStatus.fromValue(status.value), status);
      }
    });
  });
}
