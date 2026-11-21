// Grande taille de texte dans l'onglet « Membres » (D232) : à ×1, ×2 et ×3
// sur 320 dp, avec « Exclure » (vue du propriétaire) puis sans (vue d'un
// joueur). À partir de ×1,4 (`AppTypography.isLargeText`), la jauge PV est
// seule sur sa ligne, la fraction et la puce PV temporaires passent dessous,
// et « Exclure » descend en pied de carte ; sous le seuil, « Exclure » reste
// une icône 48×48 sur la rangée du nom.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_spacing.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/presentation/widgets/group_members_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../../core/widgets/display_scale_helpers.dart';

const _owner = GroupMember(
  characterId: 'char-owner',
  userId: 'user-owner',
  role: GroupRole.owner,
  name: 'Brunhilde',
  isGameMaster: false,
  level: 3,
  currentHp: 20,
  maxHp: 24,
  temporaryHp: 0,
  isDead: false,
);

/// « 15/18 ».
const _hurt = GroupMember(
  characterId: 'char-hurt',
  userId: 'user-hurt',
  role: GroupRole.membre,
  name: 'Eldrin',
  isGameMaster: false,
  level: 3,
  currentHp: 15,
  maxHp: 18,
  temporaryHp: 0,
  isDead: false,
  armorClass: 16,
  armorClassBonus: 0,
);

/// « 120/120 » avec 5 PV temporaires (risque (b) de la DA).
const _tough = GroupMember(
  characterId: 'char-tough',
  userId: 'user-tough',
  role: GroupRole.membre,
  name: 'Garrick',
  isGameMaster: false,
  level: 12,
  currentHp: 120,
  maxHp: 120,
  temporaryHp: 5,
  isDead: false,
  armorClass: 18,
  armorClassBonus: 2,
);

/// Trois états.
const _afflicted = GroupMember(
  characterId: 'char-afflicted',
  userId: 'user-afflicted',
  role: GroupRole.membre,
  name: 'Lyra',
  isGameMaster: false,
  level: 4,
  currentHp: 9,
  maxHp: 22,
  temporaryHp: 0,
  isDead: false,
  armorClass: 13,
  armorClassBonus: 0,
  conditions: [
    ConditionType.blinded,
    ConditionType.poisoned,
    ConditionType.prone,
  ],
);

const _dead = GroupMember(
  characterId: 'char-dead',
  userId: 'user-dead',
  role: GroupRole.membre,
  name: 'Thorin',
  isGameMaster: false,
  level: 5,
  currentHp: 0,
  maxHp: 30,
  temporaryHp: 0,
  isDead: true,
  armorClass: 17,
  armorClassBonus: 0,
);

/// Carte orpheline (risque (a) de la DA).
const _orphan = GroupMember(
  userId: 'user-orphan',
  role: GroupRole.membre,
  name: 'Orphée',
  isGameMaster: false,
);

const _gameMaster = GroupMember(
  userId: 'user-gm',
  role: GroupRole.membre,
  name: 'Oswald',
  isGameMaster: true,
);

const _members = [
  _owner,
  _hurt,
  _tough,
  _afflicted,
  _dead,
  _orphan,
  _gameMaster,
];

/// Membres dont la carte montre une fraction PV.
const _withHp = [_hurt, _tough, _afflicted, _dead];

/// Membres que le propriétaire peut exclure.
const _removable = [_hurt, _tough, _afflicted, _dead, _orphan, _gameMaster];

GroupDetail _detail({
  required bool ownerView,
  List<GroupMember> members = _members,
}) => GroupDetail(
  id: 'group-1',
  name: 'Les Lames de l’Aube',
  ownerId: 'user-owner',
  inviteCode: 'ABC123',
  // Vue d'un joueur : Eldrin regarde le groupe, aucun « Exclure ».
  currentUserId: ownerView ? 'user-owner' : 'user-hurt',
  members: members,
);

