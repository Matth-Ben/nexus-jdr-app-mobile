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
import '../../../core/widgets/selectable_option_tile.dart';
import '../../../core/widgets/stepper_counter.dart';
import '../../character_creation/domain/ability_score_definitions.dart';
import '../domain/character_failure.dart';
import '../domain/level_up_chain_resolver.dart';
import '../domain/level_up_choice_kind.dart';
import '../domain/level_up_choice_options.dart';
import '../domain/level_up_choice_selection.dart';
import '../domain/level_up_hit_points_calculator.dart';
import '../domain/signed_modifier_formatter.dart';
import '../domain/spell_slot_change.dart';
import 'providers/character_detail_provider.dart';
import 'providers/character_providers.dart';
import 'providers/level_up_provider.dart';
import 'widgets/level_up_header.dart';

enum _HpMethod { roll, average }

enum _LevelUpPhase { announcement, hitPoints, abilities, choice, spells, summary }

/// Budget de points de l'étape "Choix à faire", variante amélioration de
/// caractéristique (règle 5e standard : "+2 sur une caractéristique" OU
/// "+1/+1 sur deux", jamais l'alternative "don" — voir la documentation de
/// `domain/level_up_choice_kind.dart::LevelUpChoiceKind.abilityScoreImprovement`).
const int _abilityScoreImprovementBudget = 2;

