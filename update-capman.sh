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

compose down
compose pull
compose up -d --force-recreate
