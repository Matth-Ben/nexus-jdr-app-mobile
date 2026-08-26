/// Onglet actif de l'étape 7/9 "Équipement de départ" de l'assistant de
/// création (`presentation/equipment_step_screen.dart`), bascule segmentée
/// "Historique" / "Acheter (N PO)" de la spec visuelle.
///
/// Choix mutuellement exclusif (décision du chef de projet, voir la consigne
/// d'origine : "choix entre équipement de classe/historique **ou** achat via
/// l'or de départ — pas cumulable") : seul le contenu de l'onglet actif au
/// moment de "Suivant" est retenu dans `CharacterCreationDraft`
/// (`equipmentChoiceTab`), même si l'autre onglet porte une sélection encore
/// en mémoire (le panier "Acheter" reste préservé au changement d'onglet,
/// voir `presentation/equipment_step_screen.dart`, mais n'est écrit dans le
/// brouillon que s'il est actif à la validation).
enum EquipmentChoiceTab {
  /// Équipement de l'historique choisi à l'étape 3, automatiquement accordé
  /// (voir `domain/background_equipment_resolver.dart`).
  background,

  /// Achat libre dans le catalogue `items`, budget = "Bourse (N po)" de
  /// l'historique choisi (voir `domain/equipment_step_selection.dart`).
  purchase,
}
