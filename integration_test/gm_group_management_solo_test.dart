// Simulation utilisateur (05/11/2026) -- role MJ, scenario solo (sans second
// compte "joueur", pas encore disponible -- voir le compte-rendu de campagne
// correspondant dans docs/retours-utilisateurs.md). Pilote la vraie app sur
// un emulateur reel, contre le projet Supabase distant partage dev/staging/
// prod, pour juger -- pas seulement verifier -- le parcours MJ de gestion de
// groupe de bout en bout : creer un groupe, consulter ses onglets, generer/
// consulter le code d'invitation, ajouter au butin commun, tenter d'ecrire
// une note de groupe, renommer le groupe, regenerer son code, puis le
// dissoudre (nettoyage reel des donnees creees par ce test).
//
// Role choisi a la creation du groupe : "MJ -- sans personnage"
// (`GroupCreateScreen`), pas un personnage existant -- c'est le persona le
// plus realiste pour un MJ qui n'a pas forcement de fiche a lui dans sa
// propre table, ET celui qui evite de faire porter ce fichier (dedie a la
// gestion de groupe) par tout l'assistant de creation de personnage (9
// etapes, surface de regression hors-sujet ici). Consequence observee et
// deliberement verifiee par ce test : l'onglet "Notes" de l'ecran "Groupe"
// est entierement bloque pour ce persona (`GroupScreen._buildNotesTab`,
// `group_screen.dart` -- `characterId == null` renvoie
// `_NoNotesForGameMasterState` au lieu de l'editeur), donc l'etape "ecrire
// une note de groupe" du mandat ne peut pas aboutir avec ce role -- c'est un
// constat volontaire de ce test (voir docs/retours-utilisateurs.md, rôle MJ),
// pas un echec de parcours : le test fige ce comportement actuel par une
// assertion explicite plutot que de deviner silencieusement.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personnages/features/groups/presentation/widgets/group_invite_code_chip.dart';

