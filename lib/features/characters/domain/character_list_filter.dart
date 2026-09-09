import 'character_summary.dart';

/// Filtre pur de la liste des personnages (recherche par nom + filtre par
/// classe) — voir `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`
/// section 2, "Recherche / filtre dans la liste des personnages", et la
/// maquette "Liste des personnages" (`09-maquettes-captures.md`, barre de
/// recherche + icône filtre).
///
/// Widget appelant : `presentation/character_list_screen.dart`.
abstract final class CharacterListFilter {
  /// [query] : sous-chaîne recherchée dans [CharacterSummary.name],
  /// insensible à la casse — même convention que le seul autre champ de
  /// recherche déjà existant dans ce dépôt
  /// (`presentation/widgets/add_item_flow.dart`, catalogue d'objets) :
  /// comparaison simple `toLowerCase().contains(...)`, sans normalisation
  /// des accents (aucun précédent de ce genre dans ce dépôt à ce jour).
  ///
  /// [classNames] : ensemble des classes retenues ; un ensemble vide
  /// signifie "aucun filtre de classe actif" (tous les personnages passent),
  /// pas "aucune classe autorisée" — comportement volontairement permissif
  /// par défaut, cohérent avec un filtre jamais encore ouvert par le joueur.
  /// Un personnage sans classe enregistrée ([CharacterSummary.className]
  /// `null`) ne correspond jamais à un filtre de classe non vide.
  static List<CharacterSummary> apply({
    required List<CharacterSummary> characters,
    required String query,
    required Set<String> classNames,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return characters.where((character) {
      if (normalizedQuery.isNotEmpty &&
          !character.name.toLowerCase().contains(normalizedQuery)) {
        return false;
      }
      if (classNames.isNotEmpty &&
          !classNames.contains(character.className)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Classes distinctes présentes parmi [characters], triées alphabétiquement
  /// — alimente la sheet de filtre (`widgets/character_class_filter_sheet.dart`).
  /// Un personnage sans classe enregistrée n'apparaît dans aucune entrée.
  static List<String> distinctClassNames(List<CharacterSummary> characters) {
    final names = <String>{
      for (final character in characters)
        if (character.className != null) character.className!,
    }.toList();
    names.sort();
    return names;
  }
}
