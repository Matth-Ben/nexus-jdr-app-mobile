/// Une photo de la galerie de l'onglet "Histoire" (`character_photos`) —
/// voir `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Histoire" : "Galerie de photos complémentaires (au-delà du
/// portrait principal)."
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `CharacterSpellEntry`/`CharacterInventoryItem` : donnée en lecture seule
/// affichée telle quelle, aucune égalité structurelle fine nécessaire.
class CharacterGalleryPhoto {
  const CharacterGalleryPhoto({
    required this.id,
    required this.url,
    required this.createdAt,
  });

  /// `character_photos.id` (uuid).
  final String id;

  /// URL publique du fichier (bucket Supabase Storage
  /// `character-gallery-photos`, voir
  /// `domain/gallery_photo_storage_path_resolver.dart` pour la résolution
  /// inverse utilisée à la suppression).
  final String url;

  final DateTime createdAt;
}
