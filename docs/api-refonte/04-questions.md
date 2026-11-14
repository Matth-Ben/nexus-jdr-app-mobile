# 04 - Questions a trancher et requetes de controle en lecture seule

Date : 14/11/2026. Aucune de ces decisions n'est prise par l'agent SQL/API ; chaque question porte une **recommandation par defaut** (a infirmer librement).

## 1. Decisions pour Matthias (produit, perimetre, priorites)

| # | Question | Pourquoi maintenant | Recommandation par defaut |
|---|---|---|---|
| Q1 | **Perimetre de l'etape 2** : Phase 0 seule (hygiene, invisible), ou Phase 0 + 1 (squelette `api_v1`) ? | Phase 0 est sans risque et rentable (index, RLS, CHECK) ; la suite est un engagement long | Phase 0 d'abord, en une PR web revue par `code-reviewer`, puis decision sur la suite |
| Q2 | **Option d'architecture** : A (api_v1 hybride), B (RPC seules) ou C (PostgREST renforce) ? | Conditionne tout le reste (03, section 1) | **A hybride** |
| Q3 | **Histoire et Groupe** : quel modele (U1 groupe = table de jeu, U2, U3) et quelle cardinalite : une histoire = un seul groupe actif, ou plusieurs ? | Bloque X03/N01 | U1 ; un groupe actif par histoire, plusieurs groupes historiques autorises |
| Q4 | Cas aujourd'hui incompatibles entre les deux modeles : (a) plusieurs personnages d'un meme joueur dans une histoire (`character_campaigns`) contre un seul par groupe ; (b) personnages `pnj` du MJ ; (c) MJ **avec** personnage (web) contre MJ **sans** personnage (mobile) | A trancher avant d'ecrire le trigger de synchronisation | (a) un personnage actif par joueur et par table, les autres « en reserve » ; (b) PNJ = ressource du MJ separee (`table_npcs`), pas des membres ; (c) autorise des deux cotes |
| Q5 | **Que doit voir le MJ de la fiche d'un joueur ?** Aujourd'hui le MJ d'histoire lit 16 tables (inventaire, sorts, PV par niveau...) sauf journal/photos/choix de race ; le MJ de groupe en lit 5 | S05 : droit tres large non borne | Vue `character_gm_view` : etat de jeu (PV, CA, conditions, emplacements, inventaire, sorts), **sans** journal prive, notes et fond (`backstory`) tant que le joueur n'a pas choisi de les partager |
| Q6 | **Le MJ peut-il agir sur une fiche sans l'accord du joueur ?** (degats, effets) | Fonde X01 | Oui pour PV delta, conditions, objets donnes ; journalise et visible du joueur. Non pour tout le reste |
| Q7 | **Temps reel : quelles donnees en direct ?** PV/etats/combat sont deja couverts ; tresor, journaux, notes ? | RT05 | PV, effets, combat, membres, recompenses ; tresor oui ; notes/journaux personnels non |
| Q8 | **Montee de niveau et recompenses** : le MJ « accorde » (le joueur accepte et choisit) ou « applique » ? XP/or appliques directement ? | X05, Phase 2 | Accorder -> acceptation ; XP et or appliques directement (journalises) ; niveau toujours accepte par le joueur |
| Q9 | **Suppression du compte du MJ** : aujourd'hui `groups.owner_id on delete cascade` dissout le groupe de tous | S11 | Transfert de propriete a un autre membre, sinon archivage lecture seule |
| Q10 | **Edition 2014/2024** : une colonne `edition` sur chaque table de contenu + table `sources`, ou filtrage au niveau du personnage seulement (`characters.edition` existe) ? | D01-D03 | Colonnes `edition` + `source_code` + table `sources` ; catalogues filtres par edition du personnage |
| Q11 | **Politique de versions** : quand relever `app_versions.min_supported_version` pour couper l'acces direct ancien (Phase 6) ? Combien de versions mobiles simultanees maintenir ? | Phase 6 | Au moins 2 versions de store apres la bascule 5a ; pas de coupure avant que 90 % des appareils actifs aient migre (mesure a definir) |
| Q12 | **Photos et portraits** : buckets publics a URL previsible : acceptable ? | S13 | Portraits publics acceptes ; photos de galerie en URL signees |
| Q13 | **Boite a idees (`content_proposals`, votes, commentaires)** : garder pour une fonctionnalite future ou archiver ? | M02, 3 tables mortes | Garder (cout nul), documenter comme reservee |
| Q14 | **Donnees RGPD des evenements** : un journal d'actions MJ contient des donnees liees a des utilisateurs ; duree de conservation et anonymisation a la suppression de compte ? | Phase 2 | 12 mois glissants ; anonymisation de `actor_id` ; a valider par l'agent `rgpd` |
| Q15 | **Environnements** : dev, staging et prod partagent le meme projet Supabase (D06). La refonte doit-elle imposer un projet de test separe avant les Phases 2+ ? | Risque de tester sur de vraies donnees | Oui pour les Phases 2+ ; Phase 0 acceptable avec `--dry-run` + sauvegarde |
| Q16 | **Priorite relative** de cette refonte face a la roadmap mobile (rituels P3b, combat V2) | Capacite | A decider par Matthias ; le combat V2 (`advance_turn`) peut etre livre directement en `api_v1` |

