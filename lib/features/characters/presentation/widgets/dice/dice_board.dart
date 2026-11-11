import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/dice_roller.dart';
import 'die_painter.dart';
import 'die_plate.dart';
import 'die_shader_cache.dart';
import 'die_skin.dart';

/// Hauteur de la boîte du dé : identique en jet normal et en avantage/
/// désavantage, pour qu'aucun changement de mode ne fasse sauter la mise en
/// page.
const double kDiceBoardHeight = 192;

/// Côté d'un plateau seul (jet normal).
const double kSinglePlateSize = 160;

/// Côté de chaque plateau en avantage/désavantage (deux côte à côte).
const double kPairPlateSize = 120;

/// Zone du dé de la feuille de dés : un plateau 160×160 (jet normal) ou deux
/// plateaux 120×120 (avantage/désavantage, le second décalé de 120 ms) dans
/// une boîte de 192 dp de haut au minimum. Le dé retenu est étiqueté
/// « Retenu », le dé écarté « Écarté » (55 %, barré) ; le naturel (halo,
/// bordure) ne concerne que le dé retenu.
///
/// [progress] est la valeur (0..1) du contrôleur unique de la feuille ;
/// chaque plateau en dérive sa propre progression.
class DiceBoard extends StatefulWidget {
  const DiceBoard({
    required this.result,
    required this.progress,
    required this.skin,
    required this.fallbackBuilder,
    this.onTap,
    this.shaderCache,
    this.debugPaintProbe,
    super.key,
  });

  final RollResult result;
  final Animation<double> progress;
  final DieSkin skin;

  /// Dé statique de repli (niveau 2) pour la valeur donnée.
  final Widget Function(BuildContext context, int value, DieNatural natural)
  fallbackBuilder;
  final VoidCallback? onTap;

  @visibleForTesting
  final DieShaderCache? shaderCache;

  @visibleForTesting
  final VoidCallback? debugPaintProbe;

  @override
  State<DiceBoard> createState() => _DiceBoardState();
}

class _DiceBoardState extends State<DiceBoard> {
  late List<PlateProgress> _plates = _buildPlates();

  List<PlateProgress> _buildPlates() => [
    for (var i = 0; i < widget.result.dice.length; i++)
      PlateProgress(widget.progress, i, widget.result.dice.length),
  ];

  @override
  void didUpdateWidget(DiceBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.result != widget.result) {
      _plates = _buildPlates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final pair = result.dice.length == 2;
    final size = pair ? kPairPlateSize : kSinglePlateSize;
    final natural = result.isNaturalTwenty
        ? DieNatural.twenty
        : result.isNaturalOne
        ? DieNatural.one
        : DieNatural.none;

    Widget plate(int index) {
      final discarded = result.discardedIndex == index;
      final kept = pair && !discarded;
      final value = result.dice[index];
      final dieNatural = discarded ? DieNatural.none : natural;
      final child = DiePlate(
        // Une nouvelle clé par tirage : état neuf (painter, shader, fondu).
        key: ValueKey('die-plate-${identityHashCode(result)}-$index'),
        value: value,
        size: size,
        skin: widget.skin,
        progress: _plates[index],
        natural: dieNatural,
        dimmed: discarded,
        onTap: widget.onTap,
        shaderCache: widget.shaderCache,
        debugPaintProbe: widget.debugPaintProbe,
        fallbackBuilder: (context) =>
            widget.fallbackBuilder(context, value, dieNatural),
      );
      if (!pair) return child;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: AppSpacing.xs),
          FadeTransition(
            opacity: _plates[index].drive(
              CurveTween(curve: const ResultFadeCurve()),
            ),
            child: _PlateLabel(kept: kept),
          ),
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kDiceBoardHeight),
      child: Center(
        child: pair
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [plate(0), const SizedBox(width: 8), plate(1)],
              )
            : plate(0),
      ),
    );
  }
}

/// Étiquette « Retenu » / « Écarté » sous un plateau (texte réel, ≥ 11 px).
class _PlateLabel extends StatelessWidget {
  const _PlateLabel({required this.kept});

  final bool kept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      kept ? l10n.diceRollKeptLabel : l10n.diceRollDiscardedLabel,
      key: ValueKey(kept ? 'die-label-kept' : 'die-label-discarded'),
      textAlign: TextAlign.center,
      style: AppTypography.body(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: kept ? AppColors.textPrimary : AppColors.textSecondary,
      ),
    );
  }
}
