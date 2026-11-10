// Les composants partagés en police pixel (`AppTypography.display`) ne
// dépassent pas x1,3 avec la taille de police du système (décision du
// 10/11/2026), mais restent inchangés à police normale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_button.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/segmented_tab_bar.dart';
import 'package:personnages/core/widgets/segmented_toggle.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/core/widgets/wood_back_header.dart';

import 'display_scale_helpers.dart';

void main() {
  // (composant, texte réellement affiché dans le `Text`).
  final cases = <String, (Widget, String)>{
    'PrimaryButton': (
      PrimaryButton(label: 'Valider', onPressed: () {}),
      'VALIDER',
    ),
    'SecondaryButton': (
      SecondaryButton(label: 'Annuler', onPressed: () {}),
      'ANNULER',
    ),
    'DestructiveButton (plein)': (
      DestructiveButton(label: 'Supprimer', filled: true, onPressed: () {}),
      'SUPPRIMER',
    ),
    'DashedButton': (
      DashedButton(icon: Icons.add, label: 'Ajouter', onPressed: () {}),
      'Ajouter',
    ),
    'SegmentedTabBar': (
      SegmentedTabBar<int>(
        options: const [
          SegmentedTabBarOption(value: 1, label: 'Un'),
          SegmentedTabBarOption(value: 2, label: 'Deux'),
        ],
        value: 1,
        onChanged: (_) {},
      ),
      'UN',
    ),
    'SegmentedToggle': (
      SegmentedToggle<int>(
        options: const [
          SegmentedToggleOption(value: 1, label: 'Un'),
          SegmentedToggleOption(value: 2, label: 'Deux'),
        ],
        value: 1,
        onChanged: (_) {},
      ),
      'UN',
    ),
    'SheetHeaderBar': (const SheetHeaderBar(title: 'Titre'), 'Titre'),
    'WoodBackHeader': (WoodBackHeader(title: 'Fiche', onBack: () {}), 'Fiche'),
  };

  for (final entry in cases.entries) {
    final (widget, label) = entry.value;
    testWidgets('${entry.key} : x1,0 inchangé, x2,0 plafonné à x1,3', (
      tester,
    ) async {
      await pumpScaled(tester, widget, scale: 1);
      expect(find.text(label), findsOneWidget);
      expect(effectiveFontSize(tester, label, 11), closeTo(11, 0.01));

      await pumpScaled(tester, widget, scale: 2);
      expect(effectiveFontSize(tester, label, 11), closeTo(11 * 1.3, 0.01));
    });
  }

  testWidgets('DestructiveButton (contour, body) continue de grandir', (
    tester,
  ) async {
    await pumpScaled(
      tester,
      DestructiveButton(label: 'Supprimer', onPressed: () {}),
      scale: 2,
    );
    expect(effectiveFontSize(tester, 'Supprimer', 14), closeTo(28, 0.01));
  });
}