Future<void> _pump(
  WidgetTester tester,
  GroupDetail detail, {
  void Function(GroupMember member)? onRemoveMember,
  String? removingUserId,
  Locale locale = const Locale('fr'),
}) async {
  final router = GoRouter(
    initialLocation: '/group',
    routes: [
      GoRoute(
        path: '/group',
        builder: (context, state) => Scaffold(
          body: GroupMembersTabBody(
            detail: detail,
            onRemoveMember: onRemoveMember ?? (_) {},
            onLeaveGroup: () {},
            removingUserId: removingUserId,
          ),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: router,
    ),
  );
  // L'indicateur d'exclusion en cours tourne sans fin : pas de
  // `pumpAndSettle` dans ce cas (le routeur se résout en deux images).
  if (removingUserId == null) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

Finder _removeButton(GroupMember member) =>
    find.byKey(ValueKey('removeMember-${member.userId}'));

Finder _fraction(GroupMember member) =>
    find.text('${member.currentHp}/${member.maxHp}');

/// Nom affiché sur la carte de [member] (« MJ - » compris pour le MJ).
Finder _name(GroupMember member) =>
    find.textContaining(member.name, findRichText: true).first;

/// Encadré de la carte qui contient [finder] (seul `Container` de la carte
/// rembourré de `AppSpacing.md` sur les quatre côtés).
Finder _cardOf(Finder finder) => find
    .ancestor(
      of: finder,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container && w.padding == const EdgeInsets.all(AppSpacing.md),
      ),
    )
    .first;

Finder _gaugeOf(Finder card) => find.descendant(
  of: card,
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).color == AppColors.gaugeTrack,
  ),
);

/// [inner] est entièrement dans [outer] (à un demi-pixel près).
void _expectInside(Rect inner, Rect outer, String reason) {
  expect(
    inner.left >= outer.left - 0.5 &&
        inner.top >= outer.top - 0.5 &&
        inner.right <= outer.right + 0.5 &&
        inner.bottom <= outer.bottom + 0.5,
    isTrue,
    reason: '$reason : $inner hors de $outer',
  );
}

/// La fraction PV est entière (une seule ligne, rien de rogné) et à
/// l'intérieur de sa carte, elle-même à l'intérieur de l'écran.
void _expectWholeFraction(WidgetTester tester, GroupMember member) {
  final finder = _fraction(member);
  expect(finder, findsOneWidget, reason: member.name);
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: finder, matching: find.byType(RichText)),
  );
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: TextDirection.ltr,
    textScaler: paragraph.textScaler,
  )..layout();
  expect(
    paragraph.size.width,
    greaterThanOrEqualTo(painter.width - 0.5),
    reason: '${member.name} : fraction coupée',
  );
  expect(
    paragraph.size.height,
    lessThanOrEqualTo(painter.height + 0.5),
    reason: '${member.name} : fraction sur plusieurs lignes',
  );
  painter.dispose();
  final card = tester.getRect(_cardOf(finder));
  _expectInside(tester.getRect(finder), card, '${member.name} : fraction');
  final screen = Offset.zero & tester.view.physicalSize;
  _expectInside(card, screen, '${member.name} : carte');
}

/// Libellés lus par le lecteur d'écran, dans l'ordre de parcours.
List<String> _readingOrder(WidgetTester tester) => [
  for (final node in tester.semantics.simulatedAccessibilityTraversal())
    node.label,
];

/// Position du premier libellé lu qui contient [text].
int _indexOf(List<String> labels, String text) {
  final index = labels.indexWhere((label) => label.contains(text));
  expect(index, isNonNegative, reason: '« $text » absent de $labels');
  return index;
}

