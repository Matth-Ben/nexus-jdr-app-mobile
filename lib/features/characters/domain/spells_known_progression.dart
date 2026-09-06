/// Tables de progression 5e standard des sorts/cantrips CONNUS par niveau de
/// classe, pour les 4 classes "à sorts connus" (Barde, Ensorceleur,
/// Occultiste, Rôdeur) — contenu fourni par le chef de projet, vérifié via
/// l'API Open5e/SRD, autoritaire : encodé tel quel, non re-vérifié ici. Même
/// convention de clé que `SpellSlotProgression`/`SpellcastingRules` : le
/// **nom de classe en français**, pas `classes.id`.
///
/// Étape "Sorts" généralisée de la montée de niveau
/// (`presentation/level_up_screen.dart`) — jusqu'ici cette étape ne couvrait
/// que les sorts de départ d'une nouvelle classe "à sorts connus" démarrée au
/// niveau 1 par multiclassage (`SpellcastingRules.cantripQuotaFor`/
/// `levelOneSpellQuotaFor`, quotas de CRÉATION). Cette table couvre
/// désormais N'IMPORTE QUEL niveau (> 1 inclus), ce qui n'existait pas avant
/// ce chantier (voir l'ancienne condition 3 de
/// `domain/level_up_block_reason.dart::LevelUpBlockRules.evaluate`, supprimée
/// par ce même chantier).
///
/// **Coïncidence vérifiée, pas un hasard exploité à la légère** : au niveau
/// 1, [newCantripsAt]/[newSpellsKnownAt] retombent exactement sur
/// `SpellcastingRules.cantripQuotaFor`/`levelOneSpellQuotaFor` pour Barde
/// (2/4), Ensorceleur (4/2) et Occultiste (2/2) — les deux tables ont donc pu
/// être unifiées dans `presentation/providers/level_up_provider.dart` sans
/// jamais changer le comportement déjà testé du multiclassage niveau 1. Le
/// Rôdeur diverge (`SpellcastingRules.levelOneSpellQuotaFor('Rôdeur')` vaut 2
/// par simplification documentée comme propre à la CRÉATION, alors que RAW il
/// n'a aucun sort au niveau 1) : cette table encode la valeur RAW correcte
/// (0), volontairement différente de `SpellcastingRules` pour ce cas précis.
abstract final class SpellsKnownProgression {
  /// Cantrips connus par niveau de classe. Rôdeur absent (n'a RAW jamais de
  /// cantrip, à aucun niveau) — [newCantripsAt] retombe alors sur 0.
  static const Map<String, Map<int, int>> cantripsKnownByLevel = {
    'Barde': {
      1: 2,
      2: 2,
      3: 2,
      4: 3,
      5: 3,
      6: 3,
      7: 3,
      8: 3,
      9: 3,
      10: 4,
      11: 4,
      12: 4,
      13: 4,
      14: 4,
      15: 4,
      16: 4,
      17: 4,
      18: 4,
      19: 4,
      20: 4,
    },
    'Ensorceleur': {
      1: 4,
      2: 4,
      3: 4,
      4: 5,
      5: 5,
      6: 5,
      7: 5,
      8: 5,
      9: 5,
      10: 6,
      11: 6,
      12: 6,
      13: 6,
      14: 6,
      15: 6,
      16: 6,
      17: 6,
      18: 6,
      19: 6,
      20: 6,
    },
    'Occultiste': {
      1: 2,
      2: 2,
      3: 2,
      4: 3,
      5: 3,
      6: 3,
      7: 3,
      8: 3,
      9: 3,
      10: 4,
      11: 4,
      12: 4,
      13: 4,
      14: 4,
      15: 4,
      16: 4,
      17: 4,
      18: 4,
      19: 4,
      20: 4,
    },
  };

  /// Sorts connus par niveau de classe.
  static const Map<String, Map<int, int>> spellsKnownByLevel = {
    'Barde': {
      1: 4,
      2: 5,
      3: 6,
      4: 7,
      5: 8,
      6: 9,
      7: 10,
      8: 11,
      9: 12,
      10: 14,
      11: 15,
      12: 15,
      13: 16,
      14: 18,
      15: 19,
      16: 19,
      17: 20,
      18: 22,
      19: 22,
      20: 22,
    },
    'Ensorceleur': {
      1: 2,
      2: 3,
      3: 4,
      4: 5,
      5: 6,
      6: 7,
      7: 8,
      8: 9,
      9: 10,
      10: 11,
      11: 12,
      12: 12,
      13: 13,
      14: 13,
      15: 14,
      16: 14,
      17: 15,
      18: 15,
      19: 15,
      20: 15,
    },
    'Rôdeur': {
      1: 0,
      2: 2,
      3: 3,
      4: 3,
      5: 4,
      6: 4,
      7: 5,
      8: 5,
      9: 6,
      10: 6,
      11: 7,
      12: 7,
      13: 8,
      14: 8,
      15: 9,
      16: 9,
      17: 10,
      18: 10,
      19: 11,
      20: 11,
    },
    'Occultiste': {
      1: 2,
      2: 3,
      3: 4,
      4: 5,
      5: 6,
      6: 7,
      7: 8,
      8: 9,
      9: 10,
      10: 10,
      11: 11,
      12: 11,
      13: 12,
      14: 12,
      15: 13,
      16: 13,
      17: 14,
      18: 14,
      19: 15,
      20: 15,
    },
  };

  /// Nouveaux cantrips appris en passant au niveau [level] de [className] —
  /// `table[level] - table[level - 1]` (`table[0]` implicitement 0 : un
  /// personnage n'a aucun cantrip "avant le niveau 1"). 0 si [className]
  /// n'est pas dans [cantripsKnownByLevel] (Rôdeur, ou toute classe non
  /// concernée), ou si [level] n'y figure pas (défensif, en dehors de 1-20).
  static int newCantripsAt(String className, int level) =>
      _delta(cantripsKnownByLevel[className], level);

  /// Nouveaux sorts connus en passant au niveau [level] de [className] — même
  /// règle que [newCantripsAt].
  static int newSpellsKnownAt(String className, int level) =>
      _delta(spellsKnownByLevel[className], level);

  static int _delta(Map<int, int>? table, int level) {
    if (table == null) return 0;
    final at = table[level];
    if (at == null) return 0;
    final previous = table[level - 1] ?? 0;
    return at - previous;
  }
}
