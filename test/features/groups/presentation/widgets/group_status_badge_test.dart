// Tests de `GroupStatusBadge` — pastille compacte de statut priorisé
// affichée sur `_GroupRow` (`group_list_screen.dart`), voir la doc de
// classe de ce widget pour le rationale complet (priorité stricte, jamais
// de cumul, chantier F03 `docs/retours-utilisateurs.md`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/features/groups/presentation/widgets/group_status_badge.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets(
    'deadCount et lowHpCount tous les deux à 0 : aucun badge affiché',
    (tester) async {
      await _pump(
        tester,
        const GroupStatusBadge(deadCount: 0, lowHpCount: 0),
      );

      expect(find.byType(Container), findsNothing);
      expect(find.byType(Text), findsNothing);
    },
  );

  testWidgets(
    'deadCount > 0 et lowHpCount == 0 : affiche "X MORT(S)" au singulier',
    (tester) async {
      await _pump(
        tester,
        const GroupStatusBadge(deadCount: 1, lowHpCount: 0),
      );

      expect(find.text('1 MORT'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    },
  );

  testWidgets(
    'deadCount > 1 : affiche "X MORTS" au pluriel',
    (tester) async {
      await _pump(
        tester,
        const GroupStatusBadge(deadCount: 3, lowHpCount: 0),
      );

      expect(find.text('3 MORTS'), findsOneWidget);
    },
  );

  testWidgets(
    'deadCount == 0 et lowHpCount > 0 : affiche "X PV BAS" avec l\'icône '
    "d'avertissement",
    (tester) async {
      await _pump(
        tester,
        const GroupStatusBadge(deadCount: 0, lowHpCount: 2),
      );

      expect(find.text('2 PV BAS'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'deadCount > 0 ET lowHpCount > 0 : "X MORT(S)" prioritaire, jamais cumulé '
    'avec "PV bas" (avis direction-artistique du comité de revue F03)',
    (tester) async {
      await _pump(
        tester,
        const GroupStatusBadge(deadCount: 1, lowHpCount: 2),
      );

      expect(find.text('1 MORT'), findsOneWidget);
      expect(find.textContaining('PV BAS'), findsNothing);
    },
  );

  testWidgets(
    'badge "mort" : fond alertBannerBackground, bordure accentBrick (même '
    'gabarit que `_StatusBadge` de `group_members_tab_body.dart`)',
    (tester) async {
      await _pump(
        tester,
        const GroupStatusBadge(deadCount: 1, lowHpCount: 0),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.alertBannerBackground);
      expect(decoration.border!.top.color, AppColors.accentBrick);

      final text = tester.widget<Text>(find.text('1 MORT'));
      expect(text.style?.color, AppColors.accentBrick);
    },
  );

  testWidgets(
    'badge "PV bas" : fond statusUnconsciousBackground, bordure '
    'statusUnconsciousAccent (même gabarit que `_StatusBadge` pour '
    '"INCONSCIENT")',
    (tester) async {
      await _pump(
        tester,
        const GroupStatusBadge(deadCount: 0, lowHpCount: 2),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.statusUnconsciousBackground);
      expect(decoration.border!.top.color, AppColors.statusUnconsciousAccent);

      final text = tester.widget<Text>(find.text('2 PV BAS'));
      expect(text.style?.color, AppColors.statusUnconsciousAccent);
    },
  );
}
