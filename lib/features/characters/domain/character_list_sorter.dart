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
}
