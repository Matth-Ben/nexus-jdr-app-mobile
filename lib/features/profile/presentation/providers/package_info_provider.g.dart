// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

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

final class PackageInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PackageInfo>,
          PackageInfo,
          FutureOr<PackageInfo>
        >
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
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
  PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return packageInfo(ref);
  }
}

String _$packageInfoHash() => r'854bbb0e381edfdddbd736229351d6cc918a2ad1';
