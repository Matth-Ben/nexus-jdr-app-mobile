#!/usr/bin/env bash
# Régénère le splash natif (Android et iOS) à partir des vrais widgets de
# l'app.
#
# Usage, depuis n'importe où :
#   tool/generate_splash_assets.sh
#
# À relancer quand change ce que montre le haut de l'écran de lancement
# Flutter (`lib/features/splash/presentation/splash_screen.dart`,
# `lib/core/widgets/app_brand_badge.dart`, `AppColors.sceneBackground`) ou
# la section `flutter_native_splash` de `pubspec.yaml`.
#
# Prérequis : bash, Flutter.
#
# Étapes :
#   1. `tool/splash/generate_splash_sources.dart` écrit les PNG sources dans
#      `assets/splash/`, à partir des polices déjà embarquées dans le dépôt
#      (`assets/fonts/` — plus de téléchargement depuis que ces polices sont
#      embarquées en asset plutôt que chargées par `google_fonts`, dette
#      D22, `docs/dette-technique.md`) ;
#   2. `dart run flutter_native_splash:create` en dérive les ressources
#      natives (`android/app/src/main/res/`, `ios/Runner/`).
#
# Relire ensuite `git status` : l'étape 2 réécrit aussi `styles.xml`,
# `launch_background.xml`, `LaunchScreen.storyboard` et `Info.plist`.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
font_dir="$repo_root/assets/fonts"

cd "$repo_root"

echo "Rendu des PNG sources (assets/splash/)..."
flutter test tool/splash/generate_splash_sources.dart \
  --dart-define=SPLASH_FONT_DIR="$font_dir"

echo "Génération des ressources natives..."
dart run flutter_native_splash:create
