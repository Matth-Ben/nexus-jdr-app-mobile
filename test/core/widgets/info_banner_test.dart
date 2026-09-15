import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/info_banner.dart';

void main() {
  testWidgets('affiche le message et l\'icône fournis, non interactif '
      '(pas d\'InkWell)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoBanner(
            icon: Icons.smartphone_outlined,
            message: "Compte lié à l'app Histoires",
          ),
        ),
      ),
    );

    expect(find.text("Compte lié à l'app Histoires"), findsOneWidget);
    expect(find.byIcon(Icons.smartphone_outlined), findsOneWidget);
    expect(
      find.byType(InkWell),
      findsNothing,
      reason: 'ce bandeau est non interactif, jamais de zone de tap',
    );
  });

  testWidgets('InfoBanner.success affiche le message et une puce ronde pleine '
      '(Icons.circle) plutôt que l\'icône du variant par défaut', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InfoBanner.success(message: 'Partage actif')),
      ),
    );

    expect(find.text('Partage actif'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);

    final icon = tester.widget<Icon>(find.byIcon(Icons.circle));
    expect(icon.color, AppColors.accentTeal);
    expect(icon.size, 8);

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFE7F0E9));
    expect((decoration.border! as Border).top.color, AppColors.accentTeal);
  });
}
