import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../../core/widgets/stepper_counter.dart';
import '../domain/ability_score_definitions.dart';
import '../domain/ability_score_method.dart';
import '../domain/ability_score_modifier_calculator.dart';
import '../domain/ability_score_rules.dart';
import '../domain/character_creation_failure.dart';
import '../domain/race_catalog.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';

/// Étape 4/9 de l'assistant de création de personnage : scores de
/// caractéristiques (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 3 point 4, maquette `05_étape_4_caractéristiques.png`).
///
/// Contrairement aux étapes 1 à 3 (choix simples dans une liste), cette
/// étape porte de la vraie logique de règles D&D 5e — voir
/// `domain/ability_score_rules.dart` pour le détail des 3 méthodes
/// (Tableau standard/Achat par points/Dés) et
/// `domain/ability_score_modifier_calculator.dart` pour le calcul du
/// modificateur affiché (bonus racial/sous-racial inclus).
///
/// Aucune validation bloquante ici : "Suivant" est toujours actif, un jeu de
/// 6 scores est toujours valide quelle que soit la méthode (contrairement à
/// Race/Classe/Historique, qui bloquent tant que rien n'est choisi).
///
/// En-tête bois plein dupliqué depuis `background_step_screen.dart`
/// (`_Header` ci-dessous) — même principe que les étapes précédentes, pour
/// ne pas coupler les étapes entre elles.
class AbilityScoreStepScreen extends ConsumerStatefulWidget {
  const AbilityScoreStepScreen({super.key});

  @override
  ConsumerState<AbilityScoreStepScreen> createState() =>
      _AbilityScoreStepScreenState();
}

