/// Logique pure du choix d'Expertise du Roublard au niveau 1 (correctif
/// D99, `docs/dette-technique.md`), extraite de
/// `presentation/class_choice_step_screen.dart` pour rester testable sans
/// widget — même principe que `SkillsAndToolsStepSelection`.
///
/// RAW (*Manuel des Joueurs*, Roublard, Expertise) : au niveau 1, le Roublard
/// choisit exactement 2 compétences DÉJÀ maîtrisées (classe/race/historique)
/// pour y gagner l'Expertise (double bonus de maîtrise) — AUCUNE
/// substitution par la maîtrise des outils de voleur n'existe à ce niveau.
/// Cette substitution ("vous pouvez choisir deux compétences supplémentaires
/// ou votre maîtrise des outils de voleur") n'existe RAW qu'**au niveau 6**
/// — correctif D100 (`docs/dette-technique.md`) : la première implémentation
/// (D99) la proposait par erreur dès la création, `ClassChoiceStepScreen`
/// (mode Roublard niveau 1) ne la propose donc plus. Le paramètre
/// [bool thievesToolsSubstitution]/les méthodes ci-dessous le conservent
/// volontairement (jamais atteignable à `true` depuis ce point d'entrée
/// niveau 1) pour être réutilisés tels quels par un futur chantier
/// "Expertise niveau 6" (second lot d'Expertise + substitution outils de
/// voleur, maîtrise toujours accordée automatiquement au Roublard, voir
/// `ClassOption.grantedToolNames`). Les outils n'ayant aucun bonus chiffré
/// modélisé dans cette app (voir `CharacterToolProficienciesCard`), cette
/// substitution restera purement descriptive côté persistance
/// (`character_class_options.chosen_value`) : aucun calcul de bonus n'en
/// découle, contrairement aux 2 compétences (qui, elles, passent réellement
/// `character_skill_proficiencies.proficiency` à `'expertise'` — voir
/// `data/character_creation_repository.dart::createCharacter`).
abstract final class ExpertiseStepSelection {
  /// Quota RAW : 2 "emplacements" d'Expertise au niveau 1 du Roublard.
  static const int quota = 2;

  /// Quota réellement utilisable, plafonné par le nombre d'options
  /// disponibles (compétences déjà maîtrisées + 1 si la substitution outils
  /// de voleur est proposée) — garde défensive au cas où un personnage
  /// disposerait de moins de 2 compétences maîtrisées à ce stade du
  /// brouillon (ne devrait normalement jamais arriver, un Roublard ayant
  /// toujours au moins 4 compétences de classe + celles de l'historique),
  /// même principe que les autres quotas plafonnés de ce chantier (ex.
  /// `_effectiveExpertiseSkillQuota` côté montée de niveau).
  static int effectiveQuota(int availableOptionsCount) =>
      availableOptionsCount < quota ? availableOptionsCount : quota;

  /// Quota restant pour les compétences (hors substitution outils), à passer
  /// à `SkillsAndToolsStepSelection.toggle`/`.isChoiceLocked` pour les tuiles
  /// de compétence.
  static int skillQuota({
    required int availableOptionsCount,
    required bool thievesToolsSubstitution,
  }) {
    final effective = effectiveQuota(availableOptionsCount);
    return thievesToolsSubstitution ? effective - 1 : effective;
  }

  /// Nombre total d'emplacements déjà utilisés (compétences + substitution
  /// outils).
  static int selectedCount({
    required List<String> selectedSkillNames,
    required bool thievesToolsSubstitution,
  }) => selectedSkillNames.length + (thievesToolsSubstitution ? 1 : 0);

  /// "Suivant" ne s'active que lorsque le quota effectif est atteint
  /// EXACTEMENT — jamais bloquant si le catalogue de candidats est vide (cas
  /// défensif, voir la doc de classe).
  static bool canProceed({
    required int availableOptionsCount,
    required List<String> selectedSkillNames,
    required bool thievesToolsSubstitution,
  }) {
    final effective = effectiveQuota(availableOptionsCount);
    if (effective <= 0) return true;
    return selectedCount(
          selectedSkillNames: selectedSkillNames,
          thievesToolsSubstitution: thievesToolsSubstitution,
        ) ==
        effective;
  }

  /// Rehausse la maîtrise ('competente' -> 'expertise') des lignes de
  /// [skillRows] dont le `skillId` est dans [expertiseSkillIds] — logique
  /// pure appliquée par `CharacterCreationRepository.createCharacter` juste
  /// avant l'insertion dans `character_skill_proficiencies`, pour que la
  /// même compétence ne soit jamais insérée deux fois (une ligne
  /// `'competente'` déjà résolue par `SkillProficiencyResolver`, rehaussée en
  /// place plutôt que dupliquée) — correctif D99. [expertiseSkillIds] vide
  /// (classe autre que le Roublard, ou rien choisi) : [skillRows] renvoyée
  /// inchangée.
  static List<({int skillId, String proficiency})> upgradeToExpertise({
    required List<({int skillId, String proficiency})> skillRows,
    required Set<int> expertiseSkillIds,
  }) {
    if (expertiseSkillIds.isEmpty) return skillRows;
    return [
      for (final row in skillRows)
        expertiseSkillIds.contains(row.skillId)
            ? (skillId: row.skillId, proficiency: 'expertise')
            : row,
    ];
  }
}
