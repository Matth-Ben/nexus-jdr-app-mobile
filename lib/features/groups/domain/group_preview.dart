import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_preview.freezed.dart';

/// Aperçu d'un groupe résolu par `preview-group-invite` (étape 2/3 du flux
/// "Rejoindre un groupe") — avant tout engagement, aucune adhésion créée côté
/// serveur à ce stade.
@freezed
abstract class GroupPreview with _$GroupPreview {
  const factory GroupPreview({required String name, required int memberCount}) =
      _GroupPreview;
}
