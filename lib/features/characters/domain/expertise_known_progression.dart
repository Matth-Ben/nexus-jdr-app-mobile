/// Déclencheurs RAW de l'Expertise (Barde/Roublard) — contrairement aux
/// autres mécaniques de ce chantier (métamagie, tirs arcaniques, runes,
/// manœuvres, infusions, disciplines élémentaires), ce n'est PAS une table
/// de progression cumulative : exactement 2 compétences à chaque
/// déclenchement, à des niveaux fixes et distincts par classe (RAW confirmée
/// par `regles-dnd`) :
/// - Barde : niveaux 3 et 10 (`class_features.id` 167/175 — niveau 3 en base
///   pour le premier, le texte 2024 réel est niveau 2, divergence assumée,
///   câblé tel quel).
/// - Roublard : niveaux 1 et 6 (`class_features.id` 33/303). Le niveau 1 est
///   RAW un choix de création (ou de multiclassage tardif), mais ce dépôt ne
///   câble aujourd'hui QUE le cas du multiclassage tardif : il passe par ce
///   provider comme tout autre niveau 1 de nouvelle classe (voir
///   `requiresExpertiseSelection` dans
///   `presentation/providers/level_up_provider.dart`). La création native
///   d'un personnage Roublard niveau 1 n'écrit PAS ce choix —
///   `character_creation_repository.dart` n'écrit jamais dans
///   `character_class_options` et aucun écran de création dédié n'existe ;
///   trou architectural générique (touche aussi Style de combat du
///   Guerrier et Pacte de l'Occultiste) consigné en D99 de
///   `docs/dette-technique.md`, pas corrigé ici.
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

  static const Set<int> bardTriggerLevels = {3, 10};
  static const Set<int> roguishTriggerLevels = {1, 6};

  /// Quota RAW de compétences à passer en Expertise au niveau [level] de la
  /// classe [className] — toujours 2 ou 0, jamais de valeur intermédiaire.
  static int quotaAt(String className, int level) {
    if (className == bardClassName && bardTriggerLevels.contains(level)) {
      return 2;
    }
    if (className == roguishClassName && roguishTriggerLevels.contains(level)) {
      return 2;
    }
    return 0;
  }
}
