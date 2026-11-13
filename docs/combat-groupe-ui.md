# Combat du groupe — spec visuelle finale (direction artistique, 12/11/2026)

Complète `docs/combat-groupe.md` (décisions, modèle, critères). Aucune maquette n'existe dans `09-maquettes-captures.md` :
ce document est la référence de recettage. Niveau **parchemin** (`parchment.bg`) pour l'écran Combat ; en-tête bois
`WoodBackHeader` (titre « COMBAT » en `DisplayText` title). Contrastes calculés sur les hex du design system.

## 0. Ajouts au design system (validés par le chef de projet) et pièges
- Fond « tour en cours » : `goldStart` à 25 % sur `parchment.card` (≈ `#F6E4B6`, par `Color.alphaBlend`, pas un nouvel hex) ;
  `textPrimary` dessus : 13,3:1.
- 1 icône pixel 16×16 « épées croisées » (`combat_swords` via `PixelIcon`, à valider visuellement comme P6) ; le reste en
  icônes Material.
- Bandeau combat = variante **tappable d'`InfoBanner`** (fond `parchment.card`, bordure 2 `goldEnd`, icône `accent.teal`).
  Jamais `AlertBanner` (le combat n'est pas une erreur ; `accent.brick` réservé aux alertes/erreurs).
- `StepperCounter` : boutons visuels 28×28 sous les 44 dp requis → zone de tap 44×44 (visuel 28) à vérifier/corriger.
- Interdit : `textMuted` sur `parchment.card-alt` (4,41:1, sous AA) → utiliser `textSecondary` (6,5:1) sur ces fonds.
- Défauts retenus sur les points ouverts : ▲/▼ actifs seulement vers un voisin de **même initiative** (sinon désactivés,
  indice « Limite de l'égalité ») et le mode « Réordonner » n'apparaît que s'il existe une égalité ; retirés visibles au MJ
  seulement, section repliable « Retirés (N) », sans action ; ×N plafonné à 20 avec **initiative commune** (le MJ édite
  ensuite ligne par ligne) ; numérotation en collision : on continue après le plus grand suffixe existant ; MJ = propriétaire
  du groupe avec ligne `is_game_master` ; modificateur de Dex d'un monstre inconnu → d20 + 0.

## 1. Écran Combat `/groups/:id/combat`
- **En-tête fixe** sous le `WoodBackHeader` : carte `parchment.card`, bordure `border.card`, padding `space.md`, marges
  `space.lg`. Ligne 1 « Round N » `font.body` 22/800 (jamais pixel) ; ligne 2 « Tour de X » 15/700 ; sans tour actif :
  « Aucun tour actif · initiatives 2/4 ». À droite, kebab 44×44 (MJ seulement) : « Réordonner les égalités », « Terminer le
  combat ». Si le tour est hors écran : bouton compact « Voir le tour en cours » (44 de haut, défilement 250 ms). Textes
  plafonnés ×2,0 (`withClampedTextScaling`), hauteur max 40 % du viewport.
- **Liste** : `ListView` avec une clé par id de participant, `space.sm` entre lignes, marges `space.lg`. Pied fixe MJ : un
  seul `PrimaryButton` « Ajouter un monstre » (min 48, `DisplayText` control). Pas de pied pour un joueur.
- **`InitiativeRow`** : carte `parchment.card`, `radius.md`, padding `space.sm`/`space.md`, hauteur min 64. Mode normal
  (échelle < ×1,6) : `Row[rang 28 | Column(nom 15/800 sans ellipse ; Wrap(badge, libellé d'état)) | initiative | kebab 44×44]`.
  Rang 16/800 (« – » sans initiative) ; initiative 20/800 avec « Init. » 11/600 dessous (colonne min 44) ; nom sans limite de
  lignes. Mode empilé (≥ ×1,6) : ligne 1 rang + nom pleine largeur ; ligne 2 initiative, badges, `Spacer`, kebab.
- **Badges** (`radius.sm`, 11/700, icône 16) : **PJ** fond `wood.medium`, texte `text.on-wood` (7,0:1), `shield_outlined` ;
  **PNJ** fond `parchment.card-alt`, bordure 1,5 `wood.light`, texte `textSecondary`, `dangerous_outlined` ; pastille « Toi »
  en contour sur la ligne du joueur.
- **États d'une ligne** : normal (`border.card`, fond `parchment.card`) ; **tour en cours** (`border.card-emphasis` 3
  `wood.medium` + halo 1 `wood.dark`, fond `turn-fill`, libellé « Tour en cours » 12/800, `chevron_right` 24, fondu 200 ms) ;
  **en attente** (bordure pointillée 2 `wood.light`, fond `card-alt`, libellé « En attente » + `pause`) ; **retiré** (MJ
  seulement, fond `card-alt`, nom barré, « Retiré », pas de kebab) ; **sans initiative** (« – », « Initiative à saisir » 12/700
  + `CompactActionButton` « Renseigner » min 44×44, visible pour le joueur propriétaire et le MJ).
- **Menu de ligne** : MJ : « Éditer l'initiative », « Retirer du combat » (`DestructiveMenuTile`, texte brick) ; joueur sur sa
  seule ligne : « Modifier mon initiative », pas de kebab sur les autres lignes ; le tap sur la ligne ne fait rien ; retirer
  demande une confirmation (`showGroupConfirmationDialog`, « Retirer {name} du combat ? »).
- **Mode « Réordonner »** (MJ) : 2e ligne sous le contenu de la ligne, alignée à droite : `drag_handle` (44×44, glisser
  optionnel) + ▲ + ▼ (`keyboard_arrow_up/down`, 44×44) ; bouton « Terminé » dans l'en-tête ; déplacement animé 200 ms ;
  actions sémantiques « Monter » / « Descendre ».

## 2. Bandeaux (`CombatBanner`, un composant, deux variantes)
- **Groupe** : sous le `SegmentedTabBar`, hors zone défilante, visible sur les 3 onglets, marges `lg`/`sm`. Ligne 1 « Combat en
  cours · round N » 13/800 + icône épées 16 `accent.teal` ; ligne 2 « Tour de X · Ouvrir le combat » 12/700 souligné + chevron ;
  pas de pulsation ; apparition `AnimatedSize` 200 ms (immédiate en reduce motion).
- **Fiche joueur** : une ligne, min 48, même cadre, chevron, sans ligne 2 ; dans le bloc sticky **sous** `SyncStatusBanner`
  (10 sous l'en-tête bois, 10 entre bandeaux, 10 sous le dernier). Priorité : (1) alerte de synchro, (2) hors ligne, (3)
  syncing/pending/synced, puis le bandeau combat (ne disparaît jamais). Variante compacte (D211) quand `SyncBannerKind` est
  `alert` ou `offline`. Bloc combiné plafonné à 40 % de la hauteur, défilement interne comme `_SyncBand`. Pas de bandeau sur
  la liste d'accueil.
- **Hors ligne** : pas de second « Hors ligne » ; le bandeau combat ajoute « · état de HH:MM » (sur Groupe, qui n'a pas de
  `SyncStatusBanner` : ligne 2 « Hors ligne · état de HH:MM »). **MJ absent** : ligne 2 « En attente du MJ ». Plafonné ×2,0.

## 3. Feuilles (`showModalBottomSheet`, fond `parchment.bg`, `SheetHeaderBar`, padding de clavier, défilantes)
- **Initiative** : titre « Initiative de {name} ». Champ numérique signé (-20..60, 44 min, `radius.sm`) encadré de compteur −/+
  (44×44 de tap) ; vide, « + » donne 10 ; erreur (fond `#FDECE0`, bordure brick, icône + « Entre -20 et 60 ») ; champ vide :
  « Enregistrer » désactivé sans erreur. Aide (12, `textSecondary`) « Dextérité : +3 → d20 + 3 » (PJ) ; rien pour un monstre.
  `SecondaryButton` « Lancer un d20 » → `showDiceRollSheet(label: Initiative, modifier: dex, useResultLabel: 'Utiliser {total}')` :
  **`showDiceRollSheet` devient `Future<int?>`** (PR3) ; un `PrimaryButton` « Utiliser le résultat ({total} = d20 ± mod ) » ferme et
  renvoie le total, « Relancer » reste possible ; sans `useResultLabel`, comportement actuel inchangé. Le total remplit le champ,
  qui reste modifiable ; annonce « Résultat repris : {total} ». Boutons : « Enregistrer » (primaire), « Annuler ».
- **Monstre** : champ « Nom » (1..80) ; bloc initiative comme ci-dessus (+0), initiative facultative (sans valeur : ligne « sans
  initiative ») ; « Quantité ×N » (compteur 1..20) ; aperçu `liveRegion` poli « Sera ajouté : Gobelin 1, Gobelin 2, Gobelin 3 »
  (au-delà de 4 : « Gobelin 1 … Gobelin 8 (8 monstres) » ; N=1 : aucun suffixe) ; « Ajouter » (primaire, ferme, désactivé si nom vide)
  et « Ajouter et continuer » (garde la feuille, remet la quantité à 1, focus sur Nom, annonce « {count} ajoutés »).
- **Terminer le combat** : `showGroupConfirmationDialog`, confirmation en `DestructiveButton`, focus initial sur Annuler.

## 4. États et entrées
- **Lancer un combat** (onglet Membres, MJ uniquement, `canStartCombat`) : `PrimaryButton` + icône pixel, pleine largeur, sous
  `_LiveUpdateIndicator` ; absent pendant un combat actif ; chargement : spinner dans le bouton ; hors ligne : désactivé +
  « Indisponible hors ligne » ; conflit : refetch + snackbar « Un combat est déjà en cours. ».
- **Groupe sans MJ dans l'app** : propriétaire = `InfoBanner` « Pas de combat sans MJ dans l'app. » avec lien vers les
  paramètres ; joueur = rien. Aucun bouton grisé.
- **Vide MJ** : icône pixel 32 + « Le combat est lancé » + « Ajoute des monstres et attends les initiatives. » ; **vide joueur** :
  « Le MJ prépare le combat. » ; **attente d'initiatives** : en-tête « Aucun tour actif · initiatives 2/4 ».
- **Chargement** : `CircularProgressIndicator` `wood.medium` centré (Semantics « Chargement du combat ») ; **erreur** :
  `ErrorRetryState` « Impossible de charger le combat. » + « Réessayer » ; **hors ligne** : `InfoBanner` `cloud_off_outlined`
  « Hors ligne · dernier état connu à {time}. Lecture seule. », pied, « Renseigner » et kebab désactivés avec hint ; retour
  réseau : refetch complet ; **MJ absent** : `InfoBanner` `hourglass_empty` « En attente du MJ. Seul le MJ peut terminer le combat. » ;
  **combat terminé** : carte résumé « Combat terminé · {rounds} rounds · {count} participants » + « Retour au groupe » (hors
  écran : le bandeau disparaît + une annonce polie unique).
- Joueur retiré (jamais réintégré en V1) : message clair ; erreur `no_game_master` expliquée ; le propriétaire ne peut pas quitter
  le groupe pendant un combat actif (à traiter en PR2).

## 5. Animations et accessibilité
- 200 ms au plus (fondu du tour, déplacement de ligne, `AnimatedSize`) ; si `disableAnimationsOf || accessibleNavigationOf` :
  changement immédiat (retour direct du widget, pas `Duration.zero` qui plante `AnimatedSize`). **Aucun défilement automatique**
  à la réception d'un événement temps réel : offset conservé (clés par id, un seul `ScrollController`) ; seul le tap sur
  « Voir le tour en cours » fait défiler ; un seul défilement initial vers le tour actif à l'ouverture.
- Chaque ligne en `MergeSemantics` : « {rang}. {name}, PJ|PNJ, initiative {n}, tour en cours » + `CustomSemanticsAction` (Éditer,
  Retirer, Monter, Descendre) ; en-tête `Semantics(header: true)` ; annonces polies **uniquement sur changement reçu**
  (jamais au chargement), changements de round/tour fusionnés (1 par seconde) : « Round {round}. Tour de {name}. », à soi :
  « C'est ton tour. ». Jamais la couleur seule. Cibles ≥ 44×44. Police ≥ 11 (12 pour le texte courant).

## 6. Recettage mesurable (320 dp de large)
- Aucun débordement horizontal, aucune ellipse sur un nom, zéro `RenderFlex overflow`, tout interactif ≥ 44×44.
- Ligne : ×1,0 = 64 à 84 dp ; ×2,0 = mode empilé 100 à 150 dp ; ×3,0 = empilé ≤ 280 dp, nom sur plusieurs lignes.
- En-tête : ×1,0 = 72 à 96 ; ×2,0 = ×3,0 (plafonné) ≤ 40 % du viewport. Bandeau Groupe : ×1,0 = 64 à 76 ; ×2,0/×3,0 ≤ 150.
  Bandeau fiche : ×1,0 = 48 à 56 ; ×2,0/×3,0 ≤ 112 ; bloc sticky combiné ≤ 40 % de la hauteur. Pied ≥ 48 de haut, libellé à la ligne.
- Zéro saut de défilement à la réception d'un événement (offset identique avant/après, tests widget) ; contrastes de la section 0 testés.

## 7. Clés `.arb` (préfixe `combat`, FR/EN, bloc contigu à la fin)
`combatBannerTitle(round)`, `combatBannerTurn(name)`, `combatBannerAwaitingMaster`, `combatBannerOffline(time)`, `combatScreenTitle`,
`combatRound(round)`, `combatTurnOf(name)`, `combatNoActiveTurn`, `combatInitiativeProgress(done,total)`, `combatCurrentTurnLabel`,
`combatInitiativeToEnter`, `combatFillInitiative`, `combatBadgePc`/`combatBadgeNpc`, `combatYouTag`, `combatStatusWaiting`/`combatStatusRemoved`,
`combatRemovedSection(count)`, `combatMenuEditInitiative`, `combatMenuEditMine`, `combatMenuRemove`, `combatRemoveConfirmTitle(name)`,
`combatReorderMode`/`combatReorderDone`, `combatMoveUp(name)`/`combatMoveDown(name)`, `combatReorderLimit`, `combatJumpToTurn`,
`combatAddMonster`, `combatEnd`, `combatEndConfirmTitle`/`combatEndConfirmBody(round)`, `combatStart`, `combatStartUnavailableOffline`,
`combatStartAlreadyActive`, `combatNoMasterExplain`, `combatInitiativeSheetTitle(name)`, `combatInitiativeRangeError`, `combatDexHelp(mod)`,
`combatRollD20`, `combatUseRoll(total)`, `combatRollUsedAnnounce(total)`, `combatMonsterName`/`combatMonsterQuantity`,
`combatMonsterPreview(names)`/`combatMonsterPreviewMany(first,last,count)`, `combatAdd`/`combatAddAndContinue`, `combatAddedAnnounce(count)`,
`combatEmptyMasterTitle`/`combatEmptyMasterBody`, `combatEmptyPlayer`, `combatLoading`/`combatLoadError`, `combatOfflineBanner(time)`,
`combatAwaitingMasterBody`, `combatEndedSummary(rounds,count)`, `combatBackToGroup`, `combatAnnounceTurn(round,name)`,
`combatAnnounceYourTurn`, `combatAnnounceEnded`. Textes FR : « Combat en cours · round {round} », « Tour de {name} · Ouvrir le combat »,
« En attente du MJ », « Hors ligne · état de {time} », « COMBAT », « Round {round} », « Tour de {name} », « Aucun tour actif »,
« initiatives {done}/{total} », « Tour en cours », « Initiative à saisir », « Renseigner », « PJ »/« PNJ », « Toi », « En attente »/« Retiré »,
« Retirés ({count}) », « Éditer l'initiative », « Modifier mon initiative », « Retirer du combat », « Retirer {name} du combat ? »,
« Réordonner les égalités »/« Terminé », « Monter {name} »/« Descendre {name} », « Limite de l'égalité », « Voir le tour en cours »,
« Ajouter un monstre », « Terminer le combat », « Le combat disparaît pour tous les joueurs. Round atteint : {round}. »,
« Lancer un combat », « Indisponible hors ligne », « Un combat est déjà en cours. », « Pas de combat sans MJ dans l'app. »,
« Initiative de {name} », « Entre -20 et 60 », « Dextérité : {mod} → d20 {mod} », « Lancer un d20 », « Utiliser {total} »,
« Résultat repris : {total} », « Nom »/« Quantité ×N », « Sera ajouté : {names} », « {first} … {last} ({count} monstres) »,
« Ajouter »/« Ajouter et continuer », « {count} ajoutés », « Le combat est lancé », « Ajoute des monstres et attends les initiatives. »,
« Le MJ prépare le combat. », « Chargement du combat », « Impossible de charger le combat. », « Hors ligne · dernier état connu à
{time}. Lecture seule. », « En attente du MJ. Seul le MJ peut terminer le combat. », « Combat terminé · {rounds} rounds · {count}
participants », « Retour au groupe », « Round {round}. Tour de {name}. », « C'est ton tour. », « Le combat est terminé. ». Traductions EN
par dev-flutter (relues par direction-artistique).
