import 'character_status_filter.dart';
import 'character_summary.dart';

/// Filtre pur de la liste des personnages (recherche par nom + filtre par
/// classe + filtre par statut) — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section 2,
/// "Recherche / filtre dans la liste des personnages", et la maquette "Liste
/// des personnages" (`09-maquettes-captures.md`, barre de recherche + icône
/// filtre). Le filtre par statut (Vivants/Archivé/Mort) est une demande
/// utilisateur du 16/09/2026, hors cahier des charges.
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
  /// [statuses] : ensemble des statuts retenus ; un ensemble vide signifie
  /// "aucun filtre de statut actif" (tous les personnages passent), même
  /// convention permissive que [classNames]. Un personnage passe dès que
  /// [statusesOf] intersecte [statuses] (pas une égalité stricte) : un
  /// personnage mort ET archivé correspond aussi bien à "Archivé" qu'à
  /// "Mort", cochés ensemble ou séparément.
  static List<CharacterSummary> apply({
    required List<CharacterSummary> characters,
    required String query,
    required Set<String> classNames,
    Set<CharacterStatusFilter> statuses = const {},
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return characters
        .where((character) {
          if (normalizedQuery.isNotEmpty &&
              !character.name.toLowerCase().contains(normalizedQuery)) {
            return false;
          }
          if (classNames.isNotEmpty &&
              !classNames.contains(character.className)) {
            return false;
          }
          if (statuses.isNotEmpty &&
              statusesOf(character).intersection(statuses).isEmpty) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  /// Statuts auxquels [character] correspond — voir la doc de classe de
  /// [CharacterStatusFilter] : `{alive}` seul si ni mort ni archivé, sinon
  /// [CharacterStatusFilter.archived]/[CharacterStatusFilter.dead] selon les
  /// flags réellement actifs (les deux si le personnage est à la fois mort
  /// ET archivé).
  static Set<CharacterStatusFilter> statusesOf(CharacterSummary character) {
    if (!character.isDead && !character.isArchived) {
      return const {CharacterStatusFilter.alive};
    }
    return {
      if (character.isArchived) CharacterStatusFilter.archived,
      if (character.isDead) CharacterStatusFilter.dead,
    };
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
