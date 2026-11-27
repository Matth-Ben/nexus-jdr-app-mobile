// Composants du combat mené depuis Grimoire (`docs/combat-grimoire-ui.md`) :
// bandeaux Groupe et fiche (préparation, « À toi de jouer », MJ hors ligne),
// carte d'initiative, en-tête avec ligne de source, ligne « morte », mesures
// de recettage du §10 à 320 dp.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_combat_providers.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_banner.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_header.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_initiative_card.dart';
import 'package:personnages/features/combat/presentation/widgets/initiative_row.dart';
import 'package:personnages/features/combat/presentation/widgets/start_combat_section.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/combat_fixtures.dart';
import '../../../support/fake_combat_repository.dart';
import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_current_user.dart';
import '../../../support/fake_grimoire_combat_gateway.dart';
import '../../../support/grimoire_fixtures.dart';
import 'combat_test_harness.dart';

final _at = DateTime.parse(kSentAt);
String get _time => DateFormat.Hm('fr').format(_at.toLocal());

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
  Locale locale = const Locale('fr'),
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            // Marges `lg` de l'écran : 320 - 2 × 22.
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: child,
          ),
        ),
      ),
    ),
  );
  // Un bouton en chargement anime en continu : pas de pumpAndSettle.
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

CombatBannerView _banner({
  CombatBannerVariant variant = CombatBannerVariant.group,
  CombatBannerMode mode = CombatBannerMode.standard,
  CombatBannerInitiativeHint hint = CombatBannerInitiativeHint.none,
  DateTime? gmOfflineSince,
  DateTime? offlineSince,
}) => CombatBannerView(
  variant: variant,
  mode: mode,
  initiativeHint: hint,
  round: 2,
  turnName: 'Gobelin',
  gmOfflineSince: gmOfflineSince,
  offlineSince: offlineSince,
  onTap: () {},
);

