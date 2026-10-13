import 'dart:math' as math;

import 'hit_dice_pool.dart';

/// Calcul RAW 5e de la récupération des dés de vie au repos long — voir
/// `data/character_repository.dart::applyRestOnline` et
/// `presentation/widgets/rest_sheet.dart`.
///
/// Décision chef de projet du 10/10/2026 (dette D-dés de vie
/// multiclassés) :
/// 1. le nombre de dés récupérés se calcule sur le NIVEAU TOTAL du
///    personnage ([recoveredCount] — `CharacterDetail.totalLevel`, somme de
///    toutes les classes), jamais sur la seule classe primaire ;
/// 2. quand ce nombre suffit à tout récupérer, aucun choix n'est nécessaire
///    ([defaultRecovery]) ;
/// 3. quand il ne suffit pas ET qu'il existe au moins deux pools
///    *réellement* en jeu (au moins deux classes avec des dés dépensés —
///    [needsPlayerChoice]), le joueur choisit quels dés récupérer en
///    priorité (UI dédiée, `_LongRestRecoveryChoice` de `rest_sheet.dart`) :
///    il n'y a RAW rien à choisir entre deux dés strictement identiques
///    (mono-classe, ou multiclassé dont un seul pool a des dés dépensés),
///    seulement entre deux pools de nature différente.
abstract final class HitDiceRecoveryCalculator {
  /// Moitié du niveau total du personnage, arrondie à l'inférieur, au
  /// moins 1 (RAW 5e, "Multiclassing" — PHB : la récupération au repos long
  /// porte sur le total de dés de vie du personnage, pas sur une seule
  /// classe).
  static int recoveredCount({required int totalLevel}) =>
      math.max(1, totalLevel ~/ 2);

  /// Somme de [HitDicePool.spent] sur [pools].
  static int totalSpent(List<HitDicePool> pools) =>
      pools.fold(0, (sum, pool) => sum + pool.spent);

  /// Pools ayant effectivement des dés dépensés — seuls ceux-là peuvent
  /// faire l'objet d'un choix (voir [needsPlayerChoice]).
  static List<HitDicePool> spentPools(List<HitDicePool> pools) =>
      pools.where((pool) => pool.spent > 0).toList(growable: false);

  /// `true` si [recovered] (voir [recoveredCount]) ne suffit pas à
  /// restaurer tous les dés dépensés ET qu'il existe réellement plus d'un
  /// pool parmi lesquels choisir — voir la documentation de classe, point 3.
  static bool needsPlayerChoice({
    required List<HitDicePool> pools,
    required int recovered,
  }) {
    final spent = spentPools(pools);
    return spent.length > 1 && recovered < totalSpent(pools);
  }

  /// Répartition par [HitDicePool.classId] du nombre de dés récupérés pour
  /// CE pool, calculée automatiquement — valable uniquement quand
  /// [needsPlayerChoice] est `false` pour ces mêmes [pools]/[recovered] (sinon
  /// le joueur doit choisir, voir la documentation de classe). Vide si
  /// aucun dé n'est dépensé (aucune écriture nécessaire, même convention
  /// que le reste du dépôt).
  static Map<Object, int> defaultRecovery({
    required List<HitDicePool> pools,
    required int recovered,
  }) {
    final spent = spentPools(pools);
    if (spent.isEmpty) return const {};
    final total = totalSpent(pools);
    if (recovered >= total) {
      // Assez pour tout récupérer : chaque pool dépensé revient à 0,
      // quel que soit leur nombre.
      return {for (final pool in spent) pool.classId: pool.spent};
    }
    // Recovered < total, mais un seul pool a des dés dépensés : rien à
    // choisir entre dés identiques, applique directement le nombre
    // récupéré à ce pool unique (même formule que l'ancien calcul
    // mono-classe, avant cette fonctionnalité).
    assert(
      spent.length == 1,
      'defaultRecovery ne doit être appelé que quand needsPlayerChoice est '
      'false pour ces mêmes pools/recovered.',
    );
    return {spent.single.classId: recovered};
  }
}
