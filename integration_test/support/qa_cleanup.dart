import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Vérifie que [characterName] est bien un nom de personnage de test
/// (préfixe `QA-`) et le renvoie, sinon lève un [StateError].
///
/// Vrai contrôle à l'exécution, pas un `assert` : un `assert` n'existe pas en
/// mode profile/release, et ce helper est exporté. Séparé de
/// [registerQaCharacterCleanup] pour pouvoir être testé sans Supabase.
String requireQaCharacterName(String characterName) {
  if (!characterName.startsWith('QA-')) {
    throw StateError(
      'Nettoyage refusé : "$characterName" ne commence pas par "QA-".',
    );
  }
  return characterName;
}

/// Enregistre, dans un `addTearDown`, la suppression du personnage de test
/// [characterName] : exécutée MÊME si le scénario échoue ou lève une
/// exception en cours de route (modèle de la PR #255, V3-3 de
/// `docs/retours-utilisateurs.md`).
///
/// À appeler **juste après** la génération du nom
/// (`qaUniqueCharacterName`) et **avant** toute étape qui peut créer le
/// personnage (assistant de création, bouton « CRÉER LE PERSONNAGE ») : un
/// nettoyage enregistré après la création ne s'exécuterait jamais si cette
/// création, ou une étape précédente, échouait.
///
/// Garde-fous :
/// - le nom doit commencer par `QA-` ([requireQaCharacterName], [StateError]
///   levée tout de suite, avant l'enregistrement) : jamais un personnage
///   réel (Magnus, personnage personnel...) ;
/// - aucun utilisateur connecté : rien n'est supprimé (journalisé) ;
/// - la suppression se fait par nom EXACT (horodaté, donc unique à ce test)
///   ET `owner_id` = utilisateur connecté (filtre défensif en plus de la
///   RLS `auth.uid() = owner_id`) ;
/// - idempotente : sans effet si le personnage n'existe pas (création jamais
///   atteinte) ou n'existe plus ; le nombre de lignes supprimées est
///   journalisé ;
/// - n'échoue jamais (une erreur réseau, ou un `Supabase` non initialisé
///   parce que l'appli n'a pas démarré, est seulement journalisée) : un
///   nettoyage qui plante ne doit pas masquer l'échec réel du scénario.
void registerQaCharacterCleanup(String characterName) {
  requireQaCharacterName(characterName);
  addTearDown(() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        // ignore: avoid_print
        print(
          'CLEANUP: aucun utilisateur connecté, "$characterName" '
          'non supprimé.',
        );
        return;
      }
      final deleted = await client
          .from('characters')
          .delete()
          .eq('name', characterName)
          .eq('owner_id', userId)
          .select('id');
      // ignore: avoid_print
      print(
        'CLEANUP: ${deleted.length} ligne(s) supprimée(s) pour '
        '"$characterName".',
      );
    } on Object catch (error) {
      // ignore: avoid_print
      print('CLEANUP: échec de la suppression de "$characterName" : $error');
    }
  });
}
