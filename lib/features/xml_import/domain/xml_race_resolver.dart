import '../../character_creation/domain/race_catalog.dart';
import '../../character_creation/domain/race_option.dart';
import '../../character_creation/domain/subrace_option.dart';
import 'xml_field_resolution.dart';
import 'xml_name_normalizer.dart';

/// Race et sous-race résolues depuis le champ `<race>` d'un export XML.
typedef XmlRaceResolution = ({
  XmlFieldResolution<RaceOption> race,
  SubraceOption? subrace,
});

/// Résout le champ `<race>` en race **et** sous-race : aidedd.org (comme
/// l'export de l'app) y écrit souvent la sous-race plutôt que la race
/// (« Haut-elfe », « Nain des collines », « Drow »), ou les deux
/// (« Elfe (haut-elfe) », « Elfe — Haut-elfe »). Une simple recherche par nom
/// dans les races laissait ces personnages en « race non reconnue ».
///
/// Ordre d'essai, comparaison insensible à la casse et aux accents
/// ([XmlNameNormalizer]) :
/// 1. nom exact d'une race ;
/// 2. nom exact d'une sous-race, ou d'un de ses alias (nom sans la partie
///    entre parenthèses, contenu des parenthèses : « Elfe noir (Drow) » →
///    « Elfe noir », « Drow ») ;
/// 3. par mots : une sous-race dont les mots propres (hors ceux de sa race)
///    sont tous présents dans le texte, sans mot étranger à la sous-race et
///    à sa race (« Elfe (haut) », « Elfe, haut-elfe ») ;
/// 4. mêmes mots qu'une race (ordre ou ponctuation différents).
/// Sinon : race non reconnue (corrigible sur l'écran de vérification).
abstract final class XmlRaceResolver {
  static XmlRaceResolution resolve({
    required String? rawName,
    required RaceCatalog catalog,
  }) {
    final trimmed = rawName?.trim() ?? '';
    final unrecognized = (
      race: XmlFieldResolution<RaceOption>.unrecognized(trimmed),
      subrace: null,
    );
    if (trimmed.isEmpty) return unrecognized;

    final target = XmlNameNormalizer.normalize(trimmed);
    RaceOption? raceOf(SubraceOption subrace) {
      for (final race in catalog.races) {
        if (race.id == subrace.raceId) return race;
      }
      return null;
    }

    XmlRaceResolution recognized(RaceOption race, SubraceOption? subrace) => (
      race: XmlFieldResolution<RaceOption>.recognized(race),
      subrace: subrace,
    );

    // 1. Race exacte.
    for (final race in catalog.races) {
      if (XmlNameNormalizer.normalize(race.name) == target) {
        return recognized(race, null);
      }
    }

    // 2. Sous-race exacte (ou alias).
    for (final subrace in catalog.subraces) {
      final race = raceOf(subrace);
      if (race == null) continue;
      if (_aliasesOf(subrace.name)
          .any((alias) => XmlNameNormalizer.normalize(alias) == target)) {
        return recognized(race, subrace);
      }
    }

    // 3. Sous-race par mots.
    final rawTokens = _tokens(trimmed);
    for (final subrace in catalog.subraces) {
      final race = raceOf(subrace);
      if (race == null) continue;
      final raceTokens = _tokens(race.name);
      for (final alias in _aliasesOf(subrace.name)) {
        final aliasTokens = _tokens(alias);
        final distinctive = aliasTokens.difference(raceTokens);
        if (distinctive.isNotEmpty &&
            rawTokens.containsAll(distinctive) &&
            aliasTokens.union(raceTokens).containsAll(rawTokens)) {
          return recognized(race, subrace);
        }
      }
    }

    // 4. Race par mots.
    for (final race in catalog.races) {
      final raceTokens = _tokens(race.name);
      if (raceTokens.isNotEmpty &&
          raceTokens.length == rawTokens.length &&
          raceTokens.containsAll(rawTokens)) {
        return recognized(race, null);
      }
    }

    return unrecognized;
  }

  /// Libellé « Race — Sous-race » proposé à la correction manuelle, relu
  /// par [resolve] (règle 3).
  static String labelOf(RaceOption race, SubraceOption? subrace) =>
      subrace == null ? race.name : '${race.name} — ${subrace.name}';

  /// Nom complet, nom sans parenthèses, contenu des parenthèses.
  static List<String> _aliasesOf(String name) {
    final match = RegExp(r'^(.*?)\s*\((.+)\)\s*$').firstMatch(name);
    if (match == null) return [name];
    return [name, match.group(1)!, match.group(2)!];
  }

  static const Set<String> _stopWords = {
    'de',
    'des',
    'du',
    'la',
    'le',
    'les',
    'l',
    'd',
    'et',
  };

  static Set<String> _tokens(String text) => {
    for (final token in XmlNameNormalizer.normalize(
      text,
    ).split(RegExp('[^a-z0-9]+')))
      if (token.isNotEmpty && !_stopWords.contains(token)) token,
  };
}
