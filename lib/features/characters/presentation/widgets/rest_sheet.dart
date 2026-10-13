import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gain_row.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../domain/hit_dice_pool.dart';
import '../../domain/hit_dice_recovery_calculator.dart';
import '../../domain/hit_dice_spend_calculator.dart';
import '../../domain/hit_die_method.dart';
import '../../domain/rest_type.dart';

/// Résultat transmis à [showRestSheet]'s `onApply` au tap "Appliquer".
///
/// [hitDiceSpentByClassId]/[appliedGain] valent toujours vides/0 pour
/// [RestType.long] (le repos long ne propose aucune dépense de dé de vie
/// côté UI, il restaure déjà les PV au maximum), et
/// [hitDiceRecoveredByClassId] vaut toujours vide pour [RestType.short] —
/// voir `_RestSheetContentState._apply`, qui applique cette règle quel que
/// soit l'état résiduel des sections concernées (laissées affichées avant
/// un changement de segment, par exemple).
class RestSheetResult {
  const RestSheetResult({
    required this.type,
    this.hitDiceSpentByClassId = const {},
    this.appliedGain = 0,
    this.hitDiceRecoveredByClassId = const {},
    this.changePreparedSpells = false,
  });

  final RestType type;

  /// `true` si le joueur a choisi "Changer mes sorts" plutôt que "Garder ma
  /// liste" (repos long uniquement, et seulement si la feuille a été ouverte
  /// avec `canChangePreparedSpells`) : l'appelant ouvre alors la sheet
  /// "Préparer mes sorts" une fois le repos appliqué — demande utilisateur
  /// du 06/10/2026. Toujours `false` pour un repos court.
  final bool changePreparedSpells;

  /// Dés de vie dépensés à ce repos COURT, par `class_id` (chaîne — voir
  /// [HitDicePool.classId]) : une entrée par classe dont le joueur a
  /// dépensé au moins un dé — décision chef de projet du 10/10/2026 (suivi
  /// par classe, pas seulement la classe primaire). Voir
  /// `CharacterRepository.applyRest`.
  final Map<String, int> hitDiceSpentByClassId;

  /// Delta de PV réellement appliqué (déjà plafonné à `maxHp`, voir
  /// `HitDiceSpendCalculator.appliedGain`) — jamais la somme brute des dés +
  /// modificateur. Un seul total, même si plusieurs classes ont chacune
  /// dépensé des dés (le gain de PV ne distingue pas leur origine).
  final int appliedGain;

  /// Dés de vie récupérés à ce repos LONG, par `class_id` — même convention
  /// que [hitDiceSpentByClassId]. Déjà entièrement calculé (répartition
  /// automatique ou choix du joueur, voir
  /// `domain/hit_dice_recovery_calculator.dart`) : `CharacterRepository
  /// .applyRest` ne fait qu'écrire ce résultat.
  final Map<String, int> hitDiceRecoveredByClassId;

  /// Total de dés de vie dépensés, toutes classes confondues — pratique
  /// pour le message de confirmation du repos (`character_detail_screen
  /// .dart`), qui n'a pas besoin de connaître la répartition par classe.
  int get diceSpent =>
      hitDiceSpentByClassId.values.fold(0, (sum, count) => sum + count);
}

