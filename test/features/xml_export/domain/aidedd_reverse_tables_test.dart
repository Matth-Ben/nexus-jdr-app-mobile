// Tests de l'inversion des tables aidedd.org
// (`lib/features/xml_export/domain/aidedd_reverse_tables.dart`) — vérifie
// que chaque valeur connue de `AideddReferenceTables` se retrouve dans le
// sens inverse, qu'une valeur inconnue retombe proprement sur `null` (jamais
// une exception), et l'absence d'ambiguïté (libellé dupliqué) dans les
// tables sources, condition qui rend le choix "premier trouvé gagne" de
// [AideddReverseTables] purement défensif à ce jour (voir sa documentation
// de classe).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/xml_import/domain/aidedd_reference_tables.dart';
import 'package:personnages/features/xml_export/domain/aidedd_reverse_tables.dart';

void _expectNoDuplicateLabels(String name, Map<int, String> table) {
  final seen = <String, int>{};
  for (final entry in table.entries) {
    final key = entry.value.trim().toLowerCase();
    final existingId = seen[key];
    expect(
      existingId,
      isNull,
      reason:
          'Table "$name" : libellé "${entry.value}" dupliqué entre les ids '
          '$existingId et ${entry.key} — rendrait `AideddReverseTables` '
          'ambiguë pour cette entrée.',
    );
    seen[key] = entry.key;
  }
}

void main() {
  group('aucune table source n\'a de libellé dupliqué', () {
    test(
      'skills/armor/shield/weapons/toolsEquipment/items/alignments/sexes',
      () {
        _expectNoDuplicateLabels('skills', AideddReferenceTables.skills);
        _expectNoDuplicateLabels('armor', AideddReferenceTables.armor);
        _expectNoDuplicateLabels('shield', AideddReferenceTables.shield);
        _expectNoDuplicateLabels('weapons', AideddReferenceTables.weapons);
        _expectNoDuplicateLabels(
          'toolsEquipment',
          AideddReferenceTables.toolsEquipment,
        );
        _expectNoDuplicateLabels('items', AideddReferenceTables.items);
        _expectNoDuplicateLabels(
          'alignments',
          AideddReferenceTables.alignments,
        );
        _expectNoDuplicateLabels('sexes', AideddReferenceTables.sexes);
      },
    );
  });

  test('skills : toutes les 18 entrées se retrouvent en sens inverse', () {
    for (final entry in AideddReferenceTables.skills.entries) {
      expect(
        AideddReverseTables.lookup(AideddReverseTables.skills, entry.value),
        entry.key,
      );
    }
  });

  test('weapons : correspondance exacte + insensible à la casse/accents', () {
    expect(
      AideddReverseTables.lookup(AideddReverseTables.weapons, 'Épée longue'),
      20,
    );
    expect(
      AideddReverseTables.lookup(AideddReverseTables.weapons, 'epee longue'),
      20,
    );
    expect(
      AideddReverseTables.lookup(AideddReverseTables.weapons, '  ÉPÉE LONGUE '),
      20,
    );
  });

  test('armor : "Sans armure" retrouve bien l\'id 0', () {
    expect(
      AideddReverseTables.lookup(AideddReverseTables.armor, 'Sans armure'),
      0,
    );
  });

  test('items : 99 entrées se retrouvent en sens inverse', () {
    expect(
      AideddReverseTables.lookup(AideddReverseTables.items, 'Sac à dos'),
      80,
    );
    expect(AideddReverseTables.lookup(AideddReverseTables.items, 'Torche'), 90);
  });

  test('alignments/sexes : correspondance exacte', () {
    expect(
      AideddReverseTables.lookup(
        AideddReverseTables.alignments,
        'Chaotique bon',
      ),
      6,
    );
    expect(AideddReverseTables.lookup(AideddReverseTables.sexes, 'Femme'), 1);
  });

  test('valeur inconnue -> null, jamais une exception', () {
    expect(
      AideddReverseTables.lookup(
        AideddReverseTables.weapons,
        'Épée vorpale +3',
      ),
      isNull,
    );
    expect(
      AideddReverseTables.lookup(AideddReverseTables.items, 'Objet inconnu'),
      isNull,
    );
  });

  test('label vide/null -> null, jamais une exception', () {
    expect(AideddReverseTables.lookup(AideddReverseTables.sexes, null), isNull);
    expect(AideddReverseTables.lookup(AideddReverseTables.sexes, ''), isNull);
    expect(
      AideddReverseTables.lookup(AideddReverseTables.sexes, '   '),
      isNull,
    );
  });
}
