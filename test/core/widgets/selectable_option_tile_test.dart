import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 300, child: child)),
);

void main() {
  const longSubtitle =
      'Une description très longue qui ne tient jamais sur une seule ligne '
      'dans une tuile de 300 pixels de large, et doit donc être tronquée ou '
      'bien affichée en entier selon le réglage demandé.';

  testWidgets('par défaut, le sous-titre est tronqué à une ligne', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SelectableOptionTile(
          title: 'Titre',
          subtitle: longSubtitle,
          selected: false,
          onTap: () {},
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(longSubtitle));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('subtitleMaxLines null : sous-titre entier, tuile agrandie', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SelectableOptionTile(
          title: 'Titre',
          subtitle: longSubtitle,
          subtitleMaxLines: null,
          selected: false,
          onTap: () {},
        ),
      ),
    );
    final expandedHeight = tester.getSize(find.byType(SelectableOptionTile));

    await tester.pumpWidget(
      _wrap(
        SelectableOptionTile(
          title: 'Titre',
          subtitle: longSubtitle,
          selected: false,
          onTap: () {},
        ),
      ),
    );
    final truncatedHeight = tester.getSize(find.byType(SelectableOptionTile));

    expect(expandedHeight.height, greaterThan(truncatedHeight.height));
    expect(truncatedHeight.height, greaterThanOrEqualTo(44));
  });
}
