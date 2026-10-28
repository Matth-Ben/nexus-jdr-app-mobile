import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/app_launch.dart';
import 'support/character_creation_flow.dart';
import 'support/level_up_flow.dart';
import 'support/qa_test_account.dart';
import 'support/tap_helpers.dart';

/// Verification QA en conditions reelles (campagne du 25/10/2026) de la
/// tache "description et degats d'arme pour un objet personnalise" --
/// pilote la vraie app sur un emulateur Android reel, contre le projet
/// Supabase distant partage dev/staging/prod (migration deja appliquee,
/// voir config/README.md). Couvre les cas 1/2/3/4/5 du mandat QA ; le cas
/// 6 (fiche partagee) est verifie separement via le RPC get_shared_character
/// appele directement sur le client deja authentifie par l'app (meme
/// fonction serveur que CharacterSharingRepository.fetchSharedCharacter),
/// apres avoir regenere le token depuis l'ecran "Partager" reel.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Objet personnalisé : description + arme + persistance + collecte '
    'locale + non-regression catalogue + fiche partagee',
    (tester) async {
      if (!hasQaTestAccount) {
        // ignore: avoid_print
        print('SKIP: $qaTestAccountMissingReason');
        return;
      }
      await launchApp(tester);
      if (find.text('ENTRER DANS LA TAVERNE').evaluate().isNotEmpty) {
        await loginWithQaTestAccount(tester);
      }
      await tapTextIfPresent(tester, 'Passer');
      await pumpUntilSettled(tester, attempts: 6);

      final name = qaUniqueCharacterName('QA-Test-ObjetPerso');
      await createCharacter(
        tester,
        characterName: name,
        raceName: 'Humain',
        className: 'Barbare',
        backgroundName: 'Acolyte',
      );

      await openCharacterByName(tester, name);

      // --- Onglet Inventaire ("SAC") ---
      // Attente plus genereuse ici (premier chargement reseau de la fiche,
      // voir integration_test/README.md -- timeout genereux de launchApp
      // pour la meme raison) avant de chercher l'onglet "SAC", avec un
      // diagnostic explicite si jamais il n'apparait pas.
      var sacTabFound = false;
      for (var attempt = 0; attempt < 20; attempt++) {
        if (find.text('SAC').evaluate().isNotEmpty) {
          sacTabFound = true;
          break;
        }
        await tester.pump(const Duration(milliseconds: 500));
      }
      if (!sacTabFound) {
        final visibleTexts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .toList();
        // ignore: avoid_print
        print(
          'DIAGNOSTIC: onglet SAC introuvable apres ouverture du '
          'personnage. Textes visibles : $visibleTexts',
        );
      }
      await tapText(tester, 'SAC');
      await pumpUntilSettled(tester, attempts: 4);

      // Cas 1 : objet personnalise "Objet simple", description seule --
      // le bouton "Ajouter" ne doit JAMAIS etre bloque par l'absence de
      // description (elle est optionnelle).
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'Objet',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Objet personnalisé');
      await pumpUntilSettled(tester, attempts: 4);
      await tester.enterText(
        find.byKey(const Key('customItemNameField')),
        'QA Amulette Simple',
      );
      await tester.enterText(
        find.byKey(const Key('customItemDescriptionField')),
        'Une amulette de test QA, sans arme.',
      );
      await tester.pump();
      final addButtonSimple = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'AJOUTER'),
      );
      expect(
        addButtonSimple.onPressed,
        isNotNull,
        reason: 'bouton jamais bloque par absence de description (simple)',
      );
      await tapText(tester, 'AJOUTER');
      await pumpUntilSettled(tester, attempts: 6);

      expect(find.text('QA Amulette Simple'), findsOneWidget);

      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'QA Amulette Simple',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Infos');
      await pumpUntilSettled(tester, attempts: 4);
      expect(
        find.text('Une amulette de test QA, sans arme.'),
        findsOneWidget,
        reason: 'description affichee dans le panneau Infos',
      );
      await tester.tap(find.byIcon(Icons.close));
      await pumpUntilSettled(tester, attempts: 4);

      // Cas 2 : objet personnalise "Arme" -- bouton "Ajouter" desactive
      // tant qu'aucun type de degats n'est choisi.
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'Objet',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Objet personnalisé');
      await pumpUntilSettled(tester, attempts: 4);
      await tester.enterText(
        find.byKey(const Key('customItemNameField')),
        'QA Zanbato Ancestral',
      );
      await tester.enterText(
        find.byKey(const Key('customItemDescriptionField')),
        'Une lame de test QA transmise de génération en génération.',
      );
      await tester.pump();
      await tapText(tester, 'ARME');
      await pumpUntilSettled(tester, attempts: 4);

      final addButtonNoDamageType = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'AJOUTER'),
      );
      expect(
        addButtonNoDamageType.onPressed,
        isNull,
        reason: 'bouton desactive tant qu aucun type de degats n est choisi',
      );

      final diceCountIncrement = find
          .byWidgetPredicate(
            (widget) => widget is Icon && widget.semanticLabel == 'Augmenter',
          )
          .first;
      await tester.ensureVisible(diceCountIncrement);
      await tester.tap(diceCountIncrement);
      await pumpUntilSettled(tester, attempts: 4);
      await tester.ensureVisible(
        find.byKey(const Key('customItemDiceSidesField')),
      );
      await tester.tap(find.byKey(const Key('customItemDiceSidesField')));
      await pumpUntilSettled(tester, attempts: 4);
      await tester.tap(find.text('8').last);
      await pumpUntilSettled(tester, attempts: 4);

      await tester.ensureVisible(
        find.byKey(const Key('customItemDamageTypeField')),
      );
      await tester.tap(find.byKey(const Key('customItemDamageTypeField')));
      await pumpUntilSettled(tester, attempts: 4);
      await tester.tap(find.text('Perforant').last);
      await pumpUntilSettled(tester, attempts: 4);

      await tester.ensureVisible(
        find.byKey(const Key('customItemPropertiesField')),
      );
      await tester.enterText(
        find.byKey(const Key('customItemPropertiesField')),
        'legere, finesse',
      );
      await tester.pump();

      final addButtonReady = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'AJOUTER'),
      );
      expect(addButtonReady.onPressed, isNotNull);
      await tapText(tester, 'AJOUTER');
      await pumpUntilSettled(tester, attempts: 6);

      expect(find.text('QA Zanbato Ancestral'), findsOneWidget);
      expect(
        find.text('2d8'),
        findsOneWidget,
        reason: 'DiceTypeBadge affiche dans la liste avec la notation NdM',
      );
      expect(find.byType(DiceTypeBadge), findsWidgets);

      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'QA Zanbato Ancestral',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Infos');
      await pumpUntilSettled(tester, attempts: 4);
      expect(find.text('Dégâts'), findsOneWidget);
      expect(find.text('Propriétés'), findsOneWidget);
      expect(
        find.text('Une lame de test QA transmise de génération en génération.'),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.close));
      await pumpUntilSettled(tester, attempts: 4);

      // --- Cas 3 : persistance reelle -- ferme la fiche (retour a la
      // liste) puis la rouvre, pour forcer un nouveau fetch reseau (pas
      // juste relire l'etat local deja en memoire).
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await pumpUntilSettled(tester, attempts: 6);
      await openCharacterByName(tester, name);
      await tapText(tester, 'SAC');
      await pumpUntilSettled(tester, attempts: 4);

      // `find.text` ne voit que les widgets deja construits -- la liste
      // de l'onglet Inventaire reste un ListView paresseux (meme principe
      // que la liste de races de l'assistant de creation, voir
      // support/tap_helpers.dart::scrollUntilVisibleThenTap), donc on
      // defile explicitement jusqu'a chaque objet plutot que de supposer
      // qu'il est deja visible juste apres reouverture de la fiche.
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'QA Amulette Simple',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Infos');
      await pumpUntilSettled(tester, attempts: 4);
      expect(
        find.text('Une amulette de test QA, sans arme.'),
        findsOneWidget,
        reason: 'description (objet simple) relue depuis la base',
      );
      await tester.tap(find.byIcon(Icons.close));
      await pumpUntilSettled(tester, attempts: 4);

      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'QA Zanbato Ancestral',
      );
      await pumpUntilSettled(tester, attempts: 4);
      expect(
        find.text('2d8'),
        findsOneWidget,
        reason: 'de de degats relu depuis la base apres fermeture/reouverture',
      );
      await tapText(tester, 'Infos');
      await pumpUntilSettled(tester, attempts: 4);
      expect(
        find.text('Une lame de test QA transmise de génération en génération.'),
        findsOneWidget,
        reason: 'description relue depuis la base, pas depuis l etat local',
      );
      expect(find.text('Dégâts'), findsOneWidget);
      expect(find.text('Propriétés'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await pumpUntilSettled(tester, attempts: 4);

      // --- Cas 4 : mode "collecte locale" (sheet "Ajouter une
      // recompense") -- un objet personnalise-arme porte les memes
      // informations une fois reellement ajoute a l'inventaire.
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'RÉCOMPENSE',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Ajouter un objet');
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Objet personnalisé');
      await pumpUntilSettled(tester, attempts: 4);
      await tester.enterText(
        find.byKey(const Key('customItemNameField')),
        'QA Recompense Lame',
      );
      await tester.enterText(
        find.byKey(const Key('customItemDescriptionField')),
        'Une relique remise en recompense (test QA).',
      );
      await tester.pump();
      await tapText(tester, 'ARME');
      await pumpUntilSettled(tester, attempts: 4);
      await tester.ensureVisible(
        find.byKey(const Key('customItemDamageTypeField')),
      );
      await tester.tap(find.byKey(const Key('customItemDamageTypeField')));
      await pumpUntilSettled(tester, attempts: 4);
      await tester.tap(find.text('Contondant').last);
      await pumpUntilSettled(tester, attempts: 4);
      await tester.ensureVisible(
        find.byKey(const Key('customItemPropertiesField')),
      );
      await tester.enterText(
        find.byKey(const Key('customItemPropertiesField')),
        'lourde',
      );
      await tester.pump();
      await tapText(tester, 'AJOUTER');
      await pumpUntilSettled(tester, attempts: 6);

      // La sheet "Ajouter une recompense" affiche "{displayName} x {quantite}" (voir add_reward_sheet.dart), pas le nom seul.
      expect(find.textContaining('QA Recompense Lame'), findsOneWidget);
      await tapText(tester, 'AJOUTER LA RÉCOMPENSE');
      await pumpUntilSettled(tester, attempts: 6);

      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'QA Recompense Lame',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Infos');
      await pumpUntilSettled(tester, attempts: 4);
      expect(
        find.text('Une relique remise en recompense (test QA).'),
        findsOneWidget,
      );
      expect(find.text('Dégâts'), findsOneWidget);
      expect(find.text('Propriétés'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await pumpUntilSettled(tester, attempts: 4);

      // --- Cas 5 : non-regression sur un objet du catalogue.
      await scrollUntilVisibleThenTap(
        tester,
        find.byType(ListView).first,
        'Objet',
      );
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Depuis le catalogue');
      await pumpUntilSettled(tester, attempts: 4);
      await tester.enterText(find.byType(TextFormField).first, 'longue');
      await pumpUntilSettled(tester, attempts: 4);
      if (find.text('Épée longue').evaluate().isNotEmpty) {
        await tapText(tester, 'Épée longue');
        await pumpUntilSettled(tester, attempts: 4);
        await tapText(tester, 'AJOUTER');
        await pumpUntilSettled(tester, attempts: 6);

        await scrollUntilVisibleThenTap(
          tester,
          find.byType(ListView).first,
          'Épée longue',
        );
        await pumpUntilSettled(tester, attempts: 4);
        await tapText(tester, 'Infos');
        await pumpUntilSettled(tester, attempts: 4);
        expect(
          find.text('Dégâts'),
          findsOneWidget,
          reason: 'objet du catalogue, section Degats toujours affichee',
        );
        await tester.tap(find.byIcon(Icons.close));
        await pumpUntilSettled(tester, attempts: 4);
      } else {
        // ignore: avoid_print
        print(
          'OBSERVATION: Epee longue absente du catalogue -- cas 5 non '
          'verifie par ce test (repli sur flutter test).',
        );
        await tapTextIfPresent(tester, 'Annuler');
        await pumpUntilSettled(tester, attempts: 4);
      }

      // --- Cas 6 : fiche partagee -- regenere le token depuis l'ecran
      // "Partager" reel, puis verifie directement le RPC
      // get_shared_character (meme fonction serveur que
      // CharacterSharingRepository.fetchSharedCharacter).
      await tapText(tester, 'PERSO');
      await pumpUntilSettled(tester, attempts: 4);
      await tester.tap(find.byTooltip('Partager'));
      await pumpUntilSettled(tester, attempts: 6);
      final activatedShare = await tapTextIfPresent(
        tester,
        'ACTIVER LE PARTAGE',
      );
      await pumpUntilSettled(tester, attempts: 6);
      if (!activatedShare) {
        final visibleTexts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .toList();
        // ignore: avoid_print
        print(
          'DIAGNOSTIC: bouton ACTIVER LE PARTAGE introuvable sur l ecran '
          'Partager. Textes visibles : $visibleTexts',
        );
      }

      final client = Supabase.instance.client;
      final characterRow = await client
          .from('characters')
          .select('id, share_token')
          .eq('name', name)
          .single();
      final characterId = characterRow['id'] as String;
      final token = characterRow['share_token'] as String?;
      expect(
        token,
        isNotNull,
        reason: 'le partage doit etre actif apres Activer le partage',
      );

      final shared = await client.rpc(
        'get_shared_character',
        params: {'p_token': token},
      ) as Map<String, dynamic>;
      final inventory = shared['inventory'] as List<dynamic>;
      final sharedWeapon = inventory.cast<Map<String, dynamic>>().firstWhere(
        (row) => row['custom_name'] == 'QA Zanbato Ancestral',
        orElse: () => <String, dynamic>{},
      );
      expect(
        sharedWeapon,
        isNotEmpty,
        reason: 'QA Zanbato Ancestral absent de get_shared_character',
      );
      expect(
        sharedWeapon['custom_description'],
        'Une lame de test QA transmise de génération en génération.',
      );
      expect(sharedWeapon['custom_damage_dice'], '2d8');
      expect(sharedWeapon['custom_damage_type'], 'perforant');
      expect(sharedWeapon['custom_properties'], ['legere', 'finesse']);

      // Nettoyage : desactive le partage puis supprime le personnage de
      // test (voir integration_test/README.md).
      await client
          .from('characters')
          .update({'share_token': null})
          .eq('id', characterId);
      await client.from('characters').delete().eq('id', characterId);
    },
  );
}
