import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/gain_row.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../domain/character_failure.dart';
import '../domain/level_up_chain_resolver.dart';
import '../domain/level_up_hit_points_calculator.dart';
import '../domain/signed_modifier_formatter.dart';
import 'providers/character_detail_provider.dart';
import 'providers/character_providers.dart';
import 'providers/level_up_provider.dart';
import 'widgets/level_up_header.dart';

enum _HpMethod { roll, average }

enum _LevelUpPhase { hitPoints, abilities, summary }

/// Flux "Montée de niveau" — increment 1
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 6,
/// spec visuelle direction-artistique complète). Couvre uniquement les
/// niveaux qui ne nécessitent aucun choix du joueur : étapes "Points de
/// vie" et "Aptitudes de classe automatiques", puis récapitulatif. Un
/// niveau qui nécessite un choix (voir `domain/level_up_block_reason.dart`)
/// bloque le flux avant l'étape "Points de vie", au lieu de l'ignorer
/// silencieusement.
///
/// Un seul écran (pas une route par étape, contrairement à l'assistant de
/// création) : les 4 "vues" du flux (points de vie/aptitudes/récapitulatif/
/// blocage) sont de simples changements de contenu à l'intérieur du même
/// widget, piloté par [_LevelUpPhase] — plus simple à orchestrer ici que des
/// routes distinctes, puisque le chaînage multi-niveaux doit pouvoir revenir
/// à l'étape "Points de vie" pour un *nouveau* niveau sans jamais repasser
/// par la navigation (voir [_LevelUpScreenState._continueFromSummary]).
///
/// Aucune écriture en base avant le tap "Continuer" du récapitulatif — voir
/// la documentation de `CharacterRepository.applyLevelUp`.
class LevelUpScreen extends ConsumerStatefulWidget {
  const LevelUpScreen({
    required this.characterId,
    required this.initialTargetLevel,
    super.key,
  });

  final String characterId;

  /// Niveau ciblé par le déclenchement initial (`currentLevel + 1`) — voir
  /// `character_detail_screen.dart` pour les 3 points de déclenchement
  /// (bouton "+" XP franchi, lien "Monter de niveau manuellement", bandeau
  /// "NIVEAU DISPONIBLE").
  final int initialTargetLevel;