/// Ouvre la feuille "Repos" (lien texte "Prendre un repos", en fin de
/// `CharacterVitalsCard`) — sibling direct de `hp_adjustment_sheet.dart`/
/// `add_xp_sheet.dart`, même patron (`showModalBottomSheet`, fond
/// `parchment.card`, `isScrollControlled: true`).
///
/// [onApply] reçoit le [RestSheetResult] choisi par le joueur (un segment
/// est toujours sélectionné, "Repos long" par défaut) : l'appelant
/// (`character_detail_screen.dart`) est responsable d'écrire l'effet en
/// base (`CharacterRepository.applyRest`), de rafraîchir la fiche et
/// d'afficher la confirmation/erreur. La feuille se ferme immédiatement au
/// tap "Appliquer" (fire-and-forget, même patron que `showHpAdjustmentSheet`/
/// `showAddXpSheet`) — écart volontaire par rapport aux 2 feuilles sœurs :
/// l'appelant affiche ensuite un `SnackBar` de confirmation, nécessaire ici
/// car l'effet d'un repos n'est pas toujours visible sur la fiche (repos
/// court sans dé de vie dépensé, notamment).
///
/// [hitDicePools] : un pool par classe du personnage dont le dé de vie a pu
/// être résolu (`domain/hit_dice_pool.dart::HitDicePools.fromClasses`),
/// vide masque entièrement la section "dés de vie" du repos court (cas
/// défensif rare, voir `_RestHelpBlock`) — la vaste majorité des
/// personnages (mono-classe) n'a qu'un seul pool, pour lequel cette feuille
/// garde exactement le comportement d'avant cette fonctionnalité ; un
/// personnage multiclassé avec plusieurs pools peut choisir, dé par dé,
/// quelle classe dépenser/récupérer (décision chef de projet du
/// 10/10/2026). [totalLevel] : niveau total du personnage (toutes classes),
/// utilisé pour le nombre de dés récupérés au repos long (RAW 5e) — jamais
/// la seule classe primaire. [constitutionModifier] : modificateur de
/// Constitution du personnage, ajouté à chaque dé dépensé (voir
/// `HitDiceSpendCalculator`).
///
/// [canChangePreparedSpells] : `true` si le personnage a au moins un sort
/// qui se prépare — le repos long demande alors s'il faut garder la liste de
/// sorts préparés ou la changer (voir [RestSheetResult
/// .changePreparedSpells]).
Future<void> showRestSheet(
  BuildContext context, {
  required int currentHp,
  required int maxHp,
  List<HitDicePool> hitDicePools = const [],
  int totalLevel = 0,
  int constitutionModifier = 0,
  RestType initialType = RestType.long,
  bool canChangePreparedSpells = false,
  required ValueChanged<RestSheetResult> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => _RestSheetContent(
      currentHp: currentHp,
      maxHp: maxHp,
      hitDicePools: hitDicePools,
      totalLevel: totalLevel,
      constitutionModifier: constitutionModifier,
      initialType: initialType,
      canChangePreparedSpells: canChangePreparedSpells,
      onApply: onApply,
    ),
  );
}

class _RestSheetContent extends StatefulWidget {
  const _RestSheetContent({
    required this.currentHp,
    required this.maxHp,
    required this.hitDicePools,
    required this.totalLevel,
    required this.constitutionModifier,
    required this.initialType,
    required this.canChangePreparedSpells,
    required this.onApply,
  });

  final int currentHp;
  final int maxHp;
  final List<HitDicePool> hitDicePools;
  final int totalLevel;
  final int constitutionModifier;

  /// Segment présélectionné à l'ouverture — "Repos long" par défaut (spec
  /// visuelle direction-artistique d'origine). `character_vitals_card.dart`
  /// n'a plus qu'un seul bouton "Repos" (demande utilisateur du 15/09,
  /// remplace les deux boutons "Repos court"/"Repos long" du recettage
  /// direction-artistique du 13/09) et ne fournit donc plus jamais de valeur
  /// différente du défaut : le joueur choisit désormais uniquement via cette
  /// bascule segmentée, après ouverture.
  final RestType initialType;
  final bool canChangePreparedSpells;
  final ValueChanged<RestSheetResult> onApply;

  @override
  State<_RestSheetContent> createState() => _RestSheetContentState();
}

class _RestSheetContentState extends State<_RestSheetContent> {
  late RestType _type = widget.initialType;

  /// Dés à dépenser (repos court), par `classId` du pool — absence = 0 dé.
  /// Même état pour la quasi-totalité des personnages (mono-classe, un seul
  /// pool) que l'ancien champ scalaire qu'il remplace.
  final Map<Object, int> _diceToSpend = {};
  HitDieMethod _method = HitDieMethod.roll;

