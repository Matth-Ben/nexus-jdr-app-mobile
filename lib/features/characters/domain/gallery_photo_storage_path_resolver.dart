/// Résout le chemin de stockage Supabase (`{owner_id}/{character_id}/...`)
/// depuis l'URL publique renvoyée par
/// `SupabaseClient.storage.from(...).getPublicUrl(...)`, pour pouvoir
/// supprimer le fichier correspondant (`presentation` flux "Retirer cette
/// photo" → `CharacterRepository.removeGalleryPhoto`).
///
/// Duplique volontairement `domain/portrait_storage_path_resolver.dart`
/// (même algorithme, bucket différent) — même précédent de duplication
/// systématique que le reste de ce dépôt : ce bucket porte plusieurs
/// fichiers par personnage (jamais un remplacement d'un fichier unique comme
/// le portrait), voir la migration
/// `20260909160000_create_character_photos.sql` du dépôt web pour le
/// rationale d'un bucket dédié.
abstract final class GalleryPhotoStoragePathResolver {
  static const String bucket = 'character-gallery-photos';

  /// Chemin de stockage dans [bucket] (ex. `'abc/def/123456.png'`), `null`
  /// si [publicUrl] ne correspond pas au format attendu.
  static String? resolve(String publicUrl) {
    final marker = '/object/public/$bucket/';
    final index = publicUrl.indexOf(marker);
    if (index == -1) return null;
    final path = publicUrl.substring(index + marker.length);
    return path.isEmpty ? null : path;
  }
}
