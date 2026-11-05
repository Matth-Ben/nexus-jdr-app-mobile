import '../../../../l10n/app_localizations.dart';

/// Les 3 onglets de l'écran "Groupe" — Membres/Butin voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2 ; Notes
/// (carnet personnel pendant la partie) ajouté le 16/09/2026, demande
/// utilisateur hors cahier des charges.
///
/// Ne porte plus qu'un libellé (`label`) depuis le recettage
/// direction-artistique du 13/09 : la navigation entre onglets est
/// désormais assurée par `SegmentedTabBar<GroupTab>`
/// (`core/widgets/segmented_tab_bar.dart`), un simple soulignement sous un
/// libellé texte, sans icône ni titre de bandeau variable — `icon` et
/// `headerTitle` (portés par l'ancien `GroupTabBar` à icônes, retiré) n'ont
/// donc plus de raison d'être : le header de `group_screen.dart` affiche
/// désormais le nom du groupe, jamais un titre dépendant de l'onglet actif.
///
/// [label] est une méthode (pas un champ `const`, chantier "traduction de
/// l'app" Phase B, lot "Groups — écran principal") — un enum `const` ne peut
/// pas porter de texte résolu via `AppLocalizations.of(context)`, qui a
/// besoin d'un `BuildContext` au moment de l'appel : même pattern que
/// `CharacterDetailTab.label`
/// (`features/characters/presentation/widgets/character_detail_tab_bar.dart`).
enum GroupTab {
  members,
  treasure,
  notes;

  /// Libellé affiché par `SegmentedTabBar` (converti en majuscules à
  /// l'affichage par ce composant, voir sa doc de classe).
  String label(AppLocalizations l10n) => switch (this) {
    GroupTab.members => l10n.groupTabMembersLabel,
    GroupTab.treasure => l10n.groupTabTreasureLabel,
    GroupTab.notes => l10n.groupTabNotesLabel,
  };
}
