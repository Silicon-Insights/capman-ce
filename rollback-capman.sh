#!/bin/sh
set -eu

usage() {
  echo "Usage: sh ./rollback-capman.sh BUILD_NUMBER"
  echo "Example: sh ./rollback-capman.sh 2949"
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

build_number="$1"
case "$build_number" in
  ''|*[!0-9]*)
    echo "BUILD_NUMBER must contain digits only."
    usage
    exit 1
    ;;
esac

if [ ! -f .env ]; then
  echo ".env not found in the current directory"
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

current_image="$(load_env_value CAPMAN_IMAGE)"
case "$current_image" in
  ghcr.io/silicon-insights/capman-ce:CAPMAN-CE_v*_[0-9]*|ghcr.io/silicon-insights/capman-pro:CAPMAN-PRO_v*_[0-9]*)
    ;;
  *)
    echo "CAPMAN_IMAGE does not contain a supported versioned CE or Pro image: $current_image"
    exit 1
    ;;
esac

rollback_image="$(printf '%s\n' "$current_image" | sed -E "s/_[0-9]+$/_${build_number}/")"
if [ "$rollback_image" = "$current_image" ]; then
  echo "CAPMAN_IMAGE is already set to build $build_number."
  exit 0
fi

registry_user="$(load_env_value GITHUB_REGISTRY_USER)"
registry_token="$(load_env_value GITHUB_REGISTRY_TOKEN)"
case "$rollback_image" in
  ghcr.io/silicon-insights/capman-pro:*)
    if [ -z "$registry_user" ] || [ -z "$registry_token" ]; then
      echo "This private Capacity Manager (Pro) image requires GHCR credentials."
      echo "Run install-capman-pro.sh once to configure them in .env."
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

backup_env="$(mktemp "${TMPDIR:-/tmp}/capman-rollback-backup.XXXXXX")"
new_env="$(mktemp "${TMPDIR:-/tmp}/capman-rollback-env.XXXXXX")"
cp .env "$backup_env"
trap 'rm -f "$backup_env" "$new_env"' EXIT HUP INT TERM

awk -v image="$rollback_image" '
BEGIN { replaced = 0 }
/^CAPMAN_IMAGE=/ {
  if (!replaced) {
    print "CAPMAN_IMAGE=" image
    replaced = 1
  }
  next
}
{ print }
END {
  if (!replaced) {
    print "CAPMAN_IMAGE=" image
  }
}
' .env > "$new_env"
mv "$new_env" .env

echo "Pulling rollback image: $rollback_image"
if ! compose pull capman; then
  echo "Unable to pull build $build_number; restoring the previous .env."
  cp "$backup_env" .env
  exit 1
fi

echo "Recreating Capacity Manager with build $build_number..."
compose up -d --force-recreate capman
rm -f "$backup_env"
trap - EXIT HUP INT TERM
echo "Rollback complete: $rollback_image"
