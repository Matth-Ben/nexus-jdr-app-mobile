import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/checkable_option_tile.dart';
import '../../../core/widgets/gain_row.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../../../core/widgets/selectable_option_tile.dart';
import '../../../core/widgets/spell_level_tab_selector.dart';
import '../../../core/widgets/stepper_counter.dart';
import '../../character_creation/domain/ability_score_definitions.dart';
import '../../character_creation/domain/spell_option.dart';
import '../../character_creation/domain/spell_selection_resolver.dart';
import '../../character_creation/domain/spells_step_selection.dart';
import '../domain/character_failure.dart';
import '../domain/level_up_chain_resolver.dart';
import '../domain/level_up_choice_kind.dart';
import '../domain/level_up_choice_options.dart';
import '../domain/level_up_choice_selection.dart';
import '../domain/level_up_continue_option.dart';
import '../domain/level_up_hit_points_calculator.dart';
import '../domain/level_up_invocation_option.dart';
import '../domain/level_up_multiclass_option.dart';
import '../domain/signed_modifier_formatter.dart';
import '../domain/spell_slot_change.dart';
import 'providers/character_detail_provider.dart';
import 'providers/character_providers.dart';
import 'providers/level_up_provider.dart';
import 'widgets/feat_info_panel.dart';
import 'widgets/level_up_header.dart';

enum _HpMethod { roll, average }

/// Sous-mode de l'étape "Choix à faire" quand
/// `LevelUpChoiceKind.abilityScoreImprovement` est déclenché (niveaux ASI
/// 4/8/12/16/19) — spec visuelle direction-artistique section 1 :
/// `SegmentedToggle` 2 segments, même registre que [_HpMethod]. Indépendant
/// de `_LevelUpScreenState._abilityAllocations`/`_selectedListOptionId` (le
/// don choisi réutilise ce dernier, voir sa documentation) : basculer d'un
/// mode à l'autre ne doit jamais effacer la sélection de l'autre mode.
enum _AsiMethod { allocate, feat }

/// Onglet actif de la sélection de nouveaux sorts/cantrips connus (étape
/// "Sorts", généralisée à toute montée de niveau qui en apprend — pas
/// seulement le niveau 1 d'une classe multiclassée, voir
/// `domain/spells_known_progression.dart`) — même rôle que `_SpellTab` de
/// `character_creation/presentation/spells_step_screen.dart`, dupliqué ici
/// plutôt que partagé (même rationale que les autres duplicatas de ce
/// dépôt : ne jamais coupler la montée de niveau à l'assistant de création
/// pour un bout de logique/état d'écran spécifique à chacun).
enum _SpellSelectionTab { cantrip, spells }

enum _LevelUpPhase {
  /// Nouvelle phase (multiclassage), en tête — voir [_buildClassDecision] et
  /// la spec visuelle direction-artistique section 1. Invisible (saut
  /// silencieux vers [announcement]) dès que
  /// `LevelUpStepData.multiclassOptions` est vide, cas de loin le plus
  /// fréquent.
  classDecision,
  announcement,
  hitPoints,
  abilities,
  choice,
  spells,

  /// Occultiste uniquement (`LevelUpStepData.requiresInvocationSelection`),
  /// entre [spells] et [summary] — voir [_buildInvocationsStep].
  invocations,
  summary,
}

/// Budget de points de l'étape "Choix à faire", sous-mode [_AsiMethod.allocate]
/// (règle 5e standard : "+2 sur une caractéristique" OU "+1/+1 sur deux" —
/// voir la documentation de
/// `domain/level_up_choice_kind.dart::LevelUpChoiceKind.abilityScoreImprovement`).
const int _abilityScoreImprovementBudget = 2;

/// Sélection courante de l'étape `classDecision`, portée par
/// [_LevelUpScreenState._classDecisionSelection] — généralisation de l'ancien
/// sentinel "continuer la classe actuelle" (qui supposait implicitement la
/// primaire) : porte désormais le `classId` choisi ainsi que la liste dont il
/// provient ([LevelUpStepData.continueOptions] ou
/// [LevelUpStepData.multiclassOptions]), les deux listes pouvant en théorie
/// contenir des `classId` numériquement égaux à des types Dart différents
/// (voir `presentation/providers/level_up_provider.dart::_sameClassId`) —
/// jamais le cas en pratique (une classe possédée ne peut pas aussi être une
/// classe de multiclassage), mais porter le "type de liste" en plus du
/// `classId` lève toute ambiguïté sans reposer sur cette hypothèse.
///
/// Volontairement une seule classe à constructeurs nommés (pas une hiérarchie
/// scellée) : même précédent que `domain/level_up_choice_selection.dart`.
class _ClassDecisionSelection {
  const _ClassDecisionSelection.continueClass(this.classId)
    : isMulticlass = false;

  const _ClassDecisionSelection.multiclass(this.classId) : isMulticlass = true;

