import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';

import 'character_creation_flow.dart' show fillAvailableCheckableTiles;
import 'tap_helpers.dart';

/// Ouvre le flux de montee de niveau depuis la fiche personnage deja
/// affichee (CharacterDetailScreen) : bouton "+ XP" (ouvre AddXpSheet) puis
/// lien "Monter de niveau manuellement" (voir
/// widgets/add_xp_sheet.dart / widgets/character_vitals_card.dart), qui
/// pousse /characters/:id/level-up?level={totalLevel+1} sans avoir besoin
/// de gerer l'XP du tout -- une seule montee de niveau (+1) par appel.
Future<void> openLevelUpFromCharacterDetail(WidgetTester tester) async {
  await tapText(tester, '+ XP');
  await pumpUntilSettled(tester, attempts: 4);
  await tapText(tester, 'Monter de niveau manuellement');
  await pumpUntilSettled(tester, attempts: 6);
}

/// Choisit quelle option taper quand l'etape "Choix a faire" (sous-classe,
/// style de combat, ennemi jure, pacte -- voir
/// domain/level_up_choice_kind.dart) affiche des SelectableOptionTile :
/// recoit la liste des titres actuellement visibles, renvoie celui a taper.
/// `null` pour laisser [runOneLevelUp] taper le premier disponible (repli
/// par defaut, suffisant quand le choix precis n'importe pas pour le
/// scenario).
typedef ChoiceStepPicker = String? Function(List<String> availableTitles);

