// Test de non-régression dédié à `offlineNotPersistedMessage` (dette
// technique D88, registre `docs/dette-technique.md`) : avant son extraction
// dans `widgets/character_write_feedback.dart`, ce texte était dupliqué à
// l'identique, `private`, dans `character_detail_screen.dart`,
// `character_list_screen.dart` et `character_card_action_sheet.dart`, sans
// lien au compilateur entre les 3 copies. Les tests de widget de ces 3
// fichiers couvrent déjà, chacun de son côté, l'affichage de ce message, mais
// à des degrés de précision différents : seul
// `character_detail_screen_test.dart` vérifie le texte exact
// (`find.text(...)`) ; `character_list_screen_test.dart` et
// `character_card_action_sheet_test.dart` ne vérifient qu'une sous-chaîne
// (`find.textContaining("n'a pas pu être enregistrée")`), pas le texte
// intégral. Ce fichier comble cet écart au niveau unitaire, indépendamment de
// tout écran : il fige la valeur exacte et complète de la constante
// partagée, pour qu'elle ne puisse plus changer silencieusement sans faire
// échouer au moins un test.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_write_feedback.dart';

void main() {
  test('offlineNotPersistedMessage conserve son texte exact, identique à celui '
      'historiquement dupliqué dans les 3 fichiers appelants', () {
    expect(
      offlineNotPersistedMessage,
      "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
      'fois reconnecté.',
    );
  });
}
