import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import 'combat_providers.dart';

/// `true` quand le combat du groupe [groupId] est en **lecture seule** : le
/// dernier refetch a échoué (état périmé) ou le réseau est coupé. Aucune
/// écriture de combat n'est jamais mise en file hors ligne.
final combatReadOnlyProvider = Provider.family<bool, String>((ref, groupId) {
  final stale = ref.watch(
    combatProvider(groupId).select((state) => state.isReadOnly),
  );
  final offline = ref.watch(connectivityStatusProvider).value == false;
  return stale || offline;
});
