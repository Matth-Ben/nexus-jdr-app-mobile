import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/features/character_creation/presentation/class_choice_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/widgets/subclass_feature_choice_block.dart';

import 'tap_helpers.dart';

/// Pilote l'assistant de creation de personnage (9 etapes) de bout en bout,
/// depuis CharacterListScreen ("+ CREER" deja visible) jusqu'au retour sur
/// la liste des personnages apres "CREER LE PERSONNAGE".
///
/// Generique par construction (aucun nom de sort/competence/outil en dur) :
/// les etapes 5/9 "Competences et outils" et 6/9 "Sorts" utilisent
/// fillAvailableCheckableTiles pour cocher automatiquement les premieres
/// options disponibles jusqu'a satisfaire leur quota, quelle que soit la
/// classe/l'historique/la race choisis. L'etape 7/9 "Equipement de depart"
/// n'a besoin d'aucune interaction (onglet "Historique" par defaut,
/// toujours valide), ni l'etape 8/9 "Apparence et histoire" (champs
/// optionnels).
///
/// La liste de races est longue (~38 lignes) et seules les premieres sont
/// montees dans l'arbre de widgets sans defilement (sliver paresseux meme
/// pour `ListView(children: [...])`) : [raceName] passe toujours par
/// [scrollUntilVisibleThenTap]. Les autres etapes ont des listes courtes
/// (classe, sous-classe, historique, sous-race) : [tapText] simple suffit.
///
/// Gere aussi, depuis le correctif D108 (`docs/dette-technique.md`), les 4
/// choix de niveau 1 natifs introduits par D99 qui n'existaient pas quand ce
/// helper a ete ecrit -- jamais parametrables ici (resolution automatique
/// systematique avec la premiere option disponible), voir la doc de classe
/// de [_resolveClassChoiceStepScreenIfPresent]/
/// [_resolveSubclassFeatureChoiceIfPresent] :
/// - Guerrier/Rodeur : ecran "Style de combat"/"Ennemi jure" juste apres
///   l'etape Classe.
/// - Roublard : ecran "Expertise" juste apres l'etape Competences et outils.
/// - Ensorceleur + Lignage draconique (ou toute future sous-classe avec un
///   second choix de niveau 1) : second `SelectableOptionTile` sur
///   `SubclassFeatureChoiceBlock`, dans l'ecran Sous-classe existant.
Future<void> createCharacter(
  WidgetTester tester, {
  required String characterName,
  required String raceName,
  String? subraceName,
  required String className,
  String? subclassName,
  bool autoPickSubclassIfOffered = false,
  required String backgroundName,
  Map<String, int> abilityIncrements = const {},
}) async {
  await tapText(tester, '+ CRÉER');
  await pumpUntilSettled(tester, attempts: 6);

  // Etape 1/10 : Edition -- chantier "choix d'edition 2014/2024 par
  // personnage" (`EditionStepScreen`, TOUTE PREMIERE etape de l'assistant,
  // AVANT Race). Jamais parametrable ici (resolution automatique
  // systematique sur l'edition deja preselectionnee -- '2014', meme defaut
  // que `CharacterCreationDraft.edition`) : aucun scenario de cette suite
  // ne depend d'une edition precise, "SUIVANT" est deja actionnable sans
  // interaction prealable.
  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);

  // Etape 2/10 : Race (liste longue, defilement necessaire).
  await scrollUntilVisibleThenTap(
    tester,
    find.byType(ListView).first,
    raceName,
  );
  await pumpUntilSettled(tester, attempts: 4);
  await fillAbilityScoreRacialBonusIfPresentStub();
  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);

  // Etape 1b/9 : Sous-race (si applicable).
  if (subraceName != null) {
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      subraceName,
    );
    await pumpUntilSettled(tester, attempts: 4);
    await tapText(tester, 'SUIVANT');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Etape 2/9 : Classe (13 classes, peut necessiter un defilement).
  await scrollUntilVisibleThenTap(
    tester,
    find.byType(ListView).first,
    className,
  );
  await pumpUntilSettled(tester, attempts: 4);
  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);

  // Guerrier/Rodeur uniquement (D99/D108) : `ClassStepScreen._submit` pousse
  // directement `ClassChoiceStepScreen` ici (Style de combat/Ennemi jure),
  // jamais l'etape Sous-classe -- sans effet pour toute autre classe (voir la
  // doc de classe de [_resolveClassChoiceStepScreenIfPresent]).
  await _resolveClassChoiceStepScreenIfPresent(tester);

  // Etape 2b/9 : Sous-classe (Clerc/Occultiste/Ensorceleur uniquement).
  if (subclassName != null) {
    await scrollUntilVisibleThenTap(
      tester,
      find.byType(ListView).first,
      subclassName,
    );
    await pumpUntilSettled(tester, attempts: 4);
    await _resolveSubclassFeatureChoiceIfPresent(tester);
    await tapText(tester, 'SUIVANT');
    await pumpUntilSettled(tester, attempts: 4);
  } else if (autoPickSubclassIfOffered) {
    for (var drag = 0; drag < 6; drag++) {
      if (find.byType(SelectableOptionTile).evaluate().isNotEmpty) break;
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await settleQuickly(tester);
    }
    if (find.byType(SelectableOptionTile).evaluate().isNotEmpty) {
      final finder = find.byType(SelectableOptionTile).first;
      await tester.ensureVisible(finder);
      await settleQuickly(tester);
      await tester.tap(finder);
      await pumpUntilSettled(tester, attempts: 4);
      await _resolveSubclassFeatureChoiceIfPresent(tester);
      await tapText(tester, 'SUIVANT');
      await pumpUntilSettled(tester, attempts: 4);
    }
  }

  // Etape 3/9 : Historique (~36 historiques, peut necessiter un
  // defilement).
  await scrollUntilVisibleThenTap(
    tester,
    find.byType(ListView).first,
    backgroundName,
  );
  await pumpUntilSettled(tester, attempts: 4);
  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);

  // Etape 4/9 : Caracteristiques (Tableau standard par defaut -- voir
  // domain/ability_score_rules.dart::defaultStandardArrayScores : For 15,
  // Dex 14, Con 13, Int 12, Sag 10, Cha 8, ordre canonique). [abilityIncrements]
  // tape le bouton "+" (echange avec la valeur immediatement superieure du
  // pool, PAS un simple +1 -- voir AbilityScoreRules.swapUp) de chaque
  // caracteristique indiquee, autant de fois que sa valeur -- utilise par
  // les scenarios de multiclassage pour satisfaire les prerequis des deux
  // classes (domain/multiclass_prerequisites.dart) sans jamais coder en dur
  // le resultat final (qui depend de l'ordre des increments).
  for (final entry in abilityIncrements.entries) {
    await incrementAbilityScore(tester, entry.key, entry.value);
  }
  await fillAbilityScoreRacialBonusIfPresent(tester);
  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);

  // Etape 5/9 : Competences et outils.
  await fillAvailableCheckableTiles(tester);
  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);

  // Roublard uniquement (D99/D108) : `SkillsAndToolsStepScreen._submit`
  // pousse `ClassChoiceStepScreen` ici (Expertise) -- sans effet pour toute
  // autre classe.
  await _resolveClassChoiceStepScreenIfPresent(tester);

  // Etape 6/9 : Sorts (seulement classe lanceuse, sautee sinon).
  //
  // Bug trouve et corrige pendant cette campagne QA (Magicien/Clerc,
  // premier scenario de cette campagne a exercer une classe lanceuse "a
  // sorts connus" -- Mineurs + Niveau 1 -- a la CREATION) : l'onglet-pilule
  // de la 2e section s'appelle exactement 'Niveau 1' (voir
  // presentation/spells_step_screen.dart ligne ~565, SpellLevelTabOption),
  // PAS 'NIVEAU 1' (tout capitales) -- `find.text` etant sensible a la
  // casse, l'ancien `tapTextIfPresent(tester, 'NIVEAU 1')` ne trouvait
  // jamais ce bouton et ne basculait donc jamais vers l'onglet "Niveau 1",
  // laissant son quota de sorts connus vide et "SUIVANT" desactive --
  // [createCharacter] tapait alors ce bouton desactive sans effet jusqu'a
  // l'etape 9/9, ou aucun `TextFormField` n'etait jamais atteint (`Bad
  // state: No element`), un symptome tres eloigne de la cause reelle.
  if (find.text('SORTS MINEURS CONNUS').evaluate().isNotEmpty ||
      find.text('SORTS DE NIVEAU 1 CONNUS').evaluate().isNotEmpty) {
    await fillAvailableCheckableTiles(tester);
    if (await tapTextIfPresent(tester, 'Niveau 1')) {
      await pumpUntilSettled(tester, attempts: 4);
      await fillAvailableCheckableTiles(tester);
    }
    await tapText(tester, 'SUIVANT');
    await pumpUntilSettled(tester, attempts: 4);
  }

  // Etape 7/9 : Equipement de depart (onglet Historique par defaut).
  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);

  // Etape 8/9 : Apparence et histoire (champs optionnels).
  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);

  // Etape 9/9 : Recapitulatif.
  await tester.enterText(find.byType(TextFormField).first, characterName);
  await tester.pump();
  await tapText(tester, 'CRÉER LE PERSONNAGE');
  await pumpUntilSettled(tester, attempts: 10);
}

