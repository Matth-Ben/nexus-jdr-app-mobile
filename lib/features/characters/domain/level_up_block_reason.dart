import '../../character_creation/domain/spellcasting_rules.dart';
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

/// Les 3 conditions de blocage de l'increment 1 de la montée de niveau — la
/// 3ᵉ est une extension ajoutée par le chef de projet (pas dans le cahier
/// des charges d'origine), voir sa documentation ci-dessous.
///
/// Un niveau qui déclenche l'une de ces 3 conditions bloque tout le flux
/// *avant* même l'étape "Points de vie" (jamais de jet de dé pour rien) :
/// voir `presentation/level_up_screen.dart`.
abstract final class LevelUpBlockRules {
  /// Niveaux d'augmentation de caractéristique/don, règle standard 5e —
  /// codés en dur (pas de colonne dédiée en base), sans exception de classe
  /// gérée à cet incrément (ex. Guerrier/Voleur, qui en ont RAW davantage :
  /// hors périmètre de cet incrément, décision produit explicite).
  static const Set<int> abilityScoreImprovementLevels = {4, 8, 12, 16, 19};

  /// Évalue les 3 conditions de blocage pour [targetLevel], dans l'ordre où
  /// elles sont documentées (une seule raison retenue, la première qui
  /// matche) :
  /// 1. [classFeatureChoiceType] non nul (`class_features.choice_type`
  ///    renseigné pour la classe du personnage à ce niveau, voir
  ///    `data/character_repository.dart::fetchLevelUpLevelData`) ;
  /// 2. [targetLevel] ∈ [abilityScoreImprovementLevels] ;
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
  static LevelUpBlockReason? evaluate({
    required int targetLevel,
    required String className,
    required String? classFeatureChoiceType,
  }) {
    if (classFeatureChoiceType != null) {
      return LevelUpBlockReason(
        detail:
            '$className niveau $targetLevel : '
            '${ClassFeatureChoiceLabelFormatter.labelFor(classFeatureChoiceType)}',
      );
    }

    if (abilityScoreImprovementLevels.contains(targetLevel)) {
      return const LevelUpBlockReason(
        detail: 'Amélioration de caractéristique ou don',
      );
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
