/// Configuration d'environnement (URL/clé Supabase) lue depuis les
/// `--dart-define` fournis au build/run, eux-mêmes chargés depuis un fichier
/// JSON par flavor via `--dart-define-from-file` (voir `config/README.md`).
///
/// Aucune valeur n'est jamais codée en dur ici : en cas d'oubli de passer
/// `--dart-define-from-file`, [supabaseUrl] et [supabaseAnonKey] sont vides
/// et [EnvConfig.isConfigured] permet de le détecter tôt (voir `main.dart`).
abstract final class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Jeton de projet PostHog (`core/analytics/`) — vide si non fourni.
  /// Contrairement à [supabaseUrl]/[supabaseAnonKey], son absence n'a jamais
  /// vocation à bloquer le démarrage de l'app (voir [isPostHogConfigured] et
  /// `main.dart`) : PostHog est un SDK d'analytics secondaire, pas une
  /// dépendance structurante comme Supabase.
  static const String postHogApiKey = String.fromEnvironment('POSTHOG_API_KEY');

  /// Host EU par défaut (app francophone, ciblant potentiellement des
  /// utilisateurs UE) — surchageable via `--dart-define` si un host US/
  /// self-hosted est préféré.
  static const String postHogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.i.posthog.com',
  );

  /// `true` dès que [postHogApiKey] est renseigné — ne conditionne jamais le
  /// démarrage de l'app (voir [isConfigured], réservé à Supabase).
  static bool get isPostHogConfigured => postHogApiKey.isNotEmpty;
}