/// Pilote le flux de montee de niveau (level_up_screen.dart) de bout en
/// bout pour UN seul niveau, depuis l'annonce initiale jusqu'au retour sur
/// la fiche personnage (ou jusqu'a l'ecran de blocage "NIVEAU ATTEINT",
/// voir [LevelUpOutcome]).
///
/// Generique par construction : les etapes "Sorts"/"Invocations"/
/// "Disciplines elementaires" sont remplies via [fillAvailableCheckableTiles]
/// (aucun nom de sort/invocation/discipline en dur). L'etape "Choix a
/// faire" (sous-classe/style de combat/ennemi favori/pacte) est detectee
/// par la presence de SelectableOptionTile alors que "CONTINUER" est
/// desactive -- [choicePicker] decide laquelle taper (voir sa doc).
Future<LevelUpOutcome> runOneLevelUp(
  WidgetTester tester, {
  ChoiceStepPicker? choicePicker,
  String? multiclassInto,
}) async {
  // Etape `classDecision` (multiclassage) : passe avant TOUT le reste, y
  // compris l'annonce de niveau (voir level_up_screen.dart, commentaire de
  // `_hasClassDecision`) -- affichee seulement si au moins une classe est
  // eligible (prerequis des deux classes remplis, voir
  // domain/multiclass_prerequisites.dart). Defaut "Continuer" deja
  // preselectionne (meme convention que
  // test/.../level_up_screen_test.dart::pushLevelUp) : [multiclassInto]
  // tape explicitement la tuile "Se multiclasser en {classe}" avant de
  // valider, sinon la montee continue simplement la classe primaire.
  const classDecisionInstruction = "Choisissez comment ce niveau s'applique.";
  if (find.text(classDecisionInstruction).evaluate().isNotEmpty) {
    if (multiclassInto != null) {
      await tapText(tester, 'Se multiclasser en $multiclassInto');
      await pumpUntilSettled(tester, attempts: 4);
    }
    await tapText(tester, 'CONTINUER');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Annonce du niveau (increment 4) : toujours affichee en premier (une
  // fois `classDecision` franchie, si elle etait presente).
  await tapText(tester, 'CONTINUER');
  await pumpUntilSettled(tester, attempts: 4);

  // Ecran de blocage ("NIVEAU ATTEINT") si choice_type non resolu --
  // s'arrete ici, l'appelant lit le detail affiche plutot que de forcer la
  // suite.
  if (find.text('NIVEAU ATTEINT').evaluate().isNotEmpty) {
    final blockingText = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    return LevelUpOutcome(
      blocked: true,
      screenText: blockingText,
      hadElementalDisciplinesStep: false,
      hadManeuversStep: false,
    );
  }

  // Etape "Points de vie" (valeurs par defaut : jet de de, rien a choisir).
  await tapText(tester, 'CONTINUER');
  await pumpUntilSettled(tester, attempts: 4);

  // Etape "Aptitudes de classe automatiques" (rien a choisir).
  await tapText(tester, 'CONTINUER');
  await pumpUntilSettled(tester, attempts: 4);

  // Etape "Choix a faire" (sous-classe/style de combat/ennemi
  // favori/pacte), si ce niveau en declenche une -- detectee par la
  // presence de SelectableOptionTile alors que "CONTINUER" n'a pas encore
  // ete pousse plus loin (le bouton existe mais reste desactive tant
  // qu'aucune tuile n'est choisie -- `find.text('CONTINUER')` le trouve
  // dans les deux cas, seule la presence de tuiles distingue cette etape de
  // la suite).
  // Bug trouve et corrige pendant cette campagne QA (symptome : le flux
  // restait des dizaines de minutes sur cette etape sans jamais planter) :
  // un `while (true)` qui ne s'arretait QUE si plus aucune tuile n'etait
  // montee -- or les tuiles de ce choix RESTENT toujours montees une fois
  // l'ecran affiche (seul leur etat `selected` change au tap, voir
  // `SelectableOptionTile`/`level_up_screen.dart::_buildOptionListBody`) :
  // la condition d'arret n'etait donc jamais vraie, et [choicePicker]
  // renvoyant deterministiquement le MEME titre, le meme tap etait repete
  // indefiniment. Un seul tap suffit a selectionner la tuile (active
  // "CONTINUER", voir `_canContinueChoiceStep`) -- pas besoin de boucle.
  final optionTitles = tester
      .widgetList<SelectableOptionTile>(find.byType(SelectableOptionTile))
      .map((t) => t.title)
      .toList();
  final hadChoiceStep = optionTitles.isNotEmpty;
  if (hadChoiceStep) {
    final chosen = choicePicker?.call(optionTitles) ?? optionTitles.first;
    await tapText(tester, chosen);
    await pumpUntilSettled(tester, attempts: 4);
  }
  // Etape ASI ("Amelioration ou don") : contrairement a l'etape 4/9 de la
  // creation, l'allocation ne part pas d'un defaut deja valide -- il faut
  // reellement taper le bouton "+" (StepperCounter, icone Icons.add,
  // libelle semantique "Augmenter") pour atteindre le budget de 2 points,
  // sinon "CONTINUER" reste desactive. Mode "Repartir +2" (segment
  // preselectionne par defaut) : +2 sur la premiere caracteristique de la
  // liste suffit, peu importe laquelle pour les scenarios de cette
  // campagne. Detectee par l'instruction qui lui est propre -- distincte
  // de l'etape "Choix a faire" a liste (sous-classe/style de combat/ennemi
  // juré/pacte), qui n'a pas besoin de ce traitement special (deja geree
  // par la boucle SelectableOptionTile ci-dessus).
  final hasAsiStep = find
      .text('Choisissez comment progresser.')
      .evaluate()
      .isNotEmpty;
  if (hasAsiStep) {
    final incrementIcon = find.byIcon(Icons.add).first;
    await tester.ensureVisible(incrementIcon);
    await settleQuickly(tester);
    await tester.tap(incrementIcon);
    await tester.pump();
    await tester.tap(incrementIcon);
    await settleQuickly(tester);
  }
  // Un seul CONTINUER explicite ici -- UNIQUEMENT pour sortir de l'etape
  // "Choix a faire"/ASI elle-meme si elle a ete rencontree : sans elle (ex.
  // niveau 2 du Moine, qui n'a ni choix ni ASI), l'etape "Aptitudes" juste
  // au-dessus mene DEJA directement au Recapitulatif -- un CONTINUER
  // supplementaire ici tapperait alors a tort celui du Recapitulatif
  // (applique la montee en avance), laissant le CONTINUER explicite de fin
  // de fonction sans rien a taper (plus de bouton sur la fiche personnage
  // deja revenue). Bug trouve et corrige pendant cette campagne QA en
  // observant ce symptome exact (voir le rapport correspondant).
  if (hadChoiceStep || hasAsiStep) {
    await tapText(tester, 'CONTINUER');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Etape "Sorts" (si cette classe/niveau en declenche une) : meme
  // strategie generique que l'assistant de creation. Peut avoir plusieurs
  // onglets-pilules ("Mineurs"/"Sorts"/"Grimoire", voir
  // core/widgets/spell_level_tab_selector.dart) selon la classe/le niveau --
  // `CONTINUER` reste desactive tant que CHAQUE onglet affiche n'a pas son
  // quota rempli (voir level_up_screen.dart::canContinue), pas seulement
  // celui actif au premier affichage.
  //
  // Bug trouve et corrige pendant cette campagne QA (multiclassage
  // Paladin/Occultiste : le niveau 1 d'Occultiste ajoute un onglet "Sorts"
  // en plus de "Mineurs") : cette boucle ne remplissait QUE l'onglet actif
  // au chargement de l'ecran (toujours "Mineurs" si present) -- `CONTINUER`
  // restait alors indefiniment desactive (son quota "NOUVEAUX SORTS
  // CONNUS" jamais rempli), et le tap etait silencieusement sans effet :
  // [runOneLevelUp] rendait la main en plein milieu du flux (toujours sur
  // cet ecran "Sorts") sans jamais le signaler comme un blocage. Bascule
  // maintenant explicitement sur chaque onglet encore present
  // ("Sorts"/"Grimoire") et le remplit avant de taper `CONTINUER`.
  var spellGuard = 0;
  while (spellGuard < 3 &&
      (find.text('SORTS MINEURS CONNUS').evaluate().isNotEmpty ||
          find.text('NOUVEAUX SORTS CONNUS').evaluate().isNotEmpty ||
          find.textContaining('SORTS DE NIVEAU').evaluate().isNotEmpty)) {
    spellGuard++;
    await fillAvailableCheckableTiles(tester);
    if (await tapTextIfPresent(tester, 'Sorts')) {
      await pumpUntilSettled(tester, attempts: 4);
      await fillAvailableCheckableTiles(tester);
    }
    if (await tapTextIfPresent(tester, 'Grimoire')) {
      await pumpUntilSettled(tester, attempts: 4);
      await fillAvailableCheckableTiles(tester);
    }
    await tapText(tester, 'CONTINUER');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Etape "Invocations" (Occultiste).
  if (find.textContaining('INVOCATIONS CONNUES').evaluate().isNotEmpty) {
    await fillAvailableCheckableTiles(tester);
    await tapText(tester, 'CONTINUER');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Etape "Disciplines elementaires" (Moine, Voie des quatre elements).
  final hadElementalDisciplinesStep = hasElementalDisciplinesStepVisible();
  if (hadElementalDisciplinesStep) {
    await fillAvailableCheckableTiles(tester);
    await tapText(tester, 'CONTINUER');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Etape "Manoeuvres" (Guerrier, Maitre de guerre) -- meme patron que
  // l'etape "Disciplines elementaires" ci-dessus (tuiles CheckableOptionTile
  // a quota, voir level_up_screen.dart::_maneuverTile) -- jamais gere ici
  // avant cette campagne QA (reverification du correctif PR #153/D85) :
  // sans ce bloc, "CONTINUER" restait desactive tant que le quota de 3
  // manoeuvres n'etait pas atteint, et [runOneLevelUp] le retapait a vide
  // dans la boucle de rattrapage ci-dessous sans jamais le signaler comme
  // un blocage -- un faux "non bloque" masquant que l'etape n'avait jamais
  // ete remplie.
  final hadManeuversStep = hasManeuversStepVisible();
  if (hadManeuversStep) {
    await fillAvailableCheckableTiles(tester);
    await tapText(tester, 'CONTINUER');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Etape "Metamagie" (Ensorceleur) -- memes tuiles CheckableOptionTile a
  // quota que "Disciplines elementaires"/"Manoeuvres" ci-dessus (voir
  // level_up_screen.dart::_metamagicTile) -- jamais gere ici avant cette
  // campagne QA (correctif D99/cablage Metamagie, 21/10/2026) : sans ce
  // bloc, "CONTINUER" restait desactive tant que le quota de nouvelles
  // options n'etait pas atteint, et [runOneLevelUp] le retapait a vide dans
  // la boucle de rattrapage ci-dessous sans jamais le signaler comme un
  // blocage -- meme piege que les manoeuvres/disciplines avant leur
  // correctif. La sous-section optionnelle "Remplacer une option" n'a
  // besoin d'aucune interaction : elle n'est jamais obligatoire tant
  // qu'aucune tuile de retrait n'est tapee (voir
  // level_up_screen.dart::_buildMetamagicStep, `canContinue`).
  if (find.text('NOUVELLES OPTIONS DE MÉTAMAGIE').evaluate().isNotEmpty) {
    await fillAvailableCheckableTiles(tester);
    await tapText(tester, 'CONTINUER');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Recapitulatif : "CONTINUER" applique (ecrit en base) et revient a la
  // fiche -- ou enchaine directement sur l'annonce du niveau suivant si un
  // seuil XP supplementaire est deja franchi (improbable ici : la montee
  // manuelle ne credite que le strict seuil du niveau cible).
  await tapText(tester, 'CONTINUER');
  await pumpUntilSettled(tester, attempts: 6);

  // Rattrapage defensif (bug trouve et corrige pendant cette campagne QA,
  // scenario multiclassage Paladin/Occultiste) : un multiclassage vers une
  // classe de lanceur de sorts peut intercaler un ecran supplementaire
  // apres la boucle "Sorts" ci-dessus (observe : un ecran "Magie de pacte
  // debloquee..." de recalcul des emplacements, toujours sous le meme
  // "Etape X sur Y") avant d'atteindre reellement la fiche personnage
  // (identifiee par son onglet "FICHE") -- le seul CONTINUER explicite
  // ci-dessus ne suffisait pas toujours, laissant [runOneLevelUp] rendre la
  // main en plein milieu du flux sans le signaler (le test suivant ne
  // trouvait alors aucun onglet "APT."/"SORTS" a observer). Continue de
  // taper CONTINUER (en retentant fillAvailableCheckableTiles a chaque
  // etape, au cas ou une section a cocher apparaitrait) jusqu'a l'arrivee
  // sur la fiche, sans jamais depasser un authentique ecran de blocage.
  var catchUpGuard = 0;
  while (catchUpGuard < 5 &&
      find.text('FICHE').evaluate().isEmpty &&
      find.text('NIVEAU ATTEINT').evaluate().isEmpty &&
      find.text('CONTINUER').evaluate().isNotEmpty) {
    catchUpGuard++;
    await fillAvailableCheckableTiles(tester);
    await tapText(tester, 'CONTINUER');
    await pumpUntilSettled(tester, attempts: 6);
  }

  if (find.text('NIVEAU ATTEINT').evaluate().isNotEmpty) {
    final blockingText = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    return LevelUpOutcome(
      blocked: true,
      screenText: blockingText,
      hadElementalDisciplinesStep: hadElementalDisciplinesStep,
      hadManeuversStep: hadManeuversStep,
    );
  }

  return LevelUpOutcome(
    blocked: false,
    screenText: const [],
    hadElementalDisciplinesStep: hadElementalDisciplinesStep,
    hadManeuversStep: hadManeuversStep,
  );
}

/// Resultat de [runOneLevelUp].
class LevelUpOutcome {
  const LevelUpOutcome({
    required this.blocked,
    required this.screenText,
    required this.hadElementalDisciplinesStep,
    required this.hadManeuversStep,
  });

  /// `true` si le flux s'est arrete sur l'ecran "NIVEAU ATTEINT" (choix non
  /// resolu -- voir domain/level_up_block_reason.dart).
  final bool blocked;

  /// Tout le texte visible au moment ou [runOneLevelUp] a rendu la main
  /// (ecran de blocage seulement) -- utilise par les tests pour verifier
  /// le libelle exact du blocage.
  final List<String> screenText;

  /// `true` si l'etape "Disciplines elementaires" (Moine, Voie des quatre
  /// elements) a ete rencontree pendant CE niveau -- `false` si le flux a
  /// ete bloque avant de pouvoir l'atteindre. Utilise par les tests de
  /// regression (Moine d'une autre sous-classe) pour confirmer son
  /// absence pendant le flux, pas seulement apres coup (voir
  /// hasElementalDisciplinesStepVisible, qui ne refleterait plus que
  /// l'ecran final une fois le flux termine).
  final bool hadElementalDisciplinesStep;

  /// `true` si l'etape "Manoeuvres" (Guerrier, Maitre de guerre) a ete
  /// rencontree pendant CE niveau -- meme role que
  /// [hadElementalDisciplinesStep], ajoute pendant cette campagne QA
  /// (reverification du correctif PR #153/D85).
  final bool hadManeuversStep;
}

/// `true` si une etape "Disciplines elementaires" est visible sur l'ecran
/// courant -- utilise aussi par les tests de regression (Moine d'une autre
/// sous-classe que Voie des quatre elements) pour confirmer son absence.
bool hasElementalDisciplinesStepVisible() => find
    .text('DISCIPLINES \u00c9L\u00c9MENTAIRES CONNUES')
    .evaluate()
    .isNotEmpty;

/// `true` si une etape "Manoeuvres" (Guerrier, Maitre de guerre) est
/// visible sur l'ecran courant -- meme role que
/// [hasElementalDisciplinesStepVisible], ajoute pendant cette campagne QA
/// (reverification du correctif PR #153/D85) en constatant que cette etape
/// n'etait gere par AUCUNE fonction de ce fichier (voir le commentaire du
/// bloc "Manoeuvres" de [runOneLevelUp]).
bool hasManeuversStepVisible() =>
    find.text('MAN\u0152UVRES CONNUES').evaluate().isNotEmpty;

/// Ouvre un personnage par son nom depuis CharacterListScreen (deja
/// affichee) -- tape la carte portant ce nom (voir
/// presentation/widgets/character_card.dart, qui affiche `character.name`
/// et pousse /characters/{id} au tap).
Future<void> openCharacterByName(WidgetTester tester, String name) async {
  await tapText(tester, name);
  await pumpUntilSettled(tester, attempts: 6);
}
