/// Statut d'un personnage pour le filtre "Statut" de la liste des
/// personnages (icône entonnoir, `presentation/character_list_screen.dart`)
/// — demande utilisateur du 16/09/2026, hors cahier des charges.
///
/// [alive] et [archived]/[dead] ne sont PAS une partition stricte : un
/// personnage peut être à la fois archivé ET mort (les deux flags
/// `CharacterSummary.isArchived`/`isDead` sont indépendants, voir
/// `character_card.dart`, qui affiche alors les deux badges). Voir
/// `CharacterListFilter.statusesOf` pour la résolution exacte.
enum CharacterStatusFilter {
  alive(label: 'Vivants'),
  archived(label: 'Archivé'),
  dead(label: 'Mort');

  const CharacterStatusFilter({required this.label});

  final String label;
}
