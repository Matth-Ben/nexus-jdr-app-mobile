import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Exécuté automatiquement par `flutter test` avant chaque fichier de test
/// de ce dossier (convention `flutter_test_config.dart`).
///
/// Désactive le chargement réseau à la volée de `google_fonts` (voir
/// `core/theme/app_typography.dart`) pendant les tests : sans ça, chaque
/// test de widget touchant un texte stylé tenterait un vrai appel réseau
/// vers Google Fonts, ce qui est lent et non déterministe (échoue
/// silencieusement en environnement sans réseau, ce qui est le cas ici,
/// mais autant l'assumer explicitement plutôt que d'en dépendre).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
