import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/dice3d/d20_orientation.dart';
import '../../../domain/dice_roller.dart';
import 'die_flight.dart';
import 'die_motion.dart';
import 'die_number_badge.dart';
import 'die_painter.dart';
import 'die_shader_cache.dart';
import 'die_skin.dart';

/// Ce que la couche plein écran doit montrer pour un jet : résultat (déjà
/// tiré), skin, et les points d'injection de test.
class DiceFlightConfig {
  DiceFlightConfig({
    required this.result,
    required this.skin,
    required this.flightRandom,
    required this.onFailure,
    this.shaderCache,
    this.paintProbe,
  });

  final RollResult result;
  final DieSkin skin;

  /// `Random` **distinct** de celui du tirage : il ne choisit que le chemin
  /// du dé (cosmétique), jamais le résultat.
  final math.Random flightRandom;
  final DieShaderCache? shaderCache;
  final VoidCallback? paintProbe;

  /// Un dé n'a pas pu être dessiné : la feuille retire la couche et
  /// réaffiche le dé statique.
  final VoidCallback onFailure;
}

/// Couche plein écran (insérée dans l'`Overlay` racine par la feuille de
/// dés) qui possède le vol du dé : un dé 3D par résultat, lancé sur toute la
/// page, qui reste visible jusqu'à la fermeture de la feuille.
///
/// Décorative ([ExcludeSemantics]). Pendant le vol, un `GestureDetector`
/// opaque plein écran absorbe tout ; un tap = saut à l'état posé ([onSkip]),
/// jamais fermeture de la feuille. Une fois posé, la couche est
/// [IgnorePointer] : rien n'est bloqué. Le builder est constant : seuls les
/// painters (et la translation de chaque dé) écoutent le contrôleur.
class DiceFlightLayer extends StatelessWidget {
  const DiceFlightLayer({
    required this.progress,
    required this.config,
    required this.settled,
    required this.restTop,
    required this.onSkip,
    super.key,
  });

  /// Valeur (0..1) du contrôleur unique de la feuille.
  final Animation<double> progress;
  final ValueListenable<DiceFlightConfig> config;

  /// `true` une fois le dé posé : la couche laisse alors passer les taps.
  final ValueListenable<bool> settled;

  /// Haut de la feuille (coordonnée écran), mesuré une fois la feuille
  /// arrivée ; `null` tant qu'inconnu.
  final ValueListenable<double?> restTop;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ValueListenableBuilder<bool>(
        valueListenable: settled,
        builder: (context, done, child) =>
            IgnorePointer(ignoring: done, child: child),
        child: ValueListenableBuilder<DiceFlightConfig>(
          valueListenable: config,
          builder: (context, cfg, _) => _FlightScene(
            key: ValueKey(cfg),
            config: cfg,
            progress: progress,
            restTop: restTop,
            onSkip: onSkip,
          ),
        ),
      ),
    );
  }
}

class _FlightScene extends StatefulWidget {
  const _FlightScene({
    required this.config,
    required this.progress,
    required this.restTop,
    required this.onSkip,
    super.key,
  });

  final DiceFlightConfig config;
  final Animation<double> progress;
  final ValueListenable<double?> restTop;
  final VoidCallback onSkip;

  @override
  State<_FlightScene> createState() => _FlightSceneState();
}

class _FlightSceneState extends State<_FlightScene> {
  List<DieFlightPlan>? _plans;
  Size? _planSize;
  late final List<PlateProgress> _progress = [
    for (var i = 0; i < widget.config.result.dice.length; i++)
      PlateProgress(widget.progress, i, widget.config.result.dice.length),
  ];

  @override
  void initState() {
    super.initState();
    widget.restTop.addListener(_onRestTop);
  }

  @override
  void dispose() {
    widget.restTop.removeListener(_onRestTop);
    super.dispose();
  }

  void _onRestTop() {
    if (mounted) setState(() => _plans = null);
  }

  double _dieSize(double width) => widget.config.result.dice.length == 1
      ? DieFlightSizes.single(width)
      : DieFlightSizes.pair(width);

  List<DieFlightPlan> _buildPlans(MediaQueryData media) {
    final result = widget.config.result;
    final dieSize = _dieSize(media.size.width);
    final table = tableRect(
      media.size,
      top: media.padding.top,
      bottom: media.padding.bottom,
    );
    final sheetTop = widget.restTop.value ?? media.size.height * 0.5;
    final rests = restPoints(
      table: table,
      sheetTop: sheetTop,
      dieSize: dieSize,
      count: result.dice.length,
    );
    return [
      for (var i = 0; i < result.dice.length; i++)
        DieFlightPlan.build(
          table: table,
          rest: rests[i],
          radius: dieSize * kDieRadiusFraction,
          random: widget.config.flightRandom,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (_plans == null || _planSize != media.size) {
      // Un changement de taille en vol est géré par la feuille (saut à
      // l'état posé) ; ici on recalcule seulement le repos.
      _plans = _buildPlans(media);
      _planSize = media.size;
    }
    final result = widget.config.result;
    final pair = result.dice.length == 2;
    final dieSize = _dieSize(media.size.width);
    final natural = result.isNaturalTwenty
        ? DieNatural.twenty
        : result.isNaturalOne
        ? DieNatural.one
        : DieNatural.none;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < result.dice.length; i++)
          _Shadow(
            progress: _progress[i],
            plan: _plans![i],
            dieSize: dieSize,
            opacity: result.discardedIndex == i ? 0.55 : 1,
          ),
        for (var i = 0; i < result.dice.length; i++)
          _FlyingDie(
            key: ValueKey('flying-die-$i'),
            config: widget.config,
            value: result.dice[i],
            progress: _progress[i],
            plan: _plans![i],
            dieSize: dieSize,
            natural: result.discardedIndex == i ? DieNatural.none : natural,
            discarded: result.discardedIndex == i,
            kept: pair && result.discardedIndex != i,
            labelled: pair,
          ),
        // Au-dessus de tout : absorbe les taps pendant le vol (saut).
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('dice-flight-tap'),
            behavior: HitTestBehavior.opaque,
            onTap: widget.onSkip,
          ),
        ),
      ],
    );
  }
}

