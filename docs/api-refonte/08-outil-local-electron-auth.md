# 08 - Outil de Florian en logiciel local (Electron) et connexion au compte Nexus

Date : 15/11/2026. Ticket Project #7 : « Outil de Florian : Electron, connexion au compte Nexus et nouvelle analyse de la
base (étude) ». Document de **proposition** : rien n'est développé, rien n'est appliqué. La partie base de données
(Supabase et SQLite local) est dans `09-base-outil-local.md` (agent `dev-sql-api`).

Fiabilité : **[C]** vérifié (code lu ou essai exécuté sur ce poste), **[D]** déduit, **[I]** incertain (à vérifier).

## 0. Décisions de Matthias (15/11/2026)

- `grimoire-du-mj` (github.com/Coudercf/grimoire-du-mj, privé, droit d'écriture pour Matthias [C]) **est** l'outil de Florian.
- Il **reste local** : logiciel de bureau lancé avec Electron. « Le but est d'utiliser l'outil comme un logiciel afin
  d'avoir un local avec les fichiers à importer qui seront stockés directement en local afin d'éviter de devoir les
  importer sur un serveur et de devoir les stocker. »
- « Il va falloir ajouter l'authentification afin de récupérer son compte et pouvoir récupérer les groupes et les joueurs. »
- L'absence d'authentification sur le réseau local n'est **pas** acceptée : il faut une auth locale.
- Import : « mettre à jour » et « réutiliser la bibliothèque » restent cochés par défaut.

**Conflit à trancher** : la décision n° 2 du 14/11 (`00-decisions-et-vision.md` : « les histoires et leur environnement
vivent dans notre base ») et la phase 2 de `05-revision-propositions.md` (tables `adventure_*`, bucket d'images) partent
de l'hypothèse inverse. Options et recommandation dans `09-base-outil-local.md`.

## 1. Ce qui a été vérifié sur ce poste

| Vérification | Résultat | Fiabilité |
|---|---|---|
| `pnpm install` dans `grimoire-du-mj` | OK en 2 min 13 ; seul avertissement : Node 22.12 < 22.13 exigé. Le `pnpm-workspace.yaml` « gabarit » ne bloque pas. Dépôt resté propre (`git status` vide) | [C] |
| `pnpm test` | 30 fichiers, **445 tests verts** (avec `--experimental-sqlite`, nécessaire sous Node 22.12) | [C] |
| `pnpm typecheck` | propre (client et serveur) | [C] |
| Electron 45.3.2 (dernière stable) | embarque **Node 24.22.2** et SQLite 3.53.4 ; `node:sqlite` disponible **sans option** | [C] |
| Serveur de Grimoire **non modifié** lancé par le Node d'Electron (`--import tsx server/index.ts`) | API, SSE `/api/events`, WebSocket `/api/live`, SQLite en WAL : tout fonctionne | [C] |
| `node:sqlite` dans un `utilityProcess` Electron (processus Node séparé) | OK, mode WAL | [C] |
| `safeStorage` (chiffrement par le système, DPAPI sous Windows) | disponible, chiffrement/déchiffrement OK | [C] |
| Cookie posé par le processus principal sur `http://127.0.0.1:<port>` | **envoyé** avec la page, `fetch`, `EventSource` **et** `WebSocket` | [C] |
| Garde CSRF actuelle (`server/app.ts:146-152`) | une écriture **sans en-tête `Origin`** est acceptée (`POST /api/campaigns` → 201) ; un WebSocket sans `Origin` est accepté | [C] |
| Écoute sur `127.0.0.1` | le serveur n'est plus joignable depuis l'IP du réseau local (192.168.1.79) | [C] |
| Écran joueur (`/plein-ecran`) | rendu sous `CampaignLayout` (`src/App.tsx:71-80`), qui charge **la campagne entière** (`api.campaigns.get`) : notes du MJ, dialogues, PNJ, jetons cachés | [C] |

Non vérifié : empaquetage `electron-builder`, signature, mise à jour automatique, macOS, joker de port dans les URL de
redirection Supabase, flux Google sur bureau, lecture d'un `asar` depuis un `utilityProcess`.

## 2. Architecture cible

```
┌────────────── Processus principal Electron ──────────────┐
│ fenêtres (MJ, écran joueur), menu, verrou d'instance,     │
│ safeStorage (session chiffrée), cookie local, mises à jour│
└───────┬───────────────────────────────────▲──────────────┘
        │ fork + MessagePort                │ port prêt / chiffrer / ouvrir une URL
┌───────▼─────────── utilityProcess « serveur » ────────────┐
│ server/index.ts actuel : Hono + node:sqlite + SSE + WS    │
│ + middleware d'accès local + supabase-js (session, cache, │
│   Realtime)                                               │
└───────▲───────────────────────────────────────────────────┘
        │ HTTP / SSE / WebSocket sur 127.0.0.1:<port aléatoire>, cookie httpOnly
┌───────┴──── Fenêtres (renderer Chromium, sandbox) ────────┐
│ client React actuel, transport inchangé                   │
└───────────────────────────────────────────────────────────┘
   (option) écoute LAN pour les tablettes appairées, portée « écran »
```

Pourquoi garder HTTP plutôt que passer par l'IPC d'Electron : aucune réécriture de `src/lib/api.ts`, `live.ts`,
`board-live.ts` ; le mode web (`pnpm dev`, tests) continue de marcher ; les écrans joueur sur tablette restent possibles.
Pourquoi un `utilityProcess` plutôt que le processus principal : `DatabaseSync` est synchrone (un import de 400 Mo ou le
ramasse-miettes bloqueraient les fenêtres et le menu) ; un plantage du serveur est isolé et peut être relancé.

## 3. Electron : recommandations

| # | Recommandation | Fiabilité / raison |
|---|---|---|
| E1 | **Electron 45** (Node 24). Développement local en **Node 24 LTS** (ou au minimum 22.13). Prévoir une montée de version d'Electron régulière (cycle de 8 semaines, 3 versions maintenues) | [C] versions vérifiées ; Node 22.12 sur ce poste |
| E2 | Nouveau dossier `electron/` : `main.ts` (fenêtres, cookie, safeStorage, verrou `requestSingleInstanceLock`), `server-host.ts` (lance `utilityProcess.fork` sur le serveur compilé, choisit un port libre, relance en cas de plantage). Pas de preload au départ | [D] |
| E3 | Le serveur garde son point d'entrée : il lit déjà `PORT`, `HOST`, `DATA_DIR`, `CLIENT_DIR` (`server/config.ts`). Ajouts : variable `GRIMOIRE_LOCAL_TOKEN`, message « prêt » et ordre d'arrêt propre via `process.parentPort` (la fermeture actuelle repose sur SIGINT/SIGTERM, `server/index.ts:49-59`) | [C] lecture du code |
| E4 | Données dans `app.getPath('userData')/comptes/<id utilisateur>/grimoire.db`. Au premier lancement, proposer d'**adopter** une base existante (`data/grimoire.db` de Florian) : copie, `PRAGMA integrity_check`, jamais de déplacement | [D] |
| E5 | **Sauvegarde automatique** : `VACUUM INTO` au lancement puis chaque jour, 7 copies tournantes, et avant chaque migration de schéma. Corrige le risque « `data/` est l'unique copie » | [C] risque constaté ; `VACUUM INTO` existe depuis SQLite 3.27 |
| E6 | Fenêtres : `contextIsolation: true`, `sandbox: true`, `nodeIntegration: false` (configuration de la sonde, OK) ; `setWindowOpenHandler` qui refuse et ouvre les liens `https` dans le navigateur système ; blocage de `will-navigate` hors de `127.0.0.1:<port>` | [C] sonde |
| E7 | **Écran joueur en 2e fenêtre** sur l'écran choisi (`screen.getAllDisplays()`, plein écran) : couvre la télévision en HDMI sans réseau local | [D] |
| E8 | Empaquetage `electron-builder`, Windows x64 (installeur NSIS) d'abord. Serveur compilé par esbuild **sans dépendances externes** (évite les liens symboliques de pnpm dans l'archive) ; client Vite en `extraResources` tant que la lecture d'un `asar` depuis le `utilityProcess` n'est pas vérifiée. Aucune dépendance native : `node:sqlite` est intégré, les images sont traitées dans le navigateur | [D] ; [I] pour `asar` |
| E9 | Mises à jour : `electron-updater`. Le dépôt est **privé** : la mise à jour depuis GitHub exigerait un jeton embarqué (à proscrire). Options : dépôt public dédié aux versions, ou stockage public (bucket) | [D] décision Matthias/Florian |
| E10 | Signature : sans certificat, Windows affiche l'alerte SmartScreen (acceptable pour Florian et toi en test, pas pour une diffusion). macOS exige un compte Apple Developer et la notarisation : à repousser sauf si Florian travaille sur Mac | [D] décision et coût |
| E11 | Scripts : `pnpm dev` inchangé (web) ; `pnpm dev:desktop` (Vite + Electron, serveur lancé avec `--import tsx`, testé ci-dessus) ; `pnpm dist:win` | [C] pour `--import tsx` sous le Node d'Electron |
| E12 | CSP inchangée (`server/static.ts`) : les appels Supabase partent du serveur local, pas de la page ; les portraits distants sont téléchargés par le serveur et servis comme images locales | [D] |

## 4. Sécurité du serveur local (« auth pour le local »)

| # | Recommandation | Fiabilité / raison |
|---|---|---|
| S1 | Écoute sur **127.0.0.1** par défaut (au lieu de `0.0.0.0`, `server/config.ts`). Effet secondaire : plus d'alerte du pare-feu Windows au lancement | [C] essai |
| S2 | **Jeton local** : 32 octets aléatoires créés par le processus principal à chaque lancement, transmis au serveur, posé en cookie `httpOnly`, `SameSite=Strict` avant le chargement de la fenêtre. Le serveur l'exige sur **toute** requête `/api/*` et à l'ouverture du WebSocket (`crypto.timingSafeEqual`). Aucun changement du transport côté client | [C] cookie reçu sur les 4 canaux ; corrige la faille vérifiée (écriture sans `Origin` acceptée) |
| S3 | Contrôle de l'en-tête `Host` (`127.0.0.1:<port>` ou `localhost:<port>`, plus l'IP LAN si le partage est actif) contre le DNS rebinding ; la garde `Origin` actuelle est conservée en plus | [D] |
| S4 | **Partage réseau local** (tablettes, téléphones) **désactivé par défaut**, activé par le MJ : écoute supplémentaire sur l'IP LAN, **appairage par QR code** contenant un code à usage unique (5 min), qui pose un cookie de portée « écran » ; liste des appareils appairés, révocables ; arrêt du partage = tout révoquer. Remplace le dialogue actuel adresses + QR (`AppShell.tsx:200-245`) | [D] |
| S5 | **Portée « écran »** : liste blanche stricte. Nouvelle route `GET /api/display/boards/:scenarioId` (plateau seul, **jetons cachés retirés côté serveur**), images du plateau, WebSocket (`show`, `board`, `drag`), déplacement des jetons « joueur ». Tout le reste en 403, dont `/api/auth/*` et `/api/nexus/*`. Page plein écran autonome, hors `CampaignLayout` | [C] aujourd'hui l'écran joueur reçoit la campagne entière |
| S6 | Le callback OAuth (`/auth/callback`, section 5) est la seule route sans cookie : il est protégé par le vérificateur PKCE et un `state` à usage unique détenus par le serveur | [D] |

