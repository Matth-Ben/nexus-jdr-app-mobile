import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../characters/domain/currency_kind.dart';
import '../../domain/group_treasure.dart';

/// Callback de validation — voit `Map<CurrencyKind, int>` des montants que le
/// joueur veut réclamer (jamais nuls, déjà plafonnés au solde courant du
/// butin, voir [_ClaimCurrencyFieldState]).
typedef ClaimGroupTreasureCurrencyCallback = void Function(
  Map<CurrencyKind, int> amounts,
);

/// Même ordre d'affichage que `add_reward_sheet.dart` ("PO/PA/PC/PP/PE").
const List<CurrencyKind> _currencyFieldsOrder = [
  CurrencyKind.gold,
  CurrencyKind.silver,
  CurrencyKind.copper,
  CurrencyKind.platinum,
  CurrencyKind.electrum,
];

/// Sheet "S'ATTRIBUER DE LA MONNAIE" — variante de `add_reward_sheet.dart`
/// section "MONNAIE" (même grille de 5 champs), chaque champ plafonné au
/// solde courant du butin commun ([treasure]) plutôt qu'un montant à
/// ajouter — voir `docs/cahier-des-charges/12-partage-et-groupes.md` section
/// 2.2. L'appelant (`group_screen.dart`) réalise l'appel réseau
/// (`claim_group_treasure_currency` par dénomination) et gère le cas
/// partiel, cette sheet se contente de collecter des montants valides.
Future<void> showClaimGroupTreasureCurrencySheet(
  BuildContext context, {
  required GroupTreasure treasure,
  required ClaimGroupTreasureCurrencyCallback onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ClaimGroupTreasureCurrencySheetContent(
      treasure: treasure,
      onApply: onApply,
    ),
  );
}

class _ClaimGroupTreasureCurrencySheetContent extends StatefulWidget {
  const _ClaimGroupTreasureCurrencySheetContent({
    required this.treasure,
    required this.onApply,
  });

  final GroupTreasure treasure;
  final ClaimGroupTreasureCurrencyCallback onApply;

  @override
  State<_ClaimGroupTreasureCurrencySheetContent> createState() =>
      _ClaimGroupTreasureCurrencySheetContentState();
}

class _ClaimGroupTreasureCurrencySheetContentState
    extends State<_ClaimGroupTreasureCurrencySheetContent> {
  final Map<CurrencyKind, TextEditingController> _controllers = {
    for (final currency in _currencyFieldsOrder)
      currency: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers.values) {
      controller.addListener(_handleChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.removeListener(_handleChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  int _maxFor(CurrencyKind currency) => switch (currency) {
    CurrencyKind.platinum => widget.treasure.currencyPp,
    CurrencyKind.gold => widget.treasure.currencyGp,
    CurrencyKind.electrum => widget.treasure.currencyEp,
    CurrencyKind.silver => widget.treasure.currencySp,
    CurrencyKind.copper => widget.treasure.currencyCp,
  };

  Map<CurrencyKind, int> get _amounts {
    final amounts = <CurrencyKind, int>{};
    for (final entry in _controllers.entries) {
      final amount = int.tryParse(entry.value.text) ?? 0;
      if (amount > 0) amounts[entry.key] = amount;
    }
    return amounts;
  }

  bool get _canApply => _amounts.isNotEmpty;

  void _submit() {
    widget.onApply(_amounts);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.6,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: "S'ATTRIBUER DE LA MONNAIE"),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _ClaimCurrencyField(
                                currency: _currencyFieldsOrder[i],
                                controller:
                                    _controllers[_currencyFieldsOrder[i]]!,
                                max: _maxFor(_currencyFieldsOrder[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          for (var i = 3; i < 5; i++) ...[
                            if (i > 3) const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _ClaimCurrencyField(
                                currency: _currencyFieldsOrder[i],
                                controller:
                                    _controllers[_currencyFieldsOrder[i]]!,
                                max: _maxFor(_currencyFieldsOrder[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
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
                      child: PrimaryButton(
                        label: "S'attribuer",
                        onPressed: _canApply ? _submit : null,
                      ),
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

/// Champ de monnaie plafonné à [max] (solde courant du butin) : toute saisie
/// au-delà est ramenée à [max] immédiatement (voir [_clamp]) — "plafonné au
/// solde" de la spec de la tâche.
class _ClaimCurrencyField extends StatefulWidget {
  const _ClaimCurrencyField({
    required this.currency,
    required this.controller,
    required this.max,
  });

  final CurrencyKind currency;
  final TextEditingController controller;
  final int max;

  @override
  State<_ClaimCurrencyField> createState() => _ClaimCurrencyFieldState();
}

class _ClaimCurrencyFieldState extends State<_ClaimCurrencyField> {
  void _clamp(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null) return;
    if (parsed > widget.max) {
      final clamped = widget.max.toString();
      widget.controller.value = TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.max <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.currency.unitLabel,
          style: AppTypography.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          enabled: !disabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _clamp,
          decoration: InputDecoration(hintText: '0 / ${widget.max}'),
        ),
      ],
    );
  }
}
