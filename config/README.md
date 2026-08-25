# Configuration par flavor (dev / staging / prod)

## Mécanisme choisi

Le cahier des charges (`01-architecture-technique.md`) laisse ouvert le choix
entre `--dart-define` et des fichiers `.env` par flavor. Ce dépôt utilise
`--dart-define-from-file` avec un fichier JSON par flavor dans ce dossier
(`config/dev.json`, `config/staging.json`, `config/prod.json`), lus dans
`lib/main.dart` (via `lib/core/network/env_config.dart`) avec
`String.fromEnvironment(...)`.

Raison de ce choix : un seul fichier par flavor à fournir/mettre à jour, pas
de dépendance à un package de parsing `.env` supplémentaire, et intégration
native à `flutter run`/`flutter build` (`--dart-define-from-file=config/dev.json`).

Ce point n'était pas tranché dans le cahier des charges au-delà de "les deux
sont acceptés" — à signaler au chef de projet si un autre mécanisme est
préféré plus tard (ex. alignement avec un choix déjà fait côté app web).

## Fichiers

- `config/dev.json`, `config/staging.json`, `config/prod.json` : contiennent
  les vraies valeurs (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). **Ignorés par
  Git** (voir `.gitignore` à la racine) — ne jamais les committer.
- `config/*.json.example` : versions avec des valeurs placeholder, committées,
  pour que chaque développeur sache quoi remplir localement.
- `config/integration.json` : même mécanisme, mais pour les tests
  d'intégration (`test_integration/`) contre un stack Supabase **local**
  (pas un flavor de l'app) — voir `test_integration/README.md`.

## État actuel : un seul projet Supabase pour les trois flavors

**TODO / IMPORTANT** : à ce stade du projet, il n'existe qu'un seul projet
Supabase (celui utilisé aussi par l'app web "Histoires"). `config/dev.json`
contient donc les vraies valeurs de ce projet, et `config/staging.json` /
`config/prod.json` pointent **temporairement vers ce même projet** (valeurs
identiques à dev, avec une clé `_todo` explicite dans chaque fichier pour ne
pas l'oublier).

Avant tout usage réel des flavors `staging`/`prod` (build de test à distribuer,
publication sur les stores), il faudra :
1. Créer un ou deux projets Supabase distincts (staging et/ou prod) —
   tâche `dev-backend-supabase`, coordonnée avec l'équipe web.
2. Remplacer les valeurs de `config/staging.json` et `config/prod.json` par
   les URL/clés du/des nouveaux projets, et retirer la clé `_todo`.

Tant que ce n'est pas fait, builder en `staging` ou `prod` revient à utiser le
projet Supabase de dev — ne pas utiliser ces flavors pour des tests impliquant
des données qui ne doivent pas se mélanger avec le dev.

## Comment lancer l'app avec un flavor

```bash
flutter run --dart-define-from-file=config/dev.json --flavor dev -t lib/main.dart
flutter run --dart-define-from-file=config/staging.json --flavor staging -t lib/main.dart
flutter run --dart-define-from-file=config/prod.json --flavor prod -t lib/main.dart
```

## Android

Les product flavors sont déclarés dans `android/app/build.gradle.kts`
(`flavorDimensions` + bloc `productFlavors`) :

- `dev` → `applicationId` suffixé `.dev` (`com.nexusjdr.personnages.dev`)
- `staging` → `applicationId` suffixé `.staging` (`com.nexusjdr.personnages.staging`)
- `prod` → `applicationId` inchangé (`com.nexusjdr.personnages`)

## iOS — à faire manuellement sur une machine avec Xcode

Cette machine de développement est sous Linux : pas de Xcode disponible pour
créer/tester les schémas et configurations iOS correspondants. **Ne pas
bricoler `ios/Runner.xcodeproj/project.pbxproj` à l'aveugle.**

À faire plus tard, sur une machine macOS avec Xcode, pour rester cohérent
avec les flavors Android :

1. Dans Xcode, dupliquer la configuration `Debug`/`Release`/`Profile` en 3
   jeux (`Debug-dev`, `Debug-staging`, `Debug-prod`, idem Release/Profile),
   ou utiliser des `.xcconfig` par flavor (`ios/Flutter/dev.xcconfig`,
   `staging.xcconfig`, `prod.xcconfig`) qui incluent `Debug.xcconfig`/
   `Release.xcconfig` et surchargent `PRODUCT_BUNDLE_IDENTIFIER` :
   - dev → `com.nexusjdr.personnages.dev`
   - staging → `com.nexusjdr.personnages.staging`
   - prod → `com.nexusjdr.personnages`
2. Créer 3 schémas Xcode (`dev`, `staging`, `prod`), chacun associé à sa
   configuration Debug/Release/Profile correspondante.
3. Vérifier que `flutter run --flavor dev` (etc.) fonctionne bien une fois
   les schémas créés.
