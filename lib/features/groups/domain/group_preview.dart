import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_campaign_label.dart';

part 'group_preview.freezed.dart';

/// Aperçu d'un groupe résolu par `preview-group-invite` (étape 2/3 du flux
/// "Rejoindre un groupe") — avant tout engagement, aucune adhésion créée côté
/// serveur à ce stade.
@freezed
abstract class GroupPreview with _$GroupPreview {
  const GroupPreview._();

  const factory GroupPreview({
    required String name,
    required int memberCount,

    /// Titre de la campagne associée (`story_title`), `null` sans campagne
    /// ou si le serveur ne le renvoie pas. Jamais de résumé dans l'aperçu
    /// (décision n° 33 du 19/11/2026).
    String? storyTitle,
  }) = _GroupPreview;

  /// Titre affiché par la carte d'aperçu : `null` sans campagne ou s'il
  /// répète le nom du groupe (décision n° 36).
  String? get campaignTitle => GroupCampaignLabel.displayedTitle(
    storyTitle: storyTitle,
    groupName: name,
  );
}
