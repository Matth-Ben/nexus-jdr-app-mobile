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

  group('libellés alignés sur le catalogue réel (garde-fou anti-dérive)', () {
    // Noms réels de la table `items` en production (armes, armures,
    // bouclier, équipement général).
    const catalogWeapons = {
      'Bâton de combat',
      'Dague',
      'Gourdin',
      'Hachette',
      'Javeline',
      'Épieu',
      'Marteau léger',
      "Masse d'armes",
      'Gourdin à deux mains',
      'Faucille',
      'Arbalète légère',
      'Arc court',
      'Dard',
      'Fronde',
      'Cimeterre',
      'Glaive',
      'Épée à deux mains',
      'Épée courte',
      'Épée longue',
      "Fléau d'armes",
      'Fouet',
      'Grande hache',
      "Hache d'armes",
      'Hallebarde',
      'Lance de cavalerie',
      'Maillet',
      'Marteau de guerre',
      'Morgenstern',
      'Pic de guerre',
      'Pique',
      'Rapière',
      'Trident',
      'Arbalète de poing',
      'Arbalète lourde',
      'Arc long',
      'Filet',
      'Sarbacane',
    };
    const catalogArmors = {
      'Armure rembourrée',
      'Armure de cuir',
      'Armure de cuir clouté',
      'Armure de peau',
      'Chemise de mailles',
      "Armure d'écailles",
      'Cuirasse',
      'Demi-plate',
      'Cotte à anneaux',
      'Cotte de mailles',
      'Harnois à lattes',
      'Armure complète',
    };
    const catalogEquipment = {
      'Sac à dos',
      'Corde en chanvre (15 mètres)',
      'Torche',
      'Silex et briquet',
      'Rations de voyage (1 jour)',
      'Outre',
      'Couverture',
      'Sac de couchage',
      'Grappin',
      'Lanterne à capote',
      'Lanterne sourde',
      "Flacon d'huile",
      'Bougie',
      'Parchemin (feuille)',
      'Papier (feuille)',
      "Flacon d'encre",
      'Plume',
      'Sacoche à composants',
      'Symbole sacré',
      'Focaliseur druidique',
      'Focaliseur arcanique',
      'Kit de soins',
      'Miroir en acier poli',
      'Gamelle',
      'Pied-de-biche',
      'Marteau',
      'Piton',
      'Cadenas',
      'Sac (grand)',
      'Sifflet',
      'Tente (deux personnes)',
      'Vêtements communs',
      'Vêtements de voyage',
      'Vêtements fins',
      'Costume de déguisement',
      'Bourse',
    };

    test('chaque arme de la table existe au catalogue (sauf emplacements '
        'vide/mains nues)', () {
      final labels = AideddReferenceTables.weapons.entries
          .where((e) => e.key > 1)
          .map((e) => e.value);
      expect(labels.toSet().difference(catalogWeapons), isEmpty);
      expect(AideddReferenceTables.weapons, hasLength(39));
    });

    test('chaque armure (hors "Sans armure") existe au catalogue', () {
      final labels = AideddReferenceTables.armor.entries
          .where((e) => e.key > 0)
          .map((e) => e.value);
      expect(labels.toSet().difference(catalogArmors), isEmpty);
      expect(AideddReferenceTables.shield[1], 'Bouclier');
    });

    test('les objets d\'équipement à équivalent exact existent au '
        'catalogue', () {
      const idsWithExactEquivalent = [
        6,
        9,
        17,
        19,
        23,
        38,
        40,
        42,
        44,
        45,
        49,
        60,
        61,
        65,
        66,
        70,
        71,
        76,
        80,
        81,
        82,
        85,
        89,
        90,
        91,
        92,
        94,
        95,
      ];
      final labels = {
        for (final id in idsWithExactEquivalent)
          AideddReferenceTables.items[id],
      };
      expect(labels.difference(catalogEquipment), isEmpty);
    });

    test('les ids aidedd des armes renommées restent inchangés', () {
      expect(AideddReferenceTables.weapons[2], 'Bâton de combat');
      expect(AideddReferenceTables.weapons[7], 'Épieu');
      expect(AideddReferenceTables.weapons[10], 'Gourdin à deux mains');
      expect(AideddReferenceTables.weapons[11], 'Faucille');
      expect(AideddReferenceTables.weapons[14], 'Dard');
      expect(AideddReferenceTables.weapons[17], 'Glaive');
      expect(AideddReferenceTables.weapons[23], 'Grande hache');
      expect(AideddReferenceTables.weapons[26], 'Lance de cavalerie');
    });
  });
}
