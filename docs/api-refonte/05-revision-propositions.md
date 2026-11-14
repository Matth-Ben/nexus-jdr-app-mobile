# 05 - Révision des propositions à la lumière de la vision produit

Date : 14/11/2026. Étape 2, lecture seule : rien n'est décidé, rien n'est appliqué, aucun dépôt modifié. Ce document **complète** `03-propositions.md` et le **remplace là où il le contredit**. Références : `00-decisions-et-vision.md` (vision de Matthias, 14/11/2026), `01`..`04` (étape 1), `06-questions-revisees.md` (décisions), `07-parcours-et-exemples.md` (parcours).

Fiabilité : **[C]** certain (lu dans le code/les migrations), **[D]** déduit, **[I]** incertain (dépend de la production ou de l'outil de Florian). Tout ce qui concerne le futur outil de Florian est **à valider avec Florian** : je propose ce qu'il *consomme*, jamais comment il se construit.

Fichiers lus pour cette étape (en plus de l'étape 1) : `00-decisions-et-vision.md` ; `01`, `03`, `04` (relus), `02` (grep ciblé) ; `H:/Projets/Labo/markdown-editor/supabase/migrations/20261114091000_group_combat_rpcs.sql` (l.20-220) ; `.../20260930160000_create_creatures.sql` ; `.../20261110090000_add_characters_conditions.sql` ; `.../functions/create-group/index.ts` (l.1-70) ; `.../functions/_shared/group-invite.ts` (code 8 caractères, alphabet de 31) ; `lib/features/characters/data/pending_character_write_syncer.dart` (l.385-525).

---

## 1. Ce qui change dans mes recommandations

| # | Étape 1 (03/04) | Révision | Raison |
|---|---|---|---|
| R1 | L'app web est un consommateur à préserver (phases 5b, F1-F8, `stories_joined`, trigger `updated_at` côté client…) | **Supprimé.** Le seul client à préserver est le **mobile publié**. Le client neuf (Florian) consomme `api_v1` directement | `markdown-editor` gelé |
| R2 | Modèle unifié U1 + façade `table` (groupe+histoire), synchronisation `group_members` <-> `character_campaigns` par triggers, `join_table` à deux codes, `story_ensure_table` | **Abandonné.** Deux ressources distinctes reliées : `story` et `group`, `group.story_id` nullable. **Aucune synchronisation avec `character_campaigns`** (gelée). Q3/Q4 de l'étape 1 sont dissoutes : PNJ du MJ = entrées de l'histoire, pas des membres ; « plusieurs personnages par joueur » = hors modèle (un membre = un personnage actif, contrainte existante `unique(group_id,user_id)` [C]) | Vision : l'histoire est conçue pour l'outil neuf, pas héritée de `stories` |
| R3 | Droit MJ : propriétaire de groupe **ou** (transition) propriétaire d'histoire via `character_campaigns` (`is_character_gm`) | **Un seul chemin** : MJ = `groups.owner_id` du groupe, et pour toute écriture sur une fiche : groupe **lié** à une histoire, appartenance active du personnage au groupe, consentement (voir 3.1). Plus aucune lecture/écriture via `story_owner_can_read_character` | Vision : droits d'écriture MJ sur groupe lié seulement |
| R4 | Journal `character_events` par personnage | **Flux unique `game_events` par groupe** (source du temps réel, de la reprise après coupure et de l'audit). L'historique d'un personnage = filtre sur `character_id` | Un MJ agit sur un groupe ; un seul curseur de reprise (`seq`) |
| R5 | Temps réel : « optionnel pour le web » | **Cœur du produit** : Broadcast privé par groupe et par histoire, présence, reprise par `seq` (section 5) | Immersion MJ/joueurs |
| R6 | Référence : vues de lecture « pour le mobile » | **Catalogues = API publique pour un client TypeScript neuf** : clés stables (`slug`), éditions/sources normalisées, recherche, pagination, versions de contenu (section 4). Devient un prérequis de la phase 1 (le client de Florian stockera des références) | Client externe qui référence des créatures/objets/sorts dans ses histoires |
| R7 | Erreurs génériques `forbidden`/`not_found`… (03 §2.1) | **Garder les codes précis existants** (modèle de la migration combat : `not_group_owner` 42501, `combat_not_found` P0002, `combat_already_active` P0001…) ; le client route par **SQLSTATE** (classe) puis affiche par `message` (code machine). Le tableau générique de 03 devient la table de **classes** SQLSTATE -> HTTP | Compatibilité avec les 7 RPC déjà publiées et utilisées par le mobile [C] |
| R8 | Q15 (projet de test séparé) : « Oui pour les phases 2+ » | **Bloquante avant que Florian écrive un seul appel** : un développeur tiers qui teste sur le projet unique `nexus-jdr` (production) crée des données de test et peut déclencher des RLS/limites en prod | Dev/staging/prod partagent le même projet (D06 [C]) |
| R9 | `character_campaigns`/`stories`/`codex_entries` migrés ou unifiés | **Coexistence gelée, puis archivage plus tard** (3.8). Aucun objet legacy modifié | Décision d'architecture n°3 |
| R10 | Migrations « un seul historique dans le dépôt web » | **Question nouvelle** : ce dépôt est gelé. Où vit l'historique pendant et après la refonte ? (06, B1) | Contradiction entre la règle de mission et le gel |
| R11 | Phases 4/5b/6 liées au web | Remplacées par le plan de la section 7 | |

Inchangé : option A (schéma `api_v1`, vues `security_invoker` + RPC `security definer`), phase 0 d'hygiène (index, RLS initplan, CHECK, REVOKE, `pg_temp`), idempotence par `p_request_id`, pagination keyset, `rev` pour les écritures absolues, aucune policy `UPDATE` élargie pour le MJ.

---

## 2. Modèle cible révisé

### 2.1 Tables nouvelles (toutes additives ; noms proposés)

Nom physique : `stories` existe (legacy gelée) -> tables nouvelles en `adventure_*`, **ressource d'API nommée `story`** (`api_v1.stories`). Nommage : question B4.

| Table | Colonnes essentielles | Notes |
|---|---|---|
| `adventures` | id uuid, `owner_id` -> auth.users (**restrict**, pas cascade : voir 2.6), title, summary_public, cover_path, edition (`2014|2024`), status (`active|archived`), settings jsonb, rev, created_at, updated_at, `legacy_story_id` uuid null unique | `legacy_story_id` : pont futur vers `stories` (rempli seulement par la migration d'archivage) |
| `adventure_members` | adventure_id, user_id, role (`co_gm`), invited_by, created_at | Réservé aux co-MJ ; **non livré en v1** (2.6) |
| `adventure_entries` | id, adventure_id, kind (FK `story_entry_kinds`), title, summary_public, body_public, parent_id, sort_order, `creature_slug`/`custom_creature_id` (lien statblock), attributes jsonb + `attributes_version`, rev, timestamps | **Contenu montrable au joueur uniquement** (2.2) |
| `adventure_entry_secrets` | entry_id PK, body_gm, attributes_gm jsonb | **Jamais lisible par un joueur** (RLS propriétaire/co-MJ seulement) |
| `adventure_entry_reveals` | entry_id, group_id, revealed_at, revealed_by | PK (entry_id, group_id) ; **révélation par groupe** |
| `adventure_assets` | id, adventure_id, entry_id null, storage_path, kind (`map|image|handout`), mime, size_bytes, gm_only | Bucket **privé** `adventure-assets`, URL signées courtes |
| `adventure_encounters` | id, adventure_id, name, entries jsonb `[{creature_ref, count, name, revealed}]`, notes | Rencontres préparées (parcours e) |
| `custom_creatures`, `custom_items`, (`custom_spells` plus tard) | même forme que `creatures`/`items` + id uuid, `owner_id`, `adventure_id` null (null = bibliothèque perso du MJ), `base_ref` (créature SRD dont c'est une variante) | Contenu maison du MJ, **séparé** de la référence (écriture `is_admin()` inchangée) |
| `story_entry_kinds` | code PK, labels fr/en, attributes_schema jsonb | `npc, location, faction, quest, handout, note, scene, map` ; extensible sans migration de schéma |
| `game_events` | seq bigint identity (curseur), id uuid, group_id, adventure_id null, character_id null, actor_id, actor_role (`gm|player|system`), kind (FK `event_kinds`), payload jsonb, payload_version, request_id, created_at | Append-only ; source du Broadcast, de `events_since`, de l'audit |
| `character_effects`, `character_grants` | comme 03 §4.1, + `group_id`, `granted_by`, `status` étendu (2.8) | |
| `event_kinds`, `effect_kinds`, `grant_kinds` | code PK, labels, `allow_apply` (grant_kinds), schéma de payload | Tables de référence extensibles (pas d'enum) |
| `api_v1_requests` | (actor, request_id) unique, result jsonb, created_at | Idempotence, purge 7 j |
| `profiles` (proposé) | user_id PK, display_name, avatar_path | Évite de lire `auth.users.raw_user_meta_data` (S09) ; nécessaire pour afficher « qui est connecté » dans l'outil |

Colonnes ajoutées à l'existant (additif, défauts neutres) : `groups.adventure_id uuid null` (FK `adventures` **on delete set null**, index) ; `groups.invite_enabled boolean default true` (si Matthias veut couper un code : les edge functions `join-group` devraient la lire, **à valider**, elles sont dans le dépôt gelé) ; `group_members.gm_actions_consent boolean not null default false` (3.1) ; `characters.rev bigint default 0` (03 §4.1) ; `combats.rev` ; `combat_participants.revealed boolean not null default true` + `creature_ref` (3.3).

`groups.campaign_id` (FK vers `stories`, jamais renseigné [C]) : **on ne le réutilise pas** (il pointe vers la table gelée). Il est déclaré déprécié par `comment on`, jamais écrit. Il bloquera un éventuel `drop table stories` tant qu'il existe : à traiter à l'archivage.

### 2.2 Spoilers : structure plutôt que filtrage

Constat [C] : la RLS ne limite pas les colonnes (01 §6, S01 en est l'exemple : le joueur lit la ligne `stories` entière, `content` compris). Règle de conception : **ce qui ne doit jamais être vu n'est jamais dans la même table que ce qui peut l'être**.

1. `adventure_entries` ne contient que du contenu *montrable* (`summary_public`, `body_public`). Un joueur ne lit une entrée que s'il existe une ligne `adventure_entry_reveals` pour **un de ses groupes** liés à cette histoire ; la révélation est donc **par groupe** (même histoire jouée par deux tables = deux états de révélation).
2. Les notes du MJ, secrets, statistiques cachées, vraies identités vivent dans `adventure_entry_secrets` : RLS = propriétaire (et co-MJ). Aucune policy joueur : impossible à fuiter par un `select *`.
3. Entrée non révélée : **inexistante** pour le joueur (pas de « titre grisé », pas de comptage) ; `adventures` n'est lisible par un joueur que via `api_v1.group_story_info(group_id)` (titre, `summary_public`, couverture signée).
4. Les assets suivent leur entrée ; `gm_only = true` = jamais exposé ; URL signées (60 s), jamais d'URL publique (les 4 buckets existants sont publics en lecture, S13 [C] : on ne reproduit pas ce choix).
5. Événements : `reveal_story_entry` émet `story.entry_revealed` sur `group:{id}` (payload : `entry_id`, `kind`, titre) ; rien d'autre. Les événements GM-seuls transitent sur `gm:{group_id}` / `adventure:{id}` (section 5).
6. Combat : aujourd'hui tout membre lit **tous** les participants, PNJ compris [C] (`combat_participants`, select membre). Un monstre caché serait donc visible (nom compris). `revealed boolean default true` (compat : lignes existantes visibles) + policy joueur `kind='pc' or revealed` ; les nouveaux monstres ajoutés par l'outil ont `revealed=false` par défaut. **Impact sur le mobile publié** : un PNJ non révélé disparaît de son écran ; comportement voulu mais à valider (Matthias).

Ce que fait le corps : la **forme** de `body_*` (markdown ? JSON d'éditeur riche ?) appartient à Florian. Proposition : `text` markdown, avec `body_format text default 'markdown'` pour ne rien figer. **À valider avec Florian.**

### 2.3 Cardinalités (options et recommandation)

| Option | Principe | Pour | Contre |
|---|---|---|---|
| **K1 (recommandée)** | Un groupe = 0 ou 1 histoire ; une histoire = 0..N groupes | Une même aventure jouée par deux tables (module réutilisé) ; la vision (« group.story_id nullable ») ; FK simple | Plusieurs états de révélation à gérer (déjà par groupe) |
| K2 | Une histoire = 0 ou 1 groupe (index unique partiel sur `groups(adventure_id)`) | Plus simple | Interdit de rejouer une aventure ; « Générer un groupe » deviendrait destructif si on veut recommencer |
| K3 | N:M (`group_stories`) : un groupe enchaîne plusieurs histoires | Campagnes qui enchaînent des modules | Surmodélisation aujourd'hui ; la vision ne le demande pas |

Recommandation : **K1**, avec l'API qui **masque la cardinalité** : opérations `link_group_to_story` / `unlink_group_from_story` (pas d'écriture directe de `groups.adventure_id`). Si K3 devient nécessaire, la colonne devient une table de liaison sans rupture du contrat v1. Un MJ peut avoir **plusieurs histoires** (aucune contrainte d'unicité sur `owner_id`) ; plafond de groupes par histoire : décision H5 (défaut 10, `group_limit_reached`).

Invariant : `groups.owner_id` = `adventures.owner_id` à la liaison (ou co-MJ plus tard), vérifié par trigger `before insert/update of adventure_id, owner_id on groups` (pas de FK composite : trop rigide pour le transfert). Un groupe dont le propriétaire n'est plus propriétaire de l'histoire est **délié** automatiquement par le transfert (2.6).

### 2.4 `generate_group_from_story`

```
api_v1.generate_group_from_story(
  p_story_id    uuid,
  p_name        text    default null,   -- défaut : titre de l'histoire (<= 80 car.)
  p_request_id  uuid    default null
) returns api_v1.generated_group   -- (group_id, name, invite_code, story_id, created_at)
```

Comportement (`security definer`, `set search_path = public, pg_temp`, `revoke ... from public, anon`, `grant execute ... to authenticated`) :
1. `auth.uid()` non nul (`not_authenticated` 28000). Idempotence : `(actor, p_request_id)` déjà vu -> renvoie le résultat mémorisé (aucun second groupe).
2. Verrou `select ... from adventures where id = p_story_id for no key update` : `story_not_found` P0002 si absente **ou** non visible ; `not_story_owner` 42501 si l'appelant n'est pas propriétaire ; `story_archived` P0001.
3. Plafond : `group_limit_reached` P0001.
4. `insert into groups (name, owner_id, adventure_id, invite_code)` ; le trigger existant `groups_after_insert` crée `group_treasure` [C] ; code produit par une fonction SQL `private.generate_invite_code()` **qui reprend exactement la règle de l'edge function** (8 caractères, alphabet `23456789ABCDEFGHJKMNPQRSTUVWXYZ` [C], `_shared/group-invite.ts:87-106`), avec reprise sur `unique_violation` (3 tentatives, puis `invite_code_collision` P0001).
5. `insert into group_members (group_id, user_id, role, is_game_master, character_id)` = `(…, uid, 'owner', true, null)` : **même ligne que `create-group`** pour un MJ sans personnage [C, `create-group/index.ts:43-49`], ce qui satisfait `group_has_gm()` (donc `start_combat`) et l'unicité « un seul MJ sans personnage ». Transaction unique : plus de « rollback applicatif » (la fragilité décrite dans `create-group/index.ts:50-56`).
6. `insert into game_events (kind 'group.generated')`.

Relation avec l'existant :
- **`join-group` (edge) inchangé** : les joueurs utilisent le même code sur la même table `groups` ; l'app mobile publiée fonctionne sans modification (**[D]**, je n'ai lu que `create-group` et le helper ; `join-group` et `preview-group-invite` sont à relire avant de figer : aucune ne doit vérifier un champ que la RPC ne remplit pas).
- `create-group` (mobile) continue de créer des groupes **non liés** (`adventure_id` null).
- Code d'invitation : `api_v1.rotate_group_invite_code(p_group_id)` (MJ) ; `p_enabled` via `groups.invite_enabled` (à valider, 2.1). Sans expiration en v1 (décision H6).
- Groupe existant -> histoire : `api_v1.link_group_to_story(p_group_id, p_story_id)` : propriétaire des deux ; **n'accorde aucun pouvoir sur les fiches tant que le joueur n'a pas consenti** (3.1) ; événement `group.linked` poussé aux membres.

### 2.5 Droits par rôle (résumé)

| Donnée | Propriétaire du perso (joueur) | MJ (propriétaire du groupe/de l'histoire) | Membre du groupe | Public |
|---|---|---|---|---|
| Fiche | CRUD (inchangé) | lecture de la **vue MJ** (3.1 / Q5) ; écriture **uniquement** par RPC `gm_*` | lecture partielle (existant) | jeton `get_shared_character` |
| Histoire, entrées, secrets | - | CRUD | entrées **révélées** à son groupe seulement ; titre/résumé public | - |
| Combat | sa propre initiative | tout (RPC) | lecture (monstres cachés exclus) | - |
| Groupe, code | quitter | tout | lecture | - |
| Catalogues de référence | lecture | lecture ; contenu maison CRUD | lecture | lecture (inchangé : SRD) |

### 2.6 Propriété, suppression, co-MJ, comptes

- **Transfert** : `api_v1.transfer_story(p_story_id, p_new_owner uuid)` en **deux temps** (proposition puis `accept_story_transfer`), car le nouveau propriétaire reçoit les secrets. Les groupes liés dont le MJ changerait : option `p_with_groups boolean` (le nouveau MJ doit être membre du groupe) ; sinon les groupes sont **déliés** (ils survivent, `adventure_id` null, aucun droit `gm_*` ne subsiste). Transfert d'un **groupe** seul : `transfer_group(p_group_id, p_new_owner)` (nouveau propriétaire = membre) ; si le groupe était lié, délié sauf co-MJ. Réponse à Q9 : à confirmer par Matthias.
- **Suppression d'une histoire liée** : `delete_story` refuse (`story_has_groups` P0001) tant que des groupes y sont liés, sauf `p_unlink => true` : les groupes **survivent** (délier d'abord), les révélations de cette histoire sont supprimées en cascade. Filet : FK `on delete set null` (jamais de suppression en cascade d'un groupe). Archiver (`status='archived'`) est l'opération par défaut.
- **Suppression de compte du MJ** : aujourd'hui `groups.owner_id on delete cascade` dissout le groupe de tous [C, S11]. Cible : `delete-account` (edge, dépôt gelé) doit d'abord transférer ou archiver ; `adventures.owner_id` en `restrict` pour qu'une suppression de compte **échoue bruyamment** plutôt que d'effacer des histoires. Impact sur l'edge `delete-account` : **à planifier** (Matthias ; le code est dans le dépôt gelé).
- **Co-MJ** : hors v1. `adventure_members` est réservé ; le point d'extension est **une seule fonction** `api_v1.is_group_gm(group_id)` (propriétaire du groupe, ou co-MJ de l'histoire liée) utilisée par toutes les RPC `api_v1`. Les RPC combat publiques (`public.*`, qui testent `is_group_owner`) ne changent pas ; leurs alias `api_v1` appelleront `is_group_gm` le jour venu.
- **Comptes** : même `auth.users`, **aucun rôle global**. Rôles dérivés : *MJ* = `adventures.owner_id` / `groups.owner_id` ; *membre* = ligne `group_members` ; *propriétaire* = `characters.owner_id`. Un utilisateur cumule librement. `app_admins` reste réservé à l'édition de la référence. Ce que doit faire l'outil : se connecter avec `supabase-js` (mêmes fournisseurs d'authentification que le mobile : **non vérifiés**, 06-B2), utiliser la clé publique (`anon`/publishable) + JWT utilisateur, **jamais** la clé `service_role` côté client. Redirections d'authentification/CORS de l'outil : à déclarer par Matthias dans le tableau de bord (action manuelle).

### 2.7 Éditions et sources (inchangé en esprit, durci)

`sources(code PK, name_fr, name_en, edition, kind)` ; colonne `edition` + `source_code` sur `spells`, `items`, `creatures`, `races`, `backgrounds`, `class_features`… (valeur de remplissage par migration depuis le texte libre : classification 2014/2024 à valider par `regles-dnd`). Le client filtre par `p_edition`. `creatures` : une seule source aujourd'hui (SRD 5.2) [C] -> aucun monstre 2014 ; à dire à Florian.

### 2.8 Sort de `stories`, `codex_entries`, `character_campaigns`, buckets (outil gelé)

| Étape | Contenu | Quand |
|---|---|---|
| **Coexistence** | Aucun objet legacy modifié ni lu par la nouvelle API ; pas de triggers de synchronisation. Le mobile continue `join-story`/`preview-story-invite` et l'embed titre/couverture (inchangés). Les nouveaux objets portent d'autres noms (`adventure_*`). `groups.campaign_id` : déprécié. | P1 -> migration |
| **Correctif S01 (à décider)** | La policy `character_owner_can_read_joined_story` fait lire la ligne `stories` entière (dont `content`) au joueur rattaché. Ne modifie ni donnée ni schéma, mais **change un droit d'un outil gelé** : décision Matthias (06-L1). | indépendant |
| **Migration éventuelle** | Script one-shot `stories -> adventures` (`legacy_story_id`), `codex_entries -> adventure_entries` (catégorie -> `kind`), fichiers des buckets `story-*` copiés vers `adventure-assets` ; **fresh start** possible si Florian n'a pas de données à garder (06-L2, requêtes de volumétrie fournies). | après P2 |
| **Archivage** | Révocation des écritures clientes sur `stories`/`codex_entries`/`character_campaigns`, déplacement en schéma `legacy` (ou conservation lecture seule), buckets `story-*` en lecture seule. Jamais de `drop` avant décision explicite. | P6 |

Les 160 migrations de `markdown-editor` restent l'historique de fait (R10).

---

## 3. Catalogue d'actions MJ synchronisées

### 3.1 Règles communes (toutes les RPC `gm_*`)

- **Qui** : `api_v1.is_group_gm(p_group_id)` ; **groupe lié** (`groups.adventure_id is not null`, sinon `group_not_linked` P0001) ; le personnage cible appartient à une ligne **active** de `group_members` du groupe (`character_not_in_group` P0001) ; `group_members.gm_actions_consent = true` (sinon `gm_actions_not_consented` 42501). Consentement : implicite à l'adhésion pour un groupe *généré* depuis une histoire (le joueur le voit à l'aperçu du code et peut quitter à tout moment) ; **explicite** (acceptation du joueur dans l'app) pour un groupe lié *après coup*. **Décision produit Matthias + avis `rgpd`** (06-A7).
- **Exception** : les RPC de **combat** restent ouvertes à tout propriétaire de groupe, lié ou non (comportement déjà publié [C]).
- **Verrouillage** : `select ... for update` de la ligne `characters` (court), jamais plus d'une ligne par appel.
- **Idempotence** : `p_request_id uuid default null` partout ; rejouer = même résultat, un seul événement.
- **Audit/temps réel** : chaque action écrit une ligne `game_events` (`actor_role='gm'`) ; un trigger `after insert` émet le Broadcast. Le joueur voit toujours une ligne de journal lisible (« Le MJ t'inflige 7 dégâts »).
- **Erreurs communes** : `not_authenticated` 28000, `group_not_found` P0002 (inconnu ou invisible), `not_group_gm` 42501, `group_not_linked`, `character_not_in_group`, `gm_actions_not_consented`, `invalid_argument` 22023 (+ `hint` = champ), `rev_conflict` PT409, `rate_limited` PT429 (plafond par MJ/minute, valeur à fixer).
- **Règle de jeu** : la base applique le **minimum validé par `regles-dnd`** (section 8). Elle ne calcule ni résistances ni partages d'XP : le client envoie le montant final.

### 3.2 Tableau des actions

Légende statut : **E** existe et publié [C], **N** nouveau. « Hors ligne mobile » = ce que fait le joueur si son téléphone est hors ligne au moment de l'action.

| Action | Qui | RPC (schéma `api_v1`) | Erreurs spécifiques | Événement (`game_events.kind` -> topic) | Hors ligne mobile |
|---|---|---|---|---|---|
| Lancer un combat (E) | MJ du groupe (lié ou non) | `start_combat(p_group_id, p_request_id)` -> `combats` | `group_not_found`, `not_group_owner`, `no_game_master`, `combat_already_active` [C] | `combat.started` -> `group:{id}` | voit le bandeau à la reconnexion (`events_since` ou re-lecture) |
| Terminer (E) | MJ | `end_combat(p_combat_id)` (idempotent [C]) | `combat_not_found`, `not_group_owner` | `combat.ended` | idem |
| Initiative joueur (E) | membre, sa ligne | `set_my_initiative(p_combat_id, p_initiative)` | `no_character`, `invalid_initiative`, `participant_removed`, `combat_not_active` | `combat.initiative_set` | **file existante à étendre** (écriture idempotente avec `request_id`) |
| Initiative PNJ/PJ par le MJ (E) | MJ | `set_participant_initiative` | `invalid_initiative` | idem | - |
| PNJ génériques (E) | MJ | `add_npc_participants(p_combat_id, p_base_name, p_initiative, p_count)` | `npc_limit_per_call` (>20), `npc_limit_per_combat` (>60), `invalid_name`, `invalid_count` [C] | `combat.participant_added` | - |
| **Monstres du bestiaire (N)** | MJ | `add_monsters(p_combat_id, p_monsters jsonb, p_request_id)` -> `setof combat_participants`, `p_monsters = [{creature_ref, count, name, initiative, revealed}]` ; état (PV, CA) dans table MJ-seule `combat_npc_state(participant_id, creature_ref, max_hp, current_hp, armor_class, notes)` | `creature_not_found`, mêmes plafonds | `combat.participant_added` (nom public seulement si `revealed`) ; détails sur `gm:{id}` | - |
| Retirer / réordonner (E) | MJ | `remove_participant`, `reorder_participant` | `invalid_sort_order` | `combat.order_changed` | - |
| Révéler/cacher un monstre (N) | MJ | `set_participant_revealed(p_participant_id, p_revealed)` | - | `combat.participant_revealed` | - |
| Tour suivant (N, « V2 » déjà annoncé [C]) | MJ | `advance_turn(p_combat_id, p_expected_round default null)` | `combat_not_active`, `round_conflict` PT409 | `combat.turn_advanced` {round, current_participant_id} ; déclenche l'expiration des effets « en rounds » | lecture seule |
| **Dégâts / soins / PV temp (N)** | MJ, groupe lié, consentement | `gm_apply_hp_change(p_group_id, p_character_id, p_kind 'damage'|'heal'|'temp_hp', p_amount int, p_damage_type text default null, p_note text default null, p_request_id uuid default null)` -> `(hp_before, hp_after, temp_before, temp_after, dropped_to_zero, character_rev, event_seq)` | `invalid_amount` (<=0 ou > plafond), `character_dead` (règle à valider) | `character.hp_changed` {character_id, amount, kind, damage_type, hp_after, temp_after} -> `group:{id}` | **règle de conflit 3.5** |
| **Appliquer un effet/état (N)** | MJ idem | `gm_apply_effect(p_group_id, p_character_id, p_effect_kind text, p_duration jsonb default null, p_note text default null, p_request_id uuid default null)` -> `character_effects` ; durée `{unit: 'rounds'|'end_of_combat'|'until_rest'|'manual', value}` (pas d'horloge de jeu : une durée en minutes n'expire pas seule) | `unknown_effect_kind`, `invalid_duration` | `effect.applied`, puis `effect.expired`/`effect.removed` | badge à la reconnexion |
| Lever un effet (N) | MJ ; joueur sur les siens selon la règle | `remove_effect(p_effect_id, p_request_id)` | `effect_not_found` | `effect.removed` | - |
| **Accorder une récompense (N)** | MJ idem | `gm_grant(p_group_id, p_character_id, p_kind text, p_payload jsonb, p_mode text default 'grant', p_note text default null, p_request_id uuid default null)` -> `character_grants` ; `p_kind` ∈ `xp|currency|item|level_up|inspiration|custom` ; `p_mode` ∈ `grant` (en attente) / `apply` (appliquée tout de suite) | `unknown_grant_kind`, `apply_not_allowed` (ex. `level_up` en `apply`), `invalid_payload`, `item_not_found` | `grant.created` -> `group:{id}` (visible du seul destinataire pour le détail) ; `grant.applied` si `apply` | carte « récompense » à la reconnexion |
| Récompenses à plusieurs (N) | MJ | `gm_grant_many(p_group_id, p_grants jsonb, p_request_id)` : une transaction, <= 12 cibles ; **montants par cible fournis par le client** (aucun partage calculé en base) | `too_many_targets` | un événement par cible | idem |
| Annuler une récompense (N) | MJ | `gm_cancel_grant(p_grant_id)` | `grant_not_pending` | `grant.cancelled` | - |
| **Accepter / refuser** (N, côté joueur) | propriétaire du personnage | `accept_grant(p_grant_id, p_request_id)` / `decline_grant(p_grant_id)` ; `xp`, `currency`, `item` : appliqués atomiquement ; `level_up` : passe `accepted`, ouvre le parcours existant, puis **`apply_level_up(…, p_grant_id)`** (version `api_v1` de la RPC existante, ajoute le paramètre et clôt la récompense) | `grant_not_pending`, `grant_obsolete` (le niveau cible est déjà atteint), `grant_expired` | `grant.accepted`/`declined`/`applied` -> MJ | accepter xp/or/objet = écriture **en file** idempotente ; `level_up` = en ligne (v1) |
| Appeler un repos (N, option) | MJ | `gm_call_rest(p_group_id, p_kind 'short'|'long', p_note)` : **notification seulement**, chaque joueur applique son repos avec `apply_rest` (choix de dés de vie = joueur) | - | `rest.called` | push |
| Révéler/cacher une entrée d'histoire (N) | MJ de l'histoire | `reveal_story_entry(p_group_id, p_entry_id)` / `hide_story_entry(...)` | `entry_not_found`, `story_group_mismatch` | `story.entry_revealed` | lecture à la reconnexion |
| Générer / lier / délier un groupe (N) | MJ de l'histoire | 2.4 | `story_not_found`, `not_story_owner`, `group_limit_reached`, `already_linked`, `owner_mismatch` | `group.generated`, `group.linked`, `group.unlinked` -> `adventure:{id}` | - |
| Retirer un joueur (E) | MJ | suppression de `group_members` (policy existante) ou `remove_member` | - | `member.left` | - |

`create_character`, `apply_rest`, `apply_level_up` (déjà en base, **aucun appelant** [C], D05) : aliasées dans `api_v1`, appelées par le mobile à sa bascule.

### 3.3 Combat et monstres : ce qui manque [C]

`combat_participants` n'a ni PV, ni CA, ni lien vers une créature (colonnes : name, kind `pc|npc`, initiative, sort_order, status). `add_npc_participants` ne prend qu'un nom de base (limite 20 par appel, 60 par combat). L'outil de Florian a besoin des deux ; la solution est la table MJ-seule `combat_npc_state` + `add_monsters` ci-dessus, **sans toucher** aux 7 RPC publiées.

### 3.4 Journal d'audit et idempotence

`game_events` conserve : acteur, rôle, genre, charge utile minimale, `request_id`, `seq`. Aucune donnée de fiche complète. Rétention par défaut 90 jours (décision A12 + avis `rgpd`) ; `actor_id` anonymisé à la suppression de compte. `api_v1_requests` : purge à 7 jours, `unique(actor, request_id)`.

### 3.5 Conflit avec la file hors ligne du mobile [C pour l'existant]

Existant : `pending_character_write_syncer.dart` enfile des écritures **absolues** (PV : `currentHp`/`temporaryHp` + `baseCurrentHp`/`baseTemporaryHp`, l.385-417 ; XP : `newXp` + `baseXp`, l.500-524 ; monnaies : totaux + bases, l.419-465). Avant l'envoi, il relit la valeur serveur et, si elle diffère à la fois de la valeur en file et de la base mémorisée, produit un `ServerValueConflict` (alerte D34/F19) ; les commentaires indiquent que **l'écriture part dans tous les cas** (l.422-423, l.472-473 ; **[D] pour les PV et l'XP**, je n'ai pas lu la décision prise après l'alerte).

Conséquence : si le MJ applique 7 dégâts pendant que le joueur est hors ligne et que celui-ci a une écriture de PV en file, l'écriture absolue **écrase** les dégâts du MJ. Le journal `game_events` dira « 7 dégâts » alors que les PV ne les reflètent plus.

| Cas | Résolution proposée |
|---|---|
| Mobile publié (écritures directes `characters`) | **Risque accepté et documenté** jusqu'à la bascule ; atténuations : la base ne peut pas arbitrer (aucune `rev` envoyée par l'ancien client) ; l'alerte existante prévient le joueur ; événement visible dans le journal |
| Mobile migré : PV, XP, monnaies | La file envoie des **deltas** (`valeur en file - base`) via `api_v1.apply_hp_delta` / `apply_xp_delta` / `apply_currency_delta` + `request_id` : les deux écritures **se cumulent** (commutatif). Plus de conflit PV/XP/or |
| Mobile migré : champs libres (nom, notes) | `p_expected_rev` ; `rev_conflict` -> alerte existante « garder ma version / prendre celle du serveur » |
| Reconnexion | 1) rejoindre `group:{id}` ; 2) `events_since(group, last_seq)` ; 3) vider la file ; 4) relire l'état (`group_state`) : jamais l'inverse (sinon l'écriture masque l'événement) |

Décision de conception à valider avec `qa-testeur` et Matthias : l'évènement MJ est **prioritaire** en cas d'écart (principe retenu en 03 §4.3).

---

## 4. Données de référence pour l'outil

Constat [C] : `creatures` : 331 lignes, une source (« SRD 5.2 (Manuel des Monstres 2024) »), aucun client aujourd'hui ; colonnes `id` identity, size, creature_type, alignment, armor_class, hit_points, hit_dice, speed/ability_scores/saving_throws/skills jsonb, résistances texte, challenge_rating numeric, experience_points, proficiency_bonus, initiative_bonus, traits/actions/bonus_actions/reactions/legendary_actions jsonb ; index (challenge_rating), (creature_type) ; nom dans `translations` (EAV, `entity_type='creature'`) ; lecture `anon`+`authenticated`.

| Besoin | Proposition |
|---|---|
| **Clés stables** | Colonne `slug text unique` sur `creatures`, `items`, `spells`, `classes`, `races`, `feats`, `backgrounds` (D04) : **prérequis de la phase 1**, car Florian référencera ces objets. Les `id` entiers sont stables tant que les seeds ne sont pas rejoués ; le slug est le contrat. |
| **Lecture en liste** | Vues `security_invoker` `api_v1.creatures`, `items`, `spells`, `classes`, `subclasses`, `races`, `feats`, `backgrounds`, `class_features` avec `name_fr`, `name_en`, `edition`, `source_code`, `slug`, colonnes de filtre (CR, type, taille, niveau, école, rareté…) ; **sans** descriptions longues |
| **Détail** | `api_v1.get_creature(p_ref)`, `get_spell`, `get_item`... (RPC, `p_ref` = slug ou id) -> composite typé ; descriptions fr/en |
| **Recherche** | `api_v1.search_reference(p_query, p_types text[], p_locale, p_edition default null, p_limit default 50, p_after jsonb default null)` ; index de recherche dénormalisé `reference_search(entity_type, entity_id, locale, name, name_norm)` avec trigramme + `unaccent` (**extensions non vérifiées en production**, requête 06-Q-SQL-16) ; la recherche passe par cet index, pas par la jointure sur `translations` (P07) |
| **Filtres/tri** | `p_cr_min/max`, `p_types`, `p_sizes`, `p_source`, `p_edition`, `p_class_id`, `p_level`, `p_ritual`, `p_concentration`… ; tri stable `(name_norm, id)` ; keyset |
| **Pagination** | Keyset (`p_limit` <= 200, `p_after`), réponse `{items, next}` ; vues via `Range` (plafond serveur `max_rows` = 1000 [C en local]) |
| **Cache/invalidation** | Table `reference_versions(entity_type, content_rev, updated_at)` incrémentée par les migrations de seed ; ETag côté client (P06) |
| **Édition/source** | 2.7 ; l'outil affiche et filtre ; défaut = édition de l'histoire (`adventures.edition`) |
| **Contenu maison** | `custom_creatures`, `custom_items` (2.1) ; lecture combinée `api_v1.creature_catalog` = référence UNION contenu du MJ (`origin` = `reference|custom`, filtré par RLS sur `owner_id`/`adventure_id`) ; partage entre MJ : non en v1 |
| **Écriture** | Référence : inchangée (`is_admin()`). `upsert_custom_creature(p_data jsonb, p_request_id)` validé (CR, bornes) |
| **Droits** | Lecture publique conservée (SRD) ; décision B9 sur la fermeture à `authenticated` seul |

Règle de jeu : validation d'un monstre maison (CR -> bonus de maîtrise, XP) et budget de rencontre -> `regles-dnd` (section 8).

---

## 5. Temps réel de bout en bout

### 5.1 Topics (Broadcast **privé**, autorisation par `realtime.messages`)

| Topic | Abonnés autorisés | Contenu |
|---|---|---|
| `group:{group_id}` | membres, MJ | événements métier visibles des joueurs (combat, PV/état d'un coéquipier, effets, récompenses reçues, révélations, arrivées/départs) |
| `gm:{group_id}` | MJ (et co-MJ) | tout ce qui est réservé : état des monstres, acceptations/refus, notes |
| `adventure:{story_id}` | propriétaire (outil) | agrégat : groupes liés, présence, génération de groupes |
| `user:{user_id}` | l'utilisateur | grants à son nom, `gm_actions` à consentir (évite de transporter des détails sur `group:`) |

Policy `realtime.messages` : `exists` sur `group_members`/`groups`/`adventures` avec `(select auth.uid())`, une fois par abonnement. **Non vérifié** : version du serveur Realtime, disponibilité de `realtime.send`/`broadcast_changes`, quotas du plan (06-Q-SQL-6, déjà fournie).

### 5.2 Émission : un chemin unique

`insert into game_events` (par les RPC) -> trigger `after insert` -> `realtime.send(payload, event, topic, true)`. Pour couvrir **les écritures directes du mobile publié** (PV, conditions, XP via `update characters`), un trigger `after update` sur `characters` (colonnes PV/PV temp/conditions/XP/is_dead seulement) insère un événement `character.state_changed` {character_id, rev}. `postgres_changes` reste actif pour les builds publiés (inchangé).

Payloads **minimaux** (`payload_version`) : identifiants + valeurs strictement utiles à l'affichage immédiat ; jamais de ligne `characters` entière ; jamais de contenu `adventure_entry_secrets`.

### 5.3 Événements métier

`group.generated|linked|unlinked`, `member.joined|left`, `combat.started|ended|participant_added|participant_revealed|initiative_set|order_changed|turn_advanced`, `character.hp_changed|state_changed`, `effect.applied|removed|expired`, `grant.created|accepted|declined|applied|cancelled`, `rest.called`, `story.entry_revealed|hidden`.

### 5.4 Présence

Présence Supabase sur `group:{id}` : `{user_id, role, character_id, client: 'mobile'|'tool', since}` ; **uniquement tant que l'écran/groupe est ouvert**. Rien n'est persisté. À soumettre à `rgpd` (indicateur d'activité visible des autres membres). Sans MJ connecté, le mobile n'affiche rien de plus.

### 5.5 Reprise et cohérence

- `api_v1.events_since(p_group_id, p_after_seq bigint, p_limit int default 200)` -> `{events, has_more, gap}` ; `gap = true` si l'historique demandé est purgé -> le client appelle `group_state`.
- `api_v1.group_state(p_group_id)` : snapshot minimal (membres, combat actif et participants visibles, effets actifs, grants en attente, `seq` courant) calculé **avec les droits de l'appelant**.
- À `SUBSCRIBED` après coupure : `events_since(last_seq)` -> appliquer -> rejouer la file hors ligne (3.5).
- Pas de garantie d'ordre entre deux topics ; l'ordre faisant foi est `seq`.

### 5.6 Coûts (estimation, à mesurer)

Groupe de 6 joueurs + MJ + outil = 8 abonnés ; rafale de combat ~ 1 événement/s/groupe -> ~8 livraisons/s sans évaluation RLS par ligne (contrairement à `postgres_changes`, 4 tables publiées [C]). Nombre de groupes simultanés : inconnu [I] (06-Q-SQL-2). Aucun filtre `in(...)` (limite 100). Un abonnement par topic, résilié à la sortie de l'écran.

---

## 6. Contrat d'API v1 révisé

- **Schéma** `api_v1` exposé à PostgREST (`config.toml` local ; réglage « Exposed schemas » du tableau de bord en production : **action manuelle de Matthias**, à vérifier par 06-Q-SQL-1). Les tables `public` restent exposées tant que le mobile publié les utilise ; la **phase 7** retire ses accès directs.
- **Ressources** : `story`, `story_entry`, `group` (génération, liaison, code, membres), `combat`, `character` (fiche, PV, effets, récompenses), `inventory`, `reference` (créatures, objets, sorts, classes, races, dons, historiques, recherche), `event` (flux, reprise), `profile`. Les 03 §2.2 pour personnage/inventaire/sorts sont conservés ; la ressource `table` est retirée.
- **Conventions** : celles de 03 §2.1 (snake_case, `p_*`, uuid/int stable, idempotence, keyset, réponse après modification) **sauf** R7 (codes d'erreur précis + SQLSTATE).
- **Classes SQLSTATE -> HTTP** [D, à valider par test PostgREST] : 28000 -> 401 ; 42501 -> 403 ; P0002 -> 404 (**réponse identique pour « inconnu » et « invisible »**) ; 22023 -> 400 ; P0001 -> 400 (+ `detail`) ; PT409 -> 409 ; PT429 -> 429.
- **Typage TypeScript** : `supabase gen types typescript --schema api_v1` types vues et signatures de RPC ; **les retours `jsonb` ne sont pas typés**. Règle : toute RPC renvoie un **type composite nommé** ou `setof` une vue (`api_v1.generated_group`…) ; `jsonb` seulement pour `payload`/`attributes` documentés par un schéma versionné. Les types générés sont committés dans le dépôt de Florian (**à valider avec Florian**) ; le mobile (Dart) a des modèles `freezed` écrits à la main (aucun générateur). OpenAPI exposé par PostgREST : **[I]** (accès restreint selon la version).
- **Contrat documenté** : `docs/api-v1/` (ressources, erreurs, événements, schémas de payload, exemples), **même texte** dans les deux dépôts ; chaque signature a son test pgTAP (jamais de contrat sans test).
- **Versionnage** : aucune signature publiée ne change ; paramètres additionnels avec défaut ; rupture = `api_v2` ; dépréciations par `comment on` + `docs/api-v1/CHANGELOG.md`.
- **Mobile** : migre ressource par ressource depuis l'accès direct (`.schema('api_v1')` avec `supabase_flutter` **[D]**) ; l'ancien code reste valide pendant toute la transition.

---

## 7. Plan de migration révisé (phases additives)

Chaque phase : migrations propres, retour arrière en commentaire, pgTAP, PR relue (`code-reviewer`, `regles-dnd` pour les règles, `qa-testeur` pour la matrice d'accès). Matthias applique (`--dry-run` d'abord, cible `nexus-jdr (beazvozraxvcbymbxumb)`, jamais « Keystone »). **Prérequis transversal : projet Supabase de test séparé (R8).**

| Phase | Contenu | Dépend de | Effort | Impact mobile publié |
|---|---|---|---|---|
| **0 Hygiène** | index, policies initplan, CHECK `not valid` puis `validate`, REVOKE/`pg_temp`, `set_updated_at`, `comment on`, réparation des 3 tests pgTAP en échec (D60) | - | S-M | aucun |
| **1 Contrat et références** | `api_v1` (schéma, `api_v1_requests`, catalogue d'erreurs), `slug` + `sources/edition`, vues/RPC de lecture des références, `search_reference`, `reference_versions`, `profiles`, alias des RPC combat et de `create_character/apply_rest/apply_level_up`, `docs/api-v1/`, génération des types | 0, environnement de test, B1-B6 | M | aucun |
| **2 Histoire** | `adventures`, entrées/secrets/reveals/assets, rencontres, contenu maison, bucket privé, `groups.adventure_id`, `generate_group_from_story`, `link/unlink`, `rotate_group_invite_code`, transfert/suppression, `group_story_info` | 1, B7-B10 | L | aucun (colonne nullable) |
| **3 Événements et temps réel** | `game_events`, `event_kinds`, triggers d'émission, policy `realtime.messages`, `events_since`, `group_state`, présence documentée, `characters.rev` | 1 (2 pour les événements d'histoire) | M | aucun (`postgres_changes` conservé) |
| **4 Actions MJ** | `gm_apply_hp_change`, effets, grants, `accept/decline_grant`, `advance_turn`, `add_monsters`, `combat_npc_state`, `revealed`, consentement | 3, **validation `regles-dnd`**, A1-A9 | L | léger : monstres cachés invisibles, PV modifiés par le MJ visibles via `postgres_changes` |
| **5 Bascule mobile** | `character_repository` découpé (D05), RPC atomiques, file en deltas, souscription Broadcast, écrans récompenses/effets/consentement | 3, 4 | L (dev-flutter) | version à publier |
| **6 Migration/archivage legacy** | script `stories -> adventures` ou fresh start, gel en lecture seule, buckets | 2, décision Florian | M | aucun |
| **7 Nettoyage** | retrait des accès directs `character_*`, `postgres_changes`, `character_campaigns`, `campaign_id` ; `min_supported_version` relevé | 5 publiée et adoptée (Q11) | M | oui : coupe l'ancienne version |

Estimation globale base : **L à XL (6 à 9 semaines de dev-backend-supabase avec revues, hors mobile)** ; mobile L ; l'outil de Florian n'est pas estimé ici. Ordre : 0 -> 1 -> (2 || 3) -> 4 -> 5 -> 6 -> 7 ; 2 et 3 sont parallélisables seulement si deux agents/personnes disposent d'une machine chacun (contrainte RAM déjà connue du projet).

### 7.1 Ce que Florian peut commencer dès la phase 1 (contrat figé) - **à valider avec Florian**

1. Authentification partagée (`supabase-js`, même projet de **test**), session, appel `api_v1` ; génération des types.
2. Écrans **bestiaire, objets, livre de sorts, classes/races** consommant uniquement les vues et `search_reference` (lecture seule, sans risque).
3. Maquettes d'écrans histoire/entrées/rencontres contre le **contrat documenté** de la phase 2 (signatures figées, non appliquées en base) avec un jeu de données simulé.
4. Prototype Broadcast/présence sur un topic de test (dès que le projet de test existe).

### 7.2 Ce qui reste à valider avant de coder côté outil

Forme du contenu (`body_*`, `attributes` par `kind`), nature des cartes/assets et quotas, ergonomie des actions MJ (3.2), liste des événements affichés, consentement, nommage, cardinalité, calendrier.

---

## 8. À soumettre à `regles-dnd` avant toute implémentation

1. **Dégâts et soins** : ordre d'absorption des PV temporaires ; plancher à 0 ; mort instantanée (dégâts restants >= PV max) ; passage à 0 PV (inconscience, jets de mort) ; soins depuis 0 (réveil, remise à zéro des jets de mort) ; plafond aux PV max ; PV max réduits ; coups critiques ; **où** appliquer résistances/vulnérabilités/immunités (client ou base) ; déclenchement d'un rappel de test de concentration.
2. **États et effets** : durées en rounds (début/fin de quel tour), `end_of_combat`, `until_rest`, cumul d'un même état, immunités, liste d'états par édition (2014/2024), épuisement (exclu de la V1 [C]), concentration.
3. **Expérience et niveau** : table des seuils, passage de plusieurs niveaux, progression par jalons, niveau 20 max, partage d'XP (le MJ envoie les montants ; la règle de partage reste du côté du client), cohérence `level_up` / XP, règles 2014 vs 2024.
4. **Récompenses** : accord d'objets (harmonisation, charges, poids/encombrement), conversion des monnaies (`ep`), objets maison.
5. **Repos** appelés par le MJ : durée, interruption, dés de vie (le joueur choisit).
6. **Combat** : égalités d'initiative, surprise, passage de round, actions légendaires, initiative des groupes de monstres, PV des monstres, états `waiting`/`removed`, **budget de rencontre** et conversion CR -> XP (2014 vs 2024).
7. **Monstres maison** : cohérence CR / bonus de maîtrise / XP.
8. **Classification des sources par édition** (2014/2024) pour le remplissage de `edition`/`source_code`.

Aucune de ces règles n'est tranchée ici.

---

## 9. Ce que je n'ai pas pu vérifier

- Tout l'état réel de la production (06, requêtes Q-SQL-14 à 24) : fournisseurs d'authentification, volumétrie des histoires du MJ, extensions disponibles (`pg_trgm`, `unaccent`), objets Realtime (`realtime.send`, `realtime.messages`), schémas exposés.
- `join-group`, `preview-group-invite`, `delete-account` : **non relus pour cette étape** ; la compatibilité de `generate_group_from_story` avec `join-group` est **déduite** du fait qu'il s'appuie sur `groups.invite_code` et `group_members`.
- Mapping réel PostgREST des SQLSTATE personnalisés (`PT409`, `PT429`) ; comportement de `realtime.send` sous charge ; accès à l'OpenAPI.
- Ce que fait le mobile après une alerte `ServerValueConflict` (garder/écraser) pour les PV et l'XP.
- Que `build_character_sheet_json` (utilisée par `get_group_member_character`) renvoie bien `journal_entries` de la fiche d'un coéquipier : la définition lue (l.314-322 de la migration conditions) **inclut** `journal_entries` ; à confirmer si `get_group_member_character` les filtre avant de promettre « journal privé » au joueur (déduit : écart possible, à vérifier, hors périmètre de cette étape).
- Les plans d'exécution, les performances de recherche, les coûts Realtime.
- L'outil de Florian : son hébergement (web, bureau, mobile), ses fournisseurs d'authentification, son calendrier, son dépôt.
