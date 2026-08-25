#!/usr/bin/env bash
# Lance les tests d'intégration (test_integration/) contre le stack Supabase
# local du dépôt web. Voir test_integration/README.md pour le détail et pour
# lancer les tests à la main sans ce script.
#
# Prérequis : CLI Supabase disponible dans le dépôt web (`pnpm install`, elle
# est déjà en devDependency là-bas) et Docker actif. `jq` est utilisé pour
# lire la sortie de `supabase status`.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
web_repo="${NEXUS_WEB_REPO_PATH:-$repo_root/../markdown-editor}"
config_file="$repo_root/config/integration.json"

if [ ! -d "$web_repo" ]; then
  echo "Dépôt web introuvable : $web_repo" >&2
  echo "Renseignez NEXUS_WEB_REPO_PATH si ce dépôt n'est pas au chemin par défaut." >&2
  exit 1
fi

supabase_bin="$web_repo/node_modules/.bin/supabase"
if [ ! -x "$supabase_bin" ]; then
  if command -v supabase >/dev/null 2>&1; then
    supabase_bin="supabase"
  else
    echo "CLI Supabase introuvable (ni $supabase_bin, ni sur le PATH)." >&2
    echo "Lancez 'pnpm install' dans $web_repo, ou installez la CLI : https://supabase.com/docs/guides/cli" >&2
    exit 1
  fi
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "'jq' est requis pour lire la sortie de 'supabase status'." >&2
  exit 1
fi

echo "Démarrage du stack Supabase local ($web_repo)..."
(cd "$web_repo" && "$supabase_bin" start >/dev/null)

status_json="$(cd "$web_repo" && "$supabase_bin" status -o json)"
api_url="$(echo "$status_json" | jq -r '.API_URL')"
anon_key="$(echo "$status_json" | jq -r '.ANON_KEY')"

jq -n --arg url "$api_url" --arg key "$anon_key" \
  '{"SUPABASE_URL": $url, "SUPABASE_ANON_KEY": $key}' \
  > "$config_file"
echo "Config écrite dans $config_file (URL=$api_url)."

echo "Lancement de test_integration/..."
cd "$repo_root"
flutter test test_integration --dart-define-from-file="$config_file"
