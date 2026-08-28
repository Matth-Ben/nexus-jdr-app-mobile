import '../../character_creation/domain/spellcasting_rules.dart';
import 'character_failure.dart';
import 'class_feature_choice_label_formatter.dart';

/// Raison pour laquelle une montée de niveau est bloquée (increment 1 de
/// l'écran "Montée de niveau", `presentation/level_up_screen.dart`) — porte
/// un [detail] déjà formaté en français, prêt à être affiché tel quel sur la
/// carte de blocage (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 6, spec visuelle direction-artistique section 6).
class LevelUpBlockReason {
  const LevelUpBlockReason({required this.detail});

  final String detail;

  @override
  bool operator ==(Object other) =>
      other is LevelUpBlockReason && other.detail == detail;

  @override
  int get hashCode => detail.hashCode;

  @override
  String toString() => 'LevelUpBlockReason($detail)';
}

/// Conditions de blocage de la montée de niveau.
///
/// **Changement de comportement à l'increment 2** (étape "Choix à faire",
/// `presentation/level_up_screen.dart`) : la javadoc de l'increment 1
/// documentait ici "les 3 conditions de blocage". Ce n'est plus le cas —
/// [classFeatureChoiceType] valant `'sous_classe'`/`'style_combat'`/
/// `'ennemi_jure'` ([resolvedChoiceTypes]) et [targetLevel] ∈
/// [abilityScoreImprovementLevels] ne bloquent plus le flux : ils mènent
/// désormais à l'étape "Choix à faire" (voir
/// `domain/level_up_choice_kind.dart::LevelUpPendingChoiceResolver`, appelée
/// une fois [evaluate] revenu à `null`). Continuent de bloquer : tout autre
/// `choice_type` non nul (ex. `'invocation'`, table `invocations` vide en
/// base — toujours hors périmètre), et l'extension "classes à sorts connus"
/// ci-dessous (inchangée).
///
/// Un niveau qui reste bloqué bloque tout le flux *avant* même l'étape
/// "Points de vie" (jamais de jet de dé pour rien).
abstract final class LevelUpBlockRules {
  /// Niveaux d'augmentation de caractéristique/don, règle standard 5e —
  /// codés en dur (pas de colonne dédiée en base), sans exception de classe
  /// gérée à cet incrément (ex. Guerrier/Voleur, qui en ont RAW davantage :
  /// hors périmètre de cet incrément, décision produit explicite). Depuis
  /// l'increment 2, seule la répartition de caractéristiques est couverte à
  /// l'étape "Choix à faire" — l'alternative "don" reste hors périmètre
  /// (table `feats` vide en base).
  static const Set<int> abilityScoreImprovementLevels = {4, 8, 12, 16, 19};

  /// `class_features.choice_type` désormais gérés par l'étape "Choix à
  /// faire" (increment 2) plutôt que bloqués — voir
  /// `domain/level_up_choice_kind.dart`.
  static const Set<String> resolvedChoiceTypes = {
    'sous_classe',
    'style_combat',
    'ennemi_jure',
  };

