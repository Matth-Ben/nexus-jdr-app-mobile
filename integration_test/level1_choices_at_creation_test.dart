// Verification en conditions reelles de la consigne de campagne QA
// (21/10/2026, D99/D100/D102 de docs/dette-technique.md) : Guerrier (Style
// de combat), Rodeur (Ennemi jure), Roublard (Expertise, sans "outils de
// voleur" -- D100) et Ensorceleur Lignage draconique (Ancetre draconique,
// 10 types de dragon maintenant peuples en base -- D95) doivent tous se
// voir proposer leur second choix de niveau 1 DES LA CREATION, pas
// seulement au multiclassage tardif.
//
// Ecrit a l'origine (21/10/2026) sans reutiliser
// support/character_creation_flow.dart::createCharacter : au moment de ce
// chantier (D99), ce helper partage ne gerait ni ClassChoiceStepScreen
// (Guerrier/Rodeur juste apres la Classe, Roublard juste apres Competences
// et outils) ni le second SelectableOptionTile de SubclassFeatureChoiceBlock
// (Ancetre draconique) -- aucun des deux n'existait avant ce correctif.
// `createCharacter` gere maintenant les deux (correctif D108, meme nuit,
// docs/dette-technique.md) -- mais ce fichier garde volontairement SA PROPRE
// implementation minimale du parcours jusqu'au choix inclus (plutot que de
// l'appeler) : contrairement aux ~13 fichiers `level_up_*`/`multiclass_*`
// qui veulent juste AVANCER au plus vite jusqu'a la montee de niveau,
// chaque scenario ici doit explicitement INSPECTER l'ecran intermediaire
// (texte affiche, nombre d'options, absence d'option RAW-fausse) avant de
// faire son choix -- ce que `createCharacter`/`_resolveClassChoiceStepScreenIfPresent`
// font volontairement en boite noire (resolution automatique, aucune
// assertion). Les deux chemins restent donc legitimement distincts, pas un
// risque de divergence a corriger : `createCharacter` reste la seule source
// de verite sur COMMENT franchir ces ecrans en boite noire, ce fichier sur
// CE QU'ils doivent afficher.
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:personnages/core/widgets/checkable_option_tile.dart";
import "package:personnages/core/widgets/selectable_option_tile.dart";
import "package:personnages/features/character_creation/presentation/widgets/subclass_feature_choice_block.dart";

import "support/app_launch.dart";
import "support/character_creation_flow.dart"
    show fillAbilityScoreRacialBonusIfPresent, fillAvailableCheckableTiles;
