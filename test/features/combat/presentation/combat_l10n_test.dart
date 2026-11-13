// Textes du combat : parité FR/EN des clés `combat*`, couverture des clés de la
// section 7 de `docs/combat-groupe-ui.md`, messages d'échec distincts.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat_announcement.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';
import 'package:personnages/features/combat/domain/combat_view_state.dart';
import 'package:personnages/features/combat/presentation/combat_l10n.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/combat_fixtures.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)').allMatches(text).map((m) => m.group(1)!).toSet();

const _specKeys = [
  'combatBannerTitle',
  'combatBannerTurn',
  'combatBannerAwaitingMaster',
  'combatBannerOffline',
  'combatScreenTitle',
  'combatRound',
  'combatTurnOf',
  'combatNoActiveTurn',
  'combatInitiativeProgress',
  'combatCurrentTurnLabel',
  'combatInitiativeToEnter',
  'combatFillInitiative',
  'combatBadgePc',
  'combatBadgeNpc',
  'combatYouTag',
  'combatStatusWaiting',
  'combatStatusRemoved',
  'combatRemovedSection',
  'combatMenuEditInitiative',
  'combatMenuEditMine',
  'combatMenuRemove',
  'combatRemoveConfirmTitle',
  'combatReorderMode',
  'combatReorderDone',
  'combatMoveUp',
  'combatMoveDown',
  'combatReorderLimit',
  'combatJumpToTurn',
  'combatAddMonster',
  'combatEnd',
  'combatEndConfirmTitle',
  'combatEndConfirmBody',
  'combatStart',
  'combatStartUnavailableOffline',
  'combatStartAlreadyActive',
  'combatNoMasterExplain',
  'combatInitiativeSheetTitle',
  'combatInitiativeRangeError',
  'combatDexHelp',
  'combatRollD20',
  'combatUseRoll',
  'combatRollUsedAnnounce',
  'combatMonsterName',
  'combatMonsterQuantity',
  'combatMonsterPreview',
  'combatMonsterPreviewMany',
  'combatAdd',
  'combatAddAndContinue',
  'combatAddedAnnounce',
  'combatEmptyMasterTitle',
  'combatEmptyMasterBody',
  'combatEmptyPlayer',
  'combatLoading',
  'combatLoadError',
  'combatOfflineBanner',
  'combatAwaitingMasterBody',
  'combatEndedSummary',
  'combatBackToGroup',
  'combatAnnounceTurn',
  'combatAnnounceYourTurn',
  'combatAnnounceEnded',
];

