import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connectivity_checker.dart';

part 'connectivity_providers.g.dart';

/// [ConnectivityChecker] partagé par toute l'app — voir sa documentation de
/// classe. `keepAlive` : même rationale que `supabaseClientProvider`
/// (`core/network/supabase_client_provider.dart`), jamais recréé par écran.
@Riverpod(keepAlive: true)
ConnectivityChecker connectivityChecker(Ref ref) => ConnectivityPlusChecker();
