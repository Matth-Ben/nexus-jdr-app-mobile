import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_treasure_item.dart';

part 'group_treasure.freezed.dart';

/// Butin commun d'un groupe (`group_treasure`) — onglet "Butin" de l'écran
/// "Groupe" (`presentation/group_screen.dart`), section 2.2 de
/// `docs/cahier-des-charges/12-partage-et-groupes.md`.
@freezed
abstract class GroupTreasure with _$GroupTreasure {
  const GroupTreasure._();

  const factory GroupTreasure({
    required String groupId,
    @Default(0) int currencyGp,
    @Default(0) int currencyPp,
    @Default(0) int currencyEp,
    @Default(0) int currencySp,
    @Default(0) int currencyCp,
    @Default(<GroupTreasureItem>[]) List<GroupTreasureItem> items,
  }) = _GroupTreasure;

  /// `true` si toutes les monnaies sont à 0 — désactive le lien "S'attribuer
  /// de la monnaie" (spec visuelle de la tâche).
  bool get hasNoCurrency =>
      currencyGp == 0 &&
      currencyPp == 0 &&
      currencyEp == 0 &&
      currencySp == 0 &&
      currencyCp == 0;
}
