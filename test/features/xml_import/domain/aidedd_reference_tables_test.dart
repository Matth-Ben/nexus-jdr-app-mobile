// Tests de non-régression sur la transcription des tables de correspondance
// aidedd.org (`lib/features/xml_import/domain/aidedd_reference_tables.dart`)
// contre `docs/xml-import-reference-mapping.md` — quelques valeurs pivots
// plutôt qu'une re-saisie complète des tables (déjà couvertes en pratique
// par les tests bout en bout sur les deux fixtures réelles, voir
// `xml_character_import_resolver_test.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/xml_import/domain/aidedd_reference_tables.dart';

void main() {
  test('skills : 18 entrées, ordre alphabétique français', () {
    expect(AideddReferenceTables.skills, hasLength(18));
    expect(AideddReferenceTables.skills[0], 'Acrobaties');
    expect(AideddReferenceTables.skills[12], 'Perception');
    expect(AideddReferenceTables.skills[17], 'Tromperie');
  });

  test('armor : 13 entrées, 0 = Sans armure', () {
    expect(AideddReferenceTables.armor, hasLength(13));
    expect(AideddReferenceTables.armor[0], 'Sans armure');
    expect(AideddReferenceTables.armor[10], 'Cotte de mailles');
    expect(AideddReferenceTables.armor[2], 'Armure de cuir');
  });

  test('shield : 2 entrées', () {
    expect(AideddReferenceTables.shield, {0: 'Sans bouclier', 1: 'Bouclier'});
  });

  test('weapons : 39 entrées (ids 0 à 38)', () {
    expect(AideddReferenceTables.weapons, hasLength(39));
    expect(AideddReferenceTables.weapons[20], 'Épée longue');
    expect(AideddReferenceTables.weapons[6], 'Javeline');
    expect(AideddReferenceTables.weapons[32], 'Rapière');
    expect(AideddReferenceTables.weapons[3], 'Dague');
  });

  test('toolsEquipment : ids 0 à 39, validés sur pip.xml (Luth + Flûte)', () {
    expect(AideddReferenceTables.toolsEquipment[12], 'Luth');
    expect(AideddReferenceTables.toolsEquipment[10], 'Flûte');
    expect(AideddReferenceTables.toolsEquipment[0], '(vide)');
  });

  test('items : 99 entrées (ids 1 à 99) + le repli `0` = vide', () {
    expect(AideddReferenceTables.items, hasLength(100));
    expect(AideddReferenceTables.items[1], 'Acide/fiole');
    expect(AideddReferenceTables.items[99], 'Bouteille');
    expect(AideddReferenceTables.items[80], 'Sac à dos');
  });

  test('packs : 26 entrées', () {
    expect(AideddReferenceTables.packs, hasLength(26));
    expect(AideddReferenceTables.packs[16], 'Pack (a) de paladin');
    expect(AideddReferenceTables.packs[2], 'Pack (a) de barde');
  });

  test('alignments : grille 3x3, validée sur les deux fixtures réelles', () {
    expect(AideddReferenceTables.alignments, hasLength(9));
    expect(AideddReferenceTables.alignments[0], 'Loyal bon');
    expect(AideddReferenceTables.alignments[6], 'Chaotique bon');
  });

  test('sexes : 3 entrées', () {
    expect(AideddReferenceTables.sexes, {
      0: 'Homme',
      1: 'Femme',
      2: 'Non binaire',
    });
  });
}
