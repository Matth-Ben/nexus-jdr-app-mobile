import 'package:freezed_annotation/freezed_annotation.dart';

part 'background_option.freezed.dart';

/// Un historique sélectionnable à l'étape 3/9 de l'assistant de création
/// (`backgrounds`, voir `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// [skillProficiencies] est purement informatif à cette étape (affiché tel
/// quel, jamais utilisé pour construire une UI de choix de compétences) :
/// voir le commentaire de classe de [BackgroundCatalog] pour le rationale
/// détaillé de ce report.
@freezed
abstract class BackgroundOption with _$BackgroundOption {
  const BackgroundOption._();

  const factory BackgroundOption({
    required int id,
    required String name,

    /// Noms de compétences en français directement (`backgrounds
    /// .skill_proficiencies`, jsonb) — pas de FK vers `skills`, donc aucune
    /// jointure nécessaire pour les afficher.
    required List<String> skillProficiencies,
    required String featureName,
    required String featureDescription,
  }) = _BackgroundOption;

  /// Ligne "Compétences : X, Y" affichée pour toutes les lignes, qu'elles
  /// soient sélectionnées ou non (maquette `04_étape_3_historique.png`).
  String get skillsSummaryLine =>
      'Compétences : ${skillProficiencies.join(', ')}';

  /// Ligne "Aptitude : {featureName} — {featureDescription}" affichée
  /// seulement pour la ligne sélectionnée (maquette) — voir
  /// `SelectableOptionTile.selectedDetail`, utilisé par
  /// `presentation/background_step_screen.dart`.
  String get featureSummaryLine =>
      'Aptitude : $featureName — $featureDescription';
}
