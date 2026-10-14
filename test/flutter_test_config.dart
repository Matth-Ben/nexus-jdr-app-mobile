import 'dart:async';

/// Exécuté automatiquement par `flutter test` avant chaque fichier de test
/// de ce dossier (convention `flutter_test_config.dart`).
///
/// Ne fait plus rien depuis l'embarquement des polices en asset (dette D22,
/// `docs/dette-technique.md`) : ce fichier ne servait qu'à désactiver le
/// téléchargement réseau à la volée du package `google_fonts` (retiré de
/// `pubspec.yaml`) pendant les tests. `core/theme/app_typography.dart`
/// référence désormais directement les familles `PressStart2P`/`WorkSans`
/// déclarées dans `pubspec.yaml`, sans appel réseau possible. Conservé
/// (plutôt que supprimé) comme point d'extension si une configuration de
/// test globale redevient nécessaire.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
