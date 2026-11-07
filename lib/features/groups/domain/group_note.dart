import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_note.freezed.dart';

/// Carnet de notes personnel d'un membre pour un groupe (`group_notes`) —
/// onglet "Notes" de l'écran "Groupe" (`presentation/group_screen.dart`).
/// Personnel (décision utilisateur du 16/09/2026) : chaque membre ne lit/
/// écrit que sa propre note, jamais celle d'un coéquipier — contrairement à
/// `GroupTreasure`, partagé par tout le groupe.
///
/// [characterId] est purement informatif depuis la migration web
/// `20261106090000_group_notes_user_id_pk_and_character_set_null.sql` : la
/// clé primaire de `group_notes` est désormais `(group_id, user_id)`, jamais
/// `character_id` (qui passe en `on delete set null`). `null` pour un MJ
/// sans personnage (voir `GroupMember.isGameMaster`), qui a maintenant accès
/// à ce carnet comme n'importe quel membre (décision du comité de revue
/// F02(a), `docs/retours-utilisateurs.md`).
@freezed
abstract class GroupNote with _$GroupNote {
  const factory GroupNote({
    required String groupId,
    String? characterId,
    @Default('') String body,
  }) = _GroupNote;
}