/// Resout `ClassChoiceStepScreen` s'il est l'ecran courant -- correctif
/// D99/D108 (`docs/dette-technique.md`). Deux points d'insertion possibles
/// dans [createCharacter], tous deux sans effet (retour immediat) si cet
/// ecran n'est pas monte :
/// - juste apres l'etape Classe (Guerrier "Style de combat", Rodeur "Ennemi
///   jure") ;
/// - juste apres l'etape Competences et outils (Roublard "Expertise").
///
/// Un seul ecran, deux corps differents (voir la doc de classe de
/// `ClassChoiceStepScreen`) distingues ici par le type de tuile monte :
/// `CheckableOptionTile` (choix multiple a quota -- Expertise, resolu via
/// [fillAvailableCheckableTiles], deja robuste a un quota de 0) ou
/// `SelectableOptionTile` (choix exclusif -- Style de combat/Ennemi jure,
/// premiere option disponible tapee, meme pattern defensif -- quelques
/// defilements si la premiere tuile n'est pas encore montee -- que la
/// section `autoPickSubclassIfOffered` de [createCharacter]).
///
/// Jamais parametrable (resolution automatique systematique, premiere
/// option disponible) : aucun paramètre equivalent a [createCharacter]'s
/// `subclassName`/`autoPickSubclassIfOffered` n'existe pour ce choix nomme,
/// donc pas de mecanisme existant a respecter ici -- voir la demande de
/// correctif D108.
Future<void> _resolveClassChoiceStepScreenIfPresent(WidgetTester tester) async {
  if (find.byType(ClassChoiceStepScreen).evaluate().isEmpty) return;

  if (find.byType(CheckableOptionTile).evaluate().isNotEmpty) {
    // Mode Expertise (Roublard, choix multiple a quota).
    await fillAvailableCheckableTiles(tester);
  } else {
    // Mode Style de combat/Ennemi jure (Guerrier/Rodeur, choix exclusif).
    for (var drag = 0; drag < 6; drag++) {
      if (find.byType(SelectableOptionTile).evaluate().isNotEmpty) break;
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await settleQuickly(tester);
    }
    if (find.byType(SelectableOptionTile).evaluate().isNotEmpty) {
      final finder = find.byType(SelectableOptionTile).first;
      await tester.ensureVisible(finder);
      await settleQuickly(tester);
      await tester.tap(finder);
      await pumpUntilSettled(tester, attempts: 4);
    }
  }

  await tapText(tester, 'SUIVANT');
  await pumpUntilSettled(tester, attempts: 4);
}

