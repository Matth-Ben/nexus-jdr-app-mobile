import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../characters/presentation/providers/character_providers.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../data/data_export_repository.dart';

part 'data_export_providers.g.dart';

@Riverpod(keepAlive: true)
DataExportRepository dataExportRepository(Ref ref) {
  return LocalFileDataExportRepository(
    ref.watch(characterRepositoryProvider),
    ref.watch(groupRepositoryProvider),
    ref.watch(supabaseClientProvider),
  );
}