## 2. Decisions pour Florian (app web) - tout est **a valider avec Florian**

| # | Question | Recommandation par defaut |
|---|---|---|
| F1 | Accepte-t-il d'ajouter Realtime (Broadcast prive) dans l'app web (panneau « Joueurs » et vue de session) ? `TODO.md:50` le liste deja comme non fait | Oui, via un petit module partage dans `packages/supabase-client` |
| F2 | Accepte-t-il de ne plus ecrire `updated_at` cote client pour `stories`/`codex_entries` (`story/[id]/actions.ts:82,108,163` ; `codex/actions.ts:211,289`) quand un trigger le fera ? | Oui (inoffensif : le trigger ecrase la meme valeur) |
| F3 | Accepte-t-il que la ligne `stories` complete ne soit plus lisible par les joueurs (S01) ? Aucun impact web (la policy ne sert qu'au mobile) | Oui |
| F4 | `story/[id]/page.tsx:13` fait `select("*")` sur `stories` (contenu long) : accepte-t-il de restreindre les colonnes et de sortir `content` a terme ? | Oui, par etapes |
| F5 | Panneau « Joueurs » : accepte-t-il de lire `api_v1.table_members` (groupe + histoire) plutot que `character_campaigns` ? | Oui apres Phase 4 |
| F6 | Le MJ web doit-il pouvoir lancer un combat, appliquer des degats, accorder niveaux et recompenses (parcours 7.2) ? Quelle interface ? | Oui ; ecrans a concevoir ensemble ; la base fournit les RPC |
| F7 | Le bestiaire (`creatures`, 331 fiches SRD 5.2 non utilisees) doit-il alimenter le codex du MJ ? | Oui, en lecture via `api_v1.creatures` |
| F8 | Frontiere de responsabilite : qui releve les migrations qui touchent le web, et qui maintient `packages/supabase-client` ? | Un seul historique de migrations (depot web) ; PR relues par les deux |

## 3. Requetes de controle en LECTURE SEULE a faire lancer par Matthias sur la production

A lancer dans l'editeur SQL du projet `nexus-jdr (beazvozraxvcbymbxumb)` **en lecture seule** (rien ne modifie l'etat) ; tous les resultats sont des **agregats ou des noms d'objets**, sans donnee personnelle. Coller les resultats dans la conversation. Si un classificateur bloque une requete, la lancer seul et en coller le resultat. Rien n'est a executer avant ni apres une migration autrement que ces `select`.

### Q-SQL-1 - Version, extensions, parametres

```sql
select version();
select extname, extversion from pg_extension order by 1;
select name, setting from pg_settings
 where name in ('wal_level','max_replication_slots','max_wal_senders','max_connections','shared_buffers','work_mem');
select rolname, rolconfig from pg_roles where rolname = 'authenticator';   -- schemas exposes (pgrst.db_schemas)
```

### Q-SQL-2 - Volumetrie reelle (decide les index, le plan de charge, le cout Realtime)

```sql
select relname, n_live_tup,
       pg_size_pretty(pg_total_relation_size(relid)) as taille
  from pg_stat_user_tables where schemaname = 'public'
 order by pg_total_relation_size(relid) desc limit 30;

select (select count(*) from auth.users)                  as utilisateurs,
       (select count(*) from public.characters)           as personnages,
       (select count(*) from public.groups)               as groupes,
       (select count(*) from public.group_members)        as membres,
       (select count(*) from public.stories)              as histoires,
       (select count(*) from public.character_campaigns)  as rattachements,
       (select count(*) from public.combats)              as combats;
```

### Q-SQL-3 - Index reels et cles etrangeres sans index (confirme P01)

```sql
select c.conrelid::regclass::text as table_fk, a.attname as colonne,
       c.confrelid::regclass::text as table_cible
  from pg_constraint c
  join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
 where c.contype = 'f' and c.connamespace = 'public'::regnamespace
   and not exists (select 1 from pg_index i
                    where i.indrelid = c.conrelid and i.indkey[0] = c.conkey[1])
 order by 1, 2;                                  -- attendu d'apres les migrations : 67 lignes

select schemaname, relname, indexrelname, idx_scan
  from pg_stat_user_indexes where schemaname = 'public'
 order by idx_scan asc, relname limit 60;        -- index jamais utilises / index manquants deduits
select count(*) as nb_index from pg_indexes where schemaname = 'public';   -- attendu : 97
```

