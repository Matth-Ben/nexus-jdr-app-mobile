import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_brand_badge.dart';
import '../../../core/widgets/scene_scaffold.dart';

/// Écran de lancement Flutter (par opposition au splash natif statique de
/// `flutter_native_splash`, voir `pubspec.yaml`, qui reste inchangé et
/// s'affiche avant même que Flutter ne démarre) : affiché par [main] pendant
/// l'initialisation asynchrone de Supabase (et Firebase sur Android), le
/// temps strictement nécessaire — voir la documentation de classe de
/// `_AppBootstrap` dans `main.dart` pour le câblage exact — avant que
/// l'app bascule sur [NexusJdrApp] (routeur applicatif,
/// `core/router/app_router.dart`), qui redirige alors automatiquement vers
/// `/login` ou `/` selon l'état d'authentification, exactement comme
/// aujourd'hui.
///
/// Voir `docs/cahier-des-charges/09-maquettes-captures.md`, section
/// "Lancement — Splash", et `05-ux-navigation.md` (« L'écran de lancement
/// affiche l'emblème et le nom de l'app pendant le temps strictement
/// nécessaire à l'initialisation »).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SceneScaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppBrandBadge(size: 96),
              const SizedBox(height: AppSpacing.md),
              Text(
                'NEXUS JDR',
                style: AppTypography.display(
                  fontSize: 15,
                  color: AppColors.textOnWood,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'PERSONNAGES',
                style: AppTypography.display(
                  fontSize: 10,
                  color: AppColors.goldEnd,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _ThreeDotLoader(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Préparation de la taverne…',
                style: AppTypography.body(color: AppColors.textOnWoodMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicateur de chargement à 3 points, chacun pulsant en fondu enchaîné
/// décalé d'1/3 de cycle par rapport au précédent (voir maquette citée dans
/// la doc de [SplashScreen]) — implémenté avec un simple
/// [AnimationController] plutôt qu'une bibliothèque d'animation externe,
/// pas de précédent dans ce dépôt pour un usage aussi ponctuel.
class _ThreeDotLoader extends StatefulWidget {
  const _ThreeDotLoader();

  @override
  State<_ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<_ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i != 0) const SizedBox(width: AppSpacing.xs),
            _Dot(animation: _controller, delayFraction: i / 3),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.animation, required this.delayFraction});

  final Animation<double> animation;

  /// Décalage du point dans le cycle, en fraction de tour (0, 1/3, 2/3).
  final double delayFraction;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = (animation.value + delayFraction) % 1.0;
        // Fondu enchaîné : opacité minimale en début/fin de cycle, maximale
        // au milieu — trois points décalés d'1/3 de cycle chacun donnent
        // l'impression de vague caractéristique d'un indicateur "3 points".
        final opacity = 0.3 + 0.7 * (0.5 - 0.5 * math.cos(2 * math.pi * t));
        return Opacity(opacity: opacity, child: child);
      },
      child: const _DotShape(),
    );
  }
}

class _DotShape extends StatelessWidget {
  const _DotShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.goldEnd,
        shape: BoxShape.circle,
      ),
    );
  }
}
