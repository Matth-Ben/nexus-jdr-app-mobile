# Passation de session — reprise sur un autre ordinateur

État au 07/10/2026, fin de session sur le premier ordinateur. Ce fichier sert à
reprendre le travail avec Claude Code sur une autre machine. Il vit sur la branche
`docs/passation`, à part, pour ne polluer aucune PR. Le mettre à jour (et le repousser)
à chaque changement d'ordinateur.

Lire d'abord `CLAUDE.md` à la racine : conventions, pipeline de sous-agents, registre
de dette. Ce fichier ne le répète pas, il ajoute ce qui n'est écrit nulle part ailleurs.

## Où on en est

Chantier en cours, demandé par Matthias : « Fait tous les points de la partie B dans
l'ordre » — la partie B de `docs/dette-technique.md` (« fait perdre des données ou donne
une règle fausse au joueur »), points 6 à 11.

| Point | Entrée | Sujet | État |
|---|---|---|---|
| 6 | D03, D38 | Classes à sorts connus lancent sans préparer | Fusionné (PR #81) |
| 7 | D08 | Sorts innés sans emplacement, une fois par repos long | Fusionné (PR #82 ; base : dépôt web PR #19, migrations appliquées) |
| 8 | D09 | L'édition d'un personnage supprimait ses sorts innés | **En cours** : développé et poussé, QA et revue à faire |
| 9 | D10 | Import XML : sorts tous « connus », doublons | À faire |
| 10 | D05 | Montée de niveau, création et repos non atomiques | À faire (fonctions Postgres, dépôt web) |
| 11 | D33, D34, D35 | Suites du hors ligne | À faire |

### Point 8, détail

- Branche `fix/edit-keeps-innate-spells`, commit `69a3154`, poussée. Elle part de la
  branche de la PR #82, fusionnée depuis dans `main` par un commit de fusion : faire
  `git merge origin/main` avant d'ouvrir la PR si GitHub signale un écart.
- `dev-flutter` a reproduit le défaut par des tests écrits avant le correctif (5 échecs),
  puis corrigé. Format et analyse propres, suite complète `+3686: All tests passed!`.
- Ce qui change : `CharacterEditSnapshot.classSpells` (toutes les lignes sauf `'inné'`) ;
  planificateur et hydrateur ne lisent plus que celles-là ; le `DELETE` de
  `character_edit_repository.dart` porte `.neq('status', 'inné')`.
- **Reste à faire** : `qa-testeur` (critères et mutations ci-dessous), `code-reviewer`,
  mise à jour du registre (D09 corrigé, nouveaux constats), PR avec `gh`.
- Points à faire vérifier par QA :
  - changer de classe, de sous-classe, ou ne rien changer : les lignes `'inné'` restent,
    `innate_uses_spent` compris ;
  - un sort en double (inné + ordinaire) désélectionné côté classe : seule la ligne
    ordinaire part ;
  - un sort inné n'est plus pré-coché à l'étape Sorts et ne consomme plus le quota ;
  - mutation non faite par `dev-flutter` : retirer le filtre `.neq('status', 'inné')` et
    constater l'échec des tests du dépôt ;
  - aucun test de widget ne couvre l'étape Sorts en édition avec un sort inné.
- **Décision à remonter à Matthias** (ne pas trancher seul) : cocher côté classe un sort
  déjà inné insère maintenant une ligne ordinaire à côté de la ligne innée. Pour un sort
  inné de niveau 1 ou plus, la ligne ordinaire l'emporte à la lecture et masque le lancer
  gratuit (voir D43). Avant, rien n'était écrit.
- Constats à inscrire au registre, sans les corriger :
  - changer de race en édition est possible, mais les sorts innés de l'ancienne race
    restent, ceux de la nouvelle n'arrivent pas, et `characters.lineage_id` n'est ni lu
    ni écrit (décision produit : verrouiller la race en édition ou gérer l'échange) ;
  - l'hydrateur tronque en silence (`take(quota)`) les sorts au-delà du quota ;
  - `save` de l'édition non transactionnel : un échec entre suppression et insertion
    laisse le personnage sans sorts de classe (à rattacher à D05) ;
  - index unique partiel sur `(character_id, spell_id)` par nature de ligne à étudier
    côté base (à rattacher à D10 et D42) ;
  - D40 confirmé : `source_class_id` nul à l'insertion en édition sans changement de
    classe.

### Points 9 à 11, repères

- **Point 9 (D10)** : `xml_import_save_data_resolver.dart` — statut dérivé de la classe
  au lieu de « connu » partout, dédoublonnage. L'import crée toujours un nouveau
  personnage. Une contrainte unique éventuelle est une migration du dépôt web.
- **Point 10 (D05)** : fonctions Postgres `apply_level_up`, `create_character`,
  `apply_rest` par `dev-backend-supabase`, PR sur le dépôt web, application par Matthias,
  puis branchement mobile. À savoir : la récupération des dés de vie au repos long est
  relative, donc un repos rejoué les compte deux fois.
- **Point 11** : D33 (envois simultanés dans le désordre : verrou par personnage et par
  type entre le synchroniseur et le dépôt), D34 (écriture refusée indéfiniment : nouvelle
  tentative), D35 (repos ou montée de niveau avec des PV en file d'attente).

## Règles de travail convenues avec Matthias

Elles étaient dans la mémoire locale de Claude sur le premier ordinateur, qui ne voyage
pas. Les réenregistrer en mémoire sur la nouvelle machine.

- **Pipeline obligatoire** (06/10) : tout code et tout test passent par `dev-flutter` ou
  `dev-backend-supabase`, puis `qa-testeur`, puis `code-reviewer` ; `direction-artistique`
  avant et après pour une UI. La conversation principale est chef de projet : elle
  n'écrit que la config et la doc. Cette demande vaut autorisation de lancer ces
  sous-agents sans redemander.
- **Un seul agent à la fois** (06/10) : « l'ordinateur à du mal à gérer les 2 en même
  temps donc fait l'un après l'autre ». Dans chaque consigne : une seule commande
  `flutter`/`dart`/`gradle` à la fois, tests par fichier avec `--concurrency=1`, un seul
  passage de la suite complète (elle dure environ 15 minutes), pas de build, pas de
  `test_integration/` (base réelle requise). La règle venait de la machine (15 Go de
  RAM) : demander à Matthias si elle vaut aussi sur le second ordinateur.
- **PR** (07/10) : les créer avec `gh pr create --base main`, titre Conventional Commits,
  description en français (pourquoi, ce qui change, vérifications chiffrées, non vérifié,
  à tester, limites), terminée par la ligne d'attribution Claude Code. Ne jamais
  fusionner : Matthias fusionne lui-même. Un commit par PR autant que possible.
- **Dette** (07/10) : ne plus corriger au fil de l'eau. Un défaut hors périmètre se note
  dans `docs/dette-technique.md`, classé A / B / C, sans demander « je l'ajoute ? ».
  Exceptions à traiter tout de suite : perte de données, faille de sécurité, défaut causé
  par le changement en cours. En fin de chantier : une feuille de route « fait / reste à
  faire », pas une liste de questions.
- **Portrait uniquement** (06/10), iPhone, iPad et Android : ni specs, ni tests, ni code
  de repli pour le paysage.
- **Outils à jour** : garder Flutter et Dart récents (Flutter 3.47.1 sur le premier
  ordinateur) ; vérifier `flutter --version` sur le second avant de travailler.
- Répondre en français. Matthias n'est pas toujours devant l'écran : enchaîner les étapes
  sans attendre, et résumer en clair.

## Base de données : ce qu'il ne faut pas faire

- Projet Supabase `nexus-jdr`, référence `beazvozraxvcbymbxumb`, **partagé par dev,
  staging et prod**, avec des données réelles de testeurs.
- Claude n'applique jamais une migration et n'écrit jamais dans la base : ni
  `supabase db push`, ni outil MCP `apply_migration`, ni via un sous-agent. Si
  l'environnement refuse une commande, ne pas contourner le refus.
- Lecture seule tolérée, sur la structure (colonnes, contraintes, politiques, droits) et
  des comptages agrégés ; ne pas lire les données des joueurs. Ne jamais afficher de
  secret ni d'URL de connexion.
- Procédure d'une migration : la préparer dans un worktree du dépôt web avec
  `dev-backend-supabase`, la faire relire, la lire soi-même, `db push --dry-run`, ouvrir
  la PR, puis donner à Matthias la commande à lancer lui-même
  (`node_modules/.bin/supabase db push --linked`), et contrôler ensuite en lecture seule.
- Piège du projet : les privilèges par défaut accordent `EXECUTE` à `anon` et
  `authenticated` ; un `revoke … from public` seul ne suffit pas sur une fonction
  `SECURITY DEFINER`.

Faits vérifiés en base : aucune contrainte unique sur `character_spells
(character_id, spell_id)` ; aucun déclencheur sur les tables personnage ; écriture de
`character_spells` réservée au propriétaire (`owns_character(character_id)`) ; aucune
paire (personnage, sort) à la fois innée et ordinaire à ce jour.

## Ce qui ne voyage pas par Git

À remettre en place sur la nouvelle machine :

1. **`docs/cahier-des-charges/`** : ignoré par Git. Le recopier depuis le projet
   claude.ai « Nexus JDR - App mobile » ou depuis le premier ordinateur. Sans lui, les
   agents ne peuvent pas consulter la spec. La copie du premier ordinateur n'a pas de
   section pour l'onglet Sorts dans `09-maquettes-captures.md`.
2. **Dépôt web des migrations** : `git@github.com:Matth-Ben/markdown-editor.git` (sur le
   premier ordinateur : `~/Projets/Perso/markdown-editor`). Nécessaire pour le point 10.
   `npm install` pour avoir `node_modules/.bin/supabase`, puis lier le projet.
3. **`gh`** : l'installer et lancer `gh auth login` (compte `Matth-Ben`). Vérifier avec
   `gh auth status`.
4. **Configuration de l'app** : `config/dev.json`, `config/staging.json`,
   `config/prod.json` et `.env.local`, ignorés par Git (ils portent les clés). À recopier
   depuis le premier ordinateur par un canal sûr, jamais par Git ni dans une
   conversation. Sans eux l'app ne se lance pas ; les tests unitaires et de widgets,
   eux, tournent.
5. **Accès Supabase en lecture** (plugin MCP Supabase de Claude Code) : à reconnecter si
   Claude doit contrôler la structure de la base.
6. **Mémoire de Claude et contexte des sous-agents** : perdus. Ce fichier les remplace.

Suivis par Git, donc déjà là après un `git pull` : `.claude/agents/` (les six
sous-agents), `CLAUDE.md`, `docs/dette-technique.md`.

Particularités du premier ordinateur, à ne pas supposer ailleurs : un proxy `rtk`
réécrit les commandes (utiliser `rtk proxy <commande>` pour une sortie brute) ; un hook
« GateGuard » demande d'énoncer des faits avant le premier Bash et avant la première
modification de chaque fichier ; `g` est un alias zsh.

## Jamais vérifié

- Rien n'a jamais été essayé sur un appareil, ni Android ni iOS.
- Les tests d'intégration (`test_integration/`) et les tests pgTAP du dépôt web n'ont
  jamais été exécutés.
- Demandes en suspens côté Matthias : ouvrir un lien de partage et une fiche de membre
  de groupe pour confirmer le correctif de sécurité de `build_character_sheet_json` ;
  tester à la main les six étapes de la PR #82.

## Décisions en attente

La liste complète est dans `docs/dette-technique.md`, section « Décisions en attente ».
S'y ajoutent, depuis le point 8 : le sort déjà inné coché côté classe, et le changement
de race en édition.
