# 06 - Questions révisées (décisions à trancher) et requêtes de contrôle complémentaires

Date : 14/11/2026. Remplace `04-questions.md` pour le modèle révisé (`05-revision-propositions.md`) ; les requêtes Q-SQL-1 à 13 de `04` restent valables, les nouvelles portent les numéros 14 à 24. Aucune décision n'est prise par l'agent SQL/API : chaque ligne a une **recommandation par défaut**. « Qui » : **M** = Matthias, **F** = Florian, **M+F** = les deux, **CP** = chef de projet, avec l'agent à consulter si besoin.

Classement par **ordre de blocage** : bloc B (bloque la phase 1, contrat figé), H (phase 2 : histoire), A (phase 4 : actions MJ), R (temps réel, phase 3), L (legacy), M (mobile, phases 5-7). Les questions 1 à 4 du bloc B bloquent aussi **tout** début de travail de Florian sur un projet réel.

## Bloc B - Bloque la phase 1

| # | Question | Qui | Recommandation par défaut |
|---|---|---|---|
| B1 | **Où vit l'historique de migrations** ? La règle de mission dit « un seul historique dans le dépôt web », or ce dépôt est gelé. | M+F | Rester dans `markdown-editor/supabase/migrations/` (160 fichiers, harnais pgTAP, CI) jusqu'à ce que le dépôt de l'outil neuf existe ; puis déplacer `supabase/` en préservant l'ordre des timestamps. Une seule source, jamais deux |
| B2 | L'outil de Florian utilise-t-il bien **le même projet Supabase et les mêmes fournisseurs d'authentification** que le mobile ? Quel hébergement (web, bureau avec `apps/desktop`, autre) ? URL de redirection/CORS à déclarer ? | F | Oui, même projet et mêmes comptes ; `supabase-js` avec clé publique + JWT utilisateur, jamais `service_role` côté client. Requête 14 pour connaître les fournisseurs |
| B3 | **Projet Supabase de test/dev séparé** avant que quiconque écrive un appel d'API (aujourd'hui dev/staging/prod = un seul projet, D06) ? | M | **Oui, bloquant** pour Florian et pour les phases 2+. Phase 0 acceptable avec `--dry-run` + sauvegarde. Le choix (nouveau projet, branche Supabase) et son coût sont à décider par Matthias |
| B4 | **Nommage** : `adventures` (tables) exposées comme ressource `story` (`api_v1.stories`) ? `stories` existe déjà (legacy gelée). | M+F | `adventures` + `adventure_*` en base ; `story` dans l'API et l'outil ; « histoire » pour les utilisateurs |
| B5 | **Clés stables de référence** : ajouter `slug unique` sur creatures, items, spells, classes, races, feats, backgrounds avant que l'outil ne stocke des références ? | M (agent : `dev-backend-supabase`) | Oui, phase 1, par migration additive ; le slug est le contrat, l'`id` entier n'est pas garanti stable si les seeds sont rejoués |
| B6 | **Éditions et sources** : table `sources` + `edition`/`source_code` sur les tables de contenu ; qui classe chaque `source` texte libre en 2014/2024 ? | M ; `regles-dnd` pour la classification | Oui ; classification proposée par l'agent, validée par `regles-dnd` ; défaut de filtre = édition de l'histoire/du personnage |
| B7 | **Cardinalité histoire <-> groupes** : K1 (histoire 0..N groupes, groupe 0..1 histoire), K2 (1:1) ou K3 (N:M) ? | M | **K1**, avec liaison par RPC (la cardinalité reste masquée du contrat) |
| B8 | Schéma d'API : `api_v1` exposé ; versionnage ; emplacement du contrat (`docs/api-v1/`, même texte dans les deux dépôts) ; qui règle « Exposed schemas » en production ? | M | Oui ; action manuelle de Matthias, vérifiée par la requête 23 |
| B9 | **Lecture de la référence** : rester ouverte à `anon` (SRD) ou la réserver à `authenticated` pour l'API ? | M | Rester ouverte (aucune donnée personnelle, aucun changement de comportement) ; revoir si une licence l'exige |
| B10 | **Périmètre et priorité** : phase 0 seule ? 0+1 ? Priorité face à la roadmap mobile (rituels, combat V2) ? Le combat V2 (`advance_turn`) est-il livré directement dans `api_v1` ? | M | 0 puis 1 ; `advance_turn` directement en `api_v1` (phase 4) |
| B11 | **Calendrier** de l'outil de Florian et date visée pour les premières séances avec groupe lié | F | Conditionne l'ordre 2 || 3 ; à donner avant de planifier la phase 2 |
| B12 | **Profils** : table `profiles(user_id, display_name, avatar_path)` publique minimale (au lieu de lire `auth.users.raw_user_meta_data`, S09) ? | M ; `rgpd` | Oui, lisible par les membres d'un même groupe/histoire seulement |
| B13 | **Types TypeScript** : générés (`supabase gen types`) et committés dans le dépôt de Florian ? Chaque RPC renvoie un type composite nommé (pas de `jsonb` non documenté) ? | F | Oui aux deux |

