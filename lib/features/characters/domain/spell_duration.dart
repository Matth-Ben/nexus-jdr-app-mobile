/// Nature d'une durée de sort — colonne `spells.duration_kind`.
enum SpellDurationKind {
  /// `instant` : instantanée.
  instant('instant'),

  /// `timed` : durée chiffrée ([SpellDuration.value] + [SpellDuration.unit]).
  timed('timed'),

  /// `until_dispelled` : jusqu'à dissipation.
  untilDispelled('until_dispelled'),

  /// `special` : durée spéciale, non chiffrable.
  special('special'),

  /// Donnée absente (ligne ancienne, cache hors ligne, fiche partagée) ou
  /// valeur inconnue : aucune durée structurée n'est connue. Jamais écrit en
  /// base.
  unknown('');

  const SpellDurationKind(this.value);

  /// Valeur de la colonne `spells.duration_kind`.
  final String value;

  /// Kind de [raw] ; [unknown] si absent ou inconnu.
  static SpellDurationKind fromValue(Object? raw) {
    for (final kind in values) {
      if (kind != unknown && kind.value == raw) return kind;
    }
    return unknown;
  }
}

/// Unité d'une durée chiffrée — colonne `spells.duration_unit`.
enum SpellDurationUnit {
  round('round', 6),
  minute('minute', 60),
  hour('hour', 3600),
  day('day', 86400),
  week('week', 7 * 86400),
  year('year', 365 * 86400);

  const SpellDurationUnit(this.value, this.gameSeconds);

  /// Valeur de la colonne `spells.duration_unit`.
  final String value;

  /// Secondes DE JEU d'une unité (round = 6 s, an = 365 jours).
  final int gameSeconds;

  /// Unité de [raw], `null` si absente ou inconnue.
  static SpellDurationUnit? fromValue(Object? raw) {
    for (final unit in values) {
      if (unit.value == raw) return unit;
    }
    return null;
  }
}

/// Durée structurée d'un sort (colonnes `spells.duration_kind`,
/// `duration_value`, `duration_unit`), exploitable sans parser le texte
/// localisé `spells.duration` (qui reste l'affichage).
///
/// Dart pur. Ne fait AUCUN calcul d'échelle de temps (jeu -> temps réel) :
/// [gameDuration] reste exprimée en temps de jeu.
class SpellDuration {
  const SpellDuration({
    this.kind = SpellDurationKind.unknown,
    this.value,
    this.unit,
    this.concentration = false,
  });

  /// Aucune durée structurée connue.
  static const SpellDuration unknown = SpellDuration();

  /// Durée maximale chronométrable, en secondes de jeu : 10 minutes
  /// (= 100 rounds), bornes incluses.
  static const int maxTrackableGameSeconds = 600;

  /// Lit les trois colonnes de la base, tolérante : colonne absente,
  /// `null`, kind inconnu, ou `timed` incohérent (valeur <= 0 ou non
  /// entière, unité inconnue) retombent sur [unknown] (la concentration est
  /// conservée), jamais d'exception. Une valeur `value`/`unit` fournie pour
  /// un kind non `timed` est ignorée (la base l'interdit par CHECK).
  factory SpellDuration.fromColumns({
    Object? kind,
    Object? value,
    Object? unit,
    bool concentration = false,
  }) {
    final parsedKind = SpellDurationKind.fromValue(kind);
    if (parsedKind != SpellDurationKind.timed) {
      return SpellDuration(kind: parsedKind, concentration: concentration);
    }
    final parsedValue = switch (value) {
      final int v => v,
      final num v when v == v.truncate() => v.toInt(),
      _ => null,
    };
    final parsedUnit = SpellDurationUnit.fromValue(unit);
    if (parsedValue == null || parsedValue <= 0 || parsedUnit == null) {
      return SpellDuration(concentration: concentration);
    }
    return SpellDuration(
      kind: SpellDurationKind.timed,
      value: parsedValue,
      unit: parsedUnit,
      concentration: concentration,
    );
  }

  final SpellDurationKind kind;

  /// Valeur chiffrée, seulement si [isTimed].
  final int? value;

  /// Unité, seulement si [isTimed].
  final SpellDurationUnit? unit;

  /// `spells.concentration` (indépendant des colonnes de durée).
  final bool concentration;

  /// Durée chiffrée complète (kind `timed`, valeur et unité présentes).
  bool get isTimed =>
      kind == SpellDurationKind.timed && value != null && unit != null;

  /// Le sort exige de la concentration.
  bool get isConcentration => concentration;

  /// Secondes de jeu, `null` si la durée n'est pas chiffrée.
  int? get gameSeconds => isTimed ? value! * unit!.gameSeconds : null;

  /// Durée DE JEU (pas de temps réel), `null` si la durée n'est pas chiffrée.
  Duration? get gameDuration {
    final seconds = gameSeconds;
    return seconds == null ? null : Duration(seconds: seconds);
  }

  /// Chronométrable : durée chiffrée de 10 minutes de jeu au plus (bornes
  /// incluses : 10 minutes ou 100 rounds). Instantanée, jusqu'à
  /// dissipation, spéciale, inconnue ou plus longue : non.
  bool get isTrackable {
    final seconds = gameSeconds;
    return seconds != null && seconds <= maxTrackableGameSeconds;
  }

  @override
  bool operator ==(Object other) =>
      other is SpellDuration &&
      other.kind == kind &&
      other.value == value &&
      other.unit == unit &&
      other.concentration == concentration;

  @override
  int get hashCode => Object.hash(kind, value, unit, concentration);

  @override
  String toString() =>
      'SpellDuration($kind, $value, $unit, concentration: $concentration)';
}
