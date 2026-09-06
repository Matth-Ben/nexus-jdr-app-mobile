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
/// une fois [evaluate] revenu à `null`).
///
/// **Chantier "sorts/dons/invocations" (increment suivant)** : deux
/// changements supplémentaires.
/// - `'invocation'` a rejoint [resolvedChoiceTypes] : la nouvelle étape
///   "Invocations" (`domain/invocations_known_progression.dart`, basée sur le
///   delta de la table RAW à CHAQUE niveau concerné — 2, 5, 7, 9, 12, 15, 18)
///   couvre désormais ce cas mieux que le simple `choice_type` (qui n'existe
///   en base qu'au niveau 2) — voir
///   `domain/level_up_choice_kind.dart::LevelUpPendingChoiceResolver.resolve`,
///   qui ne mappe volontairement PAS `'invocation'` vers un
///   `LevelUpChoiceKind` (l'étape "Invocations" est distincte de l'étape
///   "Choix à faire").
/// - L'ancienne condition 3 ("classes à sorts connus bloquées à tout niveau
///   > 1", voir l'historique de ce fichier) est entièrement **supprimée** :
///   la nouvelle étape "Sorts" généralisée
///   (`domain/spells_known_progression.dart`) gère désormais correctement ce
///   cas à n'importe quel niveau (delta calculé, étape absente si delta nul
///   des deux côtés — jamais un blocage).
///
/// Un niveau qui reste bloqué bloque tout le flux *avant* même l'étape
/// "Points de vie" (jamais de jet de dé pour rien) — ne reste concerné que
/// tout `class_features.choice_type` non nul et encore inconnu de
/// [resolvedChoiceTypes] (aucune valeur de ce type peuplée en base à ce jour,
/// voir `20260825090700_seed_classes_subclasses_features.sql` côté dépôt web
/// : les 4 valeurs peuplées — `sous_classe`/`style_combat`/`ennemi_jure`/
/// `invocation` — y sont toutes désormais présentes).
abstract final class LevelUpBlockRules {
  /// Niveaux d'augmentation de caractéristique OU choix d'un don en
  /// alternative, règle standard 5e — codés en dur (pas de colonne dédiée en
  /// base), sans exception de classe gérée (ex. Guerrier/Voleur, qui en ont
  /// RAW davantage : hors périmètre, décision produit explicite). Les deux
  /// sous-choix (répartition de caractéristiques / don, voir
  /// `domain/level_up_choice_selection.dart::LevelUpChoiceSelection.featId`)
  /// partagent le même `LevelUpChoiceKind.abilityScoreImprovement` et donc le
  /// même niveau de déclenchement.
  static const Set<int> abilityScoreImprovementLevels = {4, 8, 12, 16, 19};

  /// `class_features.choice_type` désormais gérés sans jamais bloquer le
  /// flux — `'sous_classe'`/`'style_combat'`/`'ennemi_jure'` mènent à l'étape
  /// "Choix à faire" (increment 2, voir `domain/level_up_choice_kind.dart`),
  /// `'invocation'` à la nouvelle étape "Invocations" (voir la doc de classe
  /// ci-dessus) — ce dernier ne passe PAS par
  /// [LevelUpPendingChoiceResolver.resolve] vers un [LevelUpChoiceKind].
  static const Set<String> resolvedChoiceTypes = {
    'sous_classe',
    'style_combat',
    'ennemi_jure',
    'invocation',
  };

  /// Évalue si [targetLevel] doit bloquer tout le flux de montée de niveau,
  /// dans l'ordre suivant (une seule raison retenue, la première qui
  /// matche) :
  ///
  /// 1. [classFeatureChoiceType] non nul ET **pas** dans
  ///    [resolvedChoiceTypes] (aucune valeur peuplée en base à ce jour, voir
  ///    la doc de classe — filet de sécurité pour toute valeur future non
  ///    encore gérée) -> bloque avec le libellé résolu par
  ///    [ClassFeatureChoiceLabelFormatter].
  /// 2. [targetLevel] ∈ [abilityScoreImprovementLevels] -> ne bloque
  ///    **jamais** (étape "Choix à faire", répartition de caractéristiques
  ///    ou don).
  ///
  ///    **Cas défensif** (jamais rencontré dans les données actuelles,
  ///    vérifié : tous les `choice_type` peuplés sont aux niveaux 1-3, les
  ///    niveaux ASI sont 4/8/12/16/19, aucun chevauchement) : si
  ///    [classFeatureChoiceType] est aussi dans [resolvedChoiceTypes] au même
  ///    niveau, l'étape "Choix à faire" ne peut représenter qu'un seul choix
  ///    à la fois — plutôt que de deviner lequel des deux traiter et
  ///    d'ignorer l'autre silencieusement, cette méthode lève une
  ///    [CharacterFailure] explicite.
  ///
  /// **Ancienne condition 3 supprimée** (chantier "sorts/dons/invocations",
  /// voir la doc de classe) : une classe "à sorts connus" n'est plus jamais
  /// bloquée pour cette seule raison, quel que soit [targetLevel] — la
  /// nouvelle étape "Sorts" généralisée (`domain/spells_known_progression.dart`)
  /// gère désormais ce cas à la place (étape simplement absente quand le
  /// delta de sorts/cantrips connus est nul aux deux niveaux, voir
  /// `presentation/level_up_screen.dart`).
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

    return null;
  }
}