void main() {
  for (final scale in [1.0, 2.0, 3.0]) {
    for (final ownerView in [true, false]) {
      final view = ownerView ? 'avec « Exclure »' : 'sans « Exclure »';
      testWidgets('x$scale sur 320 dp, $view : aucun débordement, fractions '
          'entières dans leur carte', (tester) async {
        await useScaledView(tester, scale: scale, width: 320, height: 6000);
        await _pump(tester, _detail(ownerView: ownerView));

        expect(tester.takeException(), isNull);
        for (final member in _withHp) {
          _expectWholeFraction(tester, member);
        }
        expect(find.text('+5 PV temp.'), findsOneWidget);
        expect(find.text("En attente d'un personnage"), findsOneWidget);
        expect(find.text('Ne suit pas ses PV ici.'), findsOneWidget);
        expect(find.text('MORT'), findsOneWidget);
        for (final member in _removable) {
          expect(
            _removeButton(member),
            ownerView ? findsOneWidget : findsNothing,
            reason: member.name,
          );
        }
        // Jamais sur sa propre carte.
        expect(_removeButton(_owner), findsNothing);
      });
    }

    testWidgets('x$scale sur 320 dp : cible « Exclure » d\'au moins 48×48', (
      tester,
    ) async {
      await useScaledView(tester, scale: scale, width: 320, height: 6000);
      await _pump(tester, _detail(ownerView: true));

      for (final member in _removable) {
        final size = tester.getSize(_removeButton(member));
        expect(size.width, greaterThanOrEqualTo(48), reason: member.name);
        expect(size.height, greaterThanOrEqualTo(48), reason: member.name);
      }
    });
  }

  testWidgets('x1 sur 320 dp : « Exclure » en icône sur la rangée du nom, '
      'fraction sur la ligne de la jauge, puce PV temp. dessous', (
    tester,
  ) async {
    await useScaledView(tester, scale: 1, width: 320, height: 6000);
    await _pump(tester, _detail(ownerView: true));

    for (final member in _removable) {
      final button = tester.getRect(_removeButton(member));
      final name = tester.getRect(_name(member));
      expect(
        button.top < name.bottom && button.bottom > name.top,
        isTrue,
        reason: '${member.name} : « Exclure » hors de la rangée du nom',
      );
      expect(button.left, greaterThanOrEqualTo(name.right - 0.5));
      expect(
        find.descendant(
          of: _removeButton(member),
          matching: find.text('Exclure'),
        ),
        findsNothing,
        reason: '${member.name} : icône seule sous le seuil',
      );
      expect(
        find.descendant(
          of: _removeButton(member),
          matching: find.byIcon(Icons.person_remove_outlined),
        ),
        findsOneWidget,
      );
    }
    for (final member in _withHp) {
      final fraction = tester.getRect(_fraction(member));
      final gauge = tester.getRect(_gaugeOf(_cardOf(_fraction(member))));
      expect(
        (fraction.center.dy - gauge.center.dy).abs(),
        lessThan(fraction.height / 2),
        reason: '${member.name} : fraction hors de la ligne de la jauge',
      );
      expect(fraction.left, greaterThan(gauge.right));
    }
    final chip = tester.getRect(find.text('+5 PV temp.'));
    expect(
      chip.top,
      greaterThanOrEqualTo(tester.getRect(_fraction(_tough)).bottom),
    );
  });

  for (final scale in [2.0, 3.0]) {
    testWidgets('x$scale sur 320 dp : jauge seule, fraction dessous, '
        '« Exclure » en pied de carte, aligné à droite', (tester) async {
      await useScaledView(tester, scale: scale, width: 320, height: 6000);
      await _pump(tester, _detail(ownerView: true));

      for (final member in _withHp) {
        final card = _cardOf(_fraction(member));
        final cardRect = tester.getRect(card);
        final gauge = tester.getRect(_gaugeOf(card));
        final fraction = tester.getRect(_fraction(member));
        final link = tester.getRect(_removeButton(member));
        expect(
          fraction.top,
          greaterThanOrEqualTo(gauge.bottom),
          reason: '${member.name} : fraction à côté de la jauge',
        );
        // Jauge sur toute la largeur de la colonne (bord droit de la carte,
        // moins sa marge intérieure et sa bordure).
        expect(
          cardRect.right - gauge.right,
          lessThanOrEqualTo(AppSpacing.md + 3 + 0.5),
          reason: member.name,
        );
        expect(
          link.top,
          greaterThanOrEqualTo(fraction.bottom),
          reason: '${member.name} : « Exclure » pas sous la fraction',
        );
        expect(
          cardRect.right - link.right,
          lessThanOrEqualTo(AppSpacing.md + 3 + 0.5),
          reason: '${member.name} : « Exclure » pas aligné à droite',
        );
        expect(
          find.descendant(
            of: _removeButton(member),
            matching: find.text('Exclure'),
          ),
          findsOneWidget,
        );
      }
      // Après le badge de statut.
      expect(
        tester.getRect(_removeButton(_dead)).top,
        greaterThanOrEqualTo(tester.getRect(find.text('MORT')).bottom),
      );
      // Puce PV temp. dans la ligne de la fraction (ou la suivante).
      expect(
        tester.getRect(find.text('+5 PV temp.')).top,
        greaterThanOrEqualTo(
          tester.getRect(_gaugeOf(_cardOf(_fraction(_tough)))).bottom,
        ),
      );
      // Cartes MJ et orpheline : même pied de carte.
      expect(
        tester.getRect(_removeButton(_gameMaster)).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text('Ne suit pas ses PV ici.')).bottom,
        ),
      );
      expect(
        tester.getRect(_removeButton(_orphan)).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text("En attente d'un personnage")).bottom,
        ),
      );
    });
  }

  testWidgets('x3 sur 320 dp : toucher « Exclure » appelle onRemoveMember', (
    tester,
  ) async {
    await useScaledView(tester, scale: 3, width: 320, height: 6000);
    final removed = <GroupMember>[];
    await _pump(tester, _detail(ownerView: true), onRemoveMember: removed.add);

    for (final member in [_tough, _orphan, _gameMaster]) {
      await tester.tap(_removeButton(member));
      await tester.pump();
    }

    expect(removed, [_tough, _orphan, _gameMaster]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'en anglais : lien « Remove », lecteur d\'écran « Remove {nom} »',
    (tester) async {
      final handle = tester.ensureSemantics();
      await useScaledView(tester, scale: 3, width: 320, height: 6000);
      await _pump(
        tester,
        _detail(ownerView: true, members: const [_owner, _hurt]),
        locale: const Locale('en'),
      );

      expect(
        find.descendant(
          of: _removeButton(_hurt),
          matching: find.text('Remove'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(_removeButton(_hurt)),
        isSemantics(label: 'Remove Eldrin', isButton: true),
      );
      handle.dispose();
    },
  );

  // Le nom, les PV, la CA et le statut sont lus avec la carte (un seul nœud,
  // dans cet ordre) ; les états (`ConditionsZone`, nœud distinct depuis P6)
  // juste après ; « Exclure » toujours en dernier, y compris sous le seuil où
  // le bouton est en haut à droite de la carte.
  group('ordre de lecture : la carte (nom, PV, CA, statut), les états, puis '
      '« Exclure »', () {
    final member = _dead.copyWith(
      conditions: const [ConditionType.blinded, ConditionType.poisoned],
    );

    for (final scale in [1.0, 3.0]) {
      testWidgets('x$scale', (tester) async {
        final handle = tester.ensureSemantics();
        await useScaledView(tester, scale: scale, width: 320, height: 6000);
        await _pump(
          tester,
          _detail(ownerView: true, members: [_owner, member]),
        );

        final labels = _readingOrder(tester);
        final card = _indexOf(labels, 'Thorin');
        expect(
          labels[card],
          'Thorin\n0/30\nCA 17\nMORT',
          reason: 'nom, PV, CA et statut, dans cet ordre',
        );
        final conditions = _indexOf(labels, 'États actifs : Aveuglé');
        final remove = _indexOf(labels, 'Exclure Thorin');
        expect(conditions, greaterThan(card), reason: '$labels');
        expect(remove, greaterThan(conditions), reason: '$labels');
        // Plus rien de la carte après « Exclure » (pastilles comprises).
        expect(
          labels
              .skip(remove + 1)
              .where(
                (label) =>
                    label.contains('Aveuglé') ||
                    label.contains('Empoisonné') ||
                    label.contains('Thorin'),
              ),
          isEmpty,
          reason: '$labels',
        );
        handle.dispose();
      });
    }
  });

  group('exclusion en cours', () {
    for (final scale in [1.0, 3.0]) {
      testWidgets('x$scale : « Exclure » désactivé, indicateur de 20 dp à la '
          'place de l\'icône, même emprise, libellé dédié', (tester) async {
        final handle = tester.ensureSemantics();
        await useScaledView(tester, scale: scale, width: 320, height: 6000);
        final removed = <GroupMember>[];
        final detail = _detail(ownerView: true);
        await _pump(tester, detail, onRemoveMember: removed.add);
        final idleSize = tester.getSize(_removeButton(_hurt));

        // Nouvelle appli (et nouveau routeur) pour l'état « en cours ».
        await tester.pumpWidget(const SizedBox.shrink());
        await _pump(
          tester,
          detail,
          onRemoveMember: removed.add,
          removingUserId: _hurt.userId,
        );

        final button = _removeButton(_hurt);
        expect(tester.getSize(button), idleSize);
        final indicator = find.descendant(
          of: button,
          matching: find.byType(CircularProgressIndicator),
        );
        expect(indicator, findsOneWidget);
        expect(tester.getSize(indicator), const Size(20, 20));
        final progress = tester.widget<CircularProgressIndicator>(indicator);
        expect(progress.strokeWidth, 2);
        expect(progress.color, AppColors.woodMedium);
        expect(
          find.descendant(
            of: button,
            matching: find.byIcon(Icons.person_remove_outlined),
          ),
          findsNothing,
        );
        expect(
          tester.getSemantics(button),
          isSemantics(
            label: 'Exclusion de Eldrin en cours',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            hasTapAction: false,
          ),
        );
        // Les autres membres restent excluables.
        expect(
          find.descendant(
            of: _removeButton(_tough),
            matching: find.byIcon(Icons.person_remove_outlined),
          ),
          findsOneWidget,
        );

        // Le toucher ne passe pas non plus à la carte (fiche du membre).
        await tester.tap(button);
        await tester.pump();
        await tester.pump();
        expect(removed, isEmpty);
        expect(find.byType(GroupMembersTabBody), findsOneWidget);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }
  });
}
