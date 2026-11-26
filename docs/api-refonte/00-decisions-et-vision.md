# Refonte de la base en API partagée — vision produit et décisions (Matthias, 14/11/2026)

Ce document prime sur `03-propositions.md` là où il le contredit : l'agent `dev-sql-api` a écrit ses rapports (étape 1) avant
ces informations. Aucune modification de la base ni des dépôts n'est faite avant la validation de Matthias.

## Vision produit
- **L'app web `markdown-editor` (dépôt web, « Histoires ») est abandonnée.** Florian développe un **nouvel outil** de MJ,
  séparé, qui se lie à l'app mobile. Les deux utilisent **le même compte** (connexion commune).
- **Dans l'outil, le MJ crée l'histoire et tout l'environnement de l'aventure** (PNJ, lieux, notes, cartes…).
- **« Générer un groupe » depuis une histoire** : un bouton de l'outil crée un groupe à partir de l'histoire ; le MJ envoie le
  **code d'invitation** aux joueurs qui ont l'app mobile ; ils rejoignent le groupe avec ce code.
- **Un groupe n'est pas forcément lié à une histoire** (un groupe créé depuis l'app mobile seule continue d'exister).
- **Groupe lié à une histoire** : le MJ (propriétaire de l'histoire) dispose de **fonctionnalités synchronisées** entre
  l'outil et l'app mobile : **lancer les phases de combat, attribuer des récompenses, appliquer des effets**, etc.
  directement dans le groupe, depuis l'outil.
- **Les données de référence sont communes aux deux outils** : monstres (créatures), objets, livre de sorts, classes,
  races, etc. L'outil lit les mêmes données que l'app mobile.
- **Temps réel** des deux côtés pour l'immersion (joueurs sur mobile, MJ dans l'outil).

## Décisions d'architecture (Matthias, 14/11/2026)
1. **Même projet Supabase** (`nexus-jdr`) : mêmes comptes (auth), même base ; le nouvel outil consomme l'API qu'on conçoit
   (hypothèse de travail à confirmer avec Florian).
2. **Les histoires et leur environnement vivent dans notre base, accessibles par l'API** (lien groupe ↔ histoire direct,
   synchronisation temps réel simple).
3. **`markdown-editor` est gelé** : ses migrations restent l'historique de la base ; ses données (histoires, fiches du MJ,
   `stories`, `codex_entries`, buckets) ne sont ni modifiées ni supprimées maintenant ; migration ou archivage décidés
   plus tard.
