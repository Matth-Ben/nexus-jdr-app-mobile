import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/account_locale_providers.dart';

/// Signale à [AccountLocaleSync] la langue **affichée** par l'app
/// (`Localizations.localeOf`) : préférence de l'écran « Langue », sinon langue
/// du téléphone résolue — à placer dans `MaterialApp.router(builder: ...)`,
/// sous les `Localizations` de l'app. Sans effet visuel.
class AccountLocaleReporter extends ConsumerStatefulWidget {
  const AccountLocaleReporter({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AccountLocaleReporter> createState() =>
      _AccountLocaleReporterState();
}

class _AccountLocaleReporterState extends ConsumerState<AccountLocaleReporter> {
  String? _reported;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.maybeLocaleOf(context)?.languageCode;
    if (code == null || code == _reported) return;
    _reported = code;
    // Après l'image : jamais d'écriture d'un fournisseur pendant une
    // construction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(accountLocaleSyncProvider).reportAppLanguage(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
