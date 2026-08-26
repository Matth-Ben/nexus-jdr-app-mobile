/// Résout le chemin de stockage Supabase (`{owner_id}/{character_id}/...`)
/// depuis l'URL publique renvoyée par
/// `SupabaseClient.storage.from(...).getPublicUrl(...)`, pour pouvoir
/// supprimer le fichier correspondant (`presentation` flux "Retirer le
/// portrait" → `CharacterRepository.removePortrait`).
///
/// Extrait en fonction pure (testable sans réseau) plutôt qu'inline dans
/// `data/character_repository.dart` : le format d'URL publique Supabase Storage
/// est `{SUPABASE_URL}/storage/v1/object/public/{bucket}/{path}`, un détail
/// d'implémentation qui mérite un test dédié plutôt qu'une confiance
/// aveugle dans un `substring` non vérifié.
abstract final class PortraitStoragePathResolver {
  static const String bucket = 'character-portraits';

  /// Chemin de stockage dans [bucket] (ex. `'abc/def/123456.png'`), `null`
  /// si [publicUrl] ne correspond pas au format attendu (URL externe
  /// saisie manuellement par le joueur via le flux "Utiliser une URL", qui
  /// n'a alors aucun fichier à supprimer côté bucket).
  static String? resolve(String publicUrl) {
    final marker = '/object/public/$bucket/';
    final index = publicUrl.indexOf(marker);
    if (index == -1) return null;
    final path = publicUrl.substring(index + marker.length);
    return path.isEmpty ? null : path;
  }
}
