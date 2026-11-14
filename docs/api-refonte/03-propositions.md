# 03 - Propositions : architecture cible, contrat d'API, temps reel, modele unifie, migration

Date : 14/11/2026. Document de **proposition** : rien n'est decide, rien n'est applique. Les identifiants `Xnn/Snn/Pnn...` renvoient a `02-diagnostic.md`, les `Qnn` a `04-questions.md`. Tout ce qui touche l'app de Florian est marque **(a valider avec Florian)**.

## 0. Principes directeurs

1. **Additif d'abord** : aucun renommage, aucune suppression avant que les deux apps aient migre ; l'app mobile publiee continue d'ecrire dans `public.*` sous la RLS actuelle.
2. **Les droits vivent dans la base**, pas dans les clients. Un droit d'ecriture croise (MJ -> fiche) n'est **jamais** une policy `UPDATE` elargie : c'est une RPC `security definer` qui borne les colonnes, valide la regle et journalise.
3. **Un contrat = un nom stable + des erreurs stables + des tests.** Le contrat est versionne (`api_v1`) ; une rupture cree `api_v2`, jamais une modification de `api_v1`.
4. **Le modele de donnees est decouple du contrat** : les clients parlent a des « ressources » (`table`, `character`, `combat`...). Le stockage derriere peut evoluer (ex. groupe/histoire) sans casser les clients.
5. **Evolutivite des contenus** : tables de reference plutot que enums figes pour ce qui change (sources, editions, conditions, effets, recompenses) ; colonnes `edition` et `source_code` partout ou le contenu existe en 2014 et 2024.

---

## 1. Options d'architecture

### Option A - Schema dedie `api_v1` : vues + RPC (recommandee, en version « hybride »)

