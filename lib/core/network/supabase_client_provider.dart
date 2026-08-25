import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

/// Client Supabase partagé par toute l'app (auth, Postgrest, realtime,
/// storage). Suppose que `Supabase.initialize` a déjà été appelé (voir
/// `main.dart`) avant que ce provider ne soit lu — jamais dans un test de
/// widget sans l'avoir surchargé (`overrideWithValue`).
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