4. Le **combat porté par le groupe** (PR web #47, appliquée) reste valable ; une histoire se rattache au groupe, pas
   l'inverse.

## Conséquences pour l'API (à instruire par `dev-sql-api`, sans rien modifier avant validation)

> **Remplacé en grande partie par les décisions des 15 et 16/11/2026** (fin de ce document) : plus d'histoire en base, plus
> d'actions `gm_*` journalisées dans `game_events`, combats de l'outil non stockés. Section conservée pour l'historique.
- **Modèle** : `story` (histoire + environnement, propriétaire = MJ), `group.story_id` **nullable** (groupe lié ou non),
  génération d'un groupe depuis une histoire (RPC dédiée : crée le groupe, le code d'invitation, lie l'histoire, MJ =
  propriétaire de l'histoire et du groupe), relation avec l'existant (`groups.campaign_id` jamais utilisé,
  `character_campaigns`, flux `join-group`).
- **Actions MJ depuis l'outil** : RPC bornées, journalisées : lancer/terminer un combat, gérer participants et monstres
  (réutiliser les RPC du combat), attribuer des récompenses (pièces, objets, expérience/niveau) en « accorder » ou
  « appliquer », appliquer des effets/états ; droits d'écriture du MJ sur les fiches des joueurs du groupe **lié**
  seulement, jamais d'élargissement général de la RLS ; audit des actions ; résolution des conflits avec la file hors ligne
  du mobile.
- **Données de référence en lecture** pour l'outil : créatures (monstres), objets, sorts, classes, races, dons, historiques,
  avec édition et source (2014/2024) ; accès en lecture par vues versionnées ; performances (index, pagination, recherche).
- **Temps réel** : un canal par groupe (et par histoire liée), événements métier (combat, récompense, effet, niveau) ;
  reconnexion avec reprise par révision ; coût et filtres.
- **Comptes** : auth commun, rôles dérivés des données (propriétaire d'histoire = MJ, membre de groupe, propriétaire de
  personnage), pas de rôle global ; ce que Florian doit implémenter côté outil (connexion, appels API, Realtime).
- **Évolutivité et normes SQL** : contrats versionnés, tables de référence extensibles, conventions de nommage, contraintes,
  RLS performantes ; aucun remodelage futur forcé sur les parties déjà refaites.

## Questions ouvertes (à instruire, aucune tranchée ici)
Cardinalité histoire ↔ groupes (une histoire, plusieurs groupes ? un groupe, une histoire ?), un MJ peut-il avoir plusieurs
histoires, un groupe sans MJ propriétaire de l'histoire, transfert de propriété, suppression d'une histoire liée (le groupe
survit ?), partage d'une histoire entre MJ (co-MJ), droits des joueurs sur l'environnement (jamais de spoilers),
données de référence personnalisées par le MJ (monstres/objets maison), jeu de données de test et projet Supabase séparé
avant les phases lourdes (dev/staging/prod partagent aujourd'hui le même projet), calendrier de l'outil de Florian.

## Décisions de la session de propositions (Matthias, 14/11/2026)
1. **Migrations** : elles restent dans le dépôt web (`markdown-editor`, gelé côté application mais historique unique de la base).
2. **Pas de projet Supabase de test séparé** pour l'instant : on continue sur la production avec `--dry-run`. Ce n'était pas
   la recommandation de `dev-sql-api` (risque : toute erreur de migration touche la production). **Garde-fous obligatoires** :
   migrations additives et idempotentes, rejeu complet dans un Postgres jetable (deux fois) avant PR, contraintes ajoutées en
   `NOT VALID` puis validées séparément, aucune suppression ni renommage d'objet utilisé, retour arrière documenté pour chaque
   migration, requêtes de contrôle en lecture seule avant et après, application étape par étape (une migration à la fois) par
   Matthias avec `--dry-run`, sauvegarde/point de restauration vérifié avant les phases qui touchent des données. À rediscuter
   avant la phase 2 (histoire) et la phase 4 (actions du MJ), qui modifient des données et des droits.
3. **Cardinalité histoire ↔ groupe** : un groupe a 0 ou 1 histoire, une histoire a 0 à N groupes (liaison par procédures, le
   plusieurs-à-plusieurs reste possible plus tard sans rupture).
4. **Démarrage** : **phase 0 seule** (hygiène invisible : index manquants, politiques d'accès plus rapides, contraintes,
   droits), sans aucun changement de contrat visible par les apps. Les phases 1 et suivantes ne démarrent qu'avec une nouvelle
   validation de Matthias.

## Décisions du 15/11/2026 (Matthias, après l'analyse de `grimoire-du-mj`)
1. **L'outil de Florian est `grimoire-du-mj`** (github.com/Coudercf/grimoire-du-mj) : application locale (serveur Node +
   SQLite, client React), sans Supabase ni compte à ce jour.
2. **Il reste local** et sera lancé avec **Electron** comme un logiciel : « afin d'avoir un local avec les fichiers à importer
   qui seront stockés directement en local afin d'éviter de devoir les importer sur un serveur et de devoir les stocker ».
3. **Connexion au compte Nexus** à ajouter : « afin de récupérer son compte et pouvoir récupérer les groupes et les joueurs ».
4. **Auth locale obligatoire** : l'absence d'authentification sur le réseau local n'est pas acceptée.
5. Import de l'outil : « mettre à jour » et « réutiliser la bibliothèque » restent cochés par défaut.

Étude : `08-outil-local-electron-auth.md` (Electron, connexion) et `09-base-outil-local.md` (base). Décisions prises par
Matthias le même jour sur les questions de l'étude (D1 à D14 de 09 §4) :

6. **Décision n° 2 du 14/11 remplacée** (option O1 + étiquette de 09 §2.2) : « Le contenu des campagnes (histoire, PNJ, lieux,
   plateaux, images, imports) vit dans l'outil local du MJ. La base Nexus porte les comptes, les groupes, les membres, les
   personnages, le combat, les données de référence et, plus tard, les actions du MJ journalisées. » Le **titre (et un résumé
   public) de la campagne est visible des joueurs** sur le groupe (colonnes nullables sur `groups`, migration additive + version
   mobile). La phase 2 de `05` (§2.1-2.4 : `adventure_*`, bucket, modèle de spoilers, `generate_group_from_story`,
   `groups.adventure_id`) est **abandonnée**.
7. **Créer le groupe depuis l'outil** : « le compte qui fait l'histoire sera le MJ […] quand son histoire est terminée, créer le
   groupe et inviter les joueurs ». Via l'edge function existante `create-group` (sans personnage : MJ `is_game_master = true`),
   avancée juste après la connexion dans la feuille de route.
8. **Qui développe** : un sous-agent dédié TypeScript/Electron ; chaque lot = PR sur `Coudercf/grimoire-du-mj`, relue par
   `code-reviewer` puis par Florian, qui merge.
9. **Une base locale par compte**, avec reprise (copie) de la base existante de Florian au premier lancement.
10. **Contrat de lecture d'abord** : `api_v1.group_snapshot` / `my_gm_groups` livrés avant la lecture des groupes et joueurs.
11. **CA** : fonction SQL, parité testée avec le calcul du mobile (C2). **PV d'un héros lié** : la fiche mobile fait foi (jeton
    de l'outil en lecture jusqu'aux actions MJ). **Groupes affichés** : ceux dont le compte est propriétaire.
