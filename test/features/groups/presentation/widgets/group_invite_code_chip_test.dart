// Tests de widget de `GroupInviteCodeChip` — pastille de code d'invitation
// copiable d'un toucher (demande utilisateur, 2026-09-27), voir sa doc de
// classe. Couvre aussi la traduction (chantier "traduction de l'app" Phase B,
// lot "Groups — rejoindre/créer").

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/presentation/widgets/group_invite_code_chip.dart';
import 'package:personnages/l10n/app_localizations.dart';

Widget _buildWidget(String code, {Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: GroupInviteCodeChip(code: code)),
  );
}

void main() {
  testWidgets('affiche le code et le copie au toucher', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_buildWidget('ABC123'));

    expect(find.text('ABC123'), findsOneWidget);
    await tester.tap(find.text('ABC123'));
    await tester.pumpAndSettle();

    expect(copied, 'ABC123');
    expect(find.text('Code ABC123 copié.'), findsOneWidget);
  });

  testWidgets('le label sémantique mentionne le code', (tester) async {
    await tester.pumpWidget(_buildWidget('ABC123'));

    expect(
      find.bySemanticsLabel("Copier le code d'invitation ABC123"),
      findsOneWidget,
    );
  });

  group('traduction anglaise', () {
    testWidgets('copie et label sémantique en anglais', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        _buildWidget('ABC123', locale: const Locale('en')),
      );

      expect(find.bySemanticsLabel('Copy invite code ABC123'), findsOneWidget);

      await tester.tap(find.text('ABC123'));
      await tester.pumpAndSettle();

      expect(find.text('Code ABC123 copied.'), findsOneWidget);
    });
  });
}