### Q-SQL-4 - Politiques, fonctions, tables : ecart avec les migrations

```sql
select count(*) as nb_policies from pg_policies where schemaname = 'public';   -- attendu : 278
select tablename, policyname, cmd, roles from pg_policies
 where schemaname = 'public' order by 1, 2;     -- a comparer a annexes/policies_hors_reference.txt

select count(*) as nb_tables from pg_tables where schemaname = 'public';       -- attendu : 64
select tablename from pg_tables where schemaname = 'public' order by 1;
select count(*) as nb_colonnes from information_schema.columns where table_schema = 'public';  -- attendu : 442

select p.proname, pg_get_function_identity_arguments(p.oid) as args,
       p.prosecdef as definer, p.proconfig, p.proacl::text
  from pg_proc p where p.pronamespace = 'public'::regnamespace
 order by 1;                                    -- attendu : 40 fonctions ; comparer a annexes/fonctions.txt
select tgrelid::regclass::text, tgname from pg_trigger
 where not tgisinternal and tgrelid::regclass::text like 'public.%' order by 1, 2;   -- attendu : 9
```

### Q-SQL-5 - Droits par defaut et GRANT effectifs (confirme S06, S07)

```sql
select defaclrole::regrole::text as proprietaire, defaclnamespace::regnamespace::text as schema,
       defaclobjtype, defaclacl::text from pg_default_acl;

select grantee, privilege_type, count(*) as nb_tables
  from information_schema.role_table_grants
 where table_schema = 'public' and grantee in ('anon','authenticated','service_role')
 group by 1, 2 order by 1, 2;

select table_name, privilege_type from information_schema.role_table_grants
 where table_schema = 'public' and grantee = 'anon' and privilege_type <> 'SELECT'
 order by 1 limit 80;                           -- tables ou anon a plus que SELECT (masque par la RLS)
```

### Q-SQL-6 - Realtime : publication, identite de replique, version du serveur

```sql
select schemaname, tablename from pg_publication_tables where pubname = 'supabase_realtime' order by 2;
select relname, relreplident from pg_class
 where relnamespace = 'public'::regnamespace and relkind = 'r' and relreplident <> 'd';
select tablename, policyname, cmd from pg_policies where schemaname = 'realtime';      -- canaux prives existants ?
select * from realtime.schema_migrations order by version desc limit 5;                -- version du serveur Realtime
```

### Q-SQL-7 - Taches planifiees, secrets (noms seulement), buckets

```sql
select jobid, jobname, schedule, active from cron.job order by 1;
select name from vault.secrets order by 1;                       -- noms seulement, jamais decrypted_secret
select id, public, file_size_limit, allowed_mime_types from storage.buckets order by 1;
select tablename, policyname, cmd from pg_policies where schemaname = 'storage' order by 1, 2;
```

### Q-SQL-8 - Donnees de reference : edition, source, orphelins

```sql
select source, count(*) from public.spells  group by 1 order by 2 desc;
select source, count(*) from public.items   group by 1 order by 2 desc;
select source, count(*) from public.races   group by 1 order by 2 desc;
select edition, count(*) from public.class_features group by 1;
select entity_type, count(*) as orphelines
  from public.translations t
 where (entity_type = 'spell' and not exists (select 1 from public.spells s where s.id::text = t.entity_id))
    or (entity_type = 'item'  and not exists (select 1 from public.items i where i.id::text = t.entity_id))
    or (entity_type = 'class' and not exists (select 1 from public.classes c where c.id::text = t.entity_id))
    or (entity_type = 'race'  and not exists (select 1 from public.races r where r.id::text = t.entity_id))
    or (entity_type = 'feat'  and not exists (select 1 from public.feats f where f.id::text = t.entity_id))
 group by 1;
```

### Q-SQL-9 - Integrite des donnees utilisateur (avant d'ajouter des contraintes)

