import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/display_text.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../core/widgets/pixel_icons/die_result_pixel_icons.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dice3d/d20_orientation.dart';
import '../../domain/dice3d/dice_flight_simulator.dart';
import '../../domain/dice3d/die_math.dart';
import '../../domain/dice_roller.dart';
import '../../domain/signed_modifier_formatter.dart';
import 'dice/dice_haptics.dart';
import 'dice/die_flight.dart';
import 'dice/die_flight_layer.dart';
import 'dice/die_flight_runner.dart';
import 'dice/die_motion.dart';
import 'dice/die_shader_cache.dart';
import 'dice/die_skin.dart';

/// Construit la piste d'un lancer (remplace la simulation dans les tests) ;
/// `null` = la simulation a échoué (repli niveau 0).
typedef DiceFlightTrackBuilder = DiceFlightTrack? Function(
  DiceFlightLayout layout,
  List<Quat> targets,
  double duration,
);

/// Annonce d'accessibilité du résultat d'un jet (remplaçable dans les tests).
typedef DiceRollAnnouncer = void Function(BuildContext context, String text);

void _defaultAnnouncer(BuildContext context, String text) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    text,
    Directionality.of(context),
  );
}

/// Ouvre le "mini lancer de dé virtuel" d'un jet de compétence, de
/// caractéristique, de sauvegarde ou d'initiative — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Compétences" : "Jets de compétences/caractéristiques directement
/// lançables depuis la fiche". Tire immédiatement un d20 **en mode normal** à
/// l'ouverture (relançable via "Relancer"), affiche le total (d20 +
/// [modifier]) — jamais écrit en base, jamais partagé avec personne d'autre :
/// un pur confort de jeu local, comme un vrai dé qu'on lance sur la table.
///
/// Le joueur peut choisir Normal / Avantage / Désavantage (P2, 11/11/2026) :
/// choix saisi, jamais déduit, non persisté (retour à Normal à chaque
/// ouverture) ; changer de mode ne relance pas, "Relancer" l'applique.
///
/// Le dé est animé en 3D (P2b, prototype d20) : le résultat est tiré par
/// [DiceRoller] **avant** l'animation (1 400 ms, un tap la saute), qui n'est
/// qu'un habillage ; le texte, la région `liveRegion` et l'annonce n'arrivent
/// qu'une fois le dé posé (immédiatement si les animations sont coupées).
/// [skin] : apparence du dé (défaut [DieSkin.defaultSkin]), aucun sélecteur
/// dans l'UI pour l'instant.
///
/// [label] : nom de la compétence ("Athlétisme"), de la caractéristique
/// ("Force") ou de la sauvegarde affiché en titre. Aucune distinction de
/// traitement entre les cas — le bonus de maîtrise éventuel est déjà reflété
/// dans [modifier] par l'appelant. Ces jets ne sont pas des attaques : on
/// affiche "20 naturel"/"1 naturel", jamais "critique" (RAW).
///
/// [useResultLabel] (optionnel, combat de groupe — saisie d'initiative) : si
/// fourni, un bouton primaire « Utiliser {total} » (libellé construit par
/// l'appelant à partir du total d20 ± modificateur) apparaît une fois le dé
/// posé ; il ferme la feuille et **renvoie le total**. « Relancer » reste
/// possible avant. Sans [useResultLabel] (tous les autres appelants), rien ne
/// change : aucun bouton en plus, le futur se termine toujours à `null`.
Future<int?> showDiceRollSheet(
  BuildContext context, {
  required String label,
  required int modifier,
  String Function(int total)? useResultLabel,
  @visibleForTesting Random? random,
  @visibleForTesting DiceRollAnnouncer announcer = _defaultAnnouncer,
  @visibleForTesting DieSkin skin = DieSkin.defaultSkin,
  @visibleForTesting DieShaderCache? shaderCache,
  @visibleForTesting VoidCallback? paintProbe,
  @visibleForTesting Random? flightRandom,
  @visibleForTesting DiceFlightTrackBuilder? trackBuilder,
  @visibleForTesting DiceHapticPlayer? haptics,
}) {
  // Chargement du shader pendant l'ouverture de la feuille, jamais pendant
  // l'animation (ne lève jamais : un échec = rendu de niveau 1).
  (shaderCache ?? DieShaderCache.shared).preload(skin.shaderId);
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Le dé vole sur la page entière : la feuille laisse de la place (62 % de
    // la hauteur au plus).
    // `maxWidth` 640 : conserve la contrainte M3 par défaut des feuilles.
    constraints: BoxConstraints(
      maxWidth: 640,
      maxHeight: MediaQuery.sizeOf(context).height * 0.62,
    ),
    builder: (sheetContext) => _DiceRollSheetContent(
      label: label,
      modifier: modifier,
      useResultLabel: useResultLabel,
      random: random,
      announcer: announcer,
      skin: skin,
      shaderCache: shaderCache,
      paintProbe: paintProbe,
      flightRandom: flightRandom,
      trackBuilder: trackBuilder,
      haptics: haptics,
    ),
  );
}

