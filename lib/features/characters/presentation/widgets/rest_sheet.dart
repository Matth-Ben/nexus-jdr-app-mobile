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
import '../../domain/hit_dice_spend_calculator.dart';
import '../../domain/hit_die_method.dart';
import '../../domain/rest_type.dart';

/// Résultat transmis à [showRestSheet]'s `onApply` au tap "Appliquer".
///
/// [diceSpent]/[appliedGain] valent toujours 0 pour [RestType.long] : le
/// repos long ne propose aucune dépense de dé de vie côté UI (il restaure
/// déjà les PV au maximum) — voir `_RestSheetContentState._apply`, qui les
/// force à 0 pour ce type quel que soit l'état résiduel de la section "dés
/// de vie" (laissée affichée avec une valeur non nulle avant un changement
/// de segment, par exemple).
class RestSheetResult {
  const RestSheetResult({
    required this.type,
    this.diceSpent = 0,
    this.appliedGain = 0,
  });

  final RestType type;

  /// Nombre de dés de vie dépensés (repos court uniquement).
  final int diceSpent;

  /// Delta de PV réellement appliqué (déjà plafonné à `maxHp`, voir
  /// `HitDiceSpendCalculator.appliedGain`) — jamais la somme brute des dés +
  /// modificateur.
  final int appliedGain;
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
/// [hitDie] : dé de vie de la classe principale du personnage (`classes
/// .hit_die`, voir `domain/character_detail_class_row.dart::hitDie`),
/// `null` masque entièrement la section "dés de vie" du repos court (cas
/// défensif rare, voir `_RestHelpBlock`) — [hitDiceTotal]/[hitDiceSpent]
/// sont alors ignorés. [constitutionModifier] : modificateur de
/// Constitution du personnage, ajouté à chaque dé dépensé (voir
/// `HitDiceSpendCalculator`).
Future<void> showRestSheet(
  BuildContext context, {
  required int currentHp,
  required int maxHp,
  int? hitDie,
  int hitDiceTotal = 0,
  int hitDiceSpent = 0,
  int constitutionModifier = 0,
  required ValueChanged<RestSheetResult> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => _RestSheetContent(
      currentHp: currentHp,
      maxHp: maxHp,
      hitDie: hitDie,
      hitDiceTotal: hitDiceTotal,
      hitDiceSpent: hitDiceSpent,
      constitutionModifier: constitutionModifier,
      onApply: onApply,
    ),
  );
}

class _RestSheetContent extends StatefulWidget {
  const _RestSheetContent({
    required this.currentHp,
    required this.maxHp,
    required this.hitDie,
    required this.hitDiceTotal,
    required this.hitDiceSpent,
    required this.constitutionModifier,
    required this.onApply,
  });

  final int currentHp;
  final int maxHp;
  final int? hitDie;
  final int hitDiceTotal;
  final int hitDiceSpent;
  final int constitutionModifier;
  final ValueChanged<RestSheetResult> onApply;

  @override
  State<_RestSheetContent> createState() => _RestSheetContentState();
}

class _RestSheetContentState extends State<_RestSheetContent> {
  // Valeur par défaut "Repos long" — spec visuelle direction-artistique.
  RestType _type = RestType.long;

  int _diceToSpend = 0;
  HitDieMethod _method = HitDieMethod.roll;

  /// Un jet/une valeur moyenne par dé de [_diceToSpend], recalculé
  /// entièrement (voir [_rerollAll]) à chaque changement de [_diceToSpend]
  /// ou de [_method] — "jet auto-résolu", aucun bouton "Lancer" séparé à
  /// taper avant de voir un résultat (spec visuelle direction-artistique).
  List<int> _rolledValues = const [];

  int get _remainingHitDice =>
      (widget.hitDiceTotal - widget.hitDiceSpent).clamp(0, widget.hitDiceTotal);

