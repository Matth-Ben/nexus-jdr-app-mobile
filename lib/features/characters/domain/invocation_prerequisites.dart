import 'warlock_pact.dart';

/// Prérequis structurés d'une invocation occultiste, parsés depuis
/// `invocations.prerequisites` (jsonb) — clés optionnelles `level` (niveau
/// d'Occultiste minimum), `pact` (`'lame'`/`'chaine'`/`'grimoire'`) et
/// `cantrip_spell_id` (`spells.id` du sort mineur requis). La clé `text`
/// (affichage) n'est pas gérée ici, voir
/// `LevelUpInvocationOption.prerequisiteText`.
///
/// Parsing tolérant : une clé absente, de mauvais type ou de valeur inconnue
/// signifie "pas de contrainte" — jamais d'exception.
class InvocationPrerequisites {
  const InvocationPrerequisites({this.level, this.pact, this.cantripSpellId});

  /// Aucune contrainte structurée.
  static const none = InvocationPrerequisites();

  factory InvocationPrerequisites.fromJson(Object? json) {
    if (json is! Map) return none;

    final rawLevel = json['level'];
    final level = rawLevel is num ? rawLevel.toInt() : null;

    final pact = WarlockPact.fromKey(
      json['pact'] is String ? json['pact'] as String : null,
    );

    final rawCantrip = json['cantrip_spell_id'];
    final cantripSpellId = rawCantrip is num ? rawCantrip.toInt() : null;

    return InvocationPrerequisites(
      level: level != null && level > 0 ? level : null,
      pact: pact,
      cantripSpellId: cantripSpellId,
    );
  }

  final int? level;
  final WarlockPact? pact;
  final int? cantripSpellId;

  bool get isEmpty => level == null && pact == null && cantripSpellId == null;

  /// Prérequis non satisfaits, dans l'ordre niveau, pacte, sort mineur (vide
  /// = éligible).
  ///
  /// - [warlockLevel] : niveau d'Occultiste CIBLE de la montée de niveau.
  /// - [knownPact] : pacte connu (déjà en base ou choisi dans la même montée
  ///   de niveau), `null` si aucun.
  /// - [knownCantripSpellIds] : `spells.id` des sorts mineurs connus (déjà en
  ///   base, plus ceux choisis dans la même montée de niveau).
  List<InvocationPrerequisiteFailure> unmet({
    required int warlockLevel,
    required WarlockPact? knownPact,
    required Set<int> knownCantripSpellIds,
  }) {
    return [
      if (level != null && warlockLevel < level!)
        InvocationPrerequisiteFailure.level,
      if (pact != null && knownPact != pact) InvocationPrerequisiteFailure.pact,
      if (cantripSpellId != null &&
          !knownCantripSpellIds.contains(cantripSpellId))
        InvocationPrerequisiteFailure.cantrip,
    ];
  }

  /// `true` si toutes les contraintes sont satisfaites — voir [unmet].
  bool canSelect({
    required int warlockLevel,
    required WarlockPact? knownPact,
    required Set<int> knownCantripSpellIds,
  }) => unmet(
    warlockLevel: warlockLevel,
    knownPact: knownPact,
    knownCantripSpellIds: knownCantripSpellIds,
  ).isEmpty;

  @override
  bool operator ==(Object other) =>
      other is InvocationPrerequisites &&
      other.level == level &&
      other.pact == pact &&
      other.cantripSpellId == cantripSpellId;

  @override
  int get hashCode => Object.hash(level, pact, cantripSpellId);

  @override
  String toString() =>
      'InvocationPrerequisites(level: $level, pact: $pact, '
      'cantripSpellId: $cantripSpellId)';
}

/// Nature d'un prérequis d'invocation non satisfait.
enum InvocationPrerequisiteFailure { level, pact, cantrip }
