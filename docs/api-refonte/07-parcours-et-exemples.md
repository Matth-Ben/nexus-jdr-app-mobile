# 07 - Parcours de bout en bout (modèle révisé)

Date : 14/11/2026. Illustrations du modèle de `05-revision-propositions.md` ; **aucune de ces RPC n'existe encore** (sauf mention **[E]** = existe et publiée [C]). Les noms de colonnes `game_events`, `character_grants`, etc. sont des **propositions**. « Outil » = le nouvel outil de MJ de Florian (**son fonctionnement interne est à valider avec Florian** ; seuls les appels qu'il fait à l'API sont décrits). « Mobile » = l'app Flutter. Les codes d'erreur suivent `message` + SQLSTATE.

Hypothèses communes : MJ = Alice (`A`), joueurs Bob (`B`) et Chloé (`C`) ; même projet Supabase de test ; Alice et les joueurs sont connectés avec leur compte ; les droits MJ sur fiches sont limités à un groupe **lié** (05 §3.1).

---

## Parcours (a) - Créer une histoire, générer un groupe, rejoindre avec le code

| # | Acteur / appel | Ligne en base | Événement temps réel | Ce que voit l'autre app |
|---|---|---|---|---|
| 1 | A se connecte dans l'outil (`supabase.auth`) | session JWT, `auth.users` existant | - | - |
| 2 | Outil : `api_v1.create_story(p_title, p_summary_public, p_edition, p_request_id)` | `adventures` (owner_id = A, status `active`, rev 0) | - | - |
| 3 | Outil : `api_v1.upsert_story_entry(...)` x N (PNJ, lieux, notes) ; secrets via `upsert_story_entry_secret` | `adventure_entries` (+ `adventure_entry_secrets`) ; aucune ligne `adventure_entry_reveals` | - | rien (aucun joueur) |
| 4 | Outil : bouton « Générer un groupe » -> `api_v1.generate_group_from_story(p_story_id, p_name, p_request_id)` | `groups` (owner_id = A, `adventure_id` = histoire, invite_code 8 car.), `group_members` (A, role `owner`, `is_game_master = true`, character null), `group_treasure` (trigger existant [C]), `game_events` (`group.generated`) ; `api_v1_requests` (idempotence) | `adventure:{id}` : `group.generated` | L'outil affiche le code ; le mobile d'Alice, s'il est ouvert, voit un nouveau groupe où elle est MJ (liste de groupes existante) |
| 5 | A envoie le code aux joueurs (canal externe) | - | - | - |
| 6 | Mobile B : saisie du code -> edge `preview-group-invite` [E, **non relue pour cette étape**] affiche nom, MJ ; (H14 : « groupe lié à une histoire, le MJ peut agir sur votre personnage ») | lecture seulement | - | B voit le nom du groupe |
| 7 | Mobile B : edge `join-group` [E] (code, `character_id`) | `group_members` (B, character_id) ; `gm_actions_consent = true` (adhésion à un groupe lié : A2/A7) | `game_events` `member.joined` -> `group:{id}` et `adventure:{id}` ; `postgres_changes` `group_members` INSERT [C] (mobiles déjà ouverts) | L'outil affiche « Bob a rejoint (personnage X) » et la présence ; le mobile des coéquipiers affiche le nouvel arrivant |
| 8 | C fait de même | `group_members` (C) | idem | idem |

**Succès** : après 8, `groups.adventure_id` non nul ; `start_combat` possible (`group_has_gm` vrai grâce à la ligne MJ [C]).

