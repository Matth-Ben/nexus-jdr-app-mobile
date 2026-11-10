import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connectivity_checker.dart';

part 'connectivity_providers.g.dart';

/// [ConnectivityChecker] partagé par toute l'app — voir sa documentation de
/// classe. `keepAlive` : même rationale que `supabaseClientProvider`
/// (`core/network/supabase_client_provider.dart`), jamais recréé par écran.
@Riverpod(keepAlive: true)
ConnectivityChecker connectivityChecker(Ref ref) => ConnectivityPlusChecker();

/// État de connectivité en direct (`true` = connecté) : valeur courante puis
/// chaque changement — voir `ConnectivityChecker.onConnectivityChanged`.
/// Alimente le bandeau de synchro (`core/sync/`). Une erreur du canal de
/// plateforme est laissée à l'`AsyncValue` (le bandeau la traite comme « en
/// ligne », jamais comme un faux hors-ligne).
@Riverpod(keepAlive: true)
Stream<bool> connectivityStatus(Ref ref) async* {
  final checker = ref.watch(connectivityCheckerProvider);
  yield await checker.hasConnection();
  yield* checker.onConnectivityChanged;
}
