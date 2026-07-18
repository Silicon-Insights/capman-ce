#!/bin/sh
set -eu

if [ ! -f .env ]; then
  echo ".env not found in the current directory"
  echo "Copy .env.example to .env before starting."
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

compose up -d
