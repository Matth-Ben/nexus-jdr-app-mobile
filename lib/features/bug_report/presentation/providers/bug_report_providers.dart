import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/bug_report_repository.dart';

part 'bug_report_providers.g.dart';

@Riverpod(keepAlive: true)
BugReportRepository bugReportRepository(Ref ref) {
  return SupabaseBugReportRepository(ref.watch(supabaseClientProvider));
}
