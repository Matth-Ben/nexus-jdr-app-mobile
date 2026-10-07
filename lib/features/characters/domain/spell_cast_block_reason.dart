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

  /// Raison bloquant le lancer de [spell], `null` s'il peut être lancé (donc
  /// toujours `null` pour un sort mineur, voir les deux règles réutilisées
  /// ici sans les redéfinir : [SpellStatusFormatter.canCast] et
  /// [SpellCastEligibility.hasAvailableSlot]).
  ///
  /// Un sort inné à charge ([InnateSpellUsage.isLimited]) est tranché en
  /// premier, sans jamais regarder [spellSlots] : il se lance sans
  /// emplacement, donc `null` tant qu'il lui reste un usage, [innateUseSpent]
  /// sinon — jamais [unprepared] ni [noSlotAvailable].
  ///
  /// [spellSlots] : tous les emplacements utilisables, magie de pacte
  /// comprise (fusionnés par l'appelant, comme pour
  /// [SpellCastEligibility.hasAvailableSlot]).
  ///
  /// Quand les deux raisons s'appliquent, [unprepared] l'emporte : c'est
  /// celle sur laquelle le joueur peut agir tout de suite depuis le panneau
  /// (lien "Préparer ce sort") — une seule raison, jamais deux.
  static SpellCastBlockReason? of({
    required CharacterSpellEntry spell,
    required List<CharacterSpellSlot> spellSlots,
  }) {
    if (InnateSpellUsage.isLimited(spell)) {
      return InnateSpellUsage.hasUseAvailable(spell) ? null : innateUseSpent;
    }
    if (!SpellStatusFormatter.canCast(spell)) return unprepared;
    final hasSlot = SpellCastEligibility.hasAvailableSlot(
      spellSlots: spellSlots,
      spellLevel: spell.level,
    );
    return hasSlot ? null : noSlotAvailable;
  }
}