Un schema `api_v1` expose a PostgREST (`config.toml` `[api] schemas` local ; « Exposed schemas » dans le tableau de bord pour la production, **action manuelle de Matthias**). Il contient : des **vues `security_invoker`** pour les lectures simples (les RLS de `public` continuent de s'appliquer), des **RPC `security definer`** pour toutes les ecritures et les lectures composees (fiche complete), et un **catalogue d'erreurs**. Les tables restent dans `public`.

- Avantages : un seul point d'entree documente ; versionnage naturel (`api_v2` a cote) ; masquage de colonnes (S04) ; les ecritures croisees passent par du code teste ; compatible supabase-js/supabase_flutter (`.schema('api_v1')`) ; migration progressive par ressource.
- Inconvenients : duplication de surface (vues + RPC) ; `postgres_changes` **ne fonctionne pas sur des vues** (le temps reel passe donc par des tables `public` ou par Broadcast, voir section 5) ; deux apps a faire evoluer ; Realtime `postgres_changes` reste lie aux noms de tables `public` tant qu'il est utilise.
- Cout : M a L en base (reparti en 6 phases, section 8).

### Option B - RPC metier uniquement (aucune vue, aucune lecture directe)

Toutes les lectures et ecritures passent par des fonctions (`api_v1.get_character(id)`, `api_v1.list_tables()`...) qui renvoient `jsonb`/`setof`. Les tables sont retirees de PostgREST a terme (REVOKE).

- Avantages : controle total des droits et de la forme des reponses ; moins de surface RLS ; mise en cache d'une reponse = une fonction ; ideal pour la fiche (26 requetes -> 1).
- Inconvenients : perte du filtrage/tri/embedding PostgREST (chaque besoin = une fonction ou un parametre) ; reponses `jsonb` non typees (types Dart/TS a la main) ; plus de code SQL a maintenir et a tester ; plans d'execution moins lisibles ; effort L.

### Option C - PostgREST direct renforce (statu quo durci)

On garde les tables comme API : index (P01), policies reecrites (P02), GRANT par colonnes (S04), triggers de version/audit, et on ajoute des RPC seulement pour les actions MJ.

- Avantages : effort le plus faible (S a M) ; aucune bascule des clients ; coherent avec l'existant ; Realtime `postgres_changes` natif.
- Inconvenients : l'API *est* le schema : toute evolution de table est une rupture pour deux apps (dont une publiee dans les stores) ; pas de versionnage ; la RLS ne limite pas les colonnes (S02, S04) ; ne resout ni X03 (deux modeles) ni le N+1 ; les droits MJ elargis seraient disperses dans des dizaines de policies.

### Tableau comparatif

| Critere | A (api_v1 hybride) | B (RPC seules) | C (direct renforce) |
|---|---|---|---|
| Evolutivite du contrat | Bonne (versions) | Tres bonne | Faible |
| Securite colonnes/roles | Bonne | Tres bonne | Moyenne |
| Effort base | M-L | L | S-M |
| Effort clients | M (par ressource) | L | S |
| Performance (N+1) | Bonne (fiche en RPC) | Tres bonne | Moyenne |
| Realtime | Broadcast + postgres_changes transitoire | Broadcast | postgres_changes |
| Typage / outillage | Bon (vues typees) | Faible (jsonb) | Bon |
| Risque pour l'app publiee | Faible | Faible | Tres faible |

### Recommandation

**Option A, en version hybride** :
- **ecritures = RPC** (toutes celles qui traversent un role : actions MJ, tresor, groupes, creation/repos/niveau) ;
- **lectures simples = vues `security_invoker`** (listes, catalogues de reference aplatis fr/en) ;
- **lecture lourde = une RPC** (`api_v1.get_character_sheet`) ;
- **temps reel = Broadcast depuis la base** sur des topics de « table de jeu », avec `postgres_changes` conserve tel quel pour les builds mobiles deja publies.

Elle est la seule des trois qui permet d'avancer **sans reprendre ce qui est deja refait** : chaque ressource migre independamment, les tables n'ont pas a bouger, et `api_v2` reste possible. L'option C est le **plancher obligatoire** (Phase 0 : index, RLS performantes, CHECK) car elle corrige sans rien rompre ; elle n'est pas un but en soi.

Ce qui rend le modele evolutif (par choix) : schema versionne ; ressources abstraites (`table` de jeu) decouplees du stockage ; `edition` + `source_code` + table `sources` ; table `character_effects` / `character_grants` ouvertes (type en table de reference `effect_kinds`, `grant_kinds`) ; journal `character_events` generique (`kind`, `payload jsonb`, `schema_version`) ; `rev` pour la synchro ; colonnes d'audit uniformes.

---

## 2. Contrat d'API preliminaire (`api_v1`)

### 2.1 Conventions

- **Schema** `api_v1`. Noms de fonctions `snake_case`, verbe + ressource (`start_combat`, `gm_apply_damage`). Parametres `p_*`. Vues au pluriel (`api_v1.characters`).
- **Identifiants** : uuid (utilisateur), int stable (reference).
- **Erreurs stables** (modele : migration combat `20261114091000`) : `message` = code machine ; SQLSTATE = classe. Mapping PostgREST -> HTTP **[D, a valider par test]** :

| message | SQLSTATE | HTTP | Sens |
|---|---|---|---|
| `not_authenticated` | 28000 | 401 | pas de session |
| `forbidden` | 42501 | 403 | role insuffisant (membre non MJ, etc.) |
| `not_found` | P0002 | 404 | inconnu **ou** non visible (reponse uniforme, pas de fuite d'existence) |
| `invalid_argument` (+ `hint` = nom du champ) | 22023 | 400 | parametre invalide |
| `business_rule` (+ `detail` = code metier : `combat_already_active`...) | P0001 | 400 | regle de jeu/gestion |
| `rev_conflict` | PT409 | 409 | `p_expected_rev` ne correspond plus |
| `duplicate_request` | 23505 / retour idempotent | 200 | meme `p_request_id` deja traite : renvoie le resultat memorise |
| `rate_limited` | PT429 | 429 | trop d'actions MJ par minute |

  Le catalogue complet vivra dans `docs/api-v1-erreurs.md` (meme texte dans les deux depots).
- **Idempotence** : toute RPC d'ecriture accepte `p_request_id uuid default null` ; table `api_v1_requests(actor uuid, request_id uuid, result jsonb, created_at)` unique `(actor, request_id)` ; purge a 7 jours. Obligatoire pour la file hors ligne du mobile.
- **Concurrence** : ressources versionnees (`characters.rev`) ; ecritures absolues avec `p_expected_rev` ; ecritures **delta** (`apply_hp_delta`) sans rev (commutatives).
- **Pagination** : keyset `(sort_key, id)` : parametres `p_limit` (defaut 50, max 200) et `p_after jsonb`; reponse `{items, next}` pour les RPC ; `Range` PostgREST pour les vues (`max_rows` = 1000 reste le plafond serveur).
- **Reponses** : les RPC renvoient la ligne ou le jsonb **apres** modification (le client n'a pas a re-fetch).
- **Versionnage** : une fonction ou vue publiee ne change jamais de signature ; ajout de parametres a defaut seulement ; deprecation annoncee par `comment on` + entree dans `docs/api-v1-changelog.md` ; `api_v2` si rupture.

### 2.2 Ressources et operations

Legende roles : **P** proprietaire du personnage ; **MJ** MJ de la table de jeu (proprietaire du groupe, ou de l'histoire pendant la transition) ; **M** membre du groupe ; **L** lecteur public avec jeton ; **A** admin ; **-** interdit. « Aujourd'hui » = comportement RLS actuel.

| Ressource | Operation | Forme | P | MJ | M | L | Aujourd'hui |
|---|---|---|---|---|---|---|---|
| **personnage** | lire la fiche complete | `api_v1.get_character_sheet(id)` (RPC) | oui | oui (champs MJ, voir Q5) | partiel (vue `character_public`) | via `get_shared_character` | P : 26 requetes ; M : RPC `get_group_member_character` |
| | lister mes personnages | vue `api_v1.my_characters` | oui | - | - | - | `select characters` |
| | creer | `api_v1.create_character(...)` | oui | - | - | - | RPC `create_character` existe, **non appelee** |
| | modifier la fiche (champs libres) | `api_v1.update_character(id, patch jsonb, p_expected_rev)` | oui | - | - | - | `update` direct |
| | PV / PV temp (delta) | `api_v1.apply_hp_delta(id, delta, kind)` | oui | oui (journalise) | - | - | `update` direct (P seulement) |
| | repos | `api_v1.apply_rest(...)` | oui | - | - | - | RPC existe, non appelee |
| | montee de niveau | `api_v1.apply_level_up(...)` | oui | - (peut **accorder**, voir recompenses) | - | - | RPC existe, non appelee |
| | partage (jeton) | `regenerate_share_token`, `revoke_share_token` | oui | - | - | lecture | `regenerate_character_share_token` |
| **inventaire** | lire / ajouter / retirer / equiper | vue `api_v1.character_inventory` + RPC `inventory_add/remove/equip` | oui | `inventory_grant` (objet donne par le MJ, journalise) | lecture (vue publique) | partiel | CRUD direct P |
| **sorts / emplacements** | lire, preparer, lancer (consommer emplacement) | RPC `spell_prepare`, `spell_cast`, `slots_set` | oui | `slots_restore` (journalise) | - | partiel | CRUD direct P |
| **table de jeu** (groupe+histoire, section 6) | lister mes tables | vue `api_v1.my_tables` | oui | oui | oui | - | `groups` + `stories` + `character_campaigns` (deux modeles) |
| | creer / renommer / dissoudre | RPC `create_table`, `rename_table`, `dissolve_table` | - | oui | - | - | edge `create-group` + `update/delete` direct |
| | inviter / rejoindre / quitter / retirer | RPC `table_invite_code`, `join_table(code, p_character_id)`, `leave_table`, `remove_member` | oui (join/leave) | oui | - | - | edges `join-group`, `join-story` |
| | membres | vue `api_v1.table_members` | oui | oui | oui | - | `group_members` |
| | tresor | RPC `treasure_deposit`, `treasure_claim` ; lecture vue | claim | oui | claim | - | `group_treasure` UPDATE ouvert (S02) |
| | notes personnelles / journal | vues + RPC `note_set`, `journal_add` | auteur | auteur | auteur | - | CRUD direct |
| **combat** | lancer / terminer / PNJ / initiative / ordre | RPC existantes (`start_combat`... **alias** `api_v1.*`) | initiative propre | oui | lecture | - | RPC `public.*` (PR #47) |
| | tour suivant (V2) | `api_v1.advance_turn(combat)` | - | oui | lecture | - | absent |
| | degats a un joueur | `api_v1.gm_apply_damage(character, amount, type, request_id)` | notification | oui | lecture | - | **inexistant (X01)** |
| **effets / conditions** | appliquer / lever | `api_v1.gm_apply_effect`, `effect_remove` | retire les siens (selon regle) | oui | lecture | - | `characters.conditions` jsonb |
| **recompenses** | accorder XP / objet / or / niveau | `api_v1.gm_grant(character, kind, payload)` -> `character_grants` | accepter / refuser | oui | - | - | inexistant (X05) |
| **journal d'actions** | lire | vue `api_v1.character_events` | ses evenements | ceux de sa table | partiel (publics) | - | inexistant (X02) |
| **histoire** (contenu MJ) | lire titre/couverture | vue `api_v1.stories_joined` (colonnes minimales) | oui | CRUD (web) | oui | - | **S01** : ligne complete |
| **reference D&D** | lister / chercher | vues `api_v1.spells`, `items`, `classes`, ... (fr/en aplati, `edition`, `source`) | oui | oui | oui | oui | tables + `translations` EAV |
| **evenements temps reel** | s'abonner | topics Broadcast `table:{id}` | oui | oui | oui | - | postgres_changes |
| **notifications / profil / signalement** | inchange en v1 | edges existantes (aliasees plus tard) | oui | oui | oui | - | idem |

### 2.3 Regle de droit « MJ » (a implementer une fois, reutilisee partout)

`api_v1.is_character_gm(p_character_id uuid) returns boolean` (`stable`, `security definer`, `set search_path = public, pg_temp`) :
vrai si l'appelant est `groups.owner_id` d'un groupe dont un membre porte ce personnage, **ou** (transition) `stories.user_id` d'une histoire liee par `character_campaigns`. Lecture unique de `auth.uid()` dans `(select auth.uid())`. Toute RPC `gm_*` commence par cette verification puis par un `select ... for update` de la ligne personnage (verrou court), applique, ecrit `character_events`, incremente `rev`.

---

## 3. Optimisations a integrer des la Phase 0 (invisibles pour les apps)

| Action | Detail | Ecart |
|---|---|---|
| Index (sans `CONCURRENTLY`, car le CLI execute chaque migration dans une transaction ; tables peu volumineuses [I]) | `characters(owner_id)` ; `character_classes(character_id)` ; `character_inventory(character_id)` ; `character_journal_entries(character_id, created_at desc)` ; `character_photos(character_id)` ; `character_level_hp(character_id)` ; `character_race_choices(character_id)` ; `character_tool_proficiencies(character_id)` ; `character_class_options(character_id)` ; `character_ability_increases(character_id)` ; `character_campaigns(story_id)` ; `group_members(user_id)` ; `group_journal_entries(group_id, created_at desc)` ; `groups(owner_id)` ; `stories(user_id)` ; `codex_entries(user_id)` ; `combat_participants(character_id)`, `(user_id)` ; `spell_classes(class_id)` ; `bug_reports(reporter_id)` | P01 |
| Policies | `alter policy ... using ((select auth.uid()) = owner_id)` sur les 44 policies concernees (changement sans effet fonctionnel, a prouver par les tests existants) ; `stable parallel safe` sur les helpers | P02 |
| CHECK `not valid` puis `validate` | `characters` (PV, XP, monnaies >= 0), `group_treasure` | I02, I03 |
| Droits | `revoke ... from public, anon` sur les fonctions sans usage anonyme ; `pg_temp` ; GRANT par colonnes pour masquer `share_token` | S06-S08 |
| `set_updated_at()` | trigger generique sur les 7 tables a `updated_at` | N04 |
| `comment on` | toutes les tables/vues/fonctions de l'API | K01 |

Mesure : `EXPLAIN (ANALYZE, BUFFERS)` avant/apres sur un jeu synthetique (1 000 personnages, 200 groupes, 5 000 lignes d'inventaire) **dans une base jetable**, jamais en production.

---

## 4. Journal d'actions, versions et resolution des conflits

### 4.1 Nouvelles structures (toutes additives)

| Objet | Colonnes essentielles | Role |
|---|---|---|
| `characters.rev bigint not null default 0` | incrementee par trigger `before update` si une colonne « metier » change | detection de conflit, synchro incrementale |
| `character_events` (append-only) | id uuid, character_id, actor_id, actor_role (`player|gm|system`), kind (FK `event_kinds`), payload jsonb, schema_version, request_id, rev_after, created_at | journal/audit ; source du temps reel ; table de l'historique visible au joueur |
| `character_effects` | id, character_id, kind (FK `effect_kinds`), source_actor, starts_at, expires_round/at, payload, status | conditions/effets (remplace a terme `characters.conditions`) |
| `character_grants` | id, character_id, kind (`xp|gold|item|level_up|custom`), payload, status (`pending|accepted|declined|expired`), granted_by, created_at, resolved_at | recompenses en attente d'acceptation (X05) |
| `event_kinds`, `effect_kinds`, `grant_kinds` | code PK, labels fr/en, schema | tables de reference extensibles (aucun enum fige) |
| `api_v1_requests` | voir 2.1 | idempotence |

### 4.2 Droits d'ecriture croises (proposition)

- Le **proprietaire** garde tout (compat). Le **MJ** n'obtient **aucune** policy d'ecriture : uniquement des RPC `gm_*` bornees (PV delta, effets, recompenses, objets donnes, restauration d'emplacements), chacune journalisee avec `actor_role = 'gm'`.
- Le joueur **voit** chaque action MJ dans son journal (`character_events`) et peut etre notifie (push existant + broadcast).
- Les actions qui exigent des choix du joueur (niveau, sorts) passent par `character_grants` : le MJ accorde, le joueur accepte et execute `apply_level_up`. **Decision produit Q8.**
- Les regles de jeu (concentration, resistances, PV temporaires, mort) restent a valider par `regles-dnd` avant toute RPC de degats ; aucune regle RAW n'est tranchee ici.

### 4.3 Conflits avec la file hors ligne du mobile

Aujourd'hui : derniere ecriture gagnante, avec lecture prealable de la valeur serveur pour PV/XP (`pending_character_write_syncer.dart:392-447, 512-517`), et ecritures absolues.

Cible, par type d'operation :

| Type | Strategie | Exemples |
|---|---|---|
| Commutative | **delta** serveur, `request_id` idempotent, jamais d'ecrasement | PV +/- , XP +, emplacement utilise, charge de capacite |
| Valeur absolue de champ libre | `p_expected_rev` ; en cas de `rev_conflict` : l'alerte de synchro existante (D34) propose « garder ma version / prendre celle du serveur » | nom, notes, apparence |
| Etat modifiable par les deux | evenement MJ **prioritaire** et journalise ; le joueur voit l'ecart apres sync (« le MJ a applique 7 degats pendant que tu etais hors ligne ») | PV, conditions |

A la reconnexion : mobile appelle `api_v1.changes_since(character_id, rev)` (liste d'evenements) puis rejoue sa file ; pas de re-fetch complet.

---

## 5. Design temps reel

### 5.1 Choix technique

| Mecanisme | Usage propose | Pourquoi |
|---|---|---|
| **Broadcast depuis la base** (`realtime.broadcast_changes` / `realtime.send` dans un trigger ; canaux **prives** ; policy sur `realtime.messages`) | **Principal** : un topic par table de jeu `table:{group_id}` ; evenements `character.changed`, `combat.changed`, `member.joined/left`, `effect.applied`, `grant.created` | Pas de lecture RLS par ligne et par abonne (cout de `postgres_changes`), payload minimal controle (pas de ligne `characters` complete), DELETE sans souci de REPLICA IDENTITY |
| `postgres_changes` | **Transitoire** : conserve pour les versions mobiles publiees (`characters`, `group_members`, `combats`, `combat_participants`) | Compatibilite stricte |
| **Presence** | optionnelle, sur `table:{id}` seulement : « MJ en ligne », liste des joueurs connectes | Faible cout, pas persiste ; a limiter aux ecrans de table ouverts |
| Polling / pull-to-refresh | reste le repli hors ligne | |

**A verifier avant implementation** (non visible depuis les depots) : version du serveur Realtime du projet, disponibilite de `realtime.broadcast_changes` et des canaux prives, quotas du plan (messages/s, connexions simultanees). Voir Q-SQL-6.

### 5.2 Evenements (payloads minimaux)

| Evenement | Declencheur | Payload | Destinataires |
|---|---|---|---|
| `character.changed` | trigger sur `characters`/enfants **via** `character_events` | `{character_id, rev, fields:[...], actor_role}` (pas de valeurs sensibles ; le client fait `get_character_sheet` ou applique le delta) | membres + MJ de la table |
| `combat.changed` | RPC combat | `{combat_id, round, current_participant_id, rev}` | membres + MJ |
| `member.joined` / `member.left` | `group_members` | `{user_id, character_id}` | membres + MJ |
| `effect.applied` / `effect.expired` | RPC `gm_apply_effect` | `{character_id, kind, until}` | cible + MJ |
| `grant.created` | RPC `gm_grant` | `{grant_id, kind}` | proprietaire du personnage |

Autorisation des canaux : policy `realtime.messages` : lecture autorisee si `is_group_member(topic_group_id) or is_group_owner(...)` ; `(select auth.uid())` partout.

### 5.3 Ce que chaque application doit faire

| | Mobile | Web (Florian) - **a valider avec Florian** |
|---|---|---|
| Souscrire | `channel('table:{id}', private)` a l'ouverture de l'ecran Groupe ; se desabonner a la sortie ; ne plus faire de re-fetch complet : appliquer le delta ou relire `get_character_sheet` | `supabase.channel('table:{id}', {config:{private:true}})` dans le panneau « Joueurs » et la vue de session |
| Reconnexion | a `SUBSCRIBED` apres coupure : `changes_since(rev)` puis rejouer la file | idem (Next.js client component) |
| Hors ligne | lecture seule + file des ecritures **commutatives** (inchange) | non concerne (MJ en ligne) |
| Filtres | aucun filtre `in(...)` (limite 100) : un seul topic par table | idem |

### 5.4 Cout et volumetrie (estimation, a mesurer)

Un groupe de 6 joueurs + MJ = 7 abonnes ; une rafale de combat ~ 1 evenement/s/table. `postgres_changes` : 7 evaluations RLS par evenement et par table publiee ; Broadcast : 1 diffusion sans RLS par ligne. Le gain se mesure au plus pres avec le nombre de tables de jeu simultanees (inconnu [I] : Q-SQL-2).

---

## 6. Modele unifie Histoire / Groupe

### Etat actuel [C]
Histoire : `stories.user_id` (MJ), `character_campaigns(character_id, story_id, role joueur|pnj)`, code `stories.invite_code`, edge `join-story`. Groupe : `groups.owner_id`, `group_members(user_id, character_id nullable, role, is_game_master)`, code `groups.invite_code`, edge `join-group`. Le combat est porte par le groupe. `groups.campaign_id` existe (FK vers `stories`, `on delete set null`) mais n'est ni ecrit ni lu.

### Options

| Option | Principe | Pour | Contre |
|---|---|---|---|
| **U1 - Groupe = table de jeu ; l'histoire s'y rattache** (`groups.campaign_id`) | Source de verite des membres = `group_members` ; `character_campaigns` devient une projection maintenue par triggers (puis vue) ; MJ = `groups.owner_id` ; `stories.user_id` doit egaler `owner_id` du groupe rattache | `campaign_id` deja en base ; combat deja au groupe ; zero rupture pour l'app publiee | une histoire sans groupe reste possible (cas web actuel) ; contraintes de cardinalite a decider |
| U2 - Histoire = table de jeu ; groupe en vue | Inverse | Colle au vocabulaire du web | Casse le combat (PR #47), l'app mobile publiee, les edges ; non recommande |
| U3 - Nouveau concept `game_tables` | `groups` et `stories` deviennent des extensions 1-1 | Modele le plus propre | Big bang a risque, migration de donnees lourde ; a garder comme **cible de l'API** (ressource `table`) sans le materialiser |

### Recommandation : **U1 + facade `table` dans l'API**

1. `api_v1.my_tables` / `table_members` presentent un concept unique « table de jeu » (groupe + histoire optionnelle). Les clients codent contre `table`, pas contre `groups`/`stories`.
2. **Cardinalite** par defaut : plusieurs groupes peuvent pointer vers une histoire (FK many-to-one deja la) ; une histoire n'a qu'**un groupe actif** (index unique partiel `groups(campaign_id) where status = 'active'`, a decider : Q3).
3. **Adhesion unifiee** : `join_table(code)` accepte les deux types de codes pendant la transition ; rejoindre par code d'histoire cree/rejoint le groupe lie (creation paresseuse via `api_v1.story_ensure_table(story_id)` **appelable depuis le web : (a valider avec Florian)**).
4. **Synchronisation transitoire** par triggers : `group_members` <-> `character_campaigns` (ajout/retrait), en un seul sens a la fois pour eviter les boucles (colonne `source` d'origine) ; invariants verifies par une requete de controle (Q-SQL-10).
5. **Points durs a trancher** (Q3, Q4) : (a) `character_campaigns` autorise plusieurs personnages par utilisateur et par histoire, `group_members` un seul (`unique(group_id, user_id)`) ; (b) `role = 'pnj'` (personnages du MJ) n'a pas d'equivalent dans `group_members` ; (c) MJ avec personnage (autorise dans le web) vs « MJ sans personnage » du mobile.
6. **Fin de vie** : quand les deux apps lisent `api_v1`, `character_campaigns` devient une vue de compatibilite, puis est retiree (Phase 6).

---

## 7. Comment doivent fonctionner les deux applications ensemble

### 7.1 Proprietaire de chaque donnee

| Donnee | Proprietaire | Ecritures croisees autorisees |
|---|---|---|
| Fiche (identite, caracteristiques, sorts connus, inventaire, journal prive) | **Joueur** | Aucune directe ; le MJ passe par `gm_*` |
| Etat de jeu (PV, PV temp, conditions/effets, emplacements restaures, XP, or) | **Joueur** (valeur courante), **MJ** peut agir par delta journalise | `gm_apply_damage/healing/effect`, `gm_grant` |
| Combat (ordre, round, PNJ, tours) | **MJ** | Joueur : sa propre initiative |
| Tresor du groupe | **Groupe** | depot : MJ/membres selon decision ; retrait : proprietaire de ligne |
| Histoire, codex, bestiaire, cartes | **MJ (web)** | aucune |
| Membres / roles / invitation | **MJ** | membre : quitter ; joueur : choisir son personnage |
| Reference D&D | **Admin** | propositions (a decider, M02) |

### 7.2 Parcours cibles

| # | Parcours | Appels | Resultat cote joueur |
|---|---|---|---|
| 1 | MJ web lance un combat | `api_v1.start_combat(table)` -> broadcast `combat.changed` | bandeau « Combat en cours » (deja existant en mobile) |
| 2 | MJ applique des degats | `gm_apply_damage(character, amount, type, request_id)` -> `character_events` + `rev++` -> broadcast `character.changed` | PV mis a jour, ligne de journal « Le MJ t'inflige 7 degats (tranchant) » ; si hors ligne : visible a la reconnexion (`changes_since`) |
| 3 | MJ accorde une montee de niveau | `gm_grant(kind='level_up')` -> `grant.created` | Carte « Montee de niveau disponible » ; le joueur fait ses choix et appelle `apply_level_up` (RAW : `regles-dnd`) |
| 4 | MJ accorde recompense (XP, or, objet) | `gm_grant(kind=...)` | acceptation en un geste, ou application automatique pour XP/or selon Q8 |
| 5 | MJ applique un effet (poison, benediction, 3 rounds) | `gm_apply_effect` (+ expiration par round de combat) | badge d'etat sur la fiche ; retrait automatique en fin de combat selon la regle validee |
| 6 | Joueur lance son initiative | `set_my_initiative` (existant) | MJ voit l'ordre en direct (web) |
| 7 | Joueur rejoint depuis le web (lien) | `join_table(code)` | meme table visible dans les deux apps |

### 7.3 Compatibilite des versions

L'app mobile publiee **ignore** tout cela : elle continue sur `public.*`. Les nouveautes ne lui sont visibles que si elle lit `characters` via `postgres_changes` (PV mis a jour par `gm_*` : l'ancienne app affichera le changement sans journal). `app_versions.min_supported_version` (deja en base) sert de levier pour couper l'ancien acces direct en Phase 6.

---

## 8. Strategie de compatibilite et de migration progressive

Ordre d'application : une migration par phase, timestamps posterieurs a `20261114091000`, chacune avec son retour arriere en commentaire et son test pgTAP. Matthias applique (`db push --remote --dry-run` d'abord, cible `nexus-jdr (beazvozraxvcbymbxumb) · production`, jamais « Keystone »).

| Phase | Contenu | Objets nouveaux | Objets deprecies | Impact mobile | Impact web | Effort | Retour arriere |
|---|---|---|---|---|---|---|---|
| **0 Hygiene** | index, policies initplan, CHECK, REVOKE/pg_temp, trigger `updated_at`, `comment on` | index, triggers | - | aucun | aucun | S-M | `drop index`, `alter policy` inverse |
| **1 Squelette `api_v1`** | schema, catalogue d'erreurs, vues de lecture (reference, `my_characters`, `stories_joined`), alias des 7 RPC combat + `create_character/apply_rest/apply_level_up`, `api_v1_requests` | schema, ~25 vues/RPC | - | aucun (additif) | aucun | M | `drop schema api_v1 cascade` |
| **2 Journal, versions, droits MJ** | `characters.rev`, `character_events`, `character_effects`, `character_grants`, `gm_*`, `is_character_gm`, tables de reference des kinds | 6 tables, ~8 RPC | - | aucun | aucun | L | `drop` des objets (rien ne les reference) |
| **3 Temps reel Broadcast** | triggers `broadcast_changes`, policy `realtime.messages`, `changes_since` | triggers, policy | - (postgres_changes conserve) | aucun | aucun | M | `drop trigger`, `drop policy` |
| **4 Modele unifie** | `table_members`, `story_ensure_table`, `join_table`, triggers de projection `group_members <-> character_campaigns` | vues, RPC, triggers | `groups.campaign_id` (devient utilise), `character_campaigns` (projection) | aucun | optionnel | L | desactiver les triggers ; donnees : requete de controle |
| **5a Bascule mobile** | `create_character`/`apply_rest`/`apply_level_up` puis `get_character_sheet`, puis souscription Broadcast, puis lecture des evenements | - | ecritures directes `character_*` (dette D05) | **oui** : M-L (dev-flutter ; classe `character_repository.dart` de ~9 000 lignes a decouper) | - | L | reversion de la version de l'app (la base reste compatible) |
| **5b Bascule web** (**a valider avec Florian**) | lecture `api_v1.table_members`/`get_character_sheet`, actions MJ, abonnement Broadcast, retrait de l'ecriture client de `updated_at` | - | acces directs `character_campaigns`, `stories select *` | - | **oui** : M-L | M-L | PR revertable |
| **6 Nettoyage** | `revoke` DML direct sur `character_*` a `authenticated`, retrait policy S01, `character_campaigns` -> vue, retrait `postgres_changes` | - | tout ce qui est liste | requiert `min_supported_version` releve | requiert 5b fait | M | restaurer les GRANT (script prepare en Phase 0) |

Periode de **double lecture** : de la Phase 1 a la Phase 6, une meme donnee est lisible par l'ancien chemin (table `public`) et le nouveau (vue/RPC) ; test de non-regression : requete de comparaison des deux chemins (Q-SQL-11).

Estimation globale : base **L (environ 4 a 6 semaines de travail dev-backend-supabase avec revues)**, mobile **L**, web **M** ; non planifie ici (priorisation = Matthias).

---

## 9. Plan de tests

Harnais existant : `supabase/tests/*.sql` (pgTAP, 14 fichiers dont 3 en echec connu, D60) ; tests d'integration mobile `test_integration/` (workflow quotidien, D18).

1. **Reparer d'abord** les 3 tests pgTAP en echec (D60) : on ne bati pas une API sur un harnais rouge.
2. **Un fichier pgTAP par ressource**, avec une **matrice roles x operations** : roles = `anon`, proprietaire, MJ, membre non MJ, membre d'un autre groupe, MJ d'un autre groupe, admin, service. Chaque cellule du tableau 2.2 devient une assertion `lives_ok` / `throws_ok(message, SQLSTATE)`. Tests negatifs obligatoires : un MJ ne peut pas `update` directement `characters` ; un membre ne lit pas `stories.content` ; un joueur ne se credite pas d'or.
3. **Erreurs stables** : une assertion par code du catalogue.
4. **Idempotence** : meme `request_id` deux fois -> un seul evenement, meme resultat. **Concurrence** : deux sessions (`dblink` ou `pg_sleep` + deux transactions) sur `gm_apply_damage` et `apply_hp_delta` : la somme est exacte, `rev` strictement croissant.
5. **Non-regression des policies reecrites** (Phase 0) : rejouer l'integralite des tests existants avant/apres + une requete `pg_policies` comparant les lignes visibles par role sur un jeu synthetique.
6. **Compatibilite** : test d'integration qui rejoue les appels de l'ancien mobile (`public.*`) apres chaque phase.
7. **Performance** : script jetable (generation 1 000 personnages, 200 groupes) + `EXPLAIN (ANALYZE, BUFFERS)` des 10 requetes les plus frequentes (liste, fiche, groupe, combat) avant/apres Phase 0 ; seuils : aucun Seq Scan sur les tables utilisateur.
8. **Temps reel** : test d'integration de bout en bout (deux clients : MJ et joueur) mesurant la latence d'un `gm_apply_damage` jusqu'au broadcast ; test de coupure/reconnexion (`changes_since`).
9. **Revue croisee** : `code-reviewer` sur chaque PR ; `regles-dnd` sur toute RPC de regle (degats, effets, niveau) ; `qa-testeur` sur la matrice d'acces ; `rgpd` sur S09/S13/journal d'actions (donnees personnelles dans `character_events`).
10. **Zero donnee de production** dans les tests : jeux synthetiques uniquement.

---

## 10. Points de vigilance

- Realtime sur vue : impossible ; ne pas promettre de temps reel sur `api_v1.*` vues.
- `create index concurrently` incompatible avec l'execution transactionnelle des migrations du CLI.
- Les `security definer` publiees dans `api_v1` doivent toutes : `set search_path = public, pg_temp`, `revoke all ... from public, anon`, `grant execute ... to authenticated`, verifier `auth.uid()`.
- La suppression de compte (edge `delete-account`) devra gerer `character_events.actor_id` (anonymisation plutot que cascade) : sujet `rgpd`.
- Aucune des propositions ne modifie les regles D&D ; toute formule d'effet est une question pour `regles-dnd`.
