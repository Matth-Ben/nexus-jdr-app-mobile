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
}
