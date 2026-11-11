// Géométrie pure du d20 animé (P2b) : icosaèdre, table d'orientation 1..20,
// projection. Aucun moteur de rendu.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/dice3d/d20_orientation.dart';
import 'package:personnages/features/characters/domain/dice3d/die_math.dart';
import 'package:personnages/features/characters/domain/dice3d/icosahedron.dart';

void main() {
  group('icosaèdre', () {
    test('12 sommets sur la sphère unité, 20 faces', () {
      expect(Icosahedron.vertices, hasLength(12));
      expect(Icosahedron.faces, hasLength(20));
      for (final v in Icosahedron.vertices) {
        expect(v.length, closeTo(1, 1e-12));
      }
    });

    test('chaque face est un triangle équilatéral aux arêtes communes', () {
      for (final f in Icosahedron.faces) {
        expect(f.toSet(), hasLength(3));
        for (var k = 0; k < 3; k++) {
          final a = Icosahedron.vertices[f[k]];
          final b = Icosahedron.vertices[f[(k + 1) % 3]];
          expect((a - b).length, closeTo(Icosahedron.edgeLength, 1e-9));
        }
      }
    });

    test(
      'chaque sommet appartient à 5 faces, 30 arêtes (Euler : 12-30+20)',
      () {
        final perVertex = List<int>.filled(12, 0);
        final edges = <String>{};
        for (final f in Icosahedron.faces) {
          for (var k = 0; k < 3; k++) {
            perVertex[f[k]]++;
            final a = f[k];
            final b = f[(k + 1) % 3];
            edges.add(a < b ? '$a-$b' : '$b-$a');
          }
        }
        expect(perVertex, everyElement(5));
        expect(edges, hasLength(30));
      },
    );

    test('normales sortantes unitaires, centre à 0,7947 du centre', () {
      for (var i = 0; i < 20; i++) {
        expect(Icosahedron.normals[i].length, closeTo(1, 1e-12));
        expect(
          Icosahedron.normals[i].dot(Icosahedron.centers[i]),
          greaterThan(0),
        );
        expect(
          Icosahedron.centers[i].length,
          closeTo(Icosahedron.inradiusRatio, 1e-12),
        );
      }
      expect(Icosahedron.inradiusRatio, closeTo(0.7947, 1e-4));
    });

    test('repère de chaque face orthonormé et main droite', () {
      for (var i = 0; i < 20; i++) {
        final r = Icosahedron.rights[i];
        final u = Icosahedron.ups[i];
        final n = Icosahedron.normals[i];
        expect(r.dot(u).abs(), lessThan(1e-9));
        expect(u.dot(n).abs(), lessThan(1e-9));
        expect(r.dot(n).abs(), lessThan(1e-9));
        expect(r.cross(u).dot(n), closeTo(1, 1e-9));
      }
    });

    test('numérotation : permutation de 1..20, faces opposées = 21', () {
      expect(Icosahedron.faceValues.toSet(), {for (var v = 1; v <= 20; v++) v});
      for (var i = 0; i < 20; i++) {
        final opposite = Icosahedron.faceValues.indexOf(
          21 - Icosahedron.faceValues[i],
        );
        expect(
          (Icosahedron.normals[i] + Icosahedron.normals[opposite]).length,
          closeTo(0, 1e-9),
        );
      }
    });
  });

  group('table d\'orientation 1..20', () {
    for (var value = 1; value <= 20; value++) {
      test('résultat $value : face de $value frontale à <= 15°, chiffre à '
          'l\'endroit', () {
        final q = D20Orientation.forValue(value);
        final face = Icosahedron.faceIndexOf(value);
        expect(Icosahedron.faceValues[face], value);
        expect(q.norm, closeTo(1, 1e-9));

        final normal = q.rotate(Icosahedron.normals[face]);
        expect(
          normal.angleTo(Vec3.unitZ),
          lessThanOrEqualTo(kOrientationToleranceRadians),
        );
        final up = q.rotate(Icosahedron.ups[face]);
        expect(
          up.angleTo(Vec3.unitY),
          lessThanOrEqualTo(kOrientationToleranceRadians),
        );
        // Le haut du chiffre pointe vers le haut de l'écran (Y positif).
        expect(up.y, greaterThan(0.9));
        // Et le chiffre n'est pas en miroir : droite -> vers la droite.
        final right = q.rotate(Icosahedron.rights[face]);
        expect(right.x, greaterThan(0.9));
      });
    }

    test('la face cible est la plus tournée vers la caméra de toutes', () {
      for (var value = 1; value <= 20; value++) {
        final q = D20Orientation.forValue(value);
        final face = Icosahedron.faceIndexOf(value);
        for (var f = 0; f < 20; f++) {
          if (f == face) continue;
          expect(
            q.rotate(Icosahedron.normals[f]).z,
            lessThan(q.rotate(Icosahedron.normals[face]).z),
          );
        }
      }
    });

    test('centre de la face cible : devant, légèrement au-dessus du centre '
        'à cause de l\'inclinaison', () {
      for (var value = 1; value <= 20; value++) {
        final c = D20Orientation.restCenter(value);
        expect(c.z, greaterThan(0.7));
        expect(c.x.abs(), lessThan(1e-9));
        expect(
          c.y,
          closeTo(
            -Icosahedron.inradiusRatio * math.sin(kRestTiltRadians),
            1e-9,
          ),
        );
      }
    });
  });

  group('quaternions', () {
    test('rotation d\'axe/angle et composition', () {
      final q = Quat.fromAxisAngle(Vec3.unitZ, math.pi / 2);
      final v = q.rotate(Vec3.unitX);
      expect(v.x, closeTo(0, 1e-12));
      expect(v.y, closeTo(1, 1e-12));
      final twice = (q * q).rotate(Vec3.unitX);
      expect(twice.x, closeTo(-1, 1e-12));
    });
  });

  group('projection', () {
    test('orthographique, Y vers le bas, déterministe', () {
      final p = projectOrtho(
        const Vec3(0.5, 0.25, 9),
        cx: 100,
        cy: 80,
        radiusPx: 40,
      );
      expect(p.x, 120);
      expect(p.y, 70);
      final again = projectOrtho(
        const Vec3(0.5, 0.25, 9),
        cx: 100,
        cy: 80,
        radiusPx: 40,
      );
      expect(again, p);
    });

    test('la face cible reste dans le disque du dé une fois projetée', () {
      for (var value = 1; value <= 20; value++) {
        final q = D20Orientation.forValue(value);
        for (final v in Icosahedron.vertices) {
          final p = projectOrtho(q.rotate(v), cx: 0, cy: 0, radiusPx: 1);
          expect(math.sqrt(p.x * p.x + p.y * p.y), lessThanOrEqualTo(1 + 1e-9));
        }
      }
    });
  });
}
