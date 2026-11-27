import '../../../core/utils/uuid_v4.dart';
import 'group_treasure_item.dart';

/// Résultat d'une attribution calculée par [GroupTreasureItems.claim] : le
/// tableau `items` à écrire et l'entrée attribuée (avec la quantité prise).
class GroupTreasureClaim {
  const GroupTreasureClaim({required this.items, required this.claimed});

  final List<GroupTreasureItem> items;

  /// L'entrée attribuée, [GroupTreasureItem.quantity] = quantité prise.
  final GroupTreasureItem claimed;
}

/// Règles pures d'édition du tableau `group_treasure.items` (décision 91) :
/// identifiant stable, fusion des ajouts, et **garde de concurrence**.
///
/// Toute écriture part du tableau **relu juste avant d'écrire** (voir
/// `GroupRepository`) et de l'entrée telle que le joueur l'a vue
/// (`expected`) : si elle a disparu ou changé entre-temps (autre membre qui
/// l'a modifiée, attribuée ou retirée), les fonctions renvoient `null` et
/// l'appelant n'écrit rien (message, puis rechargement).
abstract final class GroupTreasureItems {
  /// Donne un `entry_id` à chaque entrée qui n'en a pas (entrées anciennes,
  /// à la première écriture du tableau). [newId] n'est injecté que par les
  /// tests.
  static List<GroupTreasureItem> withEntryIds(
    List<GroupTreasureItem> items, {
    String Function()? newId,
  }) {
    final generate = newId ?? generateUuidV4;
    return [
      for (final item in items)
        item.entryId == null ? item.copyWith(entryId: generate()) : item,
    ];
  }

  /// Position de [expected] dans [items] s'il n'a **pas changé**, sinon -1.
  /// Recherche par `entry_id` ; une entrée ancienne (sans `entry_id`) n'est
  /// retrouvée que si une entrée sans `entry_id` lui est strictement égale
  /// (dès qu'un membre a réécrit le tableau, toutes les entrées ont un
  /// `entry_id` : l'ancienne vue est alors périmée).
  static int indexOfUnchanged(
    List<GroupTreasureItem> items,
    GroupTreasureItem expected,
  ) {
    final id = expected.entryId;
    final index = id != null
        ? items.indexWhere((item) => item.entryId == id)
        : items.indexWhere((item) => item.entryId == null && item == expected);
    if (index == -1 || items[index] != expected) return -1;
    return index;
  }

  /// Ajoute [additions] à [items] : un objet du catalogue déjà présent voit sa
  /// quantité augmentée (même `item_id`), comme un objet personnalisé au
  /// contenu strictement identique ; sinon une nouvelle entrée est créée.
  /// Toutes les entrées du résultat ont un `entry_id`.
  static List<GroupTreasureItem> merge(
    List<GroupTreasureItem> items,
    List<GroupTreasureItem> additions, {
    String Function()? newId,
  }) {
    final generate = newId ?? generateUuidV4;
    final result = withEntryIds(items, newId: generate);
    for (final addition in additions) {
      if (addition.quantity <= 0) continue;
      final index = result.indexWhere(
        (existing) => addition.isCustom
            ? existing.isCustom && existing.sameContentAs(addition)
            : !existing.isCustom && existing.itemId == addition.itemId,
      );
      if (index == -1) {
        result.add(addition.copyWith(entryId: generate()));
        continue;
      }
      final existing = result[index];
      result[index] = addition.isCustom
          ? existing.copyWith(quantity: existing.quantity + addition.quantity)
          // Entrée ancienne du même objet : l'instantané du catalogue
          // (catégorie, poids) de l'ajout la complète.
          : GroupTreasureItem(
              entryId: existing.entryId,
              itemId: existing.itemId,
              displayName: existing.displayName,
              quantity: existing.quantity + addition.quantity,
              category: existing.category ?? addition.category,
              weight: existing.weight ?? addition.weight,
              extra: existing.extra,
            );
    }
    return result;
  }

  /// Remplace [expected] par [updated] (même `entry_id`) ; `null` si
  /// [expected] a disparu ou changé.
  static List<GroupTreasureItem>? replace(
    List<GroupTreasureItem> items,
    GroupTreasureItem expected,
    GroupTreasureItem updated, {
    String Function()? newId,
  }) {
    final index = indexOfUnchanged(items, expected);
    if (index == -1) return null;
    final result = withEntryIds(items, newId: newId);
    result[index] = updated.copyWith(entryId: result[index].entryId);
    return result;
  }

  /// Retire [expected] (tous ses exemplaires) ; `null` s'il a disparu ou
  /// changé.
  static List<GroupTreasureItem>? remove(
    List<GroupTreasureItem> items,
    GroupTreasureItem expected, {
    String Function()? newId,
  }) {
    final index = indexOfUnchanged(items, expected);
    if (index == -1) return null;
    return withEntryIds(items, newId: newId)..removeAt(index);
  }

  /// Prend [quantity] exemplaires de [expected] (l'entrée disparaît à 0) ;
  /// `null` si [expected] a disparu ou changé, ou si [quantity] n'est pas
  /// dans `1..expected.quantity`.
  static GroupTreasureClaim? claim(
    List<GroupTreasureItem> items,
    GroupTreasureItem expected,
    int quantity, {
    String Function()? newId,
  }) {
    final index = indexOfUnchanged(items, expected);
    if (index == -1 || quantity < 1 || quantity > expected.quantity) {
      return null;
    }
    final result = withEntryIds(items, newId: newId);
    final remaining = expected.quantity - quantity;
    if (remaining <= 0) {
      result.removeAt(index);
    } else {
      result[index] = result[index].copyWith(quantity: remaining);
    }
    return GroupTreasureClaim(
      items: result,
      claimed: expected.copyWith(quantity: quantity),
    );
  }
}
