import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'package_info_provider.g.dart';

/// Informations de version de l'app (`pubspec.yaml` : `version:`), lues au
/// runtime via `package_info_plus` — pied de page de l'écran "Profil"
/// (`presentation/profile_screen.dart`), format "Nexus JDR — Personnages ·
/// vX.Y.Z" (voir la spec direction-artistique de la tâche : version seule,
/// sans le suffixe `+N` de build number, `PackageInfo.buildNumber` n'est donc
/// jamais lu ici).
///
/// `keepAlive` : même rationale que `supabaseClientProvider`/
/// `connectivityCheckerProvider` — une info figée pour toute la session,
/// jamais recréée par écran. `PackageInfo.fromPlatform()` lit un canal de
/// plateforme natif : dans `flutter test`, surcharger ce provider (ou
/// appeler `PackageInfo.setMockInitialValues` avant le `pumpWidget`, voir
/// `test/features/profile/presentation/profile_screen_test.dart`) plutôt que
/// de le laisser échouer.
@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();
