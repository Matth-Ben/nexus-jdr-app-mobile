import 'package:personnages/core/network/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utilitaires communs aux tests d'intégration (`test_integration/`, voir
/// `test_integration/README.md`) : ces tests exécutent les vraies
/// implémentations `Supabase*Repository` contre un stack Supabase local réel
/// (Postgres + PostgREST + GoTrue), contrairement à `flutter test` qui ne
/// manipule que des doubles factices (`_FakeCharacterRepository`...) et ne
/// peut donc jamais détecter une colonne inexistante, un mismatch de type ou
/// une policy RLS cassée.
///
/// Réutilise volontairement `EnvConfig` (déjà utilisé par `main.dart`) plutôt
/// qu'un mécanisme de lecture d'environnement dédié : ces tests se lancent
/// avec le même `--dart-define-from-file`, pointé vers `config/integration.json`
/// (voir `config/README.md`) au lieu de `config/dev.json`.

/// Instancie un `SupabaseClient` brut, sans passer par `Supabase.initialize`
/// (qui dépend de plugins Flutter comme `path_provider`/`shared_preferences`,
/// indisponibles dans un test VM pur lancé via `flutter test`). Les
/// repositories de ce dépôt ne prennent qu'un `SupabaseClient` en paramètre
/// de constructeur, donc rien d'autre n'est nécessaire ici.
///
/// Flow d'auth `implicit` plutôt que le `pkce` par défaut : PKCE a besoin de
/// stocker un code verifier entre l'appel de `signUp`/`signIn` et la
/// redirection de confirmation, via un `GotrueAsyncStorage` — mécanisme
/// pensé pour les apps avec redirection (OAuth, deep link), sans objet ici
/// (e-mail/mot de passe, confirmation désactivée localement) et qu'on ne
/// veut pas brancher sur un plugin Flutter pour un test VM pur.
SupabaseClient createTestSupabaseClient() {
  if (!EnvConfig.isConfigured) {
    throw StateError(
      'SUPABASE_URL/SUPABASE_ANON_KEY manquants : lancez ces tests avec '
      '--dart-define-from-file=config/integration.json '
      '(voir test_integration/README.md).',
    );
  }
  return SupabaseClient(
    EnvConfig.supabaseUrl,
    EnvConfig.supabaseAnonKey,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}

/// Crée un utilisateur de test jetable (e-mail aléatoire à chaque appel) et
/// authentifie [client] avec sa session. La confirmation par e-mail est
/// désactivée sur le stack local (`supabase/config.toml`, côté dépôt web) :
/// la session est donc disponible immédiatement après l'inscription, sans
/// avoir besoin de cliquer un lien de confirmation.
Future<void> signUpTestUser(SupabaseClient client) async {
  final email =
      'integration-test-${DateTime.now().microsecondsSinceEpoch}@nexus-jdr.test';
  final response = await client.auth.signUp(
    email: email,
    password: 'Test1234!Integration',
  );
  if (response.session == null) {
    throw StateError(
      "Inscription sans session retournée pour $email : la confirmation "
      "par e-mail est-elle bien désactivée sur le stack local "
      "(supabase/config.toml, [auth.email] enable_confirmations) ?",
    );
  }
}

/// Contenu de référence D&D existant (une race, une classe) à utiliser dans
/// les tests, avec leur nom traduit en français attendu. Peuplé par les
/// migrations de seed du dépôt web
/// (`supabase/migrations/..._seed_races_subraces.sql` et
/// `..._seed_classes_subclasses_features.sql`).
class ReferenceContent {
  const ReferenceContent({
    required this.raceId,
    required this.raceName,
    required this.classId,
    required this.className,
    required this.backgroundId,
    required this.backgroundName,
  });

  final Object raceId;
  final String raceName;
  final Object classId;
  final String className;
  final Object backgroundId;
  final String backgroundName;
}

/// Récupère [ReferenceContent] en lisant la première race et la première
/// classe disponibles. Échoue explicitement (plutôt que de laisser passer un
/// test qui ne teste plus rien) si ces tables ou leurs traductions sont
/// vides : ça signifie que les migrations/seeds du dépôt web n'ont pas été
/// appliqués (`supabase db reset`).
Future<ReferenceContent> fetchReferenceContent(SupabaseClient client) async {
  final race = await _fetchFirstTranslatedName(
    client,
    table: 'races',
    entityType: 'race',
  );
  final characterClass = await _fetchFirstTranslatedName(
    client,
    table: 'classes',
    entityType: 'class',
  );
  final background = await _fetchFirstTranslatedName(
    client,
    table: 'backgrounds',
    entityType: 'background',
  );
  return ReferenceContent(
    raceId: race.$1,
    raceName: race.$2,
    classId: characterClass.$1,
    className: characterClass.$2,
    backgroundId: background.$1,
    backgroundName: background.$2,
  );
}

Future<(Object, String)> _fetchFirstTranslatedName(
  SupabaseClient client, {
  required String table,
  required String entityType,
}) async {
  final row = await client.from(table).select('id').limit(1).maybeSingle();
  if (row == null) {
    throw StateError(
      "Table '$table' vide : les migrations/seeds du dépôt web ont-elles "
      "été appliquées (supabase db reset) ?",
    );
  }
  final id = row['id'] as Object;

  final translation = await client
      .from('translations')
      .select('value')
      .eq('entity_type', entityType)
      .eq('entity_id', id.toString())
      .eq('field_name', 'name')
      .eq('locale', 'fr')
      .maybeSingle();
  final name = translation?['value'] as String?;
  if (name == null) {
    throw StateError(
      "Traduction manquante pour $entityType #$id : les seeds du dépôt web "
      "ont-ils été appliqués en entier (supabase db reset) ?",
    );
  }
  return (id, name);
}
