#!/bin/sh
set -eu

if [ ! -f .env.example ]; then
  echo ".env.example not found in the current directory"
  echo "Run this script from the CAPMAN-CE bundle directory."
  exit 1
fi

if [ ! -f start-capman.sh ]; then
  echo "start-capman.sh not found in the current directory"
  echo "Run this script from the CAPMAN-CE bundle directory."
  exit 1
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1"
    exit 1
  fi
}

print_docker_install_help() {
  os_name="$(uname -s 2>/dev/null || echo unknown)"
  echo
  echo "Docker is required to run CAPMAN-CE."
  echo
  case "$os_name" in
    Darwin)
      echo "macOS setup:"
      echo "1. Install Docker Desktop from https://www.docker.com/products/docker-desktop/"
      echo "2. Open Docker Desktop and wait for Docker to finish starting."
      echo "3. Re-run: sh ./install-capman.sh"
      ;;
    Linux)
      echo "Linux setup:"
      echo "1. Install Docker Engine and the Docker Compose plugin for your distribution."
      echo "2. Start the Docker daemon."
      echo "3. Confirm these commands work:"
      echo "   docker version"
      echo "   docker compose version"
      echo "4. Re-run: sh ./install-capman.sh"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "Windows setup:"
      echo "1. Install Docker Desktop from https://www.docker.com/products/docker-desktop/"
      echo "2. Start Docker Desktop and wait for Docker to finish starting."
      echo "3. If you are using WSL2, enable Docker Desktop WSL integration if needed."
      echo "4. Re-run: sh ./install-capman.sh"
      ;;
    *)
      echo "Install Docker and Docker Compose, make sure Docker is running, then re-run:"
      echo "sh ./install-capman.sh"
      ;;
  esac
}

check_compose() {
  if command -v docker-compose >/dev/null 2>&1; then
    return 0
  fi
  if docker --help 2>/dev/null | grep -q '[[:space:]]compose[[:space:]]'; then
    return 0
  fi
  echo "Docker Compose is required but was not found."
  print_docker_install_help
  exit 1
}

load_env_value() {
  key="$1"
  file="${2:-.env}"
  value="$(grep "^${key}=" "$file" | tail -n 1 | cut -d= -f2- || true)"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

update_env_value() {
  key="$1"
  value="$2"
  file="${3:-.env}"
  tmp_env="$(mktemp "${TMPDIR:-/tmp}/capman-ce-env.XXXXXX")"
  awk -v key="$key" -v value="$value" '
  BEGIN { replaced = 0 }
  $0 ~ ("^" key "=") {
    if (!replaced) {
      print key "=" value
      replaced = 1
    }
    next
  }
  { print }
  END {
    if (!replaced) {
      print key "=" value
    }
  }
  ' "$file" > "$tmp_env"
  mv "$tmp_env" "$file"
}

prompt_with_default() {
  prompt_text="$1"
  default_value="$2"
  if [ -n "$default_value" ]; then
    printf "%s [%s]: " "$prompt_text" "$default_value" >&2
  else
    printf "%s: " "$prompt_text" >&2
  fi
  IFS= read -r user_value
  if [ -n "$user_value" ]; then
    printf '%s' "$user_value"
  else
    printf '%s' "$default_value"
  fi
}

prompt_secret() {
  prompt_text="$1"
  current_value="$2"
  if [ -n "$current_value" ]; then
    printf "%s [press Enter to keep existing value]: " "$prompt_text" >&2
  else
    printf "%s: " "$prompt_text" >&2
  fi
  stty -echo
  IFS= read -r secret_value
  stty echo
  printf '\n' >&2
  if [ -n "$secret_value" ]; then
    printf '%s' "$secret_value"
  else
    printf '%s' "$current_value"
  fi
}

need_cmd git
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker was not found."
  print_docker_install_help
  exit 1
fi
check_compose

if [ ! -f .env ]; then
  cp .env.example .env
fi

default_host_port="$(load_env_value CAPMAN_HOST_PORT .env)"
default_license_api_base="$(load_env_value CAPMAN_LICENSE_API_BASE .env)"

echo "CAPMAN-CE installer"
echo "This script will update .env and start the stack."
echo

host_port="$(prompt_with_default "CAPMAN host port" "${default_host_port:-8070}")"
license_api_base="$(prompt_with_default "Licence API base URL" "${default_license_api_base:-https://capman-admin.siliconinsights.co.uk}")"

update_env_value "CAPMAN_HOST_PORT" "$host_port"
update_env_value "CAPMAN_LICENSE_API_BASE" "$license_api_base"

echo
echo "Starting CAPMAN-CE..."
sh ./start-capman.sh
echo
echo "CAPMAN-CE should be available at: http://localhost:${host_port}/home"
