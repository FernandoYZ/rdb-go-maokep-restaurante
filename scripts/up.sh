#!/usr/bin/env bash
set -euo pipefail

source .env

# ── Configuración ─────────────────────────────────────────────────────────────
CONTAINER="maokep-restaurante"
MAX_WAIT=60  # segundos de espera máximos

# ── Paleta de colores ─────────────────────────────────────────────────────────
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

WHITE='\033[38;2;255;255;255m'
GRAY='\033[38;2;113;113;122m'
MUTED='\033[38;2;63;63;70m'
GREEN='\033[38;2;74;222;128m'
YELLOW='\033[38;2;250;204;21m'
RED='\033[38;2;248;113;113m'
PURPLE='\033[38;2;167;139;250m'

# ── Helpers ───────────────────────────────────────────────────────────────────
_step() {
  local icon="$1" color="$2" label="$3" detail="${4:-}"
  if [[ -n "$detail" ]]; then
    printf "${MUTED}│${RESET}  ${color}${icon}${RESET}  ${WHITE}${label}${RESET}  ${MUTED}${detail}${RESET}\n"
  else
    printf "${MUTED}│${RESET}  ${color}${icon}${RESET}  ${WHITE}${label}${RESET}\n"
  fi
}

_wait_step() {
  local label="$1" elapsed="$2"
  printf "\r${MUTED}│${RESET}  ${YELLOW}◐${RESET}  ${WHITE}${label}${RESET}  ${MUTED}${elapsed}s${RESET}   "
}

_divider() {
  printf "${MUTED}├─────────────────────────────────────────${RESET}\n"
}

_duration() {
  printf "%.2fs" "$(awk "BEGIN { printf \"%.2f\", $1/1000 }")"
}

_fail() {
  printf "\n"
  _divider
  printf "${MUTED}│${RESET}  ${RED}${BOLD}✗ Error${RESET}  ${WHITE}${1}${RESET}\n"
  printf "${MUTED}└─────────────────────────────────────────${RESET}\n\n"
  exit 1
}

# ── Encabezado ────────────────────────────────────────────────────────────────
printf "\n"
printf "${MUTED}┌─────────────────────────────────────────${RESET}\n"
printf "${MUTED}│${RESET}  ${BOLD}${PURPLE}◆ maokep${RESET}   ${MUTED}make up${RESET}   ${DIM}$(date '+%H:%M:%S')${RESET}\n"
_divider

# ── Ejecución ─────────────────────────────────────────────────────────────────
start_ms=$(date +%s%3N)

# Detener entorno previo
_step "○" "$GRAY"  "Deteniendo entorno previo"
podman-compose down -v --remove-orphans >/dev/null 2>&1 || true
_step "✓" "$GREEN" "Entorno eliminado"

printf "${MUTED}│${RESET}\n"

# Levantar contenedores
_step "○" "$GRAY"  "Iniciando contenedores"
podman-compose up -d >/dev/null 2>&1
_step "✓" "$GREEN" "Contenedores iniciados"

printf "${MUTED}│${RESET}\n"

# Esperar: contenedor existente
elapsed=0
until podman container exists "$CONTAINER" 2>/dev/null; do
  _wait_step "Esperando contenedor" "$elapsed"
  sleep 1
  elapsed=$((elapsed + 1))
  if [[ "$elapsed" -ge "$MAX_WAIT" ]]; then
    printf "\n"
    _fail "Tiempo de espera agotado — el contenedor '$CONTAINER' nunca apareció"
  fi
done
[[ $elapsed -gt 0 ]] && printf "\n"
_step "✓" "$GREEN" "Contenedor listo" "${CONTAINER}"

printf "${MUTED}│${RESET}\n"

# Esperar: PostgreSQL listo
elapsed=0
until podman exec "$CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do
  _wait_step "Esperando PostgreSQL" "$elapsed"
  sleep 1
  elapsed=$((elapsed + 1))
  if [[ "$elapsed" -ge "$MAX_WAIT" ]]; then
    printf "\n"
    _fail "Tiempo de espera agotado — PostgreSQL no respondió a tiempo"
  fi
done
[[ $elapsed -gt 0 ]] && printf "\n"
_step "✓" "$GREEN" "PostgreSQL aceptando conexiones" "${DB_NAME}@${DB_USER}"

# ── Pie ───────────────────────────────────────────────────────────────────────
end_ms=$(date +%s%3N)
elapsed_total=$(( end_ms - start_ms ))

_divider
printf "${MUTED}│${RESET}  ${GREEN}${BOLD}✓ Listo${RESET}  ${MUTED}Despliegue completado${RESET}  ${DIM}$(_duration "$elapsed_total")${RESET}\n"
printf "${MUTED}└─────────────────────────────────────────${RESET}\n\n"