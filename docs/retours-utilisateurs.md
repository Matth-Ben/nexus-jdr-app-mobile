# Registre de retours utilisateurs (simulation joueur/MJ)

Registre alimenté par le sous-agent `simulation-utilisateur`
(`.claude/agents/simulation-utilisateur.md`), qui joue le rôle d'un joueur ou
d'un MJ utilisant réellement l'app — parcours sur émulateur via
`integration_test/` quand c'est possible, complétés par une analyse de code
— pour juger la pertinence/complétude des fonctionnalités et proposer des
axes d'amélioration. Créé le 05/11/2026, avant toute première campagne.

## Comment lire ce registre

**Catégories.**

- **Bug/friction réel** : quelque chose casse ou gêne concrètement un usage
  courant. Part directement en correctif (`dev-flutter`/`dev-backend-supabase`
  puis `code-reviewer`) — pas de revue croisée nécessaire, même circuit que
  `docs/dette-technique.md`.
- **Fonctionnalité manquante**, **Fonctionnalité existante jugée non
  pertinente**, **Donnée manquante** : ce sont des *propositions*, pas des
  décisions. Elles passent par le **comité de revue** (voir `CLAUDE.md`,
  section « Simulation utilisateur... ») avant toute décision de Matthias :
  le chef de projet consulte les sous-agents pertinents
  (`direction-artistique`, `regles-dnd`, `dev-flutter`/`dev-backend-supabase`,
  `qa-testeur`) pour un avis de faisabilité/pertinence, consigné ici à côté
  de la proposition.

**Preuve.** **R** = exécuté réellement sur émulateur (`integration_test/`,
commande citée, résultat observé) ; **L** = analyse de code/doc, pas exécuté
en conditions réelles.

**État.** *Ouvert* (signalé, pas encore discuté) ; *En revue* (comité
consulté, avis en cours de collecte) ; *Décidé — retenu* (Matthias a validé,
reste à planifier dans une phase de roadmap) ; *Décidé — écarté* (Matthias a
tranché non, avec la raison) ; *Corrigé* (avec la PR, pour un bug/friction).

**Mise à jour.** Même règle que `docs/dette-technique.md` : quand une entrée
est traitée ou tranchée, on met à jour sa colonne État en citant la PR ou la
décision, on ne supprime jamais une ligne. Une nouvelle campagne ajoute ses
entrées à la suite, avec sa date.

## Rôle joueur

*(aucune campagne exécutée encore)*

## Rôle MJ

### Campagne du 05-06/11/2026 — MJ sans personnage, solo (PR #222)

Scénario réel `integration_test/gm_group_management_solo_test.dart` : créer un
groupe comme "MJ — sans personnage", onglets Membres/Butin/Notes, code
d'invitation, butin commun, renommer, régénérer le code, dissoudre. A
d'abord révélé 2 bugs backend bloquants (D167/D168, `docs/dette-technique.md`)
— corrigés (retard de déploiement des edge functions, pas un bug de code) —
puis exécuté avec succès de bout en bout.