12. **Code d'invitation lisible par les membres** : voulu, on garde ; seul le commentaire faux est corrigé (D227).
13. **Distribution** : Windows non signé, sans mise à jour automatique au début. **Florian travaille aussi sur Mac** : version
    macOS à prévoir (notarisation quand le compte Apple Developer existera).
14. **Comptes et groupes de test dédiés** pour le développement de l'outil (pas de projet Supabase de test).
15. **Google** : au lot 5, après e-mail + mot de passe.

## Décisions du 16/11/2026 (Matthias, revue de la feuille de route de l'outil)

**Document de référence pour l'outil** : `FEUILLE-DE-ROUTE.md` de la branche `dev/nexus-desktop` du dépôt de Florian
(https://github.com/Coudercf/grimoire-du-mj/blob/dev/nexus-desktop/FEUILLE-DE-ROUTE.md), étapes 0 à 12. Il prime sur `05` à `09` là
où ils le contredisent. Les tickets Project #7 portent la même numérotation (« étape N »).

16. **Combats de l'outil non enregistrés en base** : « les combats seront juste des actions ». Grimoire est le maître du combat
    (monstres, PV des monstres, ordre d'initiative en local) ; les messages passent par un canal temps réel privé du groupe
    (Supabase Realtime, broadcast). Les tables et RPC de combat existantes restent pour le combat mené **dans l'app** par un MJ
    sans Grimoire.
17. **PV synchronisés dans les deux sens** pendant les combats ; fin de combat affichée dans l'app ; le MJ peut montrer l'image
    d'un monstre.
18. **Actions sur les fiches** : PV et états écrits par Grimoire via une fonction protégée (A1, l'app passe ses PV hors ligne en
    écarts) ; récompenses proposées sur le canal, acceptées et appliquées par l'app du joueur (A2).
19. **Révélations** (image de monstre, carte PNJ, énoncé d'énigme, parchemin) : affichées dans l'app tant que le MJ ne les cache
    pas (bouton Afficher / Cacher) ; rien en base.
20. **Bestiaire uniquement dans Grimoire** (l'app ne l'utilise pas) ; **catalogue d'objets** partagé, objets personnalisés dans
    Grimoire. Les autres catalogues ne sont pas copiés dans l'outil.
21. **Lien histoire ↔ groupe facultatif** ; Grimoire affiche les histoires ; une histoire peut être associée à un groupe généré
    depuis Grimoire **ou existant** (créé dans l'app). Grimoire et l'app restent utilisables séparément. Remplace le point 11
    « groupes affichés ».
22. **Devenir MJ du groupe** : oui (fonction base + bouton dans l'app).
23. **Notifier mon groupe** : oui (fonction réservée au MJ : « Combat ! », « À toi de jouer », « Nouvelle révélation »).
24. **Grimoire payant** (abonnement ou licence, formule à définir) : compte Nexus **obligatoire** ; droits d'accès en base (seule
    table ajoutée pour l'outil) ; signature et mises à jour automatiques obligatoires avant la mise en vente (complète le point 13).
25. **Offre Supabase gratuite** pour le moment (256 Ko par message temps réel, donc images réduites ; aucune sauvegarde ; pause
    après une semaine d'inactivité) ; le passage en Pro avant la mise en vente est proposé, non décidé.

## Décisions du 17/11/2026 (validation de Florian et réponses de Matthias)

26. **Noms des projets** (demande de Florian) : **Grimoire** = l'app de bureau Electron (`grimoire-du-mj`, ex « outil de
    Florian ») ; **Nexus** = l'app mobile (ce dépôt) ; **DeepCore** = l'API et la base (Supabase), et son dépôt (ex
    `markdown-editor`, « dépôt web »). Le compte utilisateur commun s'affiche « **compte Nexus** ».
27. **Florian valide** le travail sur son dépôt, sur la branche `dev/nexus-desktop`. Les PR de chaque étape y sont **mergées
    par Matthias** (jamais par Claude) ; Florian décide seul de la fusion dans `main`. Remplace le point 8 (« Florian relit
    et merge »).
28. **Version d'essai** (demande de Florian) : Grimoire gratuit, local, **sans limite de durée et sans compte**, avec un
    extrait du bestiaire et des objets livré à l'installation. La **licence** (compte Nexus) débloque DeepCore : bestiaire
    et catalogue d'objets complets, groupes, lien avec Nexus. Licence expirée : retour à la version d'essai. Remplace « compte
    obligatoire » (point 24).
29. **Bestiaire complet dans DeepCore, réservé aux licences** : la table des monstres **reste** (n'est pas supprimée) ; sa
    lecture publique et celle de ses traductions sont à restreindre ; Grimoire la télécharge avec une licence valide.
    Remplace « bestiaire uniquement dans Grimoire » (point 20).

## Décisions des 18 et 19/11/2026 (réponses de Matthias)

30. **Fusion des PR** : quand une PR est prête, Claude **demande à Matthias l'autorisation de merger** (une question par
    PR) et ne merge qu'après son « oui ». Remplace « mergées par Matthias (jamais par Claude) » (point 27). Les sous-agents
    ne mergent jamais ; Florian garde seul `main` de Grimoire ; les migrations restent appliquées par Matthias.
31. **Devenir MJ, autre MJ déjà présent** : si un autre membre est déjà MJ du groupe, « Devenir MJ » est **refusé** avec un
    message (`mj_already_assigned`) ; personne n'est rétrogradé. Le personnage du propriétaire quitte le groupe et reste
    dans sa liste.
32. **Combat actif** : la règle serveur « le propriétaire ne quitte ni ne dissout le groupe pendant un combat actif » est
    livrée avec « Devenir MJ » (même PR DeepCore #49, contrôle partagé `combat_active`). La suppression d'un compte n'est
    jamais bloquée.
33. **Aperçu d'invitation** : avant de rejoindre un groupe, Nexus montre le **titre** de la campagne (pas le résumé
    public). `preview-group-invite` renvoie donc `story_title` (étape 4).
34. **Aperçu d'invitation dans Nexus** : Nexus n'en avait pas (il rejoignait dès le code validé). Une **carte d'aperçu**
    est ajoutée sous le champ du code : nom du groupe, nombre de membres, « Campagne : … » ; jamais le résumé.
35. **Hors ligne** : l'étape 4 affiche la campagne **en ligne seulement** ; la mise en cache hors ligne de tout l'écran
    Groupe (aujourd'hui en erreur sans réseau) devient un ticket séparé.
36. **Titre identique au nom du groupe** (cas fréquent, « Générer un groupe » reprend le titre) : la ligne « Campagne : … »
    n'est pas répétée ; le résumé public reste affiché s'il existe.
37. **Deux armures ou deux boucliers équipés** (étape 5, 20/11/2026) : Nexus **empêche** d'équiper une seconde armure ou un
    second bouclier ; pour une fiche qui en aurait déjà deux, la **meilleure CA** s'applique, dans Nexus comme dans le calcul
    SQL de DeepCore (0 fiche concernée en production au 20/11). Le reste du calcul SQL de la CA reproduit Nexus **tel quel**
    (« la fiche mobile fait foi »), écarts RAW compris (D234), à corriger plus tard des deux côtés en même temps.

## Décisions du 22/11/2026 (avis RGPD de l'étape 5, `docs/rgpd-registre.md`)

38. **Conservation hors ligne dans Grimoire** des données des joueurs (pseudo, résumé de fiche, portrait) : **30 jours**
    depuis la dernière lecture réussie, plus effacement immédiat si le groupe est perdu, si le compte n'est plus
    propriétaire ou si la session est révoquée (R3).
39. **Corrections RGPD avant l'étape 6** : R2, R3, R4 (Grimoire) et R5 (DeepCore) sont traités avant de lancer l'étape 6.
40. **Textes d'information** (R1) : le chef de projet rédige une proposition (politique de Nexus et du site, texte pour le
    MJ dans Grimoire) ; Matthias la relit et la valide, avec Florian pour Grimoire, avant toute mise en ligne.
41. **R14 traité avant l'étape 6**, comme R13 : la suppression d'un compte efface ses fichiers dans tous les espaces de
    stockage (PR DeepCore #53). Une image d'un compte supprimé que quelqu'un d'autre aurait collée par son adresse dans
    son propre texte **disparaît aussi** : le droit à l'effacement du propriétaire prime.

## Décisions du 22/11/2026 (étape 6 de Grimoire, écrans joueur sur tablette, PR Grimoire #10)

42. **Gestes sur la tablette d'un joueur** : seulement voir le plateau, recevoir le plateau montré par le MJ et déplacer
    les jetons de héros. Ouvrir le détail d'un objet, ouvrir un trésor (révélation) et tourner un héros restent des gestes
    du MJ.
43. **PV des ennemis** : quand les barres de vie des ennemis sont masquées, aucun écran joueur (HDMI ou tablette)
    n'affiche rien de leurs PV, y compris les « −N » de dégâts (retirés de l'écran HDMI).

## Décisions du 23/11/2026 (étape 7 de Grimoire, combat piloté par Grimoire, lancée le 23/11)

44. **« MJ avec une licence valide » avant l'étape 11** : en attendant les licences, la règle est **propriétaire du
    groupe** (compte Nexus connecté). La vérification de licence s'ajoutera à l'étape 11 au même endroit (fonction SQL
    unique), sans rien défaire.
45. **Panneau de combat dans la version d'essai** : oui, combat local (PNJ et héros saisis à la main) sans compte ; le
    lien avec Nexus (initiatives, tours, notifications) reste réservé au compte.
46. **Lanceur de dés dans l'étape 7** : initiative des monstres tirée par Grimoire (d20 + bonus) et bouton pour lancer
    l'attaque et les dégâts lus dans la fiche du PNJ.
47. **Interrupteur dédié** « Combat et révélations du MJ » dans les réglages de notification de Nexus (préférence dans
    DeepCore, respectée par `notify-group`), en plus de l'interrupteur général.
48. **Limites** : `notify-group` 10 par minute par groupe et MJ, 300 par 24 h par MJ ; messages des joueurs vers le MJ
    20 par minute par membre. Réglables plus tard.
49. **Présence pendant un combat** : seul le MJ voit quels joueurs ont le combat ouvert (minimisation) ; les autres
    joueurs ne la voient pas.
50. **Joueur exclu** : son accès aux messages du MJ doit être **coupé immédiatement**, pas après l'expiration de son jeton
    (jusqu'à 1 h). Faisabilité à établir par `dev-backend-supabase` (piste du chef de projet : sujet renouvelé à chaque
    départ d'un membre).

51. **Édition des règles du combat dans Grimoire** : réglage par campagne, **2014 par défaut** (2024 au choix). Surprise :
    en 2014, la créature surprise perd son premier tour (ni déplacement, ni action, ni réaction avant la fin de ce tour) ;
    en 2024, désavantage à son jet d'initiative.
52. **Monstres identiques** : **un jet d'initiative par monstre** (pas de jet commun par fiche).
53. **Score d'initiative fixe** (10 + modificateur, variante 2024) : option par campagne, **désactivée par défaut**.
54. **Jets de sauvegarde des monstres** dans l'étape 7 : un bouton par caractéristique, d20 + modificateur lu dans la
    fiche, **modifiable** par le MJ (la fiche ne connaît pas les maîtrises), avec avantage/désavantage.

55. **Cacher un PNJ ou un monstre** : les jetons de PNJ et de monstres peuvent être cachés (comme décors, trésors et
    objets) ; cacher un participant du combat cache son jeton, et inversement ; rien n'apparaît aux joueurs avant que le
    MJ le révèle.
56. **« Donner le tour (correction) »** : gardé (ajouté par `dev-grimoire` hors spécification), sans changer le round.
57. **Moitié des dégâts** (sauvegarde réussie) : calculée **type par type**, arrondie à l'inférieur, chaque moitié
    affichée (seule lecture compatible avec une résistance à un seul type).
58. **Héros relié à Nexus et mort** : badge « Mort » et tour **sauté automatiquement**, de façon réversible ; un héros à
    0 PV mais vivant garde toujours son tour (jets contre la mort).

Choix techniques du chef de projet (23/11, PR Grimoire #11) : rien n'est montré aux joueurs avant le début réel du
combat, et un participant hérite de l'état caché de son jeton ; l'édition et les réglages de combat entrent dans les
exports JSON ; le 20 et le 1 naturels restent affichés sans CA connue ; score fixe : +5 avec avantage, −5 avec
désavantage (PHB 2024 glossaire « Initiative », DMG 2014 p.270 et PHB 2014 p.175, selon `regles-dnd`).

59. **Partie Nexus de l'étape 7 avant les tickets « Combat V2 »** (combat mené dans Nexus sans Grimoire) : ce qui est
    commun (surlignage du tour, ouverture du combat depuis une notification) est construit de façon réutilisable ; les
    tickets V2 viennent ensuite et réutilisent ce socle.
60. **Un seul interrupteur de notification pour le combat** : « Combat et révélations du MJ »
    (`push_gm_combat_and_reveals`) couvre aussi le combat natif de Nexus (la préférence « rappel de tour » prévue pour
    la V2 n'est pas créée).

61. **Combat natif et combat Grimoire dans un même groupe** : Grimoire prioritaire ; tant qu'un combat Grimoire est
    vivant, Nexus l'affiche et désactive « Lancer un combat » (natif).
62. **Initiative reçue par le MJ** : le joueur ne peut plus la modifier depuis Nexus ; seul le MJ la corrige.
63. **Nom « Grimoire » montré aux joueurs**, seulement dans une ligne discrète « Mené depuis Grimoire » de l'en-tête du
    combat. Spécification visuelle de la partie Nexus : `docs/combat-grimoire-ui.md` (§13 : arbitrages).

## Décisions du 24/11/2026 (étape 8 de Grimoire, bestiaire et catalogue d'objets)

64. **Bestiaire complet avant l'étape 11** : lisible par **tout compte connecté** ; visiteurs sans compte refusés dès
    maintenant (aujourd'hui `creatures` est lisible par `anon`). Règle dans une seule fonction SQL, complétée par la
    vraie licence à l'étape 11 (comme la décision 44).
65. **Extrait d'essai livré avec Grimoire** : une trentaine de monstres courants de FP 0 à 2 et l'équipement de base
    (armes, armures, matériel), liste proposée dans la PR et **validée par Florian** à la relecture.
66. **Monstres 2014 ajoutés** : en plus des 331 monstres du SRD 5.2 (2024), importer ceux du **SRD 5.1** (2014), noms
    en français et en anglais, avec un champ d'édition sur chaque monstre (et sur chaque objet). Licence CC BY 4.0 pour
    les deux SRD : mention d'attribution de Wizards of the Coast obligatoire dans Grimoire.
67. **Bibliothèque (`nexus-jdr-library`) en ligne** : son onglet « Créatures » lit `creatures` et les noms des monstres
    sans connexion. La **restriction** des lectures directes (décision 64, migration `20261124092000`) part dans une
    **PR DeepCore séparée**, appliquée seulement après adaptation de la Bibliothèque (connexion requise pour l'onglet, ou
    passage par l'API). Identifiants, éditions et API d'export (PR DeepCore #56) s'appliquent tout de suite.
68. **Armes et armures du SRD 5.2** (édition 2024) ajoutées au catalogue dans la PR de contenu de l'étape 8, avec les
    monstres du SRD 5.1, vérifiées par `regles-dnd` (Nexus les verra aussi dans son catalogue).

69. **Armes et armures 2024, option A** : d'abord Nexus (filtre `edition` sur ses quatre lectures d'objets, classement
    des armes courantes/de guerre par une donnée et non plus par leur nom français), publié dans une version ; ensuite
    la migration DeepCore des 36 armes et 13 armures 2024 avec leurs bottes d'arme (Weapon Mastery). La PR DeepCore #58
    part sans elles (révise la décision 68).
70. **Monstres 2014 appliqués tout de suite**, même si la Bibliothèque les affiche en double avec les monstres 2024 de
    même nom tant qu'elle ne filtre pas par édition (ticket Bibliothèque, décision 67).
71. **Licence du SRD 5.1 français** : on s'appuie sur la mention CC BY 4.0 de la page 1 (le pied de page « Interdit à la
    revente… usage personnel » est ignoré) ; mention d'attribution partout ; à faire confirmer par un conseil avant toute
    vente.

72. **Données 2024 du bestiaire corrigées avant la PR Grimoire #13** : petite PR DeepCore (vulnérabilités perdues à
    l'import du SRD 5.2, `armor_detail` « armure naturelle » posé par défaut sur tous les monstres 2024 et vidé quand le
    SRD 5.2 ne l'indique pas) appliquée en production, puis l'extrait d'essai de la PR #13 est régénéré avant son merge.
73. **Dégâts en plus sous condition** (« plus 1d4 si le jet avait l'avantage ») : convertis en **seconde attaque nommée**
    avec la condition dans le nom ; les bonus écrits dans une phrase à part restent des notes.

74. **Objets 2014 retirés de l'extrait d'essai de Grimoire** : leurs descriptions ont été rédigées d'après le Manuel des
    Joueurs (source « Manuel des Joueurs » dans DeepCore), pas d'après le SRD, et aucune licence libre ne les couvre.
    L'extrait ne garde que les objets 2024 (SRD 5.2) et les monstres. Ticket DeepCore : vérifier les textes des objets
    2014 face au SRD 5.1 et les remplacer par le texte du SRD si besoin, avec la bonne source (protège aussi Nexus).

## Décisions du 25/11/2026 (licence des objets 2014, PR DeepCore #60)

75. **Conversion des poids : 0,5 kg la livre**, comme le SRD 5.1 français, Nexus (capacité de charge) et les objets 2024 :
    les 4 poids corrigés prennent les valeurs du SRD français (250 g, 500 g, 1 kg, 10 kg) ; un ticket à part aligne
    tous les poids 2014 (aujourd'hui mélangés 0,45 et 0,5).
76. **Torche** : compléter le texte du SRD 5.1 français par « Une torche brûle pendant 1 heure. », traduit du SRD 5.1
    anglais, avec la mention « complété d'après le SRD 5.1 anglais » (CC BY 4.0 : source citée, modification signalée).
77. **Noms des objets 2014** différents du SRD 5.1 français (36) : gardés pour l'instant (un renommage demanderait une PR
    Nexus coordonnée, des armes étant reconnues par leur nom).
78. **Armes naturelles** (6, hors SRD, sans texte) : gardées ; le risque de licence est dans les traits de race (ticket
    d'audit).

## Décisions du 25/11/2026 (audit de licence de tout le contenu de jeu, `docs/licence/registre-licence-contenu.md`)

79. **Étape 1, tout de suite** (sans impact sur les joueurs) : retirer les 157 textes anglais copiés mot pour mot des
    livres (non affichés, mais téléchargeables sans compte) ; corriger les mentions de licence (écran Crédits de Nexus,
    Bibliothèque) ; ajouter la migration manquante de `races.traits_2024` et `subraces.traits_2024` (colonnes présentes
    en production, absentes de l'historique des migrations).
80. **Étape 2** : les éléments **présents au SRD** dont le texte a été rédigé d'après un livre ou repris d'aidedd.org
    (dont 420 descriptions de sorts) reçoivent le **texte officiel du SRD français** (5.1 ou 5.2.1), **sans renommer**
    (Nexus reconnaît des éléments par leur nom), source corrigée ; une PR par type, vérifiée par `regles-dnd`.
81. **Étape 3** : le contenu **hors SRD** (1 307 éléments, dont une partie utilisée par 8 des 14 personnages) ne bouge
    pas avant l'avis d'un **conseil** ; le chef de projet prépare le dossier ; jamais de suppression d'une ligne utilisée.
82. **Le dépôt DeepCore (`Matth-Ben/markdown-editor`, renommé `Matth-Ben/deepcore` le 26/11/2026) est privé** depuis le 25/11/2026 : les 157 textes anglais retirés
    de la base (PR #61) restent dans une migration publiée et dans l'historique Git. Pas de purge d'historique. Si Florian
    doit lire les contrats d'API de DeepCore, l'ajouter comme collaborateur.
83. **Mentions de licence de Nexus** (PR #310, mergée en squash `65cad41`) : les trois textes provisoires de
    `docs/licence/spec-credits-nexus.md` §3.4 (contenu hors SRD, phrase de marque et de non-affiliation, fin du paragraphe
    de propriété intellectuelle) sont validés **tels quels** en attendant l'avis du conseil (dossier §6, questions 4 et 6).
84. **Coquille du SRD français qui change une règle** (PR DeepCore #63, Tempête de neige : « 12 m de diamètre » au lieu
    de 12 m de **rayon** dans le SRD anglais) : **corrigée** dans le texte posé, listée dans la PR (couverte par la mention
    « Modifié »). Les coquilles sans effet sur la règle restent telles quelles.
85. **Pastilles de dégâts de Nexus** (premier dé de la description) : la PR #63 s'applique **d'abord** (22 pastilles
    deviennent justes, 11 fausses), **puis** Nexus est corrigé dans sa prochaine version : liste explicite d'exceptions.
86. La pastille ne montre que **le dé de dégâts infligé à la cible au niveau minimal** (option d'attaque principale) :
    rien pour un bonus (d4 d'Assistance…), une réserve de points de vie (Sommeil), une durée, un nombre, un pourcentage
    ou des dégâts subis par le lanceur.
87. **Données de jeu des sorts fausses en production** (13 règles fausses et 8 libellés incomplets relevés par
    `regles-dnd` sur la PR #63) : PR DeepCore de correction juste après la #63, en suivant le **SRD 5.1** (Soins et
    Guérison de groupe en évocation), mile = **1,5 km** comme le SRD français. L'affichage des déclencheurs des 4 sorts de
    réaction fait l'objet d'un ticket à part.
88. **Pastille de dégâts : ajouts** : les 7 sorts qui infligent des dégâts sans motif `NdM` dans leur texte reçoivent une
    pastille (Dragon illusoire 7d6, Force fantasmagorique 1d6, Fouet d'épines 1d6, Fureur de la nature 4d6, Gardien de la
    nature 1d6, Murmures dissonants 3d6, Trique noueuse 1d8). Spec : `docs/spec-pastille-degats-sorts.md`.
89. **Pastille de dégâts : sorts utilitaires** : pas de pastille quand l'option offensive est secondaire (Contrôle de
    l'eau, Modification d'apparence, Songe, Quête). Choix du chef de projet dans le cadre de la décision 86 :
    Agrandissement/Rapetissement sans pastille (bonus), premier dé gardé pour les sorts à deux dés, rien d'ajouté pour les
    dégâts conditionnels (Ossements de la Terre, Transmutation de la pierre), exception de « Fausse vie » étendue à
    « Simulacre de vie ».
90. **Ébauches dans la Bibliothèque** (pages de propositions de contenu, lues avec le compte connecté) : les ébauches
    restent proposables, avec un badge « Fiche incomplète », pour qu'un joueur puisse proposer d'en compléter la fiche
    (25/11/2026, après la PR DeepCore #66 qui les masque aux visiteurs sans compte).
91. **Butin de groupe : fiche d'un objet** (26/11/2026, demande de Matthias : « les items dans Butin de groupe, il faut
    pouvoir cliquer dessus pour voir la description, modifier l'item et l'attribuer ») : toucher un objet du butin ouvre sa
    fiche (description et détails), avec Modifier, Attribuer et Retirer du butin (avec confirmation). **Tout membre** du
    groupe peut modifier ou retirer, comme pour ajouter et attribuer. **Tous les champs** d'un objet personnalisé de la fiche
    sont modifiables (nom, description, quantité, détails d'arme et d'armure) ; ces détails suivent l'objet quand il est
    attribué à un personnage. **L'ajout et la modification** d'un objet du butin reprennent **le même système que l'inventaire**
    (Matthias : « je ne comprend pas pourquoi les 2 sont différents ») : mêmes écrans et même formulaire, seule la
    destination change.
92. **Butin : protection contre les versions mélangées** (26/11/2026) : une écriture du butin par Nexus 1.0.9 effacerait
    les nouveaux champs (identifiant `entry_id`, description, détails) de **tous** les objets. Garde-fou **DeepCore**
    (la base refuse une écriture de `group_treasure.items` qui retirerait `entry_id` à des objets qui en ont déjà un ;
    une v1.0.9 reçoit une erreur au lieu d'effacer), appliqué **avant** la publication de la v1.0.10, **plus mise à jour
    forcée** (`app_versions.min_supported_version` = 1.0.10 à la publication). Choix du chef de projet : le butin affiche
    toujours ses 5 tuiles de monnaie (sinon impossible d'y ajouter du platine ou de l'électrum).

Choix du chef de projet (24/11, PR DeepCore #58) : noms anglais des 6 armes naturelles gardés (simples noms, hors SRD) ;
coquille du SRD français (Méphite vaporeux) gardée par fidélité à la source ; initiative d'un monstre 2014 = modificateur
de Dextérité.

Choix par défaut du chef de projet (24/11, PR DeepCore #56) : édition 2014 pour les 86 objets de base et les 6 armes
naturelles ; noms anglais des 92 objets qui n'en ont pas ajoutés avec la PR de contenu (l'affichage anglais de Nexus
s'en trouve corrigé).

Précision du chef de projet (23/11, PR Grimoire #12) : « rien n'est montré avant le début réel » porte sur le
**contenu** du combat (participants, ordre) ; l'**annonce** (`combat_start`) et la demande d'initiative, sans aucun
participant, partent dès « Préparer » pour que les joueurs puissent envoyer leur initiative. La notification
`combat_start` ne part qu'aux joueurs absents (contrat DeepCore). Exigences pour la partie Nexus : « À toi de jouer »
seulement sur un message `turn` (jamais sur `state` ou `order`) ; règle d'expiration d'un combat dont Nexus ne reçoit
plus rien (Grimoire n'est pas abonné hors combat).

Choix par défaut du chef de projet (23/11, recommandations de `regles-dnd`) : égalités comme dans Nexus (PJ avant PNJ,
puis ordre d'arrivée, le MJ réordonne) ; « touche/rate » indicatif, confirmé par le MJ (la CA de Nexus ne compte ni
Bouclier ni abri) ; lecture des dégâts acceptant `7 (2d6+3)`, « plus » et « et », refusant « ou » ; modificateur de DEX
affiché à côté d'une initiative à 0.

Choix technique du chef de projet (23/11) : la langue des notifications est lue dans `user_metadata.locale` (déjà lu
par DeepCore) ; Nexus l'écrit à la connexion et au changement de langue (partie Nexus de l'étape 7) ; à défaut, français.

**Abandonné** par rapport aux propositions de `05`/`09` : tables `adventure_*`, bucket d'images d'histoire,
`generate_group_from_story`, `groups.adventure_id`, `game_events`, `combat_npc_state`, `add_monsters`, `revealed`,
export des catalogues autres que les objets et les monstres, utilisation des RPC de combat par l'outil. (Le 17/11, le
bestiaire revient dans DeepCore, réservé aux licences : point 29.)