  @override
  ConsumerState<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends ConsumerState<LevelUpScreen> {
  late int _targetLevel;
  _LevelUpPhase _phase = _LevelUpPhase.hitPoints;
  int _levelsAppliedThisSession = 0;

  _HpMethod _hpMethod = _HpMethod.roll;
  int? _rolledValue;
  int? _rolledForLevel;

  bool _isApplying = false;
  String? _applyError;

  @override
  void initState() {
    super.initState();
    _targetLevel = widget.initialTargetLevel;
  }

  void _goBackToSheet() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/characters/${widget.characterId}');
    }
  }

  /// Résultat du jet de dé pour [_targetLevel], calculé une seule fois par
  /// niveau ("déjà résolu au montage", spec visuelle) : simple mutation de
  /// champ (pas de `setState`) — sûr à appeler depuis `build()`, contrairement
  /// à un appel à `setState` qui y serait interdit. [_reroll] reste le seul
  /// point d'entrée qui déclenche un vrai rebuild (lien "Relancer le dé").
  int _ensureRolled(int hitDie) {
    if (_rolledForLevel != _targetLevel) {
      _rolledValue = LevelUpHitPointsCalculator.rollHitDie(hitDie);
      _rolledForLevel = _targetLevel;
    }
    return _rolledValue!;
  }

  void _reroll(int hitDie) {
    setState(() {
      _rolledValue = LevelUpHitPointsCalculator.rollHitDie(hitDie);
      _rolledForLevel = _targetLevel;
    });
  }

  int _hpRolledValue(int hitDie) {
    return _hpMethod == _HpMethod.roll
        ? _ensureRolled(hitDie)
        : LevelUpHitPointsCalculator.averageValue(hitDie);
  }

  int _hpGain({required int hitDie, required int constitutionModifier}) {
    return LevelUpHitPointsCalculator.hpGain(
      rolledOrAverageValue: _hpRolledValue(hitDie),
      constitutionModifier: constitutionModifier,
    );
  }

  String? _remainingLevelsLabel(int currentXp) {
    final remaining = LevelUpChainResolver.remainingLevelsAfter(
      targetLevel: _targetLevel,
      currentXp: currentXp,
    );
    if (remaining <= 0) return null;
    return 'Encore $remaining niveau${remaining > 1 ? 'x' : ''} à valider '
        'ensuite';
  }

  Future<void> _continueFromSummary(LevelUpStepData data) async {
    if (_isApplying) return;
    setState(() {
      _isApplying = true;
      _applyError = null;
    });

    final repository = ref.read(characterRepositoryProvider);
    final hpRolled = _hpRolledValue(data.hitDie);
    final hpGain = _hpGain(
      hitDie: data.hitDie,
      constitutionModifier: data.constitutionModifier,
    );
    final hpMethod = _hpMethod == _HpMethod.roll ? 'lance' : 'moyenne';

    try {
      final result = await repository.applyLevelUp(
        characterId: widget.characterId,
        hpRolled: hpRolled,
        hpMethod: hpMethod,
        hpGain: hpGain,
      );

      ref.invalidate(characterDetailProvider(widget.characterId));
      _levelsAppliedThisSession++;

      final hasMore = LevelUpChainResolver.hasNextLevelAlreadyUnlocked(
        targetLevel: result.newLevel,
        currentXp: data.currentXp,
      );

      if (!mounted) return;

      if (!hasMore) {
        _goBackToSheet();
        return;
      }

      // Enchaîne directement sur le niveau suivant : `_buildData` (voir
      // `build()`) revérifiera automatiquement le blocage de ce nouveau
      // niveau une fois les données rechargées — pas besoin de le
      // pré-vérifier ici, `blockReason` fait déjà partie de [LevelUpStepData].
      setState(() {
        _targetLevel = result.newLevel + 1;
        _phase = _LevelUpPhase.hitPoints;
        _hpMethod = _HpMethod.roll;
        _isApplying = false;
      });
    } on CharacterFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isApplying = false;
        _applyError = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isApplying = false;
        _applyError =
            "Impossible d'enregistrer la montée de niveau. Réessayez.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(
      levelUpStepDataProvider(
        characterId: widget.characterId,
        targetLevel: _targetLevel,
      ),
    );

    return SceneScaffold(
      body: SafeArea(
        child: dataAsync.when(
          data: _buildData,
          loading: () => Column(
            children: [
              const LevelUpHeader(eyebrow: 'MONTÉE DE NIVEAU'),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.goldEnd),
                ),
              ),
            ],
          ),
          error: (error, stackTrace) => Column(
            children: [
              const LevelUpHeader(eyebrow: 'MONTÉE DE NIVEAU'),
              Expanded(
                child: _ErrorState(
                  message: error is CharacterFailure
                      ? error.message
                      : 'Impossible de charger les données de montée de '
                            'niveau. Réessayez.',
                  // Invalide `characterDetailProvider` *aussi*, pas
                  // seulement `levelUpStepDataProvider` — même bug déjà
                  // corrigé sur les écrans combinateurs de l'assistant de
                  // création (voir `summary_step_screen.dart`) : invalider
                  // seulement le provider combiné ne force pas un nouvel
                  // appel réseau sur le provider feuille qui a échoué.
                  onRetry: () {
                    ref.invalidate(characterDetailProvider(widget.characterId));
                    ref.invalidate(
                      levelUpStepDataProvider(
                        characterId: widget.characterId,
                        targetLevel: _targetLevel,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildData(LevelUpStepData data) {
    if (data.blockReason != null) {
      return _buildBlocked(data);
    }
    return switch (_phase) {
      _LevelUpPhase.hitPoints => _buildHpStep(data),
      _LevelUpPhase.abilities => _buildAbilitiesStep(data),
      _LevelUpPhase.summary => _buildSummary(data),
    };
  }

  Widget _buildHpStep(LevelUpStepData data) {
    final hpRolled = _hpRolledValue(data.hitDie);
    final gain = _hpGain(
      hitDie: data.hitDie,
      constitutionModifier: data.constitutionModifier,
    );
    final newMaxHp = data.currentMaxHp + gain;
    final modText = SignedModifierFormatter.format(data.constitutionModifier);

    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
          stepLabel: 'Étape 1 sur 3 · Points de vie',
          remainingLevelsLabel: _remainingLevelsLabel(data.currentXp),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ParchmentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AccentIconBadge(
                        icon: Icons.favorite,
                        color: AppColors.accentBrick,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Points de vie',
                              style: AppTypography.body(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Dé de vie de la classe : d${data.hitDie}',
                              style: AppTypography.body(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedToggle<_HpMethod>(
                    options: const [
                      SegmentedToggleOption(
                        value: _HpMethod.roll,
                        label: 'Lancer le dé',
                      ),
                      SegmentedToggleOption(
                        value: _HpMethod.average,
                        label: 'Valeur moyenne',
                      ),
                    ],
                    value: _hpMethod,
                    onChanged: (method) => setState(() => _hpMethod = method),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$hpRolled',
                          style: AppTypography.body(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$modText modificateur de Constitution',
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (_hpMethod == _HpMethod.roll)
                          InkWell(
                            onTap: () => _reroll(data.hitDie),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: Center(
                                child: Text(
                                  'Relancer le dé',
                                  style: AppTypography.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Text(
                            '(moitié du dé arrondie au supérieur, +1)',
                            style: AppTypography.body(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Séparateur 1px `#E0D2AB` (spec visuelle) : coïncide avec
                  // `AppColors.gaugeTrack`, réutilisé ici pour un simple
                  // filet de séparation plutôt qu'une jauge.
                  Container(height: 1, color: AppColors.gaugeTrack),
                  const SizedBox(height: AppSpacing.md),
                  GainRow(
                    icon: Icons.favorite,
                    color: AppColors.accentBrick,
                    title: 'Points de vie maximum',
                    subtitle: '${data.currentMaxHp} → $newMaxHp (+$gain)',
                  ),
                ],
              ),
            ),
          ),
        ),
        _StepFooter(
          onBack: _goBackToSheet,
          onContinue: () => setState(() => _phase = _LevelUpPhase.abilities),
        ),
      ],
    );
  }

  Widget _buildAbilitiesStep(LevelUpStepData data) {
    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
          stepLabel: 'Étape 2 sur 3 · Aptitudes de classe',
          remainingLevelsLabel: _remainingLevelsLabel(data.currentXp),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ParchmentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vous obtenez automatiquement :',
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (data.automaticFeatures.isEmpty)
                    const _EmptyFeaturesState()
                  else
                    for (var i = 0; i < data.automaticFeatures.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      GainRow(
                        icon: Icons.star,
                        color: AppColors.accentTeal,
                        title: 'Nouvelle aptitude',
                        subtitle: data.automaticFeatures[i].name,
                      ),
                    ],
                ],
              ),
            ),
          ),
        ),
        _StepFooter(
          onBack: () => setState(() => _phase = _LevelUpPhase.hitPoints),
          onContinue: () => setState(() => _phase = _LevelUpPhase.summary),
        ),
      ],
    );
  }

  Widget _buildSummary(LevelUpStepData data) {
    final gain = _hpGain(
      hitDie: data.hitDie,
      constitutionModifier: data.constitutionModifier,
    );
    final newMaxHp = data.currentMaxHp + gain;

    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _ParchmentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GainRow(
                        icon: Icons.favorite,
                        color: AppColors.accentBrick,
                        title: 'Points de vie maximum',
                        subtitle: '${data.currentMaxHp} → $newMaxHp (+$gain)',
                      ),
                      for (final feature in data.automaticFeatures) ...[
                        const SizedBox(height: AppSpacing.md),
                        GainRow(
                          icon: Icons.star,
                          color: AppColors.accentTeal,
                          title: 'Nouvelle aptitude',
                          subtitle: feature.name,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_applyError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _AlertBanner(message: _applyError!),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PrimaryButton(
            label: 'Continuer',
            isLoading: _isApplying,
            onPressed: _isApplying ? null : () => _continueFromSummary(data),
          ),
        ),
      ],
    );
  }

  Widget _buildBlocked(LevelUpStepData data) {
    final isImmediate = _levelsAppliedThisSession == 0;
    return Column(
      children: [
        LevelUpHeader(
          eyebrow: isImmediate ? 'MONTÉE DE NIVEAU' : 'NIVEAU ATTEINT',
          levelLabel: isImmediate ? null : 'NIVEAU ${_targetLevel - 1}',
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _ParchmentCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: AppColors.accentBrick,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Niveau $_targetLevel : choix requis',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ce niveau nécessite un choix pas encore disponible '
                      "dans l'app.",
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      data.blockReason!.detail,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PrimaryButton(
            label: 'Retour à la fiche',
            onPressed: _goBackToSheet,
          ),
        ),
      ],
    );
  }
}

/// Carte parchemin générique du flux "Montée de niveau" — même style que
/// `AppColors.parchmentCard`/`AppRadius.md`/`AppColors.woodLight` réutilisé
/// partout ailleurs dans le dépôt (voir ex. `_AbilityRow` de
/// `ability_score_step_screen.dart`), dupliquée en privé ici plutôt que
/// promue en composant partagé (aucun autre écran n'a encore besoin de ce
/// gabarit "carte pleine largeur, padding md" exact).
class _ParchmentCard extends StatelessWidget {
  const _ParchmentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: child,
    );
  }
}

