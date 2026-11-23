// Textes du combat mené depuis Grimoire : clés du §11 de
// `docs/combat-grimoire-ui.md` en FR et en EN, tutoiement (module groupes).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Clés nouvelles du §11 (les clés réutilisées existent déjà), plus l'indice
/// de « Lancer un combat » désactivé (décision 61) et le libellé lecteur
/// d'écran du bandeau de fiche « Envoie ton initiative ».
const _keys = [
  'combatGrimoireSource',
  'combatGrimoireLeaderInfo',
  'combatShout',
  'combatPreparingStatus',
  'combatPreparingHint',
  'combatBannerPreparing',
  'combatBannerOpen',
  'combatBannerSendInitiative',
  'combatBannerInitiativeSent',
  'combatSheetBannerInitiativeRequested',
  'combatSheetBannerPreparingSemantics',
  'combatSheetBannerInitiativeRequestedSemantics',
  'combatInitiativeRequestTitle',
  'combatInitiativeRequestFor',
  'combatSendInitiative',
  'combatSendToGm',
  'combatSendHint',
  'combatInitiativeSent',
  'combatInitiativeAwaitingReceipt',
  'combatInitiativeReceived',
  'combatInitiativeKnownByGm',
  'combatInitiativeMayAdjust',
  'combatInitiativeNotReceived',
  'combatInitiativeRequestedAgain',
  'combatInitiativeSentLabel',
  'combatInitiativeCorrected',
  'combatUnavailableGmOffline',
  'combatSendRateLimited',
  'combatSendFailed',
  'combatNotMemberAnymore',
  'combatBadgeDead',
  'combatTurnSkipped',
  'combatRowDeadSemantics',
  'combatRemovedByGm',
  'combatYourTurn',
  'combatBannerYourTurn',
  'combatSheetBannerYourTurnSemantics',
  'combatCalloutInitiativeTitle',
  'combatCalloutSendInitiative',
  'combatCalloutOpen',
  'combatCalloutYourTurnBody',
  'combatCalloutClose',
  'combatGmOfflineBanner',
  'combatBannerGmOffline',
  'combatSheetBannerGmOffline',
  'combatSheetBannerGmOfflineSemantics',
  'combatInterruptedTitle',
  'combatInterruptedBody',
  'combatConnecting',
  'combatNoneTitle',
  'combatNoneBody',
  'combatGroupNotAccessible',
  'combatEndedTitle',
  'combatEndedBeforeOrder',
  'combatAnnounceStart',
  'combatAnnounceInitiativeRequested',
  'combatAnnounceInitiativeSent',
  'combatAnnounceInitiativeReceived',
  'combatAnnounceInitiativeCorrected',
  'combatAnnounceOrderRevealed',
  'combatAnnounceGmOffline',
  'combatAnnounceGmBack',
  'combatStartBlockedByGrimoire',
  'combatBackHome',
  'profileNotificationsGmCombat',
  'profileNotificationsGmCombatSubtitle',
];

void main() {
  final fr = _arb('fr');
  final en = _arb('en');

  test('toutes les clés du §11 existent en FR et en EN', () {
    for (final key in _keys) {
      expect(fr.containsKey(key), isTrue, reason: 'FR $key');
      expect(en.containsKey(key), isTrue, reason: 'EN $key');
      expect(fr.containsKey('@$key'), isTrue, reason: 'description $key');
    }
  });

  test('tutoiement en FR, aucun vouvoiement', () {
    final formal = RegExp(r'\b(vous|votre|vos|Vous|Votre|Vos)\b');
    for (final key in _keys) {
      expect(formal.hasMatch(fr[key] as String), isFalse, reason: key);
    }
  });

  test('textes du §11 repris à l\'identique (échantillon)', () {
    expect(fr['combatGrimoireSource'], 'Mené depuis Grimoire');
    expect(fr['combatYourTurn'], 'À toi de jouer');
    expect(en['combatYourTurn'], 'Your turn');
    expect(
      fr['combatGmOfflineBanner'],
      'Le MJ semble hors ligne. Dernier état reçu à {time} ; le combat '
      'reprendra dès son retour.',
    );
    expect(
      fr['combatStartBlockedByGrimoire'],
      'Un combat est mené depuis Grimoire.',
    );
  });
}
