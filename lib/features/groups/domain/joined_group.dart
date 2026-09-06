import 'package:freezed_annotation/freezed_annotation.dart';

part 'joined_group.freezed.dart';

/// Résultat de `join-group` (étape 3/3 du flux "Rejoindre un groupe") —
/// `{group_id, name}`.
@freezed
abstract class JoinedGroup with _$JoinedGroup {
  const factory JoinedGroup({required String groupId, required String name}) =
      _JoinedGroup;
}