/// Resout le second choix de niveau 1 propre a la sous-classe (ex. Ancetre
/// draconique du Lignage draconique, Ensorceleur), porte par
/// `SubclassFeatureChoiceBlock` sur l'ecran Sous-classe existant -- correctif
/// D99/D108. Sans effet (retour immediat) si ce bloc n'est pas monte (toute
/// sous-classe sans second choix de niveau 1, l'immense majorite) ou s'il
/// n'affiche aucune tuile (sous-classe sans options -- cas defensif,
/// `choice_type` renseigne sans ligne `class_options`).
///
/// A appeler juste apres avoir selectionne la sous-classe (tuile tapee,
/// `pumpUntilSettled` deja fait par l'appelant), avant de taper "SUIVANT" --
/// `SubclassFeatureChoiceBlock` n'est monte par `SubclassStepScreen` qu'une
/// fois `selectedSubclassId` non nul.
///
/// Les tuiles de ce bloc sont cherchees PARMI SES SEULS DESCENDANTS
/// (`find.descendant`), jamais parmi tous les `SelectableOptionTile` de
/// l'ecran : le bloc de choix de sous-classe lui-meme (`SubclassChoiceBlock`,
/// juste au-dessus dans le meme `ListView`) utilise aussi ce type de tuile
/// pour les AUTRES sous-classes non choisies -- les confondre taperait une
/// sous-classe differente de celle deja selectionnee plutot que l'option de
/// second choix voulue.
///
/// Jamais parametrable, meme rationale que
/// [_resolveClassChoiceStepScreenIfPresent].
Future<void> _resolveSubclassFeatureChoiceIfPresent(WidgetTester tester) async {
  final blockFinder = find.byType(SubclassFeatureChoiceBlock);
  if (blockFinder.evaluate().isEmpty) return;

  // Meme piege de montage paresseux que [scrollUntilVisibleThenTap] : ce
  // bloc peut etre monte juste en dehors du cache initial du long
  // `ListView` de l'etape Sous-classe.
  for (var drag = 0; drag < 6; drag++) {
    final tileFinder = find.descendant(
      of: blockFinder,
      matching: find.byType(SelectableOptionTile),
    );
    if (tileFinder.evaluate().isNotEmpty) break;
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await settleQuickly(tester);
  }

  final tileFinder = find.descendant(
    of: blockFinder,
    matching: find.byType(SelectableOptionTile),
  );
  if (tileFinder.evaluate().isEmpty) return;

  final finder = tileFinder.first;
  await tester.ensureVisible(finder);
  await settleQuickly(tester);
  await tester.tap(finder);
  await pumpUntilSettled(tester, attempts: 4);
}