import "support/qa_test_account.dart";
import "support/tap_helpers.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Correctif D112 (`docs/dette-technique.md`) : compter directement
  // `tester.widgetList<SelectableOptionTile>(...)` SANS defiler prealablement
  // ne voit que les tuiles deja montees dans le `cacheExtent` initial d'un
  // `ListView` long (meme piege de montage paresseux que
  // `support/tap_helpers.dart::scrollUntilVisibleThenTap` -- observe en
  // conditions reelles pour "Ennemi jure" : 7 options montees sur 13
  // attendues sans defilement). [listFinder] est deroule par petits pas en
  // accumulant les titres DEJA vus dans un `Set` (une tuile peut etre
  // demontee une fois trop loin du cache -- l'union cumulee reste robuste a
  // sa disparition ulterieure, contrairement a un simple comptage instantane)
  // jusqu'a ce qu'un defilement supplementaire n'en revele plus aucun nouveau
  // -- meme logique de detection de fin de liste que
  // `character_creation_flow.dart::fillAvailableCheckableTiles`
  // (comparaison des titres avant/apres defilement).
  Future<Set<String>> scrollAndCollectAllSelectableOptionTitles(
    WidgetTester tester,
    Finder listFinder, {
    int maxDrags = 25,
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

  Future<void> openCharacterList(WidgetTester tester) async {
    await launchApp(tester);
    if (find.text("ENTRER DANS LA TAVERNE").evaluate().isNotEmpty) {
      await loginWithQaTestAccount(tester);
    }
    await tapTextIfPresent(tester, "Passer");
    await pumpUntilSettled(tester, attempts: 6);
  }

  Future<void> startCreationUpToClassChoice(
    WidgetTester tester,
    String className,
  ) async {
    await tapText(tester, "+ CRÉER");
    await pumpUntilSettled(tester, attempts: 6);

    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      "Humain",
    );
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);

    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      className,
    );
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);
  }

  Future<void> finishCreationFromBackgroundStep(
    WidgetTester tester,
    String characterName,
  ) async {
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      "Acolyte",
    );
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);

    await fillAbilityScoreRacialBonusIfPresent(tester);
    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);

    await fillAvailableCheckableTiles(tester);
    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);

    // Etape 6/9 : Sorts (seulement classe lanceuse, sautee sinon) --
    // correctif D114 (docs/dette-technique.md) : meme logique que
    // support/character_creation_flow.dart::createCharacter (commentaire
    // "Etape 6/9 : Sorts"), jamais appliquee ici avant ce correctif -- sans
    // effet pour Guerrier/Rodeur (aucune des deux etiquettes n'est montee),
    // necessaire pour Ensorceleur (D95/D99).
    if (find.text("SORTS MINEURS CONNUS").evaluate().isNotEmpty ||
        find.text("SORTS DE NIVEAU 1 CONNUS").evaluate().isNotEmpty) {
      await fillAvailableCheckableTiles(tester);
      if (await tapTextIfPresent(tester, "Niveau 1")) {
        await pumpUntilSettled(tester, attempts: 4);
        await fillAvailableCheckableTiles(tester);
      }
      await tapText(tester, "SUIVANT");
      await pumpUntilSettled(tester, attempts: 4);
    }

    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);

    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);

    await tester.enterText(find.byType(TextFormField).first, characterName);
    await tester.pump();
    await tapText(tester, "CRÉER LE PERSONNAGE");
    await pumpUntilSettled(tester, attempts: 10);
  }

  testWidgets("Guerrier : Style de combat propose des la creation (D99)", (
    tester,
  ) async {
    if (!hasQaTestAccount) {
      // ignore: avoid_print
      print("SKIP: $qaTestAccountMissingReason");
      return;
    }
    await openCharacterList(tester);
    await startCreationUpToClassChoice(tester, "Guerrier");

    expect(
      find.textContaining("Ce choix se fait dès le niveau 1").evaluate(),
      isNotEmpty,
      reason:
          "BUG a transmettre a dev-flutter : le Guerrier ne se voit pas "
          "proposer son second choix de niveau 1 (Style de combat) "
          "directement apres le choix de classe a la creation.",
    );
    final options = tester
        .widgetList<SelectableOptionTile>(find.byType(SelectableOptionTile))
        .map((t) => t.title)
        .toList();
    // ignore: avoid_print
    print("OBSERVATION Style de combat (options proposees) : $options");
    expect(options, isNotEmpty);

    await tapText(tester, options.first);
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);

    // Horodate (D109, docs/dette-technique.md) : evite un doublon en base a
    // chaque relance de ce fichier.
    final name = qaUniqueCharacterName("QA-Test-Guerrier-D99");
    await finishCreationFromBackgroundStep(tester, name);

    expect(
      find.text(name).evaluate(),
      isNotEmpty,
      reason:
          "BUG a transmettre a dev-flutter : apres le choix de Style de "
          "combat, la creation du Guerrier ne revient jamais sur la liste "
          "des personnages (ecran bloque, voir les logs ci-dessus).",
    );
  });

  testWidgets("Rodeur : Ennemi jure propose des la creation (D99)", (
    tester,
  ) async {
    if (!hasQaTestAccount) {
      // ignore: avoid_print
      print("SKIP: $qaTestAccountMissingReason");
      return;
    }
    await openCharacterList(tester);
    await startCreationUpToClassChoice(tester, "Rôdeur");

    expect(
      find.textContaining("Ce choix se fait dès le niveau 1").evaluate(),
      isNotEmpty,
      reason:
          "BUG a transmettre a dev-flutter : le Rodeur ne se voit pas "
          "proposer son second choix de niveau 1 (Ennemi jure) "
          "directement apres le choix de classe a la creation.",
    );
    final options = (await scrollAndCollectAllSelectableOptionTitles(
      tester,
      find.byType(ListView).first,
    )).toList();
    // ignore: avoid_print
    print("OBSERVATION Ennemi jure (options proposees) : $options");
    expect(options, isNotEmpty);
    expect(
      options.length,
      13,
      reason:
          "BUG a transmettre a dev-flutter (ou regression du correctif "
          "D101) : LevelUpChoiceOptions.favoredEnemies ne compte pas 13 "
          "options.",
    );

    // Correctif D114 (docs/dette-technique.md) : a ce stade la liste a ete
    // defilee jusqu'en bas par [scrollAndCollectAllSelectableOptionTitles]
    // ci-dessus pour collecter les 13 titres -- `options.first`
    // ("Aberrations", 1ere option alphabetique) n'est donc plus montee dans
    // l'arbre de widgets. [scrollUntilVisibleThenTap] (et non [tapText] nu)
    // redefile au besoin jusqu'a ce qu'elle soit a nouveau visible.
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      options.first,
    );
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, "SUIVANT");
    await pumpUntilSettled(tester, attempts: 4);

    // Horodate (D109, docs/dette-technique.md) : evite un doublon en base a
    // chaque relance de ce fichier.
    final name = qaUniqueCharacterName("QA-Test-Rodeur-D99");
    await finishCreationFromBackgroundStep(tester, name);

    expect(
      find.text(name).evaluate(),
      isNotEmpty,
      reason:
          "BUG a transmettre a dev-flutter : apres le choix d'Ennemi jure, "
          "la creation du Rodeur ne revient jamais sur la liste des "
          "personnages (ecran bloque, voir les logs ci-dessus).",
    );
  });

  testWidgets(
    "Roublard : Expertise proposee des la creation, jamais d'outils de "
    "voleur (D99/D100)",
    (tester) async {
      if (!hasQaTestAccount) {
        // ignore: avoid_print
        print("SKIP: $qaTestAccountMissingReason");
        return;
      }
      await openCharacterList(tester);
      await startCreationUpToClassChoice(tester, "Roublard");

      expect(
        find.textContaining("Ce choix se fait dès le niveau 1").evaluate(),
        isEmpty,
        reason:
            "Inattendu : le Roublard ne devrait voir son choix "
            "d'Expertise qu'apres l'etape Competences et outils, pas ici.",
      );

      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        "Acolyte",
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, "SUIVANT");
      await pumpUntilSettled(tester, attempts: 4);
      await fillAbilityScoreRacialBonusIfPresent(tester);
      await tapText(tester, "SUIVANT");
      await pumpUntilSettled(tester, attempts: 4);

      await fillAvailableCheckableTiles(tester);
      await tapText(tester, "SUIVANT");
      await pumpUntilSettled(tester, attempts: 4);

      expect(
        find.textContaining("Ce choix se fait dès le niveau 1").evaluate(),
        isNotEmpty,
        reason:
            "BUG a transmettre a dev-flutter : le Roublard ne se voit pas "
            "proposer l'Expertise apres l'etape Competences et outils a la "
            "creation.",
      );
      final skillTiles = tester
          .widgetList<CheckableOptionTile>(find.byType(CheckableOptionTile))
          .map((t) => t.title)
          .toList();
      // ignore: avoid_print
      print("OBSERVATION Expertise (competences candidates) : $skillTiles");
      expect(
        skillTiles.any(
          (title) => title.toLowerCase().contains("outils de voleur"),
        ),
        isFalse,
        reason:
            "REGRESSION D100 (docs/dette-technique.md) : outils de voleur "
            "apparait de nouveau comme option d'Expertise au niveau 1 -- "
            "RAW-faux, cette substitution n'existe qu'au niveau 6.",
      );

      await fillAvailableCheckableTiles(tester);
      await tapText(tester, "SUIVANT");
      await pumpUntilSettled(tester, attempts: 4);

      // Horodate (D109, docs/dette-technique.md) : evite un doublon en base
      // a chaque relance de ce fichier.
      final name = qaUniqueCharacterName("QA-Test-Roublard-D99");
      await tapText(tester, "SUIVANT");
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, "SUIVANT");
      await pumpUntilSettled(tester, attempts: 4);
      await tester.enterText(find.byType(TextFormField).first, name);
      await tester.pump();
      await tapText(tester, "CRÉER LE PERSONNAGE");
      await pumpUntilSettled(tester, attempts: 10);

      expect(
        find.text(name).evaluate(),
        isNotEmpty,
        reason:
            "BUG a transmettre a dev-flutter : apres le choix d'Expertise, "
            "la creation du Roublard ne revient jamais sur la liste des "
            "personnages (ecran bloque, voir les logs ci-dessus).",
      );
    },
  );

  testWidgets(
    "Ensorceleur Lignage draconique : Ancetre draconique propose des la "
    "creation, 10 types de dragon en base (D99/D95)",
    (tester) async {
      if (!hasQaTestAccount) {
        // ignore: avoid_print
        print("SKIP: $qaTestAccountMissingReason");
        return;
      }
      await openCharacterList(tester);
      await startCreationUpToClassChoice(tester, "Ensorceleur");

      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        "Lignage draconique",
      );
      await pumpUntilSettled(tester, attempts: 4);

      // Correctif D112 (`docs/dette-technique.md`) : scope aux SEULS
      // descendants de `SubclassFeatureChoiceBlock` (Ancetre draconique) --
      // sans ce `find.descendant`, le finder remonte aussi les tuiles non
      // selectionnees de `SubclassChoiceBlock` juste au-dessus dans le meme
      // `ListView` (choix de sous-classe lui-meme), d'ou 17 options
      // observees en conditions reelles au lieu de 10 (7 autres origines
      // magiques + 10 types de dragon) -- meme pattern que
      // `character_creation_flow.dart::_resolveSubclassFeatureChoiceIfPresent`
      // (ajoute au correctif D108).
      final remainingOptions = tester
          .widgetList<SelectableOptionTile>(
            find.descendant(
              of: find.byType(SubclassFeatureChoiceBlock),
              matching: find.byType(SelectableOptionTile),
            ),
          )
          .where((t) => !t.selected)
          .map((t) => t.title)
          .toList();
      // ignore: avoid_print
      print(
        "OBSERVATION Ancetre draconique (types de dragon) : $remainingOptions",
      );
      expect(
        remainingOptions.length,
        10,
        reason:
            "BUG a transmettre a dev-flutter/dev-backend-supabase : "
            "l'Ancetre draconique ne propose pas 10 types de dragon a la "
            "creation (regression D95/D99, docs/dette-technique.md).",
      );

      await tapText(tester, remainingOptions.first);
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, "SUIVANT");
      await pumpUntilSettled(tester, attempts: 4);

      // Horodate (D109, docs/dette-technique.md) : evite un doublon en base
      // a chaque relance de ce fichier.
      final name = qaUniqueCharacterName("QA-Test-Ensorceleur-D99");
      await finishCreationFromBackgroundStep(tester, name);

      expect(
        find.text(name).evaluate(),
        isNotEmpty,
        reason:
            "BUG a transmettre a dev-flutter : apres le choix d'Ancetre "
            "draconique, la creation de l'Ensorceleur ne revient jamais "
            "sur la liste des personnages (ecran bloque, voir les logs "
            "ci-dessus).",
      );
    },
  );
}
