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
| F12 | Grimoire du Magicien au niveau 3 : sorts déjà connus proposés, rien de nouveau persisté | Bug/friction réel | **R** (3 runs, lecture en base) | Écran « NOUVEAUX SORTS CONNUS 0 / 2 » : les tuiles proposées incluent des sorts déjà au grimoire ; le récapitulatif annonce « Nouveaux sorts appris » mais `character_spells` reste à 11 lignes (attendu 13 : 3 sorts mineurs + 10 au grimoire, RAW 6 + 2 + 2). Réserve : le helper de test prend les deux premières tuiles actives, à reproduire avec des sorts réellement nouveaux. | **Corrigé (PR #240, 09/11/2026)** — hypothèse (a) établie : l'écran proposait les sorts déjà au grimoire (la persistance était saine, l'écriture ignore les sorts déjà possédés) ; ils sont désormais exclus des candidats, les quotas sont plafonnés au nombre de vrais nouveaux sorts, badge et récapitulatif ne reflètent plus que de vrais ajouts. Vaut aussi pour Barde, Ensorceleur, Occultiste, Rôdeur et les sorts mineurs (écran partagé) ; seul le Magicien a un test dédié. Non revérifié sur émulateur. |
| F13 | Dés de vie : récupération perdue quand un repos long suit un repos court de moins d'une seconde ; feuille « Repos court » périmée | Bug/friction réel | **R** (4 runs) | Run 9 : repos long immédiatement après un court, `hit_dice_spent` reste à 2 (0 dé récupéré). Run 5 : affichage « 0/2 » périmé alors que la base est correcte. Cause non établie (verrou `_isApplyingRest` ?). Rare en vraie partie. | Ouvert — à instruire par `dev-flutter`. |
| F14 | Repos long sans retour sur les dés de vie récupérés | Fonctionnalité mal calibrée | **R** | La feuille et le snackbar ne mentionnent que PV, emplacements et aptitudes, rien sur la moitié des dés de vie récupérés. | Ouvert — petit complément à traiter avec F13. |
| F15 | Emplacements de niveau 2 et plus invisibles sur l'onglet Sorts tant qu'aucun sort de ce niveau n'est connu | Bug/friction réel | **R** + **L** | Magicien niveau 3 : seules les pastilles du niveau 1 sont affichées, alors que la feuille « Lancer » propose déjà le niveau 2. Pastilles rattachées au groupe de sorts de chaque niveau (`_SpellLevelGroupSection`). Avis direction artistique : traiter comme un bug, afficher les niveaux 1 à max de la classe. | **Corrigé (PR #241, 09/11/2026)** — carte « EMPLACEMENTS DE SORTS » avec une ligne par niveau réellement disponible (multiclasse = table combinée, pacte de l'Occultiste séparé), compteur `restants/total` dans le titre de chaque groupe de sorts, sémantique d'accessibilité. Non revérifié sur émulateur. |
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

### Décisions de Matthias (09/11/2026)

- **Vague 1 seulement** retenue : P5 (signal à 0 PV), P11 (onglet Sorts du non-lanceur), P1 (saisie
  numérique des PV et des monnaies), P8 (conversion de pièces), F15/P14 (emplacements de tous
  les niveaux). PR #241 (P5, P11, F15/P14) et PR #242 (P1, P8). Les vagues 2, 3 et 4 restent à
  décider.
- **P6 retenu** : marqueurs d'états persistés et visibles du MJ (colonne `conditions` sur
  `characters`, migration web, fiche partagée, export RGPD), purement informatifs, aucun effet
  sur les jets. Chantier distinct, planifié après la vague 1.
