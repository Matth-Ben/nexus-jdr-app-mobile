// Campagne "simulation utilisateur" (chef de projet, vérification ciblée des
// correctifs F04/F05/F06 + nouveautés "temps réel groupes"/"notes multi-
// entrées", voir `docs/retours-utilisateurs.md`) : couvre les deux points de
// cette campagne qu'aucun fichier existant de ce dossier ne vérifie encore en
// conditions réelles --
//
// 1. Synchro Realtime des PV d'un membre dans l'écran "Groupe" côté MJ, SANS
//    que le MJ quitte/rouvre cet écran -- le bug initial signalé par
//    Matthias (voir `lib/features/groups/presentation/providers/
//    group_providers.dart::groupMembersRealtimeWatcher`, ajouté depuis). Le
//    harnais habituel de ce dossier (`_switchAccount` dans
//    `adventure_session_cleric_groups_test.dart`) change de compte en
//    DÉMONTANT l'app (retour à la liste, déconnexion, reconnexion) -- ce qui
//    démonterait justement l'écran "Groupe" qu'on veut observer sans
//    navigation. Pour vérifier le scénario EXACT demandé ("le joueur modifie
//    ses PV, le MJ voit la mise à jour sans quitter l'écran Groupe"), ce
//    fichier bascule l'app sur le compte MJ UNE SEULE FOIS, tôt (avant même
//    de créer le groupe), puis reste sur ce compte -- en particulier reste
//    sur l'écran "Groupe" du début à la fin de la vérification Realtime.
//    L'écriture du joueur est simulée par un second `SupabaseClient`
//    indépendant (jamais celui de l'app testée), authentifié directement
//    avec les identifiants du compte joueur -- un UPDATE Postgres réel sur
//    `characters.current_hp`, exactement la même écriture que celle que
//    ferait `hp_adjustment_sheet.dart` depuis l'app du joueur. Le canal
//    Realtime souscrit par le MJ (`channel.onPostgresChanges`, filtré sur
//    `characters.id`) reçoit cet événement quel que soit le client qui a
//    écrit la ligne -- Supabase Realtime applique la RLS de l'ABONNÉ (le MJ,
//    déjà autorisé à lire les PV de ses coéquipiers via la RLS existante de
//    `characters`, voir `GroupRepository.fetchGroupDetail`), pas celle de
//    l'auteur de l'écriture.
//
// 2. Carnet de notes de groupe multi-entrées (PR #230,
//    `group_notes_tab_body.dart`) : ajout de plusieurs entrées (avec/sans
//    titre), tri du plus récent au plus ancien, modification/suppression
//    d'une entrée sans affecter les autres -- jamais exécuté en conditions
//    réelles jusqu'ici (seul l'ancien carnet "une note par membre" avait été
//    vérifié sur émulateur, voir `gm_group_management_solo_test.dart`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personnages/core/network/env_config.dart';
import 'package:personnages/features/groups/presentation/widgets/group_invite_code_chip.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/app_launch.dart';
import 'support/character_creation_flow.dart';
import 'support/qa_test_account.dart';
import 'support/tap_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Groupe : synchro PV en temps réel (MJ) + carnet de notes multi-entrées',
    (tester) async {
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
      // Préparation : un second `SupabaseClient` indépendant, authentifié
      // comme le compte joueur -- voir le commentaire d'en-tête. Jamais
      // celui de l'app testée (`Supabase.instance.client`, qui bascule sur
      // le compte MJ dès l'étape 2 et y reste jusqu'à la fin).
      // ---------------------------------------------------------------
      final playerClient = SupabaseClient(
        EnvConfig.supabaseUrl,
        EnvConfig.supabaseAnonKey,
      );
      addTearDown(() async {
        await playerClient.dispose();
      });
      final signInResponse = await playerClient.auth.signInWithPassword(
        email: qaTestEmailJoueur,
        password: qaTestPasswordJoueur,
      );
      if (signInResponse.session == null) {
        fail(
          'Préparation : connexion du second SupabaseClient (compte joueur) '
          'échouée -- impossible de simuler une écriture joueur pendant que '
          "l'app reste sur le compte MJ.",
        );
      }

      // ---------------------------------------------------------------
      // Étape 1 : connexion joueur (app testée), création d'un personnage
      // minimal via l'assistant UI habituel -- Guerrier (aucun choix de
      // sous-classe au niveau 1, "Style de combat" résolu automatiquement
      // par [createCharacter], voir sa doc de classe).
      // ---------------------------------------------------------------
      await launchApp(tester);
      final client = Supabase.instance.client;
      if (find.text('ENTRER DANS LA TAVERNE').evaluate().isNotEmpty) {
        await loginWithQaTestAccountJoueur(tester);
      }
      await tapTextIfPresent(tester, 'Passer');
      await pumpUntilSettled(tester, attempts: 6);

      final characterName = qaUniqueCharacterName('QA-Realtime-Guerrier');
      await createCharacter(
        tester,
        characterName: characterName,
        raceName: 'Humain',
        className: 'Guerrier',
        backgroundName: 'Acolyte',
      );

      final characterRow = await client
          .from('characters')
          .select('id, current_hp, max_hp')
          .eq('name', characterName)
          .single();
      final characterId = characterRow['id'] as String;
      final initialCurrentHp = (characterRow['current_hp'] as num).toInt();
      final initialMaxHp = (characterRow['max_hp'] as num).toInt();
      observe(
        'Etape1 - personnage joueur cree',
        '$characterId ($initialCurrentHp/$initialMaxHp)',
      );
      addTearDown(() async {
        await playerClient.from('characters').delete().eq('id', characterId);
      });

      // ---------------------------------------------------------------
      // Étape 2 : bascule UNIQUE sur le compte MJ -- jamais de retour au
      // compte joueur ensuite dans ce fichier (voir le commentaire
      // d'en-tête). Création du groupe de test (MJ -- sans personnage).
      // ---------------------------------------------------------------
      await _switchAccount(tester, login: loginWithQaTestAccount);

      final groupName = qaUniqueCharacterName('QA-Realtime-Groupe');
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
      // `GroupCreateScreen` navigue directement vers `/groups/{id}` après
      // création (voir `group_create_screen.dart`) : l'app est déjà sur
      // l'écran "Groupe" (onglet Membres par défaut), AUCUNE navigation
      // supplémentaire n'est nécessaire -- c'est précisément cet écran
      // qu'on veut garder affiché jusqu'à la fin de la vérification
      // Realtime (étapes 4-5 ci-dessous).
      observe('Etape2 - ecran Groupe apres creation', visibleTexts());

      final inviteCodeChips = tester.widgetList<GroupInviteCodeChip>(
        find.byType(GroupInviteCodeChip),
      );
      if (inviteCodeChips.isEmpty) {
        fail(
          'ECART : code d\'invitation introuvable juste après la création '
          'du groupe "$groupName".',
        );
      }
      final inviteCode = inviteCodeChips.first.code;
      observe('Etape2 - code d\'invitation genere', inviteCode);
      final groupId = await client
          .from('groups')
          .select('id')
          .eq('name', groupName)
          .single()
          .then((row) => row['id'] as String);
      addTearDown(() async {
        await client.from('groups').delete().eq('id', groupId);
      });

      // ---------------------------------------------------------------
      // Étape 3 : le joueur rejoint le groupe -- directement via
      // `playerClient` (edge function `join-group`, mêmes paramètres que
      // `GroupRepository.joinGroup`), jamais via un écran "Rejoindre"
      // piloté par l'app testée (qui reste sur le compte MJ -- voir le
      // commentaire d'en-tête).
      // ---------------------------------------------------------------
      try {
        final joinResponse = await playerClient.functions.invoke(
          'join-group',
          body: {'code': inviteCode, 'character_id': characterId},
        );
        observe('Etape3 - reponse join-group', joinResponse.data);
      } catch (error) {
        fail(
          'Préparation : "join-group" a échoué ($error) -- impossible de '
          'poursuivre la vérification Realtime.',
        );
      }

      // ---------------------------------------------------------------
      // Étape 4 (F07) : SANS AUCUNE navigation (aucun tap, aucun retour
      // d'écran, aucune réouverture), le MJ resté sur l'onglet Membres doit
      // voir arriver le joueur qui vient de rejoindre (`group_members`
      // INSERT, voir `GroupRepository.subscribeToMemberUpdates`). Seulement
      // des `pump` en boucle ; le délai est mesuré.
      // ---------------------------------------------------------------
      observe('Etape4 - Membres (MJ) juste apres join-group', visibleTexts());
      final joinWatch = Stopwatch()..start();
      var sawMember = false;
      for (var attempt = 0; attempt < 30 && !sawMember; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        sawMember = find.textContaining(characterName).evaluate().isNotEmpty;
      }
      joinWatch.stop();
      observe(
        "Etape4 - delai d'apparition du nouveau membre (sans navigation)",
        sawMember ? '${joinWatch.elapsedMilliseconds} ms' : 'JAMAIS (15 s)',
      );
      observe('Etape4 - Membres (MJ) apres attente', visibleTexts());
      if (!sawMember) {
        fail(
          'ECART F07 : le personnage "$characterName" n\'apparaît pas dans '
          "l'onglet Membres côté MJ, sans navigation, 15 s après que le "
          'joueur a rejoint le groupe. Texte visible : ${visibleTexts()}',
        );
      }
      final initialHpText = '$initialCurrentHp/$initialMaxHp';
      if (find.text(initialHpText).evaluate().isEmpty) {
        fail(
          'ECART : PV initiaux "$initialHpText" du membre "$characterName" '
          'absents de l\'onglet Membres avant toute modification. Texte '
          'visible : ${visibleTexts()}',
        );
      }

      // ---------------------------------------------------------------
      // Étape 5 : le joueur (via `playerClient`, PAS l'app testée) encaisse
      // 4 dégâts -- écriture Postgres réelle sur `characters.current_hp`,
      // exactement la colonne filtrée par le canal Realtime souscrit par le
      // MJ (voir `GroupRepository.subscribeToMemberUpdates`).
      // ---------------------------------------------------------------
      final damagedCurrentHp = initialCurrentHp - 4;
      await playerClient
          .from('characters')
          .update({'current_hp': damagedCurrentHp})
          .eq('id', characterId);
      observe(
        'Etape5 - current_hp mis a jour via playerClient (hors app testee)',
        damagedCurrentHp,
      );

      // ---------------------------------------------------------------
      // Étape 6 : SANS AUCUNE navigation côté MJ (aucun tap d'onglet,
      // aucun retour d'écran) -- seulement des `pump` successifs pour
      // laisser le canal Realtime recevoir l'événement et
      // `groupDetailProvider` se réinvalider -- vérifie l'apparition des
      // nouveaux PV.
      // ---------------------------------------------------------------
      final damagedHpText = '$damagedCurrentHp/$initialMaxHp';
      var sawUpdatedHp = false;
      for (var attempt = 0; attempt < 20 && !sawUpdatedHp; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        sawUpdatedHp = find.text(damagedHpText).evaluate().isNotEmpty;
      }
      await settleQuickly(tester);
      sawUpdatedHp =
          sawUpdatedHp || find.text(damagedHpText).evaluate().isNotEmpty;
      observe(
        'Etape6 - onglet Membres (MJ) apres modification PV joueur '
        '(sans navigation)',
        visibleTexts(),
      );
      if (!sawUpdatedHp) {
        fail(
          'ECART Realtime : "$damagedHpText" (nouveaux PV du joueur) jamais '
          'apparu dans l\'onglet Membres côté MJ sans navigation, après '
          '10 secondes d\'attente (20×500ms) -- la synchro Realtime ne '
          'fonctionne pas comme attendu. Texte visible : ${visibleTexts()}',
        );
      }

      // ---------------------------------------------------------------
      // Étape 6bis (F07, DELETE) : le joueur quitte le groupe via
      // `playerClient` -- même requête que `GroupRepository.leaveGroup`
      // (suppression de sa propre ligne `group_members`, RLS du joueur). Le
      // MJ, toujours sans navigation, doit voir le membre disparaître.
      // ---------------------------------------------------------------
      final playerUserId = playerClient.auth.currentUser!.id;
      await playerClient
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', playerUserId);
      final leaveWatch = Stopwatch()..start();
      var memberGone = false;
      for (var attempt = 0; attempt < 30 && !memberGone; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        memberGone = find.textContaining(characterName).evaluate().isEmpty;
      }
      leaveWatch.stop();
      observe(
        'Etape6bis - delai de disparition du membre (sans navigation)',
        memberGone ? '${leaveWatch.elapsedMilliseconds} ms' : 'JAMAIS (15 s)',
      );
      observe('Etape6bis - Membres (MJ) apres depart', visibleTexts());
      if (!memberGone) {
        fail(
          'ECART F07 (DELETE) : "$characterName" est toujours affiché côté '
          'MJ, sans navigation, 15 s après son départ du groupe. Texte '
          'visible : ${visibleTexts()}',
        );
      }

      // ---------------------------------------------------------------
      // Étape 7 : carnet de notes multi-entrées -- le MJ (sans personnage)
      // ajoute 3 entrées distinctes (2 avec titre, 1 sans), vérifie l'ordre
      // (plus récent en premier), modifie puis supprime une entrée sans
      // affecter les autres.
      // ---------------------------------------------------------------
      await tapText(tester, 'NOTES');
      await pumpUntilSettled(tester, attempts: 4);
      observe('Etape7 - onglet NOTES avant saisie', visibleTexts());

      Future<void> addNote({String? title, required String body}) async {
        await tapText(tester, 'Ajouter une note');
        await pumpUntilSettled(tester, attempts: 4);
        if (title != null) {
          await tester.enterText(find.byType(TextFormField).first, title);
          await tester.pump();
        }
        await tester.enterText(find.byType(TextFormField).last, body);
        await tester.pump();
        // `PrimaryButton` met TOUJOURS son libellé en majuscules (voir
        // `core/widgets/primary_button.dart`) -- "Enregistrer" (casse
        // source passée par `group_note_entry_edit_sheet.dart`) est
        // introuvable tel quel, même piège déjà documenté pour "VALEUR
        // MOYENNE"/"AJOUTER AU BUTIN" dans
        // `adventure_session_cleric_groups_test.dart`.
        await tapText(tester, 'ENREGISTRER');
        await pumpUntilSettled(tester, attempts: 6);
      }

      const noteBody1 = 'Première note : embuscade sur la route du nord.';
      const noteTitle2 = 'Chapitre 2';
      const noteBody2 = 'Deuxième note : rencontre avec le marchand nain.';
      const noteTitle3 = 'Chapitre 3';
      const noteBody3 = 'Troisième note : découverte de la carte au trésor.';

      await addNote(body: noteBody1);
      if (find.textContaining(noteBody1).evaluate().isEmpty) {
        fail(
          'ECART : note sans titre "$noteBody1" absente du carnet juste '
          'après son ajout. Texte visible : ${visibleTexts()}',
        );
      }

      await addNote(title: noteTitle2, body: noteBody2);
      if (find.text(noteTitle2).evaluate().isEmpty ||
          find.textContaining(noteBody2).evaluate().isEmpty) {
        fail(
          'ECART : note avec titre "$noteTitle2" absente du carnet juste '
          'après son ajout. Texte visible : ${visibleTexts()}',
        );
      }

      await addNote(title: noteTitle3, body: noteBody3);
      observe('Etape7 - carnet apres 3 ajouts', visibleTexts());
      if (find.text(noteTitle3).evaluate().isEmpty ||
          find.textContaining(noteBody3).evaluate().isEmpty) {
        fail(
          'ECART : note avec titre "$noteTitle3" absente du carnet juste '
          'après son ajout. Texte visible : ${visibleTexts()}',
        );
      }

      // Tri du plus récent au plus ancien : la 3e note ajoutée (titre
      // "Chapitre 3") doit apparaître AVANT la 1ère (sans titre) dans
      // l'ordre vertical du `ListView` -- comparé via l'offset Y des deux
      // `Text` correspondants plutôt qu'un simple ordre de `find` (qui ne
      // reflète pas forcément l'ordre visuel).
      final chapitre3Center = tester.getCenter(find.text(noteTitle3));
      final note1Center = tester.getCenter(find.textContaining(noteBody1));
      observe(
        'Etape7 - positions verticales (tri attendu : Chapitre 3 au-dessus)',
        'Chapitre3.dy=${chapitre3Center.dy}, note1.dy=${note1Center.dy}',
      );
      if (chapitre3Center.dy >= note1Center.dy) {
        fail(
          'ECART de tri : la note la plus récente ("$noteTitle3") '
          'n\'apparaît pas au-dessus de la plus ancienne ("$noteBody1") '
          'dans le carnet -- tri "plus récent au plus ancien" non respecté.',
        );
      }

      // Modifie la note "Chapitre 2" -- vérifie que la modification
      // n'affecte NI "Chapitre 3" NI la note sans titre.
      await tapText(tester, noteTitle2);
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Modifier');
      await pumpUntilSettled(tester, attempts: 4);
      const noteBody2Edited =
          'Deuxième note, MODIFIÉE : le marchand était un '
          'imposteur.';
      await tester.enterText(find.byType(TextFormField).last, noteBody2Edited);
      await tester.pump();
      await tapText(tester, 'ENREGISTRER');
      await pumpUntilSettled(tester, attempts: 6);
      observe(
        'Etape7 - carnet apres modification de Chapitre 2',
        visibleTexts(),
      );
      if (find.textContaining(noteBody2Edited).evaluate().isEmpty) {
        fail(
          'ECART : note "$noteTitle2" modifiée absente ("$noteBody2Edited") '
          'après enregistrement. Texte visible : ${visibleTexts()}',
        );
      }
      if (find.text(noteTitle3).evaluate().isEmpty ||
          find.textContaining(noteBody1).evaluate().isEmpty) {
        fail(
          'ECART : la modification de "$noteTitle2" a fait disparaître une '
          'autre entrée ("$noteTitle3" ou "$noteBody1"). Texte visible : '
          '${visibleTexts()}',
        );
      }

      // Supprime la note "Chapitre 3" -- vérifie que la suppression
      // n'affecte NI "Chapitre 2" (modifiée) NI la note sans titre.
      await tapText(tester, noteTitle3);
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Supprimer');
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Supprimer');
      await pumpUntilSettled(tester, attempts: 6);
      observe(
        'Etape7 - carnet apres suppression de Chapitre 3',
        visibleTexts(),
      );
      if (find.text(noteTitle3).evaluate().isNotEmpty) {
        fail(
          'ECART : la note "$noteTitle3" est toujours visible après sa '
          'suppression. Texte visible : ${visibleTexts()}',
        );
      }
      if (find.textContaining(noteBody2Edited).evaluate().isEmpty ||
          find.textContaining(noteBody1).evaluate().isEmpty) {
        fail(
          'ECART : la suppression de "$noteTitle3" a fait disparaître une '
          'autre entrée ("$noteTitle2" modifiée ou "$noteBody1"). Texte '
          'visible : ${visibleTexts()}',
        );
      }

      // ---------------------------------------------------------------
      // Nettoyage : les `addTearDown` déjà enregistrés suppriment le
      // personnage (via `playerClient`, propriétaire réel) et le groupe
      // (via `client`, le MJ -- `owner_id`) -- les 2 notes restantes
      // disparaissent avec le groupe (cascade), jamais nettoyées à part.
      // ---------------------------------------------------------------
      observe(
        'Nettoyage',
        'personnage $characterName (id $characterId) et groupe $groupName '
            'seront supprimés par addTearDown.',
      );
    },
  );
}

