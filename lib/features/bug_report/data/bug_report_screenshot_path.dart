import 'dart:math';

/// Bucket privé des captures jointes aux signalements (migration du dépôt
/// web `20261027090000_bug_reports_content_severity_and_screenshot.sql`).
const String bugReportScreenshotBucket = 'bug-report-screenshots';

/// Chemin de téléversement d'une capture, tel qu'attendu à la fois par la
/// politique RLS d'insertion du bucket et par `report-bug`
/// (`screenshotPath`) : `<auth.uid() en minuscules>/<fileId>.jpg` — un seul
/// niveau de dossier, sans nom de bucket ni `/` initial.
String buildBugReportScreenshotPath({
  required String userId,
  required String fileId,
}) => '${userId.toLowerCase()}/$fileId.jpg';

/// UUID v4 aléatoire (RFC 9562), en minuscules — nom de fichier de la
/// capture, conforme à la contrainte du contrat (1-128 caractères
/// `[A-Za-z0-9._-]`, pas de `.` en tête). Écrit ici plutôt que via
/// `package:uuid` (non déclaré dans ce dépôt) : seize octets aléatoires
/// suffisent. [random] n'est injecté que par les tests.
String generateBugReportScreenshotId([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