/// Ombre ellipse au sol : taille et opacité décroissent avec la hauteur.
class _Shadow extends StatelessWidget {
  const _Shadow({
    required this.progress,
    required this.plan,
    required this.dieSize,
    required this.opacity,
  });

  final Animation<double> progress;
  final DieFlightPlan plan;
  final double dieSize;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final box = dieSize * DieFlightSizes.boxFactor;
    return Positioned(
      left: 0,
      top: 0,
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          final g = plan.groundAt(progress.value);
          return Transform.translate(
            offset: Offset(g.dx - box / 2, g.dy - box / 2),
            child: child,
          );
        },
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _ShadowPainter(progress, dieSize, opacity),
          ),
        ),
      ),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  _ShadowPainter(this.progress, this.dieSize, this.opacity)
    : super(repaint: progress);

  final Animation<double> progress;
  final double dieSize;
  final double opacity;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final h = DieFlightPlan.heightAt(progress.value).clamp(0.0, 1.0);
    final radius = dieSize * kDieRadiusFraction;
    _paint.color = AppColors.cardDiffuseShadow.withValues(
      alpha: 0.2 * (1 - 0.6 * h) * opacity,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 + radius * 0.92),
        width: radius * 1.7 * (1 - 0.35 * h),
        height: radius * 0.4 * (1 - 0.35 * h),
      ),
      _paint,
    );
  }

  @override
  bool shouldRepaint(_ShadowPainter old) =>
      old.progress != progress || old.opacity != opacity;
}

/// Un dé en vol : boîte de 1,25 × sa taille nominale, translatée hors du
/// `RepaintBoundary` (seule la translation se reconstruit, le dessin est
/// piloté par le painter), pastille du chiffre et étiquette qui apparaissent
/// à la pose.
class _FlyingDie extends StatefulWidget {
  const _FlyingDie({
    required this.config,
    required this.value,
    required this.progress,
    required this.plan,
    required this.dieSize,
    required this.natural,
    required this.discarded,
    required this.kept,
    required this.labelled,
    super.key,
  });

  final DiceFlightConfig config;
  final int value;
  final Animation<double> progress;
  final DieFlightPlan plan;
  final double dieSize;
  final DieNatural natural;
  final bool discarded;
  final bool kept;
  final bool labelled;

  @override
  State<_FlyingDie> createState() => _FlyingDieState();
}

class _FlyingDieState extends State<_FlyingDie> {
  late final DieSkin _skin = widget.config.skin.ensureReadable();
  late DieSurfacePainter _painter;
  ui.FragmentShader? _shader;
  late final Animation<double> _fade = widget.progress.drive(
    CurveTween(curve: const ResultFadeCurve()),
  );

  DieShaderCache get _cache =>
      widget.config.shaderCache ?? DieShaderCache.shared;

  @override
  void initState() {
    super.initState();
    _ensureShader();
    _painter = _buildPainter();
  }

  void _ensureShader() {
    if (_skin.textureId == DieTextureId.none) return;
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
          _painter.dispose();
          _painter = _buildPainter();
        });
      });
    }
  }

  DieSurfacePainter _buildPainter() => DieSurfacePainter(
    progress: widget.progress,
    value: widget.value,
    skin: _skin,
    shader: _shader,
    natural: widget.natural,
    struck: widget.discarded,
    opacity: widget.discarded ? 0.55 : 1,
    free: true,
    onFailure: (_) => widget.config.onFailure(),
    debugProbe: widget.config.paintProbe,
  );

  @override
  void dispose() {
    _painter.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.dieSize * DieFlightSizes.boxFactor;
    final fraction = kDieRadiusFraction / DieFlightSizes.boxFactor;
    final center = D20Orientation.restCenter(widget.value);
    final opacity = widget.discarded ? 0.55 : 1.0;

    return Positioned(
      left: 0,
      top: 0,
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: widget.progress,
        builder: (context, child) {
          final t = widget.progress.value;
          final g = widget.plan.groundAt(t);
          final lift = DieFlightPlan.liftPx(t, widget.dieSize);
          return Transform.translate(
            offset: Offset(g.dx - box / 2, g.dy - lift - box / 2),
            child: child,
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              key: const ValueKey('die-surface'),
              child: CustomPaint(painter: _painter),
            ),
            Align(
              alignment: Alignment(
                center.x * 2 * fraction,
                -center.y * 2 * fraction,
              ),
              child: FadeTransition(
                opacity: _fade,
                child: DieNumberBadge(
                  value: widget.value,
                  skin: _skin,
                  opacity: opacity,
                ),
              ),
            ),
            if (widget.labelled)
              Align(
                alignment: const Alignment(0, 0.94),
                child: FadeTransition(
                  opacity: _fade,
                  child: _DieLabel(kept: widget.kept),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Étiquette « Retenu » / « Écarté » sous un dé : pastille `parchmentCard`
/// 90 %, `font.body` 12 w700, plafonnée à ×1,3.
class _DieLabel extends StatelessWidget {
  const _DieLabel({required this.kept});

  final bool kept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          kept ? l10n.diceRollKeptLabel : l10n.diceRollDiscardedLabel,
          key: ValueKey(kept ? 'die-label-kept' : 'die-label-discarded'),
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: 1.3),
          style: AppTypography.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kept ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
