/// Libellé FR de `items.rarity` — panneau "Infos" d'un objet
/// (`presentation/widgets/item_info_panel.dart`), ligne "Rareté", affichée
/// uniquement quand `rarity != null`.
///
/// Aucune valeur n'est peuplée dans le contenu actuel (`items.rarity` est
/// une colonne sans contrainte `CHECK` côté base, jamais renseignée par les
/// migrations de seed vérifiées — ni Phase 1 ni Phase 5, aucun `items` de
/// catégorie 'objet_magique' n'existe encore) : ce mapping est donc du code
/// mort en pratique pour l'instant, préparé par avance pour un futur
/// peuplement d'objets magiques plutôt que deviné au moment de leur ajout.
/// Valeurs choisies par convention avec le reste du schéma (snake_case sans
/// accent, même style que `armor_properties.ac_dex_bonus` ou
/// `items.category`) — à ajuster si le peuplement réel des objets magiques
/// utilise une autre convention.
abstract final class InventoryRarityFormatter {
  static const Map<String, String> _labels = {
    'commune': 'Commune',
    'peu_commune': 'Peu commune',
    'rare': 'Rare',
    'tres_rare': 'Très rare',
    'legendaire': 'Légendaire',
    'artefact': 'Artefact',
  };

  /// Une valeur non reconnue retombe sur elle-même (capitalisée si possible)
  /// plutôt que sur un libellé générique — préférable pour ne jamais
  /// masquer silencieusement une vraie valeur de rareté pas encore couverte
  /// par [_labels].
  static String format(String rarity) {
    final label = _labels[rarity];
    if (label != null) return label;
    if (rarity.isEmpty) return rarity;
    return rarity[0].toUpperCase() + rarity.substring(1);
  }
}