| ID | Titre | Catégorie | Preuve | Constat | État |
|---|---|---|---|---|---|
| F01 | Le sélecteur de rôle à la création de groupe ne signale pas qu'on peut rejoindre sans personnage | Bug/friction réel | L | `group_create_screen.dart::_RoleSelectorTile`, placeholder neutre "Choisir un personnage ou un rôle" — rien n'indique avant ouverture de la sheet qu'un MJ sans fiche peut créer un groupe. Un MJ pressé pourrait abandonner à cette étape. | **Corrigé (PR #223)** — texte d'aide ajouté sur `group_create_screen.dart`/`group_join_screen.dart`, validé par `direction-artistique`/`qa-testeur`/`code-reviewer`. |
| F02 | L'onglet "Notes" est entièrement inutilisable pour un MJ sans personnage | Fonctionnalité existante jugée non pertinente | **R** (confirmé en conditions réelles le 06/11/2026) | `group_screen.dart::_buildNotesTab` : `group_notes` est indexé par `character_id`, donc jamais applicable à un MJ volontaire. Message affiché : « Le carnet de notes est propre à un personnage : en tant que MJ sans personnage, tu n'en as pas ici. » Un MJ qui anime une table sans avoir lui-même de fiche — cas très courant — ne peut tenir AUCUNE note de séance via l'app. | **Décidé — retenu (volet a uniquement, 06/11/2026)**. Migration web déployée (`20261106090000`). Implémentation mobile en cours de revue (branche `feat/groups-notes-gm-without-character`), inclut le correctif d'un trou RGPD trouvé au passage par `qa-testeur` (export "Mes données" amputait la note d'un MJ sans personnage, `data_export_repository.dart::_groupSummaryToJson`, commit `f31a615` sur cette même branche — corrigé immédiatement, défaut exposé par ce changement, pas tracé en dette). |
| F03 | Aucune vue d'ensemble pour un MJ qui anime plusieurs tables/groupes | Fonctionnalité manquante | L | `group_list_screen.dart` permet déjà de créer/rejoindre plusieurs groupes librement, mais chaque groupe s'ouvre séparément — aucun écran n'agrège les PV/statuts de plusieurs groupes à la fois. Absent de `11-fonctionnalites-a-ajouter.md`/`12-partage-et-groupes.md`. Friction réelle de préparation de séance pour un MJ multi-tables. | **Décidé — retenu, approche vue SQL (06/11/2026)**. Migration web déployée (`20261106100000`, vue `group_character_status_overview`, `security_invoker = true`). Implémentation mobile (extension `GroupSummary` + badge sur `group_list_screen.dart`) pas encore commencée. |

**Nettoyage de données en attente** : 5 groupes de test orphelins
(`QA-Sim-Groupe-*`) créés pendant cette campagne restent en base (table
`groups`, sans membre) — à supprimer par `dev-backend-supabase`, voir
`docs/dette-technique.md` (note sous D167/D168).

**Scénario à deux comptes désormais débloqué** : le second compte de test
("joueur") est câblé dans `integration_test/support/qa_test_account.dart`
(PR #224, mergée) — le parcours d'invitation réelle MJ↔joueur peut être
écrit dans une prochaine campagne.

## Propositions de fonctionnalité (comité de revue)

### F02 — Carnet de notes accessible à un MJ sans personnage

**État : En revue — avis collectés le 06/11/2026, décision en attente de Matthias.**

La proposition contient en réalité deux idées distinctes, à ne pas traiter comme une seule :
- **(a) carnet personnel du MJ sans personnage** (symétrie directe avec le carnet déjà offert aux joueurs/MJ avec personnage) ;
- **(b) notes partagées entre tous les membres du groupe** (nouvelle sémantique de visibilité, à instruire séparément si retenue).

**direction-artistique** : favorable pour (a) — réutilise `GroupNotesTabBody` à l'identique, aucun nouveau composant. Favorable avec réserve pour (b) — nécessiterait un bandeau de visibilité explicite (pattern `InfoBanner` déjà utilisé ailleurs dans Groupes) pour qu'aucun joueur ne confonde carnet privé et partagé.

**dev-backend-supabase** : (a) faisable simplement — `group_notes` a une PK `(group_id, character_id)` redondante avec `(group_id, user_id)` depuis que `group_members` garantit `unique(group_id, user_id)` ; changer la PK vers `(group_id, user_id)`, rendre `character_id` nullable informatif, backfill trivial, RLS déjà basée sur `user_id` (peu de changement). (b) serait une table séparée distincte, effort modéré, hors périmètre de ce verdict. A trouvé au passage un bug latent **D170** (`docs/dette-technique.md`) : FK `character_id` en `on delete cascade` perd silencieusement une note si le joueur supprime son personnage — à corriger avec ou indépendamment de F02.

**qa-testeur** : effort de test modéré, risque résiduel modéré si un cas précis n'est pas couvert explicitement : un membre **orphelin réassigné** (personnage supprimé puis remplacé via `set-group-character`) peut déjà avoir une note sous l'ancien `character_id` — la migration de PK doit traiter ce cas explicitement (fusion/écrasement/conflit), sans quoi c'est le principal risque de perte de données silencieuse de cette fonctionnalité. Demande aussi confirmation explicite que la policy RLS de `group_notes` sera bien réécrite en `user_id = auth.uid()` direct (pas seulement "le personnage appartient à l'appelant"), sans quoi l'upsert du MJ échouerait silencieusement par RLS même avec un code client correct. Le mode hors-ligne absent (déjà assumé pour tout le module Groupes) n'est pas un défaut propre à F02, mais mérite une entrée explicite dans `docs/dette-technique.md` comme choix produit assumé plutôt que de rester seulement en commentaire de code.

### F03 — Vue d'ensemble multi-groupes pour un MJ

**État : En revue — avis collectés le 06/11/2026, décision en attente de Matthias.**

**direction-artistique** : favorable avec réserve. Cantonner l'indicateur à `group_list_screen.dart` (déjà le point d'entrée "mes groupes"), pas à l'écran d'accueil (objet mental différent). Un seul badge compact priorisé (ex. "1 mort" prioritaire sur "PV bas") plutôt qu'un résumé chiffré multiple, en réutilisant le pattern `_StatusBadge` déjà existant — pas de nouveau composant à inventer pour ça. Point bloquant en amont du design : `GroupSummary` ne porte aujourd'hui que `memberCount`, pas de données de PV par membre — nécessite d'étendre la requête `fetchMyGroups` avant toute spec visuelle détaillée.

**dev-backend-supabase** : faisable avec effort modéré. Le schéma suffit déjà (PV sur `characters`, RLS déjà scopée par groupe). Recommande une vue/fonction SQL d'agrégation plutôt qu'une agrégation côté client. Garde-fou impératif : `security_invoker = true` sur la vue, sinon elle s'exécute avec les droits de son propriétaire et un MJ pourrait voir les groupes d'un autre MJ — risque de fuite de données, pas une question de perf.

**qa-testeur** : effort de test **élevé**, risque résiduel **élevé** si mergé sans garde-fous. Trois points durs :
1. **RLS** : ce dépôt mobile ne contient aucune migration ni stack Supabase local — un vrai test RLS négatif (MJ non-membre ne voit rien) ne peut vivre que dans la suite du dépôt web, OU côté client à deux vrais comptes — **dépendance bloquante explicite sur le wiring du second compte de test, actuellement non fait** (voir "Scénario encore bloqué" ci-dessus).
2. **Performance** : contredit le cadrage initial "agrégation client d'abord, bascule SQL plus tard" — la lecture du code montre que `fetchGroupDetail` (l'outil naturel pour calculer un badge par groupe) coûte déjà ~6 aller-retours réseau par groupe (jointures profondes + 4 requêtes `translations`). Un N+1 visible apparaîtrait dès 2-3 groupes, pas à partir d'un seuil élevé — recommande la vue/fonction SQL dès la v1, pas une option de repli.
3. **Fraîcheur** : pas de Realtime multi-groupes à bas coût (le mécanisme Realtime existant est scopé à un seul groupe à la fois) — il faut au moins définir un déclencheur de rafraîchissement minimal (invalidation au retour de navigation) avant de pouvoir écrire un test de non-régression stable.

## Décisions de Matthias (06/11/2026)

Matthias a validé l'ensemble des propositions ("je suis d'accord avec tout ce
que tu proposes, tu peux lancer le dev") :

1. **F02** : volet (a) carnet personnel du MJ sans personnage retenu. Le
   volet (b) notes partagées entre joueurs reste hors périmètre pour
   l'instant — à instruire séparément si besoin plus tard, pas dans ce lot.
2. **F02 connexe — D170** : corrigé dans la même migration que F02(a)
   (`20261106090000`, FK `character_id` passée en `on delete set null`).
3. **F03** : retenu avec l'approche "vue SQL" dès la v1 (pas d'agrégation
   côté client), conformément à la convergence qa-testeur/dev-backend-supabase.
4. **F01** : traité directement, sans attendre — voir tableau ci-dessus.
