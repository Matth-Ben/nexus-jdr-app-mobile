/// Une option d'Ascendance draconique disponible au choix de l'aptitude
/// "Ancêtre draconique" (Ensorceleur, Lignage draconique, niveau 1 de
/// sous-classe — `class_features.id = 368`, `class_id = NULL`, `subclass_id`
/// du Lignage draconique) — câblage de CODE uniquement, le contenu
/// (`class_options`, `option_type = 'ancetre_draconique'`, 10 lignes
/// attendues) arrive séparément (script dédié de Matthias) : cette classe
/// est écrite/testée contre le schéma attendu avant que le contenu existe
/// réellement en base.
///
/// Choix FIGÉ À VIE une fois fait (RAW standard, pas d'échange — contrairement
/// à la Métamagie/aux infusions) : niveau 1 de sous-classe uniquement, voir
/// `presentation/providers/level_up_provider.dart`.
///
/// [damageType] pilote automatiquement Résilience draconique (résistance,
/// `class_features.id = 57`) et Affinité élémentaire (`id = 369`) — voir
/// `CharacterDetail.draconicAncestryDamageType`, lu depuis
/// `CharacterDetail.classChoices` (même mécanisme générique que
/// `fightingStyles`/`hasBladePact`), une fois le contenu peuplé.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `LevelUpInfusionOption`.
class LevelUpDraconicAncestryOption {
  const LevelUpDraconicAncestryOption({
    required this.id,
    required this.name,
    required this.description,
    required this.damageType,
  });

  /// `class_options.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpInfusionOption.id`).
  final Object id;

  final String name;

  final String description;

  /// `class_options.prerequisites->>'damage_type'` — 'acide'/'foudre'/
  /// 'froid'/'feu'/'poison' (une des 5 valeurs RAW). Écrit tel quel dans
  /// `character_class_options.chosen_value` à la confirmation (texte libre,
  /// même convention que les autres mécaniques de ce chantier) : jamais un
  /// identifiant, ce texte est directement ce qui pilote Résilience
  /// draconique/Affinité élémentaire en lecture.
  final String damageType;
}
