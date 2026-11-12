# Refonte de la liste (un seul défilement) et V3-5 (pastille « +N » des états) — specs DA

Décisions de Matthias (12/11/2026) :
- **Refonte de la liste** : option 1 : tout défile ensemble (titre, bandeaux, recherche, cartes), **Créer / Importer
  restent fixes en pied**. La recherche/filtre reste **épinglée en haut sauf à police agrandie** (elle défile alors
  avec le reste). Le **bandeau de synchronisation reste épinglé** (visible tant qu'il y a des écritures en attente
  ou un conflit) ; le bandeau « Nouvelle version disponible » défile. **D174** (débordement horizontal de
  l'en-tête à textScale élevé) est traitée dans le même chantier.
- **V3-5** : la pastille « +N » d'une carte membre (vue MJ) ouvre une feuille ; défauts DA retenus : liste de
  **tous** les états du membre, avec la **règle courte** sous chaque nom, **seule** la pastille « +N » est
  cliquable (les pastilles individuelles restent non tappables).

## A. V3-5 — feuille des états d'un membre
- Composant : feuille modale basse en lecture seule, sur le modèle de `ConditionsSheet` (`showModalBottomSheet`,
  `isScrollControlled`, fond `parchment.bg`, `SheetHeaderBar`, hauteur au contenu plafonnée à 0,6 de l'écran,
  corps défilant, `enableDrag` vrai). Petite fonction `showMemberConditionsSheet(context, memberName, conditions)`
  (dans `features/groups/presentation/widgets/` ou à côté de `conditions_sheet.dart`).
- Contenu : titre « États de {name} » / « {name}'s conditions » ; toutes les conditions triées par
  `sortConditionsForDisplay` ; chaque ligne en lecture seule calquée sur `_ConditionRow` sans case : fond
  `parchment.card-alt`, bordure 1 px `accent.brick`, `radius.sm`, `PixelIcon` 16 dp `accent.brick`, libellé
  `font.body` 14 gras `textPrimary`, règle courte (`condition.rule(l10n)`) `font.body` 12 `textSecondary` ; jamais
  `font.display` ; sémantique de ligne « {label}, {rule} » ; aucun pied de feuille.
- Pastille : `ConditionsZone` gagne `VoidCallback? onTapMore` (distinct de `onEdit`) ; `_MoreChip` utilise
  `onTapMore ?? onTap` ; `minWidth: 44` ajouté à la zone de tap de la seule pastille « +N » (hauteur 44 déjà
  fournie par `_ChipShell`) ; `Semantics(button: true)`, libellé existant `conditionsMoreChipSemanticsLabel`
  inchangé, nouveau `hint` « Ouvre la liste des états » / « Opens the list of conditions » ; carte MJ
  (`group_members_tab_body.dart:~317`) : fournir `onTapMore`. Un tap sur la pastille gagne l'arène de gestes
  contre le `InkWell` de la carte, qui reste tappable ailleurs.
- États : aucune condition ou ≤ 2 → pas de « +N » donc pas de feuille ; police > ×1,3 → pas de plafond ni de
  « +N » (tous les noms visibles) ; vue partagée/lecture seule : même feuille ; hors ligne : données déjà en
  mémoire (`GroupMember.conditions`), aucun appel réseau ; instantané figé à l'ouverture (liste vide →
  « Aucun état actif. »). Grande police ×2,0 sur 320 dp : libellé et règle à la ligne, sans ellipse, corps défilant.
- Clés .arb FR/EN (bloc contigu à la fin) : `memberConditionsSheetTitle(name)`, `conditionsMoreChipHint`,
  `memberConditionsSheetEmpty`. Tests : tap sur « +N » ouvre la feuille ; cible ≥ 44×44 ; ×2,0 sur 320 dp ;
  les tests de `ConditionsZone` en lecture seule n'affirment pas que « +N » n'est pas un bouton.

## B. Refonte de la liste des personnages (`character_list_screen.dart`, ≈ 1 190 lignes)
Constat : aujourd'hui `build` empile une `Column` : bloc d'en-tête fixe (titre + boutons groupes/profil,
`SyncStatusBanner`, `UpdateSuggestedBanner`, `_SearchRow`) qui, si textScale > 1,3 ou hauteur < 420, est
plafonné à 50 % dans un `SingleChildScrollView` (cas F21 : défilement imbriqué), puis `Expanded(_CharacterList)`
(`ListView.separated`), puis pied fixe Créer/Importer (ou `CharacterSelectionActionBar`).
Cible (option 1) :
```
[CustomScrollView — UN seul défilement]
  TES AVENTURIERS      (groupes)(profil)   ← défile
  [Bandeau synchro]                         ← ÉPINGLÉ (SliverPersistentHeader) tant qu'il y a quelque chose à dire
  [Bandeau « Nouvelle version »]            ← défile
  [Recherche.........][filtre][sélection]  ← épinglée (pinned) sauf textScale > 1,3 : elle défile alors
  cartes…                                   ← SliverList
[ + Créer ]  [ Importer ]                   ← fixe, hors du défilement (ou barre d'actions en mode sélection)
```
- Structure : un `CustomScrollView` unique dans un `Expanded` ; `SliverToBoxAdapter` (titre, bandeau de mise à
  jour), `SliverPersistentHeader(pinned: true)` pour le bandeau de synchro (hauteur 0 / absent quand rien à
  afficher) et pour la recherche (non épinglée si `textScale > 1,3`), `SliverList` pour les cartes ; états
  chargement / vide / « aucun résultat » dans `SliverFillRemaining(hasScrollBody: false)` ; erreur inchangée
  (`ConnectionErrorState` en plein écran) ; mode sélection : recherche pleine largeur, `CharacterSelectionActionBar`
  fixe en pied ; l'état vide perd son `SingleChildScrollView`/`LayoutBuilder` (F06). Supprimer le plafond F21
  (`_headerCapFontScale`, `_headerCapMinHeight`, `_headerKey`, `ConstrainedBox` + `LayoutBuilder` associés).
- Pied : à textScale > 1,3 les deux boutons passent en colonne pleine largeur ; contenu plafonné à 35 % de la
  hauteur avec défilement interne (seule exception documentée).
- **D174** : `_Header` doit pouvoir passer sur deux lignes si la largeur manque (titre `Expanded` ; boutons
  groupes/profil 44×44 jamais poussés hors écran) à textScale élevé.
- Tablette : contenu à largeur de lecture max ~ 600 dp centré, barre de défilement en bord d'écran, pied de même
  largeur max, boutons côte à côte ; pas de grille multi-colonnes.
- Risques à tester : focus et clavier de la recherche (si non épinglée, la `TextField` peut sortir du cache :
  `keepAlive`/`cacheExtent` généreux ; en épinglé le risque disparaît), saut de défilement au changement de
  filtre, tests existants qui trouvent `ListView`/`_CharacterList`/l'en-tête plafonné (F21, F06) à réécrire,
  scénarios `integration_test/` qui font `scrollUntilVisible` sur la liste, bandeau de synchro épinglé à ×2,0 sur
  320 dp (hauteur maximale à plafonner). Aucune modification d'`.arb` sauf si une nouvelle forme de pied l'exige.
- Pas de pull-to-refresh (hors périmètre).
