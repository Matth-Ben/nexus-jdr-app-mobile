import 'spell_slot_change.dart';

/// Tables de progression 5e standard des emplacements de sorts par niveau de
/// personnage (une seule classe gérée dans l'app, pas de multiclassage) —
/// contenu fourni par le chef de projet, autoritaire : encodé tel quel, non
/// re-vérifié ici.
///
/// Étape "Sorts" de la montée de niveau (increment 3,
/// `presentation/level_up_screen.dart`) — voir aussi
/// `character_creation/domain/spellcasting_rules.dart` (quotas de sorts
/// *connus* à la création, un module distinct : celui-ci ne couvre que le
/// nombre d'*emplacements* disponibles, recalculé à chaque montée de
/// niveau).
///
/// Même convention de clé que [SpellcastingRules] : le **nom de classe en
/// français**, pas `classes.id` — voir le rationale détaillé de
/// `SpellcastingRules` (classe sœur).
abstract final class SpellSlotProgression {
  /// Lanceurs complets — emplacements de niveau de sort 1 à 9, un tableau de
  /// 9 entiers par niveau de personnage (index 0 = niveau de sort 1).
  static const Set<String> fullCasterClassNames = {
    'Barde',
    'Clerc',
    'Druide',
    'Magicien',
    'Ensorceleur',
  };

  /// Demi-lanceurs — emplacements de niveau de sort 1 à 5 uniquement (index
  /// 5-8 toujours à 0, voir [slotsForLevel]).
  static const Set<String> halfCasterClassNames = {'Paladin', 'Rôdeur'};

  /// Magie de pacte — mécanisme différent (charges rechargées au repos
  /// court), voir [pactMagicFor]. Non exposée via [slotsForLevel] (qui
  /// retourne 9 zéros pour cette classe, voir sa documentation) : l'Occultiste
  /// reste bloqué (`LevelUpBlockRules`, classe "à sorts connus") pour la
  /// plupart des niveaux, mais PAS pour un niveau ASI (4/8/12/16/19, ce
  /// blocage-là est évalué avant la condition "sorts connus" — voir
  /// `level_up_block_reason.dart::LevelUpBlockRules.evaluate`) : un Occultiste
  /// niveau ASI atteint donc bel et bien ce flux. Le vrai filet de sécurité
  /// qui empêche l'étape "Sorts" de s'afficher pour cette classe est
  /// [slotsForLevel] retournant toujours 9 zéros (donc [changesFor] retourne
  /// toujours une liste vide) — pas un blocage systématique en amont. Cette
  /// table est encodée par complétude, pas exercée via l'UI à cet incrément.
  static const Set<String> pactCasterClassNames = {'Occultiste'};

  /// `characterLevel` (1 à 20) -> 9 entiers, index 0 = niveau de sort 1.
  static const Map<int, List<int>> _fullCasterSlots = {
    1: [2, 0, 0, 0, 0, 0, 0, 0, 0],
    2: [3, 0, 0, 0, 0, 0, 0, 0, 0],
    3: [4, 2, 0, 0, 0, 0, 0, 0, 0],
    4: [4, 3, 0, 0, 0, 0, 0, 0, 0],
    5: [4, 3, 2, 0, 0, 0, 0, 0, 0],
    6: [4, 3, 3, 0, 0, 0, 0, 0, 0],
    7: [4, 3, 3, 1, 0, 0, 0, 0, 0],
    8: [4, 3, 3, 2, 0, 0, 0, 0, 0],
    9: [4, 3, 3, 3, 1, 0, 0, 0, 0],
    10: [4, 3, 3, 3, 2, 0, 0, 0, 0],
    11: [4, 3, 3, 3, 2, 1, 0, 0, 0],
    12: [4, 3, 3, 3, 2, 1, 0, 0, 0],
    13: [4, 3, 3, 3, 2, 1, 1, 0, 0],
    14: [4, 3, 3, 3, 2, 1, 1, 0, 0],
    15: [4, 3, 3, 3, 2, 1, 1, 1, 0],
    16: [4, 3, 3, 3, 2, 1, 1, 1, 0],
    17: [4, 3, 3, 3, 2, 1, 1, 1, 1],
    18: [4, 3, 3, 3, 3, 1, 1, 1, 1],
    19: [4, 3, 3, 3, 3, 2, 1, 1, 1],
    20: [4, 3, 3, 3, 3, 2, 2, 1, 1],
  };

