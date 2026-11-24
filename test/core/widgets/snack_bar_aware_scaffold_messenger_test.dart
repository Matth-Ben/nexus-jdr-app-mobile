// Messager des `SnackBar` de l'app (`SnackBarAwareScaffoldMessenger`) : la
// `SnackBar` exposée suit la file réelle (masquer puis afficher comme
// `showUndoSnackBar`, `clearSnackBars` avec des `SnackBar` en attente,
// `removeCurrentSnackBar`) ; `snackBarTopIn` échoue en douceur (`null`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/snack_bar_aware_scaffold_messenger.dart';

SnackBar _snack(String text) => SnackBar(content: Text(text));

void main() {
  late SnackBarAwareScaffoldMessengerState messenger;
  late BuildContext page;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            SnackBarAwareScaffoldMessenger(child: child!),
        home: Builder(
          builder: (context) {
            page = context;
            return const Scaffold(body: Text('PAGE'));
          },
        ),
      ),
    );
    messenger = tester.state<SnackBarAwareScaffoldMessengerState>(
      find.byType(SnackBarAwareScaffoldMessenger),
    );
  }

  String? current() =>
      (messenger.currentSnackBar.value?.content as Text?)?.data;

  testWidgets('c\'est le messager des pages : ScaffoldMessenger.of(page)', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(identical(ScaffoldMessenger.of(page), messenger), isTrue);
    messenger.showSnackBar(_snack('A'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(current(), 'A');
  });

  testWidgets('masquer puis afficher (schéma de showUndoSnackBar) : la '
      'nouvelle devient courante quand l\'ancienne est fermée', (tester) async {
    await pumpApp(tester);
    messenger.showSnackBar(_snack('A'));
    await tester.pumpAndSettle();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(_snack('B'));
    expect(current(), 'A');
    await tester.pumpAndSettle();
    expect(current(), 'B');
    expect(find.text('B'), findsOneWidget);
    messenger.hideCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(current(), isNull);
  });

  testWidgets('clearSnackBars avec des SnackBar en attente : seule la '
      'courante se ferme, puis plus rien', (tester) async {
    await pumpApp(tester);
    messenger
      ..showSnackBar(_snack('A'))
      ..showSnackBar(_snack('B'))
      ..showSnackBar(_snack('C'));
    await tester.pumpAndSettle();
    expect(current(), 'A');
    messenger.clearSnackBars();
    expect(current(), 'A');
    await tester.pumpAndSettle();
    expect(current(), isNull);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsNothing);
  });

  testWidgets('removeCurrentSnackBar : la suivante prend la place', (
    tester,
  ) async {
    await pumpApp(tester);
    messenger
      ..showSnackBar(_snack('A'))
      ..showSnackBar(_snack('B'));
    await tester.pumpAndSettle();
    messenger.removeCurrentSnackBar();
    await tester.pump();
    expect(current(), 'B');
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    messenger.removeCurrentSnackBar();
    await tester.pump();
    expect(current(), isNull);
  });

  testWidgets('snackBarTopIn : haut de la SnackBar affichée ; null sans '
      'SnackBar dans la page, sans exception', (tester) async {
    await pumpApp(tester);
    final absent = _snack('absente');
    expect(snackBarTopIn(page, absent), isNull);

    final shown = _snack('A');
    messenger.showSnackBar(shown);
    await tester.pumpAndSettle();
    final top = snackBarTopIn(page, shown);
    expect(top, closeTo(tester.getRect(find.byType(SnackBar)).top, 0.5));
    expect(snackBarTopIn(page, absent), isNull);
  });

  testWidgets("page sans Scaffold par-dessus : la SnackBar n'y est pas, "
      'null, sans exception', (tester) async {
    await pumpApp(tester);
    late BuildContext bare;
    unawaited(
      Navigator.of(page).push(
        MaterialPageRoute<void>(
          builder: (context) {
            bare = context;
            return const ColoredBox(color: Colors.white, child: Text('NU'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final snackBar = _snack('A');
    messenger.showSnackBar(snackBar);
    await tester.pumpAndSettle();
    expect(current(), 'A');
    expect(snackBarTopIn(bare, snackBar), isNull);
    expect(tester.takeException(), isNull);
  });
}
