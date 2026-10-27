import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/bug_report_repository.dart';
import '../../data/bug_report_screenshot_picker.dart';

part 'bug_report_providers.g.dart';

@Riverpod(keepAlive: true)
BugReportRepository bugReportRepository(Ref ref) {
  return SupabaseBugReportRepository(ref.watch(supabaseClientProvider));
}

/// Sélecteur/préparateur de la capture d'écran d'un signalement — surchargé
/// par un double dans les tests de widget de `report_bug_sheet.dart`.
@Riverpod(keepAlive: true)
BugReportScreenshotPicker bugReportScreenshotPicker(Ref ref) {
  return ImagePickerBugReportScreenshotPicker();
}
