/// Les 2 onglets de l'écran "Groupe" — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.
///
/// Ne porte plus qu'un libellé (`label`) depuis le recettage
/// direction-artistique du 13/09 : la navigation entre onglets est
/// désormais assurée par `SegmentedTabBar<GroupTab>`
/// (`core/widgets/segmented_tab_bar.dart`), un simple soulignement sous un
/// libellé texte, sans icône ni titre de bandeau variable — `icon` et
/// `headerTitle` (portés par l'ancien `GroupTabBar` à icônes, retiré) n'ont
/// donc plus de raison d'être : le header de `group_screen.dart` affiche
/// désormais le nom du groupe, jamais un titre dépendant de l'onglet actif.
enum GroupTab {
  members(label: 'Membres'),
  treasure(label: 'Butin');

  const GroupTab({required this.label});

  final String label;
}
