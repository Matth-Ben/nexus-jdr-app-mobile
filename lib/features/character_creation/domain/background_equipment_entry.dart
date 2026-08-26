import 'package:freezed_annotation/freezed_annotation.dart';

part 'background_equipment_entry.freezed.dart';

/// Une ligne d'équipement d'historique déjà résolue, affichée par l'onglet
/// "Historique" de l'étape 7/9 "Équipement de départ"
/// (`presentation/equipment_step_screen.dart`) — voir
/// `domain/background_equipment_resolver.dart` pour la résolution qui produit
/// ces entrées à partir de `BackgroundOption.equipment` (chaînes de texte
/// libre) et d'un [ItemCatalog].
///
/// [itemId]/[category] restent `null` pour un objet non résolu (chaîne de
/// `backgrounds.equipment` sans correspondance exacte dans `items`, via son
/// nom traduit) : la carte garde exactement le même chrome (structure,
/// bordures, pas de badge ni de case à cocher) qu'un objet résolu, et
/// [category] `null` retombe sur un libellé/icône **génériques neutres**
/// ("Équipement"/`Icons.inventory_2`, voir `domain/equipment_category_rules.dart`)
/// plutôt que sur un texte qui révélerait l'échec de résolution (ex. "Non
/// répertorié", corrigé après une régression trouvée par `qa-testeur`) :
/// rien à l'écran ne doit permettre au joueur de deviner qu'un objet précis
/// de son historique n'a pas matché la base — décision du chef de projet,
/// voir la consigne d'origine.
@freezed
abstract class BackgroundEquipmentEntry with _$BackgroundEquipmentEntry {
  const factory BackgroundEquipmentEntry({
    int? itemId,

    /// Nom affiché : le nom résolu si [itemId] n'est pas `null`, sinon la
    /// chaîne brute de `backgrounds.equipment` telle quelle (texte libre).
    required String name,
    String? category,
  }) = _BackgroundEquipmentEntry;
}
