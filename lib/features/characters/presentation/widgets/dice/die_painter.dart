import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/dice3d/die_math.dart';
import '../../../domain/dice3d/icosahedron.dart';
import 'die_flight.dart';
import 'die_flight_runner.dart';
import 'die_skin.dart';

/// Rayon du dé (sphère circonscrite) en fraction du plateau.
const double kDieRadiusFraction = 0.42;

/// Mise en valeur d'un résultat naturel (halo autour du dé).
enum DieNatural { none, twenty, one }

/// Niveau de rendu effectif du dé.
enum DieRenderLevel {
  /// Géométrie + couleurs de sommets + shader de texture.
  shader,

  /// Même géométrie, couleurs de sommets seules (shader indisponible ou
  /// skin sans texture).
  vertexColors,
}

/// Dessine le dé : un seul `CustomPainter`, `drawVertices` pour les faces
/// (ombrage plat par paliers calculé ici, texture par [ui.FragmentShader]
/// quand il est disponible), arêtes, chiffres décoratifs à 40 %, ombre, halo.
///
/// Tous les tampons (positions, couleurs, matrices, pastilles de chiffres)
/// sont alloués à la construction ; `paint` ne crée ni `Path`, ni `Paint`, ni
/// liste, ni `saveLayer`. Seuls subsistent de minuscules objets valeur
/// (`Color`, `Rect`, `Offset`) et la poignée `ui.Vertices` d'une image
/// (immuable par conception du moteur, détruite aussitôt dessinée).
///
/// Si `paint` lève, l'erreur est interceptée : le dessin s'arrête, [onFailure]
/// est appelé une fois et le widget parent bascule sur le rendu statique
/// (niveau 2) — aucune erreur n'est affichée.
class DieSurfacePainter extends CustomPainter {
  DieSurfacePainter({
    required this.progress,
    required this.runner,
    required this.value,
    required this.skin,
    this.shader,
    this.natural = DieNatural.none,
    this.struck = false,
    this.opacity = 1,
    this.onFailure,
    this.debugProbe,
  }) : _targetFace = Icosahedron.faceIndexOf(value),
       super(repaint: progress) {
    for (var step = 0; step < skin.shadeSteps; step++) {
      _stepColors[step] = skin.faceColorArgb(step, opacity: opacity);
    }
    final digitStyle = TextStyle(
      fontFamily: 'WorkSans',
      fontSize: _digitFontSize,
      fontWeight: FontWeight.w800,
      color: skin.numberColor.withValues(alpha: 0.4 * opacity),
    );
    for (var v = 1; v <= Icosahedron.faceCount; v++) {
      _digits[v - 1] = TextPainter(
        text: TextSpan(text: '$v', style: digitStyle),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    _facePaint
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    final tex = shader;
    if (tex != null) _facePaint.shader = tex;
    _edgePaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = skin.edgeWidth
      ..strokeCap = StrokeCap.round
      ..color = skin.edgeColor.withValues(alpha: opacity);
  }

  static const double _digitFontSize = 14;

  /// Valeur (0..1) du contrôleur linéaire : seule source de repeinte.
  final Animation<double> progress;

  /// Lecteur de la piste : position, orientation, échelle, squash, fondu.
  final DieFlightRunner runner;
  final int value;
  final DieSkin skin;

  /// Shader de texture déjà instancié (uniformes réglés) ou `null`.
  final ui.FragmentShader? shader;
  final DieNatural natural;

  /// Trait de rature du dé écarté (apparaît avec le fondu de fin).
  final bool struck;

  /// Opacité globale (0,55 pour le dé écarté).
  final double opacity;

  final void Function(Object error)? onFailure;

  /// Appelé au début de chaque dessin (tests : simuler une panne).
  final VoidCallback? debugProbe;

  DieRenderLevel get level =>
      shader == null ? DieRenderLevel.vertexColors : DieRenderLevel.shader;

  bool get failed => _failed;
  bool _failed = false;

  final int _targetFace;

  // Tampons réutilisés.
  final Float64List _rotated = Float64List(Icosahedron.vertexCount * 3);
  final Float32List _positions = Float32List(Icosahedron.faceCount * 6);
  final Int32List _colors = Int32List(Icosahedron.faceCount * 3);
  final Float32List _edges = Float32List(Icosahedron.faceCount * 12);
  final Float64List _matrix = Float64List(16)
    ..[10] = 1
    ..[15] = 1;
  final Int32List _stepColors = Int32List(5);
  final List<TextPainter?> _digits = List<TextPainter?>.filled(
    Icosahedron.faceCount,
    null,
  );
  final Paint _facePaint = Paint();
  final Paint _edgePaint = Paint();
  final Paint _haloPaint = Paint();
  final Paint _strikePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  // Lumière fixe (vers le haut-gauche, côté observateur).
  static final Vec3 _light = const Vec3(-0.35, 0.65, 0.68).normalized();

  /// Libère les ressources natives des chiffres.
  void dispose() {
    for (final digit in _digits) {
      digit?.dispose();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_failed) return;
    try {
      _paint(canvas, size);
    } on Object catch (error) {
      _failed = true;
      if (kDebugMode) debugPrint('DieSurfacePainter : rendu échoué ($error)');
      onFailure?.call(error);
    }
  }

  void _paint(Canvas canvas, Size size) {
    debugProbe?.call();
    runner.update(progress.value);
    final fade = runner.fade;

    // Le dé est dessiné au centre de sa boîte ; la couche déplace la boîte
    // (position, hauteur) et l'ombre est un widget à part.
    final side = math.min(size.width, size.height);
    final baseRadius = kDieRadiusFraction / DiceFlightLayout.boxFactor * side;
    final radius = baseRadius * runner.scale;
    final cx =
        size.width / 2 + (natural == DieNatural.one ? runner.shakeDp : 0);
    final cy = size.height / 2;

    _paintHalo(canvas, size, baseRadius, fade);
    _rotateVertices();
    final squashed = runner.squashX != 1 || runner.squashY != 1;
    if (squashed) {
      // Squash d'impact autour du centre du dé (pas de saveLayer).
      canvas
        ..save()
        ..translate(cx, cy)
        ..scale(runner.squashX, runner.squashY)
        ..translate(-cx, -cy);
    }
    final visible = _fillFaces(cx, cy, radius);
    if (visible > 0) {
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(_positions, 0, visible * 6),
        colors: Int32List.sublistView(_colors, 0, visible * 3),
      );
      canvas.drawVertices(
        vertices,
        shader == null ? BlendMode.srcOver : BlendMode.modulate,
        _facePaint,
      );
      vertices.dispose();
    }
    _paintDigits(canvas, cx, cy, radius, hideTarget: fade > 0);
    if (visible > 0) {
      canvas.drawRawPoints(
        ui.PointMode.lines,
        Float32List.sublistView(_edges, 0, visible * 12),
        _edgePaint,
      );
    }
    if (squashed) canvas.restore();
    if (struck && fade > 0) {
      // Trait parchemin de 3 dp cerné de bois foncé (1 dp de chaque côté).
      final from = Offset(size.width * 0.25, size.height * 0.75);
      final to = Offset(size.width * 0.75, size.height * 0.25);
      _strikePaint
        ..strokeWidth = 5
        ..color = AppColors.woodDark.withValues(alpha: fade);
      canvas.drawLine(from, to, _strikePaint);
      _strikePaint
        ..strokeWidth = 3
        ..color = AppColors.parchmentCard.withValues(alpha: fade);
      canvas.drawLine(from, to, _strikePaint);
    }
  }

  void _paintHalo(Canvas canvas, Size size, double baseRadius, double fade) {
    if (natural == DieNatural.none || fade <= 0) return;
    final isGold = natural == DieNatural.twenty;
    final peak = isGold ? 0.35 : 0.25;
    // Trois cercles (aplats) qui, superposés, totalisent `peak`.
    final each = 1 - math.pow(1 - peak, 1 / 3);
    _haloPaint.color = (isGold ? AppColors.goldStart : AppColors.accentBrick)
        .withValues(alpha: each * fade);
    final center = Offset(size.width / 2, size.height / 2);
    canvas
      ..drawCircle(center, baseRadius * 1.1, _haloPaint)
      ..drawCircle(center, baseRadius * 1.25, _haloPaint)
      ..drawCircle(center, baseRadius * 1.4, _haloPaint);
  }

  void _rotateVertices() {
    final w = runner.qw, x = runner.qx, y = runner.qy, z = runner.qz;
    final r00 = 1 - 2 * (y * y + z * z);
    final r01 = 2 * (x * y - z * w);
    final r02 = 2 * (x * z + y * w);
    final r10 = 2 * (x * y + z * w);
    final r11 = 1 - 2 * (x * x + z * z);
    final r12 = 2 * (y * z - x * w);
    final r20 = 2 * (x * z - y * w);
    final r21 = 2 * (y * z + x * w);
    final r22 = 1 - 2 * (x * x + y * y);
    _rot
      ..[0] = r00
      ..[1] = r01
      ..[2] = r02
      ..[3] = r10
      ..[4] = r11
      ..[5] = r12
      ..[6] = r20
      ..[7] = r21
      ..[8] = r22;
    final vs = Icosahedron.vertices;
    for (var i = 0; i < vs.length; i++) {
      final v = vs[i];
      _rotated[i * 3] = r00 * v.x + r01 * v.y + r02 * v.z;
      _rotated[i * 3 + 1] = r10 * v.x + r11 * v.y + r12 * v.z;
      _rotated[i * 3 + 2] = r20 * v.x + r21 * v.y + r22 * v.z;
    }
  }

  final Float64List _rot = Float64List(9);

  /// Remplit positions/couleurs/arêtes des faces tournées vers l'observateur ;
  /// renvoie leur nombre.
  int _fillFaces(double cx, double cy, double radius) {
    var count = 0;
    final steps = skin.shadeSteps;
    for (var f = 0; f < Icosahedron.faceCount; f++) {
      final n = Icosahedron.normals[f];
      final nx = _rot[0] * n.x + _rot[1] * n.y + _rot[2] * n.z;
      final ny = _rot[3] * n.x + _rot[4] * n.y + _rot[5] * n.z;
      final nz = _rot[6] * n.x + _rot[7] * n.y + _rot[8] * n.z;
      if (nz <= 0.001) continue;
      final lambert = nx * _light.x + ny * _light.y + nz * _light.z;
      final tone = ((lambert + 0.25) / 1.25).clamp(0.0, 0.9999);
      final color = _stepColors[(tone * steps).floor()];
      final face = Icosahedron.faces[f];
      for (var k = 0; k < 3; k++) {
        final vi = face[k] * 3;
        final px = cx + _rotated[vi] * radius;
        final py = cy - _rotated[vi + 1] * radius;
        _positions[count * 6 + k * 2] = px;
        _positions[count * 6 + k * 2 + 1] = py;
        _colors[count * 3 + k] = color;
        // Arête k -> k+1.
        final nk = face[(k + 1) % 3] * 3;
        _edges[count * 12 + k * 4] = px;
        _edges[count * 12 + k * 4 + 1] = py;
        _edges[count * 12 + k * 4 + 2] = cx + _rotated[nk] * radius;
        _edges[count * 12 + k * 4 + 3] = cy - _rotated[nk + 1] * radius;
      }
      count++;
    }
    return count;
  }

  void _paintDigits(
    Canvas canvas,
    double cx,
    double cy,
    double radius, {
    required bool hideTarget,
  }) {
    for (var f = 0; f < Icosahedron.faceCount; f++) {
      if (hideTarget && f == _targetFace) continue;
      final n = Icosahedron.normals[f];
      final nz = _rot[6] * n.x + _rot[7] * n.y + _rot[8] * n.z;
      // Faces trop obliques : chiffres illisibles, on les omet.
      if (nz < 0.3) continue;
      final c = Icosahedron.centers[f];
      final u = Icosahedron.ups[f];
      final r = Icosahedron.rights[f];
      final rx = _rot[0] * r.x + _rot[1] * r.y + _rot[2] * r.z;
      final ry = _rot[3] * r.x + _rot[4] * r.y + _rot[5] * r.z;
      final ux = _rot[0] * u.x + _rot[1] * u.y + _rot[2] * u.z;
      final uy = _rot[3] * u.x + _rot[4] * u.y + _rot[5] * u.z;
      final cxm = _rot[0] * c.x + _rot[1] * c.y + _rot[2] * c.z;
      final cym = _rot[3] * c.x + _rot[4] * c.y + _rot[5] * c.z;
      // Repère local du chiffre : x vers la droite de la face, y vers le bas
      // (le « haut » du chiffre est l'axe `up` du modèle), 1 unité = 1 px.
      _matrix[0] = rx;
      _matrix[1] = -ry;
      _matrix[4] = -ux;
      _matrix[5] = uy;
      _matrix[12] = cx + cxm * radius;
      _matrix[13] = cy - cym * radius;
      final digit = _digits[Icosahedron.faceValues[f] - 1]!;
      canvas
        ..save()
        ..transform(_matrix);
      digit.paint(canvas, Offset(-digit.width / 2, -digit.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(DieSurfacePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.value != value ||
      oldDelegate.skin != skin ||
      oldDelegate.shader != shader ||
      oldDelegate.natural != natural ||
      oldDelegate.struck != struck ||
      oldDelegate.opacity != opacity ||
      oldDelegate.runner != runner;
}