/// Point d'extension explicite : rien a faire a l'etape 1/9 elle-meme (le
/// bonus racial au choix ne s'affiche qu'a l'etape 4/9, voir
/// [fillAbilityScoreRacialBonusIfPresent]).
Future<void> fillAbilityScoreRacialBonusIfPresentStub() async {}

/// Repartit le bonus racial au choix de l'etape 4/9 s'il y en a un (Aasimar,
/// Demi-elfe, Forgelier...), sans rien faire sinon.
///
/// Strategie generique (aucune caracteristique en dur) : si le motif
/// "+1 / +1 / +1" est propose (races a bonus flexibles), le selectionne.
/// Puis coche les premiers FilterChip encore actifs jusqu'a ce que la carte
/// affiche son etat "complet".
///
/// Bug trouve et corrige pendant cette campagne QA (Aasimar/Druide, premier
/// scenario sans multiclassage -- donc sans aucun appel a
/// [incrementAbilityScore], le seul autre endroit qui defile cette meme
/// liste) : [RacialBonusChoiceCard] est le DERNIER enfant du
/// `ListView(children: [...])` de l'etape, apres les 6 lignes de
/// caracteristiques -- meme piege de montage paresseux que documente sur
/// [incrementAbilityScore]. Sans defilement prealable, "Bonus racial au
/// choix" n'est jamais monte a l'ecran et cette fonction concluait a tort
/// qu'aucun bonus racial au choix n'etait propose, laissant "SUIVANT"
/// durablement desactive -- l'assistant derivait alors jusqu'a l'etape 9/9
/// sans jamais atteindre son `TextFormField` (`Bad state: No element`), un
/// symptome tres eloigne de la cause reelle.
Future<void> fillAbilityScoreRacialBonusIfPresent(WidgetTester tester) async {
  for (var drag = 0; drag < 10; drag++) {
    if (find.text('Bonus racial au choix').evaluate().isNotEmpty) break;
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await settleQuickly(tester);
  }
  if (find.text('Bonus racial au choix').evaluate().isEmpty) return;

  await tapTextIfPresent(tester, '+1 / +1 / +1');

  // Coche jusqu'a 3 FilterChip actifs non selectionnes (motif le plus
  // courant -- Aasimar/Firbolg/Tabaxi... -- 2 pour Demi-elfe/Forgelier) :
  // la boucle s'arrete d'elle-meme quand plus aucun chip actif ne reste
  // (`_firstUnselectedEnabledChip` renvoie `null`), qui que soit le nombre
  // exact requis par la race -- jamais de valeur en dur ici.
  for (var i = 0; i < 6; i++) {
    final target = _firstUnselectedEnabledChip(tester);
    if (target == null) break;
    final finder = find.byWidget(target);
    await tester.ensureVisible(finder);
    await settleQuickly(tester);
    await tester.tap(finder);
    await settleQuickly(tester);
  }
}

