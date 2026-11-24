import 'package:supabase_flutter/supabase_flutter.dart';

/// Langue du **compte** (`user_metadata.locale`, `fr` ou `en`) : DeepCore
/// s'en sert pour écrire les notifications push dans la langue du joueur
/// (`notify-group`, contrat `docs/api-v1/contrat-temps-reel-combat.md` §5 :
/// `lower(raw_user_meta_data ->> 'locale')`, toute autre valeur ou absence :
/// français).
///
/// Abstraction pour que les tests fournissent un double sans
/// `Supabase.instance.client` — même principe que les autres dépôts.
abstract class AccountLocaleRepository {
  /// Un compte est connecté.
  bool get hasAccount;

  /// `user_metadata.locale` du compte connecté (session locale), `null` si
  /// absente ou sans compte.
  String? currentLocale();

  /// Écrit [languageCode] dans `user_metadata.locale`.
  Future<void> writeLocale(String languageCode);
}

class SupabaseAccountLocaleRepository implements AccountLocaleRepository {
  SupabaseAccountLocaleRepository(this._client);

  final SupabaseClient _client;

  static const String _key = 'locale';

  @override
  bool get hasAccount => _client.auth.currentUser != null;

  @override
  String? currentLocale() {
    final value = _client.auth.currentUser?.userMetadata?[_key];
    return value is String ? value : null;
  }

  @override
  Future<void> writeLocale(String languageCode) async {
    // Seulement `{locale}` : GoTrue fusionne `data` dans `user_metadata`
    // (clé par clé), et la copie locale de `user_metadata` peut être
    // périmée (nom ou avatar changés depuis l'app web) : la renvoyer en
    // entier écraserait ces changements.
    await _client.auth.updateUser(
      UserAttributes(data: <String, dynamic>{_key: languageCode}),
    );
  }
}