  void _rerollAll() {
    final hitDie = widget.hitDie;
    _rolledValues = (hitDie == null || _diceToSpend == 0)
        ? const []
        : HitDiceSpendCalculator.rollDice(
            hitDie: hitDie,
            diceCount: _diceToSpend,
            method: _method,
          );
  }

  void _setDiceToSpend(int value) {
    setState(() {
      _diceToSpend = value;
      _rerollAll();
    });
  }

  void _setMethod(HitDieMethod method) {
    setState(() {
      _method = method;
      _rerollAll();
    });
  }

  int get _rawGain => HitDiceSpendCalculator.rawGain(
    rolledOrAverageValues: _rolledValues,
    constitutionModifier: widget.constitutionModifier,
  );

  int get _appliedGain => HitDiceSpendCalculator.appliedGain(
    currentHp: widget.currentHp,
    maxHp: widget.maxHp,
    rawGain: _rawGain,
  );

  void _apply() {
    widget.onApply(
      RestSheetResult(
        type: _type,
        // Toujours 0 pour un repos long — voir la documentation de
        // [RestSheetResult].
        diceSpent: _type == RestType.short ? _diceToSpend : 0,
        appliedGain: _type == RestType.short ? _appliedGain : 0,
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
              hitDie: widget.hitDie,
              remainingHitDice: _remainingHitDice,
              hitDiceTotal: widget.hitDiceTotal,
              diceToSpend: _diceToSpend,
              onDiceToSpendChanged: _setDiceToSpend,
              method: _method,
              onMethodChanged: _setMethod,
              rolledValues: _rolledValues,
              onReroll: () => setState(_rerollAll),
              appliedGain: _appliedGain,
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

/// Bloc d'aide sous la bascule segmentée, dont le contenu dépend du
/// [RestType] sélectionné — spec visuelle direction-artistique.
class _RestHelpBlock extends StatelessWidget {
  const _RestHelpBlock({
    required this.type,
    required this.currentHp,
    required this.maxHp,
    required this.hitDie,
    required this.remainingHitDice,
    required this.hitDiceTotal,
    required this.diceToSpend,
    required this.onDiceToSpendChanged,
    required this.method,
    required this.onMethodChanged,
    required this.rolledValues,
    required this.onReroll,
    required this.appliedGain,
  });

  final RestType type;
  final int currentHp;
  final int maxHp;
  final int? hitDie;
  final int remainingHitDice;
  final int hitDiceTotal;
  final int diceToSpend;
  final ValueChanged<int> onDiceToSpendChanged;
  final HitDieMethod method;
  final ValueChanged<HitDieMethod> onMethodChanged;
  final List<int> rolledValues;
  final VoidCallback onReroll;
  final int appliedGain;

  @override
  Widget build(BuildContext context) {
    if (type == RestType.short) {
      // Cas défensif rare (voir la documentation de [showRestSheet]) :
      // aucun dé de vie de classe connu, la section entière est masquée
      // plutôt que de deviner un dé — le repos court reste alors gratuit,
      // sans PV restauré (comportement identique à avant cette
      // fonctionnalité).
      final die = hitDie;
      if (die == null) return const SizedBox.shrink();
      return _ShortRestHitDiceBlock(
        hitDie: die,
        remainingHitDice: remainingHitDice,
        hitDiceTotal: hitDiceTotal,
        currentHp: currentHp,
        maxHp: maxHp,
        diceToSpend: diceToSpend,
        onDiceToSpendChanged: onDiceToSpendChanged,
        method: method,
        onMethodChanged: onMethodChanged,
        rolledValues: rolledValues,
        onReroll: onReroll,
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
      ],
    );
  }
}

/// Contenu de [_RestHelpBlock] pour `RestType.short` quand un dé de vie de
/// classe est connu — règle RAW 5e "dépenser un dé de vie", spec visuelle
/// direction-artistique (voir la documentation de [showRestSheet]).
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
