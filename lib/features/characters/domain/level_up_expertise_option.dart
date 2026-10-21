/// Une compétence candidate à l'Expertise, à l'étape "Expertise" de la
/// montée de niveau (Barde/Roublard,
/// `presentation/level_up_screen.dart`) — contrairement aux autres
/// mécaniques de ce chantier, PAS résolue depuis `class_options` (aucune
/// ligne `option_type = 'expertise'` en base, voir
/// `domain/expertise_known_progression.dart`) : construite directement
/// depuis les compétences DÉJÀ maîtrisées du personnage
/// (`CharacterDetail.skills`, `proficiency == 'competente'`), déjà chargées
/// par `characterDetailProvider` — aucune requête réseau supplémentaire.
///
/// Exclut déjà les compétences en Expertise (`proficiency == 'expertise'`,
/// pool GLOBAL au personnage) ET celles non maîtrisées (`proficiency ==
/// 'aucune'`) : le filtre `proficiency == 'competente'` suffit à lui seul,
/// voir `presentation/providers/level_up_provider.dart`.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `LevelUpInfusionOption`.
class LevelUpExpertiseOption {
  const LevelUpExpertiseOption({required this.skillId, required this.name});

  /// `skills.id`.
  final int skillId;

  final String name;
}