void main() {
  setUpAll(loadCombatFonts);

  group('bandeau Groupe', () {
    testWidgets('préparation : rappel d\'initiative selon l\'état', (
      tester,
    ) async {
      await _pump(
        tester,
        _banner(
          mode: CombatBannerMode.preparing,
          hint: CombatBannerInitiativeHint.send,
        ),
      );
      expect(find.text('Combat en préparation'), findsOneWidget);
      expect(
        find.text('Envoie ton initiative · Ouvrir le combat'),
        findsOneWidget,
      );
      await _pump(
        tester,
        _banner(
          mode: CombatBannerMode.preparing,
          hint: CombatBannerInitiativeHint.sent,
        ),
      );
      expect(
        find.text('Initiative envoyée · Ouvrir le combat'),
        findsOneWidget,
      );
      await _pump(tester, _banner(mode: CombatBannerMode.preparing));
      expect(find.text('Ouvrir le combat'), findsOneWidget);
    });

    testWidgets('à toi de jouer : titre, cadre emphasis', (tester) async {
      await _pump(tester, _banner(mode: CombatBannerMode.yourTurn));
      expect(find.text('À toi de jouer · round 2'), findsOneWidget);
      expect(find.text('Ouvrir le combat'), findsOneWidget);
      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.byKey(const Key('combatBanner')),
              matching: find.byType(Material),
            )
            .first,
      );
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.side.width, 3);
      expect(material.color, kCombatTurnFill);
    });

    testWidgets('MJ hors ligne ; hors ligne l\'emporte', (tester) async {
      await _pump(tester, _banner(gmOfflineSince: _at));
      expect(find.text('MJ hors ligne · état de $_time'), findsOneWidget);
      await _pump(tester, _banner(gmOfflineSince: _at, offlineSince: _at));
      expect(find.text('Hors ligne · état de $_time'), findsOneWidget);
      expect(find.textContaining('MJ hors ligne'), findsNothing);
    });

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets(
        '×$scale : à toi de jouer et MJ hors ligne dans la fourchette',
        (tester) async {
          await _pump(
            tester,
            _banner(mode: CombatBannerMode.yourTurn),
            scale: scale,
          );
          final turn = tester.getSize(find.byKey(const Key('combatBanner')));
          await _pump(tester, _banner(gmOfflineSince: _at), scale: scale);
          final offline = tester.getSize(find.byKey(const Key('combatBanner')));
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            expect(turn.height, inInclusiveRange(64, 76));
            expect(offline.height, inInclusiveRange(64, 76));
          } else {
            expect(turn.height, lessThanOrEqualTo(150));
            expect(offline.height, lessThanOrEqualTo(150));
          }
        },
      );
    }
  });

  group('bandeau fiche', () {
    testWidgets('textes et libellés lecteur d\'écran', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _banner(
          variant: CombatBannerVariant.sheet,
          mode: CombatBannerMode.preparing,
          hint: CombatBannerInitiativeHint.send,
        ),
      );
      expect(find.text('Combat ! Envoie ton initiative'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Combat ! Envoie ton initiative. Ouvrir le combat.',
        ),
        findsOneWidget,
      );
      await _pump(
        tester,
        _banner(
          variant: CombatBannerVariant.sheet,
          mode: CombatBannerMode.preparing,
        ),
      );
      expect(find.text('Combat en préparation'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Combat en préparation. Ouvrir le combat.'),
        findsOneWidget,
      );
      await _pump(
        tester,
        _banner(
          variant: CombatBannerVariant.sheet,
          mode: CombatBannerMode.yourTurn,
        ),
      );
      expect(find.text('À toi de jouer · round 2'), findsOneWidget);
      expect(
        find.bySemanticsLabel('À toi de jouer, round 2. Ouvrir le combat.'),
        findsOneWidget,
      );
      await _pump(
        tester,
        _banner(variant: CombatBannerVariant.sheet, gmOfflineSince: _at),
      );
      expect(
        find.text('Combat · MJ hors ligne (état de $_time)'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Combat en cours, MJ hors ligne, état de $_time. Ouvrir le combat.',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('×$scale : MJ hors ligne ≤ 120 dp, icône masquée', (
        tester,
      ) async {
        await _pump(
          tester,
          _banner(variant: CombatBannerVariant.sheet, gmOfflineSince: _at),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.byKey(const Key('combatSheetBanner')));
        expect(size.height, lessThanOrEqualTo(120));
        await _pump(
          tester,
          _banner(
            variant: CombatBannerVariant.sheet,
            mode: CombatBannerMode.yourTurn,
          ),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const Key('combatSheetBanner'))).height,
          lessThanOrEqualTo(114),
        );
      });
    }
  });

  group('carte d\'initiative', () {
    CombatInitiativeCard card(
      CombatInitiativeCardState state, {
      int? value,
      bool preparing = true,
      String? unavailable,
      String? failure,
    }) => CombatInitiativeCard(
      state: state,
      characterName: 'Ysolde la Très Longue des Montagnes Brumeuses',
      value: value,
      preparing: preparing,
      unavailableReason: unavailable,
      failureMessage: failure,
      onSend: () {},
    );

    testWidgets('chaque état', (tester) async {
      await _pump(tester, card(CombatInitiativeCardState.requested));
      expect(find.text('Le MJ demande ton initiative'), findsOneWidget);
      expect(find.text('ENVOYER MON INITIATIVE'), findsOneWidget);

      await _pump(
        tester,
        card(CombatInitiativeCardState.sending),
        settle: false,
      );
      expect(
        tester
            .widget<PrimaryButton>(
              find.byKey(const Key('combatSendInitiative')),
            )
            .isLoading,
        isTrue,
      );

      await _pump(tester, card(CombatInitiativeCardState.sent, value: 15));
      expect(find.text('15 · envoyée au MJ'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsNothing);

      await _pump(tester, card(CombatInitiativeCardState.received));
      expect(find.text('Le MJ a ton initiative'), findsOneWidget);

      await _pump(tester, card(CombatInitiativeCardState.notReceived));
      expect(
        find.text('Le MJ n\'a pas reçu ton initiative. Renvoie-la.'),
        findsOneWidget,
      );

      await _pump(tester, card(CombatInitiativeCardState.requestedAgain));
      expect(find.text('Le MJ te redemande ton initiative.'), findsOneWidget);

      await _pump(
        tester,
        card(
          CombatInitiativeCardState.requested,
          unavailable: 'Indisponible hors ligne',
        ),
      );
      expect(find.text('Indisponible hors ligne'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(
              find.byKey(const Key('combatSendInitiative')),
            )
            .onPressed,
        isNull,
      );

      await _pump(
        tester,
        card(
          CombatInitiativeCardState.failed,
          failure: 'Tu ne fais plus partie de ce groupe.',
        ),
      );
      expect(find.text('Tu ne fais plus partie de ce groupe.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('×1,0 : 110 à 170 dp', (tester) async {
      await _pump(tester, card(CombatInitiativeCardState.requested));
      final size = tester.getSize(
        find.byKey(const Key('combatInitiativeCard')),
      );
      expect(size.height, inInclusiveRange(110, 170));
    });

    testWidgets('×3,0 sur 320 dp avec le bouton et l\'échec : sans '
        'débordement, nom complet', (tester) async {
      await _pump(
        tester,
        SingleChildScrollView(
          child: card(
            CombatInitiativeCardState.failed,
            failure: 'Trop d\'envois. Réessaie dans 42 s.',
          ),
        ),
        scale: 3,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('Pour Ysolde la Très Longue des Montagnes Brumeuses'),
        findsOneWidget,
      );
      final text = tester.widget<Text>(
        find.text('Pour Ysolde la Très Longue des Montagnes Brumeuses'),
      );
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });
  });

  group('en-tête', () {
    testWidgets('ligne de source ; ×1,0 dans les fourchettes', (tester) async {
      await _pump(
        tester,
        const CombatHeader(
          round: 2,
          turnName: 'Gobelin',
          initiativeEntered: 2,
          initiativeTotal: 3,
          sourceLabel: 'Mené depuis Grimoire',
        ),
      );
      expect(find.text('Mené depuis Grimoire'), findsOneWidget);
      expect(find.byIcon(Icons.desktop_windows_outlined), findsOneWidget);
      final standard = tester.getSize(find.byKey(const Key('combatHeader')));
      expect(standard.height, inInclusiveRange(90, 120));

      await _pump(
        tester,
        const CombatHeader(
          mode: CombatHeaderMode.preparing,
          round: 1,
          initiativeEntered: 0,
          initiativeTotal: 0,
          sourceLabel: 'Mené depuis Grimoire',
        ),
      );
      final preparing = tester.getSize(find.byKey(const Key('combatHeader')));
      expect(preparing.height, lessThanOrEqualTo(150));
      expect(find.textContaining('Round'), findsNothing);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('×$scale, nom court : même hauteur en mode normal et « À toi '
          'de jouer »', (tester) async {
        CombatHeader header(CombatHeaderMode mode) => CombatHeader(
          mode: mode,
          round: 2,
          turnName: 'Al',
          initiativeEntered: 2,
          initiativeTotal: 3,
          sourceLabel: 'Mené depuis Grimoire',
        );
        await _pump(tester, header(CombatHeaderMode.standard), scale: scale);
        final standard = tester.getSize(find.byKey(const Key('combatHeader')));
        expect(find.text('Tour de Al').hitTestable(), findsOneWidget);
        expect(find.text('À toi de jouer').hitTestable(), findsNothing);
        await _pump(tester, header(CombatHeaderMode.yourTurn), scale: scale);
        final yourTurn = tester.getSize(find.byKey(const Key('combatHeader')));
        expect(find.text('À toi de jouer').hitTestable(), findsOneWidget);
        expect(find.text('Tour de Al').hitTestable(), findsNothing);
        expect(yourTurn.height, standard.height);
      });
    }

    testWidgets('sans ligne de source : en-tête natif inchangé', (
      tester,
    ) async {
      await _pump(
        tester,
        const CombatHeader(
          round: 2,
          turnName: 'Gobelin',
          initiativeEntered: 2,
          initiativeTotal: 3,
        ),
      );
      expect(find.byKey(const Key('combatHeaderSource')), findsNothing);
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('×$scale : ≤ 40 % du viewport, à toi de jouer compris', (
        tester,
      ) async {
        await _pump(
          tester,
          const CombatHeader(
            mode: CombatHeaderMode.yourTurn,
            round: 2,
            turnName: 'Aria',
            initiativeEntered: 2,
            initiativeTotal: 3,
            sourceLabel: 'Mené depuis Grimoire',
          ),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const Key('combatHeader'))).height,
          lessThanOrEqualTo(700 * 0.4),
        );
      });
    }
  });

  group('ligne « morte »', () {
    InitiativeRow row({String name = 'Brun'}) => InitiativeRow(
      participant: fakeParticipant(
        'p-brun',
        name: name,
        initiative: 12,
        characterId: 'c-brun',
      ),
      rank: 2,
      isDead: true,
    );

    testWidgets('badge, « Tour sauté », fond, nom non barré', (tester) async {
      await _pump(tester, row());
      expect(find.text('Mort'), findsOneWidget);
      expect(find.byIcon(Icons.heart_broken_outlined), findsOneWidget);
      expect(find.text('Tour sauté'), findsOneWidget);
      final name = tester.widget<Text>(find.text('Brun'));
      expect(name.style?.decoration, isNot(TextDecoration.lineThrough));
      expect(
        tester.getSize(find.byType(InitiativeRow)).height,
        lessThanOrEqualTo(96),
      );
    });

    testWidgets('×3,0 : badges présents, ≤ 320 dp', (tester) async {
      await _pump(tester, row(), scale: 3);
      expect(tester.takeException(), isNull);
      expect(find.text('Mort'), findsOneWidget);
      expect(find.text('Tour sauté'), findsOneWidget);
      expect(
        tester.getSize(find.byType(InitiativeRow)).height,
        lessThanOrEqualTo(320),
      );
    });

    testWidgets('×3,0, nom long : passe à la ligne, jamais coupé', (
      tester,
    ) async {
      await _pump(
        tester,
        SingleChildScrollView(
          child: row(name: 'Brun le Hardi des Collines Venteuses'),
        ),
        scale: 3,
      );
      expect(tester.takeException(), isNull);
      final name = tester.widget<Text>(
        find.text('Brun le Hardi des Collines Venteuses'),
      );
      expect(name.maxLines, isNull);
      expect(find.text('Mort'), findsOneWidget);
    });

    for (final scale in [1.0, 3.0]) {
      testWidgets('×$scale, pire cas (mort, « Toi », sans initiative, '
          '`onFill` fourni) : aucun bloc d\'initiative, dans la fourchette', (
        tester,
      ) async {
        await _pump(
          tester,
          InitiativeRow(
            participant: fakeParticipant(
              'p-aria',
              name: 'Aria',
              characterId: 'c-player',
            ),
            rank: null,
            isYou: true,
            isDead: true,
            pendingLabel: 'Envoyée au MJ',
            onFill: () {},
          ),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Mort'), findsOneWidget);
        expect(find.text('Toi'), findsOneWidget);
        expect(find.text('Tour sauté'), findsOneWidget);
        expect(find.text('Initiative à saisir'), findsNothing);
        expect(find.text('Envoyée au MJ'), findsNothing);
        expect(find.text('Renseigner'), findsNothing);
        final height = tester.getSize(find.byType(InitiativeRow)).height;
        expect(height, lessThanOrEqualTo(scale == 1 ? 96 : 320));
      });
    }

    testWidgets('surbrillance sur un héros mort : le tour l\'emporte', (
      tester,
    ) async {
      await _pump(
        tester,
        InitiativeRow(
          participant: fakeParticipant(
            'p-brun',
            name: 'Brun',
            initiative: 12,
            kind: ParticipantKind.pc,
          ),
          rank: 2,
          isDead: true,
          isCurrent: true,
        ),
      );
      expect(find.text('Mort'), findsOneWidget);
      expect(find.text('Tour en cours'), findsOneWidget);
      expect(find.text('Tour sauté'), findsNothing);
    });
  });

  group('bandeau Groupe nourri par le suivi Grimoire', () {
    testWidgets('Grimoire vivant prioritaire, retiré à l\'expiration', (
      tester,
    ) async {
      final gateway = FakeGrimoireCombatGateway();
      final connectivity = FakeConnectivityChecker();
      final repo = FakeCombatRepository()
        ..snapshot = fakeSnapshot(participants: combatRoster());
      var now = DateTime(2026, 11, 23, 21);
      final container = ProviderContainer(
        overrides: [
          currentUserFromTestOverride,
          combatRepositoryProvider.overrideWithValue(repo),
          connectivityCheckerProvider.overrideWithValue(connectivity),
          grimoireCombatGatewayProvider.overrideWithValue(gateway),
          combatClockProvider.overrideWithValue(() => now),
        ],
      );
      await _pump(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: CombatGroupBanner(
            groupId: groupId,
            masterAbsent: false,
            identity: kMe,
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Combat en cours · round 1'), findsOneWidget);
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gInitiativeRequest(2, ['c-player']));
      await tester.pumpAndSettle();
      expect(find.text('Combat en préparation'), findsOneWidget);
      expect(
        find.text('Envoie ton initiative · Ouvrir le combat'),
        findsOneWidget,
      );
      now = now.add(const Duration(minutes: 10));
      await tester.pump(const Duration(minutes: 10));
      await tester.pumpAndSettle();
      // Grimoire expiré : le combat natif reprend sa place.
      expect(find.text('Combat en préparation'), findsNothing);
      expect(find.text('Combat en cours · round 1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await connectivity.close();
    });
  });

  group('« Lancer un combat » (décision 61)', () {
    testWidgets('désactivé avec l\'indice tant qu\'un combat Grimoire vit', (
      tester,
    ) async {
      final gateway = FakeGrimoireCombatGateway();
      final connectivity = FakeConnectivityChecker();
      final container = ProviderContainer(
        overrides: [
          currentUserFromTestOverride,
          combatRepositoryProvider.overrideWithValue(FakeCombatRepository()),
          connectivityCheckerProvider.overrideWithValue(connectivity),
          grimoireCombatGatewayProvider.overrideWithValue(gateway),
        ],
      );
      final GroupDetail detail = fakeGroupDetail();
      await _pump(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(combatProvider(groupId));
              return StartCombatSection(
                detail: detail,
                onOpenCombat: () {},
                onOpenSettings: () {},
              );
            },
          ),
        ),
      );
      final button = find.widgetWithText(PrimaryButton, 'LANCER UN COMBAT');
      expect(tester.widget<PrimaryButton>(button).onPressed, isNotNull);
      container
          .read(grimoireCombatProvider(groupId).notifier)
          .receive(gCombatStart(1));
      await tester.pumpAndSettle();
      expect(tester.widget<PrimaryButton>(button).onPressed, isNull);
      expect(find.text('Un combat est mené depuis Grimoire.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await connectivity.close();
    });
  });
}
