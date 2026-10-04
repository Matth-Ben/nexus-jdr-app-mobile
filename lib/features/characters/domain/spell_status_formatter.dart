import 'character_spell_entry.dart';

/// Règles dérivées de `CharacterSpellEntry.status`
/// ('connu'/'préparé'/'inné') — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Sorts" : "Distinction claire entre sorts connus et sorts
/// préparés (pour les classes à préparation quotidienne, ex.
/// Clerc/Druide)".
///
/// Aucune classe "préparée"/"connue" n'est consultée ici (contrairement à
/// `character_creation/domain/spellcasting_rules.dart::statusFor`, qui ne
/// s'applique qu'à la création) : [status] porte déjà l'information utile,
/// ces règles s'appliquent identiquement quelle que soit la classe
/// d'origine du sort.
abstract final class SpellStatusFormatter {
  /// Sous-titre affiché sous le nom du sort ("connu, non préparé" /
  /// "préparé"), `null` si aucun texte n'a de sens : un sort mineur (niveau
  /// 0, jamais "dépréparé" en 5e) ou un sort inné (toujours disponible,
  /// aucune notion de préparation) — voir la maquette "Fiche — Sorts"
  /// (`09-maquettes-captures.md`), qui n'affiche ce sous-titre que pour les
  /// sorts de niveau ≥ 1 "connu"/"préparé".
  static String? subtitle(CharacterSpellEntry spell) {
    if (spell.level == 0) return null;
    final grant = spell.grantSource;
    if (grant != null) return 'toujours préparé · ${grant.label}';
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

  /// `true` si ce sort peut être lancé : toujours vrai pour un sort mineur
  /// ou inné (jamais de notion de préparation), sinon seulement s'il est
  /// "préparé" — un sort simplement "connu" (non préparé) ne peut pas être
  /// lancé tant qu'il n'a pas été préparé, voir [canTogglePrepared].
  static bool canCast(CharacterSpellEntry spell) {
    if (spell.level == 0) return true;
    return spell.status != 'connu';
  }

  /// `true` si la bascule "Préparer ce sort"/"Ne plus préparer" a un sens
  /// pour ce sort — jamais pour un sort mineur (niveau 0) ni un sort inné
  /// ('inné'), qui n'ont pas de notion de préparation à faire varier, ni pour
  /// un sort accordé par une sous-classe (toujours préparé).
  static bool canTogglePrepared(CharacterSpellEntry spell) {
    if (spell.level == 0) return false;
    // Sort accordé par une sous-classe : toujours préparé, jamais retirable.
    if (spell.isAlwaysPrepared) return false;
    return spell.status == 'connu' || spell.status == 'préparé';
  }

  /// `true` si ce sort doit apparaître par défaut dans l'onglet "Sorts" d'un
  /// lanceur à préparation "liste complète" (Clerc/Druide/Paladin, voir
  /// `domain/prepared_caster_spell_list.dart::PreparedCasterSpellList`) —
  /// tous les sorts de la classe sont déjà fusionnés côté `CharacterDetail
  /// .spells` par `CharacterRepository` (voir
  /// `data/character_repository.dart::_fetchPreparedCasterClassListSpellIds`),
  /// ce prédicat n'est qu'un filtre d'affichage.
  ///
  /// `!canTogglePrepared(spell)` couvre déjà sans distinction supplémentaire
  /// les trois cas toujours visibles (sort mineur niveau 0, sort accordé par
  /// une sous-classe, sort 'inné') : seule une entrée `status == 'connu'`
  /// niveau >= 1 jamais préparée est masquée par défaut (elle reste
  /// accessible depuis la sheet "Ajouter un sort",
  /// `presentation/widgets/add_prepared_spells_sheet.dart`).
  static bool isVisibleInPreparedView(CharacterSpellEntry spell) =>
      !canTogglePrepared(spell) || spell.status == 'préparé';
}
