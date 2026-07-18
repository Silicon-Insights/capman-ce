#!/bin/sh
set -eu

if [ ! -f .env ]; then
  echo ".env not found in the current directory"
  exit 1
fi

if [ ! -f .env.example ]; then
  echo ".env.example not found in the current directory"
  exit 1
fi

compose() {
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose --env-file .env "$@"
  elif docker compose version >/dev/null 2>&1; then
    docker compose --env-file .env "$@"
  else
    echo "Neither docker compose nor docker-compose is available."
    exit 1
  fi
}

load_env_value() {
  key="$1"
  awk -v key="$key" '
    $0 ~ ("^" key "=") {
      sub("^[^=]*=", "", $0)
      print
      exit
    }
  ' .env
}

NEW_IMAGE_LINE="$(grep '^CAPMAN_IMAGE=' .env.example | tail -n 1 || true)"
NEW_PROJECT_LINE="$(grep '^COMPOSE_PROJECT_NAME=' .env.example | tail -n 1 || true)"

if [ -z "$NEW_IMAGE_LINE" ]; then
  echo "CAPMAN_IMAGE was not found in .env.example"
  exit 1
fi

TMP_ENV="$(mktemp "${TMPDIR:-/tmp}/capman-env.XXXXXX")"

awk -v new_image="$NEW_IMAGE_LINE" -v new_project="$NEW_PROJECT_LINE" '
BEGIN { replaced = 0; project_replaced = 0 }
/^COMPOSE_PROJECT_NAME=/ {
  if (new_project != "") {
    print new_project
    project_replaced = 1
  } else {
    print
  }
  next
}
/^CAPMAN_IMAGE=/ {
  if (!replaced) {
    print new_image
    replaced = 1
  }
  next
}
{ print }
END {
  if (new_project != "" && !project_replaced) {
    print new_project
  }
  if (!replaced) {
    print new_image
  }
}
' .env > "$TMP_ENV"

mv "$TMP_ENV" .env

registry_user="$(load_env_value GITHUB_REGISTRY_USER)"
registry_token="$(load_env_value GITHUB_REGISTRY_TOKEN)"
capman_image="$(load_env_value CAPMAN_IMAGE)"
case "$capman_image" in
  ghcr.io/silicon-insights/capman-pro:*)
    if [ -z "$registry_user" ] || [ -z "$registry_token" ]; then
      echo "This private Capacity Manager (Pro) image requires GHCR credentials."
      echo "Run install-capman-pro.sh once to add GITHUB_REGISTRY_USER and GITHUB_REGISTRY_TOKEN to .env."
      exit 1
    fi
    ;;
esac
if [ -n "$registry_user" ] && [ -n "$registry_token" ]; then
  docker_config_file="${DOCKER_CONFIG:-${HOME}/.docker}/config.json"
  if [ ! -f "$docker_config_file" ] || ! grep -q '"ghcr.io"' "$docker_config_file"; then
    printf '%s\n' "$registry_token" | docker login ghcr.io -u "$registry_user" --password-stdin
  fi
fi

compose down
compose pull
compose up -d --force-recreate
