import '../../../core/utils/french_text_normalizer.dart';
import 'character_list_sort.dart';
import 'character_summary.dart';

/// Ordonne la liste de personnages affichée sur l'écran d'accueil
/// (`presentation/character_list_screen.dart`) : les personnages encore en
/// jeu d'abord, puis les archivés, puis les morts.
///
/// Un personnage à la fois mort et archivé est classé avec les morts — la
/// mort est le statut le plus définitif des deux (voir
/// `CharacterSummary.isDead`/`isArchived`).
///
/// Tri stable : au sein d'un même groupe, l'ordre relatif d'origine (celui
/// renvoyé par `CharacterRepository.fetchCharacters`, par date de création)
/// est conservé.
abstract final class CharacterListSorter {
  static List<CharacterSummary> sort(List<CharacterSummary> characters) {
    // Regroupe via `where` (qui préserve l'ordre d'itération d'origine)
    // plutôt que `List.sort` (non garanti stable en Dart) pour ce tri à 3
    // groupes.
    final active = characters.where((c) => !c.isDead && !c.isArchived);
    final archived = characters.where((c) => !c.isDead && c.isArchived);
    final dead = characters.where((c) => c.isDead);
    return [...active, ...archived, ...dead];
  }

  /// Applique [mode] à [characters] (P18) : les trois groupes restent
  /// toujours dans l'ordre en jeu / archivés / morts (voir [sort]), le tri ne
  /// s'applique qu'**au sein** de chaque groupe. Tri stable (l'ordre relatif
  /// d'origine départage les égalités).
  ///
  /// [lastOpened] : `{characterId: epochMs}` local ; un personnage absent
  /// (jamais ouvert) passe après tous les autres de son groupe, dans son
  /// ordre d'origine.
  static List<CharacterSummary> sortBy(
    List<CharacterSummary> characters,
    CharacterListSort mode,
    Map<String, int> lastOpened,
  ) {
    final grouped = sort(characters);
    if (mode == CharacterListSort.defaultOrder) return grouped;
    final active = <CharacterSummary>[];
    final archived = <CharacterSummary>[];
    final dead = <CharacterSummary>[];
    for (final c in grouped) {
      (c.isDead ? dead : (c.isArchived ? archived : active)).add(c);
    }
    return [
      for (final group in [active, archived, dead])
        ..._sortGroup(group, mode, lastOpened),
    ];
  }

  static List<CharacterSummary> _sortGroup(
    List<CharacterSummary> group,
    CharacterListSort mode,
    Map<String, int> lastOpened,
  ) {
    // `List.sort` n'est pas garanti stable : l'index d'origine départage.
    final indexed = [for (var i = 0; i < group.length; i++) (i, group[i])];
    indexed.sort((a, b) {
      final cmp = switch (mode) {
        CharacterListSort.name => FrenchTextNormalizer.compare(
          a.$2.name,
          b.$2.name,
        ),
        CharacterListSort.lastOpened => _compareLastOpened(
          lastOpened[a.$2.id],
          lastOpened[b.$2.id],
        ),
        CharacterListSort.defaultOrder => 0,
      };
      return cmp != 0 ? cmp : a.$1.compareTo(b.$1);
    });
    return [for (final entry in indexed) entry.$2];
  }

  /// Plus récent d'abord ; `null` (jamais ouvert) après toute valeur.
  static int _compareLastOpened(int? a, int? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
