/// Mode de tri de la liste des personnages (P18), choisi dans la feuille
/// « Filtrer et trier » de `character_list_screen.dart`. Par session, non
/// persisté (comme les filtres de classe/statut).
enum CharacterListSort {
  /// Ordre du repository : en jeu, archivés, puis morts, par date de création.
  defaultOrder,

  /// Nom (A → Z), insensible à la casse et aux accents, au sein de chaque
  /// groupe.
  name,

  /// Dernière ouverture de la fiche (locale à l'appareil), la plus récente
  /// d'abord, au sein de chaque groupe ; jamais ouvert = dernier du groupe.
  lastOpened,
}
