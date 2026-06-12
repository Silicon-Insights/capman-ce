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
  elif docker --help 2>/dev/null | grep -q '[[:space:]]compose[[:space:]]'; then
    docker compose --env-file .env "$@"
  else
    echo "Neither docker compose nor docker-compose is available."
    exit 1
  fi
}

compose up -d
