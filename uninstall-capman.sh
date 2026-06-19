#!/bin/sh
set -eu

APP_NAME="Capacity Manager (CE)"
DEFAULT_PROJECT_NAME="capman-ce"
DEFAULT_DATA_DIR="./capman-data"

if [ ! -f docker-compose.yml ]; then
  echo "docker-compose.yml not found in the current directory"
  echo "Run this script from the Capacity Manager (CE) bundle directory."
  exit 1
fi

compose() {
  if [ -f .env ]; then
    if command -v docker-compose >/dev/null 2>&1; then
      docker-compose --env-file .env "$@"
    elif docker --help 2>/dev/null | grep -q '[[:space:]]compose[[:space:]]'; then
      docker compose --env-file .env "$@"
    else
      echo "Neither docker compose nor docker-compose is available."
      exit 1
    fi
  else
    if command -v docker-compose >/dev/null 2>&1; then
      docker-compose "$@"
    elif docker --help 2>/dev/null | grep -q '[[:space:]]compose[[:space:]]'; then
      docker compose "$@"
    else
      echo "Neither docker compose nor docker-compose is available."
      exit 1
    fi
  fi
}

load_env_value() {
  key="$1"
  file="$2"
  value="$(grep "^${key}=" "$file" | tail -n 1 | cut -d= -f2- || true)"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

project_name="$DEFAULT_PROJECT_NAME"
if [ -f .env ]; then
  env_project_name="$(load_env_value COMPOSE_PROJECT_NAME .env)"
  if [ -n "$env_project_name" ]; then
    project_name="$env_project_name"
  fi
fi

postgres_volume="${project_name}_postgres_data"
data_dir="$DEFAULT_DATA_DIR"

echo "This will uninstall ${APP_NAME} from the current directory."
echo
echo "It will remove:"
echo "- Docker containers and network for project: ${project_name}"
echo "- Docker volume: ${postgres_volume}"
echo "- Local data directory: ${data_dir}"
echo "- Local environment file: .env"
echo
printf "Type 'yes' to continue: "
IFS= read -r confirmation

if [ "$confirmation" != "yes" ]; then
  echo "Uninstall cancelled."
  exit 0
fi

compose down --remove-orphans || true

if docker volume inspect "$postgres_volume" >/dev/null 2>&1; then
  docker volume rm "$postgres_volume"
fi

if [ -d "$data_dir" ]; then
  rm -rf "$data_dir"
fi

if [ -f .env ]; then
  rm -f .env
fi

echo
echo "${APP_NAME} has been uninstalled from this bundle directory."