  /// Un jet/une valeur moyenne par dé de [_diceToSpend], par `classId` —
  /// recalculé entièrement (voir [_rerollPool]) à chaque changement de
  /// dé à dépenser ou de [_method] — "jet auto-résolu", aucun bouton
  /// "Lancer" séparé à taper avant de voir un résultat (spec visuelle
  /// direction-artistique).
  final Map<Object, List<int>> _rolledValuesByPool = {};

  /// Choix "Garder ma liste" (`false`, défaut)/"Changer mes sorts" (`true`)
  /// du repos long — voir [RestSheetResult.changePreparedSpells].
  bool _changePreparedSpells = false;

  /// Nombre de dés de vie récupérés à ce repos long (RAW 5e : moitié du
  /// niveau total, au moins 1) — fixe pour toute la durée d'ouverture de la
  /// feuille (ne dépend que de [widget.totalLevel], jamais d'un état local).
  late final int _recoveredCount = HitDiceRecoveryCalculator.recoveredCount(
    totalLevel: widget.totalLevel,
  );

  /// `true` si [_recoveredCount] ne suffit pas à tout récupérer ET qu'il
  /// existe réellement plus d'un pool parmi lesquels choisir (voir
  /// `HitDiceRecoveryCalculator.needsPlayerChoice`) — dans ce seul cas, le
  /// joueur répartit lui-même [_recoveredCount] dés entre ses classes via
  /// [_recoveryAllocation].
  late final bool _needsRecoveryChoice =
      HitDiceRecoveryCalculator.needsPlayerChoice(
        pools: widget.hitDicePools,
        recovered: _recoveredCount,
      );

  /// Répartition choisie par le joueur quand [_needsRecoveryChoice] est
  /// vrai — initialisée à une répartition par défaut (ordre des pools,
  /// même ordre que `CharacterDetail.classes` donc classe primaire
  /// d'abord), que le joueur peut ensuite réaffecter d'un pool à l'autre.
  late final Map<Object, int> _recoveryAllocation = _needsRecoveryChoice
      ? _defaultRecoveryAllocation()
      : const {};

  Map<Object, int> _defaultRecoveryAllocation() {
    var remaining = _recoveredCount;
    final allocation = <Object, int>{};
    for (final pool in HitDiceRecoveryCalculator.spentPools(
      widget.hitDicePools,
    )) {
      if (remaining <= 0) break;
      final take = math.min(pool.spent, remaining);
      allocation[pool.classId] = take;
      remaining -= take;
    }
    return allocation;
  }

  bool get _asksAboutPreparedSpells =>
      widget.canChangePreparedSpells && _type == RestType.long;

  int _diceToSpendFor(HitDicePool pool) => _diceToSpend[pool.classId] ?? 0;

  List<int> _rolledValuesFor(HitDicePool pool) =>
      _rolledValuesByPool[pool.classId] ?? const [];

  void _rerollPool(HitDicePool pool) {
    final count = _diceToSpendFor(pool);
    _rolledValuesByPool[pool.classId] = count == 0
        ? const []
        : HitDiceSpendCalculator.rollDice(
            hitDie: pool.hitDie,
            diceCount: count,
            method: _method,
          );
  }

  void _rerollAllPools() {
    for (final pool in widget.hitDicePools) {
      _rerollPool(pool);
    }
  }

  void _setDiceToSpend(HitDicePool pool, int value) {
    setState(() {
      _diceToSpend[pool.classId] = value;
      _rerollPool(pool);
    });
  }

  void _setMethod(HitDieMethod method) {
    setState(() {
      _method = method;
      _rerollAllPools();
    });
  }

  int get _totalDiceToSpend =>
      _diceToSpend.values.fold(0, (sum, count) => sum + count);

  int get _rawGain {
    final allValues = <int>[
      for (final pool in widget.hitDicePools) ..._rolledValuesFor(pool),
    ];
    return HitDiceSpendCalculator.rawGain(
      rolledOrAverageValues: allValues,
      constitutionModifier: widget.constitutionModifier,
    );
  }