  /// Évalue si [targetLevel] doit bloquer tout le flux de montée de niveau,
  /// dans l'ordre suivant (une seule raison retenue, la première qui
  /// matche) :
  ///
  /// 1. [classFeatureChoiceType] non nul ET **pas** dans
  ///    [resolvedChoiceTypes] (ex. `'invocation'`, `'sort_domaine'`, ou toute
  ///    valeur future non encore gérée) -> bloque avec le libellé résolu par
  ///    [ClassFeatureChoiceLabelFormatter].
  /// 2. [targetLevel] ∈ [abilityScoreImprovementLevels] -> ne bloque **pas**
  ///    (étape "Choix à faire", répartition de caractéristiques). Priorité
  ///    sur la condition 3 ci-dessous, comme à l'increment 1 (retour
  ///    immédiat sans évaluer la condition 3) : un personnage d'une classe
  ///    "à sorts connus" qui atteint un niveau ASI n'est jamais bloqué pour
  ///    cette seule raison, même si ce niveau apprend aussi un nouveau sort
  ///    (limitation déjà acceptée avant cet incrément, seulement reformulée
  ///    ici).
  ///
  ///    **Cas défensif** (jamais rencontré dans les données actuelles,
  ///    vérifié : tous les `choice_type` peuplés sont aux niveaux 1-3, les
  ///    niveaux ASI sont 4/8/12/16/19, aucun chevauchement) : si
  ///    [classFeatureChoiceType] est aussi dans [resolvedChoiceTypes] au même
  ///    niveau, l'étape "Choix à faire" ne peut représenter qu'un seul choix
  ///    à la fois — plutôt que de deviner lequel des deux traiter et
  ///    d'ignorer l'autre silencieusement, cette méthode lève une
  ///    [CharacterFailure] explicite.
  /// 3. **Extension chef de projet** : [className] est l'une des 4 classes
  ///    "à sorts connus" (Barde, Ensorceleur, Occultiste, Rôdeur —
  ///    `SpellcastingRules.statusFor(className) == 'connu'` ET
  ///    `SpellcastingRules.isSpellcastingClass(className)`, les deux
  ///    conditions sont nécessaires : `statusFor` retombe sur `'connu'` par
  ///    défaut pour toute classe non listée, y compris une classe non
  ///    lanceuse de sorts, donc `isSpellcastingClass` seul distingue les 4
  ///    classes réellement concernées) ET [targetLevel] > 1. Ces classes
  ///    apprennent fréquemment un nouveau sort connu à la montée de niveau,
  ///    mécanisme non couvert par `class_features.choice_type` et pour
  ///    lequel ce dépôt n'a aujourd'hui aucune table de progression "sorts
  ///    connus par niveau" au-delà du niveau 1 (`SpellcastingRules` ne
  ///    couvre que la création). Blocage délibérément conservateur : limite
  ///    l'utilité de cet incrément pour ces 4 classes précises jusqu'à ce
  ///    que l'étape "Sorts" de la montée de niveau soit construite (hors
  ///    périmètre ici), plutôt que de risquer de laisser passer une montée
  ///    de niveau qui aurait dû exiger un choix de sort.
  ///
  ///    **Décision increment 2, non explicitement couverte par la tâche** :
  ///    cette condition est évaluée même quand [classFeatureChoiceType] est
  ///    dans [resolvedChoiceTypes] (donc ne bloque pas via la condition 1) —
  ///    un `choice_type` résolu (ex. sous-classe) à un niveau qui apprend
  ///    *aussi* un nouveau sort connu reste bloqué : le nouveau sort n'est
  ///    toujours pas gérable, indépendamment du fait que la sous-classe le
  ///    soit désormais. Concrètement (vérifié en base) : Barde niveau 3
  ///    (sous-classe) et Rôdeur niveaux 2/3 (style de combat/sous-classe)
  ///    restent bloqués par cette condition, inchangé depuis l'increment 1 —
  ///    seuls les niveaux/classes qui n'ont pas ce chevauchement (Guerrier,
  ///    Paladin, Clerc, Druide, Magicien, Moine, Roublard, Barbare...)
  ///    profitent de l'étape "Choix à faire" à cet incrément.
  static LevelUpBlockReason? evaluate({
    required int targetLevel,
    required String className,
    required String? classFeatureChoiceType,
  }) {
    final isResolvedChoiceType =
        classFeatureChoiceType != null &&
        resolvedChoiceTypes.contains(classFeatureChoiceType);

    if (classFeatureChoiceType != null && !isResolvedChoiceType) {
      return LevelUpBlockReason(
        detail:
            '$className niveau $targetLevel : '
            '${ClassFeatureChoiceLabelFormatter.labelFor(classFeatureChoiceType)}',
      );
    }

    final isAsiLevel = abilityScoreImprovementLevels.contains(targetLevel);

    if (isResolvedChoiceType && isAsiLevel) {
      throw CharacterFailure(
        '$className niveau $targetLevel : ce niveau nécessite deux choix '
        'simultanés (${ClassFeatureChoiceLabelFormatter.labelFor(classFeatureChoiceType)} '
        'et amélioration de caractéristique), non pris en charge.',
      );
    }

    if (isAsiLevel) {
      return null;
    }

    final isKnownCasterClass =
        SpellcastingRules.isSpellcastingClass(className) &&
        SpellcastingRules.statusFor(className) == 'connu';
    if (targetLevel > 1 && isKnownCasterClass) {
      return LevelUpBlockReason(
        detail:
            '$className niveau $targetLevel : nouveau sort à choisir '
            '(pas encore disponible)',
      );
    }

    return null;
  }
}