FilterChip? _firstUnselectedEnabledChip(WidgetTester tester) {
  final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
  for (final chip in chips) {
    if (chip.onSelected != null && !chip.selected) return chip;
  }
  return null;
}

/// Coche toutes les options CheckableOptionTile encore actives et non
/// cochees trouvees sur l'ecran courant (TOUTES sections confondues --
/// "Competences de classe"/"Outils (classe)"/"Langues (historique)"/
/// "Competences (race)"/"Outils (race)" de l'etape 5/9, ou "Sorts
/// mineurs"/"Sorts de niveau N"/"Invocations"/"Disciplines elementaires"
/// ailleurs), jusqu'a ce qu'il n'en reste plus ou que [maxCycles]*[maxTaps]
/// soit atteint (garde-fou anti-boucle infinie).
///
/// Alterne deux boucles :
/// - la boucle interne tape toute tuile actionnable DEJA MONTEE dans
///   l'arbre de widgets, en relisant la liste a CHAQUE iteration (cocher
///   une tuile peut desactiver ses voisines du meme quota) ;
/// - la boucle externe force un defilement supplementaire entre deux
///   passes internes : une section plus bas dans une longue liste (ex.
///   "Langues (historique)" de l'etape 5/9, qui en a souvent 10+ candidates)
///   peut n'etre montee par AUCUNE tuile actionnable encore visible tant
///   qu'on n'a jamais defile jusqu'a elle -- la boucle interne seule
///   s'arreterait alors a tort en la croyant deja satisfaite, puisque son
///   `indexWhere` ne porte que sur les tuiles deja montees (meme piege que
///   la liste de races/classes, voir [scrollUntilVisibleThenTap]).
Future<void> fillAvailableCheckableTiles(
  WidgetTester tester, {
  int maxTaps = 20,
  int maxCycles = 6,
}) async {
  for (var cycle = 0; cycle < maxCycles; cycle++) {
    var tappedThisCycle = false;
    for (var i = 0; i < maxTaps; i++) {
      final tiles = tester
          .widgetList<CheckableOptionTile>(find.byType(CheckableOptionTile))
          .toList();
      final index = tiles.indexWhere(
        (tile) => tile.enabled && !tile.checked && tile.onTap != null,
      );
      if (index == -1) break;
      tappedThisCycle = true;
      final finder = find.byType(CheckableOptionTile).at(index);
      await tester.ensureVisible(finder);
      await settleQuickly(tester);
      await tester.tap(finder);
      await settleQuickly(tester);
    }
    final listFinder = find.byType(ListView);
    if (listFinder.evaluate().isEmpty) break;
    final beforeDrag = tester
        .widgetList<CheckableOptionTile>(find.byType(CheckableOptionTile))
        .map((t) => t.title)
        .toSet();
    await tester.drag(listFinder.first, const Offset(0, -400));
    await settleQuickly(tester);
    final afterDrag = tester
        .widgetList<CheckableOptionTile>(find.byType(CheckableOptionTile))
        .map((t) => t.title)
        .toSet();
    // Rien de nouveau monte par ce defilement ET rien tape ce cycle -> fin
    // de liste atteinte, plus rien a faire.
    if (!tappedThisCycle && afterDrag.difference(beforeDrag).isEmpty) {
      break;
    }
  }
}

