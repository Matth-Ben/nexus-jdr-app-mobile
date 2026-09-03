import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/bug_report_failure.dart';
import 'bug_report_error_mapper.dart';

/// Passerelle vers l'edge function Supabase `report-bug` — déjà déployée côté
/// dépôt web (migration `bug_reports` + RLS, jamais modifiées depuis ce
/// dépôt). Voir `presentation/widgets/report_bug_sheet.dart` (dépôt
/// `features/profile/`, seul point d'entrée pour l'instant) pour l'écran
/// appelant.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client` — même principe que `CharacterRepository`/
/// `StoryInviteRepository`.
abstract class BugReportRepository {
  /// Envoie un signalement au support. [severity] porte une des 3 valeurs
  /// techniques du contrat serveur (`mineur`/`majeur`/`bloquant`, voir
  /// `report_bug_sheet.dart`), jamais un libellé déjà traduit.
  ///
  /// Un code HTTP 200 est un succès utilisateur quel que soit le `status`
  /// métier renvoyé dans le corps (`"synced"`/`"failed"` — ce dernier
  /// signale un problème de synchronisation GitHub côté serveur, transparent
  /// pour l'app, jamais inspecté ici) : cette méthode retourne normalement
  /// dans les deux cas. Lève une [BugReportFailure] pour tout le reste (code
  /// d'erreur HTTP, exception réseau) — voir sa documentation de classe pour
  /// le rationale de son absence de distinction par code.
  Future<void> submitReport({
    required String title,
    required String description,
    required String severity,
    String? characterId,
  });
}

class SupabaseBugReportRepository implements BugReportRepository {
  SupabaseBugReportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> submitReport({
    required String title,
    required String description,
    required String severity,
    String? characterId,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await _client.functions.invoke(
        'report-bug',
        body: {
          'title': title,
          'description': description,
          'severity': severity,
          'appVersion': packageInfo.version,
          'platform': _platformLabel(),
          'characterId': ?characterId,
        },
      );
    } on FunctionException catch (error) {
      throw mapBugReportError(error);
    } on BugReportFailure {
      rethrow;
    } catch (_) {
      throw const BugReportFailure(genericBugReportErrorMessage);
    }
  }

  /// `appVersion`/`platform` du contrat `report-bug` : lus ici plutôt que
  /// reçus en paramètre (spec de la tâche, "aucun champ visible ... injectés
  /// silencieusement") — `PackageInfo.fromPlatform()` (même appel que
  /// `package_info_provider.dart`) et `Platform.isAndroid`/`isIOS`, jamais
  /// codés en dur.
  String _platformLabel() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem;
  }
}
