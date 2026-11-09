import 'dart:async';

import 'package:flutter/services.dart';

/// Interprète le texte d'un champ de montant entier : vide ou non numérique
/// donne `0` ; tout est borné à `[0, max]` (un nombre trop grand pour tenir
/// dans un `int` est lui aussi ramené à [max]).
///
/// Tolérant au collage : les espaces, séparateurs de milliers et autres
/// caractères non numériques sont ignorés ("1 234" donne 1234).
int parseAmountInput(String text, {required int max}) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 0;
  final parsed = int.tryParse(digits);
  if (parsed == null || parsed > max) return max;
  return parsed;
}

/// Formatters de saisie : ne garde que les chiffres (le collage de
/// "1 234 PO" donne "1234") et limite la longueur à celle de [max] pour
/// qu'aucune saisie ne puisse déborder.
List<TextInputFormatter> amountInputFormatters({required int max}) => [
  FilteringTextInputFormatter.digitsOnly,
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
