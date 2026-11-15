# 09 - Base de données : outil de MJ local (`grimoire-du-mj`) et API Nexus

Date : 15/11/2026. Ticket Project #7 : « Outil de Florian : Electron, connexion au compte Nexus et nouvelle analyse de la
base (étude) ». Agent `dev-sql-api`, **lecture seule** : aucune migration écrite, aucun dépôt modifié (sauf ce fichier),
aucun accès à une base distante. Complète `08-outil-local-electron-auth.md` (Electron, sécurité locale, connexion) et
**révise** `05-revision-propositions.md` sous l'hypothèse « contenu des campagnes local ».

Fiabilité : **[C]** certain (lu dans le code ou les migrations), **[D]** déduit, **[I]** incertain (dépend de la
production, d'une version de bibliothèque ou de Florian). Rien n'est décidé ici : options, coûts, recommandation.

**Fichiers lus.** Dossier `docs/api-refonte/` : `00` (y compris le bloc « Décisions du 15/11 », non commité), `05` (§1-§9),
`06`, `07`, `08`. Dépôt `grimoire-du-mj` (branche `main`, `cce83e1`) : `server/db.ts`, `server/store.ts` (l.1-420, 536-565,
800-980, 1380-1620), `server/app.ts`, `server/index.ts`, `server/config.ts`, `server/events.ts`, `server/live.ts`,
`server/exchange.ts` (passages joueurs), `shared/schema.ts`, `shared/live.ts`, `src/lib/api.ts`,
`src/components/board/board-ops.ts` (l.30-110), `README.md` (extraits), `package.json`. Migrations et edge functions lues
dans `H:/Projets/Labo/mj-ph0` (worktree de `markdown-editor`, branche `feat/api-phase0-hygiene` = `main` + phase 0, PR #48) :
`20260906182601_create_groups.sql`, `20260906190500_group_member_can_read_characters.sql`,
`20261023100000_group_member_can_read_character_ac_data.sql`, `20260927100000_group_member_character_sheet.sql` (l.305-352),
`20261016090000_group_members_orphan_character.sql` (l.120-136), `20261106100000_create_group_character_status_overview.sql`,
`20261110090000_add_characters_conditions.sql` (l.1-110), `20261114090000_create_group_combats.sql` (l.1-245),
`20261114091000_group_combat_rpcs.sql` (l.1-182, en-têtes et droits), `20260930160000_create_creatures.sql` (droits), en-têtes
des 9 migrations de la phase 0 et du fichier différé ; `functions/create-group`, `join-group`, `delete-account`,
`_shared/group-invite.ts`, `_shared/http.ts`. App mobile : `lib/features/groups/data/group_repository.dart`,
`lib/features/auth/data/auth_repository.dart` (l.374-560), `lib/features/combat/data/combat_repository.dart` (l.90-280),
`lib/features/characters/domain/armor_class_calculator.dart` (l.1-70), `lib/features/groups/domain/group_invite_code_generator.dart`,
`lib/core/cache/reference_data_cache.dart` (l.1-90).

---

## 0. Synthèse

**Verdict sur le conflit avec la décision n° 2 du 14/11.** Le conflit est réel et ne se règle pas par un compromis
technique : si le contenu des campagnes reste sur la machine du MJ (décision n° 2 du 15/11), la décision n° 2 du 14/11
(« les histoires et leur environnement vivent dans notre base ») et toute la phase 2 de `05` (§2.1-2.4) n'ont plus d'objet.
Ma recommandation (option **O1**, §2.2) : **aucune table « histoire » côté Supabase maintenant**. La base garde les comptes,
groupes, membres, personnages, le combat, les données de référence et, plus tard, les actions du MJ journalisées. Le lien
campagne ↔ groupe vit dans le SQLite local. Une étiquette publique ou une fiche distante minimale pourra s'ajouter plus tard
**sans rupture** (migrations additives). Matthias tranche.

**Les 5 recommandations principales**
1. **Florian peut coder l'essentiel de la v1 sans aucune migration** [C] : connexion (e-mail + mot de passe), lecture de ses
   groupes, membres, personnages et du combat avec les droits actuels, « Générer un groupe » avec l'edge function existante
   `create-group` (sans personnage : le MJ est créé avec `is_game_master = true`, donc le combat est possible), les 7 RPC du
   combat, la copie hors ligne des catalogues (lecture publique).
2. **Livrer un seul contrat de lecture avant le lot 3 de `08`** : `api_v1.group_snapshot(group_id)` (un appel au lieu de 6,
   sous-ensemble minimal des fiches, CA calculée côté serveur, ~5-8 Ko par groupe au lieu de ~70 Ko) et
   `api_v1.my_gm_groups()`. Utilisable ensuite par le mobile (écran « Groupe »). Pas de curseur incrémental : à l'échelle
   d'un groupe, l'instantané complet + une empreinte (`hash`) suffit.
3. **Redéfinir « groupe lié »** sans histoire : groupe dont le MJ (propriétaire, avec ligne MJ) a activé le pilotage par
   l'outil (`groups.gm_tool_enabled_at`, posé par RPC) **et** dont chaque joueur ciblé a consenti
   (`group_members.gm_actions_consent_at`). À livrer avec la phase 4 seulement.
4. **Côté SQLite** : une base par compte (comme `08` A8), des tables de cache `nexus_*` et de liens **séparées** du contenu
   (jamais dans les exports, jamais d'écriture de `campaigns`/`players` sur un événement distant), une campagne ↔ 0 ou
   1 groupe, un joueur local ↔ 0 ou 1 personnage, jamais de suppression locale déclenchée par un événement distant.
5. **Dépriorise** ce que l'hypothèse locale rend inutile : `adventure_*`, bucket d'images, modèle de spoilers, monstres
   cachés côté serveur (`revealed`), `combat_npc_state`, contenu maison en base, `profiles`, recherche serveur. **Garde** :
   slugs et éditions des références (encore plus nécessaires : l'outil stockera les références dans une base que le
   serveur ne peut pas migrer), idempotence (`p_request_id`), actions MJ de la phase 4, `game_events`.

---

## 1. Constats de départ [C]

| Constat | Référence |
|---|---|
| L'outil est un serveur Node local (Hono, `node:sqlite` en WAL, SSE `/api/events`, WebSocket `/api/live`) qui écoute sur `0.0.0.0` par défaut ; aucun compte, aucune trace de Supabase | `grimoire-du-mj/server/config.ts:22`, `server/index.ts:11-12`, `package.json` |
| Joueur local = `players(id, name, level, image, hp)` ; `hp` = PV **max** ; les PV **actuels** d'un héros sont portés par le **jeton** de chaque plateau | `server/db.ts:111-118,192`, `shared/schema.ts:94-99,372-373`, `src/components/board/board-ops.ts:41-46,84-89` |
| Une campagne porte l'état de partie (étapes cochées, choix de dialogue, jetons) ; ses joueurs sont un tableau JSON `campaigns.player_ids` | `server/db.ts:120-128`, `shared/schema.ts:291-292,405` |
| Chaque écriture relit la campagne entière (`getCampaign`) pour la nettoyer, puis notifie tous les appareils (`emitCampaign`) | `server/store.ts:251-258,846-931,1485-1529` |
| Créer un groupe côté Nexus = edge function `create-group` (nom, personnage facultatif) ; sans personnage, la ligne du créateur est `role='owner', is_game_master=true` | `markdown-editor/supabase/functions/create-group/index.ts:10-27,166-172` |
| Le combat exige que le propriétaire du groupe ait une ligne MJ (`group_has_gm`) ; monstres = nom + initiative, **jamais de PV** côté serveur | `20261114090000_create_group_combats.sql:7-17,199-214` |
| Un membre (donc le MJ, qui a une ligne) lit la ligne **entière** de `characters` et de 4 tables filles des coéquipiers ; seul le propriétaire écrit | `20260906190500_...:19-41`, `20261023100000_...:25-35`, `20260825090400_create_character_tables.sql:64-80` |
| 4 tables publiées sur Realtime : `characters`, `group_members`, `combats`, `combat_participants` | `20261107090000:48`, `20261108090000:64`, `20261114090000:338-347` |
| La CA n'est jamais stockée : le mobile la calcule en Dart (inventaire, caractéristiques, options de classe, noms **français** des classes) | `lib/features/characters/domain/armor_class_calculator.dart:10-13,61-69` |
| Phase 0 (PR #48) : dans le worktree, `093000` et `094000` ont été mis de côté dans `supabase/.phase0_attente/` (modification non commitée) : application en cours, étape par étape | `git status` de `mj-ph0` |

---

## 2. Côté Supabase

### 2.1 Révision de `05` sous l'hypothèse « contenu local »

Légende : **C** conservé, **R** réduit, **S** supprimé, **N** nouveau, **P** conservé mais reporté.

**§1 (R1-R11)**

| # | Statut | Révision et raison |
|---|---|---|
| R1 client neuf sur `api_v1` | C | L'outil appelle l'API depuis son processus Node (`08` A1) |
| R2 ressources `story` et `group`, `group.story_id` | S | Plus de ressource `story` ; seule la ressource `group` existe côté serveur |
| R3 droit MJ : propriétaire + groupe lié + membre actif + consentement | C, redéfini | « Lié » ne veut plus dire « rattaché à une histoire » (§2.3) |
| R4 flux `game_events` par groupe | P | Utile pour l'audit et le journal des actions MJ (phase 4) ; inutile pour la v1 de l'outil (lecture + combat) |
| R5 Broadcast privé au cœur | R | `postgres_changes` existant suffit à la v1 (§2.6) ; Broadcast avec la phase 4 ; topic `adventure:{id}` supprimé, `gm:{id}` probablement inutile (les données réservées au MJ restent locales) |
| R6 catalogues = API publique (slugs, éditions, pagination, versions) | C, renforcé | Copie **hors ligne** dans l'outil : clés stables encore plus nécessaires ; la recherche serveur devient secondaire (recherche locale) |
| R7 codes d'erreur précis + SQLSTATE | C | Inchangé |
| R8 projet de test avant que Florian code | C (à rediscuter) | La session du 14/11 a écarté le projet séparé ; le développement de l'outil se fera sur la production (décision D5) |
| R9 legacy gelé | C, réduit | La migration `stories -> adventures` n'a plus de cible : il ne reste que l'archivage |
| R10 où vivent les migrations | C | Toujours ouvert (B1) |
| R11 phases liées au web | remplacé | §5 de ce document |

**§2.1 tables et colonnes**

| Objet de `05` | Statut | Raison |
|---|---|---|
| `adventures` | S (option O2 possible plus tard) | Le contenu et ses métadonnées sont locaux ; une fiche distante ne sert qu'à l'affichage côté joueur (§2.2) |
| `adventure_members` (co-MJ) | S | Si le co-MJ revient un jour, il se porte au niveau du groupe (`group_gms`) |
| `adventure_entries`, `adventure_entry_secrets`, `adventure_entry_reveals` | S | Rien de secret ne quitte la machine du MJ : le problème des spoilers (H1) disparaît par construction |
| `adventure_assets` + bucket privé | S | Les fichiers restent locaux (motif de la décision du 15/11) |
| `adventure_encounters` | S | Les rencontres sont des plateaux/PNJ locaux |
| `custom_creatures`, `custom_items` | S | La bibliothèque PNJ/objets de l'outil (`npcs`, `items`, `server/db.ts:20-33`) est le contenu maison. Un objet maison donné à un joueur passera par une récompense qui en copie la fiche (colonnes personnalisées existantes de `character_inventory`) |
| `story_entry_kinds` | S | Sans objet |
| `game_events`, `event_kinds` | P | Phase 4 ; colonne `adventure_id` retirée |
| `character_effects`, `character_grants`, `effect_kinds`, `grant_kinds` | P | Phase 4, inchangés sur le fond |
| `api_v1_requests` (idempotence) | C, avancé | Un outil au réseau intermittent rejoue ses appels : utile dès la première écriture nouvelle (`create_group` RPC éventuelle, phase 4) |
| `profiles` | R (différé) | L'outil lit le pseudo du MJ dans sa session (`user_metadata.full_name`) et celui des membres par `group_members_display_name` (`20261016090000:120-133`) [C] |
| `groups.adventure_id` | S | Remplacé, si besoin, par `groups.gm_tool_enabled_at` (phase 4) et une étiquette facultative (option C, §2.3) |
| `groups.invite_enabled` | C (option) | H6 inchangée ; exige de modifier `join-group` (dépôt gelé) |
| `group_members.gm_actions_consent` | C (phase 4) | Devient `gm_actions_consent_at timestamptz` (date utile à l'audit) |
| `characters.rev` | R | Le trigger `updated_at` de la phase 0 (`20261115090000`) suffit à détecter un changement pour l'affichage ; `rev` ne sert qu'aux écritures conditionnelles de la phase 4 |
| `combats.rev` | P | Avec `advance_turn` (V2) |
| `combat_participants.revealed` | S | L'outil ne publie un monstre (nom + initiative) **que** quand le MJ veut que les joueurs le voient : un monstre caché n'existe tout simplement pas côté serveur. Évite le changement de comportement H13 sur le mobile publié |
| `combat_participants.creature_ref`, `combat_npc_state`, `add_monsters` | S | PV/CA des monstres restent sur les jetons locaux (décision combat « PNJ sans PV » [C]). Besoin réel restant : ajouter plusieurs PNJ **de noms différents** en un appel, idempotent (`add_npc_participants_batch`, N, phase 4) |

**§2.2-§2.8** : §2.2 spoilers **S** (principe conservé pour toute publication future : seul ce qui est publié part) ; §2.3
cardinalités **S côté serveur** (réglées localement, §3.2) ; §2.4 `generate_group_from_story` **remplacée** par `create-group`
existante, avec une RPC `api_v1.create_group(p_name, p_request_id)` **N, facultative** ; `link/unlink_group_to_story` **S** ;
`rotate_group_invite_code` **C, facultative** (le mobile fait aujourd'hui un `UPDATE` direct, `group_repository.dart:585-608`) ;
§2.5 droits : ligne « Histoire » **S** ; §2.6 `transfer_story`/`delete_story` **S**, `transfer_group` **P**, suppression du compte
du MJ **C** (S11/H10 toujours ouverts, §2.8) ; §2.7 éditions et sources **C** ; §2.8 legacy **R** (archivage seulement).

**§3 actions MJ** : tableau 3.2 **P** (phase 4) sauf `add_monsters`, `set_participant_revealed`, `reveal_story_entry`,
« générer/lier/délier » (**S**). `advance_turn` **C** (V2). `gm_apply_hp_change`, effets, récompenses, acceptation, repos **C**.
§3.5 (conflit avec la file hors ligne du mobile) **C** : inchangé.

**§4 références** : slugs **C (prérequis)** ; éditions/sources **C** ; vues de liste **C** ; RPC de détail **R** (l'outil a la
copie complète) ; `search_reference` **R** (recherche locale ; serveur facultatif) ; `reference_versions` **remplacé** par
`api_v1.reference_manifest()` calculé à la volée (§2.4, rien à penser à incrémenter dans chaque seed) ; contenu maison **S** ;
**N** : `api_v1.reference_export(...)` (pages complètes, traductions incluses).

**§5 temps réel** : topics `group:{id}` **P**, `user:{id}` **P**, `gm:{id}` **R**, `adventure:{id}` **S** ; présence **R**
(facultative) ; `events_since` **P** ; `group_state` **fusionné** avec `group_snapshot` (§2.4, N, phase 1a).

**§6 contrat** : **C**, ressources `story`/`story_entry` retirées, `group_snapshot` et `reference_manifest/export` ajoutées.

**§7 phases**

| Phase de `05` | Statut | Nouvelle forme |
|---|---|---|
| 0 Hygiène | C | En cours d'application (PR #48) |
| 1 Contrat et références | R | 1a « lecture outil » (S-M) + 1b « références » (M) ; `profiles` et `search_reference` sortis |
| 2 Histoire (L) | **S** | Remplacée par 2' « lien outil » (S) : rien, ou une étiquette sur `groups` (décision D7) ; le drapeau `gm_tool_enabled_at` et le consentement partent en phase 4 |
| 3 Événements et temps réel | P, fusionnée | Avec la phase 4 (les événements n'ont de sens qu'avec les actions MJ) |
| 4 Actions MJ | C | Sans les actions d'histoire ; + `add_npc_participants_batch`, + RPC « butin du groupe en delta » |
| 5 Bascule mobile | C | + lecture de `group_snapshot` pour l'écran « Groupe » |
| 6 Migration legacy | R | Archivage seulement |
| 7 Nettoyage | C | Inchangé |

Effort base estimé [D] : 05 donnait 6 à 9 semaines ; sans la phase 2 (L) ni la migration legacy, **environ 5 à 7 semaines**,
dont seulement 1a (3 à 5 jours avec revues) avant que Florian lise les groupes.

**Effet sur `06`** : B4 (nommage `adventures`), B7 (cardinalité), H1-H5, H7-H9, H11-H13 deviennent sans objet ; B2 est
largement réglée par `08` (même projet, e-mail + mot de passe, Google par boucle locale, Apple hors v1) ; B3/R8 reste ouverte
(D5) ; H6, H10, H14 (reformulée : « groupe piloté par un outil de MJ »), A1-A12, R1-R4 restent valables ; L2 devient
« archiver ou non ». **Effet sur `07`** : parcours (a) remplacé par §2.3 ; (b) conservé sans `add_monsters`/`revealed` ;
(c) et (d) conservés (phase 4) ; (e) entièrement local, sauf la publication des monstres au combat.

### 2.2 Conflit avec la décision n° 2 : options chiffrées

| Option | Principe | Coût base | Coût outil | Pour | Contre |
|---|---|---|---|---|---|
| **O1 (recommandée)** | Contenu local ; **aucun objet « histoire »** distant ; la campagne locale mémorise l'id du groupe | 0 maintenant ; phase 2 de `05` économisée (L, 2 à 3 semaines) | Liaison purement locale (§3.2) | Respecte la décision du 15/11 ; aucun fichier ni secret sur le serveur ; rien à synchroniser ; Florian peut coder la liaison tout de suite | Les joueurs ne voient pas le titre de l'histoire (sauf si le MJ nomme le groupe ainsi) |
| O1 + étiquette (option C de §2.3) | O1 + `groups.story_title`, `groups.story_summary_public` nullables | 1 migration additive (S, 1 jour avec tests) + affichage mobile (version à publier) | Écrit l'étiquette à la liaison | Le joueur voit « Campagne : … » ; aucune nouvelle table ni RPC (la policy « Owner can update their groups » couvre les colonnes) | Copie d'un titre local à tenir à jour |
| O2 | Fiche distante minimale `adventures(id, owner_id, title, summary_public, created_at, updated_at)` + `groups.adventure_id` + 4 RPC | ~1 semaine (table, RLS, RPC, tests, effet sur `delete-account`) | Créer/mettre à jour la fiche, la lier | Une « histoire » jouée par plusieurs groupes existe côté serveur ; prépare une publication de contenu partagée entre groupes | Réintroduit une copie distante de métadonnées locales ; pas de couverture sans bucket (donc sans fichier) ; utilité faible tant que rien n'est publié |
| O3 | Maintenir la décision n° 2 (contenu en base) | Phase 2 de `05` : L (2 à 3 semaines) + stockage des images | Réécrire la couche de stockage de Florian (`store.ts` 1 620 lignes, `exchange.ts` 1 168) vers l'API | Synchronisation multi-appareils native | Contredit la décision du 15/11 ; coût de stockage ; modèle de spoilers complexe |
| O4 (plus tard, additif à O1) | Publication **explicite** vers les joueurs : `group_publications(group_id, kind, title, body_public, asset_path, published_at, published_by, local_ref)` + bucket privé limité aux éléments publiés | M, le jour où la décision « révélations » est prise | Bouton « montrer aux joueurs » | Seul ce que le MJ publie part ; aucun secret possible par construction | À concevoir avec Florian et `rgpd` |

Recommandation : **O1 maintenant**, l'étiquette (C) quand Matthias veut l'afficher dans le mobile, O4 si les révélations
deviennent un besoin, O2 seulement si une « histoire » partagée par plusieurs groupes doit exister côté serveur. Toutes sont
additives à O1 : choisir O1 n'empêche rien. Proposition de rédaction pour remplacer la décision n° 2 du 14/11 (à valider) :
« Le contenu des campagnes (histoire, PNJ, lieux, plateaux, images, imports) vit dans l'outil local du MJ. La base Nexus porte
les comptes, les groupes, les membres, les personnages, le combat, les données de référence et, plus tard, les actions du MJ
journalisées et d'éventuelles publications explicites vers les joueurs. »

### 2.3 Lien groupe ↔ campagne locale, « groupe lié », « Générer un groupe »

**Options de lien.** (a) = O1 : la campagne locale garde l'id du groupe (table `campaign_links`, §3.2) ; (b) = O2 ;
(c) = O1 + étiquette sur `groups`. Recommandation : (a), puis (c) au besoin.

**Cardinalité, réglée localement** [D] : l'état de partie est dans la campagne locale (étapes cochées, choix, jetons). Une
campagne = une table de jeu = **0 ou 1 groupe**. Rejouer le même module avec un autre groupe = dupliquer la campagne (fonction
existante). Un même groupe enchaîne plusieurs campagnes dans le temps : **un groupe ↔ 0 à N campagnes**. Rien à contraindre
côté serveur.

**« Groupe lié » redéfini** (pour les seules écritures du MJ sur les fiches, phase 4) :
1. l'appelant est `groups.owner_id` **et** a une ligne `group_members.is_game_master = true` (même règle que le combat,
   `group_has_gm` [C]) ;
2. le groupe est **piloté par l'outil** : `groups.gm_tool_enabled_at is not null`, posé par une RPC
   `api_v1.set_group_gm_tool(p_group_id, p_enabled, p_request_id)` (et non par `UPDATE` direct : l'activation doit émettre
   un événement visible des membres et être journalisée) ;
3. le personnage cible a une ligne active dans ce groupe ;
4. le joueur a consenti : `group_members.gm_actions_consent_at is not null` (implicite à l'adhésion si le groupe était déjà
   piloté, explicite sinon : A7 de `06`, avis `rgpd`).
Le combat reste ouvert à tout propriétaire avec ligne MJ, piloté ou non (comportement publié [C]).

**« Générer un groupe » depuis l'outil.** Aujourd'hui [C] :
- `create-group` (POST `{name}`, sans `character_id`) crée `groups` (code de 8 caractères, alphabet
  `23456789ABCDEFGHJKMNPQRSTUVWXYZ`, 5 tentatives sur collision, `_shared/group-invite.ts:87-109,130-170`), la ligne
  `group_treasure` (trigger) et la ligne `group_members (owner, is_game_master=true)` (`create-group/index.ts:166-172`). Réponse
  `{id, name, invite_code}`. Le mobile l'appelle par `functions.invoke` (`group_repository.dart:401-408`) ; l'outil peut faire
  exactement la même chose depuis Node avec le JWT du MJ. **Aucune migration requise.**
- Limites : deux écritures non transactionnelles (« rollback applicatif », `create-group/index.ts:174-195`) ; **aucune
  idempotence** : un nouvel essai après une coupure réseau peut créer un second groupe. Côté outil : action en ligne
  seulement, bouton désactivé pendant l'appel ; en cas de réponse perdue, relire « mes groupes » et chercher un groupe du
  même nom créé dans la minute avant de réessayer.
- Rejoindre : inchangé (`join-group`, même table, même code [C]) ; le mobile publié n'a rien à changer.
- Code : régénérer = `UPDATE groups set invite_code` par le propriétaire (policy « Owner can update their groups »,
  `20260906182601_create_groups.sql:96-100`), comme le mobile (`group_repository.dart:585-608`) ; l'outil doit réutiliser le
  même alphabet et la même longueur (`group_invite_code_generator.dart:10-11`). Renommer, dissoudre, exclure : idem [C].
- Plus tard (facultatif, phase 2') : `api_v1.create_group(p_name text, p_gm_tool boolean default true, p_request_id uuid
  default null) returns api_v1.created_group` en `security definer` (une transaction, idempotente, même règle de code en SQL,
  mêmes lignes que l'edge function). Seulement si les doublons deviennent un problème réel.

### 2.4 Données que l'outil doit LIRE

| Donnée | Objet existant utilisable | Droit actuel pour le MJ | Forme recommandée |
|---|---|---|---|
| Profil du MJ (pseudo, avatar) | Session : `user.user_metadata.full_name`, `avatar_url` (`auth_repository.dart:389-391`, 573-588, 644) | Son propre JWT [C] | Tel quel ; pas de `profiles` en v1 |
| Ses groupes | `groups` | Policies propriétaire et membre (`create_groups.sql:77-85`) [C] | `api_v1.my_gm_groups()` (ci-dessous) ; en attendant, `select` direct |
| Badges morts / PV bas | Vue `group_character_status_overview` (`security_invoker`, `20261106100000:57-71`), lue par `group_repository.dart:361-364` | Membre [C] | Telle quelle ; intégrée à `my_gm_groups()` |
| Membres (+ pseudo) | `group_members` + relation calculée `display_name:group_members_display_name` (`group_repository.dart:490-498`) | « Member can select members » via `is_group_member` (`create_groups.sql:112-115`) [C] ; un propriétaire **sans** ligne ne les voit pas | Dans `group_snapshot` |
| Personnages en résumé | `characters` + `character_classes` + traductions ; pour la CA : `character_ability_scores`, `character_inventory` + `items` + `armor_properties`, `character_class_options` (requête du mobile, `group_repository.dart:478-551` : **6 allers-retours**) | Policies « teammates » (`20260906190500:36-45`, `20261023100000:25-39`) [C] : la ligne **entière**, textes personnels compris | `group_snapshot` (sous-ensemble minimal, CA serveur) |
| Fiche complète d'un membre (vue détaillée) | `get_group_member_character(p_group_id, p_character_id)` (`20260927100000:316-351`) | `authenticated`, membre du groupe [C] | Telle quelle, à la demande, **jamais mise en cache** (données personnelles) |
| Combat actif | `combats` + `combat_participants` (requête du mobile, `combat_repository.dart:106-115`) | « Member or owner can select » (`20261114090000:236-245`) [C] | Dans `group_snapshot` |
| Trésor du groupe | `group_treasure` | Membre [C] | Direct (si D12) |
| Référence (monstres, objets, sorts, classes, races, dons, historiques) | Tables publiques + `translations` (EAV) | Lecture `anon` + `authenticated` (ex. `20260930160000_create_creatures.sql:50-55`) [C] | Copie locale : `reference_manifest()` + `reference_export()` (phase 1b) ; possible dès aujourd'hui par lecture paginée directe |

**`api_v1.group_snapshot(p_group_id uuid) returns jsonb`** (phase 1a, proposition)
- `security invoker`, `stable`, `set search_path = public, pg_temp` : la RLS de l'appelant s'applique, **aucune élévation de
  droit** ; `revoke all ... from public, anon` ; `grant execute ... to authenticated`. Erreurs : `not_authenticated` 28000,
  `group_not_found` P0002 (inconnu **ou** invisible, même code que le combat).
- Retour `jsonb` versionné (exception assumée à la règle « types composites » de 05 §6, autorisée pour un document imbriqué
  à schéma publié) : schéma JSON dans `docs/api-v1/`, validé côté outil par zod (déjà utilisé partout chez Florian).

```
{ "v": 1, "hash": "<md5 du contenu>", "server_time": "...",
  "group":   { "id", "name", "owner_id", "invite_code", "is_owner", "has_game_master", "gm_tool_enabled_at": null, "created_at" },
  "members": [ { "membership_id", "user_id", "display_name", "role", "is_game_master", "joined_at",
                 "character": null | { "id", "name", "portrait_url", "race_name",
                                       "classes": [ { "class_id", "class_name", "subclass_name", "level" } ], "total_level",
                                       "current_hp", "max_hp", "temporary_hp", "is_dead", "conditions": [...],
                                       "armor_class": 15 | null, "updated_at" } } ],
  "combat":  null | { "id", "status", "round", "current_participant_id", "created_at",
                      "participants": [ { "id", "kind", "name", "initiative", "sort_order", "status", "character_id", "user_id" } ] } }
```

- Taille [D] : ~0,7 Ko par membre, ~2 Ko pour un combat de 10 participants : **5 à 8 Ko** pour 6 joueurs (~2 Ko compressé),
  contre ~70 Ko aujourd'hui côté mobile (inventaire complet de chaque coéquipier pour la CA) + 4 requêtes de traductions.
  À mesurer : Q-SQL-27/28.
- **Pas de curseur incrémental** : à l'échelle d'un groupe (≤ ~10 membres), l'instantané complet est plus simple et plus sûr ;
  l'outil compare `hash` pour ne rien retraiter. Les curseurs ne servent qu'aux catalogues (manifeste) et, en phase 4, au
  flux d'événements (`seq`).
- Minimisation : le résumé ne contient ni histoire personnelle, ni traits, ni inventaire. La RLS laissera toujours l'outil
  lire la ligne entière (elle ne filtre pas les colonnes, et le mobile en a besoin) : la discipline reste contractuelle,
  comme celle du mobile (`group_repository.dart:40-53`).
- **CA** : décision D4. Options : C1 réimplémenter en TypeScript dans l'outil (troisième copie d'une règle, dépend des noms
  français, ~6 lectures) ; **C2 fonction SQL `api_v1.character_armor_class(uuid)`** (invoker) appelée par l'instantané, cas de
  test communs avec le Dart (parité), identifiants de classe/sous-classe au lieu des noms français ; C3 colonne
  `characters.armor_class` écrite par le mobile (exige une version publiée ; `null` pour les anciennes). Recommandation : **C2**,
  avec `regles-dnd` pour la liste de cas et `qa-testeur` pour la parité.

**`api_v1.my_gm_groups()`** (phase 1a) : `setof (group_id, name, member_count, has_game_master, active_combat_id, dead_count,
low_hp_count, last_character_update)` pour les groupes dont l'appelant est propriétaire (ou aussi ceux où il joue : D9). Un
seul appel pour l'écran « Mes groupes » de l'outil ; la colonne `last_character_update` (max `characters.updated_at`, fiable
grâce au trigger de la phase 0) dit quels instantanés relire.

**Références hors ligne** (phase 1b) :
- `api_v1.reference_manifest() returns setof (entity_type, row_count, content_hash, schema_version)` : empreinte calculée à la
  volée (`md5` agrégé des lignes et de leurs traductions) ; aucun compteur à penser à incrémenter dans les seeds. Coût estimé :
  quelques dizaines de ms pour ~11 000 lignes [D], appelé au démarrage et à la reconnexion.
- `api_v1.reference_export(p_entity_type text, p_after bigint default null, p_limit int default 500)` : pages keyset par `id`,
  chaque ligne avec `slug`, `edition`, `source_code`, données et traductions fr/en incluses (pas d'EAV à recoller côté client).
- Volume (seeds rejoués, `01` l.29) : translations 7 467, spell_classes 1 392, class_features 1 030, spells 514, items 454,
  creatures 331, subclasses 121, feats 116, backgrounds 71. Copie complète estimée **4 à 8 Mo** JSON, 1 à 2 Mo compressés [D] :
  à mesurer (Q-SQL-29). Téléchargement une fois, puis seulement les types dont l'empreinte change.
- Clés stables : le `slug` (B5) reste **prérequis** avant que l'outil enregistre des références (ex. « PNJ basé sur le gobelin »)
  dans sa base, que le serveur ne pourra jamais corriger. En attendant : stocker `(entity_type, id, name_en)`.
- **Dès aujourd'hui, sans migration** : lecture paginée directe des tables (`Range`, ≤ 1 000 lignes, `max_rows`) puis des
  traductions ; sans empreinte, rafraîchissement manuel ou hebdomadaire.

### 2.5 Données que l'outil doit ÉCRIRE

| Écriture | Possible aujourd'hui ? | Comment / ce qui manque |
|---|---|---|
| Créer un groupe + code | **Oui** [C] | `create-group` ; idempotence absente (§2.3) |
| Renommer, régénérer le code, dissoudre, exclure un membre | **Oui** [C] | `UPDATE`/`DELETE` directs autorisés au propriétaire (`create_groups.sql:96-105,131-140`) |
| Lancer/terminer un combat, initiative d'un participant, ajouter/retirer/réordonner des PNJ | **Oui** [C] | 7 RPC (`20261114091000`), droits `authenticated` (l.504-510) ; codes d'erreur l.6-25. En ligne seulement, comme le mobile (`combat_repository.dart:263-276`) |
| Publier plusieurs monstres de noms différents en un appel, idempotent | Partiellement | `add_npc_participants` = un nom de base × N (≤ 20, ≤ 60 par combat) ; `add_npc_participants_batch` (N, phase 4) |
| Tour suivant | Non | `advance_turn` (V2, phase 4) |
| Donner du butin au groupe (monnaie, objets) | **Oui, avec réserve** [C] | Le MJ est membre : policy « Member can update their group_treasure » (`create_groups.sql:149-153`). Écriture **absolue** (course connue avec un joueur qui se sert, `group_repository.dart:184-212`) ; objets = `{item_id?, custom_name?, quantity}` seulement (un objet maison arrive avec son seul nom). Décision D12 ; RPC delta en phase 4 |
| Dégâts, soins, états, XP, monnaie, objets **sur une fiche de joueur** | **Non** [C] | `characters` et tables filles : `UPDATE` réservé au propriétaire. Phase 4 (`gm_*`, consentement, journal) ; jamais de policy `UPDATE` élargie |
| Écritures hors ligne mises en file | Non en v1 | Comme le combat mobile. Phase 4 : file locale `nexus_outbox` + RPC idempotentes (`p_request_id`) |

### 2.6 Temps réel pour un client Node local

- **Ce qui marche dès maintenant** [C pour l'existant, D pour Node] : `postgres_changes` sur les 4 tables publiées, avec les
  mêmes filtres que le mobile : `characters` UPDATE `id=in.(...)` (≤ 100 valeurs) ; `group_members` INSERT `group_id=eq` ;
  `group_members` DELETE **sans filtre** (l'ancienne ligne ne porte que `id`, REPLICA IDENTITY DEFAULT : l'outil garde la table
  `membership_id -> group_id` pour filtrer, `group_repository.dart:949-969`) ; `combats`/`combat_participants` `group_id=eq`
  (`combat_repository.dart:244-256`). La RLS est appliquée aux INSERT/UPDATE pour chaque abonné. supabase-js tourne dans le
  processus serveur (Node 24 d'Electron 45, `08` §1) avec son client WebSocket.
- **Usage recommandé** : sur tout événement d'un groupe ouvert, relire `group_snapshot` (anti-rebond ~300 ms), jamais de mise à
  jour construite depuis la charge brute (même principe que le mobile). Un canal par groupe ouvert, fermé à la sortie de
  l'écran.
- **Ce qui manque** : les tables filles ne sont pas publiées. Un équipement (`character_inventory`) ou une montée de niveau
  qui ne touche pas `characters` ne déclenche rien : CA ou niveau périmés jusqu'au prochain rafraîchissement. Atténuation v1 :
  relecture périodique (60 s) tant que l'écran du groupe est ouvert (~2 Ko compressé). Option à étudier (profite aussi au
  mobile) : trigger qui « touche » `characters.updated_at` quand une table fille change (plus d'écritures et d'événements :
  à mesurer).
- **Reprise après coupure** : `postgres_changes` ne rejoue rien. À `SUBSCRIBED` après coupure : relire l'instantané (peu
  coûteux). `events_since` et le Broadcast privé n'arrivent qu'avec la phase 4. Jeton : après un rafraîchissement, le nouveau
  JWT doit être transmis au client Realtime (supabase-js le fait sur `TOKEN_REFRESHED` dans les versions récentes : **[I]**, à
  vérifier par Florian sur la version retenue).
- **Coût** : `postgres_changes` vérifie la RLS par événement et par abonné ; outil + 6 mobiles = 7 abonnés par groupe. Volume
  réel de groupes simultanés inconnu **[I]** (Q-SQL-17/30). La phase 0 réduit le coût des vérifications (initplan, index
  `group_members(user_id)`).

### 2.7 Optimisations « des deux côtés »

**Déjà couvert par la phase 0** (PR #48, branche `feat/api-phase0-hygiene`) [C, état en production **[I]**, Q-SQL-25] :
- `characters.updated_at` tenu à jour par trigger (`20261115090000`) : base du `hash`/`last_character_update` des deux apps ;
- RLS en `(select auth.uid())` sur `characters` et les 4 tables de groupe (`091000`, `091100`) : moins cher pour les lectures de
  groupe **et** pour les vérifications Realtime ;
- index `group_members(user_id)`, `group_members(character_id)`, `groups(owner_id)`, `combat_participants(character_id|user_id)`,
  `combats(started_by)`, `character_*(character_id)` (`092000`, `092100`) : « mes groupes », détail de groupe, cascades ;
- droits `EXECUTE` explicites (`093000`, mis de côté pour l'instant) : `get_group_member_character`, `is_group_member`
  retirés à `anon`, gardés pour `authenticated` : **aucun effet sur l'outil** ;
- CHECK `NOT VALID` (`094000`, mis de côté) : PV/monnaies négatifs refusés (utile aux futures écritures du MJ).

**À livrer AVANT que Florian code la lecture des groupes (lot 3 de `08`)** — contrat figé :
1. `api_v1` (schéma + exposition « Exposed schemas » dans le tableau de bord, action manuelle de Matthias, Q-SQL-23) ;
2. `group_snapshot` + `my_gm_groups` + calcul de CA (D4), pgTAP : propriétaire avec ligne MJ, membre, propriétaire parti,
   tiers, anonyme ;
3. `docs/api-v1/` (même texte dans les deux dépôts) : schéma JSON de l'instantané, codes d'erreur (combat + edge functions),
   liste des **lectures directes autorisées** en attendant (tables, colonnes, filtres Realtime), règles « en ligne seulement ».
Avant que l'outil **enregistre des références** : slugs (B5) et éditions (B6).

**Peut attendre** : Broadcast privé, `game_events`, actions `gm_*`, consentement, `create_group` RPC, `profiles`, recherche
serveur, présence, étiquette d'histoire.

**Pour le mobile ensuite** (phase 5) : remplacer les 6 allers-retours de `fetchGroupDetail` par `group_snapshot` (payload
divisé par ~10 [D]) ; profiter du manifeste pour le cache de référence (aujourd'hui à durée de vie, sans version,
`reference_data_cache.dart:21-35`).

### 2.8 Comptes, profil, suppression, RGPD

- **Fournisseurs** [C, code mobile] : e-mail + mot de passe avec confirmation (`auth_repository.dart:383-400`), Google en OAuth
  web (`redirectTo: 'nexusjdr://login-callback/'`, l.418-421), Apple natif iOS (`signInWithIdToken`, l.510-514, pas encore
  opérationnel faute de compte Apple Developer, l.438-451), mot de passe oublié vers `https://nexus-jdr.app/update-password`
  (l.557-559). Pour l'outil : voir `08` A4-A7 (e-mail + mot de passe d'abord, Google par boucle locale, Apple hors v1). Un
  compte créé avec Google n'a pas de mot de passe : il devra utiliser Google dans l'outil. Répartition réelle : Q-SQL-26.
- **Profil** : `user_metadata.full_name` (pseudo) et `avatar_url` [C] suffisent ; ces métadonnées sont modifiables par
  l'utilisateur : affichage seulement, jamais une base de droit. La table `profiles` (B12) n'est pas nécessaire à la v1.
- **Suppression du compte du MJ** [C] : `delete-account` -> `auth.admin.deleteUser` (`delete-account/index.ts:121-122`) ->
  `groups.owner_id on delete cascade` (`create_groups.sql:12`) : **tous ses groupes sont dissous pour tous les joueurs**, combats
  compris (S11/H10 toujours ouverts). Côté outil : rafraîchissement refusé -> écran de connexion, base locale **jamais**
  supprimée automatiquement (`08` A10) ; liens de campagne passés à `orphan` ; cache des membres de ces groupes purgé à la
  première synchro réussie… qui n'aura plus lieu avec ce compte : prévoir une purge locale du cache distant à la déconnexion
  forcée (décision D11).
- **Suppression du compte d'un joueur** [C] : ses personnages et ses lignes `group_members`/`combat_participants` partent en
  cascade. L'outil en ligne les voit disparaître au prochain instantané ; **hors ligne, la copie locale reste** jusqu'à la
  reconnexion.
- **RGPD (signalé, non tranché, à soumettre à `rgpd`)** : l'outil stockera sur le PC du MJ des données d'autres utilisateurs
  (pseudo, nom et portrait du personnage, PV, états, classe/niveau, CA). Points : minimisation (le résumé de `group_snapshot`,
  jamais la fiche complète en cache) ; durée de conservation hors ligne et purge à la sortie d'un groupe ; base locale non
  chiffrée et sauvegardes quotidiennes (`08` E5) qui multiplient les copies ; exports JSON de l'outil (ne doivent jamais
  contenir ces données, §3.5) ; information des joueurs (aperçu du code, politique de confidentialité qui ne mentionne
  aujourd'hui que Supabase) ; droit à l'effacement inopérant sur une copie hors ligne jusqu'à la reconnexion.

---

## 3. Côté SQLite local (`grimoire-du-mj`)

Propositions de **schéma** seulement (tables/colonnes), en migrations 8 et suivantes du mécanisme existant (`PRAGMA user_version`,
une transaction par migration, `server/db.ts:239-256`), précédées d'une sauvegarde `VACUUM INTO` (`08` E5). Identifiants
distants stockés en `TEXT` (uuid), identifiants locaux inchangés (`nanoid`).

### 3.1 Rattacher la base au compte

- **Une base par compte** (`userData/comptes/<user_id>/grimoire.db`, `08` A8/E4) : aucune colonne « compte » à ajouter dans les
  tables de contenu, isolation par fichier, changement de compte = changement de base.
- Nouvelle table **`app_meta`** (une ligne) : `owner_user_id` (fixé à la première connexion, ensuite immuable),
  `owner_email_at_link` (affichage), `linked_at`, `adopted_from` (chemin/empreinte de la base anonyme adoptée), `schema_backup_at`.
  À l'ouverture : si `owner_user_id` diffère du compte connecté, refuser d'ouvrir (jamais de mélange).
- **Reprise de la base de Florian** : adoption par **copie** (`08` E4), `PRAGMA integrity_check`, puis `owner_user_id` posé ; la
  base d'origine n'est jamais déplacée ni modifiée.
- **La session Supabase n'est jamais dans SQLite** (fichier chiffré `safeStorage`, `08` A2) : une sauvegarde ou une copie de la
  base ne transporte aucun jeton.

### 3.2 Liens campagne ↔ groupe, joueur ↔ personnage, héros ↔ personnage

- **`campaign_links`** : `campaign_id` PK -> `campaigns(id) ON DELETE CASCADE`, `group_id` TEXT NOT NULL (index, non unique :
  un groupe enchaîne plusieurs campagnes), `linked_at`, `status` (`active` | `orphan`), `last_synced_at`. Table séparée plutôt
  que colonnes de `campaigns` : le lien n'entre ni dans les exports ni dans les imports (`server/exchange.ts`) par construction.
- **`player_links`** : `player_id` PK -> `players(id) ON DELETE CASCADE`, `character_id` TEXT NOT NULL **UNIQUE** (un personnage
  distant = un seul joueur local), `user_id` TEXT NOT NULL, `linked_at`, `status` (`active` | `left_group` | `character_deleted`),
  `last_seen_at`. Création possible d'un joueur local **depuis** un personnage distant (nom, niveau, PV max, portrait).
- **Jeton héros ↔ personnage** : aucun lien supplémentaire : les jetons « player » référencent `players.id`
  (`shared/schema.ts:357`), donc le personnage par `player_links`.
- **Lecture superposée plutôt que copie** : ne pas recopier les valeurs distantes dans `players` (chaque `updatePlayer`
  rediffuse toutes les campagnes du joueur, `server/store.ts:328-340`). Le serveur local ajoute à la réponse `Player` un bloc
  `nexus` (`characterId`, `currentHp`, `maxHp`, `temporaryHp`, `isDead`, `conditions`, `armorClass`, `fetchedAt`, `stale`), les
  colonnes locales restent la valeur de repli (hors ligne, lien rompu).
- **PV d'un héros lié** : aujourd'hui le jeton porte les PV actuels, la fiche locale le maximum (`board-ops.ts:84-89`). Si le
  mobile est la source de vérité, les PV affichés d'un héros lié viennent de `nexus.currentHp/maxHp` et la modification depuis
  le jeton est désactivée (ou devient `gm_apply_hp_change` en phase 4). Décision produit D6 (avec Florian).

### 3.3 Cache des données distantes

| Table | Colonnes essentielles | Règle |
|---|---|---|
| `nexus_groups` | `group_id` PK, `name`, `owner_user_id`, `invite_code`, `is_owner`, `has_game_master`, `member_count`, `gm_tool_enabled_at`, `snapshot_hash`, `server_time`, `fetched_at`, `status` (`active`/`gone`) | Remplacé à chaque instantané ; `gone` sur `group_not_found` |
| `nexus_members` | `membership_id` PK, `group_id` -> `nexus_groups ON DELETE CASCADE`, `user_id`, `display_name`, `role`, `is_game_master`, `character_id`, `joined_at` | Les absents de l'instantané sont supprimés |
| `nexus_characters` | `character_id` PK, `owner_user_id`, `name`, `portrait_url`, `portrait_image_id`, `race_name`, `classes_json`, `total_level`, `current_hp`, `max_hp`, `temporary_hp`, `is_dead`, `conditions_json`, `armor_class`, `server_updated_at`, `fetched_at` | Supprimé quand plus aucun membre en cache ne le référence ; jamais la fiche complète |
| `nexus_combats`, `nexus_combat_participants` | dernier état connu (`status`, `round`, participants : `kind`, `name`, `initiative`, `sort_order`, `status`, `character_id`) + `local_ref` (jeton/scénario local publié) | Lecture seule hors ligne ; écritures en ligne |
| `remote_images` | `url` PK, `mime`, `bytes` BLOB, `etag`, `fetched_at` | Portraits téléchargés ; **hors de `assets`**, que le ramasse-miettes viderait (`server/store.ts:1593-1619`) |
| `ref_entities` | (`entity_type`, `entity_id`) PK, `slug` (unique par type quand il existe), `edition`, `source_code`, `name_fr`, `name_en`, `data_json`, `content_hash` | Stockage générique : pas de miroir des ~20 tables de référence |
| `ref_search` | table FTS5 (`name_fr`, `name_en`, `entity_type`) | Recherche locale ; FTS5 dans le SQLite d'Electron : **[I]** |
| `ref_manifest` | `entity_type` PK, `server_hash`, `row_count`, `schema_version`, `fetched_at` | Retéléchargement par type quand l'empreinte change |
| `nexus_sync_state` | `scope` PK (`groups`, `group:<id>`, `reference:<type>`), `hash`, `last_attempt_at`, `last_success_at`, `last_error_code`, `server_time` | Affichage « dernière synchro », reprise |
| `nexus_outbox` (phase 4) | `request_id` PK, `kind`, `payload_json`, `created_at`, `attempts`, `last_error`, `status` | Uniquement avec des RPC idempotentes |

Notifications : nouveau périmètre SSE `nexus` dans `ChangeEvent` (`server/events.ts:8-16`) ; un événement distant ne passe
**jamais** par `emitCampaign`. Portée « écran » de `08` S5 : aucune table `nexus_*` exposée.

### 3.4 Strictement local / publiable plus tard (sans décider)

| Strictement local | Pourrait être publié aux joueurs plus tard (action explicite du MJ, jamais automatique) |
|---|---|
| Toutes les notes « privées du MJ » (`notes` des PNJ, objets, décors, trésors, plateaux), statistiques et PV des PNJ, dialogues et choix, énigmes (solutions, notes), `description`/`playerActions` des étapes, conditions, souvenirs des PNJ sur les joueurs (`memories`), modèles, banque d'images, jetons cachés, imports et contextes IA | `previousSummary` d'un chapitre (« rappel pour les joueurs », `shared/schema.ts:564`), textes à lire (`intro`/`outro`, narrations), fiche publique d'un PNJ (nom, portrait ; la `description` mêle apparence et motivations : un champ public séparé serait nécessaire), objets remis (via butin ou récompense), image d'un plateau en aide de jeu, monstres au combat (nom + initiative, déjà possible) |

Le principe de `05` §2.2 s'applique à toute publication future : un champ publiable n'est jamais un champ qui mélange contenu
public et notes du MJ.

### 3.5 Améliorations du schéma local qui comptent pour l'intégration

| Priorité | Constat [C] | Proposition | Pourquoi maintenant |
|---|---|---|---|
| **1** | Toute écriture de campagne/joueur relit la campagne entière et la rediffuse (`store.ts:251-258,846-931,1485-1529`) | Données distantes dans les tables `nexus_*`, périmètre SSE `nexus`, aucune écriture de `campaigns`/`players` sur un événement distant | Sinon chaque changement de PV d'un joueur recharge toute la campagne sur tous les appareils |
| **1** | Les exports embarquent les joueurs (`exchange.ts:88-92,287-290`) | Exports et imports ignorent `*_links` et `nexus_*` ; jamais d'id distant dans un fichier d'échange | Un fichier partagé ne doit transporter ni lien vers un compte tiers ni donnée de joueur |
| **1** | `memories.player_id ... ON DELETE CASCADE` (`db.ts:42`) | Règle : un événement distant (départ, personnage supprimé) ne supprime **jamais** un joueur local ; il change `player_links.status` | Supprimer le joueur effacerait en cascade les souvenirs des PNJ |
| **1** | Migrations sans sauvegarde préalable (`db.ts:239-256`) | Sauvegarde `VACUUM INTO` avant toute migration (`08` E5) | Les migrations 8+ arrivent avec l'intégration |
| 2 | `campaigns.player_ids` et `chapters.present_player_ids` en JSON (`db.ts:125,137`), parcours complet + `JSON.parse` pour « campagnes de ce joueur » (`store.ts:342-345`) | Tables `campaign_players(campaign_id, player_id, position)` et `chapter_presence(chapter_id, player_id)`, FK en cascade | Requêtes « joueur lié -> campagnes » en SQL et intégrité par FK au lieu du nettoyage ; non bloquant |
| 2 | Portraits distants : `assets` est nettoyé des images non référencées après 1 h (`store.ts:1593-1619`) | `remote_images` séparée (§3.3) | Sinon les portraits en cache disparaissent |
| 3 | `memories.npc_id` sans FK (`db.ts:217-219`) | Gardé : la suppression est gérée par le code (`store.ts:545`) | Aucun lien avec l'intégration |
| 3 | Images en BLOB dans `assets` (`db.ts:172-181`), imports jusqu'à 400 Mo (`app.ts:163`) | Plus tard : fichiers sur disque | Les sauvegardes quotidiennes ×7 multiplient la taille [D] ; non bloquant |

---

## 4. Décisions pour Matthias (ordonnées par blocage)

| # | Décision | Qui | Recommandation par défaut |
|---|---|---|---|
| D1 | **Conflit avec la décision n° 2 du 14/11** : O1, O1 + étiquette, O2, ou maintien (O3) | M (+ F) | **O1**, rédaction de remplacement en §2.2 ; 05 §2.1-2.4 et la phase 2 marqués « abandonnés » |
| D2 | Une base locale par compte et adoption par copie de la base existante de Florian (`08` A8/E4) | M + F | Oui |
| D3 | Contrat de lecture : livrer `group_snapshot`/`my_gm_groups` (phase 1a) **avant** le lot 3 de `08`, ou laisser Florian lire les tables directement en attendant | M | Livrer d'abord (3 à 5 jours) : pas de code à réécrire ensuite |
| D4 | Calcul de la CA : C1 (TypeScript dans l'outil), C2 (fonction SQL, parité testée), C3 (colonne écrite par le mobile) | M ; `regles-dnd`, `qa-testeur` | **C2** |
| D5 | Développement de l'outil sur la **production** (pas de projet de test, décision du 14/11) | M | Comptes et groupes de test dédiés, dissous après usage ; rediscuter R8 avant toute écriture `gm_*` |
| D6 | Source de vérité des PV/états d'un héros lié : la fiche mobile (jeton en lecture) ou le jeton local | M + F | Fiche mobile ; jeton en lecture jusqu'à la phase 4 |
| D7 | Étiquette d'histoire visible des joueurs (option C) : oui/non/quand ; texte côté mobile | M ; `direction-artistique` | Plus tard, avec une version mobile |
| D8 | Copie hors ligne des catalogues : complète (fr + en, ~4-8 Mo) ou à la demande ; slugs (B5) et éditions (B6) confirmés comme prérequis | M | Complète, par empreinte ; B5/B6 oui |
| D9 | Groupes affichés dans l'outil : ceux dont le compte est propriétaire seulement, ou aussi ceux où il joue | M + F | Propriétaire seulement (avec ou sans ligne MJ, signalée) |
| D10 | RGPD du cache local : durée hors ligne, purge à la sortie d'un groupe, information des joueurs, politique de confidentialité | M ; `rgpd` | Avis `rgpd` avant diffusion de l'outil |
| D11 | Compte du MJ supprimé ou session révoquée : purge du cache distant local (oui), contenu local conservé (oui) ; S11/H10 (groupes dissous en cascade) | M ; `rgpd` | Purge du cache, contenu gardé ; H10 inchangée |
| D12 | Butin avant la phase 4 : autoriser l'outil à écrire `group_treasure` (écriture absolue, course connue) | M | Non, ou seulement ajout de monnaie, en attendant une RPC delta |
| D13 | Publication de contenu vers les joueurs (O4) : jamais, ou plus tard | M + F | Plus tard, sur demande explicite |
| D14 | Exposition de `api_v1` (schéma exposé, réglage manuel) ou fonctions préfixées dans `public` | M | `api_v1` (cohérent avec 05) |

Questions de `06` qui restent ouvertes et redeviennent bloquantes plus tard : B1 (historique des migrations), A1-A12 (phase 4),
H6, H10, R1-R4.

---

## 5. Ordre des travaux côté base (garde-fous de `00` : additives, idempotentes, rejeu jetable ×2, `--dry-run`, une à la fois)

| Étape | Contenu | Dépend de | Taille | Effet sur le mobile publié |
|---|---|---|---|---|
| 0 | Terminer la phase 0 (PR #48) : `093000`, `094000`, puis le fichier différé `validate_checks` renommé | en cours | - | aucun |
| 1 | Documentation : décision D1 consignée dans `00` ; `05`/`06`/`07` annotés « remplacé par 09 » | D1 | - | aucun |
| 2 | **Phase 1a « lecture outil »** : schéma `api_v1` + droits ; fonction de CA (si C2) ; `group_snapshot` ; `my_gm_groups` ; pgTAP (propriétaire avec/sans ligne MJ, membre, tiers, anonyme, propriétaire parti) ; `docs/api-v1/` | 0, D3, D4, D14 | S-M | aucun |
| 3 | **Phase 1b « références »** : `slug` (colonne nullable, remplissage contrôlé, index unique), `sources`/`edition` (classification `regles-dnd`), `reference_manifest`, `reference_export` | 2, D8 | M | aucun |
| 4 | **Phase 2' « lien outil »** (facultative) : étiquette sur `groups` (CHECK de longueur `NOT VALID`), `create_group` RPC + `api_v1_requests` si les doublons gênent | D7 | S | aucun (colonnes nullables) |
| 5 | **Phases 3+4 fusionnées** : `game_events`, Broadcast privé, `gm_tool_enabled_at`, consentement, `gm_*`, RPC butin en delta, `add_npc_participants_batch`, `advance_turn` | `regles-dnd`, `rgpd`, A1-A12, rediscussion R8 | L | léger (événements, consentement à afficher) |
| 6 | Phase 5 mobile (instantané, deltas), archivage du legacy, nettoyage | 5 | L | version à publier |

Horodatages : strictement postérieurs à la dernière migration appliquée **et** au nom final du fichier différé de la phase 0
(appliquer `validate_checks` avant de numéroter la phase 1a évite toute collision). Chaque migration : retour arrière en
commentaire, contrôle en lecture seule avant/après (§6).

---

## 6. Requêtes de contrôle, en lecture seule (production `nexus-jdr (beazvozraxvcbymbxumb)`)

Agrégats ou noms d'objets seulement. Avant l'étape 2 : Q-25, Q-30, Q-31, Q-32 et Q-SQL-23 de `06`. Après : Q-25, Q-32
(avec les fonctions `api_v1`), Q-SQL-23.

```sql
-- Q-SQL-25 : état de la phase 0 et trigger updated_at
select version, name from supabase_migrations.schema_migrations where version >= '20261114000000' order by version;
select tgname, tgenabled from pg_trigger where tgrelid = 'public.characters'::regclass and not tgisinternal order by 1;

-- Q-SQL-26 : fournisseurs d'authentification (complète Q-SQL-14)
select provider, count(distinct user_id) as comptes from auth.identities group by 1 order by 2 desc;
select count(*) as comptes_multi_fournisseurs
  from (select user_id from auth.identities group by user_id having count(distinct provider) > 1) x;

-- Q-SQL-27 : groupes, MJ « dans l'app », taille des groupes
select count(*) as groupes,
       count(*) filter (where exists (select 1 from public.group_members m
                         where m.group_id = g.id and m.user_id = g.owner_id and m.is_game_master)) as avec_mj_app,
       count(*) filter (where not exists (select 1 from public.group_members m
                         where m.group_id = g.id and m.user_id = g.owner_id)) as proprietaire_sans_ligne
  from public.groups g;
select max(n) as membres_max, round(avg(n), 1) as membres_moy
  from (select group_id, count(*) as n from public.group_members group by 1) x;
select count(*) as proprietaires_multi_groupes from (select owner_id from public.groups group by 1 having count(*) > 1) x;

-- Q-SQL-28 : poids d'une fiche (charge actuelle vs résumé)
select pg_size_pretty(avg(pg_column_size(c.*))::bigint) as ligne_moy, pg_size_pretty(max(pg_column_size(c.*))::bigint) as ligne_max
  from public.characters c;
select round(avg(n), 1) as objets_moy, max(n) as objets_max
  from (select character_id, count(*) as n from public.character_inventory group by 1) x;

-- Q-SQL-29 : volume du catalogue de référence (copie hors ligne)
select entity_type, locale, count(*) as lignes, pg_size_pretty(sum(octet_length(value))::bigint) as texte
  from public.translations group by 1, 2 order by 1, 2;
select 'creatures' as t, count(*), pg_size_pretty(sum(pg_column_size(x.*))::bigint) from public.creatures x
union all select 'spells', count(*), pg_size_pretty(sum(pg_column_size(x.*))::bigint) from public.spells x
union all select 'items', count(*), pg_size_pretty(sum(pg_column_size(x.*))::bigint) from public.items x
union all select 'class_features', count(*), pg_size_pretty(sum(pg_column_size(x.*))::bigint) from public.class_features x;

-- Q-SQL-30 : Realtime (tables publiées, identité de réplique) ; voir aussi Q-SQL-17
select tablename from pg_publication_tables where pubname = 'supabase_realtime' order by 1;
select relname, relreplident from pg_class
 where relnamespace = 'public'::regnamespace
   and relname in ('characters', 'group_members', 'combats', 'combat_participants') order by 1;

-- Q-SQL-31 : politiques lues par l'outil (production = dépôt ?)
select tablename, policyname, cmd, roles::text from pg_policies
 where schemaname = 'public'
   and tablename in ('groups', 'group_members', 'group_treasure', 'characters', 'character_classes', 'character_ability_scores',
                     'character_inventory', 'character_class_options', 'combats', 'combat_participants')
 order by 1, 2;

-- Q-SQL-32 : droits d'exécution des fonctions appelées par l'outil
select p.proname, pg_get_function_identity_arguments(p.oid) as args,
       has_function_privilege('authenticated', p.oid, 'execute') as authenticated,
       has_function_privilege('anon', p.oid, 'execute') as anon
  from pg_proc p
 where p.pronamespace = 'public'::regnamespace
   and p.proname in ('start_combat', 'end_combat', 'set_participant_initiative', 'add_npc_participants', 'remove_participant',
                     'reorder_participant', 'set_my_initiative', 'get_group_member_character', 'group_members_display_name',
                     'claim_group_treasure_currency')
 order by 1;

-- Q-SQL-33 : qualité des données lues par l'outil
select count(*) as total, count(*) filter (where jsonb_array_length(conditions) > 0) as avec_etats,
       count(*) filter (where max_hp = 0) as max_hp_zero, count(*) filter (where current_hp > max_hp) as pv_au_dessus_du_max
  from public.characters;

-- Q-SQL-34 : butin des groupes (décision D12)
select count(*) as groupes, count(*) filter (where jsonb_array_length(items) > 0) as avec_objets,
       max(jsonb_array_length(items)) as objets_max
  from public.group_treasure;
```

Vérifications **dans le tableau de bord** (pas en SQL) : Authentication > URL Configuration > Redirect URLs (retour de
l'outil, `08` A5) ; Authentication > Sessions (durée maximale, inactivité : conditionne le hors ligne, `08` A9) ; API >
Exposed schemas (`api_v1`) ; Realtime : quotas du plan.

---

## 7. Ce que je n'ai pas pu vérifier

- **État réel de la production** : migrations de la phase 0 effectivement appliquées (seul indice : deux fichiers mis de côté
  dans le worktree), fournisseurs réellement utilisés, nombre de groupes et taille réelle, groupes dont le propriétaire n'a pas
  de ligne MJ, politiques et droits identiques au dépôt, URL de redirection et réglages de session, schémas exposés, quotas
  Realtime, volume réel des traductions (Q-25 à Q-34, Q-SQL-17/23 de `06`).
- Comportement de supabase-js en Node sur la durée : transmission du jeton rafraîchi au client Realtime, rotation du jeton de
  rafraîchissement avec deux instances (atténué par le verrou d'instance de `08` E2).
- Disponibilité de **FTS5** dans le SQLite embarqué par Electron 45 / Node 24.
- Coût réel du manifeste calculé à la volée et taille réelle de l'instantané (estimations [D]).
- Parité d'une CA calculée en SQL avec `ArmorClassCalculator` : seule l'en-tête du calculateur (l.1-70) a été lue.
- `preview-group-invite` et `set-group-character` non relus pour cette étape (aucun impact attendu : l'outil ne les appelle pas).
- Accord de Florian sur tout ce qui concerne son dépôt (tables locales, lecture superposée, source de vérité des PV) : ce sont
  des propositions, pas des décisions.