class _DiceRollSheetContent extends StatefulWidget {
  const _DiceRollSheetContent({
    required this.label,
    required this.modifier,
    required this.announcer,
    required this.skin,
    this.useResultLabel,
    this.random,
    this.shaderCache,
    this.paintProbe,
    this.flightRandom,
    this.trackBuilder,
    this.haptics,
  });

  final String label;
  final int modifier;

  /// `null` : feuille classique, sans bouton « Utiliser ».
  final String Function(int total)? useResultLabel;
  final DiceRollAnnouncer announcer;

  /// Injectable uniquement pour les tests (`DiceRoller.rollD20` documente le
  /// même besoin) — `null` en production, `Random()` non déterministe.
  final Random? random;

  final DieSkin skin;
  final DieShaderCache? shaderCache;
  final VoidCallback? paintProbe;

  /// `Random` de la trajectoire du dé (cosmétique, distinct de [random]).
  final Random? flightRandom;

  /// Remplace la simulation (tests : piste fixe ou échec simulé).
  final DiceFlightTrackBuilder? trackBuilder;

  /// Retour haptique (remplaçable dans les tests).
  final DiceHapticPlayer? haptics;

  @override
  State<_DiceRollSheetContent> createState() => _DiceRollSheetContentState();
}

class _DiceRollSheetContentState extends State<_DiceRollSheetContent>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Mode choisi pour le PROCHAIN jet : jamais persisté, Normal à chaque
  /// ouverture.
  RollMode _mode = RollMode.normal;

  /// Tiré avant toute animation : l'animation ne fait que converger vers lui.
  late RollResult _result = _roll();

  /// Contrôleur unique de l'animation (1 400 ms, + 120 ms pour le second dé).
  late final AnimationController _controller;

  /// `true` une fois le dé posé : texte, région live et annonce suivent.
  bool _settled = false;
  bool _started = false;
  bool _starting = false;
  RollResult? _announcedFor;

  /// Couche plein écran qui possède le vol du dé (insérée dans l'`Overlay`
  /// racine, retirée au `dispose`).
  OverlayEntry? _entry;
  ValueNotifier<DiceFlightConfig>? _flightConfig;
  final ValueNotifier<bool> _settledNotifier = ValueNotifier<bool>(false);

  /// Retours haptiques du lancer (joués depuis le contrôleur, jamais depuis
  /// `paint`).
  late final DiceHapticsDriver _haptics = DiceHapticsDriver(
    widget.haptics ?? const SystemDiceHapticPlayer(),
  );

  /// Piste simulée du lancer courant (`null` : repli niveau 0).
  DiceFlightTrack? _track;
  double _durationSeconds = DiceFlightLayout.durationFor(1);
  DieSkipState _skipState = DieSkipState();

  /// La couche n'a pas pu être posée ou dessinée : retour au dé statique
  /// dans la feuille.
  bool _overlayFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addStatusListener(_onStatus);
    // Contrôleur linéaire : seules courbes = ressort et orientation de la
    // simulation (aucune courbe ici).
    _controller.addListener(_onTick);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertOverlay());
  }

  /// Mise en page, simulation et saut du lancer courant. La simulation est
  /// calculée **une seule fois** par lancer (< 1 ms) ; si elle échoue,
  /// [DiceFlightConfig.track] est `null` (repli niveau 0).
  DiceFlightConfig _buildFlightConfig() {
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final result = _result;
    final layout = DiceFlightLayout.compute(
      view.physicalSize / dpr,
      paddingTop: view.padding.top / dpr,
      paddingBottom: view.padding.bottom / dpr,
      count: result.dice.length,
    );
    final duration = DiceFlightLayout.durationFor(result.dice.length);
    final targets = [
      for (final value in result.dice) D20Orientation.forValue(value),
    ];
    final random = widget.flightRandom ?? Random();
    DiceFlightTrack? track;
    try {
      track =
          widget.trackBuilder?.call(layout, targets, duration) ??
          (widget.trackBuilder == null
              ? DiceFlightSimulator.simulate(
                  layout.arena(targets, duration),
                  random,
                )
              : null);
    } on Object catch (error) {
      if (kDebugMode) debugPrint('Simulation du dé échouée : $error');
    }
    _track = track;
    _skipState = DieSkipState();
    _durationSeconds =
        track?.duration ??
        DieTimeline.totalDuration(result.dice.length).inMilliseconds / 1000;
    return DiceFlightConfig(
      result: result,
      skin: widget.skin,
      layout: layout,
      track: track,
      skip: _skipState,
      flightRandom: random,
      shaderCache: widget.shaderCache,
      paintProbe: widget.paintProbe,
      onFailure: _onOverlayFailure,
    );
  }

  /// Animations coupées : pose immédiate, aucune haptique.
  bool get _animationsDisabled => MediaQuery.disableAnimationsOf(context);

  /// Navigation accessible : pose immédiate, seulement le clic de pose.
  bool get _accessibleNavigation => MediaQuery.accessibleNavigationOf(context);

  /// Animations coupées ou navigation accessible : pose immédiate.
  bool get _reducedMotion => _animationsDisabled || _accessibleNavigation;

  void _insertOverlay() {
    if (!mounted || _overlayFailed || _entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _failOverlay();
      return;
    }
    _entry = OverlayEntry(
      builder: (_) => DiceFlightLayer(
        progress: _controller,
        config: _flightConfig!,
        settled: _settledNotifier,
        onSkip: _skip,
      ),
    );
    overlay.insert(_entry!);
  }

  void _onOverlayFailure() {
    // Appelé depuis la phase de dessin : on attend la fin de l'image.
    WidgetsBinding.instance.addPostFrameCallback((_) => _failOverlay());
  }

  void _failOverlay() {
    if (!mounted || _overlayFailed) return;
    _removeEntry();
    setState(() => _overlayFailed = true);
    _controller.value = 1;
    _settle();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  @override
  void didChangeMetrics() {
    // Changement de métriques en vol : saut à l'état posé et repos recalculé
    // pour la nouvelle taille d'écran.
    if (_controller.isAnimating) _controller.value = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _flightConfig == null) return;
      _flightConfig!.value = _buildFlightConfig();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _startRoll();
    } else if (_reducedMotion && _controller.isAnimating) {
      // Les animations viennent d'être coupées en cours de lancer : pose
      // immédiate.
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // La couche plein écran disparaît avec la feuille.
    _removeEntry();
    _controller.dispose();
    _flightConfig?.dispose();
    _settledNotifier.dispose();
    super.dispose();
  }

  RollResult _roll() => DiceRoller.rollD20Check(
    mode: _mode,
    modifier: widget.modifier,
    random: widget.random,
  );

  bool get _isRolling => !_settled;

  void _reroll() {
    if (_isRolling) return;
    setState(() {
      _result = _roll();
      _startRoll();
    });
  }

  /// Lance l'animation du jet courant (ou pose immédiatement si les
  /// animations sont coupées : pas de rebond, pas de tressautement).
  void _startRoll() {
    _starting = true;
    _settled = false;
    _settledNotifier.value = false;
    final config = _buildFlightConfig();
    if (_flightConfig == null) {
      _flightConfig = ValueNotifier(config);
    } else {
      _flightConfig!.value = config;
    }
    _controller.duration = Duration(
      milliseconds: (_durationSeconds * 1000).round(),
    );
    _haptics.start(
      DiceHapticsPlan.build(
        impacts: _track?.impacts ?? const [],
        duration: _durationSeconds,
        reducedMotion: _animationsDisabled,
        accessibleNavigation: _accessibleNavigation,
      ),
    );
    // Couche en échec : pas de vol, pose immédiate (le dé statique ne doit
    // pas révéler le résultat avant le fondu).
    if (_reducedMotion || _overlayFailed) {
      _controller.value = 1;
      // Déjà à 1 (relance) : aucun changement de statut n'est notifié.
      _settle();
    } else {
      _controller.forward(from: 0);
    }
    _starting = false;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _settle();
  }

  void _onTick() {
    if (_controller.isAnimating && !_skipState.active) {
      _haptics.tick(_controller.value * _durationSeconds);
    }
  }

  void _settle() {
    if (_settled) return;
    _settled = true;
    _settledNotifier.value = true;
    _haptics.settle();
    if (!_starting && mounted) setState(() {});
    _announceAfterFrame();
  }

  /// Tap pendant le lancer : glissement doux de 160 ms vers l'état posé (la
  /// pose, l'annonce et le clic de pose suivent à la fin du glissement).
  void _skip() {
    if (!_controller.isAnimating || _skipState.active) return;
    _skipState.begin(_controller.value);
    _haptics.cancelImpacts();
    _controller.animateTo(
      1,
      duration: const Duration(milliseconds: DieSkipState.durationMs),
      curve: Curves.linear,
    );
  }

  void _announceAfterFrame() {
    final roll = _result;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_settled || identical(_announcedFor, roll)) return;
      if (!identical(roll, _result)) return;
      _announcedFor = roll;
      widget.announcer(
        context,
        _semanticsLabel(AppLocalizations.of(context)!, roll),
      );
    });
  }

  Widget _rerollRow(AppLocalizations l10n) => Wrap(
    alignment: WrapAlignment.center,
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      SecondaryButton(
        label: l10n.diceRollSheetRerollButton,
        surface: SecondaryButtonSurface.parchment,
        // Inactif pendant le lancer.
        onPressed: _isRolling ? null : _reroll,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = _result;
    final isNatural20 = result.isNaturalTwenty;
    final isNatural1 = result.isNaturalOne;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeaderBar(title: widget.label.toUpperCase()),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ModeSelector(
                      mode: _mode,
                      // Changer de mode ne relance pas : seul "Relancer"
                      // applique le nouveau mode.
                      onChanged: (mode) => setState(() => _mode = mode),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Région live : vide tant que le dé roule, le libellé complet
                    // n'arrive (et n'est annoncé) qu'une fois le dé posé.
                    Semantics(
                      liveRegion: true,
                      container: true,
                      label: _settled ? _semanticsLabel(l10n, result) : '',
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Repli : si la couche plein écran échoue, l'ancien
                            // dé statique reprend sa place dans la feuille.
                            if (_overlayFailed)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _DieFace(
                                  value: result.kept,
                                  isNatural20: isNatural20,
                                  isNatural1: isNatural1,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            // La formule (source de vérité) apparaît en fondu
                            // en fin de lancer.
                            FadeTransition(
                              opacity: _controller.drive(
                                CurveTween(
                                  curve: _EndFadeCurve(_durationSeconds),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ResultDetail(result: result),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.diceRollResultMode(
                                      _modeName(l10n, result.mode),
                                    ),
                                    textAlign: TextAlign.center,
                                    style: AppTypography.body(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (isNatural20 || isNatural1) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    _NaturalBanner(isTwenty: isNatural20),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Avec `useResultLabel`, les actions sont dans un pied fixe
                    // (jamais sous le pli à ×2,0/×3,0) ; sinon, comme avant,
                    // « Relancer » reste dans la zone défilante.
                    if (widget.useResultLabel == null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _rerollRow(l10n),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.useResultLabel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  key: const Key('diceRollFooter'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      key: const Key('diceRollUseResult'),
                      label: widget.useResultLabel!(result.total),
                      // Inactif pendant le lancer : le total n'est connu du
                      // joueur qu'une fois le dé posé.
                      onPressed: _isRolling
                          ? null
                          : () => Navigator.of(context).pop(result.total),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _rerollRow(l10n),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fondu de la formule : derniers 200 ms du contrôleur unique.
class _EndFadeCurve extends Curve {
  const _EndFadeCurve(this.totalSeconds);

  final double totalSeconds;

  @override
  double transformInternal(double t) =>
      ((t * totalSeconds - (totalSeconds - 0.2)) / 0.2).clamp(0.0, 1.0);
}

String _modeName(AppLocalizations l10n, RollMode mode) => switch (mode) {
  RollMode.normal => l10n.diceRollModeNormal,
  RollMode.advantage => l10n.diceRollModeAdvantage,
  RollMode.disadvantage => l10n.diceRollModeDisadvantage,
};

/// "+ 3" / "− 2" (signe séparé du chiffre) pour la ligne de détail.
String _spacedModifier(int modifier) {
  final signed = SignedModifierFormatter.format(modifier);
  return '${signed.substring(0, 1)} ${signed.substring(1)}';
}

/// Libellé complet du résultat, lu par les lecteurs d'écran et annoncé au
/// tirage : « Résultat : d20 17, plus 3, total 20, 20 naturel ».
String _semanticsLabel(AppLocalizations l10n, RollResult result) {
  final modifier = result.modifier < 0
      ? l10n.diceRollSemanticsModifierMinus(-result.modifier)
      : l10n.diceRollSemanticsModifierPlus(result.modifier);
  final discarded = result.discarded;
  final parts = [
    l10n.diceRollSemanticsResult(result.kept, modifier, result.total),
    if (discarded != null)
      l10n.diceRollSemanticsDice(
        _modeName(l10n, result.mode),
        result.dice[0],
        result.dice[1],
        discarded,
      ),
    if (result.isNaturalTwenty) l10n.diceRollSheetNatural20.toLowerCase(),
    if (result.isNaturalOne) l10n.diceRollSheetNatural1.toLowerCase(),
  ];
  return parts.join(', ');
}

/// Sélecteur Normal / Avantage / Désavantage : bascule segmentée en une
/// ligne, en colonne de tuiles dès l'échelle de texte 1,5 (3 segments ne
/// tiennent plus sur 360 dp).
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final RollMode mode;
  final ValueChanged<RollMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final large = MediaQuery.textScalerOf(context).scale(10) >= 15;

    return Semantics(
      container: true,
      label: l10n.diceRollModeGroupLabel,
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in RollMode.values) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: SelectableOptionTile(
                      title: _modeName(l10n, option),
                      selected: option == mode,
                      onTap: () => onChanged(option),
                    ),
                  ),
                  if (option != RollMode.values.last)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            )
          : SegmentedToggle<RollMode>(
              value: mode,
              onChanged: onChanged,
              options: [
                for (final option in RollMode.values)
                  SegmentedToggleOption(
                    value: option,
                    label: _modeName(l10n, option),
                  ),
              ],
            ),
    );
  }
}

/// Ligne de détail : formule simple en mode normal ; avec avantage/
/// désavantage, les deux d20 avec le dé écarté barré ET suivi du mot
/// « écarté » (jamais la couleur seule).
class _ResultDetail extends StatelessWidget {
  const _ResultDetail({required this.result});

  final RollResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = AppTypography.body(fontSize: 20, fontWeight: FontWeight.w800);

    if (result.discardedIndex == null) {
      return Text(
        l10n.diceRollSheetFormula(
          result.kept,
          SignedModifierFormatter.format(result.modifier),
          result.total,
        ),
        textAlign: TextAlign.center,
        style: style,
      );
    }

    List<InlineSpan> die(int index) {
      final value = '${result.dice[index]}';
      if (index != result.discardedIndex) return [TextSpan(text: value)];
      return [
        TextSpan(
          text: value,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.accentBrick,
            decorationThickness: 2,
          ),
        ),
        TextSpan(text: ' (${l10n.diceRollDiscarded})'),
      ];
    }

    final tail = l10n.diceRollDetailTail(
      result.kept,
      _spacedModifier(result.modifier),
      result.total,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l10n.diceRollDetailLead(_modeName(l10n, result.mode))} ',
          ),
          ...die(0),
          TextSpan(text: ' ${l10n.diceRollDetailAnd} '),
          ...die(1),
          TextSpan(text: ' $tail'),
        ],
      ),
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

/// "20 naturel" / "1 naturel" : icône + texte (jamais la couleur seule). Pas
/// de « critique » : ce mot n'a de sens RAW que pour une attaque.
class _NaturalBanner extends StatelessWidget {
  const _NaturalBanner({required this.isTwenty});

  final bool isTwenty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = isTwenty ? AppColors.goldEnd : AppColors.accentBrick;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        // Icône pixel provisoire (P2b) : étoile / crâne, jamais la couleur
        // seule (la mention texte suit).
        PixelIcon(
          key: ValueKey(isTwenty ? 'natural-icon-star' : 'natural-icon-skull'),
          matrix:
              kDieResultPixelMatrices[isTwenty ? kDieStarKey : kDieSkullKey]!,
          size: 16,
          color: color,
        ),
        DisplayText(
          isTwenty ? l10n.diceRollSheetNatural20 : l10n.diceRollSheetNatural1,
          textAlign: TextAlign.center,
          style: AppTypography.display(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

/// Pastille statique du d20 — repli « niveau 2 » du dé animé si le rendu 3D
/// échoue. Bordure dorée en cas de 20 naturel, brique en cas
/// de 1 naturel (mêmes tokens que le reste de la fiche pour signaler une
/// réussite/un échec marquant), `wood.light` sinon. Taille minimale (et non
/// fixe) : le chiffre de 36 px grandit avec la police système.
class _DieFace extends StatelessWidget {
  const _DieFace({
    required this.value,
    required this.isNatural20,
    required this.isNatural1,
  });

  final int value;
  final bool isNatural20;
  final bool isNatural1;

  @override
  Widget build(BuildContext context) {
    final borderColor = isNatural20
        ? AppColors.goldEnd
        : isNatural1
        ? AppColors.accentBrick
        : AppColors.woodLight;

    return Container(
      constraints: const BoxConstraints(minWidth: 88, minHeight: 88),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: AppBorders.cardEmphasis),
      ),
      // `Center` à facteurs 1 : la pastille épouse le chiffre mais ne descend
      // jamais sous 88 (et ne s'étire pas dans son parent).
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          '$value',
          style: AppTypography.body(fontSize: 36, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
