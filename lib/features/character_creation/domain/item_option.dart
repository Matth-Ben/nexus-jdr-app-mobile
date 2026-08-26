import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_option.freezed.dart';

/// Un objet du catalogue `items` (`docs/cahier-des-charges/02-modele-donnees.md`),
/// utilisé à l'étape 7/9 "Équipement de départ" de l'assistant de création,
/// à la fois pour résoudre les chaînes de `backgrounds.equipment` (onglet
/// "Historique") et pour peupler le catalogue d'achat libre (onglet
/// "Acheter").
///
/// [category] est une colonne réelle de `items` ('arme'/'armure'/'bouclier'/
/// 'outil'/'equipement_general'/'objet_magique'/'monture_vehicule', vérifié
/// contre le schéma Supabase local) — voir `domain/equipment_category_rules.dart`
/// pour son libellé FR et son icône affichés.
///
/// [costAmount] est le montant de `items.cost` (jsonb `{"amount", "currency"}`)
/// — `currency` toujours `"gp"` pour ce MVP (décision du chef de projet, voir
/// la consigne d'origine), donc pas de champ dédié pour la devise. `double`
/// plutôt que `int` : vérifié contre le contenu peuplé, certains coûts sont
/// fractionnaires (ex. 0.05 gp pour une flèche) — voir
/// `domain/gold_amount_formatter.dart` pour leur affichage.
@freezed
abstract class ItemOption with _$ItemOption {
  const factory ItemOption({
    required int id,
    required String name,
    required String category,
    required double costAmount,
  }) = _ItemOption;
}
