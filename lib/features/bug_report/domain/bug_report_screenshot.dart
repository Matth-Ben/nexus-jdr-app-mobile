/// Source d'une capture d'écran jointe à un signalement de bug.
enum BugReportScreenshotSource { gallery, camera }

/// Poids maximal d'une capture, en octets — `file_size_limit` du bucket
/// `bug-report-screenshots` (5 Mio, migration du dépôt web
/// `20261027090000_bug_reports_content_severity_and_screenshot.sql`).
const int bugReportScreenshotMaxBytes = 5 * 1024 * 1024;

/// Catégorie d'échec lors du choix/de la préparation d'une capture — chacune
/// a son propre texte dans `report_bug_sheet.dart` (spec B.7).
enum BugReportScreenshotFailureKind {
  /// Plus de [bugReportScreenshotMaxBytes] même après compression JPEG.
  tooLarge,

  /// Image impossible à décoder (format non pris en charge).
  unsupportedFormat,

  /// Accès aux photos ou à l'appareil photo refusé/restreint par le système.
  accessDenied,
}

class BugReportScreenshotFailure implements Exception {
  const BugReportScreenshotFailure(this.kind);

  final BugReportScreenshotFailureKind kind;

  @override
  String toString() => 'BugReportScreenshotFailure(${kind.name})';

  @override
  bool operator ==(Object other) =>
      other is BugReportScreenshotFailure && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}

/// Poids d'une capture au format français : « 840 Ko » sous 1 Mo, « 1,2 Mo »
/// au-delà (base 1024, comme [bugReportScreenshotMaxBytes]).
String formatBugReportScreenshotSize(int bytes) {
  const kibi = 1024;
  const mebi = kibi * kibi;
  final kilo = (bytes / kibi).round();
  if (bytes < mebi && kilo < kibi) {
    return '${kilo < 1 ? 1 : kilo} Ko';
  }
  final mega = (bytes / mebi).toStringAsFixed(1).replaceAll('.', ',');
  return '$mega Mo';
}
