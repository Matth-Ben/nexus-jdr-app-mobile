import 'dart:io';
import 'dart:typed_data';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/bug_report_failure.dart';
import 'bug_report_error_mapper.dart';
import 'bug_report_screenshot_path.dart';

/// Passerelle vers l'edge function Supabase `report-bug` — déjà déployée côté
/// dépôt web (migration `bug_reports` + RLS, jamais modifiées depuis ce
/// dépôt). Voir `presentation/widgets/report_bug_sheet.dart` (dépôt
/// `features/profile/`, seul point d'entrée pour l'instant) pour l'écran
/// appelant.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client` — même principe que `CharacterRepository`/
/// `StoryInviteRepository`.
abstract class BugReportRepository {
  /// Envoie un signalement au support. [severity] porte une des 4 valeurs
  /// techniques du contrat serveur (`mineur`/`majeur`/`bloquant`/`contenu`,
  /// voir `report_bug_sheet.dart`), jamais un libellé déjà traduit.
  ///
  /// [screenshotJpeg], facultatif, est une capture déjà préparée (JPEG, au
  /// plus 5 Mio — voir `BugReportScreenshotPicker.prepare`) : elle est
  /// d'abord téléversée dans le bucket privé `bug-report-screenshots`, puis
  /// son chemin est transmis à `report-bug` (`screenshotPath`). Si ce
  /// téléversement échoue, `report-bug` n'est jamais appelé (pas de
  /// signalement sans sa capture, décision produit).
  ///
  /// Un code HTTP 200 est un succès utilisateur quel que soit le `status`
  /// métier renvoyé dans le corps (`"synced"`/`"failed"` — ce dernier
  /// signale un problème de synchronisation GitHub côté serveur, transparent
  /// pour l'app, jamais inspecté ici) : cette méthode retourne normalement
  /// dans les deux cas. Lève une [BugReportFailure] pour tout le reste —
  /// [BugReportFailureKind.screenshotUpload] pour un échec de téléversement
  /// ou `screenshot_not_found`, [BugReportFailureKind.generic] sinon.
  Future<void> submitReport({
    required String title,
    required String description,
    required String severity,
    String? characterId,
    Uint8List? screenshotJpeg,
  });
}

class SupabaseBugReportRepository implements BugReportRepository {
  SupabaseBugReportRepository(this._client, {String Function()? generateId})
    : _generateId = generateId ?? generateBugReportScreenshotId;

  final SupabaseClient _client;
  final String Function() _generateId;

  @override
  Future<void> submitReport({
    required String title,
    required String description,
    required String severity,
    String? characterId,
    Uint8List? screenshotJpeg,
  }) async {
    final screenshotPath = screenshotJpeg == null
        ? null
        : await _uploadScreenshot(screenshotJpeg);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await _client.functions.invoke(
        'report-bug',
        body: {
          'title': title,
          'description': description,
          'severity': severity,
          'appVersion': packageInfo.version,
          'platform': _platformLabel(),
          'characterId': ?characterId,
          'screenshotPath': ?screenshotPath,
        },
      );
    } on FunctionException catch (error) {
      throw mapBugReportError(error);
    } on BugReportFailure {
      rethrow;
    } catch (_) {
      throw const BugReportFailure(genericBugReportErrorMessage);
    }
  }

  /// Téléverse [bytes] et retourne le chemin à transmettre à `report-bug`.
  /// Nouveau nom de fichier à chaque appel, sans `upsert` (le bucket
  /// n'accorde aucun droit SELECT/UPDATE au client) : un nouvel essai après
  /// un échec de `report-bug` téléverse un nouvel objet, l'ancien restant
  /// orphelin (accepté, le client ne peut pas le supprimer).
  Future<String> _uploadScreenshot(Uint8List bytes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      // Pas de session : `report-bug` répondrait de toute façon 401.
      throw const BugReportFailure(genericBugReportErrorMessage);
    }
    final path = buildBugReportScreenshotPath(
      userId: userId,
      fileId: _generateId(),
    );
    try {
      await _client.storage
          .from(bugReportScreenshotBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    } catch (error) {
      throw mapBugReportScreenshotUploadError(error);
    }
    return path;
  }

  /// `appVersion`/`platform` du contrat `report-bug` : lus ici plutôt que
  /// reçus en paramètre (spec de la tâche, "aucun champ visible ... injectés
  /// silencieusement") — `PackageInfo.fromPlatform()` (même appel que
  /// `package_info_provider.dart`) et `Platform.isAndroid`/`isIOS`, jamais
  /// codés en dur.
  String _platformLabel() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem;
  }
}