/// Flux "Montée de niveau"
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 6,
/// spec visuelle direction-artistique complète). Étapes "Points de vie" et
/// "Aptitudes de classe automatiques" (increment 1), "Choix à faire"
/// (increment 2, uniquement quand le niveau ciblé le déclenche — voir
/// [LevelUpChoiceKind]), "Sorts" (increment 3, uniquement quand le
/// recalcul des emplacements de sorts change quelque chose à ce niveau —
/// voir [LevelUpStepData.spellSlotChanges]), puis récapitulatif. Un niveau
/// qui nécessite un choix non couvert (voir `domain/level_up_block_reason.dart`)
/// bloque le flux avant l'étape "Points de vie", au lieu de l'ignorer
/// silencieusement.
///
/// Un seul écran (pas une route par étape, contrairement à l'assistant de
/// création) : les 7 "vues" du flux (annonce/points de vie/aptitudes/choix/
/// sorts/récapitulatif/blocage) sont de simples changements de contenu à
/// l'intérieur du même widget, piloté par [_LevelUpPhase] — plus simple à
/// orchestrer ici que des routes distinctes, puisque le chaînage
/// multi-niveaux doit pouvoir revenir à l'étape "Points de vie" pour un
/// *nouveau* niveau sans jamais repasser par la navigation (voir
/// [_LevelUpScreenState._continueFromSummary]).
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
  _LevelUpPhase _phase = _LevelUpPhase.announcement;

  /// Nombre de niveaux réellement sauvegardés (écriture en base réussie)
  /// depuis l'ouverture de l'écran — permet à [_buildBlocked] de distinguer
  /// un blocage immédiat (premier niveau de la session) d'un blocage après
  /// un ou plusieurs niveaux du chaînage déjà validés (voir sa
  /// documentation).
  int _levelsAppliedThisSession = 0;

  _HpMethod _hpMethod = _HpMethod.roll;
  int? _rolledValue;
  int? _rolledForLevel;

  // État de l'étape "Choix à faire" (increment 2). Un seul jeu de champs
  // pour les 3 variantes "liste" (sous-classe/style de combat/ennemi juré) :
  // jamais simultanées pour un même niveau (voir
  // `domain/level_up_choice_kind.dart::LevelUpChoiceKind`, un seul
  // `LevelUpChoiceKind` par niveau). [_selectedListOptionId] porte
  // l'`Object` sélectionné (un `subclasses.id` pour la sous-classe, la
  // chaîne elle-même pour style de combat/ennemi juré, voir
  // `domain/level_up_choice_options.dart`).
  Object? _selectedListOptionId;

  /// Points alloués par caractéristique (0 à 2, clé
  /// `ability_score_definitions.dart`), variante amélioration de
  /// caractéristique — seules les entrées non nulles compteront pour
  /// `LevelUpChoiceSelection.abilityAllocations` au moment d'appliquer
  /// (voir [_buildChoiceSelection]). `null` tant que l'étape "Choix à faire"
  /// n'a pas encore été construite pour le niveau courant (voir
  /// [_ensureAbilityAllocationsInitialized]).
  Map<String, int>? _abilityAllocations;

  bool _isApplying = false;
  String? _applyError;

  @override
  void initState() {
    super.initState();
    _targetLevel = widget.initialTargetLevel;
  }

  /// Remet à zéro l'état de l'étape "Choix à faire" — appelé au chaînage
  /// vers un nouveau niveau (même rationale que la réinitialisation de
  /// `_hpMethod` dans [_continueFromSummary] : chaque niveau du chaînage
  /// repart d'un état de saisie vierge).
  void _resetChoiceState() {
    _selectedListOptionId = null;
    _abilityAllocations = null;
  }

  /// Initialise [_abilityAllocations] à 0 pour les 6 caractéristiques, une
  /// seule fois par niveau — appelée depuis `build()` (mutation de champ
  /// sans `setState`, même précédent que [_ensureRolled] ci-dessous : sûr
  /// tant qu'aucun rebuild n'est requis pour ce seul effet de bord).
  Map<String, int> _ensureAbilityAllocationsInitialized() {
    return _abilityAllocations ??= {
      for (final definition in abilityScoreDefinitions) definition.key: 0,
    };
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

  /// Construit le [LevelUpChoiceSelection] à envoyer à `applyLevelUp` depuis
  /// l'état de saisie de l'étape "Choix à faire", `null` si [data] n'en
  /// déclenchait aucun à ce niveau (comportement de l'increment 1,
  /// inchangé). Appelée seulement au moment d'appliquer (récapitulatif),
  /// jamais pendant la saisie — la validité de la sélection est déjà
  /// garantie à ce stade par le bouton "Continuer" désactivé de l'étape
  /// "Choix à faire" (voir [_canContinueChoiceStep]).
  LevelUpChoiceSelection? _buildChoiceSelection(LevelUpStepData data) {
    return switch (data.choiceKind) {
      null => null,
      LevelUpChoiceKind.abilityScoreImprovement =>
        LevelUpChoiceSelection.abilityScoreImprovement({
          for (final entry in _ensureAbilityAllocationsInitialized().entries)
            if (entry.value > 0) entry.key: entry.value,
        }),
      LevelUpChoiceKind.subclass => LevelUpChoiceSelection.subclass(
        _selectedListOptionId!,
      ),
      LevelUpChoiceKind.fightingStyle => LevelUpChoiceSelection.fightingStyle(
        classFeatureId: data.choiceClassFeatureId!,
        chosenValue: _selectedListOptionId! as String,
      ),
      LevelUpChoiceKind.favoredEnemy => LevelUpChoiceSelection.favoredEnemy(
        classFeatureId: data.choiceClassFeatureId!,
        chosenValue: _selectedListOptionId! as String,
      ),
    };
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
        className: data.className,
        hpRolled: hpRolled,
        hpMethod: hpMethod,
        hpGain: hpGain,
        choice: _buildChoiceSelection(data),
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
        _phase = _LevelUpPhase.announcement;
        _hpMethod = _HpMethod.roll;
        _resetChoiceState();
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
    // L'annonce passe *avant* la vérification de `blockReason` : le joueur a
    // atteint ce niveau indépendamment de la capacité de l'app à
    // l'accompagner sur l'étape suivante (spec visuelle direction-artistique,
    // "Montée de niveau (style scène)").
    if (_phase == _LevelUpPhase.announcement) {
      return _buildAnnouncement(data);
    }
    if (data.blockReason != null) {
      return _buildBlocked(data);
    }
    return switch (_phase) {
      _LevelUpPhase.announcement => _buildAnnouncement(data),
      _LevelUpPhase.hitPoints => _buildHpStep(data),
      _LevelUpPhase.abilities => _buildAbilitiesStep(data),
      _LevelUpPhase.choice => _buildChoiceStep(data),
      _LevelUpPhase.spells => _buildSpellsStep(data),
      _LevelUpPhase.summary => _buildSummary(data),
    };
  }

  /// Annonce affichée avant les étapes de chaque niveau du chaînage
  /// ("Vous passez au niveau N !", résumé de ce qui est gagné) — spec
  /// visuelle direction-artistique, "Montée de niveau (style scène)" :
  /// header (icône bouclier déjà intégrée à [LevelUpHeader]) suivi
  /// directement de la carte parchemin, sans sous-titre ni icône
  /// supplémentaire entre les deux.
  ///
  /// a) Aptitudes de classe automatiques : détail complet, gains purs déjà
  /// calculés — même [GainRow]/état vide que l'étape "Aptitudes".
  /// b) Étapes à venir (Choix/Sorts) : simple teaser de présence, jamais de
  /// résultat — voir [_UpcomingStepRow].
  /// c) Points de vie : volontairement absent, le gain dépend d'un choix
  /// (jet/moyenne) pas encore fait à ce stade.
  Widget _buildAnnouncement(LevelUpStepData data) {
    // `blockReason` prime sur `choiceKind`/`spellSlotChanges` : ces deux
    // champs sont calculés indépendamment du blocage (voir
    // `level_up_provider.dart`), et peuvent donc être non nuls/non vides
    // pour un niveau qui va justement bloquer juste après cette annonce —
    // auquel cas l'étape correspondante ne sera jamais atteinte cette
    // session (l'écran de blocage qui suit gère déjà la communication de ce
    // cas, voir [_buildBlocked]).
    final hasUpcoming =
        data.blockReason == null &&
        (data.choiceKind != null || data.spellSlotChanges.isNotEmpty);

    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
          remainingLevelsLabel: _remainingLevelsLabel(data.currentXp),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ParchmentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.automaticFeatures.isEmpty)
                    const _EmptyFeaturesState()
                  else
                    for (
                      var i = 0;
                      i < data.automaticFeatures.length;
                      i++
                    ) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      GainRow(
                        icon: Icons.star,
                        color: AppColors.accentTeal,
                        title: 'Nouvelle aptitude',
                        subtitle: data.automaticFeatures[i].name,
                      ),
                    ],
                  if (hasUpcoming) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'À venir dans les prochaines étapes',
                      style: AppTypography.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (data.choiceKind != null) ...[
                      _UpcomingStepRow(
                        icon: Icons.checklist,
                        color: AppColors.accentBlue,
                        label:
                            'Un choix de '
                            '${_choiceStepLabel(data.choiceKind!)} '
                            'vous attendra',
                      ),
                      if (data.spellSlotChanges.isNotEmpty)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                    if (data.spellSlotChanges.isNotEmpty)
                      const _UpcomingStepRow(
                        icon: Icons.auto_awesome,
                        color: AppColors.accentViolet,
                        label: 'Vos emplacements de sorts vont évoluer',
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PrimaryButton(
            label: 'Continuer',
            // `blockReason` n'est volontairement pas testé ici : le
            // prochain `_buildData` s'en charge une fois `_phase` sorti de
            // `announcement` (voir la documentation ci-dessus).
            onPressed: () => setState(() => _phase = _LevelUpPhase.hitPoints),
          ),
        ),
      ],
    );
  }

  /// 3, 4 ou 5 selon les étapes déclenchées à ce niveau — spec visuelle
  /// direction-artistique section 1 (étape "Sorts", increment 3) :
  /// [LevelUpStepData.choiceKind] non nul ajoute l'étape "Choix à faire"
  /// (increment 2, inchangé), [LevelUpStepData.spellSlotChanges] non vide
  /// ajoute l'étape "Sorts".
  int _totalSteps(LevelUpStepData data) =>
      3 +
      (data.choiceKind != null ? 1 : 0) +
      (data.spellSlotChanges.isNotEmpty ? 1 : 0);

  /// Étape suivante une fois "Aptitudes"/"Choix à faire" franchies : l'étape
  /// "Sorts" si ce niveau déclenche un changement d'emplacements
  /// (increment 3), le récapitulatif sinon — même logique de chaînage
  /// conditionnel que [LevelUpChoiceKind] pour l'étape "Choix à faire".
  /// Couvre aussi le cas défensif "condition d'affichage vraie mais 0
  /// changement calculé" (spec visuelle direction-artistique section 4) :
  /// ce cas ne devrait jamais se produire en pratique (voir
  /// `domain/spell_slot_progression.dart::SpellSlotProgression.changesFor`),
  /// mais une liste vide retombe naturellement ici sur le récapitulatif,
  /// sans code dédié supplémentaire.
  _LevelUpPhase _phaseAfterChoiceOrAbilities(LevelUpStepData data) =>
      data.spellSlotChanges.isNotEmpty
      ? _LevelUpPhase.spells
      : _LevelUpPhase.summary;

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
          stepLabel: 'Étape 1 sur ${_totalSteps(data)} · Points de vie',
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
          stepLabel: 'Étape 2 sur ${_totalSteps(data)} · Aptitudes de classe',
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
          onContinue: () => setState(() {
            _phase = data.choiceKind != null
                ? _LevelUpPhase.choice
                : _phaseAfterChoiceOrAbilities(data);
          }),
        ),
      ],
    );
  }

  /// Étape "Choix à faire" (increment 2), affichée uniquement quand
  /// [LevelUpStepData.choiceKind] est non nul — voir [_totalSteps].
  Widget _buildChoiceStep(LevelUpStepData data) {
    final kind = data.choiceKind!;

    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
          stepLabel:
              'Étape 3 sur ${_totalSteps(data)} · ${_choiceStepLabel(kind)}',
          remainingLevelsLabel: _remainingLevelsLabel(data.currentXp),
        ),
        Expanded(child: _buildChoiceBody(data, kind)),
        _StepFooter(
          onBack: () => setState(() => _phase = _LevelUpPhase.abilities),
          onContinue: _canContinueChoiceStep(data, kind)
              ? () =>
                    setState(() => _phase = _phaseAfterChoiceOrAbilities(data))
              : null,
        ),
      ],
    );
  }

  /// Libellé court de [stepLabel] pour l'étape "Choix à faire" — neufs,
  /// volontairement distincts de `ClassFeatureChoiceLabelFormatter` (pensé
  /// pour le contexte de blocage, voir sa documentation).
  String _choiceStepLabel(LevelUpChoiceKind kind) {
    return switch (kind) {
      LevelUpChoiceKind.abilityScoreImprovement =>
        'Amélioration de caractéristique',
      LevelUpChoiceKind.subclass => 'Sous-classe',
      LevelUpChoiceKind.fightingStyle => 'Style de combat',
      LevelUpChoiceKind.favoredEnemy => 'Ennemi juré',
    };
  }

  bool _canContinueChoiceStep(LevelUpStepData data, LevelUpChoiceKind kind) {
    if (kind == LevelUpChoiceKind.abilityScoreImprovement) {
      final allocations = _ensureAbilityAllocationsInitialized();
      final spent = allocations.values.fold(0, (sum, value) => sum + value);
      return spent == _abilityScoreImprovementBudget;
    }
    // Variante liste (sous-classe/style de combat/ennemi juré) : `null`
    // par défaut sur une liste vide (état vide, cas défensif) — jamais
    // sélectionnable, "Continuer" reste donc désactivé sans cas particulier
    // à gérer ici.
    return _selectedListOptionId != null;
  }

  Widget _buildChoiceBody(LevelUpStepData data, LevelUpChoiceKind kind) {
    return switch (kind) {
      LevelUpChoiceKind.abilityScoreImprovement => _buildAbilityAllocationBody(
        data,
      ),
      LevelUpChoiceKind.subclass => _buildOptionListBody(
        instruction: 'Choisissez une sous-classe.',
        icon: Icons.auto_awesome,
        options: [
          for (final subclass in data.availableSubclasses)
            (
              id: subclass.id,
              title: subclass.name,
              subtitle: (subclass.description?.isNotEmpty ?? false)
                  ? subclass.description
                  : null,
            ),
        ],
      ),
      LevelUpChoiceKind.fightingStyle => _buildOptionListBody(
        instruction: 'Choisissez un style de combat.',
        icon: Icons.security,
        options: [
          for (final style in LevelUpChoiceOptions.fightingStyles)
            (id: style, title: style, subtitle: null),
        ],
      ),
      LevelUpChoiceKind.favoredEnemy => _buildOptionListBody(
        instruction: 'Choisissez un ennemi juré.',
        icon: Icons.gps_fixed,
        options: [
          for (final enemy in LevelUpChoiceOptions.favoredEnemies)
            (id: enemy, title: enemy, subtitle: null),
        ],
      ),
    };
  }

  /// Variante liste (sous-classe/style de combat/ennemi juré) — pas de carte
  /// englobante (chaque [SelectableOptionTile] est déjà sa propre carte),
  /// sauf état vide (spec visuelle direction-artistique section 2).
  Widget _buildOptionListBody({
    required String instruction,
    required IconData icon,
    required List<({Object id, String title, String? subtitle})> options,
  }) {
    if (options.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: _ParchmentCard(child: _EmptyChoiceState()),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instruction,
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnWood,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            SelectableOptionTile(
              title: options[i].title,
              subtitle: options[i].subtitle,
              selected: _selectedListOptionId == options[i].id,
              onTap: () =>
                  setState(() => _selectedListOptionId = options[i].id),
              leading: AccentIconBadge(index: i, icon: icon),
            ),
          ],
        ],
      ),
    );
  }

  /// Variante allocation ASI — budget partagé de
  /// [_abilityScoreImprovementBudget] points entre les 6 caractéristiques.
  Widget _buildAbilityAllocationBody(LevelUpStepData data) {
    final allocations = _ensureAbilityAllocationsInitialized();
    final spent = allocations.values.fold(0, (sum, value) => sum + value);
    final remaining = _abilityScoreImprovementBudget - spent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartissez $_abilityScoreImprovementBudget points entre vos '
            'caractéristiques.',
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnWood,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            remaining > 0
                ? 'Points restants : $remaining/$_abilityScoreImprovementBudget'
                : 'Tous les points sont répartis.',
            style: AppTypography.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnWood,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < abilityScoreDefinitions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _buildAllocationRow(
              data: data,
              definition: abilityScoreDefinitions[i],
              allocations: allocations,
              remaining: remaining,
            ),
          ],
        ],
      ),
    );
  }

  /// Une ligne d'allocation ASI — factorisé hors de la boucle de
  /// [_buildAbilityAllocationBody] pour pouvoir déclarer des variables
  /// locales ([currentScore]/[alloc]/[atCap]) avant de construire le widget,
  /// ce qu'une simple expression de collection `for` ne permet pas.
  Widget _buildAllocationRow({
    required LevelUpStepData data,
    required AbilityScoreDefinition definition,
    required Map<String, int> allocations,
    required int remaining,
  }) {
    final key = definition.key;
    final currentScore = data.abilityScores[key] ?? 10;
    final alloc = allocations[key] ?? 0;
    // Plafond RAW 5e (score final ≤ 20), en plus du budget partagé de 2
    // points — voir aussi le filet de sécurité côté écriture
    // (`data/character_repository.dart::_applyAbilityScoreImprovement`),
    // cette garde UI ne doit pas être la seule ligne de défense.
    final atCap = currentScore + alloc + 1 > 20;
    return _AllocationRow(
      definition: definition,
      currentScore: currentScore,
      alloc: alloc,
      onIncrement: remaining == 0 || atCap
          ? null
          : () => setState(() => allocations[key] = alloc + 1),
      onDecrement: alloc == 0
          ? null
          : () => setState(() => allocations[key] = alloc - 1),
    );
  }

  /// Étape "Sorts" (increment 3), affichée uniquement quand
  /// [LevelUpStepData.spellSlotChanges] n'est pas vide — voir [_totalSteps]
  /// et [_phaseAfterChoiceOrAbilities]. Numérotation "Étape 3" si l'étape
  /// "Choix à faire" n'existait pas à ce niveau, "Étape 4" sinon (spec
  /// visuelle direction-artistique section 0) — toujours juste avant le
  /// récapitulatif.
  Widget _buildSpellsStep(LevelUpStepData data) {
    final stepNumber = data.choiceKind != null ? 4 : 3;

    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
          stepLabel:
              'Étape $stepNumber sur ${_totalSteps(data)} · '
              'Emplacements de sorts',
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
                    'Vos emplacements de sorts sont recalculés :',
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (var i = 0; i < data.spellSlotChanges.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    _spellSlotGainRow(data.spellSlotChanges[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
        _StepFooter(
          // Vers l'étape "Choix à faire" si elle existait à ce niveau,
          // "Aptitudes" sinon — même logique de chaînage conditionnel que le
          // "Continuer" de l'étape "Aptitudes" (voir
          // [_phaseAfterChoiceOrAbilities]), en sens inverse.
          onBack: () => setState(() {
            _phase = data.choiceKind != null
                ? _LevelUpPhase.choice
                : _LevelUpPhase.abilities;
          }),
          // Toujours actif : pur recalcul automatique, rien à valider (spec
          // visuelle direction-artistique section 0).
          onContinue: () => setState(() => _phase = _LevelUpPhase.summary),
        ),
      ],
    );
  }

  /// Une ligne de gain de l'étape "Sorts", et du bloc "Sorts" du
  /// récapitulatif ([_spellSlotSummaryGainRows]) — wording des deux
  /// variantes, spec visuelle direction-artistique section 2 :
  /// [SpellSlotChange.isNewlyUnlocked] (déblocage net, ancien total nul) vs
  /// renfort d'un palier déjà actif (libellé approuvé par le chef de
  /// projet).
  GainRow _spellSlotGainRow(SpellSlotChange change) {
    return GainRow(
      icon: Icons.auto_awesome,
      color: AppColors.accentViolet,
      title: change.isNewlyUnlocked
          ? 'Nouveaux emplacements de sorts'
          : 'Emplacements de sorts renforcés',
      subtitle: change.isNewlyUnlocked
          ? 'Niveau ${change.spellLevel} débloqué'
          : 'Niveau ${change.spellLevel} : ${change.oldTotal} → '
                '${change.newTotal} (+${change.delta})',
    );
  }

  /// Lignes de récapitulatif du bloc "Sorts" (increment 3), 0 à 2 éléments —
  /// voir la spec visuelle direction-artistique section 3. Insérées dans
  /// [_buildSummary] après le bloc "Choix à faire" existant, même ordre
  /// visuel que les étapes (PV -> Aptitudes -> Choix -> Sorts).
  List<GainRow> _spellSlotSummaryGainRows(LevelUpStepData data) => [
    for (final change in data.spellSlotChanges) _spellSlotGainRow(change),
  ];

  /// Ligne de récapitulatif du choix fait à l'étape "Choix à faire", `null`
  /// si ce niveau n'en déclenchait aucun — voir la spec visuelle
  /// direction-artistique section C.
  GainRow? _choiceSummaryGainRow(LevelUpStepData data) {
    final kind = data.choiceKind;
    if (kind == null) return null;

    final subtitle = switch (kind) {
      LevelUpChoiceKind.abilityScoreImprovement => [
        for (final definition in abilityScoreDefinitions)
          if ((_abilityAllocations?[definition.key] ?? 0) > 0)
            '${definition.label} +${_abilityAllocations![definition.key]}',
      ].join(', '),
      LevelUpChoiceKind.subclass =>
        data.availableSubclasses
            .firstWhere((option) => option.id == _selectedListOptionId)
            .name,
      LevelUpChoiceKind.fightingStyle ||
      LevelUpChoiceKind.favoredEnemy => _selectedListOptionId! as String,
    };

    return GainRow(
      icon: Icons.checklist,
      color: AppColors.accentBlue,
      title: _choiceStepLabel(kind),
      subtitle: subtitle,
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
                      if (_choiceSummaryGainRow(data) case final gainRow?) ...[
                        const SizedBox(height: AppSpacing.md),
                        gainRow,
                      ],
                      for (final spellGainRow in _spellSlotSummaryGainRows(
                        data,
                      )) ...[
                        const SizedBox(height: AppSpacing.md),
                        spellGainRow,
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

  /// L'annonce (voir [_buildAnnouncement]) vient de montrer `NIVEAU
  /// $_targetLevel`, mais ce niveau *bloqué* n'est justement jamais atteint
  /// (aucune écriture en base — voir la documentation de classe) : il ne
  /// faut donc pas confondre ce cas avec un niveau réellement validé.
  /// [isImmediate] distingue le blocage dès le premier niveau de la session
  /// (aucun niveau sauvegardé pour l'instant, en-tête neutre) d'un blocage
  /// survenant après un ou plusieurs niveaux du chaînage déjà validés avec
  /// succès (en-tête "NIVEAU ATTEINT" sur le dernier niveau *réellement*
  /// sauvegardé, `_targetLevel - 1` — signal explicite que la progression
  /// précédente a bien été enregistrée, même si celle-ci s'arrête ici).
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

/// Ligne teaser du bloc "À venir dans les prochaines étapes" de l'annonce de
/// niveau ([_LevelUpScreenState._buildAnnouncement]) — gabarit léger,
/// volontairement plus simple que [GainRow] : jamais de résultat, seulement
/// la présence d'une étape à venir (spec visuelle direction-artistique,
/// "Montée de niveau (style scène)").
class _UpcomingStepRow extends StatelessWidget {
  const _UpcomingStepRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// État vide de l'étape "Choix à faire" (increment 2, cas défensif — une
/// liste de 0 option ne devrait normalement pas arriver) — patron
/// `_EmptyFeaturesState` ci-dessus, hébergé dans une `_ParchmentCard` par
/// l'appelant (spec visuelle direction-artistique section "États").
class _EmptyChoiceState extends StatelessWidget {
  const _EmptyChoiceState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 40, color: AppColors.textMuted),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Aucune option disponible pour ce choix.',
          textAlign: TextAlign.center,
          style: AppTypography.body(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Une ligne de caractéristique de la variante allocation ASI de l'étape
/// "Choix à faire" — calquée sur `_AbilityRow` de
/// `character_creation/presentation/ability_score_step_screen.dart` (spec
/// visuelle direction-artistique section B), avec une différence
/// importante : [alloc] est le nombre de points alloués à *cette*
/// caractéristique (0 à [_abilityScoreImprovementBudget]), pas le score
/// final affiché par `StepperCounter.value` à l'étape 4/9 "Caractéristiques"
/// de l'assistant de création — à ne pas confondre.
class _AllocationRow extends StatelessWidget {
  const _AllocationRow({
    required this.definition,
    required this.currentScore,
    required this.alloc,
    required this.onIncrement,
    required this.onDecrement,
  });

  final AbilityScoreDefinition definition;
  final int currentScore;
  final int alloc;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final newScore = currentScore + alloc;

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
                  alloc == 0
                      ? '$currentScore'
                      : '$currentScore → $newScore (+$alloc)',
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
            value: alloc,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
        ],
      ),
    );
  }
}

/// Footer `Row[SecondaryButton("Retour", surface: scene), PrimaryButton
/// ("Continuer")]` des étapes 1, 2 et 3 — spec visuelle section 0.
/// [onContinue] nullable depuis l'increment 2 : l'étape "Choix à faire"
/// désactive "Continuer" tant qu'aucune sélection valide n'a été faite
/// (`PrimaryButton` gère déjà `onPressed: null`).
class _StepFooter extends StatelessWidget {
  const _StepFooter({required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback? onContinue;

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
