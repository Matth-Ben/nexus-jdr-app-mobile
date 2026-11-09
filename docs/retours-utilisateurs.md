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

### Campagne du 07/11/2026 — Pseudo-session Clerc niveau 1→2 + groupe/butin/notes, scénario RAW de référence (PR #228)

Scénario réel `integration_test/adventure_session_cleric_groups_test.dart` :
création d'un Clerc Humain (Domaine de la Vie, Acolyte), 7 dégâts, sort de
soins (domaine, emplacement niveau 1), repos long, montée de niveau 2
(méthode PV "moyenne", déterministe), puis côté MJ : création d'un groupe
("MJ — sans personnage"), invitation réelle à deux comptes, butin ajouté/
réclamé, note de groupe. Exécuté avec succès de bout en bout en conditions
réelles (toutes les valeurs RAW asserties exactes — voir
`integration_test/README.md`) ; `flutter test` rapporte néanmoins ce
fichier en échec à chaque exécution, pour une raison sans rapport avec le
scénario RAW lui-même (F06 ci-dessous).

| ID | Titre | Catégorie | Preuve | Constat | État |
|---|---|---|---|---|---|
| F04 | Équipement de départ standard du Clerc résout sur une armure hors catalogue RAW (CA 17 au lieu de 18) | Bug/friction réel | **R** | Onglet SAC : l'équipement de départ standard du Clerc résout sur "Chemise de mailles" (armure moyenne, CA 13 + mod Dex plafonné à 2) plutôt que sur l'une des 3 options RAW du PHB (armure d'écailles CA14+Dex plafonné à 2 / cuir CA11+Dex / cotte de mailles CA16 sans mod Dex) — "Chemise de mailles" n'est même pas l'une de ces 3 options, ce qui suggère un défaut de mapping/catalogue plutôt qu'un simple choix de valeur par défaut discutable. CA totale observée : 13+2(Dex)+2(bouclier)=17 au lieu de 18 attendu (armure d'écailles+bouclier) — reproduit identiquement sur toutes les exécutions réelles de la campagne. | **Corrigé (07/11/2026)** — défaut de donnée confirmé (`classes.starting_equipment`, Clerc id=3, option A), pas un bug client (code de résolution audité et confirmé correct). Migration `20261107110000_fix_cleric_starting_equipment_armor.sql` (dépôt web, PR #41), déployée en production — `classes.starting_equipment` du Clerc renvoie désormais "Armure d'écailles". Point ouvert signalé (pas traité) : le modèle actuel ne permet qu'une armure fixe par option, pas un vrai choix interactif entre les 3 options RAW du Clerc dans l'assistant de création. |
| F05 | La fiche personnage affiche encore les valeurs du niveau précédent juste après une montée de niveau en méthode "moyenne" | Bug/friction réel | **R** | Après `runOneLevelUp(useAverageHp: true)` (Clerc niveau 1→2), la fiche reste parfois affichée avec les valeurs du niveau 1 (PV "10 / 10", XP "0 / 300" inchangés) alors que `character_classes.level` est déjà à 2 en base (confirmé par lecture directe via le client Supabase pendant le test) — reproduit 2 fois sur 4 exécutions réelles de la campagne (~50 %). Fermer puis rouvrir la fiche (force un nouveau fetch réseau) corrige l'affichage à chaque fois : défaut de rafraîchissement client après ce type précis de montée de niveau (méthode PV "moyenne"), pas de perte d'écriture réelle côté serveur. | **Corrigé (PR #231)** — race condition confirmée entre deux refetchs non coordonnés sur `characterDetailProvider` (ajout d'XP puis fin de montée de niveau) : `CharacterDetailScreen._addXp` attend désormais la résolution de son propre refetch avant de naviguer vers `LevelUpScreen`. |
| F06 | Débordement visuel de 3,7px sur l'état vide de la liste de personnages | Bug/friction réel | **R** | `character_list_screen.dart::_EmptyState` déborde de 3,7px quand le compte connecté n'a aucun personnage (cas systématique du compte MJ de test dans ce scénario) — ce débordement est promu en échec de test par le framework Flutter (`FlutterError` rapportée par `flutter test`), alors qu'aucune assertion du scénario RAW lui-même n'est en cause. Fait échouer `adventure_session_cleric_groups_test.dart` à chaque exécution malgré un déroulé fonctionnel réussi de bout en bout. | **Corrigé (PR #231)** — `_EmptyState` passe par `LayoutBuilder`/`SingleChildScrollView`/`ConstrainedBox(minHeight)` : rendu centré inchangé quand l'espace est suffisant, défilement (texte jamais tronqué) sinon. Bug annexe trouvé en cours de route (débordement horizontal de `_Header` à largeur très réduite/textScale élevé) tracé séparément en dette (D174, non corrigé). |

**Nettoyage de données en attente -- périmètre revu à la hausse
(`code-reviewer`, PR #228)** : l'étape 10 de
`adventure_session_cleric_groups_test.dart` supprimait le personnage de test
en étant encore connectée sur le compte MJ (dernier changement de compte de
l'étape 9), alors que le personnage appartient au compte joueur -- la RLS
Postgres (`auth.uid() = owner_id`) rend une telle suppression un no-op
SILENCIEUX (pas d'exception), donc le personnage de test n'était EN RÉALITÉ
JAMAIS supprimé, y compris lors des exécutions rapportées comme réussies
(corrigé dans le fichier de test : rebascule sur le compte joueur avant
suppression + vérification `.maybeSingle()` -> `null`). Conséquence : en
plus du personnage orphelin déjà identifié d'une exécution ratée
(`QA-Adventure-Clerc-1794059944973480`, caractéristiques fausses — première
exécution avant la correction de la séquence de `swapUp` dans le fichier de
test), il existe probablement PLUSIEURS AUTRES personnages de test orphelins
(préfixe `QA-Adventure-Clerc-`) issus des exécutions antérieures qui
semblaient réussies — Claude ne pouvant pas écrire en base au-delà de ce que
le test lui-même exécute, le nombre exact et les identifiants précis restent
à retrouver et supprimer manuellement par Matthias.

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

### Campagne du 08/11/2026 — vérification ciblée des correctifs F04-F06 + temps réel + notes multi-entrées

Scénario réel `integration_test/group_realtime_hp_and_notes_test.dart` (nouveau,
pas encore committé) : vérifie en conditions réelles les 5 correctifs/fonctionnalités
livrés depuis la campagne précédente (F04 équipement Clerc, F05 rafraîchissement
après montée de niveau, F06 débordement état vide, synchro Realtime des PV de
groupe, carnet de notes multi-entrées) — **les 5 points confirmés conformes**.
A révélé au passage un 6ᵉ constat (F07 ci-dessous), non lié à une régression des
correctifs vérifiés.

| ID | Titre | Catégorie | Preuve | Constat | État |
|---|---|---|---|---|---|
| F07 | L'arrivée d'un nouveau membre dans un groupe n'est pas poussée en temps réel au MJ déjà sur l'écran Groupe | Bug/friction réel | **R** | `groupMembersRealtimeWatcherProvider` (`lib/features/groups/presentation/providers/group_providers.dart`) ne souscrit qu'aux changements de la table `characters` filtrés sur `memberCharacterIds` déjà connus — jamais à la table `group_members` elle-même. Un MJ qui garde l'écran Groupe ouvert pendant que des joueurs rejoignent un par un (scénario plausible de début de séance) ne voit pas apparaître le nouveau membre sans quitter/rouvrir l'écran, alors que la mise à jour des PV d'un membre déjà connu, elle, est bien poussée en direct depuis le correctif Realtime (`20261107090000`) — incohérence d'expérience entre les deux cas. | **Corrigé (PR #232 mobile + PR #42 web, 08/11/2026)** — migration `20261108090000_enable_realtime_on_group_members.sql` déployée en production (`group_members` vérifié dans `pg_publication_tables` pour `supabase_realtime`) ; `subscribeToMemberUpdates` écoute désormais `INSERT`/`DELETE` sur `group_members` filtrés par `group_id` sur le même canal que les mises à jour de PV. **Confirmé en conditions réelles le 09/11/2026** (campagne `simulation-utilisateur`, émulateur) pour l'arrivée d'un membre : visible côté MJ en ~0,5 à 1 s sans navigation. Le départ n'était en revanche pas couvert : voir F08. |
| F08 | Le départ d'un membre (joueur qui quitte, membre exclu) n'est pas poussé en temps réel au MJ déjà sur l'écran Groupe | Bug/friction réel | **R** | Suite incomplète de F07, trouvée en le vérifiant : l'arrivée d'un membre apparaît chez le MJ, mais 15 s après la suppression de sa ligne `group_members` le membre restait affiché (échec `ECART F07 (DELETE)`). Cause vérifiée en base : `public.group_members` est en `REPLICA IDENTITY DEFAULT` avec PK `id` seule, donc un `DELETE` Realtime ne porte que l'`id` et jamais `group_id` ; le filtre `group_id=eq...` ne pouvait jamais correspondre. `REPLICA IDENTITY FULL` écarté : Realtime n'applique pas la RLS aux `DELETE`, un utilisateur connecté pourrait s'abonner au `group_id` d'un autre groupe et lire les `user_id`/`character_id` des joueurs qui partent. | **Corrigé (PR #234, 09/11/2026)** — correctif client uniquement, aucune migration : `DELETE` écouté sans filtre, refresh seulement si l'`id` supprimé correspond à un membre connu du groupe (`GroupMember.membershipId`, `shouldRefreshOnMemberDelete`). Vérifié sur émulateur : le membre disparaît chez le MJ en ~1 s sans navigation (étape 6bis de `integration_test/group_realtime_hp_and_notes_test.dart`). La logique de décision est couverte par des tests unitaires ; le canal Realtime lui-même ne l'est que par ce test d'intégration (D176). |

**Nettoyage** : personnage et groupe de test créés pendant cette campagne
confirmés supprimés (`addTearDown`, vérifié par requête REST directe
post-run, y compris sur le run raté précédant l'ajustement de protocole).

**Dette de test signalée (non traitée)** : `adventure_session_cleric_groups_test.dart`
a une étape 9 obsolète depuis la PR #230 (ancien carnet "un seul champ visible"
remplacé par l'UI à tuiles/feuille modale actuelle) — à mettre à jour pour éviter
un faux signal d'échec lors d'une prochaine exécution complète de ce fichier.

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

## Campagne complète du 09/11/2026 (passes A et B1, rôle joueur)

Campagne demandée par Matthias : tester l'app comme un vrai joueur sur l'ensemble de
ses fonctionnalités, juger si elles sont concrètes à la table et ce qui manque, avec
un angle qualité de vie. Passe A : création de 3 profils (Magicien, Barbare, Occultiste),
lecture de la fiche, le reste lu dans le code. Passe B1 : interactions de la fiche
exécutées sur émulateur (PV, repos, sorts, inventaire, progression jusqu'au niveau 4,
journal). La passe B2 (import/export XML, hors-ligne, partage, profil, groupes,
accessibilité) est en cours : ses constats seront ajoutés ici.

Conforme et vérifié en conditions réelles (aucun écart) : PV et PV temporaires (plafonds,
non-cumul, absorption), repos court (dés de vie, aperçu) et long, CA avec armure et
bouclier, charge et capacité, progression des PV niveaux 2 à 4, quota de sorts préparés,
journal (ajout, modification, suppression avec confirmation), harmonisation jusqu'à 3.

### Bugs et écarts trouvés

| ID | Titre | Catégorie | Preuve | Constat | État |
|---|---|---|---|---|---|
| F09 | Bonus de maîtrise des armes non appliqué pour 8 armes (noms périmés dans le calculateur) | Écart RAW | **R** + base | `weapon_attack_calculator.dart` listait « Hache à deux mains », « Serpe », « Coutille »… alors que le catalogue contient « Grande hache », « Faucille », « Glaive » : un Barbare FOR 16 affichait « Grande hache +3 » (attendu +5). 8 armes sur 37 touchées. | **Corrigé (PR #237)** — `isProficient` délègue à `WeaponProficiencyCategoryRules`, une seule liste de référence ; test sur les 37 noms du catalogue. |
| F10 | Vitesse affichée « 30 m » alors que la valeur est en pieds | Bug/friction réel | **R** + base | `races.speed` vaut 25/30/35/40 (pieds), affiché avec le suffixe « m ». | **Corrigé (PR #238)** — `SpeedConverter.feetToMetres` (30 → 9 m, 25 → 7,5 m), la base reste en pieds. |
| F11 | Libellés d'armes, armures et équipement de l'import/export XML ne correspondent pas au catalogue | Bug/friction réel | **L** + base | Une arme importée comme « Bâton » devenait un objet personnalisé sans stats (`itemId` nul) ; une « Grande hache » exportée partait en texte libre. 8 armes, 5 armures et 11 objets d'équipement concernés. | **Corrigé (PR #239)** — libellés alignés sur le catalogue, ids aidedd inchangés, garde-fou de test. Les ids d'armures 9, 11 et 12 sont déduits de l'ordre PHB (aucune source dans le dépôt) : à confirmer avec un export aidedd réel. Lignes ambiguës laissées en objets personnalisés (Sacoche, Gourde, Sac, focaliseurs…). |
| F12 | Grimoire du Magicien au niveau 3 : sorts déjà connus proposés, rien de nouveau persisté | Bug/friction réel | **R** (3 runs, lecture en base) | Écran « NOUVEAUX SORTS CONNUS 0 / 2 » : les tuiles proposées incluent des sorts déjà au grimoire ; le récapitulatif annonce « Nouveaux sorts appris » mais `character_spells` reste à 11 lignes (attendu 13 : 3 sorts mineurs + 10 au grimoire, RAW 6 + 2 + 2). Réserve : le helper de test prend les deux premières tuiles actives, à reproduire avec des sorts réellement nouveaux. | Ouvert — gravité haute, à instruire par `dev-flutter` (reproduire d'abord avec de vrais nouveaux sorts, puis corriger). |
| F13 | Dés de vie : récupération perdue quand un repos long suit un repos court de moins d'une seconde ; feuille « Repos court » périmée | Bug/friction réel | **R** (4 runs) | Run 9 : repos long immédiatement après un court, `hit_dice_spent` reste à 2 (0 dé récupéré). Run 5 : affichage « 0/2 » périmé alors que la base est correcte. Cause non établie (verrou `_isApplyingRest` ?). Rare en vraie partie. | Ouvert — à instruire par `dev-flutter`. |
| F14 | Repos long sans retour sur les dés de vie récupérés | Fonctionnalité mal calibrée | **R** | La feuille et le snackbar ne mentionnent que PV, emplacements et aptitudes, rien sur la moitié des dés de vie récupérés. | Ouvert — petit complément à traiter avec F13. |
| F15 | Emplacements de niveau 2 et plus invisibles sur l'onglet Sorts tant qu'aucun sort de ce niveau n'est connu | Bug/friction réel | **R** + **L** | Magicien niveau 3 : seules les pastilles du niveau 1 sont affichées, alors que la feuille « Lancer » propose déjà le niveau 2. Pastilles rattachées au groupe de sorts de chaque niveau (`_SpellLevelGroupSection`). Avis direction artistique : traiter comme un bug, afficher les niveaux 1 à max de la classe. | Ouvert — à traiter dans la vague « onglet Sorts » (proposition P14). |
| F16 | Armure non maîtrisée : aucun avertissement | Écart RAW / fonctionnalité manquante | **R** | Un Magicien équipe une cotte de mailles : CA 16 correcte, snackbar « Cotte de mailles équipé » (accord masculin fautif), aucun avertissement. | Ouvert — voir proposition P10 ci-dessous. |

### Propositions de fonctionnalité — synthèse du comité de revue (09/11/2026)

Avis croisés : direction artistique (DA), règles D&D (RAW, rédigé de mémoire, points
douteux marqués), `dev-flutter` (effort), `dev-backend-supabase` (données, lu dans les
migrations seulement), `qa-testeur` (testabilité). Chiffres réels vérifiés en base le
09/11/2026 : 518 sorts (33 rituels, 232 à concentration, aucune école manquante, aucun
sort incomplet) ; 250 objets magiques, tous avec une rareté ; 247 objets sur 445 sans
poids ; 116 dons (44 sans prérequis structuré, 34 avec un niveau) ; 7 paquetages.

| ID | Proposition | Preuve | DA | RAW | Effort / backend | Risque (QA) | Recommandation du chef de projet |
|---|---|---|---|---|---|---|---|
| P1 | Saisie numérique des PV et des monnaies (champ éditable, appui long, boutons Dégâts/Soins) | R | Forte, priorité haute (reprendre la feuille d'XP) | Aucun | S (1 j), pas de backend | Élevé : `StepperCounter` partagé par 12 fichiers pour 5 tests, donc variante opt-in | Vague 1 |
| P2 | Lanceur de dés étendu (sauvegardes, attaques, dégâts, avantage/désavantage, lanceur libre) | L | Moyenne, par étapes | Avantage/désavantage à 3 états saisis par le joueur ; critique manuel plutôt qu'automatique ; ne jamais simuler la sauvegarde adverse | M, 2 temps (sauvegardes et lanceur libre d'abord) ; RNG injectable | Faible | Vague 3 |
| P3 | Concentration active + marqueur Rituel | L | Concentration forte, rituel faible | Concentration : jet de Con DD 10 ou moitié des dégâts, ne pas rompre automatiquement ; rituel : règles par classe, 2014 différent de 2024 | 3a avertissement concentration S/M (local) ; 3b rituel M, donnée mobile absente | Le plus risqué (état persisté, Realtime) | 3a en vague 2 ; 3b repoussé |
| P4 | Filtres de sorts (niveau, école, concentration, rituel, favoris) + contrôle favori | R+L | Forte, puces défilantes | Aucun | M ; favoris déjà en base et en vue partagée | Modéré | Vague 2 (sans filtre rituel) |
| P5 | Signal visuel « À 0 PV » sur sa fiche | R | Haute, libellé + icône, jamais la couleur seule | Aucun (jets contre la mort hors V1) | S (0,5 j) | Très faible | Vague 1 |
| P6 | Marqueurs d'états/conditions informatifs | L | Basse | Liste de 15, textes changés en 2024 : étiqueter l'édition ; ne rien automatiser ; épuisement hors V1 | M ; colonne `conditions` sur `characters` (migration S) + fiche partagée | Moyen (donnée persistée) | À trancher par Matthias |
| P7 | Objet personnalisé enrichi (poids, bonus magique, CA, harmonisation, types de dégâts) | L | Basse (sections « Avancé » repliées) | Bonus +1/+2/+3, harmonisation max 3 ; charges et malédictions non automatisables | M, L avec bonus au catalogue ; migration d'inventaire + fiche partagée | Élevé (calcul de CA partagé) | Repoussé ; poids seul d'abord |
| P8 | Conversion de pièces | R+L | Basse (bouton « Changer » dans la feuille de P1) | 1 PP = 10 PO = 100 PA… ; électrum retiré en 2024 | S, aucun backend | Faible | Vague 1, après décision sur l'électrum |
| P9 | Corriger un lancer de sort (snackbar « Annuler », ajustement manuel d'un emplacement) | R | Forte, priorité haute | Aucune règle d'annulation : libeller « correction » ; ajustements légitimes (Récupération arcanique, Perle de pouvoir, pacte) | M (2 j) ; file `spellSlot` à ne pas casser | Modéré | Vague 2 |
| P10 | Avertissement informatif armure/bouclier non maîtrisé | R | Moyenne, pastille « Non maîtrisé » sur l'objet | Désavantage For/Dex et incantation impossible, 2014 = 2024 ; ne pas appliquer le désavantage | S (1 j) ; union des maîtrises en multiclasse | Faible | Vague 3 |
| P11 | Onglet Sorts d'un non-lanceur : message simple, ressources visibles | R | Moyenne | Aucun | S | Moyen (sous-classes lanceuses : Chevalier occulte) | Vague 1 |
| P12 | Éclater les paquetages en objets avec poids | R | Aucun changement d'écran | Contenus différents 2014/2024 : une source par édition | Côté app S, côté contenu M (migration, les 7 paquetages sont dans `equipment_packs`) | Moyen | Vague 4 (donnée) |
| P13 | Filtrer ou étiqueter les dons proposés au niveau 4 | R | Basse-moyenne, tag « Campagne/Épique », pas de masquage | Catégories 2024 : origine, général, style de combat, épopée (niveau 19) ; griser plutôt que masquer | M ; colonne `category`/`source` sur `feats` + backfill | Faible | Vague 4 (donnée) |
| P14 | Pastilles d'emplacements de tous les niveaux disponibles | R | Haute, à traiter comme un bug | Aucun | S (0,5 j) | Moyen (multiclasse, pacte, 320 px) | = F15, vague « onglet Sorts » |

Conceptions à mener ensemble : P3 + P4 + P9 + P14 (onglet Sorts), P1 + P8 (feuille de
monnaies), P5 + P6 (zone d'état de l'en-tête). Dettes de test à combler avant :
`StepperCounter` (5 tests pour 12 usages), `SpellSlotDots` (2 tests pour 6 usages),
calculateur de CA avant P7. Toute nouvelle donnée persistée impose la mise à jour de
`data_export_repository.dart` (RGPD) et signale la fonction partagée
`build_character_sheet_json` à l'équipe web.

Vagues proposées (`dev-flutter`, validées par la DA et le QA) : **vague 1** P5, P11, P1, P8,
F15/P14 (environ 5 jours) ; **vague 2** onglet Sorts : P4, P9, P3a ; **vague 3** P2, P10 ;
**vague 4** dépendantes d'une donnée ou d'une décision : P6, P7, P12, P13, P3b.

Décisions de Matthias : en attente.
