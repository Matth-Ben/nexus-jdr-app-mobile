/// Équipement de départ d'une classe (`classes.starting_equipment`, règles
/// 2024) : plusieurs options exclusives — l'option A donne des objets et un
/// peu d'or, l'option B (C pour le Guerrier) uniquement de l'or.
///
/// Forme jsonb vérifiée en base le 2026-09-30 (migration
/// `20260930210000_classes_starting_equipment.sql`, dépôt web) :
/// `{"options": [{"label": "A", "gold": 9, "items": [{"item": "Cotte de mailles", "quantity": 1}]}]}`.
/// `item` est un nom d'objet FR, résolu contre le catalogue à la création
/// (un nom sans correspondance — paquetage, grimoire — devient une ligne
/// d'inventaire libre).
class ClassEquipmentOption {
  const ClassEquipmentOption({
    required this.label,
    required this.items,
    required this.gold,
  });

  final String label;
  final List<({String name, int quantity})> items;
  final int gold;

  /// « Cotte de mailles, Bouclier, 6 × Javeline + 9 po » ou « 150 po ».
  String get summary {
    final parts = [
      for (final item in items)
        item.quantity > 1 ? '${item.quantity} × ${item.name}' : item.name,
    ];
    if (parts.isEmpty) return '$gold po';
    return '${parts.join(', ')} + $gold po';
  }

  /// Parse la colonne jsonb ; liste vide si absente ou mal formée (cache
  /// de catalogue antérieur à la colonne, par exemple).
  static List<ClassEquipmentOption> parse(Object? raw) {
    if (raw is! Map) return const [];
    final options = raw['options'];
    if (options is! List) return const [];
    return [
      for (final option in options)
        if (option is Map && option['label'] is String)
          ClassEquipmentOption(
            label: option['label'] as String,
            gold: (option['gold'] as num?)?.toInt() ?? 0,
            items: [
              for (final item in (option['items'] as List?) ?? const [])
                if (item is Map && item['item'] is String)
                  (
                    name: item['item'] as String,
                    quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                  ),
            ],
          ),
    ];
  }

  /// Option [label] parmi [options], sinon la première (option A par
  /// défaut), `null` si la classe n'a aucune option.
  static ClassEquipmentOption? select(
    List<ClassEquipmentOption> options,
    String? label,
  ) {
    for (final option in options) {
      if (option.label == label) return option;
    }
    return options.isEmpty ? null : options.first;
  }
}