void main() {
  final fr = _arb('fr');
  final en = _arb('en');

  test('clés `combat*` identiques en FR et en EN', () {
    Set<String> keys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => k.startsWith('combat')).toSet();
    expect(keys(en), keys(fr));
    expect(keys(fr).length, greaterThan(60));
  });

  test('toutes les clés de la section 7 de la spec existent (FR et EN)', () {
    for (final key in _specKeys) {
      expect(fr.containsKey(key), isTrue, reason: 'FR $key');
      expect(en.containsKey(key), isTrue, reason: 'EN $key');
    }
  });

  test('mêmes paramètres en FR et en EN, aucune valeur vide', () {
    for (final key in fr.keys.where((k) => k.startsWith('combat'))) {
      final frText = fr[key] as String;
      final enText = en[key] as String;
      expect(frText.trim(), isNotEmpty, reason: key);
      expect(enText.trim(), isNotEmpty, reason: key);
      expect(_placeholders(enText), _placeholders(frText), reason: key);
    }
  });

  test('bloc combat contigu à la fin des deux .arb', () {
    for (final arb in [fr, en]) {
      final keys = arb.keys.toList();
      final first = keys.indexWhere(
        (k) => k.replaceFirst('@', '').startsWith('combat'),
      );
      final tail = keys.sublist(first);
      expect(
        tail.every((k) => k.replaceFirst('@', '').startsWith('combat')),
        isTrue,
      );
    }
  });

  testWidgets('messages d\'échec : un message propre par code, FR et EN', (
    tester,
  ) async {
    late AppLocalizations frL10n;
    late AppLocalizations enL10n;
    for (final locale in [const Locale('fr'), const Locale('en')]) {
      await tester.pumpWidget(
        Localizations(
          locale: locale,
          delegates: AppLocalizations.localizationsDelegates,
          child: Builder(
            builder: (context) {
              if (locale.languageCode == 'fr') {
                frL10n = AppLocalizations.of(context)!;
              } else {
                enL10n = AppLocalizations.of(context)!;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }
    // `no_game_master` est expliqué ; le local « pas de combat actif » est
    // distinct de la réponse serveur `combat_not_found`.
    expect(
      const CombatFailure(CombatFailureKind.noGameMaster).localized(frL10n),
      'Pas de combat sans MJ dans l\'app.',
    );
    expect(
      const CombatFailure(CombatFailureKind.noActiveCombat).localized(frL10n),
      'Aucun combat actif.',
    );
    expect(
      const CombatFailure(CombatFailureKind.combatNotFound).localized(frL10n),
      isNot(
        const CombatFailure(CombatFailureKind.noActiveCombat).localized(frL10n),
      ),
    );
    expect(
      const CombatFailure(CombatFailureKind.combatAlreadyActive)
          .localized(frL10n),
      'Un combat est déjà en cours.',
    );
    final seen = <String, CombatFailureKind>{};
    for (final kind in CombatFailureKind.values) {
      for (final l10n in [frL10n, enL10n]) {
        expect(CombatFailure(kind).localized(l10n), isNotEmpty);
      }
      final text = CombatFailure(kind).localized(frL10n);
      // Les codes sans message dédié partagent le message générique ; les
      // codes métier connus des RPC ont chacun un message.
      if (text != frL10n.combatFailureGeneric) {
        final previous = seen[text];
        // Seul le doublon voulu : invalid_initiative -> plage.
        expect(
          previous == null,
          isTrue,
          reason: '$kind et $previous partagent « $text »',
        );
        seen[text] = kind;
      }
    }
  });

  group('annonces (domaine)', () {
    CombatViewState active(
      String? currentId, {
      int round = 1,
      String? userId,
    }) => CombatViewState(
      phase: CombatPhase.active,
      snapshot: fakeSnapshot(
        combat: fakeCombat(round: round, currentParticipantId: currentId),
        participants: [
          fakeParticipant(
            'a',
            name: 'Aria',
            initiative: 9,
          ).copyWith(userId: userId),
          fakeParticipant('b', name: 'Brun', initiative: 5),
        ],
      ),
    );

    test('jamais au chargement (loading, none, error vers actif)', () {
      for (final phase in [
        CombatPhase.loading,
        CombatPhase.none,
        CombatPhase.error,
      ]) {
        expect(
          combatAnnouncementFor(
            previous: CombatViewState(phase: phase),
            next: active('a'),
          ),
          isNull,
        );
      }
    });

    test('changement de tour ou de round : annonce', () {
      final turn = combatAnnouncementFor(
        previous: active('a'),
        next: active('b'),
      );
      expect(turn?.kind, CombatAnnouncementKind.turn);
      expect(turn?.name, 'Brun');
      final round = combatAnnouncementFor(
        previous: active('a'),
        next: active('a', round: 2),
      );
      expect(round?.round, 2);
    });

    test('rien si le tour est identique ou si personne n\'a la main', () {
      expect(
        combatAnnouncementFor(previous: active('a'), next: active('a')),
        isNull,
      );
      expect(
        combatAnnouncementFor(previous: active('a'), next: active(null)),
        isNull,
      );
    });

    test('à soi : yourTurn ; fin : ended', () {
      expect(
        combatAnnouncementFor(
          previous: active('b'),
          next: active('a', userId: 'me'),
          currentUserId: 'me',
        )?.kind,
        CombatAnnouncementKind.yourTurn,
      );
      expect(
        combatAnnouncementFor(
          previous: active('a'),
          next: CombatViewState(
            phase: CombatPhase.ended,
            snapshot: active('a').snapshot,
          ),
        )?.kind,
        CombatAnnouncementKind.ended,
      );
    });
  });
}