  /// `characterLevel` (1 à 20) -> 5 entiers, index 0 = niveau de sort 1
  /// (niveaux de sort 6-9 toujours à 0, voir [slotsForLevel] pour le
  /// remplissage à 9 entrées).
  static const Map<int, List<int>> _halfCasterSlots = {
    1: [0, 0, 0, 0, 0],
    2: [2, 0, 0, 0, 0],
    3: [3, 0, 0, 0, 0],
    4: [3, 0, 0, 0, 0],
    5: [4, 2, 0, 0, 0],
    6: [4, 2, 0, 0, 0],
    7: [4, 3, 0, 0, 0],
    8: [4, 3, 0, 0, 0],
    9: [4, 3, 2, 0, 0],
    10: [4, 3, 2, 0, 0],
    11: [4, 3, 3, 0, 0],
    12: [4, 3, 3, 0, 0],
    13: [4, 3, 3, 1, 0],
    14: [4, 3, 3, 1, 0],
    15: [4, 3, 3, 2, 0],
    16: [4, 3, 3, 2, 0],
    17: [4, 3, 3, 3, 1],
    18: [4, 3, 3, 3, 1],
    19: [4, 3, 3, 3, 2],
    20: [4, 3, 3, 3, 2],
  };

  /// `characterLevel` (1 à 20) -> (nombre de charges, niveau des charges),
  /// magie de pacte de l'Occultiste — voir [pactMagicFor].
  static const Map<int, ({int charges, int slotLevel})> _pactMagicSlots = {
    1: (charges: 1, slotLevel: 1),
    2: (charges: 2, slotLevel: 1),
    3: (charges: 2, slotLevel: 2),
    4: (charges: 2, slotLevel: 2),
    5: (charges: 2, slotLevel: 3),
    6: (charges: 2, slotLevel: 3),
    7: (charges: 2, slotLevel: 4),
    8: (charges: 2, slotLevel: 4),
    9: (charges: 2, slotLevel: 5),
    10: (charges: 2, slotLevel: 5),
    11: (charges: 3, slotLevel: 5),
    12: (charges: 3, slotLevel: 5),
    13: (charges: 3, slotLevel: 5),
    14: (charges: 3, slotLevel: 5),
    15: (charges: 3, slotLevel: 5),
    16: (charges: 3, slotLevel: 5),
    17: (charges: 4, slotLevel: 5),
    18: (charges: 4, slotLevel: 5),
    19: (charges: 4, slotLevel: 5),
    20: (charges: 4, slotLevel: 5),
  };

  static final List<int> _allZeros = List.unmodifiable(List.filled(9, 0));

  /// Emplacements de sorts de [className] au niveau de personnage
  /// [characterLevel] (1 à 20), 9 entiers (index 0 = niveau de sort 1, index
  /// 8 = niveau de sort 9). Retourne 9 zéros pour :
  /// - une classe non lanceuse (`SpellcastingRules.isSpellcastingClass ==
  ///   false`, ex. Guerrier/Roublard/Barbare/Moine) ;
  /// - l'Occultiste (magie de pacte, mécanisme différent — voir
  ///   [pactMagicFor]) ;
  /// - un [characterLevel] hors de la plage 1-20 (défensif, ne devrait
  ///   jamais arriver : la montée de niveau ne dépasse jamais 20).
  static List<int> slotsForLevel(String className, int characterLevel) {
    if (halfCasterClassNames.contains(className)) {
      final row = _halfCasterSlots[characterLevel];
      if (row == null) return _allZeros;
      return [...row, 0, 0, 0, 0];
    }
    if (fullCasterClassNames.contains(className)) {
      return _fullCasterSlots[characterLevel] ?? _allZeros;
    }
    return _allZeros;
  }

  /// Magie de pacte de l'Occultiste au niveau de personnage [characterLevel]
  /// — `null` pour tout autre niveau hors 1-20 (défensif). Toujours `null`
  /// pour toute classe autre que l'Occultiste : cette méthode ne vérifie pas
  /// [className], appelant responsable de ne l'invoquer que pour cette
  /// classe (voir [pactCasterClassNames]).
  static ({int charges, int slotLevel})? pactMagicFor(int characterLevel) =>
      _pactMagicSlots[characterLevel];

  /// Changements de total d'emplacements de sorts entre `targetLevel - 1` et
  /// `targetLevel` pour [className], triés par niveau de sort croissant (1 à
  /// 9) — une entrée par niveau de sort dont le total change, jamais
  /// d'entrée pour un niveau de sort dont le total ne bouge pas.
  ///
  /// Calculée **uniquement** depuis les tables ci-dessus (jamais depuis
  /// `character_spell_slots` en base, qui n'a jamais été écrit avant cet
  /// incrément — voir le point critique de la spec visuelle
  /// direction-artistique de l'étape "Sorts",
  /// `presentation/level_up_screen.dart`).
  ///
  /// Vide pour une classe non lanceuse ou l'Occultiste (voir
  /// [slotsForLevel]) : les deux tables comparées sont alors identiques (9
  /// zéros), donc aucun changement détecté.
  static List<SpellSlotChange> changesFor({
    required String className,
    required int targetLevel,
  }) {
    final oldSlots = slotsForLevel(className, targetLevel - 1);
    final newSlots = slotsForLevel(className, targetLevel);
    return [
      for (var i = 0; i < 9; i++)
        if (oldSlots[i] != newSlots[i])
          SpellSlotChange(
            spellLevel: i + 1,
            oldTotal: oldSlots[i],
            newTotal: newSlots[i],
          ),
    ];
  }
}
