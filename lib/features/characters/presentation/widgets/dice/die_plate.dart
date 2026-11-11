import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/dice3d/d20_orientation.dart';
import 'die_motion.dart';
import 'die_painter.dart';
import 'die_shader_cache.dart';
import 'die_skin.dart';

/// Progression (0..1) d'un plateau, dérivée du contrôleur unique de la
/// feuille : le plateau d'indice i démarre [DieTimeline.staggerMs] × i après
/// le premier.
class PlateProgress extends Animation<double>
    with AnimationWithParentMixin<double> {
  PlateProgress(this.parent, this.index, this.count);

  @override
  final Animation<double> parent;
  final int index;
  final int count;

  @override
  double get value => DieTimeline.plateProgress(parent.value, index, count);
}

/// Courbe du fondu de résultat (derniers 200 ms) d'un plateau.
class ResultFadeCurve extends Curve {
  const ResultFadeCurve();

  @override
  double transformInternal(double t) => DieTimeline.resultFade(t);
}

/// Un plateau de dé : cadre parchemin (bordure selon le résultat naturel),
/// dé 3D dessiné par [DieSurfacePainter] dans un `RepaintBoundary`, pastille
/// du chiffre (vrai `Text`, net et à l'endroit) qui apparaît à la pose.
///
/// Entièrement décoratif ([ExcludeSemantics]) : le résultat est dit par le
/// texte de la feuille. Si le painter lève une erreur, le plateau bascule sur
/// [fallbackBuilder] (dé statique), sans rien afficher d'autre.
class DiePlate extends StatefulWidget {
  const DiePlate({
    required this.value,
    required this.size,
    required this.skin,
    required this.progress,
    required this.fallbackBuilder,
    this.natural = DieNatural.none,
    this.dimmed = false,
    this.onTap,
    this.shaderCache,
    this.debugPaintProbe,
    super.key,
  });

  final int value;

  /// Côté du plateau, bordure comprise (160, ou 120 en avantage).
  final double size;
  final DieSkin skin;
  final Animation<double> progress;
  final Widget Function(BuildContext context) fallbackBuilder;
  final DieNatural natural;

  /// Dé écarté : 55 %, barré.
  final bool dimmed;

  /// Tap sur le plateau (saut à l'état posé pendant le lancer).
  final VoidCallback? onTap;

  @visibleForTesting
  final DieShaderCache? shaderCache;

  @visibleForTesting
  final VoidCallback? debugPaintProbe;

  @override
  State<DiePlate> createState() => _DiePlateState();
}

class _DiePlateState extends State<DiePlate> {
  late DieSkin _skin = widget.skin.ensureReadable();
  late DieSurfacePainter _painter;
  ui.FragmentShader? _shader;
  late Animation<double> _fade;
  bool _fallback = false;
  bool _revealed = false;

  DieShaderCache get _cache => widget.shaderCache ?? DieShaderCache.shared;

  @override
  void initState() {
    super.initState();
    _bindProgress();
    _ensureShader();
    _painter = _buildPainter();
  }

