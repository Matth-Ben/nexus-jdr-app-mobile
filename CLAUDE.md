# Nexus JDR — Personnages (app mobile Flutter)

Ce fichier oriente Claude Code quand il travaille dans **ce dépôt** (le dépôt mobile,
séparé du monorepo web — voir `13-depot-versioning-publication.md` du cahier des charges).

## Où est la spec

Le cahier des charges complet (14 documents : vision, modèle de données, UX,
design system, roadmap...) vit dans le projet claude.ai **"Nexus JDR - App mobile"**,
qui reste la source de vérité. Une copie locale de lecture est disponible dans
`docs/cahier-des-charges/` à la racine de ce dépôt (ignorée par Git — voir `.gitignore`,
resynchronisée manuellement depuis claude.ai en cas de mise à jour d'un document), pour
que Claude Code local puisse la consulter directement sans accès au projet claude.ai.
Avant toute tâche un peu structurante, relire le document pertinent plutôt que de deviner :
- Vision/faisabilité → `docs/cahier-des-charges/00-vision-et-faisabilite.md`
- Architecture technique (Flutter, Supabase, cache offline) → `docs/cahier-des-charges/01-architecture-technique.md`
- Modèle de données → `docs/cahier-des-charges/02-modele-donnees.md`
- Import XML aidedd.org → `docs/cahier-des-charges/03-import-xml-aidedd.md`
- Fonctionnalités → `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
- UX/navigation → `docs/cahier-des-charges/05-ux-navigation.md`
- Roadmap et phases → `docs/cahier-des-charges/06-roadmap.md`
- Source des données D&D et stratégie FR/EN → `docs/cahier-des-charges/07-source-donnees-i18n.md`
- Direction artistique → `docs/cahier-des-charges/08-direction-artistique.md`
- Maquettes/captures → `docs/cahier-des-charges/09-maquettes-captures.md`
- Design system (tokens, composants) → `docs/cahier-des-charges/10-design-system.md`
- Fonctionnalités à ajouter → `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`
- Partage et groupes → `docs/cahier-des-charges/12-partage-et-groupes.md`
- Dépôt/CI/CD/publication stores → `docs/cahier-des-charges/13-depot-versioning-publication.md`
- Organisation multi-agent → `docs/cahier-des-charges/14-organisation-multi-agent.md`

## Comment ce dépôt est organisé (une fois amorcé)

Architecture par fonctionnalité, pas par type technique :

```
lib/
  features/
    characters/{data,domain,presentation}
    character_creation/...
    join_story/...
  core/
    network/       # client Supabase
    cache/         # drift (SQLite), file de synchro offline
    widgets/        # composants partagés (design system)
    theme/          # tokens de 10-design-system.md
```

Conventions figées dans le cahier des charges (à ne jamais recontester sans
raison neuve) :
- Flutter + `supabase_flutter`, cache local `drift`, modèles `freezed` + `json_serializable`.
- Gestion d'état : **Riverpod** (décision du 25/08/2026, voir `01-architecture-technique.md`).
- Lint strict (`flutter_lints` ou `very_good_analysis`) dès le premier commit.
- Tests unitaires sur la logique métier (modificateurs, montée de niveau,
  emplacements de sorts) + tests de widgets sur les écrans critiques.
- Aucune clé/URL en dur — configuration par flavor (`dev`/`staging`/`prod`).
- App en **portrait uniquement**, iPhone, iPad et Android (décision du
  06/10/2026) : pas de mise en page paysage à concevoir, tester ni corriger.
  Le verrou est posé en configuration native (`ios/Runner/Info.plist`,
  `android/app/src/main/AndroidManifest.xml`, `targetSdk` figé dans
  `android/app/build.gradle.kts`), dont les commentaires décrivent les
  limites (tablettes, multi-fenêtre).
- Les migrations SQL restent dans le dépôt **web** (`supabase/migrations/`) —
  ce dépôt ne contient aucun fichier de migration.
- Conventional Commits (`feat:`, `fix:`, `chore:`...).
- PR obligatoire sur la branche principale, CI verte requise avant merge.

## Organisation multi-agent

Ce projet utilise des sous-agents Claude Code dédiés, définis dans
`.claude/agents/`. Le rôle de **chef de projet** n'est pas un sous-agent : c'est
la conversation principale (toi, avec Matthias) — c'est elle qui découpe une
phase de la roadmap en tâches, choisit quel sous-agent invoquer, relit ce
qu'il produit, et arbitre les décisions produit/techniques qui restent en
dehors du cahier des charges.

| Sous-agent | Rôle | À invoquer pour |
|---|---|---|
| `direction-artistique` | DA / revue UI | Valider un écran contre `10-design-system.md`/`08-direction-artistique.md` **avant** de le considérer fini |
| `dev-flutter` | Développeur Flutter | Implémenter une fonctionnalité (écran, logique métier, intégration Supabase) |
| `dev-backend-supabase` | Backend/données | Schéma, migrations (dans le dépôt web), politiques RLS, edge functions |
| `qa-testeur` | Testeur/QA | Écrire les tests, valider une fonctionnalité contre ses critères d'acceptation, chasser les régressions |
| `code-reviewer` | Revue de code | Relire un diff avant merge (conventions, sécurité, architecture) |
| `dette-technique` | Audit de dette technique | Analyser le code en place (périssable, fragile, mort) et produire un registre de dette priorisé — ne corrige rien lui-même |
| `regles-dnd` | Expert des règles D&D 5e (RAW) | Valider la règle exacte **avant** d'implémenter une mécanique de jeu (sorts, emplacements, multiclassage, dés de vie, préparation), puis vérifier la fidélité RAW du code **après** — ne code pas, ne tranche jamais seul une ambiguïté RAW (remonte à la conversation principale) |
| `rgpd` | Audit RGPD / confidentialité | Analyser l'app en place (consentement, droits d'accès/export/suppression, sous-traitants tiers, permissions OS, textes légaux vs comportement réel du code) et produire un registre d'écarts priorisé — ne corrige rien lui-même |
| `dev-sql-api` | Expert SQL / architecte d'API (décision du 14/11/2026) | Auditer le schéma partagé avec l'app web de Florian, concevoir la couche d'API (vues/RPC versionnées, droits par rôle) et rédiger les migrations progressives sur le dépôt **web** ; jamais d'accès à la production, jamais d'application d'une migration (Matthias l'applique), compatibilité avec les deux apps pendant toute la transition |
| `simulation-utilisateur` | Simulation joueur/MJ | Utiliser réellement l'app (parcours sur émulateur via `integration_test/` + analyse de code) du point de vue d'un joueur ou d'un MJ, pour juger la pertinence/complétude des fonctionnalités et proposer des axes d'amélioration — ne tranche jamais seul la faisabilité ou la pertinence d'une proposition |

**Tout développement passe par ces sous-agents** (décision du 06/10/2026) :
la conversation principale n'écrit pas elle-même le code ni les tests d'une
fonctionnalité ou d'un correctif, elle délègue à `dev-flutter`/
`dev-backend-supabase`, puis à `qa-testeur`, puis à `code-reviewer` avant de
pousser la branche — y compris pour une petite modification. Seuls les
fichiers de configuration et de documentation (ce fichier, `.claude/`,
`docs/`) restent édités directement.

### Un ticket par tâche (décision du 12/11/2026)

Toute tâche, correction ou évolution, a **son ticket** sur le tableau GitHub Project #7 **avant** de commencer. Le
ticket porte le contexte nécessaire pour éviter les débordements : demande d'origine (citée, avec la date), contexte,
décisions déjà prises, périmètre et hors périmètre, critères d'acceptation, dépendances et conflits possibles avec
d'autres tickets, liens (docs, PR). À la création, le chef de projet relit les tickets ouverts pour repérer les demandes
qui entrent en conflit et les signale à Matthias avant de lancer le travail. Les tâches qui reviennent à Matthias
(migrations web à appliquer, comptes de test, vérifications sur appareil, nettoyage) sont des tickets de catégorie
« Tâche (toi) » avec les **commandes exactes** et ce qu'il doit renvoyer, pour qu'il n'ait pas à relire les messages.
Les reliquats d'une PR restent dans `docs/dette-technique.md` (lignes D…) ; le ticket est mis à jour (statut, PR) à chaque
étape.

### Séquence type pour une fonctionnalité UI

1. `direction-artistique` valide/complète la spec visuelle de l'écran (si pas
   déjà couvert par `09-maquettes-captures.md`/`10-design-system.md`).
2. `dev-flutter` implémente.
3. `qa-testeur` écrit/complète les tests et vérifie le résultat contre les
   critères d'acceptation de la phase (`06-roadmap.md`).
4. `code-reviewer` relit le diff avant merge.

Pour une fonctionnalité backend/données (nouvelle table, RLS, edge function),
remplacer l'étape 1 par `dev-backend-supabase`, et prévenir que la migration
doit être ouverte en PR sur le dépôt **web**, pas ici.

### Séquence type pour une mécanique de jeu (règles D&D)

1. `regles-dnd` produit la règle RAW exacte et ses cas limites (voir
   `.claude/agents/regles-dnd.md`) ; toute ambiguïté RAW remonte à la
   conversation principale avant de continuer.
2. `dev-flutter` implémente.
3. `regles-dnd` vérifie la fidélité RAW du résultat (tables/formules valeur
   par valeur, pas par échantillonnage).
4. `qa-testeur` écrit/complète les tests et vérifie les critères
   d'acceptation habituels (hors-ligne, régressions).
5. `code-reviewer` relit le diff avant merge.

Les étapes 1 et 3 peuvent se combiner avec la séquence UI habituelle quand
la mécanique a aussi un volet visuel (ex. un nouvel écran de choix de
sorts) : `regles-dnd` valide la règle, `direction-artistique` valide
l'habillage, chacun dans son périmètre.

### Audit de dette technique

`dette-technique` n'entre pas dans la séquence d'une fonctionnalité : il
audite le code déjà en place. À invoquer en fin de phase de roadmap, avant
d'attaquer une grosse fonctionnalité sur une zone déjà dense, ou sur
demande. Il rend un registre priorisé ; le chef de projet choisit quoi
traiter, puis chaque correction retenue suit la séquence habituelle
(`dev-flutter` → `qa-testeur` → `code-reviewer`).

### Audit RGPD / confidentialité

`rgpd` n'entre pas non plus dans la séquence d'une fonctionnalité : il
audite l'app déjà en place (consentement, droits d'accès/export/suppression,
sous-traitants tiers, permissions OS, cohérence textes légaux ↔ code). À
invoquer en fin de phase de roadmap, avant une soumission aux stores, ou sur
demande. Il rend un registre d'écarts priorisé (catégories A/B/C comme
`docs/dette-technique.md`) ; le chef de projet choisit quoi traiter, puis
chaque correction retenue suit la séquence habituelle (`dev-flutter`/
`dev-backend-supabase` → `qa-testeur` → `code-reviewer`). Signale aussi,
sans jamais l'implémenter, le moment où Sign-In with Apple deviendrait
obligatoire (directive store 4.8) si une connexion sociale tierce est
ajoutée — l'implémentation d'Apple Sign-In elle-même reste différée.

Le registre courant vit dans `docs/dette-technique.md`. Il classe la dette en
trois catégories (bloque la production / fait perdre des données ou donne une
règle fausse au joueur / peut attendre). Quand une entrée est traitée, mettre
à jour son état en citant la PR plutôt que supprimer la ligne ; un défaut
découvert en cours de tâche s'y ajoute au lieu d'être corrigé au fil de l'eau.

### Simulation utilisateur (joueur/MJ) et revue croisée des propositions

`simulation-utilisateur` n'entre pas non plus dans la séquence standard
d'une fonctionnalité : il audite l'app déjà en place du point de vue d'un
joueur ou d'un MJ qui l'utiliserait réellement — parcours réels sur
l'émulateur via `integration_test/` (mêmes conventions que les scénarios
existants : sélecteurs texte/type/clé, jamais par coordonnées d'écran,
nettoyage systématique des données de test créées dans le projet Supabase
distant partagé) complétés par une analyse de code pour juger la
pertinence/complétude de ce qui existe déjà. À invoquer en fin de phase de
roadmap, avant une version destinée à de vrais joueurs/MJ, ou sur demande.
Il ne corrige rien lui-même (un bug trouvé se route à `dev-flutter`/
`dev-backend-supabase` comme d'habitude) et ne tranche jamais seul la
faisabilité technique ou la pertinence produit d'une proposition de
fonctionnalité — il la remonte comme fiche à soumettre au comité de revue
ci-dessous, jamais comme une décision actée.

**Comité de revue des propositions** (décision du 05/11/2026) : toute
proposition de fonctionnalité significative remontée par
`simulation-utilisateur` (pas un simple bug/friction, qui part directement
en correctif) passe par une revue croisée avant toute décision — le chef de
projet consulte les sous-agents pertinents pour un avis de faisabilité/
pertinence sur chaque proposition : `direction-artistique` (ajustement
visuel/UX), `regles-dnd` (conformité RAW si la proposition touche une
mécanique de jeu), `dev-flutter`/`dev-backend-supabase` (faisabilité
technique et effort estimé), `qa-testeur` (testabilité, impact sur le mode
hors-ligne/RLS). Le chef de projet consigne les avis croisés dans
`docs/retours-utilisateurs.md` à côté de la proposition, puis soumet
l'ensemble à Matthias pour décision — aucun sous-agent ne tranche seul, et
le chef de projet n'arbitre pas non plus à la place de Matthias sur une
question de priorisation produit.

Le registre courant vit dans `docs/retours-utilisateurs.md`. Même logique de
catégorisation que `docs/dette-technique.md`, adaptée à l'usage : chaque
entrée est un bug/friction réel, une fonctionnalité manquante, une
fonctionnalité existante jugée non pertinente/mal calibrée, ou une donnée
manquante — avec, pour les propositions de fonctionnalité, les avis du
comité de revue et la décision de Matthias une fois rendue.

### Découpage par phase (voir `06-roadmap.md`)

- **Phase 0 (cadrage)** : chef de projet + `dev-flutter` (setup projet Flutter,
  connexion Supabase, choix définitif `drift` vs `Hive`).
- **Phase 1 (socle de données)** : `dev-backend-supabase` en premier (tables de
  référence, peuplement du contenu de base).
- **Phase 2 (app V1)** : boucle `direction-artistique` → `dev-flutter` →
  `qa-testeur` → `code-reviewer`, écran par écran.
- **Phase 3 (import XML)** : `dev-flutter` (parsing + écran de vérification) +
  `qa-testeur` renforcé (panel large de personnages exportés).
- **Phase 4 (synchro "Histoires")** : `dev-backend-supabase` d'abord (à
  coordonner avec l'équipe web), puis boucle UI habituelle.

## Ce que chaque sous-agent ne doit pas faire

Aucun sous-agent ne tranche seul une question produit qui n'est pas déjà
décidée dans le cahier des charges (ex. : gestion d'état Riverpod vs Bloc si
jamais non tranché, priorisation entre deux fonctionnalités). Ces questions
remontent à la conversation principale.
