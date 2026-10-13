import '../../../core/rules/spell_status.dart';
import 'character_spell_entry.dart';
import 'character_spell_slot.dart';
import 'innate_spell_usage.dart';
import 'spell_cast_eligibility.dart';
import 'spell_status_formatter.dart';

/// Raison pour laquelle l'action "Lancer" d'un sort est désactivée — affichée
/// sous le bouton du panneau "Infos"
/// (`presentation/widgets/spell_info_panel.dart`), qui restait jusque-là grisé
/// sans explication pour le joueur.
enum SpellCastBlockReason {
  /// Sort de niveau >= 1 simplement 'connu' : [SpellStatusFormatter.canCast]
  /// est faux.
  unprepared('Sort non préparé : préparez-le pour pouvoir le lancer.'),

  /// Plus aucun emplacement de niveau égal ou supérieur :
  /// [SpellCastEligibility.hasAvailableSlot] est faux.
  noSlotAvailable(
    "Plus d'emplacement de sort disponible pour ce niveau ou un niveau "
    'supérieur.',
  ),

  /// Sort inné de niveau >= 1 dont l'usage a déjà été dépensé depuis le
  /// dernier repos long : [InnateSpellUsage.hasUseAvailable] est faux. Pas
  /// de relance avec un emplacement dans cette version.
  innateUseSpent('Déjà utilisé : disponible après un repos long.');

  const SpellCastBlockReason(this.message);

  /// Texte d'aide affiché tel quel au joueur. À garder court : la mise en
  /// page du pied du panneau en dépend (matrice de mise en page de
  /// `spell_info_panel_test.dart`).
  final String message;

  /// Raison bloquant le lancer de [spell] par sa route ORDINAIRE
  /// (emplacement/préparation — classe), `null` s'il peut être lancé ainsi
  /// (donc toujours `null` pour un sort mineur, voir les deux règles
  /// réutilisées ici sans les redéfinir : [SpellStatusFormatter.canCast] et
  /// [SpellCastEligibility.hasAvailableSlot]).
  ///
  /// Un sort SEULEMENT inné (`spell.status == SpellStatus.innate`, aucune
  /// ligne ordinaire concurrente — voir
  /// `data/character_spell_row_mapper.dart::parseStatuses` — ET
  /// [InnateSpellUsage.isLimited] vrai, pour exclure un sort mineur inné — à
  /// volonté, sans notion d'usage — ou, en toute rigueur, un sort accordé
  /// par une sous-classe dont [status] vaudrait malgré tout 'inné' — ne
  /// devrait jamais arriver en pratique, voir [CharacterSpellEntry
  /// .grantSource]) est tranché en premier par [ofInnateRoute], sans jamais
  /// regarder [spellSlots] : il n'a AUCUNE route ordinaire, juste la
  /// sienne, gratuite.
  ///
  /// Un sort à double route (D43 du registre de dette technique,
  /// `docs/dette-technique.md` : inné ET connu/préparé, les deux lignes
  /// coexistent) NE prend PAS cette branche : [spell.status] y vaut déjà le
  /// statut ordinaire (toujours gagnant pour cette facette, voir
  /// [CharacterSpellEntry.hasInnateRoute]), donc cette méthode raisonne ici
  /// uniquement sur sa route ordinaire — sa route innée, indépendante, se
  /// teste séparément avec [ofInnateRoute], affichée comme une action à
  /// part dans le panneau "Infos" (`presentation/widgets/spell_info_panel
  /// .dart`), jamais fusionnée avec celle-ci : aucune des deux ne doit
  /// pouvoir masquer l'autre.
  ///
  /// [spellSlots] : tous les emplacements utilisables, magie de pacte
  /// comprise (fusionnés par l'appelant, comme pour
  /// [SpellCastEligibility.hasAvailableSlot]).
  static SpellCastBlockReason? of({
    required CharacterSpellEntry spell,
    required List<CharacterSpellSlot> spellSlots,
  }) {
    if (spell.status == SpellStatus.innate &&
        InnateSpellUsage.isLimited(spell)) {
      return ofInnateRoute(spell);
    }
    if (!SpellStatusFormatter.canCast(spell)) return unprepared;
    final hasSlot = SpellCastEligibility.hasAvailableSlot(
      spellSlots: spellSlots,
      spellLevel: spell.level,
    );
    return hasSlot ? null : noSlotAvailable;
  }

  /// Raison bloquant spécifiquement la route INNÉE (gratuite, sans
  /// emplacement, [InnateSpellUsage.usesPerLongRest] fois par repos long) de
  /// [spell] — `null` si elle n'a aucune route innée
  /// ([InnateSpellUsage.isLimited] faux : sort mineur, pas de ligne 'inné',
  /// ou accordé par une sous-classe) ou s'il lui reste un usage, sinon
  /// [innateUseSpent].
  ///
  /// Ignore totalement [spellSlots] : l'usage gratuit par repos long est
  /// indépendant de la route de classe (D43) — jamais de relance avec un
  /// emplacement dans cette version si l'usage inné est épuisé.
  ///
  /// Appelée par [of] pour un sort SEULEMENT inné (voir sa doc), et
  /// directement par le panneau "Infos" pour l'action "Lancer (sort inné)"
  /// séparée d'un sort à double route (D43).
  static SpellCastBlockReason? ofInnateRoute(CharacterSpellEntry spell) {
    if (!InnateSpellUsage.isLimited(spell)) return null;
    return InnateSpellUsage.hasUseAvailable(spell) ? null : innateUseSpent;
  }
}
