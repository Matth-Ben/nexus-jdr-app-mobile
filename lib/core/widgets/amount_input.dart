import 'dart:async';

import 'package:flutter/services.dart';

/// Interprète le texte d'un champ de montant entier : vide ou non numérique
/// donne `0` ; tout est borné à `[0, max]` (un nombre trop grand pour tenir
/// dans un `int` est lui aussi ramené à [max]).
///
/// Tolérant au collage : les espaces, séparateurs de milliers et autres
/// caractères non numériques sont ignorés ("1 234" donne 1234). Seule la
/// partie entière compte : tout ce qui suit le premier "." ou "," est
/// ignoré ("27.5" et "27,5" donnent 27, ".5" donne 0).
int parseAmountInput(String text, {required int max}) {
  final digits = _integerDigits(text);
  if (digits.isEmpty) return 0;
  final parsed = int.tryParse(digits);
  if (parsed == null || parsed > max) return max;
  return parsed;
}

/// Chiffres de la partie entière de [text] (avant le premier "." ou ",").
String _integerDigits(String text) {
  final separator = text.indexOf(RegExp('[.,]'));
  final integerPart = separator < 0 ? text : text.substring(0, separator);
  return integerPart.replaceAll(RegExp(r'\D'), '');
}

/// Ne garde que la partie entière : un collage "27.5" ou "27,5" donne "27"
/// (la partie décimale est ignorée, jamais concaténée en "275"). Un
/// séparateur *tapé* au clavier (ajout d'un seul caractère) est simplement
/// refusé.
class _IntegerPartFormatter extends TextInputFormatter {
  const _IntegerPartFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final hasSeparator = text.contains(RegExp('[.,]'));
    if (hasSeparator && text.length - oldValue.text.length == 1) {
      return oldValue;
    }
    final digits = _integerDigits(text);
    if (digits == text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// Formatters de saisie : ne garde que les chiffres de la partie entière (le
/// collage de "1 234 PO" donne "1234", celui de "27,5" donne "27") et limite
/// la longueur à celle de [max] pour qu'aucune saisie ne puisse déborder.
List<TextInputFormatter> amountInputFormatters({required int max}) => [
  const _IntegerPartFormatter(),
  LengthLimitingTextInputFormatter('$max'.length),
];

/// Pas appliqué au tick numéro [tick] (0 = premier tick) d'un appui long :
/// 1 pendant les 10 premiers ticks, puis 5 jusqu'au 25e, puis 10.
int amountRepeatStep(int tick) {
  if (tick < 10) return 1;
  if (tick < 25) return 5;
  return 10;
}

/// Délai avant le tick numéro [tick] d'un appui long : démarre à 300 ms et
/// diminue de 15 % par tick, plancher à 60 ms.
Duration amountRepeatDelay(int tick) {
  var millis = 300.0;
  for (var i = 0; i < tick && millis > 60; i++) {
    millis *= 0.85;
  }
  return Duration(milliseconds: millis < 60 ? 60 : millis.round());
}

/// Répétition accélérée d'une action (appui long sur un bouton +/-) :
/// chaque tick appelle `onTick(step)` avec le pas courant
/// ([amountRepeatStep]), à intervalle décroissant ([amountRepeatDelay]).
/// Un seul [Timer] actif à la fois ; [stop] (relâchement, annulation du
/// geste) et [dispose] (démontage) l'annulent.
class AmountRepeater {
  Timer? _timer;
  int _tick = 0;

  /// `true` tant qu'une répétition est en cours.
  bool get isRunning => _timer != null;

  /// Démarre la répétition : le premier tick arrive après le premier délai.
  void start(void Function(int step) onTick) {
    stop();
    _schedule(onTick);
  }

  void _schedule(void Function(int step) onTick) {
    _timer = Timer(amountRepeatDelay(_tick), () {
      onTick(amountRepeatStep(_tick));
      _tick++;
      // `onTick` peut avoir appelé [stop] : ne reprogramme alors rien.
      if (_timer != null) _schedule(onTick);
    });
  }

  /// Arrête la répétition en cours (sans effet s'il n'y en a pas).
  void stop() {
    _timer?.cancel();
    _timer = null;
    _tick = 0;
  }

  /// À appeler au démontage du widget propriétaire.
  void dispose() => stop();
}
