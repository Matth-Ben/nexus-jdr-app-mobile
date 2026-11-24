import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/connectivity_checker.dart';
import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/account_locale_repository.dart';

part 'account_locale_providers.g.dart';

/// Code de langue écrit dans `user_metadata.locale` : `en` ou `fr` (repli,
/// comme la langue de l'app et comme `notify-group`).
String accountLocaleCode(String languageCode) =>
    languageCode.toLowerCase() == 'en' ? 'en' : 'fr';

/// Garde `user_metadata.locale` du compte égal à la langue affichée par
/// l'app (préférence explicite de l'écran « Langue », sinon langue du
/// téléphone résolue en `fr`/`en`) : DeepCore écrit les notifications push
/// dans cette langue (`notify-group`).
///
/// - Écrit **seulement si elle change** (comparée à la session locale, mise
///   à jour par chaque écriture réussie) : à la connexion et au changement de
///   langue dans l'app.
/// - Hors ligne ou en échec : rien n'est écrit, nouvel essai à la prochaine
///   occasion (retour du réseau, connexion, changement de langue).
/// - Best-effort : aucune exception ne remonte.
class AccountLocaleSync {
  AccountLocaleSync(this._repository, this._connectivity);

  final AccountLocaleRepository _repository;
  final ConnectivityChecker _connectivity;

  String? _appLanguage;
  bool _running = false;
  bool _rerun = false;

  /// Langue affichée par l'app (`Localizations.localeOf`), signalée par
  /// `AccountLocaleReporter` à chaque changement.
  void reportAppLanguage(String languageCode) {
    final code = accountLocaleCode(languageCode);
    if (code == _appLanguage) return;
    _appLanguage = code;
    unawaited(sync());
  }

  /// Écrit la langue de l'app dans le compte si elle en diffère. Une seule
  /// écriture à la fois ; une demande faite pendant l'écriture est rejouée
  /// ensuite.
  Future<void> sync() async {
    if (_running) {
      _rerun = true;
      return;
    }
    _running = true;
    try {
      do {
        _rerun = false;
        await _syncOnce();
      } while (_rerun);
    } finally {
      _running = false;
    }
  }

  Future<void> _syncOnce() async {
    final desired = _appLanguage;
    if (desired == null) return;
    try {
      if (!_repository.hasAccount) return;
      if (_repository.currentLocale()?.toLowerCase() == desired) return;
      if (!await _connectivity.hasConnection()) return;
      await _repository.writeLocale(desired);
    } on Object catch (error) {
      debugPrint('AccountLocaleSync: $error');
    }
  }
}

@Riverpod(keepAlive: true)
AccountLocaleRepository accountLocaleRepository(Ref ref) =>
    SupabaseAccountLocaleRepository(ref.watch(supabaseClientProvider));

/// [AccountLocaleSync] de l'app (`keepAlive`) : réessaie à chaque connexion
/// effective (`signedIn`, reprise de session) et au retour du réseau.
@Riverpod(keepAlive: true)
AccountLocaleSync accountLocaleSync(Ref ref) {
  final connectivity = ref.watch(connectivityCheckerProvider);
  final sync = AccountLocaleSync(
    ref.watch(accountLocaleRepositoryProvider),
    connectivity,
  );
  final auth = ref.watch(authStateStreamProvider).onAuthStateChange.listen((
    state,
  ) {
    final signedIn =
        state.event == AuthChangeEvent.signedIn ||
        (state.event == AuthChangeEvent.initialSession &&
            state.session != null);
    if (signedIn) unawaited(sync.sync());
  }, onError: (_) {});
  final restored = connectivity.onConnectivityRestored.listen(
    (_) => unawaited(sync.sync()),
    onError: (_) {},
  );
  ref.onDispose(() {
    unawaited(auth.cancel());
    unawaited(restored.cancel());
  });
  return sync;
}
