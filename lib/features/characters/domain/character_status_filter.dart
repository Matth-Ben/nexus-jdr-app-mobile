/// Statut d'un personnage pour le filtre "Statut" de la liste des
/// personnages (icône entonnoir, `presentation/character_list_screen.dart`)
/// — demande utilisateur du 16/09/2026, hors cahier des charges.
///
/// [alive] et [archived]/[dead] ne sont PAS une partition stricte : un
/// personnage peut être à la fois archivé ET mort (les deux flags
/// `CharacterSummary.isArchived`/`isDead` sont indépendants, voir
/// `character_card.dart`, qui affiche alors les deux badges). Voir
/// `CharacterListFilter.statusesOf` pour la résolution exacte.
///
/// Ne porte plus de libellé affichable (`label`, retiré au chantier
/// "traduction de l'app" Phase B, lot "Characters — liste") : ce `domain/`
/// n'a jamais accès à `AppLocalizations`/`BuildContext` — voir
/// `presentation/widgets/character_list_filter_sheet.dart::_statusLabel`,
/// seul appelant de cet enum, pour la résolution localisée du texte.
enum CharacterStatusFilter { alive, archived, dead }
