// Verification QA en conditions reelles (campagne du 29/10/2026) de la tache
// "memorisation du filtre de preparation des sorts" (PR en cours,
// `feat/spell-preparation-filter-persistence`) -- pilote la vraie app sur un
// emulateur Android reel, contre le projet Supabase distant partage
// dev/staging/prod. Couvre les cas 1/2/3 du mandat QA (fiche rouverte,
// portee globale a l'appareil entre deux personnages differents,
// non-regression sur une classe sans preparation) ; le cas 4 (redemarrage
// reel de l'app) et le cas 5 (fiche partagee en lecture seule) sont verifies
// separement -- voir le compte-rendu QA correspondant.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personnages/core/widgets/segmented_toggle.dart';
import 'package:personnages/features/characters/domain/spell_preparation_filter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/app_launch.dart';
import 'support/character_creation_flow.dart';
import 'support/level_up_flow.dart';
import 'support/qa_test_account.dart';
import 'support/tap_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Filtre de preparation des sorts : memorise a la reouverture de la '
    'meme fiche, applique a une AUTRE fiche sans action du joueur, jamais '
    'impose a une classe sans preparation',
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

      final client = Supabase.instance.client;
      final createdCharacterIds = <String>[];

      SpellPreparationFilter? currentFilter() {
        final finder = find.byType(SegmentedToggle<SpellPreparationFilter>);
        if (finder.evaluate().isEmpty) return null;
        return tester
            .widget<SegmentedToggle<SpellPreparationFilter>>(finder)
            .value;
      }

      // --- Cas 1 : Clerc (classe a preparation) -- fixe explicitement le
      // filtre a "Prepares" (idempotent, ne presuppose aucune valeur deja
      // memorisee par une campagne QA anterieure sur ce meme emulateur),
      // puis ferme/rouvre la MEME fiche.
      final clercName = qaUniqueCharacterName('QA-Test-FiltrePrep-Clerc');
      await createCharacter(
        tester,
        characterName: clercName,
        raceName: 'Humain',
        className: 'Clerc',
        subclassName: 'Domaine de la Vie',
        backgroundName: 'Acolyte',
      );

      await openCharacterByName(tester, clercName);
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);

      expect(
        currentFilter(),
        isNotNull,
        reason:
            'carte PRÉPARATION DES SORTS attendue pour un Clerc '
            '(classe a preparation)',
      );

      // Baseline connue : "Tous", quelle que soit la valeur deja memorisee.
      await tapText(tester, 'TOUS');
      await pumpUntilSettled(tester, attempts: 4);
      expect(currentFilter(), SpellPreparationFilter.all);

      await tapText(tester, 'PRÉPARÉS');
      await pumpUntilSettled(tester, attempts: 4);
      expect(currentFilter(), SpellPreparationFilter.prepared);

      // Ferme la fiche (retour a la liste) puis la rouvre : nouvelle
      // instance de `CharacterSpellsTabBody`, pas juste une navigation
      // d'onglet au sein du meme widget.
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await pumpUntilSettled(tester, attempts: 6);
      await openCharacterByName(tester, clercName);
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);

      expect(
        currentFilter(),
        SpellPreparationFilter.prepared,
        reason:
            'cas 1 : le filtre "Préparés" doit rester selectionne a la '
            'reouverture de la MEME fiche, pas repasser a "Tous"',
      );

      // --- Cas 2 : AUTRE fiche (Magicien, classe differente a
      // preparation) -- le filtre memorise doit deja etre applique a
      // l'ouverture, sans aucun tap sur la bascule.
      final magicienName = qaUniqueCharacterName('QA-Test-FiltrePrep-Magicien');
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await pumpUntilSettled(tester, attempts: 6);
      await createCharacter(
        tester,
        characterName: magicienName,
        raceName: 'Humain',
        className: 'Magicien',
        backgroundName: 'Acolyte',
      );

      await openCharacterByName(tester, magicienName);
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);

      expect(
        currentFilter(),
        SpellPreparationFilter.prepared,
        reason:
            'cas 2 : portee globale a l\'appareil -- le filtre "Préparés" '
            'choisi sur la fiche du Clerc doit deja etre applique a '
            'l\'ouverture de la fiche du Magicien, sans action du joueur',
      );

      // --- Cas 3 (non-regression) : classe sans mecanisme de preparation
      // (Ensorceleur seul, sorts connus) -- le filtre memorise globalement
      // ne doit jamais s'imposer : pas de carte de preparation du tout.
      final ensorceleurName = qaUniqueCharacterName(
        'QA-Test-FiltrePrep-Ensorceleur',
      );
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await pumpUntilSettled(tester, attempts: 6);
      await createCharacter(
        tester,
        characterName: ensorceleurName,
        raceName: 'Humain',
        className: 'Ensorceleur',
        autoPickSubclassIfOffered: true,
        backgroundName: 'Acolyte',
      );

      await openCharacterByName(tester, ensorceleurName);
      if (find.text('SORTS').evaluate().isNotEmpty) {
        await tapText(tester, 'SORTS');
        await pumpUntilSettled(tester, attempts: 4);
      }

      expect(
        find.text('PRÉPARATION DES SORTS'),
        findsNothing,
        reason:
            'cas 3 : un Ensorceleur seul (sorts connus, jamais prepares) ne '
            'doit jamais se voir imposer le filtre "Préparés" memorise par '
            'ailleurs -- garde-fou `hasPreparation`',
      );
      expect(currentFilter(), isNull);

      // Nettoyage (voir integration_test/README.md) : recupere les 3 ids
      // par nom puis supprime.
      for (final name in [clercName, magicienName, ensorceleurName]) {
        final row = await client
            .from('characters')
            .select('id')
            .eq('name', name)
            .maybeSingle();
        if (row != null) createdCharacterIds.add(row['id'] as String);
      }
      for (final id in createdCharacterIds) {
        await client.from('characters').delete().eq('id', id);
      }
    },
  );
}
