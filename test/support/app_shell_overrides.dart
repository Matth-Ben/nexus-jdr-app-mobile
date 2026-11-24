import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:personnages/features/combat/presentation/providers/grimoire_groups_providers.dart';
import 'package:personnages/features/profile/data/account_locale_repository.dart';
import 'package:personnages/features/profile/presentation/providers/account_locale_providers.dart';

import 'fake_connectivity_checker.dart';

/// Aucun compte connecté : la langue du compte n'est jamais écrite.
class NoAccountLocaleRepository implements AccountLocaleRepository {
  @override
  bool get hasAccount => false;

  @override
  String? currentLocale() => null;

  @override
  Future<void> writeLocale(String languageCode) async {}
}

/// Surcharges des coordinateurs posés par `NexusJdrApp` qui liraient
/// `Supabase.instance.client` (non initialisé dans un test de widget) : suivi
/// des combats de tous les groupes, langue du compte. Même rationale que les
/// surcharges de `characterWriteSyncCoordinatorProvider` dans
/// `test/widget_test.dart`.
List<Override> appShellTestOverrides() => [
  grimoireGroupsFollowerProvider.overrideWith((ref) {}),
  accountLocaleSyncProvider.overrideWithValue(
    AccountLocaleSync(NoAccountLocaleRepository(), FakeConnectivityChecker()),
  ),
];
