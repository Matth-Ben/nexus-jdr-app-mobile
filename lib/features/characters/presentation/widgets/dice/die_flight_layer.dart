import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/dice3d/d20_orientation.dart';
import '../../../domain/dice3d/dice_flight_simulator.dart';
import '../../../domain/dice_roller.dart';
import 'die_flight.dart';
import 'die_flight_runner.dart';
import 'die_number_badge.dart';
import 'die_painter.dart';
import 'die_shader_cache.dart';
import 'die_skin.dart';

/// Ce que la couche plein écran doit montrer pour un jet : résultat (déjà
/// tiré), skin, mise en page, piste simulée (ou `null` = repli niveau 0) et
/// les points d'injection de test.
class DiceFlightConfig {
  DiceFlightConfig({
    required this.result,
    required this.skin,
    required this.layout,
    required this.track,
    required this.skip,
    required this.flightRandom,
    required this.onFailure,
    this.shaderCache,
    this.paintProbe,
  });

  final RollResult result;
  final DieSkin skin;
  final DiceFlightLayout layout;

  /// Piste simulée ; `null` : la simulation a échoué, repli « niveau 0 »
  /// (ancienne polyligne).
  final DiceFlightTrack? track;

  /// Saut au tap (glissement de 160 ms), partagé par les deux dés.
  final DieSkipState skip;

  /// `Random` **distinct** de celui du tirage : il ne sert qu'au chemin du
  /// repli niveau 0, jamais au résultat.
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
    required this.onSkip,
    super.key,
  });

  /// Valeur (0..1) du contrôleur linéaire de la feuille.
  final Animation<double> progress;
  final ValueListenable<DiceFlightConfig> config;

  /// `true` une fois le dé posé : la couche laisse alors passer les taps.
  final ValueListenable<bool> settled;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    // L'Overlay racine est hors de tout Material : sans ce `Material`, les
    // textes de la couche héritent du `DefaultTextStyle` d'erreur de
    // MaterialApp (souligné jaune double).
    return Material(
      type: MaterialType.transparency,
      child: ExcludeSemantics(
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
              onSkip: onSkip,
            ),
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
    required this.onSkip,
    super.key,
  });

  final DiceFlightConfig config;
  final Animation<double> progress;
  final VoidCallback onSkip;

  @override
  State<_FlightScene> createState() => _FlightSceneState();
}

class _FlightSceneState extends State<_FlightScene> {
  late final List<DieFlightRunner> _runners = _buildRunners();

  List<DieFlightRunner> _buildRunners() {
    final cfg = widget.config;
    final dice = cfg.result.dice;
    final layout = cfg.layout;
    final track = cfg.track;
    return [
      for (var i = 0; i < dice.length; i++)
        if (track != null)
          DieFlightRunner.track(
            track: track,
            die: i,
            rest: layout.rests[i],
            target: D20Orientation.forValue(dice[i]),
            diameter: layout.diameter,
            skip: cfg.skip,
          )
        else
          DieFlightRunner.plan(
            plan: DieFlightPlan.build(
              table: layout.table,
              rest: layout.rests[i],
              radius: layout.radius,
              random: cfg.flightRandom,
            ),
            die: i,
            count: dice.length,
            rest: layout.rests[i],
            target: D20Orientation.forValue(dice[i]),
            diameter: layout.diameter,
            skip: cfg.skip,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final result = cfg.result;
    final pair = result.dice.length == 2;
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
            progress: widget.progress,
            runner: _runners[i],
            layout: cfg.layout,
            opacity: result.discardedIndex == i ? 0.55 : 1,
          ),
        for (var i = 0; i < result.dice.length; i++)
          _FlyingDie(
            key: ValueKey('flying-die-$i'),
            config: cfg,
            value: result.dice[i],
            progress: widget.progress,
            runner: _runners[i],
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

/// Ombre ellipse au sol : taille, opacité et décalage dépendent de la
/// hauteur ; flou créé une fois.
class _Shadow extends StatelessWidget {
  const _Shadow({
    required this.progress,
    required this.runner,
    required this.layout,
    required this.opacity,
  });

  final Animation<double> progress;
  final DieFlightRunner runner;
  final DiceFlightLayout layout;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final box = layout.box;
    return Positioned(
      left: 0,
      top: 0,
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          runner.update(progress.value);
          return Transform.translate(
            offset: Offset(runner.x - box / 2, runner.y - box / 2),
            child: child,
          );
        },
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _ShadowPainter(progress, runner, opacity),
          ),
        ),
      ),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  _ShadowPainter(this.progress, this.runner, this.opacity)
    : super(repaint: progress) {
    _paint.maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      runner.diameter * 0.05,
    );
  }

  final Animation<double> progress;
  final DieFlightRunner runner;
  final double opacity;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    runner.update(progress.value);
    final h = runner.h.clamp(0.0, 1.0);
    final d = runner.diameter;
    final r = d / 2;
    // Pose : ombre x 1,15.
    final pose = 1 + 0.15 * runner.poseU;
    _paint.color = AppColors.cardDiffuseShadow.withValues(
      alpha: (0.2 * (1 - 0.6 * h) * opacity * pose).clamp(0.0, 1.0),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width / 2 + 0.06 * d * (1 + h),
          size.height / 2 + 0.92 * r,
        ),
        width: 1.7 * r * (1 - 0.35 * h) * pose,
        height: 0.4 * r * (1 - 0.35 * h) * pose,
      ),
      _paint,
    );
  }

  @override
  bool shouldRepaint(_ShadowPainter old) =>
      old.progress != progress ||
      old.runner != runner ||
      old.opacity != opacity;
}

/// Un dé en vol : boîte de 1,25 × son côté nominal, translatée hors du
/// `RepaintBoundary` (seule la translation se reconstruit, le dessin est
/// piloté par le painter), pastille du chiffre et étiquette (ancrée sous le
/// bord du dé) qui apparaissent à la pose.
class _FlyingDie extends StatefulWidget {
  const _FlyingDie({
    required this.config,
    required this.value,
    required this.progress,
    required this.runner,
    required this.natural,
    required this.discarded,
    required this.kept,
    required this.labelled,
    super.key,
  });

  final DiceFlightConfig config;
  final int value;
  final Animation<double> progress;
  final DieFlightRunner runner;
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
  late final Animation<double> _fade = RunnerFade(
    widget.progress,
    widget.runner,
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
    runner: widget.runner,
    value: widget.value,
    skin: _skin,
    shader: _shader,
    natural: widget.natural,
    struck: widget.discarded,
    opacity: widget.discarded ? 0.55 : 1,
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
    final layout = widget.config.layout;
    final box = layout.box;
    final fraction = kDieRadiusFraction / DiceFlightLayout.boxFactor;
    final center = D20Orientation.restCenter(widget.value);
    final opacity = widget.discarded ? 0.55 : 1.0;
    final runner = widget.runner;

    return Positioned(
      left: 0,
      top: 0,
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: widget.progress,
        builder: (context, child) {
          runner.update(widget.progress.value);
          return Transform.translate(
            offset: Offset(
              runner.x - box / 2,
              runner.y - runner.lift - box / 2,
            ),
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
              // Étiquette ancrée 4 dp sous le bord du dé (centre + 0,42·S + 4),
              // elle suit le dé où qu'il se pose.
              Positioned(
                left: 0,
                right: 0,
                top: layout.labelTop,
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: _DieLabel(kept: widget.kept),
                  ),
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
