/// Bonus de caractéristiques raciaux **au choix du joueur**, portés par deux
/// clés spéciales du jsonb `races.ability_bonuses`/`subraces.ability_bonuses` :
///
/// - `choice_others: {"count": n, "amount": a}` — +a à n caractéristiques
///   au choix, différentes de celles qui ont déjà un bonus fixe (Demi-elfe :
///   `{"cha": 2, "choice_others": {"count": 2, "amount": 1}}`, Forgelier) ;
/// - `choice_flexible: true` — règle des races « à bonus flexibles »
///   (Monsters of the Multiverse et suivants : Aasimar, Firbolg, Tabaxi...) :
///   +2 à une caractéristique et +1 à une autre, ou +1 à trois
///   caractéristiques différentes.
///
/// Les choix du joueur sont une simple `Map<String, int>` (clé de
/// caractéristique → bonus), stockée dans le brouillon
/// (`CharacterCreationDraft.racialBonusChoices`) et ajoutée aux bonus fixes
/// par `FinalAbilityScoresResolver`.
sealed class RacialBonusChoiceSpec {
  const RacialBonusChoiceSpec();

  /// Spécification de choix de [raceBonuses] + [subraceBonuses], `null` si
  /// aucun bonus n'est à choisir (cas de la plupart des races classiques).
  static RacialBonusChoiceSpec? from({
    required Map<String, dynamic>? raceBonuses,
    Map<String, dynamic>? subraceBonuses,
  }) {
    final race = raceBonuses ?? const <String, dynamic>{};
    final subrace = subraceBonuses ?? const <String, dynamic>{};
    if (race['choice_flexible'] == true || subrace['choice_flexible'] == true) {
      return const FlexibleRacialBonusSpec();
    }
    final others = race['choice_others'] ?? subrace['choice_others'];
    if (others is Map) {
      final count = others['count'];
      final amount = others['amount'];
      if (count is num && amount is num && count > 0) {
        return OthersRacialBonusSpec(
          count: count.toInt(),
          amount: amount.toInt(),
          excluded: {
            for (final entry in [...race.entries, ...subrace.entries])
              if (_abilityKeys.contains(entry.key) && entry.value is num)
                entry.key,
          },
        );
      }
    }
    return null;
  }

  /// `true` si [choices] est une répartition complète et valide.
  bool isComplete(Map<String, int> choices);

  /// Libellé de la règle, affiché au-dessus du sélecteur.
  String get ruleLabel;
}

/// `choice_others` : +[amount] à [count] caractéristiques, hors [excluded].
final class OthersRacialBonusSpec extends RacialBonusChoiceSpec {
  const OthersRacialBonusSpec({
    required this.count,
    required this.amount,
    required this.excluded,
  });

  final int count;
  final int amount;

  /// Caractéristiques ayant déjà un bonus racial fixe (« autres »).
  final Set<String> excluded;

  @override
  bool isComplete(Map<String, int> choices) =>
      choices.length == count &&
      choices.entries.every(
        (entry) =>
            _abilityKeys.contains(entry.key) &&
            !excluded.contains(entry.key) &&
            entry.value == amount,
      );

  @override
  String get ruleLabel =>
      '+$amount à $count caractéristique${count > 1 ? 's' : ''} au choix';
}

/// `choice_flexible` : +2 / +1, ou +1 / +1 / +1.
final class FlexibleRacialBonusSpec extends RacialBonusChoiceSpec {
  const FlexibleRacialBonusSpec();

  @override
  bool isComplete(Map<String, int> choices) {
    if (!choices.keys.every(_abilityKeys.contains)) return false;
    final values = choices.values.toList()..sort();
    return _listEquals(values, const [1, 2]) ||
        _listEquals(values, const [1, 1, 1]);
  }

  @override
  String get ruleLabel =>
      '+2 à une caractéristique et +1 à une autre, ou +1 à trois';
}

const Set<String> _abilityKeys = {'str', 'dex', 'con', 'int', 'wis', 'cha'};

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