- **P8, électrum** : masqué tant que le solde est à 0 (comme PE et PP aujourd'hui), valable pour
  les deux éditions.
- Choix de conception retenus par le chef de projet sur avis de la direction artistique, que
  Matthias peut inverser : compteur `restants/total` dans le titre de chaque groupe de sorts
  (sans pastilles), « Niveau N » dans la carte d'emplacements, message du non-lanceur avant
  « RESSOURCES », bouton principal de la feuille PV qui suit le mode (Infliger / Soigner /
  Ajouter).

### Passes B2 et B3 (hors fiche : liste, hors-ligne, partage, profil, accessibilité)

Passe B2 : 3 parcours sur 10 exécutés (connexion/session, liste des personnages, début du
hors-ligne). Passe B3 : 4 parcours sur 7 exécutés (hors-ligne, partage, langue anglaise,
accessibilité). **Non exécutés** : import XML par l'interface (sélecteur de fichier natif non
pilotable, seuls les tests unitaires ont tourné), export « Mes données » généré, groupes à
deux comptes (le second compte n'a pas pu s'authentifier en REST), vue partagée ouverte par un
autre compte, utiliser une aptitude / préparer un sort / équiper un objet hors-ligne.

Vérifié conforme en conditions réelles : PV, emplacements et repos court mis en file se
resynchronisent au retour du réseau sans doublon ; un kill de l'app avec une écriture en
attente est rejoué au relancement ; un double tap sur « Appliquer » ne crée qu'une écriture ;
la session survit au kill ; le partage de personnage fonctionne de bout en bout (activation,
vue partagée en mètres, désactivation avec confirmation, lien révoqué) ; mauvais mot de passe
et compte inconnu donnent le même message (pas d'énumération de comptes) ; la suppression de
compte s'ouvre jusqu'à l'avertissement « Action irréversible » (jamais confirmée).

| ID | Titre | Catégorie | Preuve | Constat | État |
|---|---|---|---|---|---|
| F17 | Le FAQ promet un hors-ligne que l'app ne tient pas pour l'inventaire, les monnaies et le journal | Écart doc/comportement | **R** + **L** | `profileFaqAnswer3` : « modifiables sans connexion : PV, XP, inventaire… Aucune donnée n'est perdue ». Seuls `updateHp`, `addXp`, `castSpell`, sorts innés, `useClassFeature` et `applyRest` sont mis en file (`PendingCharacterWriteKind`). Hors-ligne : +5 PO → « Hors ligne : cette action n'a pas pu être enregistrée », les PO restent à 20 ; une note de journal donne le même message (le texte saisi est conservé tant que la feuille reste ouverte) ; l'ajout depuis le catalogue donne « Impossible de contacter le serveur » (catalogue non mis en cache). | **Texte du FAQ corrigé (PR #244, 09/11/2026)** — chaque promesse vérifiée contre le code ; précise qu'un seul repos est mis en attente par personnage et que création, montée de niveau, inventaire, monnaies, journal et préparation de sorts demandent une connexion ; réponses 1 (bouton « Importer XML ») et 2 (lien d'invitation, sans promettre l'écran masqué) corrigées. **Reste ouvert** : l'extension de la file hors-ligne (proposition P15), et la configuration du lien d'invitation Android jugée « incomplète » dans le manifeste (D190). |
| F18 | Hors-ligne, le compteur d'emplacements ne baisse pas à l'écran après un lancer de sort | Bug/friction réel | **R** | Magicien niveau 1, hors-ligne, « Graisse » : le message « sera synchronisé » s'affiche mais le compteur reste `2 / 2` ; au retour du réseau la base montre `slots_used=1`. L'action est bien partie, mais le joueur croit qu'elle a échoué et relance, consommant le second emplacement. Les PV, eux, s'affichent de façon optimiste. | **Non reproduit par test (PR #245, tests seuls, 09/11/2026)** — l'affichage optimiste des emplacements existe déjà (`_localSpellSlotsUsed`, `_effectiveDetail`, superposition `_withPendingWrites`) ; 3 tests verrouillent le comportement attendu. Cause du constat sur émulateur toujours inconnue : deux pistes plausibles consignées en D184 et D185 (le carte d'emplacements a aussi été refaite par la PR #241 depuis ce constat) ; à revérifier sur émulateur avec une trace. Lacune voisine : D186. |
| F19 | La resynchronisation hors-ligne écrase silencieusement une modification faite ailleurs | Bug/friction réel | **R** (`passe_b3_hors_ligne_test.dart`) | Hors-ligne, PV 8 puis −3 (5 en file) ; pendant ce temps un autre client écrit `current_hp = 2` ; au retour du réseau la base finit à 5, l'écriture de l'autre client est perdue, sans message ni alerte. L'écriture en file est un PV **absolu** rejoué, pas un delta. **Correction du 10/11/2026** : le scénario « un MJ soigne un joueur » est impossible, la seule policy d'écriture de `characters` est `auth.uid() = owner_id` (vérifié en base) ; le vrai cas est **le même compte sur deux appareils** (téléphone et tablette). Plus rare que décrit initialement. | Ouvert — décision de conception à instruire (rejouer en delta, ou prévenir quand la valeur serveur a changé) : proposition P17. |
| F20 | Après une erreur de catalogue hors-ligne, la feuille reste bloquée | Bug/friction réel | **R** | « Impossible de contacter le serveur… RÉESSAYER » est resté affiché plus de 80 s après le retour du réseau, sans relance automatique ; les contrôles suivants sont inaccessibles tant que la feuille n'est pas fermée. | Ouvert — relance automatique au retour du réseau, ou bouton plus visible. |
| F21 | Débordements de mise en page avec la police agrandie et sur petit écran, y compris l'écran de connexion | Bug/friction réel | **R** (`passe_b3_a11y_test.dart`) | Police 1,3 : débordement de 14 px (`character_list_screen.dart:533`) et 31 px (`character_skills_card.dart:57`). Police 2,0 + écran 480×800 : 7 débordements, dont le splash (`splash_screen.dart:35`, 375 px), **l'écran de connexion** (`login_screen.dart:580`, 462 px ; `social_auth_button.dart:78`, 304 px), la bannière de mise à jour et la liste (jusqu'à 1356 px). Un joueur avec une police agrandie ne peut pas se connecter. Inclut B2-5 (34 px sur une feuille de la liste). Autres débordements déjà connus : D174 et les rangées de `CharacterVitalsCard` (lignes ~161 et ~305). | **Corrigé en partie (PR #243, 09/11/2026)** — bouton de connexion sociale à libellé flexible, bannière de mise à jour empilée selon la largeur disponible (lien ≥ 44 px), `_Header` et liste (plafond du bloc d'en-tête seulement à grande échelle ou petite hauteur, focus de la recherche conservé), carte de compétences, splash défilant. **Le débordement de `login_screen.dart:580` n'est pas reproduit** : cette ligne est le séparateur « ou » en `Expanded`, aucun test avec les vraies polices ne déborde (1,3 / 2,0 / 3,0 sur 6 tailles) ; probablement un build périmé de l'émulateur ou un clavier ouvert → **à revérifier sur émulateur** (police 2,0, 480×800), non fait (émulateur saturé le 10/11). Restent : D179, D189 et la police `display` des titres qui se coupe en milieu de mot (décision de Matthias). |
| F22 | Groupes, partage, rejoindre une histoire, revue d'import XML non traduits en anglais | Bug/friction réel | **R** + **L** | App en EN : tout l'écran de partage, la liste et les écrans de groupe, « REJOINDRE UN GROUPE », « Étape 1 / 4 », la bannière « Nouvelle version disponible », « Compte lié à l'app Histoires », « Historique : Acolyte », « 1d4+3 perforant » de la vue partagée restent en français ; 0 occurrence d'`AppLocalizations` dans `features/groups/presentation/*`, `character_share_screen.dart`, `xml_import_review_screen.dart` (2 199 lignes) et `join_story/`. Périmètre bien plus large que D172. « 1 membres » (D171). Profil, confidentialité, FAQ, mentions légales et notifications sont bien en EN. | Ouvert — chantier de localisation à décider (même méthode que la Phase B), voir D172. |
| F23 | Partage : message « Lien de partage régénéré » à la première activation | Bug/friction réel | **R** | Libellé de la régénération réutilisé pour l'activation ; au premier run l'écran montrait encore « ACTIVER LE PARTAGE » alors que le jeton existait (non reproduit au second run). | **Corrigé (PR #246, 09/11/2026)** — « Partage activé. » à la première activation, « Lien de partage régénéré. » seulement si le partage était déjà actif ; cause de l'écran qui montrait encore « ACTIVER LE PARTAGE » établie et corrigée (le rafraîchissement n'était pas attendu : un second tap régénérait un jeton). Textes de l'écran toujours en français en dur (F22). |
| F24 | Retour Android depuis la liste racine ferme l'app sans garde | Bug/friction réel | **R** | Comportement Android standard, mais sans confirmation alors que des écritures peuvent être en attente. | Ouvert — confort, à rapprocher de P16. |

### Propositions de fonctionnalité — passes B2 et B3 (à soumettre au comité de revue)

| ID | Proposition | Preuve | Constat | État |
|---|---|---|---|---|
| P15 | Étendre la file hors-ligne à l'inventaire, aux monnaies, au journal, à la préparation de sorts et à l'équipement ; mettre le catalogue d'objets en cache | R | Aujourd'hui seuls PV, XP, emplacements, sorts innés, aptitudes et repos sont mis en file. Pendant une session sans réseau, le joueur ne peut ni dépenser de l'or, ni ramasser un objet, ni noter. | Ouvert — à instruire par le comité (effort, risque de conflit, RGPD). |
| P16 | Indicateur permanent d'état réseau, de file d'attente (« N en attente ») et de dernière synchronisation | R | Hors-ligne, la fiche est strictement identique, aucun repère ; la resynchronisation est silencieuse. | Ouvert — à instruire. |
| P17 | Résolution des conflits hors-ligne (rejouer en delta, ou prévenir quand la valeur serveur a changé) | R | Voir F19. | Ouvert — à instruire, dépend de P15/P16. |
| P18 | Liste des personnages : tri (nom, dernière ouverture), duplication, PV/CA sur la carte, « Archivé · Annuler » | R + L | Tri figé (en jeu, archivés, morts, par date de création) ; la carte n'affiche que « Race · Classe · Niv. » et l'XP ; archiver fait disparaître le personnage sans confirmation ni annulation ; pas de favori/épinglé ; recherche par nom et suppression avec confirmation OK, mode sélection multiple présent. | Ouvert — confort. | **Décision de Matthias (11/11/2026) : annuler l'archivage + PV/CA sur la carte + tri ; pas de duplication.** |
| P19 | « Rejoindre une histoire » masqué dans l'UI alors que le FAQ le décrit | L | Le bouton est « volontairement masqué » (`character_list_screen.dart`) ; `profileFaqAnswer2` décrit toujours cet écran. | Ouvert — aligner le FAQ ou rendre l'écran accessible. | **Décision de Matthias (11/11/2026) : aligner le FAQ sur l'app (écran Rejoindre une histoire reste masqué).** |

### Bilan de la campagne complète

Constats de cette campagne : 3 bugs corrigés et mergés (F09, F10, F11), 1 corrigé en attente de
merge (F12, PR #240), 12 constats ouverts (F13 à F24) et 19 propositions (P1 à P19), dont la
vague 1 (P1, P5, P8, P11, P14) en cours de merge (PR #241 et #242). Priorités suggérées par le
chef de projet, à valider : (1) corriger le FAQ (F17), l'affichage optimiste des emplacements
(F18) et les débordements de l'écran de connexion (F21), sans attendre ; (2) décider du chantier
hors-ligne (P15, P16, P17), qui conditionne l'usage réel à la table ; (3) décider du chantier de
localisation (F22).

## Chantier hors-ligne : décisions du 10/11/2026 (P15, P16, P17)

Avis croisés du comité (conception Flutter, backend, QA, direction artistique) : la file d'écriture
existe mais ses garanties sont partielles. Les écritures de monnaies, journal, inventaire,
préparation de sorts et équipement renvoient `WriteOutcome.queued` **sans rien persister** ;
`castSpell` n'attrape que `TimeoutException` (D184) ; l'état confirmé n'est pas reporté dans le
cache (D185) ; un abandon laisse un écrasement local (D186) ; une seule fin de repos par
personnage (D187). Le dev backend a aussi constaté que la RLS d'UPDATE de `characters` est
réservée au propriétaire : le cas « un MJ écrase les PV d'un joueur » n'existe pas, le vrai
risque (F19, D178) est le **même compte sur deux appareils**.

Décisions de Matthias :
- **Périmètre** : application seule d'abord, aucune RPC serveur ni migration pour l'instant.
- **Conflit** : alerte non bloquante (la valeur du serveur est affichée, l'utilisateur est prévenu).
- **Composant** : `SyncStatusBanner` validé (réutilise `InfoBanner`/`AlertBanner`, aucune nouvelle
  couleur), silencieux en usage normal ; états hors-ligne / N en attente / synchro en cours / erreur.
- **Retour Android depuis la liste racine** : dialogue seulement s'il y a des écritures en attente.

Découpage : T0 (retours honnêtes de `WriteOutcome` + harnais de test de la file), T1 (fondations
de la file : D184 à D187, table `pending_character_ops`, drift v5), T2 (indicateur), puis monnaies,
journal, inventaire, cache du catalogue. Statut : T0 en cours.

## Vérification sur émulateur de la vague 1 (10/11/2026, `main` = cc4fc75)

Pixel 7 Pro API 34, fr-FR, build profile. Tout #240 à #246 fonctionne en vrai : feuille PV
(INFLIGER/SOIGNER/AJOUTER, bornes, appui long, « À 0 PV »), monnaies (retrait limité au solde,
conversion avec valeur totale conservée), onglet Sorts (compteurs `restants/total`, lancer au
niveau supérieur), grimoire niveau 3 (aucun doublon), partage (« Partage activé. »), FAQ.
Le scénario d'aventure passe après correction d'un sélecteur périmé (défilement avant lecture des
pastilles). **F18 résolu** (le compteur baisse hors ligne et se synchronise au retour du réseau).
**F21 : le débordement de `login_screen.dart:580` n'est pas reproduit** (411 et 320 dp, polices
1,3 et 2,0) ; l'écran de connexion est sain, constat clos.

Nouveaux constats :

| Id | Constat | Gravité | Suite |
|---|---|---|---|
| V2-5 | Chevalier occulte niveau 3 : l'onglet Sorts affiche « Ce personnage ne lance pas de sorts. » alors que le personnage a « Incantation » (tiers-lanceurs non gérés, limitation déjà tracée dans la dette) : le message ment | Moyenne | À décider avec le chantier tiers-lanceurs ; au minimum un message honnête |
| V2-6 | Un lancer de sort de niveau 1 par un lanceur niveau 3+ demande une 2e feuille (3 taps) alors que le niveau 1 est présélectionné | Basse | Comité de revue (P-à ouvrir) | **Décision de Matthias (11/11/2026) : laisser tel quel (comité non requis).** |
| V2-7 | Électrum et platine non saisissables depuis un solde nul (tuile masquée à 0, décision de Matthias) ; conversion PA vers PO propose PC par défaut | Basse | Comité de revue | **Décision de Matthias (11/11/2026) : laisser tel quel.** |
| V2-8 | Écran de partage : chaînes françaises en dur (titre, snackbars, dialogue), casse incohérente (« Désactiver le partage » vs « ACTIVER LE PARTAGE ») | Basse | Correctif i18n |
| V2-9 | Police 2,0 sur 411 dp : titre « TES AVENT/URIERS » et bouton « IMPORTE/R XML » coupés en plein mot | Moyenne | Plafond de la police pixel (PR #247 à #249) |
| V2-10 | Police 2,0 : barre d'onglets de la fiche déborde de 22 à 24 px (libellés tronqués) | Moyenne | Plafond + onglets élastiques (PR #249) |
| V2-11 | Police 2,0 : carte Points de vie déborde de 53 px à droite | Moyenne | Plafond (PR #247/#249), à revérifier sur émulateur |
| V2-17 | `adventure_session_cleric_groups_test.dart` nettoie en ligne et non via `addTearDown` : un échec laisse le personnage en base | Basse | Correctif de test |

Non exécuté : clavier réel ouvert sur la feuille PV (clavier simulé en test), carte des
compétences à 1,3 et 2,0, électrum > 0.

Décision de Matthias (10/11/2026) sur le plafond de la police pixel : règle à 3 paliers
(titres ×1,3 ; boutons et onglets ×1,5 ; valeurs PV/XP ×1,6 en conteneur contraint) ; onglets
de fiche en police de corps sous 340 dp ; sélecteur à 3 segments maintenu à ×1,3.

## Vérification sur émulateur des PR #251 à #254 (10/11/2026, `main` = 1987d53)

Pixel 7 Pro API 34, fr-FR, comptes QA uniquement. **Conforme** : bandeau de synchronisation (silence en
usage normal ; « Hors ligne. Tes modifications… » après ≈ 2 s ; « Hors ligne · N modifications en
attente » en direct ; « Synchronisation… » puis « Synchronisé » ≈ 2 s puis silence ; sticky sur la fiche,
au-dessus du bandeau de mise à jour sur la liste), dialogue de retour Android si N > 0, ligne
« Dernière synchronisation » du Profil, **alerte de conflit F19 provoquée de bout en bout** (texte exact,
fermeture ×, visible liste et fiche, survit à une relance), un seul repos en attente, conditions
(sélecteur 14 états ordonnés, Enregistrer inactif sans changement, persistance, vue MJ en lecture seule,
refus propre hors ligne avec sélection conservée, pas de débordement à ×2,0 sur 320 dp). **V2-9, V2-10
et V2-11 corrigés** à ×2,0 ; l'écran de connexion est sain jusqu'à ×3,0.

| Id | Constat | Gravité | Suite |
|---|---|---|---|
| V3-1 | Onglet Sorts : titres de carte en police pixel non plafonnés (« EMPLACEMENTS DE SORTS », « PRÉPARATION DES SORTS », « SORTS PRÉPARÉS ») ; à ×3,0 sur 320 dp coupés en plein mot, à ×2,0 « SORTS PRÉPARÉS 2/2 » tassé ; l'inventaire à ×3,0 perd le nom de l'objet | Basse à moyenne | PR 2 du plafond de police (D192) |
| V3-2 | Tuile « VIT. » : débordement de 27 px à ×3,0 sur 411 dp ; « INIT. » et « INSP. » tronqués en « IN… » | Basse (×3,0 hors plage Android standard) | PR 2 |
| V3-3 | `adventure_session_cleric_groups_test.dart` échoue en l'état (« ECART 3 : SpellSlotDots niveau 1 introuvable ») : liste restée défilée après « LANCER » ; l'échec laisse un personnage `QA-Adventure-Clerc-…` orphelin dans la base distante (V2-17 aggravé) | Moyenne | Correctif de test : remonter la liste avant la lecture + nettoyage via `addTearDown` |
| V3-4 | Chips d'états à 411 dp avec 3 chips : le crayon d'édition tombe seul sur une 2e ligne | Basse | Ajustement de mise en page |
| V3-5 | Carte membre MJ : la pastille « +3 » ne dit pas quels états sont masqués (le libellé sémantique existe) | Basse | Fiche pour le comité de revue si souhaité |
| V3-8 | Alerte d'abandon/conflit avec un nom de personnage long (32 caractères) : bandeau de 5 lignes (≈ 150 dp) | Basse | À surveiller ; limiter la longueur du nom affiché |

Icônes pixel : lisibles à 32 dp ; **ambiguës** : À terre (lit/règle), Agrippé (poing), Étourdi (étincelles
confondues avec « bonus »), Inconscient (« z » dans un coin) ; à 16 dp, À terre et Étourdi deviennent des
taches (le libellé accompagne toujours l'icône). Hauteur utile du sélecteur : ≈ 7,5 lignes à ×1,0, 1,7
ligne à 320 dp/×2,0. **Non exécuté** : fiche partagée anonyme `/p/token` (indiscernable de la fiche
membre), « jamais » de la dernière synchronisation, vrai redémarrage du processus, « Quitter quand même »,
N = 0 isolé pour le dialogue, exactement 4 conditions, coupure réseau en pleine réponse.

## Vérification sur émulateur du chantier hors ligne et des PR #269 à #286 (12/11/2026, `main` = dcb0d59)

Campagne automatisée + parcours manuels (compte QA MJ, build release `dev`, données `QA-` nettoyées, Magnus intact).
**Réussi** : écritures hors ligne en file (PV 8/8→7/8, conditions, aptitude de classe, monnaies, journal,
inventaire : retrait, déséquipement, ajout d'objet personnalisé), bandeau « Hors ligne · N modifications en
attente » puis « Synchronisé » ≈ 2 s ; un seul repos en file, le second refusé avec le message prévu ; conflit
(alerte non bloquante, persistée, dédoublonnée « +N autres ») et abandon (D193 : « La fiche affiche la valeur
du serveur ») ; repos court puis long en ligne : « +1 dé de vie récupéré » (F13/F14 vérifié) ; démarrage à froid
hors ligne : l'écran de chargement est quitté en ≈ 11 s (V4-5 : pas de blocage infini) ; liste en un seul
défilement, recherche épinglée, PV/CA, feuille « Filtrer et trier », archivage ; polices ×2,0 et ×3,0 utilisables
(liste, fiche, assistant) ; dé 3D : résultat lisible dans la pastille, formule, modes ; icônes pixel redessinées
(à terre, agrippé, étourdi) lisibles ; texte de la bannière de mise à jour en anglais relevé.
**Non vérifié** : fluidité du dé 3D (build debug, `gfxinfo` à 0 image), avantage/désavantage, saut au tap, dé plein
écran ; emplacement de sort dépensé hors ligne, ajout/équipement d'objet de catalogue hors ligne ; ordre du
tri, annulation d'archivage ; assistant de création à ×2,0 ; vrai démarrage à froid (process tué).

| Réf. | Constat | Gravité | Suite |
|---|---|---|---|
| V5-1 | `_CharacterListScreenState.didPopNext` (`character_list_screen.dart:~197`) invalide un provider pendant le `didUpdateWidget` du Navigator de go_router : `setState() or markNeedsBuild() called during build` après la création d'un personnage (debug : écran rouge, `pumpAndSettle` expire ; reproduit 3 fois) | Moyenne | Corrigé par la PR en cours `fix/emulator-campaign-bugs` |
| V5-2 | Mode sélection à ×2,0 : « Aucun personnage sélectionné » réduit à une lettre ou deux par ligne ; alerte de synchro persistante + bannière de mise à jour = ≈ 65 % de l'écran de la liste à ×2,0 (alerte tronquée, chevauchement) ; une croix tapée par erreur a ouvert le mode sélection | Moyenne | Corrigé par la PR en cours |
| V5-3 | Libellés collés aux valeurs sur la carte des PV (« POINTS DE VIE12 / 12 », « EXPÉRIENCE0 / 300 ») même à ×1,0 : régression probable de `_LabelValueRow` (#283) | Basse | Corrigé par la PR en cours |
| V5-4 | Démarrage à froid hors ligne : la liste reste en spinner ≈ 6 s après la sortie de l'écran de chargement (≈ 11 s à ≈ 17 s) avant d'afficher les cartes en cache | Basse à moyenne | À examiner (cache de liste au démarrage) |
| V5-5 | Fiche jamais ouverte sur l'appareil + hors ligne : « Impossible de contacter le serveur » + RÉESSAYER, alors que le bandeau « Hors ligne » est affiché ; rien n'indique quelles fiches sont disponibles hors ligne | Moyenne | **Fiche B au comité** |
| V5-6 | Archivage/désarchivage depuis le menu de la fiche : aucun retour visible (ni snackbar ni badge sur la fiche) | Basse | À arbitrer |
| V5-7 | `AuthRetryableFetchException` (refresh de jeton hors ligne) a terminé un scénario de test ; non reproduit en conditions réelles | Basse | À surveiller (Crashlytics) |
| V5-8 | Les alertes de conflit et d'abandon s'empilent (« +2 autres ») sans écran de consultation ; trompeuses si les personnages sont supprimés ailleurs ; un bandeau « 1 modification en attente d'envoi » reste affiché en ligne tant qu'une écriture orpheline n'est pas traitée | Basse | **Fiche A au comité** |

**Propositions pour le comité de revue (non décidées)** : **A** — liste des alertes de synchronisation (écran ou
panneau repliable listant toutes les alertes avec « tout écarter », V5-2/V5-8) ; **B** — disponibilité hors ligne
explicite (indiquer sur la liste quelles fiches sont en cache, ou précharger les fiches au premier chargement de
la liste, V5-5). Contenu du catalogue encore en français en anglais (« Humain · Guerrier ») : chantier i18n du
contenu déjà tracé.
