import 'package:freezed_annotation/freezed_annotation.dart';

part 'join_story_result.freezed.dart';

/// Résultat d'un rattachement réussi (`join-story`, étape 4/4 du flux
/// "Rejoindre une histoire") — [characterId] est celui déjà connu de
/// l'appelant (transmis à `join-story`, pas renvoyé par la réponse), porté
/// ici pour que `presentation/join_character_step_screen.dart` n'ait pas à le
/// recapturer séparément avant de naviguer vers `/characters/{characterId}`.
@freezed
abstract class JoinStoryResult with _$JoinStoryResult {
  const factory JoinStoryResult({
    required String characterCampaignId,
    required String joinedAt,
    required String characterId,
    required String storyId,
    required String storyTitle,
    String? storyCoverUrl,
  }) = _JoinStoryResult;
}
