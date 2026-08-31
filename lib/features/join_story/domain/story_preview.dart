import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_preview.freezed.dart';

/// Aperçu d'une histoire résolu par `preview-story-invite` (étape 2/4 du
/// flux "Rejoindre une histoire", `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 7.1) — avant tout engagement, aucun rattachement créé côté
/// serveur à ce stade.
///
/// Volontairement minimal (pas de nom de MJ) : décision produit actée par le
/// chef de projet, voir la consigne de la tâche — aucune notion de profil
/// utilisateur n'existe dans le schéma web actuel.
@freezed
abstract class StoryPreview with _$StoryPreview {
  const factory StoryPreview({
    required String title,

    /// URL publique déjà résolue (bucket Storage `story-covers`, lecture
    /// publique) — jamais le chemin de stockage brut renvoyé par l'edge
    /// function (`cover_image_path`), résolu côté dépôt
    /// (`data/story_invite_repository.dart`), même principe que
    /// `characters.portrait_url`.
    String? coverUrl,
  }) = _StoryPreview;
}
