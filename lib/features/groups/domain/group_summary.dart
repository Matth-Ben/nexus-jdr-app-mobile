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
    // Agrégats de statut vital des membres du groupe (vue
    // `group_character_status_overview`, voir
    // `GroupRepository.fetchMyGroups`) — consommés par
    // `group_list_screen.dart::GroupStatusBadge` pour afficher un badge
    // priorisé ("X mort(s)" prioritaire sur "X PV bas") sur `_GroupRow`,
    // sans jamais dupliquer la jauge PV individuelle déjà affichée par
    // `group_members_tab_body.dart`. `@Default(0)` plutôt que `required` :
    // évite de casser les constructions existantes de `GroupSummary` qui ne
    // portent pas sur ce chantier (ex. `data_export_repository_test.dart`),
    // même convention que `GroupTreasure.currencyGp`.
    @Default(0) int deadCount,
    // "PV bas" : vivant et `0 < current_hp <= max_hp * 0.25` (voir la vue
    // `group_character_status_overview`, qui applique déjà cette règle
    // côté serveur — ce champ n'est qu'un agrégat déjà calculé, jamais
    // recalculé côté client).
    @Default(0) int lowHpCount,
  }) = _GroupSummary;
}
