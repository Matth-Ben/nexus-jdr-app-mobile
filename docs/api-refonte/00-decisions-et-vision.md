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
