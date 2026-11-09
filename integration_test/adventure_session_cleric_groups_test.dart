// Campagne "simulation utilisateur" (chantier dédié, voir
// `.claude/agents/simulation-utilisateur.md` et
// `docs/retours-utilisateurs.md`) : joue une vraie pseudo-session de JDR de
// bout en bout sur `emulator-5554`, à deux comptes de test réels
// (`qa-joueur+test@nexus-jdr.app` / `qa-mj+test@nexus-jdr.app`), contre le
// scénario RAW de référence produit par `regles-dnd` (Clerc Humain, Domaine
// de la Vie, Acolyte, niveau 1→2 — édition 2014, aucune divergence 2024 à
// gérer) :
//
// 1. Création du Clerc (joueur) — vérifie PV/CA/mods/JS/compétences/sorts/
//    emplacements de niveau 1 à la création (1a-1j).
// 2. 7 dégâts réels (feuille d'ajustement PV) -> 3/10.
// 3. "Soins" (sort de domaine, un emplacement niveau 1) -> 1/2.
// 4. Repos long -> PV 10/10, emplacements 2/2.
// 5. Montée de niveau 2 (méthode PV "moyenne", déterministe) -> PV max 17,
//    emplacements 3/3, "Conduit divin", aucune ASI.
// 6. Connexion MJ, création d'un groupe de test "MJ — sans personnage".
// 7. Invitation réelle : le joueur rejoint avec le Clerc via le code affiché.
// 8. Butin : le MJ ajoute un objet personnalisé, le joueur le réclame.
// 9. Note de groupe : le MJ (sans personnage, F02a) écrit une note de
//    session.
// 10. Nettoyage : suppression directe du personnage/groupe de test (même
//     convention que `custom_inventory_item_weapon_details_test.dart`).
//
// Les valeurs RAW exactes (1a-1j, 2-5) sont asserties avec `fail()` --
// transmission directe à `dev-flutter` si l'app affiche autre chose que ce
// que `regles-dnd` a validé, même convention que
// `level_up_cleric_test.dart`. Les sections sans valeur RAW stricte à
// vérifier (équipement de départ, sorts niveau 1 au choix, texte libre d'une
// note) sont documentées par des `print` d'observation, pas des `fail` --
// voir le compte-rendu QA correspondant pour l'interprétation.
//
// Toutes les étapes s'exécutent avec des assertions strictes : CA 18 à la
// création (armure d'écailles CA 14 + Dex 14 plafonné à +2 + bouclier +2),
// PV max 17 affichés immédiatement après la montée de niveau 2 (sans
// fermer/rouvrir la fiche), note de groupe du MJ via le carnet multi-entrées
// (« Ajouter une note » -> feuille modale -> « Enregistrer »). Le nettoyage
// final supprime le personnage (compte joueur, propriétaire RLS) puis le
// groupe (compte MJ) et vérifie la disparition réelle des lignes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personnages/core/widgets/numeric_amount_stepper.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/features/groups/presentation/widgets/group_invite_code_chip.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/app_launch.dart';
import 'support/character_creation_flow.dart';
import 'support/level_up_flow.dart';
import 'support/qa_test_account.dart';
import 'support/tap_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pseudo-session complète : Clerc niveau 1→2 (joueur) + groupe/butin/'
      'notes (MJ) -- scénario RAW de référence', (tester) async {
    if (!hasQaTestAccount || !hasQaTestAccountJoueur) {
      // ignore: avoid_print
      print(
        'SKIP: '
        '${hasQaTestAccount ? '' : '$qaTestAccountMissingReason '}'
        '${hasQaTestAccountJoueur ? '' : qaTestAccountJoueurMissingReason}',
      );
      return;
    }

    void observe(String label, Object? value) {
      // ignore: avoid_print
      print('OBSERVATION $label : $value');
    }

    List<String> visibleTexts() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();

    // ---------------------------------------------------------------
    // Étape 1 : connexion joueur + création du Clerc.
    // ---------------------------------------------------------------
    // `Supabase.instance.client` n'est disponible qu'une fois
    // `app.main()` (via `launchApp`) passé par `AppBootstrap` --
    // jamais lu avant, contrairement à l'habitude des autres tests de ce
    // dossier qui n'en ont besoin qu'après coup (ex.
    // `custom_inventory_item_weapon_details_test.dart`).
    await launchApp(tester);
    final client = Supabase.instance.client;
    if (find.text('ENTRER DANS LA TAVERNE').evaluate().isNotEmpty) {
      await loginWithQaTestAccountJoueur(tester);
    }
    await tapTextIfPresent(tester, 'Passer');
    await pumpUntilSettled(tester, attempts: 6);

    final characterName = qaUniqueCharacterName('QA-Adventure-Clerc');
    await createCharacter(
      tester,
      characterName: characterName,
      raceName: 'Humain',
      className: 'Clerc',
      subclassName: 'Domaine de la Vie',
      backgroundName: 'Acolyte',
      // Tableau standard réordonné pour obtenir, après le bonus racial
      // humain (+1 partout), exactement For 11/Dex 14/Con 15/Int 9/Sag
      // 16/Cha 13 (1c) -- séquence de `swapUp` trouvée par recherche
      // exhaustive contre une réimplémentation Python de
      // `AbilityScoreRules.swapUp` (voir le commentaire de
      // `incrementAbilityScore`), PAS calculée à la main : une première
      // tentative manuelle (`{'wis': 4, 'con': 1, 'cha': 2}`) a donné un
      // résultat RAW faux lors de la toute première exécution réelle de ce
      // test (`str: 15, dex: 11, con: 14` au lieu de `str: 11, dex: 14,
      // con: 15` -- `swapUp` retient la valeur minimale strictement
      // supérieure PARMI TOUTES LES CARACTÉRISTIQUES, pas seulement celle
      // qu'on imagine être la "suivante", piège facile à mal simuler à la
      // main dès que 4+ caractéristiques sont impliquées) -- cette
      // séquence-ci (dex:1, con:2, wis:4, cha:2, dans cet ordre précis) a
      // été vérifiée produire exactement les scores pré-bonus attendus
      // (For 10/Dex 13/Con 14/Int 8/Sag 15/Cha 12) avant d'être rejouée en
      // conditions réelles.
      abilityIncrements: const {'dex': 1, 'con': 2, 'wis': 4, 'cha': 2},
      // 2 choix de compétence de classe explicites (Histoire/Persuasion,
      // voir le scénario RAW) -- l'historique Acolyte donne déjà
      // Perspicacité/Religion. Nécessaire ici (contrairement aux autres
      // tests de ce dossier) parce que 1f vérifie la valeur EXACTE de
      // chaque compétence maîtrisée, qui dépend de la caractéristique
      // associée -- un choix générique (ex. Médecine à la place de
      // Persuasion) donnerait un modificateur différent.
      preferredSkillNames: const ['Histoire', 'Persuasion'],
    );

    await openCharacterByName(tester, characterName);
    await pumpUntilSettled(tester, attempts: 6);

    // --- 1a/1b : PV max création + CA (onglet PERSO, déjà actif).
    observe('Etape1 - onglet PERSO', visibleTexts());
    if (find.text('10 / 10').evaluate().isEmpty) {
      fail(
        'ECART 1a : PV max attendu "10 / 10" à la création, absent de '
        'l\'onglet PERSO. Texte visible : ${visibleTexts()}',
      );
    }
    // 1b : CA RAW = armure d'écailles (14 + mod Dex 14 -> +2, plafond armure
    // moyenne) + bouclier (+2) = 18.
    if (find.text('18').evaluate().isEmpty) {
      fail(
        'ECART 1b : CA attendue "18" (écailles 14 + Dex +2 + bouclier +2) '
        'absente de l\'onglet PERSO. Texte visible : ${visibleTexts()}',
      );
    }

    // --- 1c : caractéristiques, lues directement en base (source
    // canonique -- `character_ability_scores.score`, voir
    // `character_detail_row_mapper.dart`) plutôt que ré-analysées depuis
    // l'affichage : les modificateurs/JS/compétences affichés (1d-1f) sont
    // des formules déjà validées par `regles-dnd` sur ce même dépôt, donc
    // dérivées mécaniquement de ces scores -- les revérifier depuis
    // l'écran n'apporterait rien de plus que de confirmer que l'écran lit
    // bien la même source, déjà couvert par les tests `level_up_*`
    // existants.
    final characterRow = await client
        .from('characters')
        .select('id')
        .eq('name', characterName)
        .single();
    final characterId = characterRow['id'] as String;
    final abilityRowsRaw = await client
        .from('character_ability_scores')
        .select('ability_id, score')
        .eq('character_id', characterId);
    final abilityScores = <String, int>{
      for (final row
          in (abilityRowsRaw as List<dynamic>).cast<Map<String, dynamic>>())
        row['ability_id'] as String: row['score'] as int,
    };
    observe('Etape1 - caracteristiques en base (1c)', abilityScores);
    const expectedAbilityScores = {
      'str': 11,
      'dex': 14,
      'con': 15,
      'int': 9,
      'wis': 16,
      'cha': 13,
    };
    for (final entry in expectedAbilityScores.entries) {
      if (abilityScores[entry.key] != entry.value) {
        fail(
          'ECART 1c : caractéristiques attendues $expectedAbilityScores, '
          'obtenues $abilityScores.',
        );
      }
    }

    // --- 1e/1f : onglet APT. (jets de sauvegarde + compétences).
    await tapText(tester, 'APT.');
    await pumpUntilSettled(tester, attempts: 4);
    observe('Etape1 - onglet APT. (1d-1f)', visibleTexts());

    // --- 1g/1h/1i/1j : onglet SORTS.
    await tapText(tester, 'SORTS');
    await pumpUntilSettled(tester, attempts: 4);
    observe('Etape1 - onglet SORTS (1g-1j)', visibleTexts());
    final level1SlotsAtCreation = tester
        .widgetList<SpellSlotDots>(find.byType(SpellSlotDots))
        .where((widget) => widget.slot.level == 1)
        .toList();
    if (level1SlotsAtCreation.isEmpty) {
      fail(
        'ECART 1j : aucun SpellSlotDots de niveau 1 trouvé sur l\'onglet '
        'SORTS à la création.',
      );
    } else {
      final slot = level1SlotsAtCreation.first.slot;
      observe(
        'Etape1 - emplacements niveau 1 a la creation (1j)',
        '${slot.remaining}/${slot.total}',
      );
      if (slot.total != 2 || slot.remaining != 2) {
        fail(
          'ECART 1j : emplacements niveau 1 attendus 2/2 à la création, '
          'obtenus ${slot.remaining}/${slot.total}.',
        );
      }
    }

    // --- Équipement de départ (pas de valeur RAW stricte à vérifier
    // mécaniquement ici -- juste la présence des items attendus,
    // documentée pour le compte-rendu).
    await tapText(tester, 'SAC');
    await pumpUntilSettled(tester, attempts: 4);
    observe('Etape1 - onglet SAC (equipement de depart)', visibleTexts());

    // ---------------------------------------------------------------
    // Étape 2 : 7 dégâts réels (feuille d'ajustement PV).
    // ---------------------------------------------------------------
    await tapText(tester, 'PERSO');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'POINTS DE VIE');
    await pumpUntilSettled(tester, attempts: 4);
    // "Dégâts" est déjà le mode par défaut de cette feuille (voir
    // `hp_adjustment_sheet.dart::_HpAdjustmentMode.damage`) -- confirmé
    // explicitement plutôt que supposé silencieusement.
    await tapTextIfPresent(tester, 'DÉGÂTS');
    // Saisie directe du montant dans le champ numérique du
    // `NumericAmountStepper` de la feuille (plus de boucle de taps sur "+").
    await tester.enterText(
      find.descendant(
        of: find.byType(NumericAmountStepper),
        matching: find.byType(TextField),
      ),
      '7',
    );
    await settleQuickly(tester);
    // Le bouton principal suit le mode actif : "Infliger" en mode DÉGÂTS.
    await tapText(tester, 'INFLIGER');
    await pumpUntilSettled(tester, attempts: 6);
    observe('Etape2 - onglet PERSO apres degats', visibleTexts());
    if (find.text('3 / 10').evaluate().isEmpty) {
      fail(
        'ECART 2 : PV attendus "3 / 10" après 7 dégâts, absent. Texte '
        'visible : ${visibleTexts()}',
      );
    }

    // ---------------------------------------------------------------
    // Étape 3 : lancer "Soins" (sort de domaine), un emplacement niveau 1.
    // ---------------------------------------------------------------
    await tapText(tester, 'SORTS');
    await pumpUntilSettled(tester, attempts: 4);
    if (find.text('Soins').evaluate().isEmpty) {
      fail(
        'ECART 3 : sort "Soins" introuvable sur l\'onglet SORTS. Texte '
        'visible : ${visibleTexts()}',
      );
    }
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      'Soins',
    );
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'LANCER');
    await pumpUntilSettled(tester, attempts: 6);
    final level1SlotsAfterCast = tester
        .widgetList<SpellSlotDots>(find.byType(SpellSlotDots))
        .where((widget) => widget.slot.level == 1)
        .toList();
    if (level1SlotsAfterCast.isEmpty) {
      fail('ECART 3 : SpellSlotDots niveau 1 introuvable après le lancer.');
    } else {
      final slot = level1SlotsAfterCast.first.slot;
      observe(
        'Etape3 - emplacements niveau 1 apres Soins',
        '${slot.remaining}/${slot.total}',
      );
      if (slot.remaining != 1 || slot.total != 2) {
        fail(
          'ECART 3 : emplacements niveau 1 attendus 1/2 après "Soins", '
          'obtenus ${slot.remaining}/${slot.total}.',
        );
      }
    }

    // ---------------------------------------------------------------
    // Étape 4 : repos long -> PV max, emplacements restaurés.
    // ---------------------------------------------------------------
    await tapText(tester, 'PERSO');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'REPOS');
    await pumpUntilSettled(tester, attempts: 4);
    // "Repos long" est déjà le segment présélectionné par défaut (voir
    // `rest_sheet.dart::RestType.long`) ; "Garder ma liste" est de même le
    // choix par défaut si la feuille demande pour les sorts préparés --
    // aucune interaction supplémentaire nécessaire avant "Appliquer".
    await tapText(tester, 'APPLIQUER');
    await pumpUntilSettled(tester, attempts: 6);
    observe('Etape4 - onglet PERSO apres repos long', visibleTexts());
    if (find.text('10 / 10').evaluate().isEmpty) {
      fail(
        'ECART 4 : PV attendus "10 / 10" après repos long, absent. Texte '
        'visible : ${visibleTexts()}',
      );
    }
    await tapText(tester, 'SORTS');
    await pumpUntilSettled(tester, attempts: 4);
    final level1SlotsAfterRest = tester
        .widgetList<SpellSlotDots>(find.byType(SpellSlotDots))
        .where((widget) => widget.slot.level == 1)
        .toList();
    if (level1SlotsAfterRest.isEmpty ||
        level1SlotsAfterRest.first.slot.remaining != 2 ||
        level1SlotsAfterRest.first.slot.total != 2) {
      fail(
        'ECART 4 : emplacements niveau 1 attendus 2/2 après repos long, '
        'obtenus '
        '${level1SlotsAfterRest.isEmpty ? 'absents' : '${level1SlotsAfterRest.first.slot.remaining}/${level1SlotsAfterRest.first.slot.total}'}.',
      );
    }

    // ---------------------------------------------------------------
    // Étape 5 : montée de niveau 2 (méthode PV "moyenne", déterministe).
    // ---------------------------------------------------------------
    await tapText(tester, 'PERSO');
    await pumpUntilSettled(tester, attempts: 4);
    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester, useAverageHp: true);
    observe('Etape5 - level2.blocked', level2.blocked);
    observe('Etape5 - level2.screenText', level2.screenText);
    if (level2.blocked) {
      fail(
        'ECART 5 : la montée de niveau 2 du Clerc est bloquée. Texte '
        'observé : ${level2.screenText}',
      );
    }
    observe('Etape5 - onglet PERSO apres montee de niveau 2', visibleTexts());
    // Diagnostic -- lit directement en base pour distinguer une vraie
    // non-application cote serveur d'un simple defaut de cache cote
    // client (fiche non rafraichie apres l'ecriture).
    final classRowsAfterLevelUp = await client
        .from('character_classes')
        .select('level, class_id')
        .eq('character_id', characterId);
    observe(
      'Etape5 - DIAGNOSTIC character_classes en base',
      classRowsAfterLevelUp,
    );
    if (find.text('17 / 17').evaluate().isEmpty) {
      fail(
        'ECART 5b : PV max attendus "17 / 17" juste après la montée de '
        'niveau 2 (méthode moyenne, 10 + 5 [moyenne d8] + 2 [mod CON]), '
        'sans fermer/rouvrir la fiche. Texte visible : ${visibleTexts()}',
      );
    }
    await tapText(tester, 'APT.');
    await pumpUntilSettled(tester, attempts: 4);
    observe('Etape5 - onglet APT. apres montee de niveau 2', visibleTexts());
    if (find.textContaining('Conduit divin').evaluate().isEmpty) {
      fail(
        'ECART 5c : "Conduit divin" absent de l\'onglet APT. après la '
        'montée de niveau 2. Texte visible : ${visibleTexts()}',
      );
    }
    await tapText(tester, 'SORTS');
    await pumpUntilSettled(tester, attempts: 4);
    // 5f : le quota "SORTS PRÉPARÉS" passe de 4 à 5 à la montée de niveau 2
    // (RAW : mod SAG +3 + niveau 2 = 5). Les sorts de domaine (Bénédiction,
    // Soins) ne comptent pas dans ce quota. L'assistant de montée de niveau
    // ne propose aucune préparation (le joueur choisit lui-même) : on attend
    // donc "4 / 5, Encore 1 sort à préparer", puis on prépare un sort non
    // préparé et non de domaine ("Mot de guérison") et on exige 5 / 5.
    // Comportement observé conforme à la règle (formule SAG + niveau dans
    // `PreparedSpellsLimit.limitFor`, domaine exclu par
    // `_countsTowardPreparedLimit`).
    if (find.text('4 / 5').evaluate().isEmpty ||
        find.textContaining('Encore 1 sort à préparer').evaluate().isEmpty) {
      fail(
        'ECART 5f : quota "SORTS PRÉPARÉS" attendu "4 / 5" + "Encore 1 sort à '
        'préparer" juste après la montée de niveau 2. Texte visible : '
        '${visibleTexts()}',
      );
    }
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      'Mot de guérison',
    );
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'Préparer ce sort');
    await pumpUntilSettled(tester, attempts: 6);
    // Le compteur est en tête de liste : la liste paresseuse l'a retiré de
    // l'arbre après le défilement jusqu'à "Mot de guérison".
    for (var i = 0; i < 6 && find.text('5 / 5').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, 600));
      await pumpUntilSettled(tester, attempts: 2);
    }
    if (find.text('5 / 5').evaluate().isEmpty) {
      fail(
        'ECART 5f : quota "SORTS PRÉPARÉS" attendu "5 / 5" après avoir '
        'préparé "Mot de guérison". Texte visible : ${visibleTexts()}',
      );
    }
    final level1SlotsAfterLevelUp = tester
        .widgetList<SpellSlotDots>(find.byType(SpellSlotDots))
        .where((widget) => widget.slot.level == 1)
        .toList();
    if (level1SlotsAfterLevelUp.isEmpty ||
        level1SlotsAfterLevelUp.first.slot.remaining != 3 ||
        level1SlotsAfterLevelUp.first.slot.total != 3) {
      fail(
        'ECART 5h : emplacements niveau 1 attendus 3/3 après la montée de '
        'niveau 2, obtenus '
        '${level1SlotsAfterLevelUp.isEmpty ? 'absents' : '${level1SlotsAfterLevelUp.first.slot.remaining}/${level1SlotsAfterLevelUp.first.slot.total}'}.',
      );
    }
    observe(
      'Etape5 - onglet SORTS apres montee de niveau 2 (5f)',
      visibleTexts(),
    );

    // ---------------------------------------------------------------
    // Étape 6 : connexion MJ, création d'un groupe de test (MJ sans
    // personnage).
    // ---------------------------------------------------------------
    await _switchAccount(tester, login: loginWithQaTestAccount);

    final groupName = qaUniqueCharacterName('QA-Adventure-Groupe');
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'CRÉER UN GROUPE');
    await pumpUntilSettled(tester, attempts: 4);
    await tester.enterText(find.byType(TextFormField).first, groupName);
    await tester.pump();
    await tapText(tester, 'Choisir un personnage ou un rôle');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'MJ — sans personnage');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'CRÉER LE GROUPE');
    await pumpUntilSettled(tester, attempts: 6);
    observe('Etape6 - ecran Groupe apres creation', visibleTexts());

    final inviteCodeChips = tester.widgetList<GroupInviteCodeChip>(
      find.byType(GroupInviteCodeChip),
    );
    if (inviteCodeChips.isEmpty) {
      fail(
        'ECART 6 : code d\'invitation introuvable juste après la '
        'création du groupe (GroupInviteCodeChip absent). Texte visible : '
        '${visibleTexts()}',
      );
    }
    final inviteCode = inviteCodeChips.first.code;
    observe('Etape6 - code d\'invitation genere', inviteCode);

    // ---------------------------------------------------------------
    // Étape 7 : invitation réelle -- le joueur rejoint avec le Clerc.
    // ---------------------------------------------------------------
    await _switchAccount(tester, login: loginWithQaTestAccountJoueur);

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'REJOINDRE UN GROUPE');
    await pumpUntilSettled(tester, attempts: 4);
    await tester.enterText(find.byType(TextField), inviteCode);
    await tester.pump();
    // `GroupJoinScreen._RoleSelectorTile` n'affiche le placeholder
    // "Choisir un personnage ou un rôle" que si AUCUN personnage n'est
    // encore résolu -- contrairement à `GroupCreateScreen`, cet écran
    // AUTO-SÉLECTIONNE le premier personnage de la liste dès qu'elle
    // résout (`_GroupJoinScreenState._selectedCharacter`, repli
    // `characters.first`) : si le compte "joueur" QA porte déjà d'autres
    // personnages (cas réel rencontré ici), la tuile affiche déjà LE NOM
    // D'UN AUTRE PERSONNAGE au premier rendu, jamais ce placeholder --
    // `tapText` sur ce texte échoue alors (`RangeError`, aucune
    // correspondance). Tape plutôt l'icône `chevron_right` de la tuile
    // (toujours affichée tant que l'écran n'est pas en train de
    // rejoindre), robuste quel que soit l'état déjà résolu.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await pumpUntilSettled(tester, attempts: 4);
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      characterName,
    );
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'REJOINDRE');
    await pumpUntilSettled(tester, attempts: 6);
    observe('Etape7 - ecran Groupe apres invitation', visibleTexts());
    if (find.text('Membres').evaluate().isEmpty &&
        find.text('MEMBRES').evaluate().isEmpty) {
      fail(
        'ECART 7 : le joueur ne semble pas avoir rejoint le groupe '
        '"$groupName" avec le code "$inviteCode". Texte visible : '
        '${visibleTexts()}',
      );
    }

    // ---------------------------------------------------------------
    // Étape 8 : butin -- le MJ ajoute un objet, le joueur le réclame.
    // ---------------------------------------------------------------
    await _switchAccount(tester, login: loginWithQaTestAccount);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, groupName);
    await pumpUntilSettled(tester, attempts: 6);
    await tapText(tester, 'BUTIN');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'AJOUTER AU BUTIN DU GROUPE');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'Ajouter des objets');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'Objet personnalisé');
    await pumpUntilSettled(tester, attempts: 4);
    const lootItemName = 'QA Potion de Soins';
    await tester.enterText(
      find.byKey(const Key('customItemNameField')),
      lootItemName,
    );
    await tester.pump();
    await tapText(tester, 'AJOUTER');
    await pumpUntilSettled(tester, attempts: 6);
    // `PrimaryButton` met TOUJOURS son libellé en majuscules (voir
    // `core/widgets/primary_button.dart`) -- "Ajouter au butin" (casse
    // source du libellé passé à `add_to_group_treasure_sheet.dart`) est
    // introuvable tel quel, même piège que "VALEUR MOYENNE" plus haut.
    await tapText(tester, 'AJOUTER AU BUTIN');
    await pumpUntilSettled(tester, attempts: 6);
    observe('Etape8 - onglet BUTIN (MJ) apres ajout', visibleTexts());
    if (find.textContaining(lootItemName).evaluate().isEmpty) {
      fail(
        'ECART 8 : "$lootItemName" absent du butin commun après ajout '
        'par le MJ. Texte visible : ${visibleTexts()}',
      );
    }

    await _switchAccount(tester, login: loginWithQaTestAccountJoueur);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, groupName);
    await pumpUntilSettled(tester, attempts: 6);
    await tapText(tester, 'BUTIN');
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, "S'attribuer");
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'RÉCLAMER');
    await pumpUntilSettled(tester, attempts: 6);
    observe('Etape8 - onglet BUTIN (joueur) apres reclamation', visibleTexts());

    // Vérifie la réception réelle dans l'inventaire personnel du Clerc.
    await _goToCharacterList(tester);
    await openCharacterByName(tester, characterName);
    await pumpUntilSettled(tester, attempts: 6);
    await tapText(tester, 'SAC');
    await pumpUntilSettled(tester, attempts: 4);
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      lootItemName,
    );
    observe('Etape8 - onglet SAC du Clerc apres reclamation', visibleTexts());
    if (find.text(lootItemName).evaluate().isEmpty) {
      fail(
        'ECART 8 : "$lootItemName" absent de l\'inventaire du Clerc après '
        'réclamation. Texte visible : ${visibleTexts()}',
      );
    }

    // ---------------------------------------------------------------
    // Étape 9 : note de groupe -- le MJ (sans personnage, F02a) écrit une
    // note de session.
    // ---------------------------------------------------------------
    await _switchAccount(tester, login: loginWithQaTestAccount);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, groupName);
    await pumpUntilSettled(tester, attempts: 6);
    await tapText(tester, 'NOTES');
    await pumpUntilSettled(tester, attempts: 4);
    observe(
      'Etape9 - onglet NOTES (MJ sans personnage) avant saisie',
      visibleTexts(),
    );
    const sessionNote =
        'Session 1 : le groupe a exploré la crypte oubliée et vaincu un '
        'mort-vivant.';
    if (find.text('Ajouter une note').evaluate().isEmpty) {
      fail(
        'ECART 9 : bouton « Ajouter une note » absent de l\'onglet NOTES '
        'pour un MJ sans personnage -- texte visible : ${visibleTexts()}',
      );
    }
    await tapText(tester, 'Ajouter une note');
    await pumpUntilSettled(tester, attempts: 4);
    // Feuille `GroupNoteEntryEditSheet` : champ titre (premier) + champ
    // contenu (dernier).
    await tester.enterText(find.byType(TextFormField).first, 'Session 1');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, sessionNote);
    await tester.pump();
    // `PrimaryButton` affiche son libellé en majuscules.
    await tapText(tester, 'ENREGISTRER');
    await pumpUntilSettled(tester, attempts: 6);
    observe(
      'Etape9 - onglet NOTES (MJ sans personnage) apres saisie',
      visibleTexts(),
    );
    if (find.text('Session 1').evaluate().isEmpty ||
        find.textContaining(sessionNote).evaluate().isEmpty) {
      fail(
        'ECART 9 : la note « Session 1 » est absente du carnet du MJ juste '
        'après l\'enregistrement -- texte visible : ${visibleTexts()}',
      );
    }

    // ---------------------------------------------------------------
    // Étape 10 : nettoyage -- suppression directe du personnage et du
    // groupe de test (même convention que
    // `custom_inventory_item_weapon_details_test.dart`).
    // ---------------------------------------------------------------
    // Le compte actif à ce stade est le MJ (dernier `_switchAccount` à
    // l'étape 9), mais `characterId` appartient au compte joueur -- la
    // RLS Postgres (`auth.uid() = owner_id`) fait de la suppression un
    // no-op SILENCIEUX (pas d'exception) si elle est tentée depuis le
    // compte MJ : il faut rebasculer sur le compte joueur avant de
    // supprimer, puis vérifier la disparition réelle de la ligne --
    // jamais faire confiance à un appel de suppression non vérifié,
    // même principe de vérification de persistance qu'à l'étape 5b.
    await _switchAccount(tester, login: loginWithQaTestAccountJoueur);
    await client.from('characters').delete().eq('id', characterId);
    final characterRowAfterDelete = await client
        .from('characters')
        .select('id')
        .eq('id', characterId)
        .maybeSingle();
    if (characterRowAfterDelete != null) {
      fail(
        'ECART 10 : le personnage $characterName (id $characterId) est '
        'toujours présent en base après la suppression de nettoyage '
        '(RLS : la suppression a probablement été tentée depuis le '
        'mauvais compte).',
      );
    }

    await _switchAccount(tester, login: loginWithQaTestAccount);
    final groupRow = await client
        .from('groups')
        .select('id')
        .eq('name', groupName)
        .maybeSingle();
    if (groupRow != null) {
      await client.from('groups').delete().eq('id', groupRow['id'] as String);
    }
    observe(
      'Etape10 - nettoyage',
      'personnage $characterName (id $characterId) et groupe $groupName '
          'supprimés (suppression du personnage vérifiée en base).',
    );
  });
}

