import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_note.freezed.dart';

/// Carnet de notes personnel d'un membre pour un groupe (`group_notes`) —
/// onglet "Notes" de l'écran "Groupe" (`presentation/group_screen.dart`).
/// Personnel (décision utilisateur du 16/09/2026) : chaque membre ne lit/
/// écrit que sa propre note, jamais celle d'un coéquipier — contrairement à
/// `GroupTreasure`, partagé par tout le groupe.
@freezed
abstract class GroupNote with _$GroupNote {
  const factory GroupNote({
    required String groupId,
    required String characterId,
    @Default('') String body,
  }) = _GroupNote;
}
