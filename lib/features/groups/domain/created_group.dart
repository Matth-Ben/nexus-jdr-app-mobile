import 'package:freezed_annotation/freezed_annotation.dart';

part 'created_group.freezed.dart';

/// Résultat de `create-group` (écran "Créer un groupe") — `{id, name,
/// invite_code}`.
@freezed
abstract class CreatedGroup with _$CreatedGroup {
  const factory CreatedGroup({
    required String id,
    required String name,
    required String inviteCode,
  }) = _CreatedGroup;
}
