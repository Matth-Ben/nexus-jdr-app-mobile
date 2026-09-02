import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/inventory_rarity_formatter.dart';

void main() {
  group('InventoryRarityFormatter.format', () {
    test('mappe les 6 valeurs connues vers leur libellé FR', () {
      expect(InventoryRarityFormatter.format('commune'), 'Commune');
      expect(InventoryRarityFormatter.format('peu_commune'), 'Peu commune');
      expect(InventoryRarityFormatter.format('rare'), 'Rare');
      expect(InventoryRarityFormatter.format('tres_rare'), 'Très rare');
      expect(InventoryRarityFormatter.format('legendaire'), 'Légendaire');
      expect(InventoryRarityFormatter.format('artefact'), 'Artefact');
    });

    test('une valeur inconnue retombe sur elle-même capitalisée, jamais un '
        'libellé générique (ne masque jamais une vraie donnée non encore '
        'couverte)', () {
      expect(InventoryRarityFormatter.format('exotique'), 'Exotique');
    });

    test('une chaîne vide reste vide', () {
      expect(InventoryRarityFormatter.format(''), '');
    });
  });
}
