/// Icosaèdre régulier (d20) du dé animé : 12 sommets, 20 faces, repère de
/// chaque face (centre, normale, « haut » du chiffre) et numérotation.
library;

import 'dart:math' as math;

import 'die_math.dart';

/// Géométrie de l'icosaèdre, calculée une fois (champs statiques). Rayon
/// circonscrit normalisé à 1.
abstract final class Icosahedron {
  static const int vertexCount = 12;
  static const int faceCount = 20;

  static final double _phi = (1 + math.sqrt(5)) / 2;

  /// 12 sommets : permutations circulaires de (0, ±1, ±φ), normalisés.
  static final List<Vec3> vertices = () {
    final raw = <Vec3>[];
    for (final a in const [-1.0, 1.0]) {
      for (final b in [-_phi, _phi]) {
        raw
          ..add(Vec3(0, a, b))
          ..add(Vec3(a, b, 0))
          ..add(Vec3(b, 0, a));
      }
    }
    return List<Vec3>.unmodifiable([for (final v in raw) v.normalized()]);
  }();

  /// Longueur d'une arête (distance minimale entre deux sommets).
  static final double edgeLength = () {
    var best = double.infinity;
    for (var i = 0; i < vertices.length; i++) {
      for (var j = i + 1; j < vertices.length; j++) {
        best = math.min(best, (vertices[i] - vertices[j]).length);
      }
    }
    return best;
  }();

  static bool _isEdge(int i, int j) =>
      ((vertices[i] - vertices[j]).length - edgeLength).abs() < 1e-6;

  /// 20 faces : triplets de sommets deux à deux voisins, ordonnés de façon
  /// déterministe et orientés pour que la normale pointe vers l'extérieur.
  static final List<List<int>> faces = () {
    final result = <List<int>>[];
    for (var a = 0; a < vertexCount; a++) {
      for (var b = a + 1; b < vertexCount; b++) {
        if (!_isEdge(a, b)) continue;
        for (var c = b + 1; c < vertexCount; c++) {
          if (!_isEdge(a, c) || !_isEdge(b, c)) continue;
          final va = vertices[a];
          final n = (vertices[b] - va).cross(vertices[c] - va);
          final centroid = (va + vertices[b] + vertices[c]).scaled(1 / 3);
          result.add(n.dot(centroid) > 0 ? [a, b, c] : [a, c, b]);
        }
      }
    }
    return List<List<int>>.unmodifiable([
      for (final f in result) List<int>.unmodifiable(f),
    ]);
  }();

  /// Centre (barycentre) de chaque face.
  static final List<Vec3> centers = List<Vec3>.unmodifiable([
    for (final f in faces)
      (vertices[f[0]] + vertices[f[1]] + vertices[f[2]]).scaled(1 / 3),
  ]);

  /// Rapport rayon inscrit / rayon circonscrit (≈ 0,7947) : distance du
  /// centre d'une face à l'origine.
  static final double inradiusRatio = centers.first.length;

  /// Normale unitaire sortante de chaque face.
  static final List<Vec3> normals = List<Vec3>.unmodifiable([
    for (final c in centers) c.normalized(),
  ]);

  /// « Haut » du chiffre de chaque face : du centre vers le premier sommet de
  /// la face (dans le plan de la face, unitaire).
  static final List<Vec3> ups = List<Vec3>.unmodifiable([
    for (var i = 0; i < centers.length; i++)
      (vertices[faces[i][0]] - centers[i]).normalized(),
  ]);

  /// « Droite » du chiffre : `up × normale` (repère main droite, comme
  /// Y × Z = X).
  static final List<Vec3> rights = List<Vec3>.unmodifiable([
    for (var i = 0; i < centers.length; i++)
      ups[i].cross(normals[i]).normalized(),
  ]);

  /// Valeur (1..20) portée par chaque face. Convention d'un d20 : deux faces
  /// opposées totalisent 21. Affectation cosmétique (l'ordre des chiffres
  /// autour d'un sommet n'imite pas un dé réel) : seul le tirage fait foi,
  /// jamais la numérotation du modèle.
  static final List<int> faceValues = () {
    final values = List<int>.filled(faceCount, 0);
    var next = 1;
    for (var i = 0; i < faceCount; i++) {
      if (values[i] != 0) continue;
      values[i] = next;
      values[_oppositeOf(i)] = 21 - next;
      next++;
    }
    return List<int>.unmodifiable(values);
  }();

  static int _oppositeOf(int face) {
    for (var j = 0; j < faceCount; j++) {
      if (j != face && (normals[j] + normals[face]).length < 1e-9) return j;
    }
    throw StateError('Face opposée introuvable pour $face');
  }

  /// Indice de la face portant [value] (1..20).
  static int faceIndexOf(int value) {
    assert(value >= 1 && value <= faceCount, 'valeur hors 1..20 : $value');
    return faceValues.indexOf(value);
  }
}
