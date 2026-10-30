// Verification en conditions reelles (campagne QA du 30/10/2026) du chantier
// "masque les races indisponibles en 2024 + suggestions rapides sous Race
// personnalisée" (commit 3ae576c, race_step_screen.dart) :
// - edition 2024 : Demi-elfe/Demi-orc (traits2024 null) absents des listes
//   "RACES DE BASE"/"RACES D'EXTENSION", races disponibles (Elfe...)
//   inchangees ;
// - "Race personnalisée" selectionnee en 2024 : suggestions rapides
//   (ActionChip) pour ces deux races, un tap pre-remplit le champ texte
//   librement editable ensuite, la creation aboutit avec le texte final et
//   la fiche l'affiche ;
// - edition 2014 : comportement inchange (toutes affichees/selectionnables,
//   aucune suggestion sous "Race personnalisée").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';

import 'support/app_launch.dart';
import 'support/character_creation_flow.dart'
    show fillAbilityScoreRacialBonusIfPresent, fillAvailableCheckableTiles;
import 'support/qa_test_account.dart';
import 'support/tap_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openCharacterList(WidgetTester tester) async {
    await launchApp(tester);
    if (find.text('ENTRER DANS LA TAVERNE').evaluate().isNotEmpty) {
      await loginWithQaTestAccount(tester);
    }
    await tapTextIfPresent(tester, 'Passer');
    await pumpUntilSettled(tester, attempts: 6);
  }

  // Meme patron que level1_choices_at_creation_test.dart : defile par petits
  // pas en accumulant les titres deja vus (une tuile peut etre demontee une
  // fois trop loin du cache) jusqu'a ce qu'un defilement supplementaire n'en
  // revele plus aucun nouveau.
  Future<Set<String>> scrollAndCollectAllRaceTitles(
    WidgetTester tester,
    Finder listFinder, {
    int maxDrags = 30,
  }) async {
    final titles = <String>{};
    for (var i = 0; i < maxDrags; i++) {
      titles.addAll(
        tester
            .widgetList<SelectableOptionTile>(find.byType(SelectableOptionTile))
            .map((t) => t.title),
      );
      final beforeDrag = titles.length;
      await tester.drag(listFinder, const Offset(0, -250));
      await settleQuickly(tester);
      titles.addAll(
        tester
            .widgetList<SelectableOptionTile>(find.byType(SelectableOptionTile))
            .map((t) => t.title),
      );
      if (titles.length == beforeDrag) break;
    }
    return titles;
  }

  // Defile [listFinder] jusqu'a ce que [target] soit monte dans l'arbre de
  // widgets -- meme piege de montage paresseux documente dans
  // support/tap_helpers.dart::scrollUntilVisibleThenTap, mais ici pour un
  // finder generique (pas seulement find.text) : utilise pour le champ de
  // race personnalisee, identifie par son hintText (voir son usage) --
  // find.byType(TextField) seul serait ambigu avec le champ de recherche
  // (TextFormField, toujours monte, utilisant lui aussi un TextField en
  // interne).
  Future<void> scrollUntilFound(
    WidgetTester tester,
    Finder listFinder,
    Finder target, {
    int maxDrags = 15,
  }) async {
    for (var i = 0; i < maxDrags; i++) {
      if (target.evaluate().isNotEmpty) return;
      await tester.drag(listFinder, const Offset(0, -200));
      await settleQuickly(tester);
    }
  }

  testWidgets('edition 2024 : Demi-elfe/Demi-orc absents des listes de races, '
      'Elfe (race normale) reste selectionnable avec son flux habituel '
      'derriere (non-regression)', (tester) async {
    if (!hasQaTestAccount) {
      // ignore: avoid_print
      print('SKIP: $qaTestAccountMissingReason');
      return;
    }
    await openCharacterList(tester);

    await tapText(tester, '+ CRÉER');
    await pumpUntilSettled(tester, attempts: 6);

    // Etape 1/10 : Edition -- bascule sur 2024.
    await tapText(tester, '2024 — Manuel des Joueurs revu');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'SUIVANT');
    await pumpUntilSettled(tester, attempts: 4);

    // Etape 2/10 : Race -- collecte TOUS les titres en defilant
    // entierement la liste, pour ne pas confondre "jamais monte" avec
    // "reellement absent".
    final titles = await scrollAndCollectAllRaceTitles(
      tester,
      find.byType(ListView).first,
    );

    expect(
      titles.contains('Demi-elfe'),
      isFalse,
      reason:
          'Demi-elfe (traits2024 null) ne doit plus apparaitre du tout '
          'dans les listes de races en edition 2024. Titres collectes : '
          '$titles',
    );
    expect(
      titles.contains('Demi-orc'),
      isFalse,
      reason:
          'Demi-orc (traits2024 null) ne doit plus apparaitre du tout '
          'dans les listes de races en edition 2024. Titres collectes : '
          '$titles',
    );
    expect(
      titles.contains('Elfe'),
      isTrue,
      reason:
          'une race disponible en 2024 (Elfe) doit rester affichee '
          'normalement. Titres collectes : $titles',
    );

    // Non-regression : Elfe reste normalement selectionnable, "SUIVANT"
    // s'active, et le flux continue derriere (sous-race/lignee/classe
    // selon le catalogue) -- on ne verifie pas l'ecran exact suivant,
    // juste qu'on a bien quitte l'etape Race sans blocage ni crash.
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      'Elfe',
    );
    await pumpUntilSettled(tester, attempts: 4);
    await fillAbilityScoreRacialBonusIfPresent(tester);
    await tapText(tester, 'SUIVANT');
    await pumpUntilSettled(tester, attempts: 4);

    expect(
      find.text('2. Race'),
      findsNothing,
      reason:
          'apres avoir selectionne Elfe (race normale, disponible en '
          '2024) et tape SUIVANT, l\'assistant doit avoir quitte '
          'l\'etape Race (sous-race/lignee/classe selon le catalogue).',
    );

    // Aucune ecriture reseau n'a eu lieu a ce stade (le brouillon de
    // creation reste en memoire jusqu'a "CRÉER LE PERSONNAGE") -- rien a
    // nettoyer en base pour ce scenario.
  });

  testWidgets(
    'edition 2024, "Race personnalisée" : suggestions Demi-elfe/Demi-orc, '
    'un tap pre-remplit le champ texte, qui reste librement editable, la '
    'creation aboutit avec le texte final et la fiche l\'affiche',
    (tester) async {
      if (!hasQaTestAccount) {
        // ignore: avoid_print
        print('SKIP: $qaTestAccountMissingReason');
        return;
      }
      await openCharacterList(tester);

      await tapText(tester, '+ CRÉER');
      await pumpUntilSettled(tester, attempts: 6);

      // Etape 1/10 : Edition -- bascule sur 2024.
      await tapText(tester, '2024 — Manuel des Joueurs revu');
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);

      // Etape 2/10 : Race -- selectionne "Race personnalisée" (derniere
      // tuile de la liste, defilement necessaire).
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'Race personnalisée',
      );
      await pumpUntilSettled(tester, attempts: 4);

      expect(
        find.widgetWithText(ActionChip, 'Demi-elfe'),
        findsOneWidget,
        reason:
            'suggestion rapide attendue pour Demi-elfe (indisponible en '
            '2024) sous "Race personnalisée".',
      );
      expect(
        find.widgetWithText(ActionChip, 'Demi-orc'),
        findsOneWidget,
        reason:
            'suggestion rapide attendue pour Demi-orc (indisponible en '
            '2024) sous "Race personnalisée".',
      );

      // Un tap sur la suggestion "Demi-orc" pre-remplit le champ texte.
      await tapText(tester, 'Demi-orc');
      await pumpUntilSettled(tester, attempts: 4);

      // Identifie precisement par son hintText, PAS find.byType(TextField)
      // seul : le champ de recherche (TextFormField, toujours monte)
      // utilise aussi un TextField en interne -- une fois les deux montes,
      // byType seul matcherait les deux et serait ambigu.
      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Nom de la race personnalisée',
        description: 'champ de race personnalisée',
      );
      await scrollUntilFound(
        tester,
        find.byType(ListView).first,
        textFieldFinder,
      );
      await tester.ensureVisible(textFieldFinder);
      await settleQuickly(tester);
      expect(
        tester.widget<TextField>(textFieldFinder).controller!.text,
        'Demi-orc',
        reason: 'le tap sur la suggestion doit pre-remplir le champ texte.',
      );

      // Le champ reste librement editable APRES le tap -- pas reinitialise.
      // `tester.enterText(textFieldFinder, ...)` echoue de facon
      // reproductible sur cet ecran (`StateError: No element` leve DANS la
      // recherche interne de descendant `EditableText` de
      // `WidgetTester.showKeyboard` -- voir le compte-rendu QA de ce
      // chantier pour le detail des tentatives). Repli documente par
      // `WidgetTester.enterText` lui-meme pour ce cas ("first ensure that
      // widget has an open connection... then call testTextInput.enterText
      // directly") : un tap focalise le champ sans passer par cette
      // recherche instable, puis `testTextInput.enterText` simule la
      // saisie sans aucun finder.
      await tester.tap(textFieldFinder);
      await settleQuickly(tester);
      const editedRaceText = 'Demi-orc des Terres Brisees (QA)';
      tester.testTextInput.enterText(editedRaceText);
      await tester.pump();
      // Le clavier logiciel reel qui apparait au tap reduit le viewport et
      // peut faire defiler le `ListView` pour garder le champ focalise
      // visible -- re-garantit sa presence/visibilite apres coup plutot que
      // de supposer la position de defilement inchangee depuis le tap.
      await scrollUntilFound(
        tester,
        find.byType(ListView).first,
        textFieldFinder,
      );
      await settleQuickly(tester);
      expect(
        tester.widget<TextField>(textFieldFinder).controller!.text,
        editedRaceText,
        reason:
            'le champ de race personnalisée doit rester librement '
            'editable apres le tap sur une suggestion, sans etre '
            'reinitialise au nom suggere.',
      );

      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);
      // Race personnalisée : aucune etape sous-race/lignee, direct Classe.
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'Barbare',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);

      // Historique.
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'Acolyte',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);

      // Caracteristiques (Tableau standard par defaut). Contrairement a ce
      // que supposait la premiere version de ce test, une race
      // personnalisee propose AUSSI "Bonus racial au choix" en edition
      // 2024 (aucune table RAW n'existe pour une race inventee -- l'app
      // propose alors le meme choix flexible que les races RAW qui en
      // ont) : sans le resoudre ici, "SUIVANT" restait durablement
      // desactive et le reste du parcours tournait a vide sur cet ecran
      // (TextFormField jamais atteint au recapitulatif, voir le
      // compte-rendu QA de ce chantier).
      await fillAbilityScoreRacialBonusIfPresent(tester);
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);

      // Competences et outils.
      await fillAvailableCheckableTiles(tester);
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);

      // Sorts : Barbare non lanceur, etape sautee automatiquement.

      // Equipement de depart (onglet Historique par defaut).
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);

      // Apparence et histoire (champs optionnels).
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);

      // Recapitulatif -- meme repli que le champ de race personnalisee
      // ci-dessus (StateError reproductible avec le patron standard
      // tester.enterText sur CET ecran, voir le compte-rendu QA de ce
      // chantier) : tap pour focaliser, puis testTextInput.enterText
      // direct.
      final name = qaUniqueCharacterName('QA-Test-RaceCustomSuggestion');
      final nameFieldFinder = find.byType(TextFormField).first;
      await tester.tap(nameFieldFinder);
      await settleQuickly(tester);
      tester.testTextInput.enterText(name);
      await tester.pump();
      await tapText(tester, 'CRÉER LE PERSONNAGE');
      await pumpUntilSettled(tester, attempts: 10);

      // De retour sur la liste -- ouvre le personnage cree et verifie que
      // la fiche affiche bien le texte final (edite), pas le nom suggere
      // brut "Demi-orc".
      await tapText(tester, name);
      await pumpUntilSettled(tester, attempts: 6);

      expect(
        find.textContaining(editedRaceText),
        findsOneWidget,
        reason:
            'la fiche du personnage cree doit afficher le texte de race '
            'personnalisée final (edite apres le tap sur la suggestion), '
            'pas le nom suggere brut.',
      );

      // Nettoyage (meme regle que integration_test/README.md "Donnees de
      // test laissees en base") : revient a la liste puis supprime le
      // personnage de test cree par ce scenario.
      final backFinder = find.byIcon(Icons.arrow_back_ios_new);
      if (backFinder.evaluate().isNotEmpty) {
        await tester.tap(backFinder.first);
        await pumpUntilSettled(tester, attempts: 6);
      }
      if (find.text(name).evaluate().isNotEmpty) {
        await tester.longPress(find.text(name));
        await pumpUntilSettled(tester, attempts: 4);
        if (await tapTextIfPresent(tester, 'Supprimer le personnage')) {
          await pumpUntilSettled(tester, attempts: 4);
          await tapTextIfPresent(tester, 'Supprimer');
          await pumpUntilSettled(tester, attempts: 6);
        }
      } else {
        // ignore: avoid_print
        print(
          'NETTOYAGE MANUEL REQUIS : personnage de test "$name" cree par '
          'ce scenario, non retrouve sur la liste pour suppression '
          'automatique.',
        );
      }
    },
  );

  testWidgets(
    'edition 2014 : Demi-elfe/Demi-orc restent affiches et selectionnables '
    'normalement (comportement inchange), aucune suggestion sous "Race '
    'personnalisée"',
    (tester) async {
      if (!hasQaTestAccount) {
        // ignore: avoid_print
        print('SKIP: $qaTestAccountMissingReason');
        return;
      }
      await openCharacterList(tester);

      await tapText(tester, '+ CRÉER');
      await pumpUntilSettled(tester, attempts: 6);

      // Etape 1/10 : Edition -- 2014 deja preselectionnee par defaut.
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);

      // Etape 2/10 : Race.
      final titles = await scrollAndCollectAllRaceTitles(
        tester,
        find.byType(ListView).first,
      );
      expect(
        titles.contains('Demi-elfe'),
        isTrue,
        reason:
            'Demi-elfe doit rester affiche normalement en edition 2014. '
            'Titres collectes : $titles',
      );
      expect(
        titles.contains('Demi-orc'),
        isTrue,
        reason:
            'Demi-orc doit rester affiche normalement en edition 2014. '
            'Titres collectes : $titles',
      );

      // Selectionnable comme avant : le tap selectionne reellement la
      // tuile (pas de blocage), "SUIVANT" s'active.
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'Demi-elfe',
      );
      await pumpUntilSettled(tester, attempts: 4);
      final nextButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(
        nextButton.onPressed,
        isNotNull,
        reason:
            'Demi-elfe doit rester normalement selectionnable en edition '
            '2014 ("SUIVANT" actif apres selection).',
      );

      // "Race personnalisée" : aucune suggestion en 2014 (liste vide par
      // construction -- aucune race indisponible dans cette edition).
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'Race personnalisée',
      );
      await settleQuickly(tester);
      await pumpUntilSettled(tester, attempts: 4);
      expect(
        find.byType(ActionChip),
        findsNothing,
        reason:
            'aucune suggestion rapide ne doit apparaitre sous "Race '
            'personnalisée" en edition 2014.',
      );

      // Aucune ecriture reseau n'a eu lieu -- rien a nettoyer en base.
    },
  );
}
