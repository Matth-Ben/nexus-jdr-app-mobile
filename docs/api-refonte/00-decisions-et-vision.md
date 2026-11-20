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

**Abandonné** par rapport aux propositions de `05`/`09` : tables `adventure_*`, bucket d'images d'histoire,
`generate_group_from_story`, `groups.adventure_id`, `game_events`, `combat_npc_state`, `add_monsters`, `revealed`,
export des catalogues autres que les objets et les monstres, utilisation des RPC de combat par l'outil. (Le 17/11, le
bestiaire revient dans DeepCore, réservé aux licences : point 29.)
