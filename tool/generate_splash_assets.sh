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
# Prérequis : bash, curl, sha256sum (ou shasum, fourni par macOS), Flutter.
#
# Étapes :
#   1. récupère les polices de l'app (Press Start 2P, Work Sans) dans un
#      cache hors dépôt, aux mêmes adresses et empreintes que `google_fonts`
#      (réseau requis la première fois seulement) ;
#   2. `tool/splash/generate_splash_sources.dart` écrit les PNG sources dans
#      `assets/splash/` ;
#   3. `dart run flutter_native_splash:create` en dérive les ressources
#      natives (`android/app/src/main/res/`, `ios/Runner/`).
#
# Relire ensuite `git status` : l'étape 3 réécrit aussi `styles.xml`,
# `launch_background.xml`, `LaunchScreen.storyboard` et `Info.plist`.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
font_dir="${SPLASH_FONT_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/nexus-jdr-personnages/fonts}"

# Empreintes SHA-256 reprises de `google_fonts` (`GoogleFontsFile` de
# `pressStart2p` et de `workSans` en graisse 400) : ce sont exactement les
# fichiers que l'app télécharge à l'exécution.
fonts=(
  "PressStart2P-Regular.ttf 8e9e854f71aebd3bb8342321d0cc92cabf68e27354dd7a90e806bce895da8dca"
  "WorkSans-Regular.ttf 4e3f7658c0730039e4c170dc038292141b9ac48df1732c335200391b072d6599"
)

# Affiche l'empreinte SHA-256 d'un fichier (`sha256sum` sous Linux, `shasum`
# sous macOS).
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

mkdir -p "$font_dir"
for entry in "${fonts[@]}"; do
  read -r name hash <<<"$entry"
  target="$font_dir/$name"
  if [ ! -f "$target" ]; then
    echo "Téléchargement de $name..."
    curl --fail --silent --show-error --location \
      --output "$target.part" "https://fonts.gstatic.com/s/a/$hash.ttf"
    if [ "$(sha256_of "$target.part")" != "$hash" ]; then
      rm -f "$target.part"
      echo "Téléchargement de $name rejeté : empreinte SHA-256 inattendue." >&2
      exit 1
    fi
    mv "$target.part" "$target"
  fi
  # Le cache est revérifié à chaque exécution.
  if [ "$(sha256_of "$target")" != "$hash" ]; then
    echo "Empreinte inattendue pour $target : supprimez ce fichier et relancez." >&2
    exit 1
  fi
done

cd "$repo_root"

echo "Rendu des PNG sources (assets/splash/)..."
echo "Les messages « Error: google_fonts was unable to load font … » qui suivent"
echo "sont attendus : le générateur interdit à google_fonts de télécharger les"
echo "polices et les charge lui-même, depuis $font_dir."
echo "Seul le code de sortie fait foi."
flutter test tool/splash/generate_splash_sources.dart \
  --dart-define=SPLASH_FONT_DIR="$font_dir"

echo "Génération des ressources natives..."
dart run flutter_native_splash:create