  final Object classId;
  final bool isMulticlass;
}

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
  _LevelUpPhase _phase = _LevelUpPhase.classDecision;

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
  // pour les 4 variantes "liste" (sous-classe/style de combat/ennemi juré/don,
  // voir la spec visuelle direction-artistique section 2) : jamais
  // simultanées pour un même niveau (voir
  // `domain/level_up_choice_kind.dart::LevelUpChoiceKind`, un seul
  // `LevelUpChoiceKind` par niveau — le don et l'allocation de
  // caractéristiques partagent `LevelUpChoiceKind.abilityScoreImprovement`
  // mais restent mutuellement exclusifs via [_asiMethod]).
  // [_selectedListOptionId] porte l'`Object` sélectionné (un `subclasses.id`
  // pour la sous-classe, la chaîne elle-même pour style de combat/ennemi
  // juré, un `feats.id` pour un don — voir `domain/level_up_choice_options.dart`).
  Object? _selectedListOptionId;

  /// Sous-mode de l'étape "Choix à faire" quand le kind est
  /// [LevelUpChoiceKind.abilityScoreImprovement] — voir [_AsiMethod].
  /// Présélectionné sur [_AsiMethod.allocate] (spec visuelle
  /// direction-artistique section 1), reset uniquement par
  /// [_resetChoiceState] : indépendant de [_abilityAllocations]/
  /// [_selectedListOptionId], basculer ne doit jamais effacer l'autre mode.
  _AsiMethod _asiMethod = _AsiMethod.allocate;

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

  /// État de l'étape `classDecision` (multiclassage/choix de la classe
  /// continuée). `null` tant que l'étape n'a pas encore été construite pour
  /// ce niveau (voir [_ensureClassDecisionSelected], même précédent que
  /// [_abilityAllocations]) ; ensuite toujours non nul, présélectionné sur
  /// la classe primaire dans [LevelUpStepData.continueOptions]. Reset dans
  /// [_resetClassDecisionState].
  _ClassDecisionSelection? _classDecisionSelection;

  /// `classes.id` de la classe choisie pour multiclasser CE niveau, figé au
  /// moment où le joueur quitte l'étape `classDecision` (bouton "Continuer")
  /// — distinct de [_classDecisionSelection] (état de saisie tant que
  /// l'étape est affichée) : c'est cette valeur, pas la sélection en cours,
  /// qui est transmise à `levelUpStepDataProvider` (voir [build]) pour que
  /// toutes les étapes suivantes du niveau restent stables même si l'étape
  /// `classDecision` n'est plus affichée. `null` = ne multiclasse pas ce
  /// niveau (comportement historique, voir aussi
  /// [_committedContinueClassId]).
  Object? _committedMulticlassClassId;

  /// `classes.id` de la classe déjà possédée à CONTINUER ce niveau (primaire
  /// ou secondaire), figé au moment où le joueur quitte l'étape
  /// `classDecision` — même rôle que [_committedMulticlassClassId] côté
  /// "continuer" plutôt que "multiclasser" (les deux ne sont jamais commis
  /// simultanément, voir [_buildClassDecision]). `null` = continuer la classe
  /// primaire (comportement historique) : reste `null` si le joueur n'a
  /// jamais choisi explicitement une classe secondaire, y compris quand
  /// l'étape `classDecision` est invisible (voir [_buildData]).
  Object? _committedContinueClassId;

  /// État de la sélection de nouveaux sorts/cantrips connus (étape "Sorts",
  /// généralisée — voir [_SpellSelectionTab]) — même patron que
  /// `SpellsStepScreen` (étape 6/9 de l'assistant de création).
  List<String> _selectedNewCantrips = [];
  List<String> _selectedNewSpells = [];
  _SpellSelectionTab? _spellSelectionActiveTab;

  /// État de la sélection d'invocations occultistes (étape "Invocations") —
  /// clés `invocation.id.toString()` (voir [_buildInvocationIds]), pour
  /// réutiliser directement `SpellsStepSelection.toggle`/`.isChoiceLocked`
  /// (génériques sur `List<String>` + quota, voir la spec visuelle
  /// direction-artistique section 3).
  List<String> _selectedInvocationIds = [];

  @override
  void initState() {
    super.initState();
    _targetLevel = widget.initialTargetLevel;
    _resetClassDecisionState();
  }

  /// Remet à zéro l'état de l'étape `classDecision` — [_classDecisionSelection]
  /// remis à `null` (présélection sur la primaire recalculée au prochain
  /// affichage de l'étape, voir [_ensureClassDecisionSelected]). Appelée dans
  /// [initState] et dans [_continueFromSummary] (chaînage vers un nouveau
  /// niveau : l'éligibilité au multiclassage/la liste des classes à
  /// continuer doivent être réévaluées à chaque niveau, jamais héritées du
  /// niveau précédent).
  void _resetClassDecisionState() {
    _classDecisionSelection = null;
    _committedMulticlassClassId = null;
    _committedContinueClassId = null;
  }

  /// Remet à zéro la sélection de sorts/cantrips connus — même rationale que
  /// [_resetClassDecisionState] (chaînage vers un nouveau niveau).
  void _resetSpellSelectionState() {
    _selectedNewCantrips = [];
    _selectedNewSpells = [];
    _spellSelectionActiveTab = null;
  }

  /// Remet à zéro la sélection d'invocations — même rationale que
  /// [_resetSpellSelectionState].
  void _resetInvocationSelectionState() {
    _selectedInvocationIds = [];
  }

  void _toggleNewCantrip(String name, int quota) {
    setState(() {
      _selectedNewCantrips = SpellsStepSelection.toggle(
        current: _selectedNewCantrips,
        value: name,
        quota: quota,
      );
    });
  }

  void _toggleNewSpell(String name, int quota) {
    setState(() {
      _selectedNewSpells = SpellsStepSelection.toggle(
        current: _selectedNewSpells,
        value: name,
        quota: quota,
      );
    });
  }

  void _toggleInvocation(String invocationId, int quota) {
    setState(() {
      _selectedInvocationIds = SpellsStepSelection.toggle(
        current: _selectedInvocationIds,
        value: invocationId,
        quota: quota,
      );
    });
  }

  /// Identifiants de sorts prêts pour `CharacterRepository.applyLevelUp`
  /// (paramètre `initialSpellIds`, nom conservé malgré la généralisation —
  /// voir sa documentation) — réutilise `SpellSelectionResolver.resolve`
  /// (même mécanisme que l'étape 9/9 "Récapitulatif" de l'assistant de
  /// création), qui ne fait ici que dédupliquer et résoudre les noms choisis
  /// en identifiants via le catalogue déjà chargé : `status` n'est pas
  /// utilisé (le statut `'connu'`/`'préparé'` est recalculé par le
  /// repository depuis `className`, jamais transporté ici). Liste vide si ce
  /// niveau ne déclenche aucune sélection de sorts.
  List<int> _buildNewSpellIds(LevelUpStepData data) {
    if (!data.requiresSpellSelection) return const [];
    final rows = SpellSelectionResolver.resolve(
      cantripNames: _selectedNewCantrips,
      levelOneSpellNames: _selectedNewSpells,
      catalog: data.spellSelectionCatalog!,
      className: data.className,
    );
    return [for (final row in rows) row.spellId];
  }

  /// Identifiants d'invocations prêts pour `CharacterRepository.applyLevelUp`
  /// (paramètre `invocationIds`) — simple reconversion de
  /// [_selectedInvocationIds] (`String`, voir sa documentation) en `int`.
  List<int> _buildInvocationIds(LevelUpStepData data) {
    if (!data.requiresInvocationSelection) return const [];
    return [for (final id in _selectedInvocationIds) int.parse(id)];
  }

  /// Remet à zéro l'état de l'étape "Choix à faire" — appelé au chaînage
  /// vers un nouveau niveau (même rationale que la réinitialisation de
  /// `_hpMethod` dans [_continueFromSummary] : chaque niveau du chaînage
  /// repart d'un état de saisie vierge).
  void _resetChoiceState() {
    _selectedListOptionId = null;
    _abilityAllocations = null;
    _asiMethod = _AsiMethod.allocate;
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
        _asiMethod == _AsiMethod.feat
            ? LevelUpChoiceSelection.feat(_selectedListOptionId!)
            : LevelUpChoiceSelection.abilityScoreImprovement({
                for (final entry
                    in _ensureAbilityAllocationsInitialized().entries)
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
        classId: data.classId,
        className: data.className,
        isMulticlassing: data.isMulticlassing,
        hpRolled: hpRolled,
        hpMethod: hpMethod,
        hpGain: hpGain,
        choice: _buildChoiceSelection(data),
        initialSpellIds: _buildNewSpellIds(data),
        invocationIds: _buildInvocationIds(data),
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
        // `classDecision`, pas `announcement` directement : l'éligibilité au
        // multiclassage doit être réévaluée à chaque niveau du chaînage (voir
        // [_resetClassDecisionState]) — `_buildData` saute silencieusement à
        // `announcement` si aucune classe n'est éligible à ce nouveau niveau.
        _phase = _LevelUpPhase.classDecision;
        _hpMethod = _HpMethod.roll;
        _resetChoiceState();
        _resetClassDecisionState();
        _resetSpellSelectionState();
        _resetInvocationSelectionState();
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
        multiclassClassId: _committedMulticlassClassId,
        continueClassId: _committedContinueClassId,
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
                        multiclassClassId: _committedMulticlassClassId,
                        continueClassId: _committedContinueClassId,
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

  /// `true` si l'étape `classDecision` doit être affichée : au moins une
  /// vraie décision à prendre, soit "continuer QUELLE classe" (personnage
  /// multiclassé, `continueOptions.length > 1`), soit "continuer ou
  /// multiclasser" (`multiclassOptions` non vide, comportement historique).
  /// `false` dans l'immense majorité des cas (personnage mono-classé sans
  /// classe éligible au multiclassage) : `continueOptions` contient alors
  /// toujours exactement une entrée (la primaire), voir
  /// `presentation/providers/level_up_provider.dart::LevelUpStepData.continueOptions`.
  bool _hasClassDecision(LevelUpStepData data) =>
      data.continueOptions.length > 1 || data.multiclassOptions.isNotEmpty;

  Widget _buildData(LevelUpStepData data) {
    // `classDecision` passe avant *tout le reste*, y compris `blockReason` :
    // un niveau où la classe actuelle est bloquée peut redevenir jouable si
    // le joueur choisit de multiclasser (la nouvelle classe démarre à son
    // niveau 1, jamais bloqué pour cette raison), ou en continuant une AUTRE
    // classe déjà possédée non bloquée à ce niveau — spec visuelle
    // direction-artistique section 1. Invisible (mutation sans `setState`,
    // même précédent que [_ensureRolled]) dès que [_hasClassDecision] est
    // faux, cas de loin le plus fréquent.
    if (_phase == _LevelUpPhase.classDecision) {
      if (!_hasClassDecision(data)) {
        _phase = _LevelUpPhase.announcement;
      } else {
        return _buildClassDecision(data);
      }
    }
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
      _LevelUpPhase.classDecision => _buildClassDecision(data),
      _LevelUpPhase.announcement => _buildAnnouncement(data),
      _LevelUpPhase.hitPoints => _buildHpStep(data),
      _LevelUpPhase.abilities => _buildAbilitiesStep(data),
      _LevelUpPhase.choice => _buildChoiceStep(data),
      _LevelUpPhase.spells => _buildSpellsStep(data),
      _LevelUpPhase.invocations => _buildInvocationsStep(data),
      _LevelUpPhase.summary => _buildSummary(data),
    };
  }

  /// Présélectionne [_classDecisionSelection] sur la classe primaire de
  /// [data.continueOptions] au premier affichage de l'étape `classDecision`
  /// pour ce niveau — simple mutation de champ (pas de `setState`), même
  /// précédent que [_ensureRolled]/[_ensureAbilityAllocationsInitialized] :
  /// sûr tant qu'aucun rebuild n'est requis pour ce seul effet de bord.
  /// `orElse` défensif (ne devrait jamais arriver : une des entrées de
  /// `continueOptions` est toujours marquée `isPrimary`, voir
  /// `domain/character_detail.dart::CharacterDetail.primaryClass`).
  _ClassDecisionSelection _ensureClassDecisionSelected(LevelUpStepData data) {
    return _classDecisionSelection ??= _ClassDecisionSelection.continueClass(
      data.continueOptions
          .firstWhere(
            (option) => option.isPrimary,
            orElse: () => data.continueOptions.first,
          )
          .classId,
    );
  }

  /// Étape `classDecision` — affichée uniquement quand [_hasClassDecision]
  /// est vrai (voir [_buildData]). Réutilise [SelectableOptionTile] (choix
  /// exclusif), posé directement sur le fond scène, sans carte parchemin
  /// englobante — spec visuelle direction-artistique section 2. Pas de
  /// `stepLabel` (même statut que l'annonce/le récapitulatif : cette étape
  /// n'est pas numérotée). Une tuile "Continuer en {classe}" par entrée de
  /// [LevelUpStepData.continueOptions] (primaire incluse, plus jamais un cas
  /// spécial câblé en dur), suivie d'une tuile "Se multiclasser en {classe}"
  /// par entrée de [LevelUpStepData.multiclassOptions] (inchangé).
  Widget _buildClassDecision(LevelUpStepData data) {
    _ensureClassDecisionSelected(data);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choisissez comment ce niveau s'applique.",
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnWood,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < data.continueOptions.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _continueOptionTile(data, data.continueOptions[i]),
                ],
                for (var i = 0; i < data.multiclassOptions.length; i++) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _multiclassOptionTile(data.multiclassOptions[i], index: i),
                ],
              ],
            ),
          ),
        ),
        _StepFooter(
          onBack: _goBackToSheet,
          // Toujours actif : la primaire est présélectionnée par défaut (voir
          // [_ensureClassDecisionSelected]), spec visuelle section 2.
          onContinue: () => setState(() {
            final selection = _classDecisionSelection!;
            if (selection.isMulticlass) {
              _committedMulticlassClassId = selection.classId;
              _committedContinueClassId = null;
            } else {
              _committedMulticlassClassId = null;
              // `null` plutôt que `selection.classId` quand la primaire est
              // choisie (comportement historique, voir la doc de
              // [_committedContinueClassId]) : `data` reflète déjà "continuer
              // la primaire" par défaut tant que rien n'a été commis, donc
              // committer explicitement son `classId` ne changerait aucune
              // donnée mais forcerait `levelUpStepDataProvider` à réévaluer
              // sous une nouvelle clé (argument différent), et donc à
              // reformuler une requête réseau identique pour rien —
              // uniquement les classes SECONDAIRES ont besoin d'un
              // `continueClassId` explicite.
              final isPrimarySelection = data.continueOptions.any(
                (option) =>
                    option.isPrimary && option.classId == selection.classId,
              );
              _committedContinueClassId = isPrimarySelection
                  ? null
                  : selection.classId;
            }
            _phase = _LevelUpPhase.announcement;
          }),
        ),
      ],
    );
  }

  /// Une tuile "Continuer en {classe}" de l'étape `classDecision` — une par
  /// entrée de [LevelUpStepData.continueOptions] (primaire incluse).
  ///
  /// **Amélioration recommandée par la direction artistique (appliquée)** :
  /// si la classe PRIMAIRE est bloquée à ce niveau (`data.blockReason`, non
  /// nul quand le personnage n'est pas en train de multiclasser — voir
  /// `presentation/providers/level_up_provider.dart` : `data` reflète
  /// toujours "continuer la primaire" tant que ce niveau n'a pas encore été
  /// commis, voir [_committedContinueClassId]), le sous-titre DE LA TUILE
  /// PRIMAIRE change pour signaler le blocage à venir *avant* que le joueur
  /// ne valide "Continuer" et ne tombe sur l'écran de blocage — pour que
  /// l'alternative "multiclasser" (ou continuer une autre classe) soit
  /// visible en premier. Le badge passe alors en `Icons.lock_outline`/
  /// `accent.brick` (adaptation : le composant partagé [SelectableOptionTile]
  /// n'a pas de slot d'icône dédié à droite de la ligne, contrairement au
  /// balisage suggéré par la spec visuelle — un changement du badge
  /// [leading] déjà existant reste le compromis le plus proche sans modifier
  /// ce composant partagé, à valider par le chef de projet si un slot dédié
  /// est souhaité). Aucune information de blocage n'est en revanche
  /// disponible pour une tuile "Continuer" secondaire tant qu'elle n'a pas
  /// été commise (le blocage d'une classe secondaire ne peut être vérifié
  /// qu'après avoir explicitement choisi de la continuer, sur l'étape
  /// suivante — voir [_buildBlocked]).
  Widget _continueOptionTile(
    LevelUpStepData data,
    LevelUpContinueOption option,
  ) {
    final isBlocked =
        option.isPrimary && !data.isMulticlassing && data.blockReason != null;
    return SelectableOptionTile(
      title: 'Continuer en ${option.className}',
      subtitle: isBlocked
          ? 'Ce niveau nécessite un choix pas encore disponible dans '
                "l'app."
          : 'Vous progressez dans votre voie actuelle (niveau '
                '${option.currentLevel} → ${option.currentLevel + 1}).',
      selected:
          !_classDecisionSelection!.isMulticlass &&
          _classDecisionSelection!.classId == option.classId,
      onTap: () => setState(
        () => _classDecisionSelection = _ClassDecisionSelection.continueClass(
          option.classId,
        ),
      ),
      leading: isBlocked
          ? const AccentIconBadge(
              icon: Icons.lock_outline,
              color: AppColors.accentBrick,
            )
          : const AccentIconBadge(icon: Icons.shield, color: AppColors.goldEnd),
    );
  }

  /// Une tuile "Se multiclasser en {classe}" de l'étape `classDecision`.
  Widget _multiclassOptionTile(
    LevelUpMulticlassOption option, {
    required int index,
  }) {
    return SelectableOptionTile(
      title: 'Se multiclasser en ${option.className}',
      subtitle:
          'Vous débutez au niveau 1 dans cette classe. Prérequis rempli : '
          '${option.satisfiedAbilityLabels.join(', ')}.',
      selected:
          _classDecisionSelection!.isMulticlass &&
          _classDecisionSelection!.classId == option.classId,
      onTap: () => setState(
        () => _classDecisionSelection = _ClassDecisionSelection.multiclass(
          option.classId,
        ),
      ),
      leading: AccentIconBadge(index: index, icon: Icons.call_split),
    );
  }

  /// Bandeau de contexte affiché en tête de toutes les étapes concernant la
  /// nouvelle classe, tant que le multiclassage est en cours (Points de
  /// vie/Aptitudes/Choix/Sorts/Récapitulatif) — spec visuelle
  /// direction-artistique section 4a. N'appelle jamais cette méthode sans
  /// avoir vérifié `data.isMulticlassing` au préalable (utilise
  /// `data.multiclassClassName!`, non nul dans ce cas).
  Widget _multiclassInfoBanner(LevelUpStepData data) {
    return InfoBanner(
      icon: Icons.call_split,
      message: 'Nouvelle classe : ${data.multiclassClassName} (niveau 1)',
    );
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
        (data.choiceKind != null ||
            _hasSpellsStep(data) ||
            _hasInvocationsStep(data));

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
                    for (var i = 0; i < data.automaticFeatures.length; i++) ...[
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
                      if (_hasSpellsStep(data))
                        const SizedBox(height: AppSpacing.sm),
                    ],
                    if (_hasSpellsStep(data)) ...[
                      const _UpcomingStepRow(
                        icon: Icons.auto_awesome,
                        color: AppColors.accentViolet,
                        label: 'Vos emplacements de sorts vont évoluer',
                      ),
                      if (_hasInvocationsStep(data))
                        const SizedBox(height: AppSpacing.sm),
                    ],
                    // Décision assumée au-delà de la spec visuelle littérale
                    // (qui ne couvrait que les sections "Choix à faire"/
                    // "Sorts" de cette annonce) : même traitement "teaser"
                    // pour l'étape "Invocations", par cohérence avec les deux
                    // autres — à valider par le chef de projet si un
                    // désaccord existe sur ce point.
                    if (_hasInvocationsStep(data))
                      const _UpcomingStepRow(
                        icon: Icons.remove_red_eye,
                        color: AppColors.accentViolet,
                        label: 'De nouvelles invocations vous attendront',
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

  /// `true` si l'étape "Sorts" doit être affichée à ce niveau : soit un
  /// changement d'emplacements est calculé (increment 3, inchangé), soit une
  /// sélection de nouveaux sorts/cantrips connus est requise — TOUTE montée
  /// de niveau d'une classe "à sorts connus" qui en apprend (multiclassage
  /// niveau 1 OU classe continuée > niveau 1, voir
  /// [LevelUpStepData.requiresSpellSelection] et
  /// `domain/spells_known_progression.dart`) — les deux ne s'excluent pas
  /// mutuellement dans l'affichage (une nouvelle classe demi-lanceuse comme
  /// le Rôdeur peut n'avoir *aucun* changement d'emplacements à son niveau
  /// interne 1 tout en nécessitant malgré tout une sélection de sorts
  /// connus, voir `character_creation/domain/spellcasting_rules.dart`).
  bool _hasSpellsStep(LevelUpStepData data) =>
      data.spellSlotChanges.isNotEmpty || data.requiresSpellSelection;

  /// `true` si l'étape "Invocations" doit être affichée à ce niveau —
  /// Occultiste uniquement, voir [LevelUpStepData.requiresInvocationSelection].
  bool _hasInvocationsStep(LevelUpStepData data) =>
      data.requiresInvocationSelection;

  /// 3 à 6 selon les étapes déclenchées à ce niveau — spec visuelle
  /// direction-artistique : [LevelUpStepData.choiceKind] non nul ajoute
  /// l'étape "Choix à faire" (increment 2, inchangé), [_hasSpellsStep]
  /// ajoute l'étape "Sorts", [_hasInvocationsStep] ajoute l'étape
  /// "Invocations".
  int _totalSteps(LevelUpStepData data) =>
      3 +
      (data.choiceKind != null ? 1 : 0) +
      (_hasSpellsStep(data) ? 1 : 0) +
      (_hasInvocationsStep(data) ? 1 : 0);

  /// Étape suivante une fois "Aptitudes"/"Choix à faire" franchies : l'étape
  /// "Sorts" si ce niveau la déclenche ([_hasSpellsStep]), sinon l'étape
  /// "Invocations" si ce niveau la déclenche ([_hasInvocationsStep]), le
  /// récapitulatif sinon — même logique de chaînage conditionnel que
  /// [LevelUpChoiceKind] pour l'étape "Choix à faire". Couvre aussi le cas
  /// défensif "condition d'affichage vraie mais 0 changement calculé" (spec
  /// visuelle direction-artistique section 4) : ce cas ne devrait jamais se
  /// produire en pratique pour la branche mono-classe historique (voir
  /// `domain/spell_slot_progression.dart::SpellSlotProgression.changesFor`),
  /// mais une liste vide retombe naturellement ici sur le récapitulatif,
  /// sans code dédié supplémentaire.
  _LevelUpPhase _phaseAfterChoiceOrAbilities(LevelUpStepData data) {
    if (_hasSpellsStep(data)) return _LevelUpPhase.spells;
    if (_hasInvocationsStep(data)) return _LevelUpPhase.invocations;
    return _LevelUpPhase.summary;
  }

  /// Étape suivante une fois "Sorts" franchie : l'étape "Invocations" si ce
  /// niveau la déclenche ([_hasInvocationsStep]), le récapitulatif sinon.
  _LevelUpPhase _phaseAfterSpells(LevelUpStepData data) =>
      _hasInvocationsStep(data)
      ? _LevelUpPhase.invocations
      : _LevelUpPhase.summary;

  /// Étape précédente de "Invocations" ("Retour") : l'étape "Sorts" si ce
  /// niveau la déclenche ([_hasSpellsStep]), sinon "Choix à faire" si
  /// déclenchée, sinon "Aptitudes" — même logique de repli que le "Retour"
  /// existant de l'étape "Sorts".
  _LevelUpPhase _phaseBeforeInvocations(LevelUpStepData data) {
    if (_hasSpellsStep(data)) return _LevelUpPhase.spells;
    if (data.choiceKind != null) return _LevelUpPhase.choice;
    return _LevelUpPhase.abilities;
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
          stepLabel: 'Étape 1 sur ${_totalSteps(data)} · Points de vie',
          remainingLevelsLabel: _remainingLevelsLabel(data.currentXp),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isMulticlassing) ...[
                  _multiclassInfoBanner(data),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _ParchmentCard(
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
                                  // Le niveau TOTAL du personnage (affiché par
                                  // `LevelUpHeader.levelLabel`) peut différer du
                                  // niveau 1 dans la nouvelle classe — texte
                                  // désambiguïsé explicitement (spec visuelle
                                  // direction-artistique section 4b).
                                  data.isMulticlassing
                                      ? 'Dé de vie de ${data.className} (niveau '
                                            '1) : d${data.hitDie}'
                                      : 'Dé de vie de la classe : d${data.hitDie}',
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
                        onChanged: (method) =>
                            setState(() => _hpMethod = method),
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
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                  ),
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
              ],
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
    // Bloc "Maîtrises de multiclassage" (spec visuelle direction-artistique
    // section 3) : uniquement en branche multiclasse ET si cette classe en
    // accorde au moins une (Ensorceleur/Magicien n'en accordent aucune, voir
    // `domain/multiclass_proficiencies.dart`).
    final hasMulticlassProficiencies =
        data.isMulticlassing && data.multiclassProficiencies.isNotEmpty;

    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
          stepLabel:
              'Étape 2 sur ${_totalSteps(data)} · '
              '${hasMulticlassProficiencies ? 'Aptitudes & maîtrises' : 'Aptitudes de classe'}',
          remainingLevelsLabel: _remainingLevelsLabel(data.currentXp),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isMulticlassing) ...[
                  _multiclassInfoBanner(data),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _ParchmentCard(
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
                      if (hasMulticlassProficiencies) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(height: 1, color: AppColors.gaugeTrack),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Maîtrises de multiclassage :',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (
                          var i = 0;
                          i < data.multiclassProficiencies.length;
                          i++
                        ) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.md),
                          GainRow(
                            icon: Icons.construction,
                            color: AppColors.accentTeal,
                            title: 'Nouvelle maîtrise',
                            subtitle: data.multiclassProficiencies[i],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
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
        Expanded(
          child: Column(
            children: [
              if (data.isMulticlassing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _multiclassInfoBanner(data),
                ),
              Expanded(child: _buildChoiceBody(data, kind)),
            ],
          ),
        ),
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
      LevelUpChoiceKind.abilityScoreImprovement => 'Amélioration ou don',
      LevelUpChoiceKind.subclass => 'Sous-classe',
      LevelUpChoiceKind.fightingStyle => 'Style de combat',
      LevelUpChoiceKind.favoredEnemy => 'Ennemi juré',
    };
  }

  bool _canContinueChoiceStep(LevelUpStepData data, LevelUpChoiceKind kind) {
    if (kind == LevelUpChoiceKind.abilityScoreImprovement) {
      if (_asiMethod == _AsiMethod.feat) {
        return _selectedListOptionId != null;
      }
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
      LevelUpChoiceKind.abilityScoreImprovement => _buildAsiOrFeatBody(data),
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
              onInfoTap: null,
            ),
        ],
      ),
      LevelUpChoiceKind.fightingStyle => _buildOptionListBody(
        instruction: 'Choisissez un style de combat.',
        icon: Icons.security,
        options: [
          for (final style in LevelUpChoiceOptions.fightingStyles)
            (id: style, title: style, subtitle: null, onInfoTap: null),
        ],
      ),
      LevelUpChoiceKind.favoredEnemy => _buildOptionListBody(
        instruction: 'Choisissez un ennemi juré.',
        icon: Icons.gps_fixed,
        options: [
          for (final enemy in LevelUpChoiceOptions.favoredEnemies)
            (id: enemy, title: enemy, subtitle: null, onInfoTap: null),
        ],
      ),
    };
  }

  /// Sous-état ASI-ou-don de l'étape "Choix à faire" — spec visuelle
  /// direction-artistique section 1 : instruction, `SegmentedToggle` 2
  /// segments (présélection [_AsiMethod.allocate]), puis le corps du mode
  /// choisi. Mode allocation = [_buildAbilityAllocationBody] inchangé. Mode
  /// don = [_buildOptionListBody] (réutilisation intégrale, voir section 2 de
  /// la spec).
  Widget _buildAsiOrFeatBody(LevelUpStepData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                'Choisissez comment progresser.',
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnWood,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedToggle<_AsiMethod>(
                options: const [
                  SegmentedToggleOption(
                    value: _AsiMethod.allocate,
                    label: 'Répartir +2',
                  ),
                  SegmentedToggleOption(
                    value: _AsiMethod.feat,
                    label: 'Choisir un don',
                  ),
                ],
                value: _asiMethod,
                onChanged: (method) => setState(() => _asiMethod = method),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        Expanded(
          child: _asiMethod == _AsiMethod.allocate
              ? _buildAbilityAllocationBody(data)
              : _buildOptionListBody(
                  instruction: 'Choisissez un don.',
                  icon: Icons.military_tech,
                  options: [
                    for (final feat in data.availableFeats)
                      (
                        id: feat.id,
                        title: feat.name,
                        subtitle: feat.prerequisiteText,
                        onInfoTap: () => showFeatInfoPanel(context, feat: feat),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Variante liste (sous-classe/style de combat/ennemi juré/don) — pas de
  /// carte englobante (chaque [SelectableOptionTile] est déjà sa propre
  /// carte), sauf état vide (spec visuelle direction-artistique section 2).
  ///
  /// [onInfoTap] (option) : bouton "i" additionnel affiché à côté de la
  /// tuile, ouvrant un panneau "Infos" — jamais consommé par
  /// [SelectableOptionTile] lui-même (composant partagé, pas de slot dédié) :
  /// une zone de tap séparée à sa droite plutôt qu'une modification de ce
  /// composant, seul usage à ce jour (liste de dons, section 2 de la spec
  /// visuelle direction-artistique) — le tap sur le reste de la ligne
  /// sélectionne l'option normalement.
  Widget _buildOptionListBody({
    required String instruction,
    required IconData icon,
    required List<
      ({Object id, String title, String? subtitle, VoidCallback? onInfoTap})
    >
    options,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableOptionTile(
                    title: options[i].title,
                    subtitle: options[i].subtitle,
                    selected: _selectedListOptionId == options[i].id,
                    onTap: () =>
                        setState(() => _selectedListOptionId = options[i].id),
                    leading: AccentIconBadge(index: i, icon: icon),
                  ),
                ),
                if (options[i].onInfoTap != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    child: IconButton(
                      onPressed: options[i].onInfoTap,
                      icon: const Icon(
                        Icons.info_outline,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
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

  /// Étape "Sorts", affichée uniquement quand [_hasSpellsStep] vaut `true`
  /// (increment 3, et généralisée depuis le chantier "sorts/dons/
  /// invocations" — voir [_totalSteps] et [_phaseAfterChoiceOrAbilities]).
  /// Numérotation "Étape 3" si l'étape "Choix à faire" n'existait pas à ce
  /// niveau, "Étape 4" sinon (spec visuelle direction-artistique section 0)
  /// — toujours juste avant l'étape "Invocations" si elle existe, sinon le
  /// récapitulatif.
  ///
  /// Deux variantes : sélection de nouveaux sorts/cantrips connus (voir
  /// [_buildSpellSelectionStep] — plus seulement le niveau 1 d'une classe
  /// multiclassée, généralisé à toute montée de niveau qui en apprend), ou
  /// simple recalcul automatique d'emplacements (comportement historique de
  /// l'increment 3, ci-dessous).
  Widget _buildSpellsStep(LevelUpStepData data) {
    final stepNumber = data.choiceKind != null ? 4 : 3;

    if (data.requiresSpellSelection) {
      return _buildSpellSelectionStep(data, stepNumber);
    }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isMulticlassing) ...[
                  _multiclassInfoBanner(data),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _ParchmentCard(
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
                      for (
                        var i = 0;
                        i < data.spellSlotChanges.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        _spellSlotGainRow(data.spellSlotChanges[i]),
                      ],
                    ],
                  ),
                ),
              ],
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
          onContinue: () => setState(() => _phase = _phaseAfterSpells(data)),
        ),
      ],
    );
  }

  /// Étape "Sorts" généralisée : sélection de nouveaux sorts/cantrips connus
  /// — niveau 1 d'une nouvelle classe multiclassée "à sorts connus"
  /// (Barde/Ensorceleur/Occultiste/Rôdeur) OU tout niveau > 1 d'une telle
  /// classe continuée qui en apprend (voir
  /// `domain/spells_known_progression.dart`) — même patron que
  /// `SpellsStepScreen` (étape 6/9 de l'assistant de création), spec
  /// visuelle direction-artistique section 4.
  ///
  /// **Simplification assumée** : cette étape ne couvre QUE l'ajout de
  /// nouveaux sorts/cantrips, jamais l'échange d'un sort déjà connu contre un
  /// autre (RAW 5e : Barde/Ensorceleur/Rôdeur/Occultiste peuvent tous
  /// échanger un sort connu à chaque montée de niveau) — le joueur peut
  /// toujours modifier ses sorts connus manuellement depuis l'onglet Sorts
  /// existant de la fiche (déjà éditable) si besoin.
  Widget _buildSpellSelectionStep(LevelUpStepData data, int stepNumber) {
    final catalog = data.spellSelectionCatalog!;
    final cantripQuota = data.newCantripQuota;
    final spellQuota = data.newSpellQuota;
    final showCantripTab = cantripQuota > 0;
    final showSpellsTab = spellQuota > 0;

    // Onglet par défaut, déterminé une seule fois (même précédent que
    // `SpellsStepScreen._activeTab`) : "Mineurs" s'il est visible, sinon
    // "Sorts".
    _spellSelectionActiveTab ??= showCantripTab
        ? _SpellSelectionTab.cantrip
        : _SpellSelectionTab.spells;
    final activeTab = _spellSelectionActiveTab!;
    final showTabSelector = showCantripTab && showSpellsTab;

    final cantrips = [
      for (final spell in catalog.spells)
        if (spell.level == 0) spell,
    ];
    // Liste PLATE couvrant tous les niveaux de sort castables à ce niveau de
    // classe (pas de sous-onglets par niveau de sort, spec visuelle
    // direction-artistique section 4) — triée par niveau de sort puis
    // alphabétiquement.
    final spells =
        [
          for (final spell in catalog.spells)
            if (spell.level >= 1 && spell.level <= data.maxCastableSpellLevel)
              spell,
        ]..sort((a, b) {
          final byLevel = a.level.compareTo(b.level);
          return byLevel != 0 ? byLevel : a.name.compareTo(b.name);
        });

    final canProceed = SpellsStepSelection.canProceed(
      cantripQuota: cantripQuota,
      selectedCantrips: _selectedNewCantrips,
      levelOneSpellQuota: spellQuota,
      selectedLevelOneSpells: _selectedNewSpells,
    );

    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
          stepLabel: 'Étape $stepNumber sur ${_totalSteps(data)} · Sorts',
          remainingLevelsLabel: _remainingLevelsLabel(data.currentXp),
        ),
        if (showTabSelector) ...[
          const SizedBox(height: AppSpacing.sm),
          SpellLevelTabSelector<_SpellSelectionTab>(
            options: const [
              SpellLevelTabOption(
                value: _SpellSelectionTab.cantrip,
                label: 'Mineurs',
              ),
              SpellLevelTabOption(
                value: _SpellSelectionTab.spells,
                label: 'Sorts',
              ),
            ],
            value: activeTab,
            onChanged: (tab) => setState(() => _spellSelectionActiveTab = tab),
          ),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                // Correctif structurel (bug latent) : conditionné à
                // `data.isMulticlassing` comme partout ailleurs dans cet
                // écran — cet appel était auparavant inconditionnel, ce qui
                // affichait à tort "Nouvelle classe : ... (niveau 1)" pour
                // une montée de niveau normale (classe continuée).
                if (data.isMulticlassing) ...[
                  _multiclassInfoBanner(data),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (activeTab == _SpellSelectionTab.cantrip)
                  _spellSelectionSection(
                    title: 'SORTS MINEURS CONNUS',
                    quota: cantripQuota,
                    selected: _selectedNewCantrips,
                    candidates: cantrips,
                    onToggle: _toggleNewCantrip,
                    showLevelSuffix: false,
                  )
                else
                  _spellSelectionSection(
                    title: 'NOUVEAUX SORTS CONNUS',
                    quota: spellQuota,
                    selected: _selectedNewSpells,
                    candidates: spells,
                    onToggle: _toggleNewSpell,
                    showLevelSuffix: true,
                  ),
                const SizedBox(height: AppSpacing.md),
                _ParchmentCard(
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
                      if (data.spellSlotChanges.isEmpty)
                        Text(
                          'Aucun emplacement de sorts à ce niveau.',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        )
                      else
                        for (
                          var i = 0;
                          i < data.spellSlotChanges.length;
                          i++
                        ) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.md),
                          _spellSlotGainRow(data.spellSlotChanges[i]),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _StepFooter(
          onBack: () => setState(() {
            _phase = data.choiceKind != null
                ? _LevelUpPhase.choice
                : _LevelUpPhase.abilities;
          }),
          // Désactivé tant que les quotas cantrips/sorts ne sont pas
          // atteints — même garde que l'étape 6/9 de l'assistant de création
          // (`SpellsStepSelection.canProceed`), spec visuelle
          // direction-artistique section 4.
          onContinue: canProceed
              ? () => setState(() => _phase = _phaseAfterSpells(data))
              : null,
        ),
      ],
    );
  }

  /// Contenu d'un onglet de [_buildSpellSelectionStep] : titre de section +
  /// badge de quota, puis une [_spellSelectionTile] par sort candidat — même
  /// patron que `SpellsStepScreen._spellSection`.
  Widget _spellSelectionSection({
    required String title,
    required int quota,
    required List<String> selected,
    required List<SpellOption> candidates,
    required void Function(String name, int quota) onToggle,
    required bool showLevelSuffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            _QuotaBadge(text: '${selected.length} / $quota'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < candidates.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _spellSelectionTile(
            candidates[i],
            index: i,
            selected: selected,
            quota: quota,
            onToggle: onToggle,
            showLevelSuffix: showLevelSuffix,
          ),
        ],
      ],
    );
  }

  /// Une tuile de sort candidat — même patron que
  /// `SpellsStepScreen._spellTile`. [showLevelSuffix] ajoute le niveau de
  /// sort au `subtitle` (ex. "Évocation · 1 action (niveau 2)") — pertinent
  /// uniquement pour la section "NOUVEAUX SORTS CONNUS" (liste plate
  /// multi-niveaux, spec visuelle direction-artistique section 4), jamais
  /// pour les cantrips (toujours niveau 0, non affiché).
  Widget _spellSelectionTile(
    SpellOption spell, {
    required int index,
    required List<String> selected,
    required int quota,
    required void Function(String name, int quota) onToggle,
    required bool showLevelSuffix,
  }) {
    final isSelected = selected.contains(spell.name);
    return CheckableOptionTile(
      title: spell.name,
      subtitle: showLevelSuffix
          ? '${spell.metaLine} (niveau ${spell.level})'
          : spell.metaLine,
      leading: AccentIconBadge(index: index, icon: Icons.auto_awesome),
      checked: isSelected,
      enabled: !SpellsStepSelection.isChoiceLocked(
        isSelected: isSelected,
        selectedCount: selected.length,
        quota: quota,
      ),
      onTap: () => onToggle(spell.name, quota),
    );
  }

  /// Étape "Invocations", affichée uniquement quand [_hasInvocationsStep]
  /// vaut `true` (Occultiste, voir `domain/invocations_known_progression.dart`)
  /// — spec visuelle direction-artistique section 3. Pas de bandeau
  /// multiclassage sur cette étape (un multiclassage en Occultiste démarre
  /// toujours au niveau 1, les invocations RAW commencent au niveau 2 — cette
  /// condition ne peut jamais être vraie ici).
  ///
  /// **Simplification assumée** (même esprit que l'étape "Sorts", voir son
  /// commentaire "pas d'échange de sort déjà connu") : cette étape ne couvre
  /// QUE l'ajout de nouvelles invocations, jamais l'échange d'une invocation
  /// déjà connue contre une autre — RAW 5e, l'Occultiste peut pourtant le
  /// faire à chaque montée de niveau, comme les 4 classes "à sorts connus"
  /// pour leurs sorts. Le joueur peut toujours ajuster ses invocations
  /// connues manuellement si besoin (aucun onglet dédié aujourd'hui, mais
  /// rien n'empêche une correction en base par un futur écran).
  Widget _buildInvocationsStep(LevelUpStepData data) {
    final stepNumber = _invocationsStepNumber(data);
    final quota = data.invocationQuota;
    final selected = _selectedInvocationIds;

    return Column(
      children: [
        LevelUpHeader(
          eyebrow: 'MONTÉE DE NIVEAU',
          levelLabel: 'NIVEAU $_targetLevel',
          stepLabel: 'Étape $stepNumber sur ${_totalSteps(data)} · Invocations',
          remainingLevelsLabel: _remainingLevelsLabel(data.currentXp),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INVOCATIONS CONNUES',
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    _QuotaBadge(text: '${selected.length} / $quota'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.availableInvocations.isEmpty)
                  const _ParchmentCard(
                    child: _EmptyChoiceState(
                      message:
                          'Vous connaissez déjà toutes les invocations '
                          'occultistes disponibles.',
                    ),
                  )
                else
                  for (
                    var i = 0;
                    i < data.availableInvocations.length;
                    i++
                  ) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.xs),
                    _invocationTile(
                      data.availableInvocations[i],
                      index: i,
                      quota: quota,
                    ),
                  ],
              ],
            ),
          ),
        ),
        _StepFooter(
          onBack: () => setState(() => _phase = _phaseBeforeInvocations(data)),
          // Actif dès que le quota EFFECTIF est atteint (voir la doc de
          // [LevelUpStepData.invocationQuota]) — toujours vrai quand la liste
          // de candidats est vide (quota effectif 0, déjà atteint), spec
          // visuelle direction-artistique section 3.
          onContinue: selected.length == quota
              ? () => setState(() => _phase = _LevelUpPhase.summary)
              : null,
        ),
      ],
    );
  }

  /// Une tuile d'invocation candidate — réutilise directement
  /// `SpellsStepSelection.toggle`/`.isChoiceLocked` (déjà génériques sur
  /// `List<String>` + quota, voir [_selectedInvocationIds]). Couleur
  /// d'accent fixe [AppColors.accentViolet] (distinct du cycle générique de
  /// [AccentIconBadge], spec visuelle direction-artistique section 3).
  Widget _invocationTile(
    LevelUpInvocationOption invocation, {
    required int index,
    required int quota,
  }) {
    final id = invocation.id.toString();
    final isSelected = _selectedInvocationIds.contains(id);
    return CheckableOptionTile(
      title: invocation.name,
      subtitle: invocation.prerequisiteText,
      leading: AccentIconBadge(
        index: index,
        icon: Icons.remove_red_eye,
        color: AppColors.accentViolet,
      ),
      checked: isSelected,
      enabled: !SpellsStepSelection.isChoiceLocked(
        isSelected: isSelected,
        selectedCount: _selectedInvocationIds.length,
        quota: quota,
      ),
      onTap: () => _toggleInvocation(id, quota),
    );
  }

  /// 3, 4, 5 ou 6 selon les étapes déclenchées avant "Invocations" à ce
  /// niveau — même principe que le calcul de `stepNumber` de
  /// [_buildSpellsStep].
  int _invocationsStepNumber(LevelUpStepData data) {
    final spellsStepNumber = data.choiceKind != null ? 4 : 3;
    return _hasSpellsStep(data) ? spellsStepNumber + 1 : spellsStepNumber;
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
  /// direction-artistique section C. Titre dynamique pour
  /// [LevelUpChoiceKind.abilityScoreImprovement] selon le sous-choix réel
  /// (spec visuelle direction-artistique section 5, point 1) : mode
  /// allocation, titre inchangé `'Amélioration de caractéristique'` ; mode
  /// don, titre `'Don'` et subtitle = nom du don choisi. Icône/couleur
  /// inchangées dans les deux cas.
  GainRow? _choiceSummaryGainRow(LevelUpStepData data) {
    final kind = data.choiceKind;
    if (kind == null) return null;

    if (kind == LevelUpChoiceKind.abilityScoreImprovement) {
      if (_asiMethod == _AsiMethod.feat) {
        final featName = data.availableFeats
            .firstWhere((option) => option.id == _selectedListOptionId)
            .name;
        return GainRow(
          icon: Icons.checklist,
          color: AppColors.accentBlue,
          title: 'Don',
          subtitle: featName,
        );
      }
      final subtitle = [
        for (final definition in abilityScoreDefinitions)
          if ((_abilityAllocations?[definition.key] ?? 0) > 0)
            '${definition.label} +${_abilityAllocations![definition.key]}',
      ].join(', ');
      return GainRow(
        icon: Icons.checklist,
        color: AppColors.accentBlue,
        title: 'Amélioration de caractéristique',
        subtitle: subtitle,
      );
    }

    final subtitle = switch (kind) {
      LevelUpChoiceKind.subclass =>
        data.availableSubclasses
            .firstWhere((option) => option.id == _selectedListOptionId)
            .name,
      LevelUpChoiceKind.fightingStyle ||
      LevelUpChoiceKind.favoredEnemy => _selectedListOptionId! as String,
      LevelUpChoiceKind.abilityScoreImprovement => throw StateError(
        'unreachable : traité ci-dessus',
      ),
    };

    return GainRow(
      icon: Icons.checklist,
      color: AppColors.accentBlue,
      title: _choiceStepLabel(kind),
      subtitle: subtitle,
    );
  }

  /// Lignes de récapitulatif du bloc "Sorts appris" (cantrips/sorts, une
  /// [GainRow] par liste non vide) — spec visuelle direction-artistique
  /// section 5, point 2 : lacune préexistante corrigée avec ce chantier (ce
  /// bloc était absent du récapitulatif, y compris pour la branche
  /// multiclasse déjà livrée). Insérées dans [_buildSummary] après le bloc
  /// "Choix à faire", avant les [GainRow] de changement d'emplacements.
  List<GainRow> _spellsKnownSummaryGainRows(LevelUpStepData data) {
    return [
      if (_selectedNewCantrips.isNotEmpty)
        GainRow(
          icon: Icons.auto_awesome,
          color: AppColors.accentViolet,
          title: 'Nouveaux sorts mineurs',
          subtitle: _selectedNewCantrips.join(', '),
        ),
      if (_selectedNewSpells.isNotEmpty)
        GainRow(
          icon: Icons.auto_awesome,
          color: AppColors.accentViolet,
          title: 'Nouveaux sorts appris',
          subtitle: _selectedNewSpells.join(', '),
        ),
    ];
  }

  /// Ligne de récapitulatif du bloc "Invocation(s)" (Occultiste), `null` si
  /// aucune invocation n'a été choisie à ce niveau — spec visuelle
  /// direction-artistique section 5, point 3 : titre accordé singulier/
  /// pluriel, subtitle = noms joints par ", ". Insérée dans [_buildSummary]
  /// après les blocs "Sorts", avant le bandeau d'erreur.
  GainRow? _invocationSummaryGainRow(LevelUpStepData data) {
    if (_selectedInvocationIds.isEmpty) return null;
    final names = [
      for (final id in _selectedInvocationIds)
        data.availableInvocations
            .firstWhere((option) => option.id.toString() == id)
            .name,
    ];
    final plural = names.length > 1 ? 's' : '';
    return GainRow(
      icon: Icons.remove_red_eye,
      color: AppColors.accentViolet,
      title: 'Nouvelle$plural invocation$plural occultiste$plural',
      subtitle: names.join(', '),
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
                if (data.isMulticlassing) ...[
                  _multiclassInfoBanner(data),
                  const SizedBox(height: AppSpacing.sm),
                ],
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
                      for (final spellGainRow in _spellsKnownSummaryGainRows(
                        data,
                      )) ...[
                        const SizedBox(height: AppSpacing.md),
                        spellGainRow,
                      ],
                      for (final spellSlotGainRow in _spellSlotSummaryGainRows(
                        data,
                      )) ...[
                        const SizedBox(height: AppSpacing.md),
                        spellSlotGainRow,
                      ],
                      if (_invocationSummaryGainRow(data)
                          case final invocationRow?) ...[
                        const SizedBox(height: AppSpacing.md),
                        invocationRow,
                      ],
                    ],
                  ),
                ),
                if (_applyError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AlertBanner(message: _applyError!),
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
  ///
  /// **Important** : le niveau interpolé dans "Niveau N : choix requis" est
  /// `data.currentLevel + 1` — le niveau DANS la classe concernée (celle qui
  /// bloque), jamais `_targetLevel` (le niveau TOTAL du personnage) — spec
  /// visuelle direction-artistique section 6.5 : en branche multiclasse,
  /// `data.currentLevel` vaut 0 (nouvelle classe), donc ce niveau vaut
  /// toujours 1, jamais le niveau total (ex. "Barbare niveau 6" serait
  /// RAW-incohérent si le choix bloqué concerne en réalité le niveau 1 du
  /// Barbare). Pour un personnage à une seule classe (branche "continuer"),
  /// `data.currentLevel + 1 == _targetLevel`, comportement inchangé.
  Widget _buildBlocked(LevelUpStepData data) {
    final isImmediate = _levelsAppliedThisSession == 0;
    final blockedClassLevel = data.currentLevel + 1;
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
                      'Niveau $blockedClassLevel : choix requis',
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
///
/// [message] : personnalisable depuis le chantier "sorts/dons/invocations"
/// (étape "Invocations", message spécifique "Vous connaissez déjà toutes les
/// invocations occultistes disponibles." — voir la spec visuelle
/// direction-artistique section 3, un cas attendu et non défensif pour cette
/// étape précise, contrairement aux 3 autres usages de ce widget). Retombe
/// sur le texte générique historique si non fourni.
class _EmptyChoiceState extends StatelessWidget {
  const _EmptyChoiceState({
    this.message = 'Aucune option disponible pour ce choix.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 40, color: AppColors.textMuted),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
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

/// Badge "X / Y" de [_LevelUpScreenState._spellSelectionSection] et de
/// l'étape "Invocations" ([_LevelUpScreenState._buildInvocationsStep]) —
/// même patron que `_QuotaBadge` de
/// `character_creation/presentation/spells_step_screen.dart`, dupliqué ici
/// plutôt que partagé (même rationale que le reste des duplicatas de ce
/// dépôt entre l'assistant de création et la montée de niveau).
class _QuotaBadge extends StatelessWidget {
  const _QuotaBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: 1),
      ),
      child: Text(
        text,
        style: AppTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
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
