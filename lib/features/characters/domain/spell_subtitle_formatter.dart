import 'character_spell_entry.dart';

/// Sous-titre méta d'un sort ("{École} · Niveau {N}"/"{École} · Sort
/// mineur"), partagé mot pour mot entre la sheet "Actions de sort"
/// (`presentation/widgets/spell_action_sheet.dart`) et le panneau "Infos"
/// (`presentation/widgets/spell_info_panel.dart`) — voir la spec visuelle :
/// "sous-titre (identique à celui de la sheet d'actions)".
abstract final class SpellSubtitleFormatter {
  /// "{École} · Niveau {N}" (ou "{École} · Sort mineur" au niveau 0) ; replié
  /// sur juste le niveau si [CharacterSpellEntry.school] est vide.
  static String format(CharacterSpellEntry spell) {
    final levelLabel = spell.level == 0
        ? 'Sort mineur'
        : 'Niveau ${spell.level}';
    final school = spell.school.trim();
    if (school.isEmpty) return levelLabel;
    return '$school · $levelLabel';
  }
}
