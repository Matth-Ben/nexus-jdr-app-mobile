import 'dart:io';

/// URLs de fiche store (Play Store/App Store) de l'app — `app_versions`
/// (`data/app_version_repository.dart`) ne porte que des numéros de version,
/// jamais d'URL ; celles-ci sont donc construites ici à partir de
/// l'identifiant d'application déjà connu du dépôt, jamais codé en dur
/// ailleurs ni deviné.
///
/// **Écart signalé par rapport à la tâche d'origine** : celle-ci mentionnait
/// `app.nexusjdr.personnages` comme identifiant déjà connu — l'identifiant
/// réel de ce dépôt (vérifié dans `android/app/build.gradle`,
/// `applicationId`, et `ios/Runner.xcodeproj/project.pbxproj`,
/// `PRODUCT_BUNDLE_IDENTIFIER`) est `com.nexusjdr.personnages`. C'est cette
/// valeur, celle effectivement utilisée par les builds natifs, qui est
/// utilisée ici plutôt que celle mentionnée dans la tâche.
///
/// Depuis le 2026-09-25, l'`applicationId` Android est `com.nexus_jdr` (nom
/// de package de la fiche Google Play, figé côté Google) : Android et iOS
/// n'ont donc plus le même identifiant.
abstract final class AppStoreUrls {
  static const String _androidApplicationId = 'com.nexus_jdr';
  static const String _iosBundleId = 'com.nexusjdr.personnages';

  /// Fiche Play Store — format canonique
  /// `https://play.google.com/store/apps/details?id=<applicationId>`,
  /// résolvable dès la publication de l'app (voir
  /// `project_cicd_and_publishing_status.md` : release Android déjà
  /// opérationnelle). Utilise toujours l'identifiant de production, jamais
  /// les variantes `.dev`/`.staging` (`applicationIdSuffix`,
  /// `android/app/build.gradle`) : la mise à jour proposée à l'utilisateur
  /// doit toujours pointer vers la fiche publique de l'app, jamais vers un
  /// identifiant qui n'existe pas sur le store.
  static Uri playStore() => Uri.parse(
    'https://play.google.com/store/apps/details?id=$_androidApplicationId',
  );

  /// Fiche App Store — **approximation documentée** : contrairement au Play
  /// Store, l'App Store n'expose aucune URL canonique construite à partir du
  /// seul identifiant de bundle (`apps.apple.com` attend un identifiant
  /// numérique `idXXXXXXXXX`, connu seulement une fois l'app publiée sur le
  /// compte Apple Developer — en attente, voir
  /// `project_cicd_and_publishing_status.md`). En l'absence de cet
  /// identifiant, cette URL reste construite à partir du seul identifiant
  /// d'application connu plutôt que d'inventer un identifiant numérique
  /// fictif ; elle n'ouvrira pas la bonne fiche tant que l'app n'est pas
  /// publiée. `openAppStorePage` (`presentation/app_store_launcher.dart`)
  /// reste défensif (`canLaunchUrl`/`try`-`catch`) : cette approximation ne
  /// provoque jamais de crash, seulement un message d'erreur si l'ouverture
  /// échoue. À remplacer par l'URL `id`-préfixée dès la première publication
  /// iOS.
  static Uri appStore() =>
      Uri.parse('https://apps.apple.com/app/$_iosBundleId');

  /// URL de la fiche store de la plateforme courante — `Platform.isIOS`,
  /// même discipline que `AppVersionRepository._platformLabel`.
  static Uri current() => Platform.isIOS ? appStore() : playStore();
}