  @override
  void didUpdateWidget(DiePlate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      oldWidget.progress.removeListener(_onProgress);
      _bindProgress();
    }
    if (oldWidget.skin != widget.skin ||
        oldWidget.value != widget.value ||
        oldWidget.natural != widget.natural ||
        oldWidget.dimmed != widget.dimmed) {
      _skin = widget.skin.ensureReadable();
      _ensureShader(force: oldWidget.skin != widget.skin);
      _rebuildPainter();
    }
  }

  void _bindProgress() {
    _fade = widget.progress.drive(CurveTween(curve: const ResultFadeCurve()));
    widget.progress.addListener(_onProgress);
    _revealed = _fade.value > 0;
  }

  /// Ne reconstruit le plateau qu'une fois, quand le résultat est révélé
  /// (bordure) : l'animation du dé elle-même ne passe que par le painter.
  void _onProgress() {
    final revealed = _fade.value > 0;
    if (revealed != _revealed && mounted) {
      setState(() => _revealed = revealed);
    }
  }

  void _ensureShader({bool force = false}) {
    if (force) _disposeShader();
    if (_skin.textureId == DieTextureId.none) {
      _disposeShader();
      return;
    }
    final id = _skin.shaderId;
    final program = _cache.programFor(id);
    if (program != null) {
      _shader ??= program.fragmentShader()
        ..setFloat(0, _skin.textureId.index.toDouble())
        ..setFloat(1, _skin.textureOpacity);
    } else if (!_cache.hasFailed(id)) {
      _cache.preload(id).then((_) {
        if (!mounted) return;
        setState(() {
          _ensureShader();
          _rebuildPainter();
        });
      });
    }
  }

  void _disposeShader() {
    _shader?.dispose();
    _shader = null;
  }

  DieSurfacePainter _buildPainter() => DieSurfacePainter(
    progress: widget.progress,
    value: widget.value,
    skin: _skin,
    shader: _shader,
    natural: widget.natural,
    struck: widget.dimmed,
    opacity: widget.dimmed ? 0.55 : 1,
    onFailure: _onPaintFailure,
    debugProbe: widget.debugPaintProbe,
  );

  void _rebuildPainter() {
    _painter.dispose();
    _painter = _buildPainter();
  }

  /// Appelé depuis la phase de dessin : le basculement en niveau 2 attend la
  /// fin de l'image.
  void _onPaintFailure(Object error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_fallback) setState(() => _fallback = true);
    });
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgress);
    _painter.dispose();
    _disposeShader();
    super.dispose();
  }

  Color get _borderColor {
    if (!_revealed || widget.dimmed) return AppColors.woodLight;
    return switch (widget.natural) {
      DieNatural.twenty => AppColors.goldEnd,
      DieNatural.one => AppColors.accentBrick,
      DieNatural.none => AppColors.woodLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_fallback) {
      content = Center(child: widget.fallbackBuilder(context));
    } else {
      final center = D20Orientation.restCenter(widget.value);
      content = Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            key: const ValueKey('die-surface'),
            child: CustomPaint(painter: _painter),
          ),
          Align(
            alignment: Alignment(
              center.x * 2 * kDieRadiusFraction,
              -center.y * 2 * kDieRadiusFraction,
            ),
            child: FadeTransition(
              opacity: _fade,
              child: DieNumberBadge(
                value: widget.value,
                skin: _skin,
                opacity: widget.dimmed ? 0.55 : 1,
              ),
            ),
          ),
        ],
      );
    }

    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.parchmentCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _borderColor,
                width: AppBorders.cardEmphasis,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Pastille du chiffre du résultat : `font.body` 800, 28 dp (1 chiffre) /
/// 24 dp (2 chiffres), plafonné à ×1,3 (conteneur de taille fixe), fond
/// opaque à ≥ 70 %, contraste ≥ 4,5:1 garanti par [DieSkin.ensureReadable].
/// 6, 9, 16 et 19 sont soulignés (un trait de 2 dp) pour ne pas se confondre
/// à l'envers.
///
/// Volontairement un [DecoratedBox] (et non un `Container`) : le plus proche
/// `Container` ancêtre du chiffre reste le plateau lui-même.
class DieNumberBadge extends StatelessWidget {
  const DieNumberBadge({
    required this.value,
    required this.skin,
    this.opacity = 1,
    super.key,
  });

  final int value;
  final DieSkin skin;
  final double opacity;

  /// Chiffres ambigus à l'envers.
  static const Set<int> underlined = {6, 9, 16, 19};

  @override
  Widget build(BuildContext context) {
    final safe = skin.ensureReadable();
    final fontSize = value >= 10 ? 24.0 : 28.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: safe.numberBackdropColor.withValues(
          alpha: safe.numberBackdropOpacity * opacity,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md + 3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '$value',
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: 1.3),
          style:
              AppTypography.body(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: safe.numberColor.withValues(alpha: opacity),
                height: 1.1,
              ).copyWith(
                decoration: underlined.contains(value)
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: safe.numberColor.withValues(alpha: opacity),
                decorationThickness: 2,
              ),
        ),
      ),
    );
  }
}
