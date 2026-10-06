import '../../../core/utils/french_text_normalizer.dart';
import 'character_spell_entry.dart';
import 'spell_status_formatter.dart';

/// Un groupe de sorts d'un même niveau, pour la section "SORTS" de l'onglet
/// Compétences (`presentation/widgets/character_spells_section.dart`).
class SpellLevelGroup {
  const SpellLevelGroup({
    required this.level,
    required this.label,
    required this.spells,
  });

  final int level;

  /// "Sorts mineurs" (niveau 0) ou "Niveau N".
  final String label;

  final List<CharacterSpellEntry> spells;
}

/// Regroupe les sorts d'un personnage par niveau pour l'affichage — voir la
/// spec de la tâche qui a produit ce fichier ("0 = Sorts mineurs, 1 =
/// Niveau 1, etc.").
abstract final class SpellsByLevelGrouper {
  static String labelFor(int level) =>
      level == 0 ? 'Sorts mineurs' : 'Niveau $level';

  /// Groupes triés par niveau croissant (mineurs en premier), sorts triés
  /// par nom au sein d'un même niveau. Avec [preparedFirst], les sorts
  /// restant à préparer ([SpellStatusFormatter.isUnprepared]) passent après
  /// tous les autres au sein de leur niveau (onglet "Sorts", demande
  /// utilisateur du 06/10/2026).
  static List<SpellLevelGroup> group(
    List<CharacterSpellEntry> spells, {
    bool preparedFirst = false,
  }) {
    final byLevel = <int, List<CharacterSpellEntry>>{};
    for (final spell in spells) {
      byLevel.putIfAbsent(spell.level, () => []).add(spell);
    }

    final levels = byLevel.keys.toList()..sort();
    return [
      for (final level in levels)
        SpellLevelGroup(
          level: level,
          label: labelFor(level),
          spells: byLevel[level]!
            ..sort((a, b) {
              if (preparedFirst) {
                final aUnprepared = SpellStatusFormatter.isUnprepared(a);
                final bUnprepared = SpellStatusFormatter.isUnprepared(b);
                if (aUnprepared != bUnprepared) return aUnprepared ? 1 : -1;
              }
              return FrenchTextNormalizer.compare(a.name, b.name);
            }),
        ),
    ];
  }
}
