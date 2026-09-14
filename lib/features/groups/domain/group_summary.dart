import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_summary.freezed.dart';

/// Résumé léger d'un groupe dont le joueur connecté est membre — utilisé par
/// le bouton "groupes" de `character_list_screen.dart` (0/1/2+ groupes) et la
/// sheet listant les groupes (2+ cas).
@freezed
abstract class GroupSummary with _$GroupSummary {
  const factory GroupSummary({
    required String id,
    required String name,
    required int memberCount,
    // Identifiant du créateur (`groups.owner_id`) — utilisé par
    // `group_list_screen.dart` pour afficher le badge "TOI" à côté du nom
    // du groupe fondé par le joueur connecté (comparé à
    // `currentUserProvider`).
    required String founderId,
  }) = _GroupSummary;
}