import 'support/app_launch.dart';
import 'support/qa_test_account.dart';
import 'support/tap_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'MJ solo : créer un groupe, butin, note bloquée (MJ sans personnage), '
    'renommer, régénérer le code, dissoudre',
    (tester) async {
      if (!hasQaTestAccount) {
        // ignore: avoid_print
        print('SKIP: $qaTestAccountMissingReason');
        return;
      }

      // --- Préambule standard (voir integration_test/README.md) ---
      await launchApp(tester);
      if (find.text('ENTRER DANS LA TAVERNE').evaluate().isNotEmpty) {
        await loginWithQaTestAccount(tester);
      }
      await tapTextIfPresent(tester, 'Passer');
      await pumpUntilSettled(tester, attempts: 6);

      Future<void> goBack() async {
        // `.last` : si l'écran précédent reste monté sous celui-ci
        // (Navigator), son propre bouton retour matcherait aussi ce même
        // icône -- voir le commentaire de ce fichier plus bas pour le même
        // raisonnement appliqué aux TextFormField d'une sheet de
        // confirmation.
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).last);
        await pumpUntilSettled(tester, attempts: 6);
      }

      final groupNameOriginal =
          'QA-Sim-Groupe-${DateTime.now().millisecondsSinceEpoch}';

      // --- Étape 1 : point d'entrée "Groupes" depuis la liste des
      // personnages (icône ronde, voir character_list_screen.dart::
      // _GroupsButton -- pas de libellé texte ni de Key dédiée). ---
      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await pumpUntilSettled(tester, attempts: 6);

      // --- Étape 2 : créer un groupe ---
      // 1 tap pour arriver ici (bouton "CRÉER UN GROUPE" de GroupListScreen).
      await tapText(tester, 'CRÉER UN GROUPE');
      await pumpUntilSettled(tester, attempts: 4);

      await tester.enterText(
        find.byType(TextFormField).first,
        groupNameOriginal,
      );
      await tester.pump();

      // Rôle "MJ — sans personnage" : 1 tap pour ouvrir la sheet "CHOISIR TON
      // RÔLE", 1 tap pour choisir la ligne MJ (toujours en tête, voir
      // group_create_screen.dart::_GmOptionRow) -- 2 taps au total pour ce
      // choix, raisonnable, mais la tuile de déclenchement
      // ("Choisir un personnage ou un rôle") ne dit pas explicitement
      // qu'elle ouvre un sélecteur de RÔLE autant que de personnage : un MJ
      // qui découvre l'écran pourrait hésiter à taper dessus en pensant
      // qu'elle ne concerne que les joueurs avec personnage (voir le
      // registre de retours utilisateurs pour ce constat détaillé).
      await tapText(tester, 'Choisir un personnage ou un rôle');
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'MJ — sans personnage');
      await pumpUntilSettled(tester, attempts: 4);

      await tapText(tester, 'CRÉER LE GROUPE');
      // Appel réseau de création + chargement de groupDetailProvider --
      // attente généreuse, même rationale que launchApp/createCharacter.
      await pumpUntilSettled(tester, attempts: 12);

      // --- Étape 3 : consulter l'écran principal du groupe (onglets) ---
      // Jusqu'au 06/11/2026, un MJ créant un groupe avec le rôle
      // "MJ — sans personnage" atterrissait ici sur
      // `GroupCharacterReassignmentScreen` ("CHOISIR UN NOUVEAU
      // PERSONNAGE") au lieu de l'écran normal : `create-group` ne posait
      // pas `is_game_master = true` en l'absence de `character_id`
      // (D167/D168/D169, docs/dette-technique.md). Confirmé réglé par cette
      // exécution (06/11/2026, après redéploiement de `create-group`/
      // `join-group`/`set-group-character` depuis `main` du dépôt web) :
      // le test atteint directement `GroupScreen` ci-dessous, sans jamais
      // voir "CHOISIR UN NOUVEAU PERSONNAGE" -- plus de détection explicite
      // nécessaire ici.
      expect(
        find.text(groupNameOriginal.toUpperCase()),
        findsOneWidget,
        reason:
            'le header du groupe doit afficher son nom (WoodBackHeader, '
            'group_screen.dart) juste après la création -- navigation '
            'directe create -> group screen, sans repasser par la liste.',
      );
      expect(find.text('MEMBRES'), findsOneWidget);
      expect(find.text('BUTIN'), findsOneWidget);
      expect(find.text('NOTES'), findsOneWidget);
      // Groupe à 1 seul membre (le MJ) : la bannière + le code d'invitation
      // sont déjà visibles directement sur l'onglet "Membres" par défaut,
      // sans action supplémentaire -- bon réflexe UX (le MJ n'a pas besoin
      // de chercher "Paramètres" juste pour partager son code tout de suite
      // après la création).
      expect(find.byType(GroupInviteCodeChip), findsOneWidget);

      // --- Étape 4 : écran "Paramètres" -- consulter le code d'invitation
      // ---
      // 1 tap (icône réglages, visible uniquement pour le fondateur -- voir
      // group_screen.dart, `detail.isOwner`).
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await pumpUntilSettled(tester, attempts: 6);
      expect(find.text('PARAMÈTRES DU GROUPE'), findsOneWidget);
      expect(find.byType(GroupInviteCodeChip), findsOneWidget);
      final codeBeforeRegenerate = tester
          .widget<GroupInviteCodeChip>(find.byType(GroupInviteCodeChip))
          .code;
      expect(codeBeforeRegenerate, isNotEmpty);

      await goBack();

      // --- Étape 5 : ajouter au butin commun (monnaie) ---
      await tapText(tester, 'BUTIN');
      await pumpUntilSettled(tester, attempts: 4);
      // Bannière explicite pour un MJ sans personnage -- il peut gérer le
      // butin mais pas s'en attribuer une part (voir
      // group_treasure_tab_body.dart). Bon signal : l'app explique
      // POURQUOI les actions "S'attribuer"/"Répartir" sont désactivées
      // plutôt que de les griser sans explication.
      expect(
        find.text(
          'En tant que MJ sans personnage, tu peux gérer le butin commun '
          'mais pas t\'attribuer une part — seuls les membres avec un '
          'personnage le peuvent.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'AJOUTER AU BUTIN DU GROUPE');
      await pumpUntilSettled(tester, attempts: 4);
      // Sheet "AJOUTER AU BUTIN DU GROUPE" : 5 champs de monnaie, ordre
      // or/argent/cuivre/platine/électrum (voir
      // add_to_group_treasure_sheet.dart::_currencyFieldsOrder) -- le
      // premier est donc l'or.
      await tester.enterText(find.byType(TextFormField).first, '15');
      await tester.pump();
      await tapText(tester, 'AJOUTER AU BUTIN');
      await pumpUntilSettled(tester, attempts: 6);
      expect(
        find.text('15'),
        findsWidgets,
        reason:
            'la monnaie ajoutée (15 PO) doit apparaître dans la stat box '
            '"MONNAIE COMMUNE" après invalidation de groupTreasureProvider.',
      );

      // --- Étape 6 : écrire une note de groupe (texte) ---
      await tapText(tester, 'NOTES');
      await pumpUntilSettled(tester, attempts: 4);
      // CONSTAT (voir l'en-tête de ce fichier et docs/retours-utilisateurs.md,
      // rôle MJ) : un MJ sans personnage n'a tout simplement PAS d'onglet
      // "Notes" fonctionnel -- `group_notes` est indexé par `character_id`,
      // jamais applicable à sa propre ligne (group_screen.dart::
      // _buildNotesTab). Ce test fige ce comportement par une assertion
      // explicite plutôt que de passer à côté silencieusement : aucun champ
      // de saisie n'est présent, un message d'état désactivé le remplace.
      expect(find.byType(TextField), findsNothing);
      expect(
        find.text(
          'Le carnet de notes est propre à un personnage : en tant que MJ '
          'sans personnage, tu n\'en as pas ici.',
        ),
        findsOneWidget,
      );

      // --- Étape 7 : renommer le groupe + régénérer le code d'invitation
      // ---
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await pumpUntilSettled(tester, attempts: 6);

      final groupNameRenamed = '$groupNameOriginal-Renomme';
      await tester.enterText(
        find.byType(TextFormField).first,
        groupNameRenamed,
      );
      await tester.pump();
      await tapText(tester, 'ENREGISTRER');
      await pumpUntilSettled(tester, attempts: 6);

      // Régénérer le code -- confirmation PrimaryButton (PAS
      // DestructiveButton, voir group_confirmation_dialog.dart : le chantier
      // a explicitement choisi de NE PAS traiter cette action comme
      // destructrice, contrairement à "Exclure"/"Quitter"/"Dissoudre").
      await tapText(tester, 'RÉGÉNÉRER');
      await pumpUntilSettled(tester, attempts: 4);
      // `.last` : la boîte de dialogue de confirmation se superpose à
      // l'écran "Paramètres" (toujours monté dessous), qui affiche lui aussi
      // un bouton "RÉGÉNÉRER" -- seul le dernier dans l'arbre de widgets est
      // celui de la boîte de dialogue (showDialog empile une nouvelle entrée
      // d'Overlay par-dessus la page courante).
      await tester.tap(find.text('RÉGÉNÉRER').last);
      await pumpUntilSettled(tester, attempts: 6);

      final codeAfterRegenerate = tester
          .widget<GroupInviteCodeChip>(find.byType(GroupInviteCodeChip))
          .code;
      expect(
        codeAfterRegenerate,
        isNot(equals(codeBeforeRegenerate)),
        reason: 'régénérer doit invalider l\'ancien code et en produire un '
            'nouveau (GroupRepository.regenerateInviteCode).',
      );

      // --- Étape 8 : dissoudre le groupe (nettoyage réel) ---
      await tapText(tester, 'Dissoudre le groupe');
      await pumpUntilSettled(tester, attempts: 4);
      await tapText(tester, 'Continuer');
      await pumpUntilSettled(tester, attempts: 4);
      // `.last` : même raisonnement que le bouton "RÉGÉNÉRER" ci-dessus --
      // l'écran "Paramètres" (toujours monté sous la sheet) a lui aussi un
      // TextFormField (le nom du groupe), seul le dernier de l'arbre est
      // celui de la sheet de dissolution.
      await tester.enterText(
        find.byType(TextFormField).last,
        groupNameRenamed,
      );
      await tester.pump();
      await tapText(tester, 'Dissoudre définitivement');
      await pumpUntilSettled(tester, attempts: 10);

      // De retour à l'accueil (character_list_screen.dart) -- l'icône
      // "groupes" redevient le point d'entrée visible.
      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);

      // Vérification finale : le groupe dissous n'apparaît plus dans la
      // liste (aucune donnée orpheline laissée en base par ce test). Si
      // cette assertion échoue (groupe toujours listé), le nettoyage n'a
      // pas abouti -- voir integration_test/README.md pour la procédure
      // manuelle (table `groups` du projet Supabase distant partagé).
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await pumpUntilSettled(tester, attempts: 6);
      expect(
        find.text(groupNameRenamed),
        findsNothing,
        reason:
            'NETTOYAGE MANUEL REQUIS si cet assert échoue : groupe de test '
            '"$groupNameRenamed" potentiellement non dissous (table `groups` '
            'du projet Supabase distant partagé dev/staging/prod).',
      );
    },
  );
}
