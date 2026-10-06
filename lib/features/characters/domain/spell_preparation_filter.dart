import 'character_spell_entry.dart';
import 'spell_status_formatter.dart';

/// Filtre d'affichage de l'onglet "Sorts" selon l'état de préparation —
/// bascule "Tous"/"Préparés"/"Non préparés" de la carte "PRÉPARATION DES
/// SORTS" (`presentation/widgets/spell_preparation_card.dart`), demande
/// utilisateur du 06/10/2026. Pur filtre de présentation, jamais persisté.
enum SpellPreparationFilter {
  all('Tous'),
  prepared('Préparés'),
  unprepared('Non préparés');

  const SpellPreparationFilter(this.label);

  final String label;

  /// [prepared] garde tout ce qui est lançable en l'état (sorts préparés,
  /// mais aussi sorts mineurs, innés et accordés par une sous-classe, qui
  /// n'ont jamais à être préparés) ; [unprepared] ne garde que les sorts
  /// restant à préparer (voir [SpellStatusFormatter.isUnprepared]).
  List<CharacterSpellEntry> apply(List<CharacterSpellEntry> spells) =>
      switch (this) {
        all => spells,
        prepared => [
          for (final spell in spells)
            if (!SpellStatusFormatter.isUnprepared(spell)) spell,
        ],
        unprepared => [
          for (final spell in spells)
            if (SpellStatusFormatter.isUnprepared(spell)) spell,
        ],
      };
}