/// Libelle affiche ("FORCE", "CHARISME"...) pour chaque cle de
/// caracteristique (voir domain/ability_score_definitions.dart::label,
/// mis en majuscules par [AbilityScoreStepScreen._AbilityRow]) -- utilise
/// pour retrouver la ligne correspondante a l'etape 4/9, voir le
/// commentaire de [incrementAbilityScore].
const Map<String, String> _abilityKeyLabel = {
  'str': 'FORCE',
  'dex': 'DEXTÉRITÉ',
  'con': 'CONSTITUTION',
  'int': 'INTELLIGENCE',
  'wis': 'SAGESSE',
  'cha': 'CHARISME',
};

/// Tape [times] fois le bouton "+" de [abilityKey] a l'etape 4/9
/// "Caracteristiques" (methode "Tableau standard" : chaque tap echange la
/// valeur courante avec la valeur immediatement superieure du pool des 6,
/// portee par une AUTRE caracteristique -- voir
/// domain/ability_score_rules.dart::swapUp. Jamais un simple +1).
///
/// Bug trouve et corrige pendant cette campagne QA (multiclassage
/// Paladin/Occultiste, premier scenario a incrementer une caracteristique
/// hors des deux premieres de l'etape) : la liste des 6 lignes est un
/// `ListView(children: [...])`, lazy par sliver meme avec `children: [...]`
/// (meme piege que [scrollUntilVisibleThenTap], voir sa doc) -- sans
/// defilement prealable, seules les premieres lignes sont montees et
/// `find.byIcon(Icons.add).at(index)` (ancienne version, par position
/// GLOBALE parmi tous les Icons.add de l'ecran) levait un `RangeError`
/// ("index should be less than 2: 5" pour 'cha') plutot que l'echec de
/// recherche habituel. Retrouve maintenant la ligne par son libelle visible
/// (ex. "CHARISME") puis le bouton "+" a l'interieur de CETTE ligne
/// precisement (`find.ancestor`/`find.descendant`) -- robuste meme si des
/// lignes au-dessus sortent du cache une fois defilees (comportement par
/// defaut d'un `ListView`), contrairement a un index global.
Future<void> incrementAbilityScore(
  WidgetTester tester,
  String abilityKey,
  int times,
) async {
  final label = _abilityKeyLabel[abilityKey];
  assert(label != null, 'Cle de caracteristique inconnue : $abilityKey');

  for (var drag = 0; drag < 10; drag++) {
    if (find.text(label!).evaluate().isNotEmpty) break;
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await settleQuickly(tester);
  }

  final rowFinder = find
      .ancestor(of: find.text(label!), matching: find.byType(Row))
      .first;
  final addIconFinder = find.descendant(
    of: rowFinder,
    matching: find.byIcon(Icons.add),
  );

  for (var i = 0; i < times; i++) {
    await tester.ensureVisible(addIconFinder);
    await settleQuickly(tester);
    await tester.tap(addIconFinder);
    await settleQuickly(tester);
  }
}