/// État vide de l'étape "Aptitudes de classe automatiques" (cas le plus
/// fréquent) — patron `_EmptyState` de `equipment_step_screen.dart`
/// transposé (spec visuelle).
class _EmptyFeaturesState extends StatelessWidget {
  const _EmptyFeaturesState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.star_border, size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Aucune nouvelle aptitude de classe à ce niveau.',
            textAlign: TextAlign.center,
            style: AppTypography.body(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Footer `Row[SecondaryButton("Retour", surface: scene), PrimaryButton
/// ("Continuer")]` des étapes 1 et 2 — spec visuelle section 0.
class _StepFooter extends StatelessWidget {
  const _StepFooter({required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(label: 'Retour', onPressed: onBack),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: PrimaryButton(label: 'Continuer', onPressed: onContinue),
          ),
        ],
      ),
    );
  }
}

/// "Bandeau d'alerte inline" du design système, dupliqué depuis
/// `equipment_step_screen.dart`/`summary_step_screen.dart` (privé à chaque
/// écran, non réutilisable tel quel) — même rationale de duplication que le
/// reste de ce dépôt.
class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.accentBrick,
          width: AppBorders.card,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentBrick,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte parchemin d'état d'erreur — patron `_ErrorState` standard,
/// hébergé dans une carte parchemin plutôt que flottant nu sur le fond bois
/// (spec visuelle section 0, "Règle de contenu").
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _ParchmentCard(
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
              SecondaryButton(
                label: 'Réessayer',
                surface: SecondaryButtonSurface.parchment,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
