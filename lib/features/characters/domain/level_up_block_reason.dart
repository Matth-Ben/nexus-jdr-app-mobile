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
/// **Correctif Moine, Voie des quatre éléments (bug bloquant)** :
/// `'discipline_elementaire'` a rejoint [resolvedChoiceTypes] — même
/// traitement que `'invocation'` ci-dessus (nouvelle étape "Disciplines
/// élémentaires" dédiée, basée sur le delta de
/// `domain/elemental_disciplines_known_progression.dart` à CHAQUE niveau
/// concerné — 3, 6, 11, 17 — indépendamment du nombre de lignes
/// `class_features.choice_type = 'discipline_elementaire'` réellement
/// présentes en base). Avant ce correctif, ce `choice_type` n'étant dans
/// aucune version de [resolvedChoiceTypes], tout Moine Voie des quatre
/// éléments restait bloqué indéfiniment à sa montée de niveau 3.
///
/// **Chantier "tir arcanique/rune/infusion"** : `'tir_arcanique'` (Guerrier,
/// Archer arcanique), `'rune'` (Guerrier, Chevalier runique) et `'infusion'`
/// (Artificier, aptitude de CLASSE) ont rejoint [resolvedChoiceTypes] — même
/// traitement que `'discipline_elementaire'`/`'invocation'` ci-dessus
/// (étapes dédiées "Tirs arcaniques"/"Runes"/"Infusions", basées sur le
/// delta de `domain/arcane_shots_known_progression.dart`/
/// `domain/runes_known_progression.dart`/
/// `domain/infusions_known_progression.dart`). Ces 3 lignes `class_features`
/// ont `choice_type = NULL` en base au moment de ce chantier (un SQL de
/// correction de contenu, préparé pour Matthias, doit encore être exécuté
/// côté dépôt web) : cet ajout à [resolvedChoiceTypes] est donc écrit pour
/// fonctionner correctement une fois ce SQL appliqué, mais ne change rien
/// tant qu'il ne l'est pas (un `choice_type` nul ne passe jamais par ce
/// test, voir [evaluate] ci-dessous) — même défense que le reste de ce
/// fichier face à un contenu non encore peuplé.
///
/// **Correctif D92** (`docs/dette-technique.md`) : `'manoeuvre'` (Guerrier,
/// Maître de guerre) a rejoint [resolvedChoiceTypes] — même traitement que
/// `'tir_arcanique'`/`'rune'`/`'infusion'` ci-dessus (étape dédiée
/// "Manœuvres" déjà câblée, `domain/maneuvers_known_progression.dart`, basée
/// sur `requiresManeuverSelection`/`maneuverDelta` dans
/// `presentation/providers/level_up_provider.dart`, indépendamment de
/// [LevelUpPendingChoiceResolver.resolve]). Avant ce correctif, si
/// `class_features.choice_type = 'manoeuvre'` devenait non nul en base,
/// [evaluate] aurait bloqué tout Guerrier Maître de guerre à son niveau 3
/// malgré cette étape déjà fonctionnelle — exactement le bug D86 rejoué.
/// `'manoeuvre'` a aussi rejoint l'exclusion correspondante de
/// [LevelUpPendingChoiceResolver.resolve] (`domain/level_up_choice_kind.dart`)
/// pour que le `StateError` défensif de cette méthode ne se déclenche pas à
/// tort une fois cette valeur non nulle en base.
///
/// Un niveau qui reste bloqué bloque tout le flux *avant* même l'étape
/// "Points de vie" (jamais de jet de dé pour rien) — ne reste concerné que
/// tout `class_features.choice_type` non nul et encore inconnu de
/// [resolvedChoiceTypes] (voir `20260825090700_seed_classes_subclasses_features.sql`
/// côté dépôt web pour l'historique du peuplement : les valeurs
/// `sous_classe`/`style_combat`/`ennemi_jure`/`invocation`/`pacte`/
/// `discipline_elementaire` y sont toutes désormais présentes).
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
  /// `'pacte'` (Faveur de pacte de l'Occultiste, niveau 3) à l'étape "Choix à
  /// faire" (`LevelUpChoiceKind.pact`), `'invocation'`,
  /// `'discipline_elementaire'`, `'tir_arcanique'`, `'rune'`, `'infusion'` et
  /// `'manoeuvre'` à leurs étapes dédiées respectives
  /// ("Invocations"/"Disciplines élémentaires"/"Tirs
  /// arcaniques"/"Runes"/"Infusions"/"Manœuvres", voir la doc de classe
  /// ci-dessus) — ces six derniers ne passent PAS par
  /// [LevelUpPendingChoiceResolver.resolve] vers un [LevelUpChoiceKind].
  static const Set<String> resolvedChoiceTypes = {
    'sous_classe',
    'style_combat',
    'ennemi_jure',
    'invocation',
    'pacte',
    'discipline_elementaire',
    'tir_arcanique',
    'rune',
    'infusion',
    'manoeuvre',
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
