import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/numeric_amount_stepper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/currency_conversion.dart';
import '../../domain/currency_kind.dart';

/// Ouvre la sheet de conversion de pièces (bouton "Changer" de
/// `currency_adjustment_sheet.dart`) : choix de la pièce source, de la pièce
/// cible, du montant, avec aperçu du résultat avant validation (voir
/// `domain/currency_conversion.dart` pour les taux et les règles).
///
/// [balances] : soldes actuels des 5 monnaies. [onApply] reçoit les nouveaux
/// soldes **absolus** des deux pièces touchées (débit + crédit ensemble :
/// l'appelant doit les écrire en une seule fois, jamais séparément).
Future<void> showCurrencyConversionSheet(
  BuildContext context, {
  required Map<CurrencyKind, int> balances,
  required ValueChanged<Map<CurrencyKind, int>> onApply,
  CurrencyKind? initialSource,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => _CurrencyConversionSheetContent(
      balances: balances,
      initialSource: initialSource,
      onApply: onApply,
    ),
  );
}

class _CurrencyConversionSheetContent extends StatefulWidget {
  const _CurrencyConversionSheetContent({
    required this.balances,
    required this.initialSource,
    required this.onApply,
  });

  final Map<CurrencyKind, int> balances;
  final CurrencyKind? initialSource;
  final ValueChanged<Map<CurrencyKind, int>> onApply;

  @override
  State<_CurrencyConversionSheetContent> createState() =>
      _CurrencyConversionSheetContentState();
}

class _CurrencyConversionSheetContentState
    extends State<_CurrencyConversionSheetContent> {
  late final List<CurrencyKind> _currencies = convertibleCurrencies(
    widget.balances,
  );
  late CurrencyKind _from;
  late CurrencyKind _to;
  int _amount = 0;

  int _balanceOf(CurrencyKind currency) => widget.balances[currency] ?? 0;

  /// Sources proposées : celles qui ont un solde à convertir.
  List<CurrencyKind> get _sources =>
      _currencies.where((c) => _balanceOf(c) > 0).toList();

  @override
  void initState() {
    super.initState();
    final sources = _sources;
    final initial = widget.initialSource;
    _from = initial != null && sources.contains(initial)
        ? initial
        : (sources.isNotEmpty ? sources.first : CurrencyKind.gold);
    _to = _defaultTargetFor(_from);
  }

  /// Cible par défaut : la pièce juste en dessous dans l'ordre de valeur, ou
  /// celle juste au-dessus pour le cuivre.
  CurrencyKind _defaultTargetFor(CurrencyKind from) {
    final index = _currencies.indexOf(from);
    if (index >= 0 && index < _currencies.length - 1) {
      return _currencies[index + 1];
    }
    return _currencies.firstWhere((c) => c != from);
  }

  void _selectFrom(CurrencyKind currency) {
    setState(() {
      final previous = _from;
      _from = currency;
      if (_to == currency) _to = previous;
      final max = _balanceOf(currency);
      if (_amount > max) _amount = max;
    });
  }

  void _selectTo(CurrencyKind currency) {
    setState(() {
      final previous = _to;
      _to = currency;
      if (_from == currency) {
        // Échange source/cible : la nouvelle source doit avoir un solde.
        if (_balanceOf(previous) > 0) {
          _from = previous;
          final max = _balanceOf(previous);
          if (_amount > max) _amount = max;
        } else {
          _to = previous;
        }
      }
    });
  }

  CurrencyConversion get _conversion => convertCurrency(
    from: _from,
    to: _to,
    amount: _amount,
    balanceFrom: _balanceOf(_from),
  );

  void _apply() {
    final conversion = _conversion;
    if (!conversion.isValid) return;
    widget.onApply({
      _from: _balanceOf(_from) - conversion.spent,
      _to: _balanceOf(_to) + conversion.obtained,
    });
    Navigator.of(context).pop();
  }

  Widget _chips(
    List<CurrencyKind> options,
    CurrencyKind selected,
    ValueChanged<CurrencyKind> onSelected,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final currency in options)
          ChoiceChip(
            label: Text('${currency.unitLabel} · ${_balanceOf(currency)}'),
            selected: currency == selected,
            onSelected: (_) => onSelected(currency),
          ),
      ],
    );
  }

  TextStyle get _sectionStyle => AppTypography.body(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sources = _sources;
    final conversion = _conversion;

    return SafeArea(
      child: SingleChildScrollView(
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
                l10n.currencyConversionSheetTitle,
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (sources.isEmpty)
                Text(
                  l10n.currencyConversionSheetNothingToConvert,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else ...[
                Text(
                  l10n.currencyConversionSheetFromLabel,
                  style: _sectionStyle,
                ),
                const SizedBox(height: AppSpacing.xs),
                _chips(sources, _from, _selectFrom),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.currencyConversionSheetToLabel, style: _sectionStyle),
                const SizedBox(height: AppSpacing.xs),
                _chips(
                  _currencies.where((c) => c != _from).toList(),
                  _to,
                  _selectTo,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.currencyConversionSheetAmountLabel,
                  style: _sectionStyle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: NumericAmountStepper(
                    value: _amount,
                    max: _balanceOf(_from),
                    autofocus: true,
                    fieldLabel: l10n.currencyConversionSheetAmountLabel,
                    decrementLabel: l10n.numericAmountDecreaseLabel,
                    incrementLabel: l10n.numericAmountIncreaseLabel,
                    onChanged: (value) => setState(() => _amount = value),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _Preview(conversion: conversion, from: _from, to: _to),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: l10n.currencyConversionSheetCancelButton,
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.currencyConversionSheetApplyButton,
                      onPressed: conversion.isValid ? _apply : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aperçu du résultat : rien tant qu'aucun montant n'est saisi, message
/// d'erreur si le montant ne suffit pas pour une pièce entière, sinon
/// "X PA contre Y PO" (+ reste non converti).
class _Preview extends StatelessWidget {
  const _Preview({
    required this.conversion,
    required this.from,
    required this.to,
  });

  final CurrencyConversion conversion;
  final CurrencyKind from;
  final CurrencyKind to;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = conversion.error;

    if (error == CurrencyConversionError.tooSmall) {
      return Text(
        l10n.currencyConversionSheetTooSmall,
        style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
      );
    }
    if (!conversion.isValid) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currencyConversionSheetPreview(
            conversion.spent,
            from.unitLabel,
            conversion.obtained,
            to.unitLabel,
          ),
          style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        if (conversion.unconverted > 0)
          Text(
            l10n.currencyConversionSheetRemainder(
              conversion.unconverted,
              from.unitLabel,
            ),
            style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
          ),
      ],
    );
  }
}