```sql
select 'classes en double' as controle, count(*) from (
  select character_id, class_id from public.character_classes group by 1, 2 having count(*) > 1) x
union all select 'persos avec 2 classes principales', count(*) from (
  select character_id from public.character_classes where is_primary group by 1 having count(*) > 1) x
union all select 'persos sans classe principale', count(*) from public.characters c
  where not exists (select 1 from public.character_classes k where k.character_id = c.id and k.is_primary)
union all select 'valeurs negatives (PV/XP/monnaies)', count(*) from public.characters
  where current_hp < 0 or temporary_hp < 0 or xp < 0
     or currency_gp < 0 or currency_pp < 0 or currency_ep < 0 or currency_sp < 0 or currency_cp < 0
union all select 'PV courants > PV max', count(*) from public.characters where current_hp > max_hp
union all select 'tresor de groupe negatif', count(*) from public.group_treasure
  where currency_gp < 0 or currency_pp < 0 or currency_ep < 0 or currency_sp < 0 or currency_cp < 0
union all select 'characters.updated_at = created_at', count(*) from public.characters where updated_at = created_at
union all select 'total characters', count(*) from public.characters;
```

### Q-SQL-10 - Invariants du modele Histoire / Groupe (decide U1)

```sql
select 'groupes avec campaign_id renseigne' as controle, count(*) from public.groups where campaign_id is not null
union all select 'histoires avec joueurs rattaches', count(distinct story_id) from public.character_campaigns
union all select 'rattachements role pnj', count(*) from public.character_campaigns where role = 'pnj'
union all select 'joueur avec 2+ persos dans la meme histoire', count(*) from (
  select cc.story_id, c.owner_id from public.character_campaigns cc
  join public.characters c on c.id = cc.character_id
  where cc.role = 'joueur' group by 1, 2 having count(*) > 1) x
union all select 'membres dont le perso n''appartient pas a user_id', count(*) from public.group_members gm
  join public.characters c on c.id = gm.character_id where c.owner_id <> gm.user_id
union all select 'utilisateurs MJ d''histoire ET proprietaires de groupe', count(*) from (
  select user_id from public.stories intersect select owner_id from public.groups) x
union all select 'groupes sans MJ dans l''app', count(*) from public.groups g
  where not exists (select 1 from public.group_members m
                     where m.group_id = g.id and m.user_id = g.owner_id and m.is_game_master);
```

### Q-SQL-11 - Gabarit de comparaison « double lecture » (a rejouer apres chaque phase)

```sql
-- Exemple : meme liste de membres par l'ancien chemin (a adapter a chaque ressource)
select count(*) from public.group_members;
-- puis, apres Phase 1/4 : select count(*) from api_v1.table_members;  -- doit etre egal
```

### Q-SQL-12 - Charge reelle des requetes (si `pg_stat_statements` est active)

```sql
select left(query, 120) as requete, calls, round(mean_exec_time::numeric, 2) as ms_moy,
       round(total_exec_time::numeric, 0) as ms_total
  from pg_stat_statements
 order by total_exec_time desc limit 25;        -- optionnel ; requetes normalisees, sans parametres
```

### Q-SQL-13 - Contenu du MJ lisible par les joueurs (mesure l'impact de S01)

```sql
select count(*) as histoires, count(*) filter (where length(content) > 0) as avec_contenu,
       pg_size_pretty(sum(length(content))::bigint) as volume
  from public.stories;
select count(distinct s.id) as histoires_ayant_des_joueurs
  from public.stories s join public.character_campaigns cc on cc.story_id = s.id;
```

## 4. Ce que cette etape n'a PAS pu verifier

1. **Toute l'etat reel de la production** : index/policies/fonctions ajoutes ou retires hors migrations (precedents D58 et D72), `pg_default_acl`, tables effectivement publiees, version de Postgres et de Realtime, extensions, jobs cron, contenu du Vault, volumetrie, plan d'abonnement et quotas. Les requetes ci-dessus sont la liste exacte de ce qu'il faut lire.
2. **Comportement serveur de Realtime** (limite `in` a 100 valeurs, cout de l'evaluation RLS par abonne, disponibilite de `broadcast_changes` et des canaux prives) : pris dans la documentation Supabase, non mesure.
3. **Mapping PostgREST des SQLSTATE vers HTTP** (en particulier `PT409`, `PT429`) : a valider par un test avant d'etre fige dans le contrat.
4. **Plans d'execution et temps de reponse** : raisonnes sur le schema ; aucun jeu de donnees utilisateur dans le rejeu.
5. **`packages/supabase-client` et `packages/core` du monorepo web**, les tests Deno des edge functions (non executes), l'execution reelle des edge functions.
6. **Edge functions `preview-*`** : politique d'authentification (aucun `verify_jwt` configure dans `config.toml`) non verifiee en production.
7. **Rejeu local** : `pg_net` et `pg_cron` simules par des stubs ; Auth, Storage, Vault simules ; les `GRANT` observes sur `anon` dans mon rejeu sont pollues par mes privileges par defaut de stub (voir S06).
8. Aucune verification des regles D&D (hors perimetre ; a router vers `regles-dnd`).
