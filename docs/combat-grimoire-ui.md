# Combat mené depuis Grimoire : partie Nexus de l'étape 7, spec visuelle (direction artistique, 23/11/2026)

Complète `docs/combat-groupe-ui.md`, qui reste la référence pour tout ce qui n'est pas redit ici. Applique le contrat
DeepCore `docs/api-v1/contrat-temps-reel-combat.md` (§4.1 à §4.4, §5) et les décisions 43, 47, 49, 58, 59 et 60.
`09-maquettes-captures.md` ne contient aucune maquette de cet écran : ce document sert de référence de recettage.
Niveau **parchemin** (même écran que le combat natif).

## 0. Principes, ajouts au design system, contrastes
- **Un seul écran et une seule route** (`/groups/:id/combat`), avec les mêmes bandeaux, en-tête et lignes. La source
  (native ou Grimoire) change le **modèle de vue**, pas le gabarit. Les widgets partagés reçoivent des paramètres
  (mode, libellés, callbacks nuls), jamais un test « est-ce Grimoire ».
- **Aucune couleur nouvelle.** Tokens réutilisés : `kCombatTurnFill` (`goldStart` à 25 % sur `parchment.card`),
  `deadCardBackground` (#E8E3D8), `alertBannerBackground` et `accentBrick` (badge Mort), `InfoBanner`,
  `border.card-emphasis`, `PixelIcon` épées (16 ou 32 dp seulement).
- **Ajouts de composants, à valider par le chef de projet** :
  - (a) `CombatCallout`, signal global, deux variantes (§6) ;
  - (b) `CombatInitiativeCard` (§3) ;
  - (c) `CombatDeadBadge` (§4) ;
  - (d) modes `preparing` et `yourTurn` de `CombatHeader` ;
  - (e) variantes `preparing`, `yourTurn` et `gmOffline` de `CombatBannerView` (Groupe et fiche) ;
  - (f) états « Aucun combat en cours » et « Pas de nouvelles du MJ ».
- **Réutilisable par le combat natif V2** (décision 59) : (a), (d) `yourTurn`, (e) `yourTurn` et le routage d'ouverture
  depuis une notification (§8). **Propre à Grimoire** : la ligne de source, les accusés d'envoi et de réception de
  l'initiative, « MJ hors ligne » et l'expiration.
- **Contrastes calculés** :
  - `textPrimary` sur turn-fill : 13,3:1 ; `textSecondary` sur turn-fill : 6,9:1.
  - `accentTeal` sur turn-fill : 4,3:1. Réservé aux **icônes** (seuil 3:1) : jamais de texte teal sur ce fond.
  - `accentBrick` sur `alertBannerBackground` : 5,7:1.
  - `textSecondary` sur `deadCardBackground` : 6,8:1 ; `textPrimary` sur `deadCardBackground` : 13,0:1.
  - `accentTeal` sur `parchment.card` : 4,9:1.
  - `textMuted` interdit sur `deadCardBackground` (4,57:1) et sur `card-alt`.
- **Jamais `AlertBanner` ni `accent.brick`** pour un état du combat (préparation, MJ hors ligne, expiration) : ce ne
  sont pas des erreurs. La brique sert seulement au badge Mort et aux erreurs d'envoi.
- **Mouvement** (`combat_motion.dart`) : 200 ms au plus. Si `combatReduceMotion` est vrai, le widget est rendu
  directement (jamais `Duration.zero` sur `AnimatedSize`). **Aucune animation en boucle** : ni pulsation, ni spinner
  pendant la préparation (c'est une attente de jeu, pas un chargement).

## 1. Source du combat : un indice sobre
- **Nécessaire, mais minimal.** Le joueur ne doit pas changer d'habitudes : écran, bandeaux et lignes sont identiques
  au combat natif. L'indice explique seulement ce qui diffère : initiative « envoyée au MJ » plutôt
  qu'« enregistrée », « MJ hors ligne » plutôt que « MJ absent », aucun contrôle pour le propriétaire.
- **Emplacement** : dernière ligne de `CombatHeader`, `space.xs` au-dessus. Icône `desktop_windows_outlined` 16
  `textSecondary`, puis « Mené depuis Grimoire » en 12/600 `textSecondary`. Elle est lue avec l'en-tête.
- **Absente** du combat natif, des bandeaux, du callout et des notifications.
- **Meneur** (`is_leader` vrai) qui ouvre Nexus : `InfoBanner` (icône `desktop_windows_outlined`) « Tu mènes ce
  combat depuis Grimoire. Ici, tu le suis comme les joueurs. ». Aucun contrôle de MJ : ni kebab d'en-tête, ni pied
  « Ajouter un monstre », ni menu de ligne, ni réordonnancement.
- **En source Grimoire, pour tout le monde** : l'ordre est en lecture seule. La seule action possible est d'envoyer
  sa propre initiative (§3).

## 2. Préparation : annonce sans contenu
- **Quand** : après `combat_start`, ou sur un `state` `active` avec `participants: []`. Préparation et premier tour
  caché sont **volontairement identiques** à l'écran.
- **En-tête, mode `preparing`** :
  - ligne 1 : « Combat ! » en 22/800, `Semantics(header)` ;
  - ligne 2 : « En préparation » en 15/700 ;
  - ligne 3 : « L'ordre d'initiative apparaîtra au premier tour. » en 13/400 `textSecondary` ;
  - puis la ligne de source.
  - **Rien d'autre** : pas de round, pas de « initiatives N/M », aucune initiative des autres joueurs (contrat §4.2,
    et décision 49 : un retard d'initiative trahirait qui a l'app ouverte).
- **Corps** (défilant, texte agrandissable sans plafond) :
  - `CombatInitiativeCard` si le joueur est concerné (§3) ;
  - puis un bloc d'attente centré : `PixelIcon` épées 32 `textSecondary` et « Le MJ prépare le combat. »
    (clé existante `combatEmptyPlayer`), 14/700.
- **Bandeau Groupe** :
  - ligne 1 : « Combat en préparation » ;
  - ligne 2, selon le cas : « Envoie ton initiative · Ouvrir le combat » (demandée, pas encore envoyée),
    « Initiative envoyée · Ouvrir le combat » (envoyée), sinon « Ouvrir le combat ».
- **Bandeau fiche** : « Combat ! Envoie ton initiative » (demandée, pas encore envoyée), sinon « Combat en
  préparation ».
- **Dévoilement** (premier `order`, ou `combat_start` avec une liste) :
  - `AnimatedSwitcher` : fondu de 200 ms sur l'en-tête et le corps ;
  - un seul positionnement initial sur le tour en cours (la liste n'existait pas : aucune position de défilement à
    préserver) ;
  - annonce « L'ordre d'initiative est dévoilé. ». Si un `turn` suit dans la seconde, la fusion existante garde
    l'annonce du tour.

## 3. Initiative du joueur
**Concerné** : le personnage courant du joueur (détail du groupe) figure dans `initiative_requested_for`, ou dans un
`initiative_request`. Avec `character_ids: null`, le joueur est concerné si sa ligne n'a pas d'initiative connue.

**`CombatInitiativeCard`** :
- Habillage : `parchment.card`, bordure 2 `goldEnd` (appel à l'action, même cadre que les bandeaux), `radius.md`,
  padding `md`. Valeurs en `font.body` 800, jamais en police pixel.
- Position :
  - pendant la préparation : premier élément du corps défilant ;
  - une fois l'ordre dévoilé : zone fixe entre l'en-tête et la liste (place de l'actuel « Renseigner mon
    initiative »), textes plafonnés ×2,0, hauteur max 30 % du viewport avec défilement interne.
- Apparition et retrait : `AnimatedSize` 200 ms.

| État | Contenu | Action |
|---|---|---|
| Demandée | « Le MJ demande ton initiative » 15/800 ; « Pour {name} » 13 `textSecondary` | `PrimaryButton` « Envoyer mon initiative », pleine largeur, ouvre la feuille |
| Envoi en cours | idem | `PrimaryButton` avec `isLoading` |
| Envoyée | `send_outlined` 20 teal + « {value} · envoyée au MJ » 15/800 ; « En attente de confirmation du MJ… » 13 `textSecondary` | aucune |
| Reçue | `check_circle_outline` 20 teal + « {value} · reçue par le MJ » (« Le MJ a ton initiative » si la valeur est inconnue) ; en préparation : « Le MJ peut l'ajuster : la valeur retenue s'affichera au premier tour. » | aucune ; la carte disparaît au dévoilement, la ligne du joueur prend le relais |
| Non reçue | état Demandée + « Le MJ n'a pas reçu ton initiative. Renvoie-la. » | bouton |
| Redemandée | état Demandée + « Le MJ te redemande ton initiative. » | bouton |
| Indisponible | bouton désactivé + texte **visible** (pas seulement une info-bulle), 12 `textSecondary` : « Indisponible hors ligne » (clé existante) ou « Indisponible tant que le MJ est hors ligne. » | aucune |
| Échec | sous le bouton : `error_outline` 16 brique + texte 12/700 `textPrimary`. `rate_limited` : « Trop d'envois. Réessaie dans {seconds} s. » ; `no_character` : clé existante ; `group_not_found` : « Tu ne fais plus partie de ce groupe. » ; autre : « Envoi impossible. Réessaie. » | bouton réactivé |

- **Feuille** : `showInitiativeSheet` réutilisée telle quelle (champ, compteur, aide Dextérité, « Lancer un d20 »),
  avec deux paramètres nouveaux :
  - libellé du bouton primaire : « Envoyer au MJ » ;
  - aide 12 `textSecondary` au-dessus des boutons : « Une fois reçue, seul le MJ peut la modifier. ».
- **Passage d'« Envoyée » à « Reçue »**, dès que l'un des deux arrive :
  - un `state` où le personnage n'est plus dans `initiative_requested_for` ;
  - un ordre où la ligne du joueur porte une initiative.
- **Limite côté Grimoire** : pendant la préparation, Grimoire ne publie rien quand il reçoit une initiative
  (`shared/combat-live.ts:226`). La confirmation attend donc le `state` périodique, 25 à 35 s (voir Q3).
- **« Non reçue »** : un `state` reçu plus de 5 s après l'envoi réussi qui liste encore le personnage.
- **Pas de « Modifier » après l'envoi** : Grimoire ignore une initiative déjà fixée
  (`server/nexus/combat-live.ts:1100`). Un renvoi n'aurait aucun effet visible. La correction appartient au MJ (Q4).
- **Valeur retenue par le MJ** :
  - Une fois l'ordre dévoilé, la ligne du joueur affiche la valeur de Grimoire, seule source de vérité.
  - Si elle diffère de la valeur envoyée (gardée en mémoire) : libellé de statut dans la ligne « Corrigée par le MJ
    (envoyé : {sent}) », 12/700 `textSecondary`, icône `edit_note` 16, et annonce « Le MJ a retenu {value}. ».
  - Valeur envoyée inconnue (l'app a été relancée) : rien.
- **Ligne sans initiative** (celle du joueur, quand elle est demandée) : libellé « Initiative à saisir » et
  `CompactActionButton` « Renseigner », qui lance le même flux. Une fois envoyée : libellé « Envoyée au MJ », sans
  bouton.

## 4. Ordre en lecture seule
- **`InitiativeRow`** réutilisée sans menu ni réordonnancement (callbacks nuls).
  - L'ordre est le tableau `participants` tel quel, **jamais retrié**.
  - Rang : index + 1 si l'initiative est connue, sinon « – ».
- **PJ / PNJ** : badges existants. Aucun PV, aucune CA, aucun état « vaincu » (décision 43). Aucune zone réservée à
  ces données.
- **« Toi »** : `user_id` égal à celui du joueur. Si `user_id` vaut `null`, repli sur `character_id` égal au
  personnage courant du joueur.
- **En-tête** :
  - ligne 1 : « Round N » ;
  - ligne 2 : « Tour de X ». Sans tour (`current_participant_id` nul) : « Aucun tour actif · initiatives N/M »,
    où N = participants publics avec une initiative et M = participants publics ;
  - puis la ligne de source.
- **`waiting`** : état existant « En attente ».
- **Surbrillance** : état « tour en cours » existant, appliqué sur `order`, `turn` ou `state`. Tours cachés : rien ne
  bouge, aucun indice à ajouter.
- **`participant_removed`** :
  - la ligne disparaît (`AnimatedSize` 200 ms), sans section « Retirés » ;
  - si c'est le joueur : `InfoBanner` (icône `block_outlined`) « Le MJ t'a retiré de ce combat. ». Clé **nouvelle** :
    la clé native ajoute « tu ne peux pas le rejoindre », ce qui est faux ici ;
  - si le joueur réapparaît dans un ordre suivant, le bandeau disparaît.
- **Héros mort** (décision 58) :
  - `CombatDeadBadge` dans le `Wrap` des badges : fond `alertBannerBackground`, bordure 1,5 `accentBrick`,
    `radius.sm`, icône `heart_broken_outlined` 16, texte « Mort » en `font.body` 11/800 `accentBrick`. Même police que
    PJ/PNJ pour garder la ligne homogène ; le badge MORT en police pixel de l'onglet Membres ne change pas.
  - Libellé de statut « Tour sauté » 12/700 `textSecondary`, icône `redo` 16.
  - Fond de ligne : `deadCardBackground`. Le nom n'est pas barré (barré veut dire « retiré »).
  - Donnée : `characters.is_dead`, déjà lu en temps réel par le détail du groupe, rapproché par `character_id`. Le
    contrat n'a pas de champ « mort » (Q7).
  - Si la surbrillance tombe malgré tout sur ce héros (correction du MJ), le style « tour en cours » l'emporte et le
    badge reste.
- **Lecteur d'écran** : l'étiquette fusionnée de la ligne ajoute « mort, tour sauté » et, le cas échéant, « corrigée
  par le MJ ».

## 5. « À toi de jouer »
- **Déclencheur unique** : un message `turn` dont `current_participant_id` désigne le participant `pc` du joueur
  (`user_id`, repli `character_id`).
- **Jamais** sur `order`, `state` ou `combat_start`, même si la surbrillance désigne le joueur (contrat §4.2).
- **Fin du mode**, au premier de ces cas :
  - un `turn`, `order` ou `state` dont le tour n'est plus celui du joueur ;
  - un `participant_removed` qui le concerne ;
  - `combat_end` ;
  - l'expiration à 10 min.

| Situation | Comportement |
|---|---|
| Écran Combat du groupe ouvert | En-tête mode `yourTurn` : fond turn-fill, bordure 3 `woodMedium` + halo 1 `woodDark` (comme la ligne en cours). Ligne 2 « À toi de jouer » 15/800, précédée du `PixelIcon` épées 16 `accentTeal`. `AnimatedContainer` 200 ms + un seul « coup » d'échelle 1,00 → 1,02 → 1,00 (200 ms, `easeOut`). **Même hauteur qu'en mode normal** : la liste ne bouge pas. Ligne du joueur : état « tour en cours » existant. Aucun défilement automatique (bouton « Voir le tour en cours » existant si la ligne est hors écran). `HapticFeedback.mediumImpact` une fois. Annonce « C'est ton tour. », assertive. |
| App au premier plan, autre écran (Groupe, fiche, accueil, autre groupe) | `CombatCallout` variante tour (§6), avec haptique et annonce. Bandeaux Groupe et fiche de ce groupe en variante `yourTurn` : cadre emphasis et fond turn-fill ; ligne 1 « À toi de jouer · round {round} » ; ligne 2 (Groupe seulement) « Ouvrir le combat ». Sans pulsation. |
| Feuille modale ouverte | Haptique et annonce tout de suite ; le callout apparaît à la fermeture de la feuille. |
| App en arrière-plan ou fermée | Nexus ne doit plus compter comme « présent » (Q2), pour que Grimoire envoie la notification push. Au retour : réabonnement, `state_request`, puis état complet **sans** « À toi de jouer » (surbrillance seulement). |
| App ouverte depuis la notification `your_turn` | Écran Combat (§8), surbrillance seulement, aucune annonce au chargement. |
| Push `combat_start` ou `your_turn` reçue app ouverte (concurrence entre présence et envoi) | Jamais la SnackBar générique de `_showForegroundMessage` (`push_token_registrar.dart:155`). Afficher le callout correspondant s'il n'est pas déjà visible (dédoublonnage par groupe et par type, 60 s). |

## 6. `CombatCallout` : signal global dans l'app
- **Position et règles d'affichage** :
  - un seul callout à la fois ;
  - en **bas** de l'écran (zone des SnackBar), flottant, marges `lg`, au-dessus de la barre d'onglets et du clavier ;
  - jamais en haut, pour ne masquer ni l'en-tête ni le bouton retour ;
  - absent de l'écran Combat du groupe concerné.
- **Interaction** : toute la carte est tappable (hauteur min 56) et ouvre l'écran Combat. Bouton `close` 44×44
  `textSecondary`, libellé « Fermer ».
- **Variante annonce** (« Combat ! » ; ou « Initiative demandée » quand le MJ redemande l'initiative) :
  - fond `parchment.card`, bordure 2 `goldEnd`, `radius.md`, épées 16 teal ;
  - ligne 1 en 15/800 `textPrimary` ;
  - ligne 2 en 13/700 `textSecondary` : « {group} · Envoie ton initiative » ou « {group} · Ouvrir le combat » ;
  - chevron 20 ;
  - disparaît seule après 10 s, **sauf** si `accessibleNavigation` est actif.
- **Variante tour** :
  - fond turn-fill, bordure emphasis ;
  - ligne 1 « À toi de jouer » ; ligne 2 « {group} · round {round} · Ouvrir le combat » ;
  - ne disparaît **jamais seule** : tap, « Fermer », fin du tour ou ouverture de l'écran Combat.
- **Sur un écran scène** (accueil) : c'est une carte parchemin à bordure marquée, la règle des cartes sur fond
  scène s'applique.
- **Mouvement** : entrée en fondu + glissement de 8 dp (200 ms), sortie en fondu (150 ms). Reduce motion : immédiat.
- **Taille** : textes plafonnés ×2,0 ; hauteur ≤ 25 % du viewport, sinon défilement interne. Le nom du groupe est du
  texte brut qui passe à la ligne, jamais coupé par une ellipse.
- **Sémantique** : `liveRegion`, rôle bouton « Ouvrir le combat », action « Fermer ».

## 7. MJ hors ligne et expiration (contrat §4.4)
- **Minuterie** : comptée depuis la **réception** du dernier message de Grimoire pour le combat affiché. Compte :
  tout message `v` = 1 avec `combat_id` et `seq`. Ne comptent pas : `channel_rotated` et la présence.
- **Heure affichée** : le `sent_at` de ce message, en heure locale HH:mm via `combatClockLabel` (« 21:04 », comme le
  reste du combat, et non « 21 h 04 »).
- **Priorité des états** :
  1. Téléphone hors ligne, ou canal pas `SUBSCRIBED` : bandeau hors ligne existant « Hors ligne · dernier état connu
     à {time}. Lecture seule. ». **Jamais** « MJ hors ligne » dans ce cas : Nexus ne sait pas qui est coupé.
  2. MJ hors ligne.
  3. Affichage normal.
  - Après un réabonnement, attendre 5 s (réponse au `state_request`) avant d'afficher « MJ hors ligne ».
- **Après 90 s sans message** :
  - écran Combat : `InfoBanner` neutre (icône `hourglass_empty`) au-dessus de l'en-tête : « Le MJ semble hors ligne.
    Dernier état reçu à {time} ; le combat reprendra dès son retour. » ;
  - tout le reste est conservé : dernière vue, surbrillance, mode `yourTurn` ;
  - l'envoi d'initiative est désactivé (§3) ;
  - bandeau Groupe, ligne 2 : « MJ hors ligne · état de {time} » ;
  - bandeau fiche : « Combat · MJ hors ligne (état de {time}) ». Même exception que la PR #301 : ≤ 120 dp à partir
    de ×1,6, icône masquée ;
  - une seule annonce polie, sur l'écran Combat seulement : « Le MJ semble hors ligne. La dernière vue reste
    affichée. ».
- **Après 10 min sans message** :
  - les bandeaux Groupe et fiche sont retirés (`AnimatedSize` 200 ms), ainsi que le callout ;
  - si l'écran Combat est ouvert, il passe à l'état « Pas de nouvelles du MJ » : `PixelIcon` 32 `textSecondary`,
    titre en 16/800, « Dernier état reçu à {time}. Le combat réapparaîtra ici s'il reprend. » en 13
    `textSecondary`, `SecondaryButton` « Retour au groupe » ;
  - **pas** de résumé de fin : on ne sait pas si le combat est terminé.
- **Retour d'un message** :
  - il s'applique selon les règles de `seq` ;
  - un `state` ou un `combat_start` d'un **autre** combat remplace la vue ;
  - le bandeau « MJ hors ligne » se retire (`AnimatedSize` 200 ms), avec l'annonce « Le MJ est de retour. » ;
  - après expiration, le combat réapparaît en fondu (200 ms).

## 8. Fin, ouverture depuis une notification, aucun combat
- **`combat_end`** :
  - carte de résumé existante `combatEndedSummary(rounds, count)` (pluriels ICU existants) et « Retour au groupe » ;
  - avec `participant_count` = 0 : « Combat terminé » en 16/800 puis « Le combat s'est terminé avant que l'ordre
    soit dévoilé. » en 13 `textSecondary`. La forme « 1 round · 0 participant » se lirait comme une panne, et la
    nouvelle formulation ne révèle rien des participants cachés ;
  - joueur hors de l'écran Combat : bandeaux et callout retirés, une seule annonce polie (comportement existant) ;
  - plus aucun message de ce combat n'est appliqué ensuite.
- **Notification `combat_start` ou `your_turn` touchée** (`onMessageOpenedApp`, `getInitialMessage`) :
  - données attendues : `{v: "1", type, group_id}`. Un type inconnu est ignoré ;
  - compte qui n'est plus membre du groupe : rien ne s'ouvre, SnackBar « Ce groupe n'est plus accessible. » ;
  - membre : `go('/groups/{id}')` puis `push('/groups/{id}/combat')`, pour que le retour mène à l'écran Groupe ;
  - le combat natif V2 doit utiliser le même format de données et donc le même routage (décision 59). À étendre dans
    `_routeFromMessage` (`push_token_registrar.dart:185`).
- **Ouverture de l'écran sans état connu** :
  - chargement existant, avec un libellé **visible** « Connexion au combat… » (13 `textSecondary`) pendant 5 s au
    plus (abonnement + `state_request`) ;
  - puis, si rien n'est arrivé : état « Aucun combat en cours » : `PixelIcon` 32, titre en 16/800, « Le combat est
    peut-être terminé, ou le MJ n'est pas connecté. Il s'affichera ici dès qu'il reprend. », bouton « Retour au
    groupe » ;
  - l'écran **continue d'écouter** et bascule en fondu (200 ms) si un état arrive ;
  - si la fin de ce combat est déjà connue en mémoire : résumé de fin ;
  - cet état remplace aussi le message natif « Aucun combat actif. ».
- **`your_turn` touchée alors que le tour est passé** : vue courante, sans message particulier.

## 9. Réglages
- **Emplacement** : `ProfileNotificationsScreen`, **première** ligne de la carte « DÉCLENCHEURS »
  (`profile_notifications_screen.dart:223`).
- **Composant** : `_ToggleRow(standalone: false)`, icône `campaign_outlined` 22.
  - Titre : « Combat et révélations du MJ ».
  - Sous-titre : « Début du combat, ton tour et ce que le MJ te montre. ». C'est la seule ligne de la carte avec un
    sous-titre : son titre couvre trois évènements et le combat natif (décision 60).
- **Comportement** : grisée quand « Notifications push » est coupé ; activée par défaut (pas de ligne = activée) ;
  bascule optimiste, retour arrière et SnackBar d'erreur existants ; colonne `push_gm_combat_and_reveals`.
- **Portée** : l'interrupteur ne règle que les notifications push. Bandeaux, callout et haptique dans l'app restent
  actifs (Q6).

## 10. Accessibilité et recettage
- **Annonces polies**, seulement sur un changement **reçu** : jamais au chargement, ni sur un `state` de reprise.
  Fusion existante à une annonce par seconde. Liste :
  - « Combat ! Le MJ lance un combat dans {group}. »
  - « Le MJ demande ton initiative. »
  - « Initiative {value} envoyée au MJ. »
  - « Le MJ a reçu ton initiative. »
  - « Le MJ a retenu {value}. »
  - « L'ordre d'initiative est dévoilé. »
  - « Round {round}. Tour de {name}. », sur `turn` seulement (un `order` qui déplace la surbrillance n'est pas
    annoncé).
  - « C'est ton tour. », assertive.
  - « Le MJ semble hors ligne. La dernière vue reste affichée. » puis « Le MJ est de retour. »
  - « Le combat est terminé. »
- **Jamais la couleur seule** : tour = bordure + fond + libellé ; mort = badge (texte + icône) + « Tour sauté » ;
  MJ hors ligne = texte.
- **Texte ×3,0 sur 320 dp** (leçons de D232 et D237) :
  - aucun nom de personnage ni de groupe en `maxLines: 1` ni coupé par une ellipse ;
  - tests à ×3,0 **avec les boutons présents** : carte d'initiative avec son bouton, ligne « morte » avec ses badges,
    callout avec « Fermer », bandeau fiche « MJ hors ligne ».
- **Règles générales** : cibles ≥ 44×44, police ≥ 11 (12 pour le texte courant), portrait uniquement.
- **Mesures de recettage (320 dp)** :
  - en-tête avec la ligne de source : ×1,0 = 90 à 120 dp (préparation : ≤ 150) ; ×2,0 et ×3,0 : ≤ 40 % du viewport ;
  - carte d'initiative : ×1,0 = 110 à 170 dp ; en zone fixe : ≤ 30 % du viewport ;
  - callout : ×1,0 = 56 à 88 dp ; ×2,0 et ×3,0 : ≤ 25 % du viewport ;
  - ligne « morte » : ×1,0 ≤ 96 dp ; ×3,0 ≤ 320 dp ;
  - bandeaux : fourchettes de `combat-groupe-ui.md` §6, + 2 dp pour la variante `yourTurn` (bordure 3 + halo) ;
  - zéro saut de défilement à la réception d'un message (position identique avant et après) ;
  - le mode `yourTurn` ne change pas la hauteur de l'en-tête.

## 11. Clés `.arb` (FR / EN, bloc contigu après les clés `combat` existantes, tutoiement)
- `combatGrimoireSource` : « Mené depuis Grimoire » / "Run from Grimoire"
- `combatGrimoireLeaderInfo` : « Tu mènes ce combat depuis Grimoire. Ici, tu le suis comme les joueurs. » / "You're running this combat from Grimoire. Here, you follow it like the players."
- `combatShout` : « Combat ! » / "Combat!"
- `combatPreparingStatus` : « En préparation » / "Getting ready"
- `combatPreparingHint` : « L'ordre d'initiative apparaîtra au premier tour. » / "The initiative order will appear on the first turn."
- `combatBannerPreparing` : « Combat en préparation » / "Combat getting ready"
- `combatBannerOpen` : « Ouvrir le combat » / "Open combat"
- `combatBannerSendInitiative` : « Envoie ton initiative · Ouvrir le combat » / "Send your initiative · Open combat"
- `combatBannerInitiativeSent` : « Initiative envoyée · Ouvrir le combat » / "Initiative sent · Open combat"
- `combatSheetBannerInitiativeRequested` : « Combat ! Envoie ton initiative » / "Combat! Send your initiative"
- `combatSheetBannerPreparingSemantics` : « Combat en préparation. Ouvrir le combat. » / "Combat getting ready. Open combat."
- `combatInitiativeRequestTitle` : « Le MJ demande ton initiative » / "The GM is asking for your initiative"
- `combatInitiativeRequestFor(name)` : « Pour {name} » / "For {name}"
- `combatSendInitiative` : « Envoyer mon initiative » / "Send my initiative"
- `combatSendToGm` : « Envoyer au MJ » / "Send to GM"
- `combatSendHint` : « Une fois reçue, seul le MJ peut la modifier. » / "Once received, only the GM can change it."
- `combatInitiativeSent(value)` : « {value} · envoyée au MJ » / "{value} · sent to the GM"
- `combatInitiativeAwaitingReceipt` : « En attente de confirmation du MJ… » / "Waiting for the GM to confirm…"
- `combatInitiativeReceived(value)` : « {value} · reçue par le MJ » / "{value} · received by the GM"
- `combatInitiativeKnownByGm` : « Le MJ a ton initiative » / "The GM has your initiative"
- `combatInitiativeMayAdjust` : « Le MJ peut l'ajuster : la valeur retenue s'affichera au premier tour. » / "The GM may adjust it: the final value will show on the first turn."
- `combatInitiativeNotReceived` : « Le MJ n'a pas reçu ton initiative. Renvoie-la. » / "The GM didn't get your initiative. Send it again."
- `combatInitiativeRequestedAgain` : « Le MJ te redemande ton initiative. » / "The GM is asking for your initiative again."
- `combatInitiativeSentLabel` : « Envoyée au MJ » / "Sent to the GM"
- `combatInitiativeCorrected(sent)` : « Corrigée par le MJ (envoyé : {sent}) » / "Adjusted by the GM (you sent {sent})"
- `combatUnavailableGmOffline` : « Indisponible tant que le MJ est hors ligne. » / "Unavailable while the GM is offline."
- `combatSendRateLimited(seconds)` : « Trop d'envois. Réessaie dans {seconds} s. » / "Too many attempts. Try again in {seconds} s."
- `combatSendFailed` : « Envoi impossible. Réessaie. » / "Couldn't send. Try again."
- `combatNotMemberAnymore` : « Tu ne fais plus partie de ce groupe. » / "You're no longer in this group."
- `combatBadgeDead` : « Mort » / "Dead"
- `combatTurnSkipped` : « Tour sauté » / "Turn skipped"
- `combatRowDeadSemantics` : « mort, tour sauté » / "dead, turn skipped"
- `combatRemovedByGm` : « Le MJ t'a retiré de ce combat. » / "The GM removed you from this combat."
- `combatYourTurn` : « À toi de jouer » / "Your turn"
- `combatBannerYourTurn(round)` : « À toi de jouer · round {round} » / "Your turn · round {round}"
- `combatSheetBannerYourTurnSemantics(round)` : « À toi de jouer, round {round}. Ouvrir le combat. » / "Your turn, round {round}. Open combat."
- `combatCalloutInitiativeTitle` : « Initiative demandée » / "Initiative requested"
- `combatCalloutSendInitiative(group)` : « {group} · Envoie ton initiative » / "{group} · Send your initiative"
- `combatCalloutOpen(group)` : « {group} · Ouvrir le combat » / "{group} · Open combat"
- `combatCalloutYourTurnBody(group, round)` : « {group} · round {round} · Ouvrir le combat » / "{group} · round {round} · Open combat"
- `combatCalloutClose` : « Fermer » / "Close"
- `combatGmOfflineBanner(time)` : « Le MJ semble hors ligne. Dernier état reçu à {time} ; le combat reprendra dès son retour. » / "The GM seems to be offline. Last update at {time}; the combat will resume when they're back."
- `combatBannerGmOffline(time)` : « MJ hors ligne · état de {time} » / "GM offline · as of {time}"
- `combatSheetBannerGmOffline(time)` : « Combat · MJ hors ligne (état de {time}) » / "Combat · GM offline (as of {time})"
- `combatSheetBannerGmOfflineSemantics(time)` : « Combat en cours, MJ hors ligne, état de {time}. Ouvrir le combat. » / "Combat in progress, GM offline, as of {time}. Open combat."
- `combatInterruptedTitle` : « Pas de nouvelles du MJ » / "No news from the GM"
- `combatInterruptedBody(time)` : « Dernier état reçu à {time}. Le combat réapparaîtra ici s'il reprend. » / "Last update at {time}. The combat will show up here again if it resumes."
- `combatConnecting` : « Connexion au combat… » / "Connecting to the combat…"
- `combatNoneTitle` : « Aucun combat en cours » / "No combat in progress"
- `combatNoneBody` : « Le combat est peut-être terminé, ou le MJ n'est pas connecté. Il s'affichera ici dès qu'il reprend. » / "The combat may be over, or the GM isn't connected. It will show up here as soon as it resumes."
- `combatGroupNotAccessible` : « Ce groupe n'est plus accessible. » / "This group is no longer available."
- `combatEndedTitle` : « Combat terminé » / "Combat over"
- `combatEndedBeforeOrder` : « Le combat s'est terminé avant que l'ordre soit dévoilé. » / "The combat ended before the order was revealed."
- `combatAnnounceStart(group)` : « Combat ! Le MJ lance un combat dans {group}. » / "Combat! The GM starts a combat in {group}."
- `combatAnnounceInitiativeRequested` : « Le MJ demande ton initiative. » / "The GM is asking for your initiative."
- `combatAnnounceInitiativeSent(value)` : « Initiative {value} envoyée au MJ. » / "Initiative {value} sent to the GM."
- `combatAnnounceInitiativeReceived` : « Le MJ a reçu ton initiative. » / "The GM received your initiative."
- `combatAnnounceInitiativeCorrected(value)` : « Le MJ a retenu {value}. » / "The GM set it to {value}."
- `combatAnnounceOrderRevealed` : « L'ordre d'initiative est dévoilé. » / "The initiative order is revealed."
- `combatAnnounceGmOffline` : « Le MJ semble hors ligne. La dernière vue reste affichée. » / "The GM seems to be offline. The last view stays on screen."
- `combatAnnounceGmBack` : « Le MJ est de retour. » / "The GM is back."
- `profileNotificationsGmCombat` : « Combat et révélations du MJ » / "GM combat and reveals"
- `profileNotificationsGmCombatSubtitle` : « Début du combat, ton tour et ce que le MJ te montre. » / "Combat start, your turn and what the GM shows you."
- **Clés existantes réutilisées** : `combatEmptyPlayer`, `combatEndedSummary`, `combatBackToGroup`,
  `combatAnnounceYourTurn`, `combatAnnounceTurn`, `combatAnnounceEnded`, `combatOfflineBanner`,
  `combatBannerOffline`, `combatSheetBannerOffline`, `combatStartUnavailableOffline`, `combatFailureNoCharacter`,
  `combatInitiativeSheetTitle`, `combatFillInitiative`, `combatInitiativeToEnter`, `combatBannerTitle`,
  `combatBannerTurn`, `combatBannerNoTurn`, `combatLoading`.

## 12. Questions produit (avec recommandation)
- **Q1. Combat natif et combat Grimoire en même temps dans un groupe.**
  - Recommandation : le combat Grimoire est affiché en priorité tant qu'il est vivant.
  - « Lancer un combat » (natif) est désactivé, avec l'indice « Un combat est mené depuis Grimoire. ».
  - Le refus symétrique (Grimoire refuse « Préparer » pendant un combat natif) reste à arbitrer côté Grimoire.
- **Q2. « Présent » doit vouloir dire « Nexus au premier plan ».**
  - Retirer la présence (ou se désabonner) quand l'app passe en arrière-plan. Sinon, Grimoire ne notifie pas un
    joueur dont l'app est en arrière-plan mais encore connectée, et ce joueur rate son tour.
  - S'abonner aux canaux de **tous** les groupes du joueur tant que l'app est au premier plan. Sinon, aucun callout
    hors de l'écran du groupe.
  - Recommandation : oui aux deux. Choix technique à faire par le chef de projet avec `dev-flutter`.
- **Q3. Accusé de réception rapide de l'initiative pendant la préparation** (aujourd'hui jusqu'à 35 s).
  - Recommandation : Grimoire publie un `state` quand il applique une initiative (petite PR Grimoire).
  - À défaut : Nexus envoie un `state_request` 2 s après un envoi réussi. Coût : un `state` de plus, vu par tout le
    groupe (même fuite de timing que D241 b, déjà acceptée).
- **Q4. Pas de modification de l'initiative par le joueur une fois reçue** (Grimoire l'ignore).
  - Recommandation : le confirmer, avec le texte « seul le MJ peut la modifier ».
- **Q5. Afficher le nom « Grimoire » aux joueurs.**
  - Recommandation : oui, dans la seule ligne de source discrète.
- **Q6. L'interrupteur ne règle que les notifications push.**
  - Recommandation : oui. Les signaux dans l'app (bandeaux, callout, haptique) restent.
- **Q7. Source du badge « Mort ».**
  - Nexus le déduit de `characters.is_dead`. Il faut confirmer que le « Mort » de Grimoire (décision 58) lit ou
    écrit ce même champ.
  - Sinon, il faudrait un champ dans le contrat : changement de contrat à faire valider.
  - Recommandation : même champ.
- **Hors périmètre, signalé** : un badge « Inconscient » dans la ligne (les PV des joueurs sont déjà visibles dans
  l'onglet Membres). À décider plus tard.

## 13. Arbitrages du 23/11/2026 (chef de projet et Matthias)
- **Composants (a) à (f) du §0** : validés par le chef de projet.
- **Q1** (Matthias, décision 61) : **Grimoire prioritaire**. Tant qu'un combat Grimoire est vivant, Nexus l'affiche et
  désactive « Lancer un combat » (natif) avec l'indice « Un combat est mené depuis Grimoire. ». Le refus symétrique côté
  Grimoire viendra plus tard.
- **Q2** (chef de projet) : **présent = Nexus au premier plan**. La présence est retirée (ou les canaux quittés) quand
  l'app passe en arrière-plan ; tant que l'app est au premier plan, Nexus s'abonne aux canaux de **tous** les groupes du
  joueur (callout hors de l'écran du groupe).
- **Q3** (chef de projet) : pas de changement de Grimoire. Nexus envoie un `state_request` 2 s après un envoi
  d'initiative réussi (même fuite de timing que D241 b, déjà acceptée).
- **Q4** (Matthias, décision 62) : **seul le MJ modifie une initiative reçue** ; pas de « Modifier » après l'envoi.
- **Q5** (Matthias, décision 63) : le nom « Grimoire » est montré aux joueurs, **seulement** dans la ligne de source
  discrète de l'en-tête.
- **Q6** (chef de projet) : l'interrupteur ne règle que les notifications push ; bandeaux, callout et haptique restent.
- **Q7** (chef de projet) : le badge « Mort » lit `characters.is_dead`, le même champ que Grimoire (cache de l'étape 5,
  décision 58) ; aucun changement de contrat.
- Badge « Inconscient » : hors périmètre.
