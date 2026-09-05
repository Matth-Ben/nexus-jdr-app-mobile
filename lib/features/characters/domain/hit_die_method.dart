/// Méthode de détermination de la valeur d'un dé de vie dépensé.
///
/// Même principe que l'enum privé `_HpMethod` de
/// `presentation/level_up_screen.dart` (étape "Points de vie" de la montée
/// de niveau), mais public : partagé ici avec la dépense de dés de vie au
/// repos court (`presentation/widgets/rest_sheet.dart`,
/// `domain/hit_dice_spend_calculator.dart`), le second endroit du dépôt à
/// proposer ce même choix "lancer/valeur moyenne" au joueur. `_HpMethod`
/// reste inchangé (hors périmètre de cette tâche) — les deux écrans
/// n'affichent d'ailleurs pas exactement le même libellé pour le segment
/// "lancer" ("Lancer le dé", au singulier, vs "Lancer les dés" ici, un lot
/// pouvant compter plusieurs dés).
enum HitDieMethod { roll, average }
