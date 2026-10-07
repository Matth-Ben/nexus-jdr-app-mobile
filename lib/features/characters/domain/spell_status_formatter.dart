import 'character_spell_entry.dart';

/// Règles dérivées de `CharacterSpellEntry.status`
/// ('connu'/'préparé'/'inné') — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Sorts" : "Distinction claire entre sorts connus et sorts
/// préparés (pour les classes à préparation quotidienne, ex.
/// Clerc/Druide)".
///
/// Aucune classe n'est consultée ici : la classe d'origine du sort est déjà
/// résumée par [CharacterSpellEntry.requiresPreparation] (dérivé à la
/// lecture, voir `PreparedSpellsLimit.spellRequiresPreparation`). Un sort
/// d'une classe à sorts connus (Barde, Ensorceleur, Occultiste, Rôdeur) se
/// lance sans préparation : ni bascule, ni libellé, ni sous-titre de
/// préparation, quel que soit son `status`.
abstract final class SpellStatusFormatter {
  /// Sous-titre affiché sous le nom du sort ("connu, non préparé" /
  /// "préparé"), `null` si aucun texte n'a de sens : un sort mineur (niveau
  /// 0, jamais "dépréparé" en 5e), un sort inné (toujours disponible,
  /// aucune notion de préparation) ou un sort qui ne se prépare pas
  /// ([CharacterSpellEntry.requiresPreparation] faux) — voir la maquette
  /// "Fiche — Sorts" (`09-maquettes-captures.md`), qui n'affiche ce sous-titre que pour les
  /// sorts de niveau ≥ 1 "connu"/"préparé".
  static String? subtitle(CharacterSpellEntry spell) {
    if (spell.level == 0) return null;
    final grant = spell.grantSource;
    if (grant != null) return 'toujours préparé · ${grant.label}';
    if (!spell.requiresPreparation) return null;
    switch (spell.status) {
      case 'connu':
        return 'connu, non préparé';
      case 'préparé':
        return 'préparé';
      default:
        // 'inné', ou une valeur inattendue (contrainte check côté base,
        // ne devrait pas arriver) : traité comme "toujours disponible",
        // aucun sous-titre.
        return null;
    }
  }

  /// `true` si ce sort peut être lancé : toujours vrai pour un sort mineur,
  /// inné ou qui ne se prépare pas (classe à sorts connus, voir
  /// [CharacterSpellEntry.requiresPreparation]), sinon seulement s'il est
  /// "préparé" — un sort simplement "connu" (non préparé) ne peut pas être
  /// lancé tant qu'il n'a pas été préparé, voir [canTogglePrepared].
  static bool canCast(CharacterSpellEntry spell) {
    if (spell.level == 0) return true;
    if (!spell.requiresPreparation) return true;
    return spell.status != 'connu';
  }

  /// `true` si la bascule "Préparer ce sort"/"Ne plus préparer" a un sens
  /// pour ce sort — jamais pour un sort mineur (niveau 0) ni un sort inné
  /// ('inné'), qui n'ont pas de notion de préparation à faire varier, ni pour
  /// un sort accordé par une sous-classe (toujours préparé), ni pour un sort
  /// qui ne se prépare pas ([CharacterSpellEntry.requiresPreparation] faux,
  /// même si son `status` vaut 'préparé').
  static bool canTogglePrepared(CharacterSpellEntry spell) {
    if (spell.level == 0) return false;
    // Sort accordé par une sous-classe : toujours préparé, jamais retirable.
    if (spell.isAlwaysPrepared) return false;
    if (!spell.requiresPreparation) return false;
    return spell.status == 'connu' || spell.status == 'préparé';
  }

  /// `true` si ce sort attend d'être préparé pour pouvoir être lancé : un
  /// sort de niveau >= 1 simplement 'connu' — exactement les sorts pour
  /// lesquels [canCast] est faux et [canTogglePrepared] vrai. Affiché grisé
  /// et après les sorts préparés dans l'onglet "Sorts" (voir
  /// `presentation/widgets/character_spells_section.dart::_SpellRow`,
  /// `SpellsByLevelGrouper.group`).
  static bool isUnprepared(CharacterSpellEntry spell) =>
      canTogglePrepared(spell) && spell.status == 'connu';

  /// Libellé d'état de préparation affiché en face du nom du sort dans
  /// l'onglet "Sorts" ("préparé"/"non préparé"), `null` pour un sort sans
  /// notion de préparation à faire varier (sort mineur, inné, sort d'une
  /// classe à sorts connus, accordé par une sous-classe — ce dernier porte
  /// déjà sa pastille "DOMAINE"/"SERMENT").
  static String? preparationLabel(CharacterSpellEntry spell) {
    if (!canTogglePrepared(spell)) return null;
    return spell.status == 'préparé' ? 'préparé' : 'non préparé';
  }
}