  int get _appliedGain => HitDiceSpendCalculator.appliedGain(
    currentHp: widget.currentHp,
    maxHp: widget.maxHp,
    rawGain: _rawGain,
  );

  /// Nombre déjà alloué de [_recoveryAllocation] — pour afficher ce qu'il
  /// reste à répartir et plafonner les steppers.
  int get _recoveryAllocated =>
      _recoveryAllocation.values.fold(0, (sum, count) => sum + count);

  void _setRecoveryAllocation(HitDicePool pool, int value) {
    setState(() => _recoveryAllocation[pool.classId] = value);
  }

  Map<String, int> _hitDiceSpentByClassIdForApply() => {
    for (final pool in widget.hitDicePools)
      if (_diceToSpendFor(pool) > 0)
        pool.classId.toString(): _diceToSpendFor(pool),
  };

  Map<String, int> _hitDiceRecoveredByClassIdForApply() {
    final allocation = _needsRecoveryChoice
        ? _recoveryAllocation
        : HitDiceRecoveryCalculator.defaultRecovery(
            pools: widget.hitDicePools,
            recovered: _recoveredCount,
          );
    return {
      for (final entry in allocation.entries)
        if (entry.value > 0) entry.key.toString(): entry.value,
    };
  }

  void _apply() {
    widget.onApply(
      RestSheetResult(
        type: _type,
        // Toujours vide pour un repos long — voir la documentation de
        // [RestSheetResult].
        hitDiceSpentByClassId: _type == RestType.short
            ? _hitDiceSpentByClassIdForApply()
            : const {},
        appliedGain: _type == RestType.short ? _appliedGain : 0,
        hitDiceRecoveredByClassId: _type == RestType.long
            ? _hitDiceRecoveredByClassIdForApply()
            : const {},
        changePreparedSpells: _asksAboutPreparedSpells && _changePreparedSpells,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // `shrinkWrap: true` (plutôt qu'un `SingleChildScrollView` nu) :
            // se dimensionne au contenu réel pour un personnage mono-classe
            // (l'immense majorité, comportement visuel inchangé depuis
            // avant cette section), mais devient scrollable sans jamais
            // déborder (`RenderFlex overflow`) pour un personnage
            // multiclassé dont plusieurs pools de dés de vie affichés en
            // même temps (plusieurs lignes d'état + jets + tuiles) peuvent
            // dépasser la hauteur disponible de la feuille — trouvé en
            // écrivant les tests de widget de cette section.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repos',
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'PV actuels : ${widget.currentHp} / ${widget.maxHp}',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedToggle<RestType>(
                      options: const [
                        SegmentedToggleOption(
                          value: RestType.short,
                          label: 'Repos court',
                        ),
                        SegmentedToggleOption(
                          value: RestType.long,
                          label: 'Repos long',
                        ),
                      ],
                      value: _type,
                      onChanged: (type) => setState(() => _type = type),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _RestHelpBlock(
                      type: _type,
                      currentHp: widget.currentHp,
                      maxHp: widget.maxHp,
                      pools: widget.hitDicePools,
                      diceToSpendOf: _diceToSpendFor,
                      onDiceToSpendChanged: _setDiceToSpend,
                      method: _method,
                      onMethodChanged: _setMethod,
                      rolledValuesOf: _rolledValuesFor,
                      onReroll: () => setState(_rerollAllPools),
                      totalDiceToSpend: _totalDiceToSpend,
                      appliedGain: _appliedGain,
                      needsRecoveryChoice: _needsRecoveryChoice,
                      recoveredCount: _recoveredCount,
                      recoveryAllocated: _recoveryAllocated,
                      recoveryAllocationOf: (pool) =>
                          _recoveryAllocation[pool.classId] ?? 0,
                      onRecoveryAllocationChanged: _setRecoveryAllocation,
                    ),
                    if (_asksAboutPreparedSpells) ...[
                      const SizedBox(height: AppSpacing.md),
                      _PreparedSpellsChoice(
                        change: _changePreparedSpells,
                        onChanged: (change) =>
                            setState(() => _changePreparedSpells = change),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Annuler',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  // Toujours activé : un segment est toujours sélectionné,
                  // aucune saisie à valider (spec visuelle).
                  child: PrimaryButton(label: 'Appliquer', onPressed: _apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Question "sorts préparés" du repos long (classes qui préparent leurs
/// sorts) : garder la liste actuelle ou la changer une fois le repos
/// appliqué — demande utilisateur du 06/10/2026, voir
/// [RestSheetResult.changePreparedSpells].
class _PreparedSpellsChoice extends StatelessWidget {
  const _PreparedSpellsChoice({required this.change, required this.onChanged});

  final bool change;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bookmark,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'SORTS PRÉPARÉS',
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedToggle<bool>(
          options: const [
            SegmentedToggleOption(value: false, label: 'Garder ma liste'),
            SegmentedToggleOption(value: true, label: 'Changer mes sorts'),
          ],
          value: change,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          change
              ? 'Après le repos, la liste de vos sorts s\'ouvre pour '
                    'choisir ceux à préparer.'
              : 'Vos sorts préparés restent les mêmes après le repos.',
          style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Bloc d'aide sous la bascule segmentée, dont le contenu dépend du
/// [RestType] sélectionné — spec visuelle direction-artistique.
class _RestHelpBlock extends StatelessWidget {
  const _RestHelpBlock({
    required this.type,
    required this.currentHp,
    required this.maxHp,
    required this.pools,
    required this.diceToSpendOf,
    required this.onDiceToSpendChanged,
    required this.method,
    required this.onMethodChanged,
    required this.rolledValuesOf,
    required this.onReroll,
    required this.totalDiceToSpend,
    required this.appliedGain,
    required this.needsRecoveryChoice,
    required this.recoveredCount,
    required this.recoveryAllocated,
    required this.recoveryAllocationOf,
    required this.onRecoveryAllocationChanged,
  });

  final RestType type;
  final int currentHp;
  final int maxHp;
  final List<HitDicePool> pools;
  final int Function(HitDicePool pool) diceToSpendOf;
  final void Function(HitDicePool pool, int value) onDiceToSpendChanged;
  final HitDieMethod method;
  final ValueChanged<HitDieMethod> onMethodChanged;
  final List<int> Function(HitDicePool pool) rolledValuesOf;
  final VoidCallback onReroll;
  final int totalDiceToSpend;
  final int appliedGain;
  final bool needsRecoveryChoice;
  final int recoveredCount;
  final int recoveryAllocated;
  final int Function(HitDicePool pool) recoveryAllocationOf;
  final void Function(HitDicePool pool, int value) onRecoveryAllocationChanged;

  @override
  Widget build(BuildContext context) {
    if (type == RestType.short) {
      // Cas défensif rare (voir la documentation de [showRestSheet]) :
      // aucun pool de dé de vie connu, la section entière est masquée
      // plutôt que de deviner un dé — le repos court reste alors gratuit,
      // sans PV restauré (comportement identique à avant cette
      // fonctionnalité).
      if (pools.isEmpty) return const SizedBox.shrink();
      if (pools.length == 1) {
        final pool = pools.single;
        return _ShortRestHitDiceBlock(
          hitDie: pool.hitDie,
          remainingHitDice: pool.available,
          hitDiceTotal: pool.total,
          currentHp: currentHp,
          maxHp: maxHp,
          diceToSpend: diceToSpendOf(pool),
          onDiceToSpendChanged: (value) => onDiceToSpendChanged(pool, value),
          method: method,
          onMethodChanged: onMethodChanged,
          rolledValues: rolledValuesOf(pool),
          onReroll: onReroll,
          appliedGain: appliedGain,
        );
      }
      return _MulticlassShortRestHitDiceBlock(
        pools: pools,
        currentHp: currentHp,
        maxHp: maxHp,
        diceToSpendOf: diceToSpendOf,
        onDiceToSpendChanged: onDiceToSpendChanged,
        method: method,
        onMethodChanged: onMethodChanged,
        rolledValuesOf: rolledValuesOf,
        onReroll: onReroll,
        totalDiceToSpend: totalDiceToSpend,
        appliedGain: appliedGain,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restaure les PV au maximum, réinitialise les emplacements de '
          'sorts et recharge toutes les aptitudes rechargeables (repos '
          'court comme repos long).',
          style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'PV après repos : $maxHp / $maxHp',
          style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
        ),
        // Choix des dés de vie récupérés — seulement quand la récupération
        // ne suffit pas à tout restaurer ET qu'il existe réellement plus
        // d'un pool parmi lesquels choisir (voir
        // `HitDiceRecoveryCalculator.needsPlayerChoice`). Dans tous les
        // autres cas (mono-classe, ou multiclasse dont la récupération
        // suffit), rien de plus à afficher : le repos long reste aussi
        // simple qu'avant cette fonctionnalité.
        if (needsRecoveryChoice) ...[
          const SizedBox(height: AppSpacing.md),
          _LongRestRecoveryChoice(
            pools: pools,
            recoveredCount: recoveredCount,
            allocated: recoveryAllocated,
            allocationOf: recoveryAllocationOf,
            onAllocationChanged: onRecoveryAllocationChanged,
          ),
        ],
      ],
    );
  }
}

/// Contenu de [_RestHelpBlock] pour `RestType.short` quand un seul pool de
/// dé de vie est connu (personnage mono-classe, l'immense majorité) — règle
/// RAW 5e "dépenser un dé de vie", spec visuelle direction-artistique (voir
/// la documentation de [showRestSheet]). Inchangé depuis avant la prise en
/// charge du multiclassage : voir [_MulticlassShortRestHitDiceBlock] pour
/// plusieurs pools.
class _ShortRestHitDiceBlock extends StatelessWidget {
  const _ShortRestHitDiceBlock({
    required this.hitDie,
    required this.remainingHitDice,
    required this.hitDiceTotal,
    required this.currentHp,
    required this.maxHp,
    required this.diceToSpend,
    required this.onDiceToSpendChanged,
    required this.method,
    required this.onMethodChanged,
    required this.rolledValues,
    required this.onReroll,
    required this.appliedGain,
  });

  final int hitDie;
  final int remainingHitDice;
  final int hitDiceTotal;
  final int currentHp;
  final int maxHp;
  final int diceToSpend;
  final ValueChanged<int> onDiceToSpendChanged;
  final HitDieMethod method;
  final ValueChanged<HitDieMethod> onMethodChanged;
  final List<int> rolledValues;
  final VoidCallback onReroll;
  final int appliedGain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // a. Ligne d'état.
        Text(
          'Dés de vie disponibles : $remainingHitDice/$hitDiceTotal '
          '(d$hitDie)',
          style: AppTypography.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // b. Ligne "Dés à dépenser" + stepper — toujours affichée, même à
        // 0 dé disponible (stepper visible mais désactivé nativement, voir
        // `StepperCounter`).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dés à dépenser',
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            StepperCounter(
              value: diceToSpend,
              onDecrement: diceToSpend > 0
                  ? () => onDiceToSpendChanged(diceToSpend - 1)
                  : null,
              onIncrement: diceToSpend < remainingHitDice
                  ? () => onDiceToSpendChanged(diceToSpend + 1)
                  : null,
            ),
          ],
        ),
        if (remainingHitDice == 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Aucun dé de vie disponible. Le repos court reste gratuit — '
            'aucune action supplémentaire requise.',
            style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
        // c. Bloc de jet, uniquement si des dés sont dépensés.
        if (diceToSpend > 0) ...[
          const SizedBox(height: AppSpacing.md),
          SegmentedToggle<HitDieMethod>(
            options: const [
              SegmentedToggleOption(
                value: HitDieMethod.roll,
                label: 'Lancer les dés',
              ),
              SegmentedToggleOption(
                value: HitDieMethod.average,
                label: 'Valeur moyenne',
              ),
            ],
            value: method,
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final value in rolledValues) _HitDieResultTile(value: value),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: method == HitDieMethod.roll
                ? InkWell(
                    onTap: onReroll,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
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
                  )
                : Text(
                    '(moitié du dé arrondie au supérieur, +1, par dé)',
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Container(height: 1, color: AppColors.gaugeTrack),
          ),
          const SizedBox(height: AppSpacing.sm),
          // d. PV déjà au maximum : le repos ne restaurera rien de plus,
          // mais n'empêche pas la dépense des dés (RAW : les dés sont
          // dépensés même si le jet est "gaspillé").
          if (currentHp >= maxHp) ...[
            const InfoBanner(
              icon: Icons.info_outline,
              message:
                  'PV déjà au maximum : ce repos ne restaurera aucun PV '
                  'supplémentaire.',
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          GainRow(
            icon: Icons.favorite,
            color: AppColors.accentBrick,
            title: 'PV restaurés',
            subtitle: '$currentHp → ${currentHp + appliedGain} (+$appliedGain)',
          ),
        ],
      ],
    );
  }
}

/// Contenu de [_RestHelpBlock] pour `RestType.short` quand **plusieurs**
/// pools de dés de vie sont connus (personnage multiclassé dont au moins
/// deux classes ont un dé de vie résolu) — décision chef de projet du
/// 10/10/2026 : le joueur choisit, pool par pool, combien de dés de CHAQUE
/// classe il dépense (règle RAW 5e, explicitement laissée au choix du
/// joueur dès que plusieurs types sont en jeu). Jet/valeur moyenne restent
/// un choix UNIQUE partagé par tous les pools de ce repos (un seul
/// `SegmentedToggle`, pas un par pool) — spec simplifiée volontaire,
/// cohérente avec `_ShortRestHitDiceBlock` (déjà un choix unique par repos
/// en mono-classe).
class _MulticlassShortRestHitDiceBlock extends StatelessWidget {
  const _MulticlassShortRestHitDiceBlock({
    required this.pools,
    required this.currentHp,
    required this.maxHp,
    required this.diceToSpendOf,
    required this.onDiceToSpendChanged,
    required this.method,
    required this.onMethodChanged,
    required this.rolledValuesOf,
    required this.onReroll,
    required this.totalDiceToSpend,
    required this.appliedGain,
  });

  final List<HitDicePool> pools;
  final int currentHp;
  final int maxHp;
  final int Function(HitDicePool pool) diceToSpendOf;
  final void Function(HitDicePool pool, int value) onDiceToSpendChanged;
  final HitDieMethod method;
  final ValueChanged<HitDieMethod> onMethodChanged;
  final List<int> Function(HitDicePool pool) rolledValuesOf;
  final VoidCallback onReroll;
  final int totalDiceToSpend;
  final int appliedGain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final pool in pools) ...[
          _PoolSpendRow(
            pool: pool,
            diceToSpend: diceToSpendOf(pool),
            onChanged: (value) => onDiceToSpendChanged(pool, value),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (totalDiceToSpend > 0) ...[
          SegmentedToggle<HitDieMethod>(
            options: const [
              SegmentedToggleOption(
                value: HitDieMethod.roll,
                label: 'Lancer les dés',
              ),
              SegmentedToggleOption(
                value: HitDieMethod.average,
                label: 'Valeur moyenne',
              ),
            ],
            value: method,
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final pool in pools)
            if (diceToSpendOf(pool) > 0) ...[
              Text(
                '${pool.className} (d${pool.hitDie})',
                style: AppTypography.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final value in rolledValuesOf(pool))
                    _HitDieResultTile(value: value),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          Center(
            child: method == HitDieMethod.roll
                ? InkWell(
                    onTap: onReroll,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
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
                  )
                : Text(
                    '(moitié du dé arrondie au supérieur, +1, par dé)',
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Container(height: 1, color: AppColors.gaugeTrack),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (currentHp >= maxHp) ...[
            const InfoBanner(
              icon: Icons.info_outline,
              message:
                  'PV déjà au maximum : ce repos ne restaurera aucun PV '
                  'supplémentaire.',
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          GainRow(
            icon: Icons.favorite,
            color: AppColors.accentBrick,
            title: 'PV restaurés',
            subtitle: '$currentHp → ${currentHp + appliedGain} (+$appliedGain)',
          ),
        ],
      ],
    );
  }
}

/// Ligne "état + stepper" d'UN pool pour
/// [_MulticlassShortRestHitDiceBlock] — même contenu que les parties a/b de
/// [_ShortRestHitDiceBlock], préfixé du nom de classe pour distinguer les
/// pools entre eux.
class _PoolSpendRow extends StatelessWidget {
  const _PoolSpendRow({
    required this.pool,
    required this.diceToSpend,
    required this.onChanged,
  });

  final HitDicePool pool;
  final int diceToSpend;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${pool.className} — dés de vie disponibles : ${pool.available}/'
          '${pool.total} (d${pool.hitDie})',
          style: AppTypography.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dés à dépenser',
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            StepperCounter(
              value: diceToSpend,
              onDecrement: diceToSpend > 0
                  ? () => onChanged(diceToSpend - 1)
                  : null,
              onIncrement: diceToSpend < pool.available
                  ? () => onChanged(diceToSpend + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// Répartition des dés de vie récupérés entre les pools d'un personnage
/// multiclassé, quand [recoveredCount] ne suffit pas à tout restaurer —
/// décision chef de projet du 10/10/2026 : le joueur choisit lui-même, par
/// classe, quels dés récupérer en priorité (RAW 5e silencieux sur ce point
/// précis). Chaque stepper reste borné à `[0, pool.spent]`, et la somme de
/// toutes les allocations ne dépasse jamais [recoveredCount] (voir
/// [_RestSheetContentState._setRecoveryAllocation]/les bornes `onIncrement`
/// ci-dessous) : diminuer un pool libère un budget qu'un autre pool peut
/// ensuite recevoir.
class _LongRestRecoveryChoice extends StatelessWidget {
  const _LongRestRecoveryChoice({
    required this.pools,
    required this.recoveredCount,
    required this.allocated,
    required this.allocationOf,
    required this.onAllocationChanged,
  });

  final List<HitDicePool> pools;
  final int recoveredCount;
  final int allocated;
  final int Function(HitDicePool pool) allocationOf;
  final void Function(HitDicePool pool, int value) onAllocationChanged;

  @override
  Widget build(BuildContext context) {
    final remaining = recoveredCount - allocated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dés de vie récupérés : $recoveredCount — répartissez-les entre '
          'vos classes',
          style: AppTypography.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final pool in HitDiceRecoveryCalculator.spentPools(pools)) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${pool.className} (d${pool.hitDie}) — ${pool.spent} '
                  'dépensé(s)',
                  style: AppTypography.body(fontSize: 13),
                ),
              ),
              StepperCounter(
                value: allocationOf(pool),
                onDecrement: allocationOf(pool) > 0
                    ? () => onAllocationChanged(pool, allocationOf(pool) - 1)
                    : null,
                onIncrement: allocationOf(pool) < pool.spent && remaining > 0
                    ? () => onAllocationChanged(pool, allocationOf(pool) + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          'Reste à répartir : $remaining',
          style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Une tuile de résultat de dé de vie (28×28px, spec visuelle
/// direction-artistique) — non interactive, purement un affichage de
/// valeur.
class _HitDieResultTile extends StatelessWidget {
  const _HitDieResultTile({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: 1.5),
      ),
      child: Text(
        '$value',
        style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
