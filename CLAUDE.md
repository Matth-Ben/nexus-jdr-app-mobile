# Nexus JDR — Personnages (app mobile Flutter)

Ce fichier oriente Claude Code quand il travaille dans **ce dépôt** (le dépôt mobile,
séparé du monorepo web — voir `13-depot-versioning-publication.md` du cahier des charges).

## Où est la spec

Le cahier des charges complet (14 documents : vision, modèle de données, UX,
design system, roadmap...) vit dans le projet claude.ai **"Nexus JDR - App mobile"**,
pas dans ce dépôt. Avant toute tâche un peu structurante, relire le document
pertinent plutôt que de deviner :
- Vision/faisabilité → `00-vision-et-faisabilite.md`
- Architecture technique (Flutter, Supabase, cache offline) → `01-architecture-technique.md`
- Modèle de données → `02-modele-donnees.md`
- Import XML aidedd.org → `03-import-xml-aidedd.md`
- Fonctionnalités → `04-fonctionnalites-app-mobile.md`
- UX/navigation → `05-ux-navigation.md`
- Roadmap et phases → `06-roadmap.md`
- Direction artistique → `08-direction-artistique.md`
- Design system (tokens, composants) → `10-design-system.md`
- Partage et groupes → `12-partage-et-groupes.md`
- Dépôt/CI/CD/publication stores → `13-depot-versioning-publication.md`

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
- Lint strict (`flutter_lints` ou `very_good_analysis`) dès le premier commit.
- Tests unitaires sur la logique métier (modificateurs, montée de niveau,
  emplacements de sorts) + tests de widgets sur les écrans critiques.
- Aucune clé/URL en dur — configuration par flavor (`dev`/`staging`/`prod`).
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