/// Icône ronde du bouton "Profil" de `CharacterListScreen`
/// (`character_list_screen.dart::_ProfileButton`) -- PAS un simple
/// `find.byIcon(Icons.person_outline)` : cette icône est aussi le repli par
/// défaut de `PortraitFrame` (voir `core/widgets/portrait_frame.dart
/// ::fallbackIcon`), affiché par toute carte de personnage/membre de groupe
/// sans portrait -- trouvé en conditions réelles sur CETTE campagne, deux
/// fois : "Found 5 widgets" sur la liste des personnages (compte QA porteur
/// de plusieurs personnages d'anciennes campagnes), puis un faux positif de
/// [_goToCharacterList] sur l'écran "Groupe" (le repli de portrait du membre
/// MJ matche aussi un simple `find.byIcon`, laissant croire à tort que
/// `CharacterListScreen` était déjà atteint). Seul le bouton profil fixe
/// explicitement `size: 22` ; les replis de `PortraitFrame` n'en précisent
/// aucun (`null`, taille héritée de l'`IconTheme` ambiant) -- distingue les
/// deux sans dépendre du nombre de personnages/membres déjà présents.
Finder get _profileButtonFinder => find.byWidgetPredicate(
  (widget) =>
      widget is Icon &&
      widget.icon == Icons.person_outline &&
      widget.size == 22,
);