/// Icône ronde du bouton "Profil" de `CharacterListScreen`
/// (`character_list_screen.dart::_ProfileButton`) -- calque exact du
/// finder de même nom dans `adventure_session_cleric_groups_test.dart` (voir
/// sa doc pour le piège évité : ne JAMAIS confondre avec le repli
/// `PortraitFrame.fallbackIcon`, qui matche aussi `Icons.person_outline`
/// mais sans `size: 22`).
Finder get _profileButtonFinder => find.byWidgetPredicate(
  (widget) =>
      widget is Icon &&
      widget.icon == Icons.person_outline &&
      widget.size == 22,
);

/// Revient à `CharacterListScreen` depuis n'importe quel écran de ce
/// scénario -- calque de `adventure_session_cleric_groups_test.dart`, voir
/// sa doc de classe.
Future<void> _goToCharacterList(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    if (_profileButtonFinder.evaluate().isNotEmpty) return;
    final back = find.byIcon(Icons.arrow_back_ios_new);
    if (back.evaluate().isEmpty) break;
    await tester.tap(back.first);
    await pumpUntilSettled(tester, attempts: 4);
  }
}

/// Change de compte de test en conditions réelles -- calque de
/// `adventure_session_cleric_groups_test.dart`, voir sa doc de classe.
/// Utilisé UNE SEULE FOIS dans ce fichier (joueur -> MJ, voir le commentaire
/// d'en-tête) : contrairement au fichier d'origine, jamais de retour vers le
/// compte joueur ensuite dans l'app testée (seul `playerClient`, un second
/// `SupabaseClient` indépendant, continue d'agir pour ce compte).
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