class _AbilityScoreStepScreenState
    extends ConsumerState<AbilityScoreStepScreen> {
  static const int _totalSteps = 9;

  late AbilityScoreMethod _method;
  late Map<String, int> _scores;
  int? _raceId;
  int? _subraceId;

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — même rationale que
    // `RaceStepScreen`/`ClassStepScreen`/`BackgroundStepScreen`. Si le
    // brouillon n'a encore ni méthode ni scores (première visite), repart
    // sur la méthode "Tableau standard" avec son assignation par défaut.
    final draft = ref.read(characterCreationDraftControllerProvider);
    _raceId = draft.raceId;
    _subraceId = draft.subraceId;
    final draftMethod = draft.abilityScoreMethod;
    final draftScores = draft.abilityScores;
    if (draftMethod != null && draftScores != null) {
      _method = draftMethod;
      _scores = draftScores;
    } else {
      _method = AbilityScoreMethod.standardArray;
      _scores = AbilityScoreRules.defaultScoresFor(_method);
    }
  }

  /// Change de méthode et repart sur une base cohérente avec elle plutôt
  /// que de conserver les scores de l'ancienne méthode (ex. un score de 18
  /// obtenu aux dés n'est pas atteignable au Tableau standard, qui plafonne
  /// à 15) — voir `AbilityScoreRules.defaultScoresFor`.
  void _selectMethod(AbilityScoreMethod method) {
    if (method == _method) return;
    setState(() {
      _method = method;
      _scores = AbilityScoreRules.defaultScoresFor(method);
    });
  }

  /// Relance les 6 dés (méthode "Dés" uniquement), et réinitialise
  /// l'assignation aux caractéristiques.
  void _rerollDice() {
    setState(() {
      _scores = AbilityScoreRules.rollDiceScores();
    });
  }

  bool _canIncrement(String key) {
    return switch (_method) {
      AbilityScoreMethod.standardArray ||
      AbilityScoreMethod.diceRoll => AbilityScoreRules.canSwapUp(_scores, key),
      AbilityScoreMethod.pointBuy => AbilityScoreRules.canIncrementPointBuy(
        _scores,
        key,
      ),
    };
  }

  bool _canDecrement(String key) {
    return switch (_method) {
      AbilityScoreMethod.standardArray || AbilityScoreMethod.diceRoll =>
        AbilityScoreRules.canSwapDown(_scores, key),
      AbilityScoreMethod.pointBuy => AbilityScoreRules.canDecrementPointBuy(
        _scores,
        key,
      ),
    };
  }

  void _increment(String key) {
    setState(() {
      _scores = switch (_method) {
        AbilityScoreMethod.standardArray ||
        AbilityScoreMethod.diceRoll => AbilityScoreRules.swapUp(_scores, key),
        AbilityScoreMethod.pointBuy => AbilityScoreRules.incrementPointBuy(
          _scores,
          key,
        ),
      };
    });
  }

  void _decrement(String key) {
    setState(() {
      _scores = switch (_method) {
        AbilityScoreMethod.standardArray ||
        AbilityScoreMethod.diceRoll => AbilityScoreRules.swapDown(_scores, key),
        AbilityScoreMethod.pointBuy => AbilityScoreRules.decrementPointBuy(
          _scores,
          key,
        ),
      };
    });
  }

  /// Toujours poussée depuis `/characters/new/step-3` (étape 3 "Historique")
  /// via `context.push` : `pop()` suffit, même rationale que
  /// `BackgroundStepScreen._goBack`.
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que les étapes précédentes. Toujours
  /// actif : pas de validation bloquante sur cette étape (voir la
  /// documentation de la classe).
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setAbilityScores(method: _method, scores: _scores);
    context.push('/characters/new/step-5');
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(raceCatalogProvider);

    return Scaffold(
      body: catalogAsync.when(
        data: _buildContent,
        loading: () => Column(
          children: [
            _MinimalHeader(onBack: _goBack),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          children: [
            _MinimalHeader(onBack: _goBack),
            Expanded(
              child: _ErrorState(
                message: error is CharacterCreationFailure
                    ? error.message
                    : 'Impossible de charger les bonus raciaux. Réessayez.',
                onRetry: () => ref.invalidate(raceCatalogProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RaceCatalog catalog) {
    return Column(
      children: [
        _Header(onBack: _goBack, currentStep: 4, totalSteps: _totalSteps),
        Expanded(
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedToggle<AbilityScoreMethod>(
                        options: const [
                          SegmentedToggleOption(
                            value: AbilityScoreMethod.standardArray,
                            label: 'Tableau',
                          ),
                          SegmentedToggleOption(
                            value: AbilityScoreMethod.pointBuy,
                            label: 'Points',
                          ),
                          SegmentedToggleOption(
                            value: AbilityScoreMethod.diceRoll,
                            label: 'Dés',
                          ),
                        ],
                        value: _method,
                        onChanged: _selectMethod,
                      ),
                      if (_method == AbilityScoreMethod.pointBuy) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Points restants : '
                          '${AbilityScoreRules.pointBuyRemaining(_scores)}'
                          '/${AbilityScoreRules.pointBuyBudget}',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (_method == AbilityScoreMethod.diceRoll) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _rerollDice,
                            child: Text(
                              'Relancer les dés',
                              style: AppTypography.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: [
                      for (
                        var i = 0;
                        i < abilityScoreDefinitions.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        _AbilityRow(
                          definition: abilityScoreDefinitions[i],
                          score: _scores[abilityScoreDefinitions[i].key]!,
                          modifier: AbilityScoreModifierCalculator.modifierFor(
                            baseScore: _scores[abilityScoreDefinitions[i].key]!,
                            racialBonus:
                                AbilityScoreModifierCalculator.racialBonusFor(
                                  abilityKey: abilityScoreDefinitions[i].key,
                                  catalog: catalog,
                                  raceId: _raceId,
                                  subraceId: _subraceId,
                                ),
                          ),
                          canIncrement: _canIncrement(
                            abilityScoreDefinitions[i].key,
                          ),
                          canDecrement: _canDecrement(
                            abilityScoreDefinitions[i].key,
                          ),
                          onIncrement: () =>
                              _increment(abilityScoreDefinitions[i].key),
                          onDecrement: () =>
                              _decrement(abilityScoreDefinitions[i].key),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Retour',
                          surface: SecondaryButtonSurface.parchment,
                          onPressed: _goBack,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Suivant',
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Une ligne de caractéristique : badge coloré, nom + modificateur, compteur
/// +/- (maquette `05_étape_4_caractéristiques.png`).
class _AbilityRow extends StatelessWidget {
  const _AbilityRow({
    required this.definition,
    required this.score,
    required this.modifier,
    required this.canIncrement,
    required this.canDecrement,
    required this.onIncrement,
    required this.onDecrement,
  });

  final AbilityScoreDefinition definition;
  final int score;
  final int modifier;
  final bool canIncrement;
  final bool canDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        children: [
          AccentIconBadge(icon: definition.icon, color: definition.accentColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  definition.label.toUpperCase(),
                  style: AppTypography.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Modificateur $modifierText',
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StepperCounter(
            value: score,
            onIncrement: canIncrement ? onIncrement : null,
            onDecrement: canDecrement ? onDecrement : null,
          ),
        ],
      ),
    );
  }
}

/// Bandeau bois plein en tête d'écran, avec le titre d'étape et la barre de
/// progression — copié depuis `equipment_step_screen.dart`/
/// `summary_step_screen.dart` (voir la documentation de classe de
/// [AbilityScoreStepScreen]).
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textOnWood,
                      ),
                    ),
                    Text(
                      'CRÉATION',
                      style: AppTypography.display(
                        fontSize: 11,
                        color: AppColors.textOnWood,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '4. Caractéristiques',
                          style: AppTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnWood,
                          ),
                        ),
                        Text(
                          'Étape $currentStep / $totalSteps',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.textOnWoodMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StepProgressBar(
                      totalSteps: totalSteps,
                      currentStep: currentStep,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau bois minimal (retour + "CRÉATION" uniquement), affiché pendant le
/// chargement/l'erreur — copie exacte du pattern des étapes 6/7/9.
class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textOnWood,
                ),
              ),
              Text(
                'CRÉATION',
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textOnWood,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
