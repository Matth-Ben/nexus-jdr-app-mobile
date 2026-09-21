import 'warlock_pact.dart';

/// Sorts accordés par la faveur de pacte de l'Occultiste (niveau 3), règles
/// pures appliquées par la montée de niveau
/// (`presentation/level_up_screen.dart`) :
///
/// - Pacte du grimoire : [tomeCantripCount] sorts mineurs de N'IMPORTE QUELLE
///   liste de classe, à choisir parmi les sorts mineurs pas encore connus ;
/// - Pacte de la chaîne : le sort Appel de familier, ajouté
///   automatiquement s'il n'est pas déjà connu ;
/// - Pacte de la lame : rien (l'arme de pacte est hors périmètre).
abstract final class WarlockPactRewards {
  /// Nombre de sorts mineurs offerts par le Livre des ombres.
  static const int tomeCantripCount = 3;

  /// Quota de sorts mineurs à choisir pour [pact] : [tomeCantripCount] pour le
  /// pacte du grimoire, 0 sinon (y compris `null`).
  static int cantripQuotaFor(WarlockPact? pact) =>
      pact == WarlockPact.tome ? tomeCantripCount : 0;

  /// `true` si [pact] ajoute Appel de familier (pacte de la chaîne).
  static bool grantsFamiliar(WarlockPact? pact) => pact == WarlockPact.chain;

  /// Sous-ensemble de [candidates] (`id` -> tout ce qui porte un identifiant
  /// de sort mineur) non encore connu : exclut les sorts mineurs déjà connus
  /// du personnage.
  static List<T> availableCantrips<T>(
    List<T> candidates, {
    required int Function(T) idOf,
    required Set<int> knownSpellIds,
  }) {
    return [
      for (final candidate in candidates)
        if (!knownSpellIds.contains(idOf(candidate))) candidate,
    ];
  }

  /// Identifiants de sorts à ajouter à `character_spells` pour [pact], à
  /// concaténer aux sorts déjà choisis par ailleurs dans la même montée de
  /// niveau ([alreadyPlannedSpellIds]).
  ///
  /// - grimoire : [chosenCantripIds] (tronqués à [tomeCantripCount]) ;
  /// - chaîne : [familiarSpellId] s'il est résolu (`null` = sort introuvable
  ///   dans le catalogue, rien n'est ajouté) ;
  /// - jamais un identifiant déjà connu ([knownSpellIds]) ni déjà prévu
  ///   ([alreadyPlannedSpellIds]) : pas de doublon.
  static List<int> spellIdsToAdd({
    required WarlockPact? pact,
    required List<int> chosenCantripIds,
    required int? familiarSpellId,
    required Set<int> knownSpellIds,
    Set<int> alreadyPlannedSpellIds = const {},
  }) {
    final wanted = <int>[
      if (pact == WarlockPact.tome) ...chosenCantripIds.take(tomeCantripCount),
      if (grantsFamiliar(pact) && familiarSpellId != null) familiarSpellId,
    ];
    final result = <int>[];
    for (final id in wanted) {
      if (knownSpellIds.contains(id) ||
          alreadyPlannedSpellIds.contains(id) ||
          result.contains(id)) {
        continue;
      }
      result.add(id);
    }
    return result;
  }

  /// `true` si Appel de familier sera réellement ajouté (pacte de la
  /// chaîne, sort résolu et pas déjà connu) — pilote la ligne "Appel de
  /// familier ajouté" du récapitulatif.
  static bool willAddFamiliar({
    required WarlockPact? pact,
    required int? familiarSpellId,
    required Set<int> knownSpellIds,
  }) =>
      grantsFamiliar(pact) &&
      familiarSpellId != null &&
      !knownSpellIds.contains(familiarSpellId);
}
