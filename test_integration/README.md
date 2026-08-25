# Tests d'intégration (`test_integration/`)

## Pourquoi ce dossier existe

Tous les repositories de données de ce dépôt (`AuthRepository`,
`CharacterRepository`...) sont des abstractions injectables, testées via des
doubles factices (`_FakeAuthRepository`, `_FakeCharacterRepository`...) dans
la suite `flutter test` habituelle (dossier `test/`). C'est volontaire et
correct pour tester la logique d'écran/de widget rapidement et sans réseau —
mais ça veut aussi dire qu'**aucun test de `test/` n'exécute jamais la vraie
requête PostgREST** envoyée par une implémentation `Supabase*Repository`.

Le 25/08/2026, `SupabaseCharacterRepository.fetchCharacters()` interrogeait la
table `translations` avec une colonne `name` qui n'existe pas (la vraie
colonne est `value`, avec un filtre `field_name` requis), et contenait un bug
de type (`entity_id` est `text` côté Postgres, alors que les ids de
`races`/`classes` reviennent en `int` de PostgREST). `flutter analyze` et
`flutter test` étaient tous les deux verts malgré ce bug — il n'a été détecté
que par une vérification manuelle (`supabase db reset` + `psql`).

Ce dossier corrige ce point mort : il exécute les vraies implémentations
`Supabase*Repository` contre un vrai stack Supabase local (Postgres +
PostgREST + GoTrue), pour détecter les colonnes inexistantes, les mismatchs
de type et les policies RLS cassées — le genre de bug qu'un double factice ne
peut par construction jamais révéler.

Ce n'est **pas** le dossier `integration_test/` officiel de Flutter : ces
tests ne pilotent pas l'app sur un appareil/émulateur (`flutter drive`), ce
sont de simples tests VM (comme ceux de `test/`) qui parlent réseau à un vrai
Supabase local. D'où le nom différent, pour ne pas prêter à confusion.

## Pourquoi séparé de `flutter test`

`flutter test` (sans argument) exécute tout `test/**/*_test.dart`
automatiquement. Ces tests d'intégration ont volontairement été mis **hors**
de `test/`, dans `test_integration/` à la racine, pour ne jamais s'exécuter
par accident sans stack Supabase local démarré (ce qui les ferait échouer
pour tout le monde, y compris en CI tant qu'aucun stack éphémère n'y est
branché — voir section CI plus bas).

## Lancer les tests

### Option rapide : le script

```bash
tool/run_integration_tests.sh
```

Démarre le stack Supabase local du dépôt web (par défaut au chemin
`../markdown-editor` relatif à ce dépôt — surchargeable avec la variable
`NEXUS_WEB_REPO_PATH`), régénère `config/integration.json` avec les
URL/clé anon actuelles, puis lance `flutter test test_integration`.

Prérequis : Docker actif, `jq` installé, et la CLI Supabase disponible dans
le dépôt web (`pnpm install` là-bas — elle y est déjà en devDependency).

### Option manuelle

1. Dans le dépôt web :

   ```bash
   supabase start
   ```

   (si c'est la première fois, ou après avoir tiré de nouvelles migrations :
   `supabase db reset` pour appliquer migrations + seeds au complet — ce test
   a besoin qu'au moins une race et une classe existent avec leur traduction
   française, ce que les migrations de seed fournissent déjà.)

2. Copier `config/integration.json.example` vers `config/integration.json`
   et y renseigner `SUPABASE_URL`/`SUPABASE_ANON_KEY` avec les valeurs
   affichées par `supabase start` (ou `supabase status -o json`).

3. Depuis ce dépôt :

   ```bash
   flutter test test_integration --dart-define-from-file=config/integration.json
   ```

## Ce que ça couvre / ne couvre pas

- Couvre : le vrai schéma Postgres (noms/types de colonnes), les vraies
  policies RLS (`owner_id = auth.uid()`, `owns_character(...)`...), le
  comportement réel de PostgREST (embeds, filtres, jointures via
  `translations`).
- Ne couvre pas : l'UI (aucun widget rendu ici), le mode hors-ligne/cache
  `drift` (ces tests parlent directement à Supabase, pas au cache local).

## Nettoyage des données de test

Chaque test insère un personnage de test et le supprime en fin de test
(`addTearDown`), donc la table `characters` reste propre. Les **utilisateurs
Auth** créés pour authentifier chaque run (un e-mail aléatoire par exécution,
voir `support/test_environment.dart`) ne sont en revanche pas supprimés — la
clé anon utilisée ici n'a pas accès à l'API admin GoTrue nécessaire pour ça,
et ce n'est pas nécessaire pour un stack local jetable. Lancez de temps en
temps `supabase db reset` dans le dépôt web pour repartir d'une base propre.

## CI

Pas encore branché : il faudrait un stack Supabase éphémère en CI (service
Docker + CLI, `supabase start` puis `supabase db reset`) avant d'y lancer
`flutter test test_integration`. Noté ici pour ne pas avoir à le
redécouvrir — pas fait à ce stade car aucune pipeline CI n'existe encore
dans ce dépôt (voir `13-depot-versioning-publication.md`).