**Erreurs** :
- Étape 2/4 : `not_authenticated` 28000 ; `invalid_argument` 22023 (titre vide, `hint` = `title`) ; `story_not_found` P0002 (histoire d'un autre MJ **ou** inexistante : même réponse) ; `not_story_owner` 42501 ; `story_archived` P0001 ; `group_limit_reached` P0001 ; `invite_code_collision` P0001 (après 3 reprises, quasi impossible : 31^8 combinaisons).
- Étape 7 : erreurs de `join-group` : liste **à relire dans le dépôt gelé** avant de figer (non vérifiée) ; codes saisis faux/obsolètes, personnage déjà dans un autre groupe, doublon `unique(group_id, user_id)` [C].

**Concurrence** :
- Double clic « Générer » : même `p_request_id` -> un seul groupe (résultat mémorisé) ; deux `request_id` différents = deux groupes (plafond H5).
- Deux joueurs qui rejoignent simultanément : contraintes uniques existantes (`unique(group_id,user_id)`, `unique(group_id,character_id)` partielle [C]) ; aucun verrou nécessaire.
- Rotation du code pendant qu'un joueur saisit l'ancien : l'ancien code est refusé (`join-group` : code introuvable).

---

## Parcours (b) - Combat lancé depuis l'outil, initiatives sur mobile, MJ en direct

Rôles : A (MJ, outil), B et C (mobile), groupe lié (ou non : le combat marche dans les deux cas [C]).

| # | Acteur / appel | Ligne en base | Événement temps réel | Ce que voit l'autre app |
|---|---|---|---|---|
| 1 | Outil : `api_v1.start_combat(p_group_id, p_request_id)` (alias de `public.start_combat` [E]) | `combats` (status `active`, round 1, started_by = A) ; `combat_participants` : une ligne `pc` par membre avec personnage, hors MJ, `initiative` NULL [C] | `postgres_changes` `combats`/`combat_participants` [C] ; `game_events` `combat.started` -> `group:{id}` | Mobile B/C : bandeau « combat en cours » (déjà implémenté, `combat_repository.dart` [C]) |
| 2 | Outil : `api_v1.add_monsters(p_combat_id, [{creature_ref:{slug:'goblin'}, count:3, revealed:false, initiative:null}])` **(N)** | 3 lignes `combat_participants` (`kind='npc'`, `revealed=false`) + `combat_npc_state` (PV, CA du bestiaire) | `combat.participant_added` sur `gm:{id}` (détails) ; **rien** sur `group:{id}` tant que non révélés | Mobile : aucune ligne PNJ (monstres cachés) |
| 3 | Mobile B : `set_my_initiative(p_combat_id, 14)` [E] | `combat_participants` (B) : initiative 14 | `postgres_changes` ; `game_events` `combat.initiative_set` -> `group:{id}` | L'outil voit « Bob : 14 » en direct ; mobile C voit l'ordre mis à jour |
| 4 | Mobile C : `set_my_initiative(p_combat_id, 9)` | idem | idem | idem |
| 5 | Outil : `set_participant_initiative(p_participant_id, 12)` pour chaque gobelin, puis `set_participant_revealed(..., true)` | initiative ; `revealed = true` | `combat.participant_revealed` -> `group:{id}` | Les gobelins apparaissent dans l'ordre d'initiative sur le mobile |
| 6 | Outil : `advance_turn(p_combat_id, p_expected_round)` **(N)** à chaque tour | `combats.current_participant_id`, `round` | `combat.turn_advanced` {round, current_participant_id} | Le mobile met en évidence le tour courant ; les effets « en rounds » expirent (`effect.expired`) |
| 7 | Outil : `end_combat(p_combat_id)` [E, idempotent] | `combats.status='ended'`, `ended_at` | `combat.ended` | Le bandeau disparaît |

**Erreurs** : étape 1 `not_group_owner` 42501, `group_not_found` P0002, `no_game_master` P0001, `combat_already_active` P0001 ; étape 2 `npc_limit_per_combat` (60), `creature_not_found` ; étape 3 `invalid_initiative` 22023 (hors -20..60), `no_character`, `combat_not_active`, `participant_removed` ; étape 6 `round_conflict` PT409 (un autre onglet a déjà avancé le tour). Tous les codes [E] sont dans l'en-tête de `20261114091000_group_combat_rpcs.sql` [C].

**Concurrence** : toutes les RPC combat verrouillent le combat (`FOR UPDATE`, `combat_lock_for_gm` [C]) : deux écritures concurrentes sont sérialisées ; MJ et joueur écrivant l'initiative d'une même ligne : **la dernière gagne** [D] (l'événement porte l'acteur ; le client affiche la valeur serveur). Deux `start_combat` simultanés : un seul gagne (`combat_already_active`, index unique partiel [C]). **Hors ligne** : B sans réseau ne peut pas saisir son initiative (écriture en file, idempotente via `request_id` à ajouter côté mobile) ; à la reconnexion `events_since` lui montre le combat en cours.

---

## Parcours (c) - Dégâts appliqués à un joueur hors ligne, puis reconnexion

État initial : B (Bob) a 20/30 PV, mobile **hors ligne** depuis 5 minutes ; il a déjà une écriture de PV en file (il s'est soigné de 3 : 23 PV, `baseCurrentHp=20`, `currentHp=23`) [mécanisme : `pending_character_write_syncer.dart:385-417`].

| # | Acteur / appel | Ligne en base | Événement temps réel | Ce que voit l'autre app |
|---|---|---|---|---|
| 1 | Outil : `gm_apply_hp_change(p_group_id, p_character_id, 'damage', 7, 'slashing', null, p_request_id)` **(N)** | Vérifie : MJ du groupe, groupe lié, personnage membre actif, consentement ; `select … for update` sur `characters` ; `current_hp` 20 -> 13 ; `rev` +1 ; `game_events` (`character.hp_changed`, actor_role `gm`, payload {amount 7, type slashing, hp_after 13}) ; `api_v1_requests` | `group:{id}` : `character.hp_changed` ; push FCM « Ton MJ a modifié tes PV » si préférence (A11) | L'outil affiche 13 PV ; mobile C (coéquipier en ligne) voit les PV de Bob baisser ; Bob : rien (hors ligne) |
| 2 | Bob revient en ligne. Mobile : 1) rejoint `group:{id}` ; 2) `events_since(p_group_id, last_seq)` -> reçoit `character.hp_changed` | - | - | Journal : « Le MJ t'inflige 7 dégâts (tranchant) » |
| 3a | **Cible (mobile migré)** : la file envoie un **delta** `+3` : `api_v1.apply_hp_delta(character, +3, request_id)` | `current_hp` 13 -> 16 ; `game_events` `character.hp_changed` (actor `player`) | idem | PV = 16 des deux côtés : les deux écritures se cumulent |
| 3b | **Mobile publié** : la file écrit la valeur absolue 23 (`update characters`) après `_detectHpChange` : le serveur (13) diffère de la base (20) et de la valeur en file (23) -> `ServerValueConflict` (alerte D34/F19 [C]) ; l'écriture part ensuite (**[D]**, voir 05 §3.5) | `current_hp` = 23 ; trigger `after update` -> `game_events` `character.state_changed` | `character.state_changed` | **Incohérence acceptée (A10)** : le journal dit 7 dégâts, les PV reviennent à 23 ; l'outil affiche 23 et le journal permet de le constater |

