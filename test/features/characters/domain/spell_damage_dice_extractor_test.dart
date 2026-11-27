import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spell_damage_dice_extractor.dart';

/// Sorts sans pastille de `docs/spec-pastille-degats-sorts.md` (30 noms plus
/// l'autre nom de « Fausse vie »), avec la pastille qu'ils affichaient avant
/// la correction (premier `NdM` de leur description de production).
const _noBadge = <String, String>{
  'Agrandissement/Rapetissement': '1d4',
  'Amélioration de caractéristique': '2d6',
  "Animation d'objets": '1d4',
  'Arrêt du temps': '1d4',
  'Aura de vitalité': '2d6',
  'Bond cinétique': '1d8',
  'Contact avec un autre plan': '6d6',
  "Contrôle de l'eau": '2d8',
  'Contrôle du climat': '1d4',
  'Couleurs dansantes': '6d10',
  'Espièglerie de Nathair': '1d4',
  'Esprit guérisseur': '1d6',
  'Fausse vie': '1d4',
  'Simulacre de vie': '1d4',
  'Festin des héros': '2d10',
  'Fusion dans la pierre': '6d6',
  "Modification d'apparence": '1d6',
  'Mot de guérison': '1d4',
  'Mot de guérison de groupe': '1d4',
  'Porte dimensionnelle': '4d6',
  'Prière de guérison': '2d8',
  'Quête': '5d10',
  'Régénération': '4d8',
  'Soins': '1d8',
  'Soins de groupe': '3d8',
  'Sommeil': '5d8',
  'Songe': '3d6',
  'Souhait': '1d10',
  'Téléportation': '1d10',
  "Toile d'araignée": '2d4',
  'Transfert de vie': '4d8',
};

/// Sorts dont la pastille est remplacée : (premier `NdM` du texte, dé
/// attendu).
const _replaced = <String, (String, ({int count, int sides}))>{
  'Main de Bigby': ('2d6', (count: 4, sides: 8)),
  'Tremblement de terre': ('1d6', (count: 5, sides: 6)),
};

/// Sorts qui reçoivent une pastille malgré un texte sans `NdM` (décision 88).
const _added = <String, ({int count, int sides})>{
  'Dragon illusoire': (count: 7, sides: 6),
  'Force fantasmagorique': (count: 1, sides: 6),
  "Fouet d'épines": (count: 1, sides: 6),
  'Fureur de la nature': (count: 4, sides: 6),
  'Gardien de la nature': (count: 1, sides: 6),
  'Murmures dissonants': (count: 3, sides: 6),
  'Trique noueuse': (count: 1, sides: 8),
};

void main() {
  group('SpellDamageDiceExtractor.extract, sort non listé : premier NdM de '
      'la description (comportement inchangé)', () {
    test('description avec un motif net', () {
      expect(
        SpellDamageDiceExtractor.extract(
          name: 'Boule de feu',
          description:
              'La cible doit subir 8d6 dégâts de feu lors d\'un échec.',
        ),
        (count: 8, sides: 6),
      );
    });

    test('description sans motif (sort utilitaire) -> null', () {
      expect(
        SpellDamageDiceExtractor.extract(
          name: 'Lumière',
          description: 'Vous créez une lumière vive dans un rayon de 6 mètres.',
        ),
        isNull,
      );
    });

    test('motif de mise à l\'échelle après le motif principal : ne retient '
        'que le premier', () {
      expect(
        SpellDamageDiceExtractor.extract(
          name: 'Projectile magique',
          description:
              'La cible subit 3d8 dégâts de force (+1d8/niv au-delà du '
              'niveau 5).',
        ),
        (count: 3, sides: 8),
      );
    });

    test('sort à deux dés de dégâts : le premier, inchangé', () {
      expect(
        SpellDamageDiceExtractor.extract(
          name: 'Colonne de flamme',
          description:
              'Chaque créature subit 4d6 dégâts de feu et 4d6 dégâts '
              'radiants.',
        ),
        (count: 4, sides: 6),
      );
    });

    test('description vide -> null', () {
      expect(
        SpellDamageDiceExtractor.extract(name: 'Sort inconnu', description: ''),
        isNull,
      );
    });

    test('comparaison exacte : un nom listé écrit avec une autre casse '
        'n\'est pas reconnu', () {
      expect(
        SpellDamageDiceExtractor.extract(
          name: 'soins',
          description: 'La cible récupère 1d8 points de vie.',
        ),
        (count: 1, sides: 8),
      );
      expect(
        SpellDamageDiceExtractor.extract(
          name: 'Main De Bigby',
          description: 'La main inflige 2d6 dégâts, ou 4d8 en poing serré.',
        ),
        (count: 2, sides: 6),
      );
    });
  });

  group('aucune pastille (30 sorts + « Simulacre de vie »)', () {
    test('la table couvre les 31 noms de la spec', () {
      expect(_noBadge, hasLength(31));
    });

    for (final MapEntry(key: name, value: formerBadge) in _noBadge.entries) {
      test('$name : plus de $formerBadge', () {
        final description = 'Texte de production qui mentionne $formerBadge.';
        // Sans l'exception, la description donnerait bien une pastille.
        expect(
          SpellDamageDiceExtractor.extract(
            name: 'Sort non listé',
            description: description,
          ),
          isNotNull,
        );
        expect(
          SpellDamageDiceExtractor.extract(
            name: name,
            description: description,
          ),
          isNull,
        );
      });
    }
  });

  group('remplacer', () {
    for (final MapEntry(key: name, value: (firstDice, expected))
        in _replaced.entries) {
      test('$name : $firstDice -> ${expected.count}d${expected.sides}', () {
        expect(
          SpellDamageDiceExtractor.extract(
            name: name,
            description:
                'Premier dé du texte : $firstDice, puis '
                '${expected.count}d${expected.sides}.',
          ),
          expected,
        );
      });
    }
  });

  group('ajouter (décision 88)', () {
    test('la table couvre les 7 noms de la spec', () {
      expect(_added, hasLength(7));
    });

    for (final MapEntry(key: name, value: expected) in _added.entries) {
      test('$name : ${expected.count}d${expected.sides} malgré un texte '
          'sans NdM', () {
        const description = 'Résumé sans motif de dé, ou un « d8 » seul.';
        expect(
          SpellDamageDiceExtractor.extract(
            name: 'Sort non listé',
            description: description,
          ),
          isNull,
        );
        expect(
          SpellDamageDiceExtractor.extract(
            name: name,
            description: description,
          ),
          expected,
        );
      });
    }
  });

  group('nom avec des espaces en trop (trim)', () {
    test('sans pastille', () {
      expect(
        SpellDamageDiceExtractor.extract(
          name: '  Soins \n',
          description: 'La cible récupère 1d8 points de vie.',
        ),
        isNull,
      );
    });

    test('remplacé', () {
      expect(
        SpellDamageDiceExtractor.extract(
          name: '\tMain de Bigby  ',
          description: 'La main inflige 2d6 dégâts, ou 4d8 en poing serré.',
        ),
        (count: 4, sides: 8),
      );
    });

    test('ajouté', () {
      expect(
        SpellDamageDiceExtractor.extract(
          name: ' Trique noueuse ',
          description: 'Le dé de dégâts du bâton devient un d8.',
        ),
        (count: 1, sides: 8),
      );
    });
  });
}