## Bloc H - Phase 2 : histoire

| # | Question | Qui | Recommandation par défaut |
|---|---|---|---|
| H1 | **Modèle de spoilers** : contenu montrable séparé des secrets (`adventure_entries` / `adventure_entry_secrets`), révélation **par groupe** | M+F | Oui (jamais de colonne secrète dans une table lisible par un joueur) |
| H2 | **Format du contenu** (`body_*`) : markdown ou document structuré (JSON d'éditeur) ? Taille maximale ? | F | `text` markdown + colonne `body_format` ; borne ~200 ko |
| H3 | **Types d'entrées** (`npc, location, faction, quest, handout, note, scene, map`) et schéma d'`attributes` par type | F | Liste en table `story_entry_kinds`, schémas versionnés, extensible sans migration |
| H4 | **Cartes et fichiers** : bucket privé `adventure-assets`, URL signées 60 s, types MIME, taille max, quota par histoire | M+F | Privé + signé ; images <= 10 Mo ; quota par histoire à fixer d'après le plan Supabase (requête 18) |
| H5 | **Plafond de groupes par histoire** | M | 10 (`group_limit_reached`) |
| H6 | **Code d'invitation** : rotation, désactivation (`groups.invite_enabled`), expiration ; l'edge `join-group` (dépôt gelé) doit lire le drapeau | M | Rotation + désactivation oui, expiration non en v1 ; modification de `join-group` = PR sur le dépôt gelé relue par Matthias |
| H7 | **Lier après coup** un groupe mobile existant à une histoire (`link_group_to_story`) | M | Oui, sans aucun pouvoir sur les fiches avant consentement individuel (A7) |
| H8 | **Transfert de propriété** d'une histoire / d'un groupe (en deux temps, le nouveau MJ accepte) | M | Oui ; groupes déliés par défaut, `p_with_groups` optionnel |
| H9 | **Suppression d'une histoire liée** : refus tant que des groupes y sont liés, sauf `p_unlink` ; archivage par défaut ; groupes toujours conservés | M | Oui |
| H10 | **Suppression de compte du MJ** (S11 / Q9) : aujourd'hui le groupe de tous est dissous (cascade). Cible : transfert au membre le plus ancien sinon archivage lecture seule ; l'edge `delete-account` doit être adaptée | M ; `rgpd` | Transfert/archivage ; `adventures.owner_id` en `restrict` |
| H11 | **Co-MJ** | M | Pas en v1 ; extension prévue (`adventure_members`, `is_group_gm`) |
| H12 | **Contenu maison** (monstres, objets) : tables `custom_*` séparées, bibliothèque personnelle (`adventure_id` null) ou par histoire, pas de partage entre MJ en v1 | M+F | Oui |
| H13 | **Monstres cachés dans le combat** : un PNJ non révélé disparaît de l'écran du mobile publié (changement de comportement visible) | M | Accepter ; lignes existantes `revealed = true` (aucun changement pour l'historique) |
| H14 | **Aperçu du code** (`preview-group-invite`) : indiquer « groupe lié à une histoire » + titre et la clause « le MJ peut modifier votre personnage » | M ; `rgpd` | Oui (champ additif ignoré par l'ancien mobile) |

## Bloc A - Phase 4 : actions MJ

| # | Question | Qui | Recommandation par défaut |
|---|---|---|---|
| A1 | **Portée du droit d'écriture du MJ sur une fiche** (ex-Q6) | M | Uniquement groupe **lié** + personnage membre actif + consentement ; jamais de policy `UPDATE` élargie ; combat inchangé (tout propriétaire de groupe) |
| A2 | **Accorder** (le joueur accepte) ou **appliquer** (immédiat), par genre : xp, currency, item, inspiration | M | `grant` par défaut ; `apply` autorisé pour xp, currency, item, inspiration ; interdit pour `level_up` ; table `grant_kinds.allow_apply` modifiable sans migration de code |
| A3 | **Montée de niveau** : toujours acceptée par le joueur, qui fait ses choix via `apply_level_up` ; que se passe-t-il si le niveau cible est déjà atteint (`grant_obsolete`) ? | M ; `regles-dnd` | Oui ; récompense `level_up` clôturée par `apply_level_up(…, p_grant_id)` |
| A4 | **Règles de dégâts/soins** appliquées en base (PV temp, plancher 0, plafond max, mort) et où traiter résistances et concentration | `regles-dnd` puis M | Base : absorption PV temp, bornes 0..max ; le client envoie le montant final après résistances |
| A5 | **Effets** : table `character_effects` comme vérité ; miroir **à sens unique** vers `characters.conditions` pour le mobile publié ; durées `rounds|end_of_combat|until_rest|manual` ; pas d'horloge de jeu | M ; `regles-dnd` | Oui ; que devient un état retiré à la main sur l'ancien mobile alors que l'effet reste actif ? (à trancher avec `qa-testeur`) |
| A6 | **Repos par le MJ** : notification seulement (le joueur applique `apply_rest`) | M ; `regles-dnd` | Oui |
| A7 | **Consentement** : implicite à l'adhésion pour un groupe généré depuis une histoire, **explicite** pour un groupe lié après coup (`group_members.gm_actions_consent`) | M ; `rgpd` | Oui ; badge « groupe lié » visible dans l'app mobile |
| A8 | **Limitation de débit** des actions MJ (`rate_limited`) | M | 60 actions/minute/MJ (à mesurer) |
| A9 | **Accepter une récompense hors ligne** : xp/or/objet en file idempotente ; `level_up` en ligne | M ; `qa-testeur` | Oui |
| A10 | **Écrasement par l'ancien mobile** : une écriture absolue de PV en file écrase une action MJ (3.5) tant que la version n'est pas migrée | M | Risque accepté et documenté jusqu'à la phase 5 ; relever `min_supported_version` ensuite |
| A11 | **Notifications push** sur dégâts/récompenses/combat (préférence `notification_preferences` à ajouter) | M | Oui, désactivable, texte sans détail sensible |
| A12 | **Journal `game_events`** : durée de conservation et anonymisation à la suppression de compte (ex-Q14) | M ; `rgpd` | 90 jours glissants ; `actor_id` anonymisé |

## Bloc R - Temps réel (phase 3)

| # | Question | Qui | Recommandation par défaut |
|---|---|---|---|
| R1 | **Présence** (indicateur « connecté ») visible dans le groupe ; données non persistées | M ; `rgpd` | Oui, limitée à l'écran de groupe/outil ouvert |
| R2 | **Quotas du plan Supabase** (connexions, messages/s) et version de Realtime | M | Mesurer d'abord (requête 17 et tableau de bord) |
| R3 | Remplacer `postgres_changes` par Broadcast partout à terme, en gardant l'ancien pour les builds publiés | M | Oui ; retrait en phase 7 |
| R4 | Topics : `group:{id}`, `gm:{id}`, `adventure:{id}`, `user:{id}` | F+M | Oui |

## Bloc L - Legacy (outil gelé)

| # | Question | Qui | Recommandation par défaut |
|---|---|---|---|
| L1 | **Correctif S01** (le joueur rattaché lit la ligne `stories` entière, `content` compris) : le corriger malgré le gel (aucune donnée touchée, un droit seulement) ? | M | Oui, en dernier (faible urgence : peu de données attendues, requête 15) |
| L2 | **Migrer** les histoires/codex de Florian vers le nouveau modèle, ou **repartir à zéro** ? | F | Décider d'après la requête 15 ; migration par script one-shot (`legacy_story_id`) seulement si les données comptent |
| L3 | Date d'**archivage** (écritures révoquées, schéma `legacy`) | M | Après la migration ou le choix « zéro » ; jamais de `drop` |
| L4 | **Buckets `story-covers`/`story-content-images`** : copie vers `adventure-assets` ou conservation lecture seule | M+F | Conservation lecture seule ; copie à la demande |
| L5 | `groups.campaign_id` et `character_campaigns` : déclarés dépréciés, jamais utilisés par la nouvelle API | M | Oui |

## Bloc M - Mobile (phases 5-7)

| # | Question | Qui | Recommandation par défaut |
|---|---|---|---|
| M1 | **Politique de versions** : quand relever `app_versions.min_supported_version` (coupure de l'accès direct) ? | M | Après au moins 2 versions de store et une adoption mesurée (Q11 d'`04`) |
| M2 | **Écrans mobile** : consentement, récompenses en attente, effets, groupe lié | M ; `direction-artistique` | À concevoir après la phase 4 |
| M3 | **File hors ligne en deltas** (3.5) | M ; `qa-testeur` | Oui, avec test de non-régression sur le flux actuel |
| M4 | **Priorité** de la refonte face aux autres chantiers mobile | M | À décider |

### Les 10 questions les plus bloquantes (ordre)

B3 (projet de test), B1 (où vivent les migrations), B2 (même projet/auth, hébergement de l'outil), B7 (cardinalité), B4 (nommage), B5 (slugs), B6 (éditions/sources), H1 (spoilers), A1/A7 (portée des droits MJ et consentement), B10 (périmètre et priorité).

---

## Requêtes SQL complémentaires, **en lecture seule**, à faire lancer par Matthias (production `nexus-jdr (beazvozraxvcbymbxumb)`)

Mêmes règles qu'en `04` : agrégats ou noms d'objets, aucune donnée personnelle ; coller les résultats ; si un classificateur bloque une requête, la lancer seul. Aucune ne modifie l'état.

### Q-SQL-14 - Fournisseurs d'authentification et comptes (B2)

```sql
select coalesce(raw_app_meta_data->>'provider', 'inconnu') as fournisseur, count(*) as comptes
  from auth.users group by 1 order by 2 desc;
select count(*) filter (where raw_user_meta_data->>'full_name' is null) as sans_nom,
       count(*) as total from auth.users;
```

### Q-SQL-15 - Données de l'ancien outil (L1, L2)

```sql
select count(*) as histoires, count(distinct user_id) as mj,
       count(*) filter (where length(coalesce(content,'')) > 0) as avec_contenu,
       pg_size_pretty(coalesce(sum(length(content)), 0)::bigint) as volume,
       count(*) filter (where invite_code_enabled) as codes_actifs from public.stories;
select category, count(*) as entrees, pg_size_pretty(sum(length(coalesce(content,'')))::bigint) as volume
  from public.codex_entries group by 1 order by 2 desc;
select role, count(*) from public.character_campaigns group by 1;
```

### Q-SQL-16 - Extensions disponibles pour la recherche (section 4 de 05)

```sql
select name, default_version, installed_version from pg_available_extensions
 where name in ('pg_trgm','unaccent','pgcrypto','pg_stat_statements','pg_net','pg_cron','btree_gin') order by 1;
```

### Q-SQL-17 - Objets Realtime disponibles (temps réel privé)

```sql
select proname from pg_proc where pronamespace = 'realtime'::regnamespace order by 1;   -- send ? broadcast_changes ? topic ?
select to_regclass('realtime.messages') as table_messages;
select count(*) as abonnements from realtime.subscription;
```

### Q-SQL-18 - Volume des buckets (H4, L4)

```sql
select bucket_id, count(*) as objets, pg_size_pretty(sum((metadata->>'size')::bigint)) as taille
  from storage.objects group by 1 order by 2 desc;
select id, public, file_size_limit, allowed_mime_types from storage.buckets order by 1;
```

### Q-SQL-19 - Stabilité des données de référence (B5, B6)

```sql
select count(*) as creatures, min(id) as id_min, max(id) as id_max, count(distinct source) as sources from public.creatures;
select locale, count(*) from public.translations where entity_type = 'creature' group by 1;
select count(*) as sans_traduction_fr from public.creatures c
 where not exists (select 1 from public.translations t where t.entity_type = 'creature'
                    and t.entity_id = c.id::text and t.locale = 'fr' and t.field_name = 'name');
select count(*) - count(distinct name_en) as doublons_potentiels from (
  select t.entity_id, t.field_value as name_en from public.translations t
   where t.entity_type = 'creature' and t.locale = 'en' and t.field_name = 'name') x;   -- adapter le nom de colonne si besoin (voir l'annexe schema_public_rejoue.sql)
```

### Q-SQL-20 - Groupes et liens à préserver (H7, H10)

```sql
select count(*) filter (where campaign_id is not null) as groupes_avec_campaign_id, count(*) as groupes from public.groups;
select count(*) as membres_actifs, count(*) filter (where is_game_master) as mj_sans_perso,
       count(distinct group_id) as groupes_avec_membres from public.group_members;
select count(*) as groupes_sans_ligne_mj from public.groups g
 where not exists (select 1 from public.group_members m where m.group_id = g.id and m.user_id = g.owner_id);
```

### Q-SQL-21 - Dépendances de la suppression de compte (H10)

```sql
select conrelid::regclass::text as table_fk, pg_get_constraintdef(oid) as definition
  from pg_constraint where contype = 'f' and confrelid = 'auth.users'::regclass order by 1;
```

### Q-SQL-22 - Combats existants (compatibilité de `revealed`, `combat_npc_state`)

```sql
select count(*) as combats, count(*) filter (where status = 'active') as actifs from public.combats;
select kind, status, count(*) from public.combat_participants group by 1, 2 order by 1, 2;
```

### Q-SQL-23 - Schémas exposés et rôles de l'API (B8)

```sql
select rolname, rolconfig from pg_roles where rolname in ('authenticator','anon','authenticated');
select nspname from pg_namespace where nspname in ('api_v1','private','legacy') order by 1;
```

### Q-SQL-24 - Fonctions publiques exécutables par `anon` (surface actuelle à ne pas élargir)

```sql
select p.proname, p.prosecdef as definer
  from pg_proc p
 where p.pronamespace = 'public'::regnamespace
   and has_function_privilege('anon', p.oid, 'execute')
 order by 1;
```
