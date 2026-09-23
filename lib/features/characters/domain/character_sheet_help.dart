import '../../character_creation/domain/creation_step_help.dart';

/// Explications de la fiche personnage, affichées par le bouton ⓘ placé à
/// côté de "Partager" dans l'en-tête de l'onglet "Personnage" (demande
/// utilisateur, 2026-09-24) — même format et même ton (tutoiement) que
/// [CreationStepHelp], réutilise son panneau `showStepHelpSheet`.
abstract final class CharacterSheetHelp {
  static const personnage = StepHelpContent(
    title: 'La fiche personnage',
    body:
        'VITESSE : distance que ton personnage parcourt en un tour.\n'
        "CA (classe d'armure) : le score qu'un ennemi doit atteindre pour "
        'te toucher, calculé depuis ton armure, ton bouclier et ta '
        'Dextérité.\n'
        'INIT. (initiative) : ton bonus au jet qui fixe l\'ordre de jeu '
        'en combat — touche la tuile pour le lancer.\n'
        'INSPIRATION : accordée par le MJ, touche la tuile pour '
        "l'activer ou la dépenser.\n\n"
        'Points de vie : utilise les boutons de la carte pour encaisser '
        'des dégâts, te soigner ou prendre un repos.\n\n'
        'Caractéristiques (FOR, DEX, CON, INT, SAG, CHA) : score et '
        'modificateur — touche une tuile pour lancer un jet.\n\n'
        'Onglets du bas : Aptitudes, Sorts, Sac et Histoire regroupent '
        'le reste de ta fiche ; dans les listes, touche un élément pour '
        'voir son détail.\n\n'
        'Partager (icône lien) : crée un lien de lecture seule vers cette '
        'fiche, par exemple pour ton MJ. Le menu ⋮ permet d\'exporter en '
        'XML, archiver ou supprimer le personnage.',
  );
}