**Erreurs** : `not_group_linked` P0001 (groupe non lié : l'outil désactive l'action) ; `gm_actions_not_consented` 42501 ; `character_not_in_group` P0001 (joueur parti) ; `invalid_amount` 22023 ; `character_dead` P0001 (règle à valider par `regles-dnd`) ; `not_group_gm` 42501 ; `rate_limited` PT429 ; `duplicate` : même `request_id` -> même résultat, aucun second événement.

**Concurrence** : deux MJ-outil (deux onglets d'Alice) appliquant des dégâts à Bob : le verrou de ligne sérialise, la somme est exacte (commutatif) ; deux `request_id` identiques : un seul effet. Bob en ligne qui se soigne au même instant : verrou de ligne + delta -> somme exacte (cible) ; écriture directe absolue du mobile publié : dernière écriture gagnante [C]. **Ce qui reste à valider avec `regles-dnd`** : absorption des PV temporaires, passage à 0 PV, mort instantanée, rappel de concentration.

---

## Parcours (d) - Récompense et montée de niveau acceptées par le joueur

| # | Acteur / appel | Ligne en base | Événement temps réel | Ce que voit l'autre app |
|---|---|---|---|---|
| 1 | Outil : `gm_grant(p_group_id, p_character_id, 'xp', '{"amount":300}', 'grant', 'Fin du chapitre 2', p_request_id)` **(N)** | `character_grants` (status `pending`, granted_by = A) ; `game_events` `grant.created` | `user:{B}` : `grant.created` ; push (A11) | Mobile B : carte « Récompense : 300 XP du MJ » (accepter/refuser) ; l'outil : « en attente » |
| 2 | Outil : `gm_grant(…, 'level_up', '{"to_level":4}', 'grant')` ; tentative `p_mode='apply'` : refusée (`apply_not_allowed`) | `character_grants` (pending, kind `level_up`) | idem | Carte « Montée de niveau disponible » |
| 3 | Mobile B : `accept_grant(p_grant_id, p_request_id)` pour l'XP | `characters.xp` += 300 sous verrou ; grant -> `applied` ; `game_events` `grant.applied` | `gm:{id}` et `group:{id}` | L'outil voit « Bob a accepté +300 XP » ; la fiche de Bob affiche l'XP à jour |
| 4 | Mobile B : `accept_grant(…)` pour `level_up` -> status `accepted` ; le mobile ouvre le parcours de montée de niveau existant (choix : PV, caractéristiques/don, sorts) | `character_grants` -> `accepted` | `grant.accepted` | L'outil : « Bob monte de niveau… » |
| 5 | Mobile B : `api_v1.apply_level_up(…, p_grant_id)` (version `api_v1` de la RPC [E, aucun appelant aujourd'hui, D05]) | `character_classes.level` +1, PV, emplacements, etc. dans **une** transaction ; grant -> `applied` ; `game_events` `grant.applied` (level) | idem | L'outil : niveau 4 de Bob |
| 6 | Variante : B refuse -> `decline_grant` | grant -> `declined` | `grant.declined` | L'outil : « Bob a refusé » |

**Erreurs** : `grant_not_pending` P0001 (déjà traitée, annulée par le MJ) ; `grant_obsolete` P0001 (niveau cible déjà atteint, par XP par exemple) ; `grant_expired` ; `invalid_payload` 22023 ; `unknown_grant_kind` ; `not_group_linked` ; `gm_actions_not_consented` ; côté `apply_level_up` : les erreurs de la RPC existante (non relues dans cette étape ; **à lister avant de figer**).

**Concurrence** : le MJ annule (`gm_cancel_grant`) pendant que le joueur accepte : la ligne du grant est verrouillée, **le premier gagne**, l'autre reçoit `grant_not_pending`. Double tape « accepter » : idempotent (même `request_id`, ou état déjà `applied`). Deux grants d'XP simultanés : sommés sous verrou de `characters`. **Hors ligne** : l'acceptation de l'XP peut être mise en file (A9) ; celle du niveau exige le réseau (v1). **À soumettre à `regles-dnd`** : seuils d'XP vs niveau accordé, plusieurs niveaux d'un coup, règles 2014/2024.

---

## Parcours (e) - Le MJ prépare une rencontre avec le catalogue de monstres

| # | Acteur / appel | Ligne en base | Événement temps réel | Ce que voit l'autre app |
|---|---|---|---|---|
| 1 | Outil : `search_reference(p_query:='gob', p_types:=['creature'], p_locale:='fr', p_edition:='2024', p_limit:=50)` ou vue `api_v1.creatures` filtrée (`challenge_rating`, `creature_type`, `size`), `Range` | lecture seule de `creatures` (331 lignes SRD 5.2 [C]) + `custom_creatures` du MJ (RLS propriétaire) | - | - |
| 2 | Pagination : `p_after` = curseur `(name_norm, id)` de la page précédente ; `next` null en dernière page | - | - | - |
| 3 | Outil : `get_creature(p_ref:='goblin')` -> statblock complet (traits, actions, résistances, CR, XP) fr/en | - | - | - |
| 4 | Outil : `upsert_custom_creature(p_data, p_request_id)` pour une variante (`base_ref` = goblin) | `custom_creatures` (owner A, `adventure_id` = histoire ou null) | - | - |
| 5 | Outil : `save_encounter(p_story_id, p_name, p_entries, p_notes)` | `adventure_encounters` (entries `[{creature_ref, count, name, revealed:false}]`) | - | rien (non révélé) |
| 6 | Outil (le moment venu) : `start_combat` puis `add_monsters` à partir de la rencontre (parcours b) | voir (b) | voir (b) | voir (b) |

**Succès** : l'ensemble de la préparation est invisible des joueurs (aucune ligne `adventure_entry_reveals`, aucun événement sur `group:{id}`).

**Erreurs** : `invalid_argument` 22023 (`p_limit` > 200, `hint` = `p_limit` ; curseur invalide) ; `creature_not_found` P0002 (slug inconnu **ou** créature maison d'un autre MJ : même réponse) ; `invalid_payload` (CR/PB/XP incohérents d'un monstre maison, règles à valider par `regles-dnd`) ; `story_not_found` ; `rate_limited` ; 401 si session expirée.

**Concurrence** : lectures sans verrou. Deux onglets qui éditent la même rencontre : `p_expected_rev` -> `rev_conflict` PT409 (l'outil propose de recharger). Modification du bestiaire par un administrateur pendant une session : `reference_versions.content_rev` change ; l'outil invalide son cache à la prochaine requête (ETag). Le **budget de rencontre** (seuils de difficulté, CR -> XP) est une règle de jeu : l'outil ne doit pas l'inventer, la règle est à valider par `regles-dnd` (2014 et 2024 diffèrent) ; la base ne renvoie que `challenge_rating` et `experience_points`.

**Limites connues** : les 331 créatures sont des monstres SRD 5.2 (2024) uniquement ; aucun monstre 2014 [C] ; les noms viennent de `translations` (EAV) : la recherche repose sur l'index dénormalisé `reference_search` de la phase 1 ; trigramme/`unaccent` non vérifiés en production (Q-SQL-16).