## 5. Connexion au compte Nexus (login / register)

Constat côté mobile [C] (`lib/features/auth/data/auth_repository.dart`) : e-mail + mot de passe avec **confirmation par
e-mail activée** (l.393-400 : `session == null` signifie confirmation requise), pseudo stocké en `full_name` (l.389-391),
Google en OAuth web avec retour `nexusjdr://login-callback/` (l.418-421), Apple en natif iOS (`signInWithIdToken`),
réinitialisation du mot de passe vers `https://nexus-jdr.app/update-password` (l.557-559).

| # | Recommandation | Fiabilité / raison |
|---|---|---|
| A1 | **supabase-js dans le processus serveur**, jamais dans la page. La page appelle des routes locales `/api/auth/*`. Les jetons Supabase ne quittent jamais le processus serveur : une faille XSS dans l'interface ne peut pas voler le jeton de rafraîchissement | [D] |
| A2 | Persistance : adaptateur `storage` de supabase-js qui demande au processus principal de chiffrer/déchiffrer avec `safeStorage` (fichier `session.bin` dans `userData`). Options : `persistSession: true`, `autoRefreshToken: true`, `detectSessionInUrl: false`, `flowType: 'pkce'` | [C] safeStorage ; [D] le reste |
| A3 | URL et clé publique (publishable/anon, protégée par la RLS) injectées **au build** par environnement (dev / prod), jamais en dur dans le code source. Attention : dev et prod partagent aujourd'hui le même projet Supabase (R8 de 05) : Florian ne doit utiliser que des **comptes et groupes de test** | [C] R8 |
| A4 | Routes locales : `GET /api/auth/session` (`signed_out` / `online` / `offline`, id, e-mail, pseudo, date de dernière synchro) ; `POST /api/auth/sign-in` ; `POST /api/auth/sign-up` (renvoie `needsEmailConfirmation`, même règle que le mobile, `full_name` seulement si pseudo saisi) ; `POST /api/auth/password-reset` (même page `nexus-jdr.app/update-password`) ; `POST /api/auth/sign-out` ; `POST /api/auth/google` (renvoie l'URL à ouvrir dans le navigateur système). Messages d'erreur alignés sur `auth_error_mapper.dart` | [D] |
| A5 | **Google** : boucle locale (RFC 8252). Retour sur `http://127.0.0.1:<port>/auth/callback?code=…`, échange par `exchangeCodeForSession`, page « Connexion réussie, revenez dans Grimoire », événement SSE vers l'interface. À ajouter dans les URL de redirection Supabase : `http://127.0.0.1:*/auth/callback` (Supabase traite `.` et `/` comme séparateurs, le `*` devrait couvrir le port : **à tester**) ; à défaut, un port fixe réservé au retour | [I] joker de port |
| A6 | **Apple** : les comptes Apple ne viennent que d'iOS, pas encore publié : hors v1. Repli universel possible : **code à 6 chiffres par e-mail** (`signInWithOtp` + `verifyOtp`) si le modèle d'e-mail Supabase affiche `{{ .Token }}`. À décider | [D] |
| A7 | **Inscription** : même parcours que le mobile. Message « vérifie ta boîte mail », puis connexion dans l'outil après le clic. Rien à créer côté Supabase | [C] confirmation activée |
| A8 | **Une base locale par compte** : la première connexion lie la base au compte (`app_meta.owner_user_id`, voir 09) ; changer de compte change de base, jamais de mélange | [D] |
| A9 | **Hors ligne** : connexion obligatoire au **premier** lancement seulement. Ensuite, sans réseau, l'outil démarre avec l'identité en cache : tout le contenu local reste utilisable, les groupes et joueurs sont lus dans le cache avec leur date, les actions distantes sont grisées avec un message | [D] ; [I] limites de session dans le tableau de bord Supabase (durée maximale, inactivité) |
| A10 | Session révoquée ou compte supprimé (rafraîchissement refusé) : retour à l'écran de connexion ; la base locale n'est **jamais** supprimée automatiquement, export proposé | [D] |
| A11 | Interface : écran Connexion / Inscription / Mot de passe oublié, menu Compte (pseudo, en ligne / hors ligne, dernière synchro, déconnexion), garde de route tant que `signed_out`, redirection sur 401. Habillage dans le design de Florian (shadcn), pas celui de Nexus : à valider avec lui | [D] |
| A12 | Groupes et joueurs : routes locales `/api/nexus/*` qui lisent le **cache local** et déclenchent une synchro. Forme des données, droits et optimisations : `09-base-outil-local.md` | renvoi |

## 6. Ampleur des changements dans le code de Florian (estimation)

| Zone | Changement | Taille |
|---|---|---|
| `electron/` (nouveau), scripts, `electron-builder` | coquille, fenêtres, utilityProcess, sauvegardes, écran joueur en 2e fenêtre | M |
| `server/index.ts`, `server/config.ts` | jeton local, messages prêt/arrêt, hôte 127.0.0.1 par défaut | S |
| `server/app.ts`, `server/live.ts` | middleware cookie + `Host`, portée « écran », routes `/api/auth/*`, `/auth/callback`, `/api/display/*` | M |
| `server/nexus/` (nouveau) | client Supabase, stockage de session, synchro du cache, Realtime | M à L (selon 09) |
| `server/db.ts` | migrations 8 et suivantes (compte, liens distants, cache) | S à M (selon 09) |
| `src/` | écrans de connexion, menu compte, garde, page plein écran autonome, liaison campagne ↔ groupe et joueur ↔ personnage | M à L |
| Tests | middleware et portées, routes d'auth (Supabase simulé), migrations, adoption de base | M |

## 7. Risques et points ouverts

1. **Conflit avec la décision n° 2** (section 0) : bloque la conception de la liaison groupe ↔ campagne (09).
2. **Développement sur la production** (même projet Supabase) : comptes et groupes de test obligatoires pour Florian.
3. **Qui développe et avec quel circuit** : c'est le dépôt de Florian (PR sur `Coudercf/grimoire-du-mj`). Nos sous-agents
   sont spécialisés Flutter (`dev-flutter`) et Supabase ; aucun n'est défini pour TypeScript/Electron. À décider : Florian
   code, ou un agent dédié est créé, avec `code-reviewer` en relecture.
4. **Accord de Florian** sur l'architecture (utilityProcess, cookie local, portée « écran », une base par compte).
5. Distribution : signature, mises à jour depuis un dépôt privé, macOS.
6. **RGPD** : l'outil mettra en cache, sur la machine du MJ, des données d'autres utilisateurs (pseudos, personnages).
   Durée, purge à la sortie d'un groupe : à faire auditer par `rgpd` avant diffusion.

## 8. Feuille de route proposée (à valider ensemble)

Intègre les recommandations de `09-base-outil-local.md` (D1 à D14 de 09 §4 ; ordre côté base en 09 §5). Deux pistes en
parallèle possibles : **outil** (dépôt de Florian, lots 1 à 6) et **base** (dépôt web, étapes B), avec un seul point de
rendez-vous obligatoire : B1a avant le lot 3.

**Décisions de Matthias du 15/11 intégrées** (00, points 6 à 15) : O1 + titre visible des joueurs, création du groupe depuis
l'outil avancée juste après la connexion (lot 2b), agent dédié TypeScript/Electron + relecture et merge par Florian, une base
par compte avec reprise, contrat de lecture d'abord, CA en SQL, PV de la fiche mobile, groupes dont le compte est propriétaire,
Windows non signé sans mise à jour automatique, **Mac aussi** (le code doit rester multiplateforme dès le lot 1 : chemins,
`safeStorage` = trousseau macOS ; Florian peut développer sur Mac avec `pnpm dev:desktop` sans paquet signé), comptes de test
dédiés, Google au lot 5.

Parcours visé : le MJ se connecte → écrit son histoire (local) → « Générer un groupe » (titre de la campagne) → code
d'invitation → les joueurs rejoignent depuis l'app mobile et voient le titre de la campagne → l'outil lit le groupe et les
personnages (instantané) → combat.

| Lot | Contenu | Dépend de | Critères d'acceptation |
|---|---|---|---|
| 0 - Prérequis (toi) | Node 24 LTS sur le poste ; accord de Florian sur 08/09 ; comptes de test dédiés (ticket « Tâche (toi) ») ; création du sous-agent TypeScript/Electron (`.claude/agents/`) | décisions prises | Florian d'accord ; comptes de test prêts |
| 1 - Coquille Electron | E1-E8, E11, S1-S3 ; écran joueur en 2e fenêtre ; build Windows non signé | 0 | double-clic → app ouverte ; données dans `userData` et sauvegardées ; 445 tests verts ; requête sans cookie refusée (test) ; IP LAN injoignable |
| 2 - Connexion Nexus | A1-A11 (e-mail + mot de passe, inscription, mot de passe oublié), base par compte, adoption de la base existante, hors ligne | 1 | connexion / inscription / déconnexion avec un compte de test ; redémarrage sans ressaisie ; démarrage hors ligne ; jeton absent des fichiers en clair |
| 2b - Générer un groupe | bouton « Générer un groupe » sur une campagne : `create-group` (nom = titre de la campagne, sans personnage), code d'invitation affiché et copiable, lien local campagne ↔ groupe (0..1), régénération du code (même alphabet que le mobile) ; bouton bloqué pendant l'appel (fonction non idempotente) | 2 | groupe de test créé depuis l'outil, rejoint depuis le mobile avec le code ; le MJ est `is_game_master` ; aucun doublon sur double clic |
| B2' - Base « titre visible » | `groups.story_title`, `groups.story_summary_public` nullables (CHECK de longueur `NOT VALID`), écrits par le propriétaire (policy existante) | B0 | aucun effet sur le mobile publié |
| 2c - Titre visible (outil + mobile) | l'outil écrit le titre/résumé à la génération et à la mise à jour ; le mobile l'affiche sur le groupe (spec `direction-artistique`, version à publier) | 2b, B2' | le joueur voit « Campagne : … » dans son groupe |
| B0 - Base (toi) | terminer la phase 0 (PR web #48) | en cours | ticket existant |
| B1a - Base « lecture outil » | `api_v1.group_snapshot`, `api_v1.my_gm_groups`, fonction de CA (D4), pgTAP (09 §5, étape 2) | B0, D3, D4, D14 | aucun effet sur le mobile publié ; contrat documenté dans `docs/api-v1/` |
| 3 - Groupes et joueurs (lecture) | tables locales `nexus_*` et de liens (09 §3), liaison campagne ↔ groupe (0..1) et joueur ↔ personnage, PV en lecture (D6), rafraîchissement par empreinte, groupes affichés selon D9 | 2, **B1a** | instantané d'un groupe de test affiché hors ligne après une synchro ; aucune donnée distante dans les exports ; aucun joueur local supprimé par un événement distant |
| 4 - Partage LAN appairé | S4-S5, page plein écran autonome, jetons cachés filtrés côté serveur | 1 | tablette appairée par QR ; aucune donnée hors plateau lisible ; révocation effective |
| 5 - Google et macOS | A5 (Google, adresse de retour à ajouter dans Supabase) ; paquet macOS (signature ad hoc pour les tests, notarisation quand le compte Apple Developer existera) ; Windows reste non signé et sans mise à jour automatique (décision du 15/11) | 2 | connexion Google sur un compte de test ; outil installé et lancé sur le Mac de Florian |
| 6a - Combat depuis l'outil | combat via les 7 RPC existantes (lancer, participants, initiative, terminer), sans migration | 3 | combat de test lancé depuis l'outil et suivi des deux côtés |
| B1b - Base « références » | slugs, éditions, `reference_manifest` / `reference_export` (copie hors ligne des catalogues, D8) | B1a | aucun effet sur le mobile publié |
| 6b - Catalogues hors ligne | copie locale des monstres, objets, sorts par empreinte | B1b | bestiaire consultable hors ligne |
| B3+4 puis 6c - Actions MJ | `game_events`, Broadcast privé, `gm_tool_enabled_at`, consentement, `gm_*` (dégâts, récompenses, effets) ; puis bouton côté outil | 6a, `regles-dnd`, `rgpd`, A1-A12 de 06 | voir 09 §5 étape 5 |

Chaque lot deviendra un ticket Project #7 (avec ses tâches « Tâche (toi) ») une fois la feuille de route validée.
