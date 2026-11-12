import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
/// - le nom doit commencer par `QA-` (assertion) : jamais un personnage réel
///   (Magnus, personnage personnel...) ;
/// - la suppression se fait par nom EXACT (horodaté, donc unique à ce test)
///   avec la session du compte QA actif : la RLS
///   (`auth.uid() = owner_id`) interdit de toute façon de supprimer le
///   personnage d'un autre compte ;
/// - idempotente : sans effet si le personnage n'existe pas (création jamais
///   atteinte) ou n'existe plus ;
/// - n'échoue jamais (une erreur réseau, ou un `Supabase` non initialisé
///   parce que l'appli n'a pas démarré, est seulement journalisée) : un
///   nettoyage qui plante ne doit pas masquer l'échec réel du scénario.
void registerQaCharacterCleanup(String characterName) {
  assert(
    characterName.startsWith('QA-'),
    'Nettoyage refusé : "$characterName" ne commence pas par "QA-".',
  );
  addTearDown(() async {
    try {
      await Supabase.instance.client
          .from('characters')
          .delete()
          .eq('name', characterName);
    } on Object catch (error) {
      // ignore: avoid_print
      print('CLEANUP: échec de la suppression de "$characterName" : $error');
    }
  });
}
