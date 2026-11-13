import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/combat_failure.dart';
import '../domain/combat_enums.dart';

/// Message localisé d'un [CombatFailure] (un cas par code serveur stable).
/// Le message local « pas de combat actif » ([CombatFailureKind.noActiveCombat])
/// est distinct d'une réponse serveur `combat_not_found`.
extension CombatFailureL10n on CombatFailure {
  String localized(AppLocalizations l10n) => switch (kind) {
    CombatFailureKind.noActiveCombat => l10n.combatFailureNoActive,
    CombatFailureKind.combatNotFound => l10n.combatFailureNotFound,
    CombatFailureKind.combatNotActive => l10n.combatFailureNotActive,
    CombatFailureKind.combatAlreadyActive => l10n.combatStartAlreadyActive,
    CombatFailureKind.noGameMaster => l10n.combatNoMasterExplain,
    CombatFailureKind.gmAbsent => l10n.combatFailureGmAbsent,
    CombatFailureKind.notGroupOwner => l10n.combatFailureNotOwner,
    CombatFailureKind.participantRemoved =>
      l10n.combatFailureParticipantRemoved,
    CombatFailureKind.npcLimitPerCall => l10n.combatFailureNpcLimitCall,
    CombatFailureKind.npcLimitPerCombat => l10n.combatFailureNpcLimitCombat,
    CombatFailureKind.invalidInitiative => l10n.combatInitiativeRangeError,
    CombatFailureKind.invalidName => l10n.combatFailureInvalidName,
    CombatFailureKind.offline => l10n.combatStartUnavailableOffline,
    CombatFailureKind.network => l10n.combatFailureNetwork,
    _ => l10n.combatFailureGeneric,
  };
}

/// Heure locale « HH:mm » du dernier état connu.
String combatClockLabel(AppLocalizations l10n, DateTime instant) =>
    DateFormat.Hm(l10n.localeName).format(instant.toLocal());

/// « PJ » ou « PNJ ».
String combatKindLabel(AppLocalizations l10n, ParticipantKind kind) =>
    kind == ParticipantKind.pc ? l10n.combatBadgePc : l10n.combatBadgeNpc;
