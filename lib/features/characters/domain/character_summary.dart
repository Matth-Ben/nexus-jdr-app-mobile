import 'package:freezed_annotation/freezed_annotation.dart';

import 'xp_table.dart';

part 'character_summary.freezed.dart';

/// Résumé d'un personnage tel qu'affiché dans la liste d'accueil
/// (`presentation/character_list_screen.dart`).
///
/// Combine des champs directs de `characters` (`02-modele-donnees.md`) avec
/// des valeurs déjà résolues côté dépôt (`data/character_repository.dart`) :
/// nom de race/classe traduits, niveau total tous multiclassages confondus.
/// Volontairement plus léger que le futur modèle complet de fiche
/// personnage, qui vivra dans ce même dossier `domain/` une fois la fiche
/// implémentée.
@freezed
abstract class CharacterSummary with _$CharacterSummary {
  const CharacterSummary._();

  const factory CharacterSummary({
    required String id,
    required String name,

    /// URL publique/signée du portrait (`characters.portrait_url`), `null`
    /// si le joueur n'en a pas encore défini un.
    String? portraitUrl,

    /// Nom de race traduit (via `translations`), `null` si race
    /// personnalisée (homebrew) ou non résolue.
    String? raceName,

    /// Nom de la classe principale traduit (`character_classes.is_primary`
    /// = true, ou la première classe à défaut), `null` si le personnage n'a
    /// aucune classe enregistrée.
    String? className,

    /// Niveau total, somme de `character_classes.level` (gère le
    /// multiclassage de façon simple : un personnage niveau 3/2 est affiché
    /// "Niv. 5").
    required int level,

    /// XP cumulée actuelle (`characters.xp`).
    required int xp,

    /// `characters.is_dead` — voir `CharacterDetail.isDead` pour le
    /// rationale complet (statut "mort" manuel). Surfacé ici pour le badge
    /// "MORT" de la carte personnage (`presentation/widgets/character_card.dart`),
    /// voir `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`
    /// section 2. `@Default(false)` : ajouté après la première version de ce
    /// modèle.
    @Default(false) bool isDead,

    /// `characters.is_archived` — statut "archivé" manuel (même principe que
    /// [isDead] : un flag simple, sans effet caché sur le reste de la fiche,
    /// voir `docs/cahier-des-charges/10-design-system.md` section 4, "Carte
    /// personnage", variante "archivé"). Bascule via le lien "Archiver ce
    /// personnage"/"Désarchiver" de l'onglet "Personnage"
    /// (`CharacterVitalsCard`) — voir `CharacterRepository.setArchived`.
    @Default(false) bool isArchived,
  }) = _CharacterSummary;

  /// XP cumulée requise pour le niveau suivant, `null` si [level] est déjà
  /// au niveau maximum de la table de progression ([XpTable.maxLevel]).
  int? get nextLevelXpThreshold => XpTable.cumulativeXpForNextLevel(level);

  /// Ratio de remplissage de la jauge XP, entre 0 et 1.
  ///
  /// Vaut 1 (jauge pleine) si le personnage est déjà au niveau maximum : il
  /// n'y a alors plus de "niveau suivant" vers lequel progresser.
  double get xpProgress {
    final nextThreshold = nextLevelXpThreshold;
    if (nextThreshold == null) {
      return 1;
    }
    final currentThreshold = XpTable.cumulativeXpForLevel(level);
    final span = nextThreshold - currentThreshold;
    if (span <= 0) {
      return 1;
    }
    return ((xp - currentThreshold) / span).clamp(0, 1).toDouble();
  }
}
