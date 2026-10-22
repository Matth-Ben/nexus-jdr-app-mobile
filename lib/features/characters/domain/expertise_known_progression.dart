/// Déclencheurs RAW de l'Expertise (Barde/Roublard) — contrairement aux
/// autres mécaniques de ce chantier (métamagie, tirs arcaniques, runes,
/// manœuvres, infusions, disciplines élémentaires), ce n'est PAS une table
/// de progression cumulative : exactement 2 compétences à chaque
/// déclenchement, à des niveaux fixes et distincts par classe (RAW confirmée
/// par `regles-dnd`) :
/// - Barde : niveaux 3 et 10 en édition 2014 (`class_features.id` 167/175),
///   niveaux 2 et 9 en édition 2024 (nouvelles lignes `class_features`) —
///   voir [edition2024BardTriggerLevels]. Chantier "choix d'édition
///   2014/2024 par personnage" (`character_creation/domain
///   /character_creation_draft.dart::edition`) : avant ce chantier, seuls
///   les niveaux 2014 étaient câblés, avec une divergence RAW documentée et
///   assumée (voir l'historique git de ce fichier) — désormais résolue en
///   rendant [quotaAt] sensible à [edition].
/// - Roublard : niveaux 1 et 6, INCHANGÉS entre les deux éditions
///   (`class_features.id` 33/303, `edition` NULL — s'applique aux deux).
///   Le niveau 1 est RAW un choix de création (ou de multiclassage tardif),
///   mais ce dépôt ne câble aujourd'hui QUE le cas du multiclassage tardif
///   via ce provider : voir `requiresExpertiseSelection` dans
///   `presentation/providers/level_up_provider.dart`. La création native
///   d'un personnage Roublard niveau 1 a son propre chemin dédié
///   (`ClassChoiceStepScreen`/`character_creation_repository.dart`, D99 de
///   `docs/dette-technique.md`), hors du périmètre de ce fichier.
///
/// Le pool de compétences éligibles (déjà maîtrisées, PAS déjà en
/// Expertise) est GLOBAL au personnage, toutes classes/déclenchements
/// confondus — voir `data/character_repository.dart::fetchAvailableFeats`
/// pour le précédent de lecture directe de l'état déjà en base plutôt qu'un
/// catalogue séparé : l'Expertise pioche dans
/// `character_skill_proficiencies`, pas dans `class_options` (aucune ligne
/// `option_type = 'expertise'` en base, confirmé — RAW, l'Expertise
/// s'applique à une compétence DÉJÀ maîtrisée, elle n'a pas de "catalogue"
/// propre).
abstract final class ExpertiseKnownProgression {
  static const String bardClassName = 'Barde';
  static const String roguishClassName = 'Roublard';

  /// Niveaux de déclenchement du Barde en édition 2014 (défaut historique de
  /// ce fichier) — voir la doc de classe.
  static const Set<int> bardTriggerLevels = {3, 10};

  /// Niveaux de déclenchement du Barde en édition 2024 — voir la doc de
  /// classe. Le texte 2024 avance ces deux déclenchements d'un niveau par
  /// rapport à 2014 (3→2, 10→9).
  static const Set<int> edition2024BardTriggerLevels = {2, 9};

  /// Inchangés entre les deux éditions — voir la doc de classe.
  static const Set<int> roguishTriggerLevels = {1, 6};

  /// Quota RAW de compétences à passer en Expertise au niveau [level] de la
  /// classe [className], pour l'édition [edition] (`'2014'` par défaut,
  /// même convention que `CharacterDetail.edition`) — toujours 2 ou 0,
  /// jamais de valeur intermédiaire. Seul le Barde dépend de [edition] (voir
  /// [bardTriggerLevels]/[edition2024BardTriggerLevels]) ; le Roublard est
  /// inchangé entre les deux éditions.
  static int quotaAt(String className, int level, {String edition = '2014'}) {
    if (className == bardClassName &&
        (edition == '2024' ? edition2024BardTriggerLevels : bardTriggerLevels)
            .contains(level)) {
      return 2;
    }
    if (className == roguishClassName && roguishTriggerLevels.contains(level)) {
      return 2;
    }
    return 0;
  }

  /// `true` seulement pour le Roublard (RAW 2014 PHB : substitution de la
  /// maîtrise des outils de voleur à une des 2 places d'Expertise, aux DEUX
  /// déclenchements 1 et 6, indépendamment l'un de l'autre — jamais pour le
  /// Barde). Réintroduit par le chantier "choix d'édition 2014/2024 par
  /// personnage" (retiré en D104 de `docs/dette-technique.md` sur la base
  /// d'une citation RAW erronée, voir la doc de classe de ce fichier et
  /// celle de `presentation/providers/level_up_provider.dart
  /// ::LevelUpStepData.allowsThievesToolsSubstitution`) : à l'appelant de
  /// gater en plus par `edition == '2014'`, cette méthode ne connaît pas
  /// elle-même l'édition du personnage.
  static bool allowsThievesToolsSubstitution(String className) =>
      className == roguishClassName;
}
