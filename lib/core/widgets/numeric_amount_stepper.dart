import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'amount_input.dart';

/// Variante opt-in de [StepperCounter] pour les montants qui peuvent être
/// grands (PV, monnaies) : même habillage de boutons +/- (carrés
/// `parchment.card-alt`, bordure `wood.light`, zone de tap 44x44), mais la
/// valeur centrale est un champ numérique éditable (clavier numérique,
/// chiffres seulement, vide = 0, borné à `[0, max]`) et un appui long sur
/// +/- répète l'action avec une accélération ([AmountRepeater]).
///
/// [StepperCounter] reste inchangé (±1) pour ses autres usages.
///
/// Contrôlé : le parent possède [value] et le met à jour dans [onChanged].
/// Si [max] diminue sous la valeur courante, c'est au parent de la ramener
/// dans les bornes (le champ suit [value]).
class NumericAmountStepper extends StatefulWidget {
  const NumericAmountStepper({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.decrementLabel,
    required this.incrementLabel,
    this.fieldLabel,
    this.autofocus = false,
    super.key,
  });

  final int value;

  /// Borne haute incluse ; la borne basse est toujours 0.
  final int max;

  final ValueChanged<int> onChanged;

  /// Libellés d'accessibilité des boutons (fournis traduits par l'appelant,
  /// `core/widgets` n'embarque pas de textes).
  final String decrementLabel;
  final String incrementLabel;

  /// Libellé d'accessibilité du champ.
  final String? fieldLabel;

  final bool autofocus;

  @override
  State<NumericAmountStepper> createState() => _NumericAmountStepperState();
}

class _NumericAmountStepperState extends State<NumericAmountStepper> {
  late final TextEditingController _controller;
  final AmountRepeater _repeater = AmountRepeater();

  /// Dernière valeur connue, à jour même entre deux taps rapprochés avant
  /// que le parent ait reconstruit ce widget.
  late int _latest;

  @override
  void initState() {
    super.initState();
    _latest = widget.value;
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(NumericAmountStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    _latest = widget.value;
    _syncText();
  }

  @override
  void dispose() {
    _repeater.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Champ vide pour 0 (le hint "0" s'affiche), pour que la saisie d'un
  /// premier chiffre ne donne pas "05".
  static String _format(int value) => value == 0 ? '' : '$value';

  void _setText(int value) {
    final text = _format(value);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _syncText() {
    // Ne réécrit pas le champ si le texte courant dit déjà la même valeur
    // (ex. champ vide = 0).
    final current = parseAmountInput(_controller.text, max: widget.max);
    if (current != widget.value) _setText(widget.value);
  }

  void _handleTextChanged(String text) {
    final parsed = parseAmountInput(text, max: widget.max);
    // Valeur écrêtée à max : le champ reflète la borne.
    if (text.isNotEmpty && _format(parsed) != text) _setText(parsed);
    if (parsed != _latest) {
      _latest = parsed;
      widget.onChanged(parsed);
    }
  }

  /// Applique [delta] (borné à `[0, max]`) ; `false` si la valeur n'a pas
  /// évolué (borne déjà atteinte).
  bool _step(int delta) {
    final next = (_latest + delta).clamp(0, widget.max);
    if (next == _latest) return false;
    _latest = next;
    widget.onChanged(next);
    return true;
  }

  /// Dernier pas de répétition appliqué : un retour haptique léger marque
  /// chaque changement de palier (1, 5, 10).
  int _lastRepeatStep = 1;

  void _startRepeat(int sign) {
    _lastRepeatStep = 1;
    _repeater.start((step) {
      // Borne atteinte : inutile de continuer à tourner sans effet.
      if (!_step(sign * step)) {
        _repeater.stop();
        return;
      }
      if (step != _lastRepeatStep) {
        _lastRepeatStep = step;
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RepeatButton(
          icon: Icons.remove,
          semanticLabel: widget.decrementLabel,
          enabled: widget.value > 0,
          onStep: () => _step(-1),
          onRepeatStart: () => _startRepeat(-1),
          onRepeatStop: _repeater.stop,
        ),
        SizedBox(
          width: 112,
          child: Semantics(
            label: widget.fieldLabel,
            textField: true,
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: amountInputFormatters(max: widget.max),
              onChanged: _handleTextChanged,
              style: AppTypography.body(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        ),
        _RepeatButton(
          icon: Icons.add,
          semanticLabel: widget.incrementLabel,
          enabled: widget.value < widget.max,
          onStep: () => _step(1),
          onRepeatStart: () => _startRepeat(1),
          onRepeatStop: _repeater.stop,
        ),
      ],
    );
  }
}

class _RepeatButton extends StatefulWidget {
  const _RepeatButton({
    required this.icon,
    required this.semanticLabel,
    required this.enabled,
    required this.onStep,
    required this.onRepeatStart,
    required this.onRepeatStop,
  });

  final IconData icon;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onStep;
  final VoidCallback onRepeatStart;
  final VoidCallback onRepeatStop;

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  static const double _tapTargetSize = 44;
  static const double _visualSize = 28;

  /// État "pressé" sobre (tap ou appui long en cours) : fond
  /// `parchment.card`, bordure `wood.medium`.
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(_RepeatButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed && widget.enabled;
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.semanticLabel,
        excludeSemantics: true,
        onTap: widget.enabled ? widget.onStep : null,
        child: Listener(
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? widget.onStep : null,
            onLongPressStart: widget.enabled
                ? (_) => widget.onRepeatStart()
                : null,
            onLongPressEnd: (_) => widget.onRepeatStop(),
            onLongPressCancel: widget.onRepeatStop,
            child: SizedBox(
              width: _tapTargetSize,
              height: _tapTargetSize,
              child: Center(
                child: Container(
                  width: _visualSize,
                  height: _visualSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pressed
                        ? AppColors.parchmentCard
                        : AppColors.parchmentCardAlt,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: pressed
                          ? AppColors.woodMedium
                          : AppColors.woodLight,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