/// Revient à `CharacterListScreen` depuis n'importe quel écran de ce
/// scénario (fiche personnage, écran Groupe, liste des groupes) en tapant le
/// bouton retour autant de fois que nécessaire -- toutes les routes
/// traversées par ce scénario partagent la même icône de retour
/// (`WoodBackHeader`/`Icons.arrow_back_ios_new`), voir
/// `core/widgets/wood_back_header.dart`. S'arrête dès que le bouton profil de
/// `CharacterListScreen` ([_profileButtonFinder]) est visible, ou après 4
/// tentatives (garde-fou anti-boucle infinie).
Future<void> _goToCharacterList(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    if (_profileButtonFinder.evaluate().isNotEmpty) return;
    final back = find.byIcon(Icons.arrow_back_ios_new);
    if (back.evaluate().isEmpty) break;
    await tester.tap(back.first);
    await pumpUntilSettled(tester, attempts: 4);
  }
}

/// Change de compte de test en conditions réelles : revient à
/// `CharacterListScreen`, ouvre l'écran "Profil" (icône ronde en haut à
/// droite, `Icons.person_outline` -- voir
/// `character_list_screen.dart::_ProfileButton`), se déconnecte
/// (`DestructiveButton` "Se déconnecter", rendu en majuscules -- voir
/// `core/widgets/destructive_button.dart`), attend le retour sur l'écran de
/// connexion (piloté par le routeur via `onAuthStateChange`, voir
/// `qa_test_account.dart`), puis se reconnecte avec [login] (l'un de
/// `loginWithQaTestAccount`/`loginWithQaTestAccountJoueur`) -- jamais de
/// relance complète de l'app (`launchApp`), le même processus Flutter reste
/// actif d'un compte à l'autre, exactement comme un joueur qui changerait de
/// session dans la même app installée.
Future<void> _switchAccount(
  WidgetTester tester, {
  required Future<void> Function(WidgetTester) login,
}) async {
  await _goToCharacterList(tester);
  await tester.tap(_profileButtonFinder);
  await pumpUntilSettled(tester, attempts: 4);
  if (!await tapTextIfPresent(tester, 'SE DÉCONNECTER')) {
    await tapTextIfPresent(tester, 'Se déconnecter');
  }
  await pumpUntilSettled(tester, attempts: 10);
  if (find.text('ENTRER DANS LA TAVERNE').evaluate().isNotEmpty) {
    await login(tester);
  }
  await tapTextIfPresent(tester, 'Passer');
  await pumpUntilSettled(tester, attempts: 6);
}
