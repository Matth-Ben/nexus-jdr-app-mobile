import 'package:freezed_annotation/freezed_annotation.dart';

part 'background_option.freezed.dart';

/// Un historique sélectionnable à l'étape 3/9 de l'assistant de création
/// (`backgrounds`, voir `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// [skillProficiencies] est purement informatif à cette étape (affiché tel
/// quel, jamais utilisé pour construire une UI de choix de compétences) :
/// voir le commentaire de classe de [BackgroundCatalog] pour le rationale
/// détaillé de ce report.
///
/// [toolOrLanguageGrantedTools]/[languageChoiceCount] ne sont utilisés qu'à
/// l'étape 5/9 "Compétences et outils" (`presentation
/// /skills_and_tools_step_screen.dart`), même rationale que les champs
/// équivalents de [ClassOption] : voyagent sur ce modèle plutôt qu'un modèle
/// dédié, valeurs par défaut permissives pour ne pas casser les usages
/// existants de l'étape 3/9.
///
/// `backgrounds.tool_or_language_choices` (jsonb) peut contenir jusqu'à trois
/// clés (vérifié contre
/// `supabase/migrations/20260825090800_seed_backgrounds.sql` du dépôt web) :
/// - `"tools"` (tableau de chaînes) : parfois un vrai nom d'outil ("Kit de
///   déguisement"), parfois une phrase de substitution ("un jeu au choix",
///   "un instrument de musique au choix") — décision du chef de projet :
///   traité tel quel comme du texte informatif octroyé automatiquement, pas
///   comme un choix interactif (contrairement à la forme `{"count", "type"}`
///   de `classes.tool_proficiencies`), donc jamais résolu vers un id
///   `tools.id`. Voir [toolOrLanguageGrantedTools].
/// - `"languages"` (entier) : un vrai choix interactif de N langues parmi la
///   table `languages`. Voir [languageChoiceCount].
/// - `"vehicles"` (tableau de chaînes) : hors périmètre de l'étape 5/9,
///   jamais lu ni affiché (décision du chef de projet) — pas de champ dédié
///   sur ce modèle.
///
/// [equipment] n'est utilisé qu'à l'étape 7/9 "Équipement de départ"
/// (`presentation/equipment_step_screen.dart`), même rationale que
/// [toolOrLanguageGrantedTools]/[languageChoiceCount] pour l'étape 5/9 :
/// voyage sur ce modèle plutôt qu'un modèle dédié, valeur par défaut vide
/// pour ne pas casser les usages existants des étapes 3/5.
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

    /// Contenu de la clé `"tools"` de `tool_or_language_choices`, tel quel
    /// (voir le commentaire de classe) — vide si cette clé est absente.
    @Default(<String>[]) List<String> toolOrLanguageGrantedTools,

    /// Contenu de la clé `"languages"` de `tool_or_language_choices`, `null`
    /// si cette clé est absente (pas de choix de langue octroyé par cet
    /// historique).
    int? languageChoiceCount,

    /// `backgrounds.equipment` (jsonb), tableau plat de chaînes de texte
    /// libre tel quel (ex. `["Symbole sacré", ..., "Bourse (15 po)"]`) —
    /// **pas** de structure `{item, quantity}` (contrairement à
    /// `equipment_packs.contents`, non utilisé ici), voir le commentaire de
    /// classe pour le rationale détaillé et
    /// `domain/background_equipment_parser.dart`/
    /// `domain/background_equipment_resolver.dart` pour son exploitation à
    /// l'étape 7/9.
    @Default(<String>[]) List<String> equipment,
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
